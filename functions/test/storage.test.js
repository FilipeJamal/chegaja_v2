const {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "chegaja-ac88d";
const FIRESTORE_RULES = fs.readFileSync(
    path.resolve(__dirname, "../../firestore.rules"),
    "utf8"
);
const STORAGE_RULES = fs.readFileSync(
    path.resolve(__dirname, "../../storage.rules"),
    "utf8"
);

function upload(context, storagePath, contentType = "image/jpeg", bytes = "hello") {
    return context
        .storage()
        .ref(storagePath)
        .put(Buffer.from(bytes), {contentType});
}

async function seedPedido(testEnv, pedidoId, data) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("pedidos").doc(pedidoId).set(data);
    });
}

async function seedPilotParticipant(testEnv, uid, roles) {
    await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection("pilot_participants").doc(uid).set({
            uid,
            status: "active",
            roles,
            city: "Maputo",
        });
    });
}

function verifiedClaims(extra = {}) {
    return {phone_number: "+258840000000", ...extra};
}

describe("Storage Security Rules", () => {
    let testEnv;

    before(async () => {
        testEnv = await initializeTestEnvironment({
            projectId: PROJECT_ID,
            firestore: {
                rules: FIRESTORE_RULES,
                host: "127.0.0.1",
                port: 8080,
            },
            storage: {
                rules: STORAGE_RULES,
                host: "127.0.0.1",
                port: 9199,
            },
        });
    });

    after(async () => {
        await testEnv.cleanup();
    });

    beforeEach(async () => {
        await testEnv.clearFirestore();
        await testEnv.clearStorage();
    });

    it("denies unauthenticated writes outside known app paths", async () => {
        const unauth = testEnv.unauthenticatedContext();
        await assertFails(upload(unauth, "random/open.txt", "text/plain"));
    });

    it("allows pedido participants to upload and read pedido attachments", async () => {
        await seedPedido(testEnv, "pedido_1", {
            clienteId: "client1",
            prestadorId: "provider1",
            providerAccessGranted: true,
            providerAccessGrantedTo: "provider1",
            providerAccessGrantedAt: new Date(),
            status: "aceito",
        });
        await seedPilotParticipant(testEnv, "client1", ["cliente"]);
        await seedPilotParticipant(testEnv, "provider1", ["prestador"]);

        const client = testEnv.authenticatedContext("client1", verifiedClaims());
        const provider = testEnv.authenticatedContext("provider1", verifiedClaims());
        const storagePath = "pedidos/pedido_1/anexos/foto.jpg";

        await assertSucceeds(
            client.firestore().collection("pedidos").doc("pedido_1").get()
        );
        await assertSucceeds(upload(client, storagePath));
        await assertSucceeds(provider.storage().ref(storagePath).getDownloadURL());

        await testEnv.withSecurityRulesDisabled(async (context) => {
            await context.firestore().collection("pedidos").doc("pedido_1").update({
                status: "concluido",
                estado: "concluido",
            });
        });
        await assertSucceeds(provider.storage().ref(storagePath).getDownloadURL());
        await assertFails(upload(
            provider,
            "chats/pedido_1/images/after-completion.jpg"
        ));
        await assertFails(upload(
            client,
            "pedidos/pedido_1/anexos/after-completion.jpg"
        ));
    });

    it("requires an explicit provider grant for pedido and chat attachments", async () => {
        await seedPedido(testEnv, "pedido_grant", {
            clienteId: "client1",
            prestadorId: "provider1",
            status: "aguarda_resposta_prestador",
        });
        await seedPilotParticipant(testEnv, "client1", ["cliente"]);
        await seedPilotParticipant(testEnv, "provider1", ["prestador"]);

        const client = testEnv.authenticatedContext("client1", verifiedClaims());
        const provider = testEnv.authenticatedContext("provider1", verifiedClaims());
        const pedidoPath = "pedidos/pedido_grant/anexos/client-evidence.jpg";
        const chatPath = "chats/pedido_grant/images/provider-photo.jpg";

        await assertSucceeds(upload(client, pedidoPath));
        await assertFails(provider.storage().ref(pedidoPath).getDownloadURL());
        await assertFails(upload(provider, chatPath));

        await testEnv.withSecurityRulesDisabled(async (context) => {
            await context.firestore().collection("pedidos").doc("pedido_grant").update({
                status: "aceito",
                estado: "aceito",
                providerAccessGranted: true,
                providerAccessGrantedTo: "provider1",
                providerAccessGrantedAt: new Date(),
            });
        });

        await assertSucceeds(provider.storage().ref(pedidoPath).getDownloadURL());
        await assertSucceeds(upload(provider, chatPath));
    });

    it("keeps shared pedido evidence immutable for every non-admin participant", async () => {
        await seedPedido(testEnv, "pedido_immutable", {
            clienteId: "client1",
            prestadorId: "provider1",
            providerAccessGranted: true,
            providerAccessGrantedTo: "provider1",
            providerAccessGrantedAt: new Date(),
            status: "aceito",
        });
        await seedPilotParticipant(testEnv, "client1", ["cliente"]);
        await seedPilotParticipant(testEnv, "provider1", ["prestador"]);

        const client = testEnv.authenticatedContext("client1", verifiedClaims());
        const provider = testEnv.authenticatedContext("provider1", verifiedClaims());
        const admin = testEnv.authenticatedContext("admin1", {admin: true});
        const sharedObjects = [
            ["pedidos/pedido_immutable/anexos/evidence.jpg", "image/jpeg"],
            ["chats/pedido_immutable/images/evidence.jpg", "image/jpeg"],
            ["chats/pedido_immutable/files/evidence.pdf", "application/pdf"],
            ["chats/pedido_immutable/audio/evidence.m4a", "audio/mp4"],
        ];

        for (const [storagePath, contentType] of sharedObjects) {
            await assertSucceeds(upload(client, storagePath, contentType, "original"));
            await assertFails(upload(provider, storagePath, contentType, "tampered"));
            await assertFails(provider.storage().ref(storagePath).delete());
            await assertFails(upload(client, storagePath, contentType, "replaced"));
            await assertFails(client.storage().ref(storagePath).delete());
            await assertSucceeds(admin.storage().ref(storagePath).delete());
        }
    });

    it("denies pedido attachment access to non-participants", async () => {
        await seedPedido(testEnv, "pedido_2", {
            clienteId: "client1",
            prestadorId: "provider1",
            status: "aceito",
        });

        const attacker = testEnv.authenticatedContext("attacker", verifiedClaims());
        const storagePath = "pedidos/pedido_2/anexos/foto.jpg";

        await assertFails(upload(attacker, storagePath));
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await upload(context, storagePath);
        });
        await assertFails(attacker.storage().ref(storagePath).getDownloadURL());
    });

    it("requires both verified phone and active pilot membership for private uploads", async () => {
        await seedPedido(testEnv, "pedido_gate", {
            clienteId: "client1",
            prestadorId: null,
            status: "criado",
        });
        await seedPilotParticipant(testEnv, "client1", ["cliente"]);

        const unverifiedParticipant = testEnv.authenticatedContext("client1");
        const verifiedOutsideCohort = testEnv.authenticatedContext(
            "client2",
            verifiedClaims()
        );

        await assertFails(upload(
            unverifiedParticipant,
            "pedidos/pedido_gate/anexos/unverified.jpg"
        ));
        await assertFails(upload(
            verifiedOutsideCohort,
            "temp/client2/anexos/outside-cohort.jpg"
        ));
    });

    it("limits pedido attachments to supported content types and size", async () => {
        await seedPedido(testEnv, "pedido_3", {
            clienteId: "client1",
            prestadorId: "provider1",
            status: "aceito",
        });
        await seedPilotParticipant(testEnv, "client1", ["cliente"]);

        const client = testEnv.authenticatedContext("client1", verifiedClaims());
        await assertFails(
            upload(client, "pedidos/pedido_3/anexos/app.exe", "application/x-msdownload")
        );
        await assertFails(
            upload(
                client,
                "pedidos/pedido_3/anexos/large.pdf",
                "application/pdf",
                Buffer.alloc(21 * 1024 * 1024)
            )
        );
    });

    it("restricts temporary pedido attachments to the authenticated user folder", async () => {
        await seedPilotParticipant(testEnv, "client1", ["cliente"]);
        const client = testEnv.authenticatedContext("client1", verifiedClaims());

        await assertSucceeds(
            upload(client, "temp/client1/anexos/pre_pedido.jpg")
        );
        await assertFails(
            upload(client, "temp/other/anexos/pre_pedido.jpg")
        );
        await assertFails(
            upload(client, "temp/anexos_123/pre_pedido.jpg")
        );
    });

    it("allows chat audio only for pedido participants", async () => {
        await seedPedido(testEnv, "pedido_audio", {
            clienteId: "client1",
            prestadorId: "provider1",
            status: "aceito",
        });
        await seedPilotParticipant(testEnv, "client1", ["cliente"]);
        const client = testEnv.authenticatedContext("client1", verifiedClaims());
        const attacker = testEnv.authenticatedContext("attacker", verifiedClaims());
        const storagePath = "chats/pedido_audio/audio/message.m4a";
        await assertSucceeds(upload(client, storagePath, "audio/mp4"));
        await assertFails(upload(attacker, storagePath, "audio/mp4"));
        await assertFails(upload(client, "chats/pedido_audio/audio/fake.m4a", "image/jpeg"));
    });

    it("uses dedicated public profile paths and blocks legacy profile uploads", async () => {
        await seedPilotParticipant(testEnv, "client1", ["cliente"]);
        const client = testEnv.authenticatedContext("client1", verifiedClaims());
        const other = testEnv.authenticatedContext("other", verifiedClaims());
        const publicPath = "profile_public/client1/profile.jpg";
        await assertSucceeds(upload(client, publicPath));
        await assertSucceeds(other.storage().ref(publicPath).getDownloadURL());
        await assertFails(upload(other, publicPath));
        await assertFails(upload(client, "users/client1/profile.jpg"));
        await assertFails(upload(client, "prestadores/client1/profile.jpg"));
    });

    it("allows KYC upload only in a temporary grant and keeps reads admin-only", async () => {
        await seedPilotParticipant(testEnv, "provider1", ["prestador"]);
        const provider = testEnv.authenticatedContext("provider1", {
            ...verifiedClaims(),
            kyc_upload_enabled: true,
        });
        const providerWithoutClaim = testEnv.authenticatedContext(
            "provider1",
            verifiedClaims()
        );
        const other = testEnv.authenticatedContext("other", verifiedClaims());
        const admin = testEnv.authenticatedContext("admin1", {admin: true});
        const storagePath = "kyc_pending/provider1/submission_1/front.jpg";

        await assertFails(upload(providerWithoutClaim, storagePath));
        await assertFails(upload(provider, storagePath));
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await context.firestore().collection("kyc_upload_grants").doc("provider1").set({
                submissionId: "submission_1",
                expiresAt: new Date(Date.now() + 10 * 60 * 1000),
            });
        });

        await assertSucceeds(upload(provider, storagePath));
        await assertFails(provider.storage().ref(storagePath).getDownloadURL());
        await assertSucceeds(admin.storage().ref(storagePath).getDownloadURL());
        await assertFails(other.storage().ref(storagePath).getDownloadURL());
    });

    it("blocks legacy KYC uploads and expired grants", async () => {
        await seedPilotParticipant(testEnv, "provider1", ["prestador"]);
        const provider = testEnv.authenticatedContext("provider1", {
            ...verifiedClaims(),
            kyc_upload_enabled: true,
        });
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await context.firestore().collection("kyc_upload_grants").doc("provider1").set({
                submissionId: "expired",
                expiresAt: new Date(Date.now() - 60 * 1000),
            });
        });

        await assertFails(upload(provider, "kyc/provider1/front.jpg"));
        await assertFails(upload(provider, "kyc_pending/provider1/expired/front.jpg"));
    });

    it("blocks story uploads while the feature is outside the pilot", async () => {
        const provider = testEnv.authenticatedContext("provider1");
        await assertFails(upload(provider, "stories/provider1/story.jpg"));
    });
});
