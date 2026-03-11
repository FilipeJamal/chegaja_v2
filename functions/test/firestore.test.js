const {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "chegaja-v2";
const FIRESTORE_RULES = fs.readFileSync(
    path.resolve(__dirname, "../../firestore.rules"),
    "utf8"
);

describe("Firestore Security Rules", () => {
    let testEnv;

    before(async () => {
        testEnv = await initializeTestEnvironment({
            projectId: PROJECT_ID,
            firestore: {
                rules: FIRESTORE_RULES,
                host: "127.0.0.1",
                port: 8080,
            },
        });
    });

    after(async () => {
        await testEnv.cleanup();
    });

    beforeEach(async () => {
        await testEnv.clearFirestore();
    });

    describe("Users Collection", () => {
        it("should allow a user to read their own profile", async () => {
            const alice = testEnv.authenticatedContext("alice");
            await assertSucceeds(
                alice.firestore().collection("users").doc("alice").get()
            );
        });

        it("should allow a user to create their own profile", async () => {
            const alice = testEnv.authenticatedContext("alice");
            await assertSucceeds(
                alice.firestore().collection("users").doc("alice").set({
                    name: "Alice",
                    email: "alice@example.com",
                })
            );
        });

        it("should deny a user from writing to another user's profile", async () => {
            const alice = testEnv.authenticatedContext("alice");
            await assertFails(
                alice.firestore().collection("users").doc("bob").set({
                    name: "Hacked",
                })
            );
        });
    });

    describe("Prestadores Collection", () => {
        it("should allow anyone to read provider profiles", async () => {
            const unauth = testEnv.unauthenticatedContext();
            await assertSucceeds(
                unauth.firestore().collection("prestadores").doc("provider1").get()
            );
        });

        it("should allow a provider to update their own profile", async () => {
            const provider = testEnv.authenticatedContext("provider1");
            // Setup initial data
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context
                    .firestore()
                    .collection("prestadores")
                    .doc("provider1")
                    .set({ name: "Old Name", ratingCount: 0 });
            });

            await assertSucceeds(
                provider.firestore().collection("prestadores").doc("provider1").update({
                    name: "New Name",
                })
            );
        });

        it("should deny updates to rating fields by the provider", async () => {
            const provider = testEnv.authenticatedContext("provider1");
            // Setup initial data
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context
                    .firestore()
                    .collection("prestadores")
                    .doc("provider1")
                    .set({ name: "Provider", ratingCount: 10 });
            });

            // Try to boost rating
            await assertFails(
                provider.firestore().collection("prestadores").doc("provider1").update({
                    ratingCount: 100,
                })
            );
        });
    });

    describe("Pedidos Collection", () => {
        it("should allow a client to create a valid order", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore().collection("pedidos").add({
                    clienteId: "client1",
                    status: "criado",
                    createdAt: new Date(),
                    description: "Need help",
                })
            );
        });

        it("should deny creation if clienteId does not match auth uid", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("pedidos").add({
                    clienteId: "other_client", // Mismatch
                    status: "criado",
                })
            );
        });

        it("should allow provider to read an open order", async () => {
            // Ensure provider profile exists (requirement for isPrestador())
            await testEnv.withSecurityRulesDisabled(async (context) => {
                const adminDb = context.firestore();
                await adminDb.collection("prestadores").doc("provider1").set({});

                await adminDb.collection("pedidos").doc("order1").set({
                    clienteId: "client1",
                    status: "criado",
                    prestadorId: null
                });
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertSucceeds(
                provider.firestore().collection("pedidos").doc("order1").get()
            );
        });
    });

    describe("Chats Collection", () => {
        beforeEach(async () => {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context.firestore().collection("pedidos").doc("order_chat_1").set({
                    clienteId: "client1",
                    prestadorId: "provider1",
                    status: "aceito",
                });
            });
        });

        it("should allow a participant to merge-create chat meta when pedidoId matches", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore().collection("chats").doc("order_chat_1").set(
                    {
                        pedidoId: "order_chat_1",
                        updatedAt: new Date(),
                        clienteNome: "Cliente",
                    },
                    {merge: true}
                )
            );
        });

        it("should deny merge-create chat meta without pedidoId", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("chats").doc("order_chat_1").set(
                    {
                        updatedAt: new Date(),
                        clienteNome: "Cliente",
                    },
                    {merge: true}
                )
            );
        });
    });
});
