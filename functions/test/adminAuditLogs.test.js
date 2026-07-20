const assert = require("assert");
const { Timestamp } = require("firebase-admin/firestore");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "chegaja-ac88d";

const functions = require("../index");

describe("Admin audit log Functions", () => {
    const db = functions.__test__.getDb();
    const adminAuth = { uid: "admin1", token: { admin: true } };
    const commonAuth = { uid: "user1", token: {} };

    async function clearCollection(name) {
        const snap = await db.collection(name).get();
        if (snap.empty) return;
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
    }

    async function clearData() {
        await clearCollection("adminAuditLogs");
        await clearCollection("reports");
        await clearCollection("support_tickets");
        await clearCollection("pedidos");
        await clearCollection("stories");
    }

    async function auditLogs() {
        const snap = await db.collection("adminAuditLogs")
            .orderBy("createdAt", "desc")
            .get();
        return snap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    }

    beforeEach(async () => {
        await clearData();
    });

    it("admin_updateReportStatus creates an audit log with before and after status", async () => {
        await db.collection("reports").doc("report1").set({
            reporterId: "client1",
            targetType: "provider_profile",
            targetId: "provider1",
            reasonCode: "fraud",
            severity: "high",
            status: "pending_review",
            createdAt: Timestamp.fromMillis(Date.now() - 1000),
            updatedAt: Timestamp.fromMillis(Date.now() - 1000),
        });

        await functions.__test__.admin.adminUpdateReportStatusCore({
            database: db,
            auth: adminAuth,
            data: {
                reportId: "report1",
                status: "reviewed",
                decisionReason: "Triagem concluida",
            },
        });

        const logs = await auditLogs();
        assert.strictEqual(logs.length, 1);
        assert.strictEqual(logs[0].actorUid, "admin1");
        assert.strictEqual(logs[0].action, "report.update_status");
        assert.strictEqual(logs[0].targetType, "report");
        assert.strictEqual(logs[0].targetId, "report1");
        assert.strictEqual(logs[0].beforeStatus, "pending_review");
        assert.strictEqual(logs[0].afterStatus, "reviewed");
        assert.strictEqual(logs[0].reason, "Triagem concluida");
        assert.strictEqual(logs[0].source, "admin_callable");
        assert.ok(logs[0].createdAt);
    });

    it("support, no-show and story admin actions create audit logs", async () => {
        await db.collection("support_tickets").doc("ticket1").set({
            status: "open",
            subject: "Ajuda",
            createdAt: Timestamp.fromMillis(Date.now() - 3000),
        });
        await db.collection("pedidos").doc("pedido1").set({
            noShowDecision: "pending",
            updatedAt: Timestamp.fromMillis(Date.now() - 2000),
        });
        await db.collection("stories").doc("story1").set({
            prestadorId: "provider1",
            createdAt: Timestamp.fromMillis(Date.now() - 1000),
        });

        await functions.__test__.admin.adminUpdateSupportTicketStatusCore({
            database: db,
            auth: adminAuth,
            data: { ticketId: "ticket1", status: "resolved" },
        });
        await functions.__test__.admin.adminSetNoShowDecisionCore({
            database: db,
            auth: adminAuth,
            data: { pedidoId: "pedido1", decision: "approved" },
        });
        await functions.__test__.admin.adminDeleteStoryCore({
            database: db,
            auth: adminAuth,
            data: { storyId: "story1" },
        });

        const logs = await auditLogs();
        const byAction = Object.fromEntries(logs.map((log) => [log.action, log]));

        assert.strictEqual(
            byAction["support_ticket.update_status"].targetId,
            "ticket1"
        );
        assert.strictEqual(byAction["support_ticket.update_status"].beforeStatus, "open");
        assert.strictEqual(byAction["support_ticket.update_status"].afterStatus, "resolved");

        assert.strictEqual(byAction["no_show.set_decision"].targetId, "pedido1");
        assert.strictEqual(byAction["no_show.set_decision"].beforeStatus, "pending");
        assert.strictEqual(byAction["no_show.set_decision"].afterStatus, "approved");

        assert.strictEqual(byAction["story.delete"].targetId, "story1");
        assert.strictEqual(byAction["story.delete"].beforeStatus, "active");
        assert.strictEqual(byAction["story.delete"].afterStatus, "deleted");
    });

    it("admin_listAuditLogs returns recent logs and supports filters", async () => {
        await db.collection("adminAuditLogs").doc("old").set({
            actorUid: "admin1",
            action: "story.delete",
            targetType: "story",
            targetId: "story_old",
            beforeStatus: "active",
            afterStatus: "deleted",
            source: "admin_callable",
            createdAt: Timestamp.fromMillis(Date.now() - 5000),
        });
        await db.collection("adminAuditLogs").doc("new").set({
            actorUid: "admin1",
            action: "report.update_status",
            targetType: "report",
            targetId: "report_new",
            beforeStatus: "pending_review",
            afterStatus: "reviewed",
            source: "admin_callable",
            createdAt: Timestamp.fromMillis(Date.now()),
        });

        const result = await functions.__test__.admin.adminListAuditLogsCore({
            database: db,
            auth: adminAuth,
            data: { limit: 1 },
        });

        assert.strictEqual(result.logs.length, 1);
        assert.strictEqual(result.logs[0].id, "new");

        const filtered = await functions.__test__.admin.adminListAuditLogsCore({
            database: db,
            auth: adminAuth,
            data: { targetType: "story", action: "story.delete", limit: 50 },
        });

        assert.strictEqual(filtered.logs.length, 1);
        assert.strictEqual(filtered.logs[0].id, "old");
    });

    it("admin_listAuditLogs blocks common and anonymous users", async () => {
        await assert.rejects(
            () => functions.__test__.admin.adminListAuditLogsCore({
                database: db,
                auth: commonAuth,
                data: {},
            }),
            (err) => err.code === "permission-denied"
        );

        await assert.rejects(
            () => functions.__test__.admin.adminListAuditLogsCore({
                database: db,
                auth: null,
                data: {},
            }),
            (err) => err.code === "permission-denied"
        );
    });
});
