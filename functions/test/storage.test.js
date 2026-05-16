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
            status: "aceito",
        });

        const client = testEnv.authenticatedContext("client1");
        const provider = testEnv.authenticatedContext("provider1");
        const storagePath = "pedidos/pedido_1/anexos/foto.jpg";

        await assertSucceeds(
            client.firestore().collection("pedidos").doc("pedido_1").get()
        );
        await assertSucceeds(upload(client, storagePath));
        await assertSucceeds(provider.storage().ref(storagePath).getDownloadURL());
    });

    it("denies pedido attachment access to non-participants", async () => {
        await seedPedido(testEnv, "pedido_2", {
            clienteId: "client1",
            prestadorId: "provider1",
            status: "aceito",
        });

        const attacker = testEnv.authenticatedContext("attacker");
        const storagePath = "pedidos/pedido_2/anexos/foto.jpg";

        await assertFails(upload(attacker, storagePath));
        await testEnv.withSecurityRulesDisabled(async (context) => {
            await upload(context, storagePath);
        });
        await assertFails(attacker.storage().ref(storagePath).getDownloadURL());
    });

    it("limits pedido attachments to supported content types and size", async () => {
        await seedPedido(testEnv, "pedido_3", {
            clienteId: "client1",
            prestadorId: "provider1",
            status: "aceito",
        });

        const client = testEnv.authenticatedContext("client1");
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
        const client = testEnv.authenticatedContext("client1");

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

    it("keeps KYC documents private to the owner and admins", async () => {
        const provider = testEnv.authenticatedContext("provider1");
        const other = testEnv.authenticatedContext("other");
        const admin = testEnv.authenticatedContext("admin1", {admin: true});
        const storagePath = "kyc/provider1/front.jpg";

        await assertSucceeds(upload(provider, storagePath));
        await assertSucceeds(provider.storage().ref(storagePath).getDownloadURL());
        await assertSucceeds(admin.storage().ref(storagePath).getDownloadURL());
        await assertFails(other.storage().ref(storagePath).getDownloadURL());
    });
});
