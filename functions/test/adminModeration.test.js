const assert = require("assert");
const { Timestamp } = require("firebase-admin/firestore");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "chegaja-ac88d";

const functions = require("../index");

describe("Admin moderation report Functions", () => {
    const db = functions.__test__.db;
    const adminAuth = { uid: "admin1", token: { admin: true } };
    const commonAuth = { uid: "user1", token: {} };

    async function clearReports() {
        const snap = await db.collection("reports").get();
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
    }

    async function seedReport(id, data = {}) {
        await db.collection("reports").doc(id).set({
            reporterId: "client1",
            targetType: "provider_profile",
            targetId: "provider1",
            targetOwnerId: "provider1",
            reasonCode: "fraud",
            severity: "high",
            status: "pending_review",
            details: "Perfil suspeito",
            createdAt: Timestamp.fromMillis(Date.now() - 1000),
            updatedAt: Timestamp.fromMillis(Date.now() - 1000),
            ...data,
        });
    }

    beforeEach(async () => {
        await clearReports();
    });

    it("admin can list pending reports", async () => {
        await seedReport("report_pending");
        await seedReport("report_reviewed", { status: "reviewed" });

        const result = await functions.__test__.admin.adminListReportsCore({
            db,
            auth: adminAuth,
            data: { status: "pending_review", limit: 20 },
        });

        assert.strictEqual(result.reports.length, 1);
        assert.strictEqual(result.reports[0].id, "report_pending");
        assert.strictEqual(result.reports[0].status, "pending_review");
        assert.strictEqual(result.reports[0].targetType, "provider_profile");
        assert.strictEqual(result.counts.pending_review, 1);
    });

    it("admin can list reports by status", async () => {
        await seedReport("report_pending");
        await seedReport("report_escalated", { status: "escalated" });

        const result = await functions.__test__.admin.adminListReportsCore({
            db,
            auth: adminAuth,
            data: { status: "escalated", limit: 20 },
        });

        assert.deepStrictEqual(result.reports.map((item) => item.id), ["report_escalated"]);
    });

    it("admin can update report status with review metadata", async () => {
        await seedReport("report_update");

        await functions.__test__.admin.adminUpdateReportStatusCore({
            db,
            auth: adminAuth,
            data: {
                reportId: "report_update",
                status: "reviewed",
                decisionReason: "Analise inicial concluida",
            },
        });

        const snap = await db.collection("reports").doc("report_update").get();
        const data = snap.data();
        assert.strictEqual(data.status, "reviewed");
        assert.strictEqual(data.reviewedBy, "admin1");
        assert.strictEqual(data.decisionReason, "Analise inicial concluida");
        assert.ok(data.reviewedAt);
        assert.ok(data.updatedAt);
    });

    it("invalid status fails", async () => {
        await seedReport("report_invalid");

        await assert.rejects(
            () => functions.__test__.admin.adminUpdateReportStatusCore({
                db,
                auth: adminAuth,
                data: { reportId: "report_invalid", status: "bad_status" },
            }),
            (err) => err.code === "invalid-argument"
        );
    });

    it("missing report fails with controlled error", async () => {
        await assert.rejects(
            () => functions.__test__.admin.adminUpdateReportStatusCore({
                db,
                auth: adminAuth,
                data: { reportId: "missing", status: "reviewed" },
            }),
            (err) => err.code === "not-found"
        );
    });

    it("common user cannot list or update reports", async () => {
        await seedReport("report_private");

        await assert.rejects(
            () => functions.__test__.admin.adminListReportsCore({
                db,
                auth: commonAuth,
                data: { status: "pending_review" },
            }),
            (err) => err.code === "permission-denied"
        );

        await assert.rejects(
            () => functions.__test__.admin.adminUpdateReportStatusCore({
                db,
                auth: commonAuth,
                data: { reportId: "report_private", status: "reviewed" },
            }),
            (err) => err.code === "permission-denied"
        );
    });

    it("unauthenticated user cannot list or update reports", async () => {
        await seedReport("report_private");

        await assert.rejects(
            () => functions.__test__.admin.adminListReportsCore({
                db,
                auth: null,
                data: { status: "pending_review" },
            }),
            (err) => err.code === "permission-denied"
        );

        await assert.rejects(
            () => functions.__test__.admin.adminUpdateReportStatusCore({
                db,
                auth: null,
                data: { reportId: "report_private", status: "reviewed" },
            }),
            (err) => err.code === "permission-denied"
        );
    });
});
