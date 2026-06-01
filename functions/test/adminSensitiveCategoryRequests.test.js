const assert = require("assert");
const { Timestamp } = require("firebase-admin/firestore");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "chegaja-ac88d";

const functions = require("../index");

describe("Admin sensitive category request Functions", () => {
    const db = functions.__test__.db;
    const adminAuth = { uid: "admin1", token: { admin: true } };
    const commonAuth = { uid: "user1", token: {} };

    async function clearCollection(name) {
        const snap = await db.collection(name).get();
        if (snap.empty) return;
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
    }

    async function clearProviderApprovals(providerId) {
        const snap = await db
            .collection("prestadores")
            .doc(providerId)
            .collection("categoryApprovals")
            .get();
        if (snap.empty) return;
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
    }

    async function clearData() {
        await clearCollection("adminAuditLogs");
        await clearCollection("sensitiveCategoryRequests");
        await clearProviderApprovals("provider1");
        await clearProviderApprovals("provider2");
        await clearCollection("prestadores");
    }

    async function seedRequest(id, overrides = {}) {
        const now = Date.now();
        await db.collection("sensitiveCategoryRequests").doc(id).set({
            providerId: "provider1",
            categoryId: "electricity",
            categoryName: "Eletricidade",
            status: "pending_review",
            evidenceTypes: ["work_experience"],
            evidenceText: "Tenho experiencia comprovavel nesta categoria.",
            portfolioUrls: ["https://example.com/obra.jpg"],
            documentRefs: [],
            createdAt: Timestamp.fromMillis(now - 2000),
            submittedAt: Timestamp.fromMillis(now - 1000),
            updatedAt: Timestamp.fromMillis(now - 1000),
            ...overrides,
        });
    }

    beforeEach(async () => {
        await clearData();
    });

    it("admin_listSensitiveCategoryRequests lists pending requests and filters", async () => {
        await seedRequest("req1");
        await seedRequest("req2", {
            providerId: "provider2",
            categoryId: "gas",
            categoryName: "Gas",
            status: "approved",
            updatedAt: Timestamp.fromMillis(Date.now()),
        });

        const result = await functions.__test__.admin
            .adminListSensitiveCategoryRequestsCore({
                database: db,
                auth: adminAuth,
                data: { status: "pending_review", limit: 50 },
            });

        assert.strictEqual(result.requests.length, 1);
        assert.strictEqual(result.requests[0].id, "req1");
        assert.strictEqual(result.requests[0].providerId, "provider1");
        assert.strictEqual(result.requests[0].categoryName, "Eletricidade");
        assert.strictEqual(result.requests[0].evidenceText, "Tenho experiencia comprovavel nesta categoria.");
        assert.deepStrictEqual(result.requests[0].portfolioUrls, ["https://example.com/obra.jpg"]);
        assert.strictEqual(result.counts.pending_review, 1);
        assert.strictEqual(result.counts.approved, 1);

        const byProvider = await functions.__test__.admin
            .adminListSensitiveCategoryRequestsCore({
                database: db,
                auth: adminAuth,
                data: { status: "all", providerId: "provider2", categoryId: "gas" },
            });

        assert.strictEqual(byProvider.requests.length, 1);
        assert.strictEqual(byProvider.requests[0].id, "req2");
    });

    it("admin_listSensitiveCategoryRequests blocks common and anonymous users", async () => {
        await assert.rejects(
            () => functions.__test__.admin.adminListSensitiveCategoryRequestsCore({
                database: db,
                auth: commonAuth,
                data: {},
            }),
            (err) => err.code === "permission-denied"
        );

        await assert.rejects(
            () => functions.__test__.admin.adminListSensitiveCategoryRequestsCore({
                database: db,
                auth: null,
                data: {},
            }),
            (err) => err.code === "permission-denied"
        );
    });

    it("admin_reviewSensitiveCategoryRequest approves request and creates approval plus audit log", async () => {
        await seedRequest("req1");

        await functions.__test__.admin.adminReviewSensitiveCategoryRequestCore({
            database: db,
            auth: adminAuth,
            data: {
                requestId: "req1",
                decision: "approved",
                decisionReason: "Experiencia suficiente para esta fase.",
                expiresAt: Date.now() + 86400000,
            },
        });

        const request = await db.collection("sensitiveCategoryRequests").doc("req1").get();
        assert.strictEqual(request.data().status, "approved");
        assert.strictEqual(request.data().reviewedBy, "admin1");
        assert.strictEqual(request.data().decisionReason, "Experiencia suficiente para esta fase.");
        assert.ok(request.data().reviewedAt);

        const approval = await db
            .collection("prestadores")
            .doc("provider1")
            .collection("categoryApprovals")
            .doc("electricity")
            .get();
        assert.strictEqual(approval.exists, true);
        assert.strictEqual(approval.data().status, "approved");
        assert.strictEqual(approval.data().sourceRequestId, "req1");
        assert.strictEqual(approval.data().approvedBy, "admin1");
        assert.ok(approval.data().approvedAt);

        const provider = await db.collection("prestadores").doc("provider1").get();
        assert.strictEqual(provider.exists, true);
        assert.deepStrictEqual(provider.data().approvedSensitiveCategoryIds, ["electricity"]);
        assert.deepStrictEqual(provider.data().approvedSensitiveCategoryNames, ["Eletricidade"]);
        assert.ok(provider.data().categoryApprovalsUpdatedAt);
        assert.strictEqual(provider.data().evidenceText, undefined);
        assert.strictEqual(provider.data().documentRefs, undefined);
        assert.strictEqual(provider.data().portfolioUrls, undefined);

        const logs = await db.collection("adminAuditLogs").get();
        assert.strictEqual(logs.docs.length, 1);
        const log = logs.docs[0].data();
        assert.strictEqual(log.action, "sensitive_category_request.approve");
        assert.strictEqual(log.targetType, "sensitive_category_request");
        assert.strictEqual(log.targetId, "req1");
        assert.strictEqual(log.beforeStatus, "pending_review");
        assert.strictEqual(log.afterStatus, "approved");
        assert.strictEqual(log.reason, "Experiencia suficiente para esta fase.");
        assert.strictEqual(log.metadata.providerId, "provider1");
        assert.strictEqual(log.metadata.categoryId, "electricity");
        assert.strictEqual(log.metadata.evidenceText, undefined);
    });

    it("admin_reviewSensitiveCategoryRequest rejects or requests more info without creating approval", async () => {
        await seedRequest("req1");
        await seedRequest("req2", {
            categoryId: "gas",
            categoryName: "Gas",
            status: "submitted",
        });

        await functions.__test__.admin.adminReviewSensitiveCategoryRequestCore({
            database: db,
            auth: adminAuth,
            data: {
                requestId: "req1",
                decision: "rejected",
                decisionReason: "Falta contexto minimo.",
            },
        });
        await functions.__test__.admin.adminReviewSensitiveCategoryRequestCore({
            database: db,
            auth: adminAuth,
            data: {
                requestId: "req2",
                decision: "needs_more_info",
                decisionReason: "Envia mais detalhes da experiencia.",
            },
        });

        const rejected = await db.collection("sensitiveCategoryRequests").doc("req1").get();
        const moreInfo = await db.collection("sensitiveCategoryRequests").doc("req2").get();
        assert.strictEqual(rejected.data().status, "rejected");
        assert.strictEqual(moreInfo.data().status, "needs_more_info");

        const approvals = await db
            .collection("prestadores")
            .doc("provider1")
            .collection("categoryApprovals")
            .get();
        assert.strictEqual(approvals.empty, true);

        const provider = await db.collection("prestadores").doc("provider1").get();
        if (provider.exists) {
            assert.strictEqual(provider.data().approvedSensitiveCategoryIds, undefined);
            assert.strictEqual(provider.data().approvedSensitiveCategoryNames, undefined);
            assert.strictEqual(provider.data().categoryApprovalsUpdatedAt, undefined);
        }

        const logs = await db.collection("adminAuditLogs").get();
        const actions = logs.docs.map((doc) => doc.data().action).sort();
        assert.deepStrictEqual(actions, [
            "sensitive_category_request.needs_more_info",
            "sensitive_category_request.reject",
        ]);
    });

    it("admin_reviewSensitiveCategoryRequest validates decision, reason and permissions", async () => {
        await seedRequest("req1");

        await assert.rejects(
            () => functions.__test__.admin.adminReviewSensitiveCategoryRequestCore({
                database: db,
                auth: adminAuth,
                data: { requestId: "req1", decision: "invalid" },
            }),
            (err) => err.code === "invalid-argument"
        );

        await assert.rejects(
            () => functions.__test__.admin.adminReviewSensitiveCategoryRequestCore({
                database: db,
                auth: adminAuth,
                data: { requestId: "req1", decision: "rejected" },
            }),
            (err) => err.code === "invalid-argument"
        );

        await assert.rejects(
            () => functions.__test__.admin.adminReviewSensitiveCategoryRequestCore({
                database: db,
                auth: adminAuth,
                data: { requestId: "missing", decision: "approved" },
            }),
            (err) => err.code === "not-found"
        );

        await assert.rejects(
            () => functions.__test__.admin.adminReviewSensitiveCategoryRequestCore({
                database: db,
                auth: commonAuth,
                data: { requestId: "req1", decision: "approved" },
            }),
            (err) => err.code === "permission-denied"
        );
    });
});
