const assert = require("assert");
const { Timestamp } = require("firebase-admin/firestore");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "chegaja-ac88d";

const functions = require("../index");

describe("Public handle Functions", () => {
    const db = functions.__test__.getDb();
    const authProvider1 = { uid: "provider1", token: {} };
    const authProvider2 = { uid: "provider2", token: {} };

    async function clearCollection(name) {
        const snap = await db.collection(name).get();
        if (snap.empty) return;
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
    }

    async function clearData() {
        await clearCollection("handles");
        await clearCollection("provider_public");
    }

    async function seedPrestador(uid) {
        await db.collection("provider_public").doc(uid).set({
            nome: `Provider ${uid}`,
            createdAt: Timestamp.fromMillis(Date.now() - 1000),
        });
    }

    beforeEach(async () => {
        await clearData();
    });

    it("handle_checkAvailability returns available for a clean free handle", async () => {
        const result = await functions.__test__.handles.handleCheckAvailabilityCore({
            database: db,
            data: { handle: "@Maria_Bolos" },
        });

        assert.strictEqual(result.normalizedHandle, "maria_bolos");
        assert.strictEqual(result.available, true);
        assert.strictEqual(result.reason, "available");
    });

    it("handle_checkAvailability rejects invalid, reserved, prohibited and existing handles", async () => {
        await db.collection("handles").doc("studioarte").set({
            uid: "provider1",
            role: "prestador",
            status: "active",
            createdAt: Timestamp.fromMillis(Date.now()),
        });

        const invalid = await functions.__test__.handles.handleCheckAvailabilityCore({
            database: db,
            data: { handle: "ab" },
        });
        const reserved = await functions.__test__.handles.handleCheckAvailabilityCore({
            database: db,
            data: { handle: "admin" },
        });
        const prohibited = await functions.__test__.handles.handleCheckAvailabilityCore({
            database: db,
            data: { handle: "servicos-sexuais" },
        });
        const existing = await functions.__test__.handles.handleCheckAvailabilityCore({
            database: db,
            data: { handle: "studioarte" },
        });

        assert.strictEqual(invalid.available, false);
        assert.strictEqual(invalid.reason, "too_short");
        assert.strictEqual(reserved.available, false);
        assert.strictEqual(reserved.reason, "reserved");
        assert.strictEqual(prohibited.available, false);
        assert.strictEqual(prohibited.reason, "blocked");
        assert.strictEqual(existing.available, false);
        assert.strictEqual(existing.reason, "taken");
    });

    it("handle_reserveProviderHandle reserves a valid handle for provider", async () => {
        await seedPrestador("provider1");

        const result = await functions.__test__.handles.handleReserveProviderHandleCore({
            database: db,
            auth: authProvider1,
            data: { handle: "@Maria_Bolos" },
        });

        assert.deepStrictEqual(result, {
            handle: "maria_bolos",
            handleDisplay: "@maria_bolos",
            uid: "provider1",
            status: "active",
        });

        const handleSnap = await db.collection("handles").doc("maria_bolos").get();
        assert.strictEqual(handleSnap.exists, true);
        assert.strictEqual(handleSnap.data().uid, "provider1");
        assert.strictEqual(handleSnap.data().status, "active");

        const prestadorSnap = await db.collection("provider_public").doc("provider1").get();
        assert.strictEqual(prestadorSnap.data().handle, "maria_bolos");
        assert.strictEqual(prestadorSnap.data().handleDisplay, "@maria_bolos");
        assert.ok(prestadorSnap.data().handleUpdatedAt);
    });

    it("handle_reserveProviderHandle requires auth and provider profile", async () => {
        await assert.rejects(
            () => functions.__test__.handles.handleReserveProviderHandleCore({
                database: db,
                auth: null,
                data: { handle: "maria_bolos" },
            }),
            (err) => err.code === "unauthenticated"
        );

        await assert.rejects(
            () => functions.__test__.handles.handleReserveProviderHandleCore({
                database: db,
                auth: authProvider1,
                data: { handle: "maria_bolos" },
            }),
            (err) => err.code === "failed-precondition"
        );
    });

    it("handle_reserveProviderHandle is idempotent for same uid and blocks other uid", async () => {
        await seedPrestador("provider1");
        await seedPrestador("provider2");

        await functions.__test__.handles.handleReserveProviderHandleCore({
            database: db,
            auth: authProvider1,
            data: { handle: "maria_bolos" },
        });

        const again = await functions.__test__.handles.handleReserveProviderHandleCore({
            database: db,
            auth: authProvider1,
            data: { handle: "maria_bolos" },
        });
        assert.strictEqual(again.handle, "maria_bolos");

        await assert.rejects(
            () => functions.__test__.handles.handleReserveProviderHandleCore({
                database: db,
                auth: authProvider2,
                data: { handle: "maria_bolos" },
            }),
            (err) => err.code === "already-exists"
        );
    });

    it("handle_reserveProviderHandle rejects invalid reserved and prohibited handles", async () => {
        await seedPrestador("provider1");

        for (const handle of ["ab", "admin", "servicos-sexuais"]) {
            await assert.rejects(
                () => functions.__test__.handles.handleReserveProviderHandleCore({
                    database: db,
                    auth: authProvider1,
                    data: { handle },
                }),
                (err) => err.code === "invalid-argument"
            );
        }
    });

    it("handle swap releases old handle without making it available to others", async () => {
        await seedPrestador("provider1");
        await seedPrestador("provider2");

        await functions.__test__.handles.handleReserveProviderHandleCore({
            database: db,
            auth: authProvider1,
            data: { handle: "maria_bolos" },
        });
        await functions.__test__.handles.handleReserveProviderHandleCore({
            database: db,
            auth: authProvider1,
            data: { handle: "studioarte" },
        });

        const oldSnap = await db.collection("handles").doc("maria_bolos").get();
        assert.strictEqual(oldSnap.data().status, "released");
        assert.strictEqual(oldSnap.data().previousOwnerUid, "provider1");

        await assert.rejects(
            () => functions.__test__.handles.handleReserveProviderHandleCore({
                database: db,
                auth: authProvider2,
                data: { handle: "maria_bolos" },
            }),
            (err) => err.code === "already-exists"
        );
    });
});
