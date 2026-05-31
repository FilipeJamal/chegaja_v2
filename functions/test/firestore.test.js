const {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const { arrayUnion, serverTimestamp, Timestamp } = require("firebase/firestore");
const fs = require("fs");
const path = require("path");

const PROJECT_ID = "chegaja-ac88d";
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

        it("should deny updates to rating fields by another signed-in user", async () => {
            const outsider = testEnv.authenticatedContext("outsider");
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context
                    .firestore()
                    .collection("prestadores")
                    .doc("provider1")
                    .set({
                        name: "Provider",
                        ratingCount: 10,
                        ratingSum: 45,
                        ratingAvg: 4.5,
                    });
            });

            await assertFails(
                outsider.firestore().collection("prestadores").doc("provider1").update({
                    ratingCount: 999,
                    ratingSum: 999,
                    ratingAvg: 5,
                    updatedAt: serverTimestamp(),
                })
            );
        });

        it("should deny provider creating profile with handle fields directly", async () => {
            const provider = testEnv.authenticatedContext("provider_handle");
            await assertFails(
                provider.firestore().collection("prestadores").doc("provider_handle").set({
                    nome: "Provider Handle",
                    handle: "provider_handle",
                    handleDisplay: "@provider_handle",
                    handleUpdatedAt: serverTimestamp(),
                })
            );
        });

        it("should deny provider updating handle fields directly", async () => {
            const provider = testEnv.authenticatedContext("provider1");
            const providerDb = provider.firestore();
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context
                    .firestore()
                    .collection("prestadores")
                    .doc("provider1")
                    .set({ nome: "Provider", city: "Lisboa" });
            });

            await assertFails(
                providerDb.collection("prestadores").doc("provider1").update({
                    handle: "provider1",
                    handleDisplay: "@provider1",
                    handleUpdatedAt: serverTimestamp(),
                })
            );

            await assertSucceeds(
                providerDb.collection("prestadores").doc("provider1").update({
                    city: "Porto",
                })
            );
        });
    });

    describe("Public Handles Collection", () => {
        async function seedHandle(id = "maria_bolos", data = {}) {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context.firestore().collection("handles").doc(id).set({
                    uid: "provider1",
                    role: "prestador",
                    status: "active",
                    createdAt: new Date(),
                    updatedAt: new Date(),
                    ...data,
                });
            });
        }

        it("should allow public reads of handle reservation docs", async () => {
            await seedHandle();
            const unauth = testEnv.unauthenticatedContext();

            await assertSucceeds(
                unauth.firestore().collection("handles").doc("maria_bolos").get()
            );
        });

        it("should deny client-side create update and delete on handles", async () => {
            const provider = testEnv.authenticatedContext("provider1");
            const providerDb = provider.firestore();

            await assertFails(
                providerDb.collection("handles").doc("maria_bolos").set({
                    uid: "provider1",
                    role: "prestador",
                    status: "active",
                    createdAt: serverTimestamp(),
                    updatedAt: serverTimestamp(),
                })
            );

            await seedHandle();

            await assertFails(
                providerDb.collection("handles").doc("maria_bolos").update({
                    status: "blocked",
                    updatedAt: serverTimestamp(),
                })
            );
            await assertFails(
                providerDb.collection("handles").doc("maria_bolos").delete()
            );
        });
    });

    describe("Sensitive Category Requirements and Requests", () => {
        function validRequestPayload(overrides = {}) {
            return {
                providerId: "provider1",
                categoryId: "electricity",
                categoryName: "Eletricidade",
                status: "pending_review",
                evidenceTypes: ["certificate", "work_experience"],
                evidenceText: "Tenho comprovativo profissional.",
                portfolioUrls: ["https://example.com/work"],
                documentRefs: [],
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp(),
                submittedAt: serverTimestamp(),
                ...overrides,
            };
        }

        async function seedSensitiveRequest(id = "request1", data = {}) {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context.firestore()
                    .collection("sensitiveCategoryRequests")
                    .doc(id)
                    .set({
                        providerId: "provider1",
                        categoryId: "electricity",
                        categoryName: "Eletricidade",
                        status: "draft",
                        evidenceTypes: ["certificate"],
                        evidenceText: "Draft",
                        portfolioUrls: [],
                        documentRefs: [],
                        createdAt: new Date(),
                        updatedAt: new Date(),
                        ...data,
                    });
            });
        }

        async function seedApproval(data = {}) {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context.firestore()
                    .collection("prestadores")
                    .doc("provider1")
                    .collection("categoryApprovals")
                    .doc("electricity")
                    .set({
                        providerId: "provider1",
                        categoryId: "electricity",
                        categoryName: "Eletricidade",
                        status: "approved",
                        sourceRequestId: "request1",
                        approvedBy: "admin1",
                        approvedAt: new Date(),
                        createdAt: new Date(),
                        updatedAt: new Date(),
                        ...data,
                    });
            });
        }

        it("should allow public reads and deny user writes on category requirements", async () => {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context.firestore()
                    .collection("categoryRequirements")
                    .doc("electricity")
                    .set({
                        categoryId: "electricity",
                        categoryName: "Eletricidade",
                        riskLevel: "sensitive",
                        approvalRequired: true,
                        evidenceTypes: ["certificate"],
                        isActive: true,
                    });
            });
            const unauth = testEnv.unauthenticatedContext();
            const provider = testEnv.authenticatedContext("provider1");
            const admin = testEnv.authenticatedContext("admin1", { admin: true });

            await assertSucceeds(
                unauth.firestore().collection("categoryRequirements").doc("electricity").get()
            );
            await assertFails(
                provider.firestore().collection("categoryRequirements").doc("gas").set({
                    categoryId: "gas",
                    categoryName: "Gas",
                    riskLevel: "sensitive",
                    approvalRequired: true,
                    evidenceTypes: ["license"],
                    isActive: true,
                })
            );
            await assertSucceeds(
                admin.firestore().collection("categoryRequirements").doc("gas").set({
                    categoryId: "gas",
                    categoryName: "Gas",
                    riskLevel: "sensitive",
                    approvalRequired: true,
                    evidenceTypes: ["license"],
                    isActive: true,
                    createdAt: serverTimestamp(),
                    updatedAt: serverTimestamp(),
                })
            );
        });

        it("should allow provider to create a valid request for self", async () => {
            const provider = testEnv.authenticatedContext("provider1");

            await assertSucceeds(
                provider.firestore()
                    .collection("sensitiveCategoryRequests")
                    .doc("request1")
                    .set(validRequestPayload())
            );
        });

        it("should deny invalid requester, extra fields and review fields on create", async () => {
            const unauth = testEnv.unauthenticatedContext();
            const provider = testEnv.authenticatedContext("provider1");
            const unauthDb = unauth.firestore();
            const providerDb = provider.firestore();

            await assertFails(
                unauthDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request1")
                    .set(validRequestPayload())
            );
            await assertFails(
                providerDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request2")
                    .set(validRequestPayload({ providerId: "provider2" }))
            );
            await assertFails(
                providerDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request3")
                    .set(validRequestPayload({ hackedApproval: true }))
            );
            await assertFails(
                providerDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request4")
                    .set(validRequestPayload({ reviewedBy: "provider1" }))
            );
        });

        it("should deny long evidence text and invalid create status", async () => {
            const provider = testEnv.authenticatedContext("provider1");
            const providerDb = provider.firestore();

            await assertFails(
                providerDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request_long")
                    .set(validRequestPayload({ evidenceText: "x".repeat(2001) }))
            );
            await assertFails(
                providerDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request_approved")
                    .set(validRequestPayload({ status: "approved" }))
            );
            await assertFails(
                providerDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request_bad_evidence")
                    .set(validRequestPayload({ evidenceTypes: ["fake_certificate"] }))
            );
        });

        it("should allow owner reads, deny outsider reads and allow admin reads", async () => {
            await seedSensitiveRequest();
            const provider = testEnv.authenticatedContext("provider1");
            const outsider = testEnv.authenticatedContext("provider2");
            const admin = testEnv.authenticatedContext("admin1", { admin: true });

            await assertSucceeds(
                provider.firestore().collection("sensitiveCategoryRequests").doc("request1").get()
            );
            await assertFails(
                outsider.firestore().collection("sensitiveCategoryRequests").doc("request1").get()
            );
            await assertSucceeds(
                admin.firestore().collection("sensitiveCategoryRequests").doc("request1").get()
            );
        });

        it("should allow provider edits only while draft or needs_more_info", async () => {
            await seedSensitiveRequest("request_draft", { status: "draft" });
            await seedSensitiveRequest("request_review", { status: "pending_review" });
            const provider = testEnv.authenticatedContext("provider1");
            const providerDb = provider.firestore();

            await assertSucceeds(
                providerDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request_draft")
                    .update({
                        evidenceText: "Texto atualizado",
                        updatedAt: serverTimestamp(),
                    })
            );
            await assertFails(
                providerDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request_draft")
                    .update({
                        status: "approved",
                        reviewedBy: "provider1",
                        updatedAt: serverTimestamp(),
                    })
            );
            await assertFails(
                providerDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request_review")
                    .update({
                        evidenceText: "Tentativa tardia",
                        updatedAt: serverTimestamp(),
                    })
            );
        });

        it("should allow admin to review requests and manage approvals", async () => {
            await seedSensitiveRequest("request_review", { status: "pending_review" });
            const provider = testEnv.authenticatedContext("provider1");
            const admin = testEnv.authenticatedContext("admin1", { admin: true });
            const providerDb = provider.firestore();
            const adminDb = admin.firestore();

            await assertSucceeds(
                adminDb
                    .collection("sensitiveCategoryRequests")
                    .doc("request_review")
                    .update({
                        status: "approved",
                        reviewedBy: "admin1",
                        reviewedAt: serverTimestamp(),
                        decisionReason: "Comprovativo aceite",
                        updatedAt: serverTimestamp(),
                    })
            );
            await assertFails(
                providerDb
                    .collection("prestadores")
                    .doc("provider1")
                    .collection("categoryApprovals")
                    .doc("electricity")
                    .set({
                        providerId: "provider1",
                        categoryId: "electricity",
                        categoryName: "Eletricidade",
                        status: "approved",
                        sourceRequestId: "request_review",
                    })
            );
            await assertSucceeds(
                adminDb
                    .collection("prestadores")
                    .doc("provider1")
                    .collection("categoryApprovals")
                    .doc("electricity")
                    .set({
                        providerId: "provider1",
                        categoryId: "electricity",
                        categoryName: "Eletricidade",
                        status: "approved",
                        sourceRequestId: "request_review",
                        approvedBy: "admin1",
                        approvedAt: serverTimestamp(),
                        createdAt: serverTimestamp(),
                        updatedAt: serverTimestamp(),
                    })
            );
        });

        it("should allow public reads but no client writes on category approvals", async () => {
            await seedApproval();
            const unauth = testEnv.unauthenticatedContext();
            const provider = testEnv.authenticatedContext("provider1");

            await assertSucceeds(
                unauth.firestore()
                    .collection("prestadores")
                    .doc("provider1")
                    .collection("categoryApprovals")
                    .doc("electricity")
                    .get()
            );
            await assertFails(
                provider.firestore()
                    .collection("prestadores")
                    .doc("provider1")
                    .collection("categoryApprovals")
                    .doc("electricity")
                    .update({
                        status: "approved",
                        updatedAt: serverTimestamp(),
                    })
            );
        });
    });

    describe("Pedidos Collection", () => {
        async function seedPedido(id, data) {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context.firestore().collection("pedidos").doc(id).set({
                    clienteId: "client1",
                    status: "criado",
                    estado: "criado",
                    prestadorId: null,
                    servicoId: "svc1",
                    servicoNome: "Canalizador",
                    createdAt: new Date(),
                    ...data,
                });
            });
        }

        async function seedProvider(id, data = {}) {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context.firestore().collection("prestadores").doc(id).set({
                    servicos: ["svc1"],
                    servicosNomes: ["Canalizador"],
                    ...data,
                });
            });
        }

        function avaliacaoPayload(overrides = {}) {
            return {
                pedidoId: "order_review_done",
                clienteId: "client1",
                prestadorId: "provider1",
                estrelas: 5,
                comentario: "Servico bem feito",
                createdAt: serverTimestamp(),
                ...overrides,
            };
        }

        async function seedCompletedPedido(id = "order_review_done", data = {}) {
            await seedProvider("provider1");
            await seedPedido(id, {
                clienteId: "client1",
                status: "concluido",
                estado: "concluido",
                prestadorId: "provider1",
                ...data,
            });
        }

        describe("Avaliacoes Collection", () => {
            it("should allow owner client to create a review for a completed order with the expected doc id", async () => {
                await seedCompletedPedido();
                const client = testEnv.authenticatedContext("client1");

                await assertSucceeds(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1")
                        .set(avaliacaoPayload())
                );
            });

            it("should deny review creation when order is not completed", async () => {
                await seedProvider("provider1");
                await seedPedido("order_review_open", {
                    clienteId: "client1",
                    status: "aceito",
                    estado: "aceito",
                    prestadorId: "provider1",
                });
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_open_client1")
                        .set(avaliacaoPayload({
                            pedidoId: "order_review_open",
                        }))
                );
            });

            it("should deny another client reviewing someone else's order", async () => {
                await seedCompletedPedido();
                const otherClient = testEnv.authenticatedContext("client2");

                await assertFails(
                    otherClient.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client2")
                        .set(avaliacaoPayload({
                            clienteId: "client2",
                        }))
                );
            });

            it("should deny provider reviewing their own completed order as client", async () => {
                await seedCompletedPedido();
                const provider = testEnv.authenticatedContext("provider1");

                await assertFails(
                    provider.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_provider1")
                        .set(avaliacaoPayload({
                            clienteId: "provider1",
                        }))
                );
            });

            it("should deny unauthenticated review creation", async () => {
                await seedCompletedPedido();
                const unauth = testEnv.unauthenticatedContext();

                await assertFails(
                    unauth.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1")
                        .set(avaliacaoPayload())
                );
            });

            it("should deny rating below one", async () => {
                await seedCompletedPedido();
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1")
                        .set(avaliacaoPayload({ estrelas: 0 }))
                );
            });

            it("should deny rating above five", async () => {
                await seedCompletedPedido();
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1")
                        .set(avaliacaoPayload({ estrelas: 6 }))
                );
            });

            it("should deny non-string comments", async () => {
                await seedCompletedPedido();
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1")
                        .set(avaliacaoPayload({ comentario: 123 }))
                );
            });

            it("should deny comments that are too long", async () => {
                await seedCompletedPedido();
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1")
                        .set(avaliacaoPayload({ comentario: "x".repeat(501) }))
                );
            });

            it("should deny extra fields in reviews", async () => {
                await seedCompletedPedido();
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1")
                        .set(avaliacaoPayload({ moderationStatus: "approved" }))
                );
            });

            it("should deny reviews with a client-controlled createdAt", async () => {
                await seedCompletedPedido();
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1")
                        .set(avaliacaoPayload({ createdAt: new Date("2026-05-01T12:00:00Z") }))
                );
            });

            it("should deny review creation with wrong document id", async () => {
                await seedCompletedPedido();
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("wrong_doc")
                        .set(avaliacaoPayload())
                );
            });

            it("should deny duplicate review using another document id", async () => {
                await seedCompletedPedido();
                await testEnv.withSecurityRulesDisabled(async (context) => {
                    await context.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1")
                        .set(avaliacaoPayload({
                            createdAt: new Date(),
                        }));
                });
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1_copy")
                        .set(avaliacaoPayload())
                );
            });

            it("should deny reviewing a different provider than the assigned provider", async () => {
                await seedProvider("provider2");
                await seedCompletedPedido();
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore()
                        .collection("avaliacoes")
                        .doc("order_review_done_client1")
                        .set(avaliacaoPayload({ prestadorId: "provider2" }))
                );
            });

            it("should deny client directly changing provider rating aggregates", async () => {
                await seedCompletedPedido();
                const client = testEnv.authenticatedContext("client1");

                await assertFails(
                    client.firestore().collection("prestadores").doc("provider1").update({
                        ratingCount: 99,
                        ratingSum: 495,
                        ratingAvg: 5,
                        updatedAt: serverTimestamp(),
                    })
                );
            });
        });

        function manualInviteAcceptPatch(providerId, overrides = {}) {
            return {
                status: "aceito",
                estado: "aceito",
                prestadorId: providerId,
                updatedAt: serverTimestamp(),
                historico: arrayUnion({
                    evento: "convite_aceite",
                    timestamp: Timestamp.now(),
                    userId: providerId,
                    descricao: "Prestador aceitou o convite",
                }),
                ...overrides,
            };
        }

        function noShowPatch(reporterRole, overrides = {}) {
            return {
                noShowReportedBy: reporterRole,
                noShowReason: "tester nao apareceu",
                noShowAt: serverTimestamp(),
                updatedAt: serverTimestamp(),
                historico: arrayUnion({
                    evento: "noshow",
                    timestamp: Timestamp.now(),
                    userId: reporterRole === "prestador" ? "provider1" : "client1",
                    descricao: `${reporterRole} reportou No-Show`,
                }),
                ...overrides,
            };
        }

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

        it("should deny provider accepting an open order for another provider id", async () => {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                const adminDb = context.firestore();
                await adminDb.collection("prestadores").doc("provider1").set({
                    servicos: ["svc1"],
                    servicosNomes: ["Canalizador"],
                });
                await adminDb.collection("pedidos").doc("order_accept_self").set({
                    clienteId: "client1",
                    status: "criado",
                    estado: "criado",
                    prestadorId: null,
                    servicoId: "svc1",
                    servicoNome: "Canalizador",
                    createdAt: new Date(),
                });
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertFails(
                provider.firestore().collection("pedidos").doc("order_accept_self").update({
                    status: "aceito",
                    estado: "aceito",
                    prestadorId: "provider2",
                })
            );
        });

        it("should allow matching provider to accept an open order for themselves", async () => {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                const adminDb = context.firestore();
                await adminDb.collection("prestadores").doc("provider1").set({
                    servicos: ["svc1"],
                    servicosNomes: ["Canalizador"],
                });
                await adminDb.collection("pedidos").doc("order_accept_ok").set({
                    clienteId: "client1",
                    status: "criado",
                    estado: "criado",
                    prestadorId: null,
                    servicoId: "svc1",
                    servicoNome: "Canalizador",
                    createdAt: new Date(),
                });
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertSucceeds(
                provider.firestore().collection("pedidos").doc("order_accept_ok").update({
                    status: "aceito",
                    estado: "aceito",
                    prestadorId: "provider1",
                })
            );
        });

        it("should allow a client to invite a provider manually", async () => {
            await seedProvider("provider1");
            await seedPedido("order_manual_invite", {
                status: "criado",
                estado: "criado",
                prestadorId: null,
            });

            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore().collection("pedidos").doc("order_manual_invite").update({
                    status: "aguarda_resposta_prestador",
                    estado: "aguarda_resposta_prestador",
                    prestadorId: "provider1",
                })
            );
        });

        it("should allow the invited provider to accept a manual invite", async () => {
            await seedProvider("provider1");
            await seedPedido("order_manual_invite_accept", {
                status: "aguarda_resposta_prestador",
                estado: "aguarda_resposta_prestador",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertSucceeds(
                provider.firestore().collection("pedidos").doc("order_manual_invite_accept").update(
                    manualInviteAcceptPatch("provider1")
                )
            );
        });

        it("should deny another provider accepting someone else's manual invite", async () => {
            await seedProvider("provider1");
            await seedProvider("provider2");
            await seedPedido("order_manual_invite_wrong_provider", {
                status: "aguarda_resposta_prestador",
                estado: "aguarda_resposta_prestador",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider2");
            await assertFails(
                provider.firestore().collection("pedidos").doc("order_manual_invite_wrong_provider").update(
                    manualInviteAcceptPatch("provider2")
                )
            );
        });

        it("should deny invited provider changing prestadorId while accepting manual invite", async () => {
            await seedProvider("provider1");
            await seedProvider("provider2");
            await seedPedido("order_manual_invite_provider_attack", {
                status: "aguarda_resposta_prestador",
                estado: "aguarda_resposta_prestador",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertFails(
                provider.firestore().collection("pedidos").doc("order_manual_invite_provider_attack").update(
                    manualInviteAcceptPatch("provider2")
                )
            );
        });

        it("should deny invited provider changing clienteId while accepting manual invite", async () => {
            await seedProvider("provider1");
            await seedPedido("order_manual_invite_client_attack", {
                status: "aguarda_resposta_prestador",
                estado: "aguarda_resposta_prestador",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertFails(
                provider.firestore().collection("pedidos").doc("order_manual_invite_client_attack").update(
                    manualInviteAcceptPatch("provider1", { clienteId: "client2" })
                )
            );
        });

        it("should deny invited provider changing economic fields while accepting manual invite", async () => {
            await seedProvider("provider1");
            await seedPedido("order_manual_invite_economic_attack", {
                status: "aguarda_resposta_prestador",
                estado: "aguarda_resposta_prestador",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertFails(
                provider.firestore().collection("pedidos").doc("order_manual_invite_economic_attack").update(
                    manualInviteAcceptPatch("provider1", {
                        precoFinal: 1,
                        commissionPlatform: 0,
                        earningsProvider: 1,
                        earningsTotal: 1,
                    })
                )
            );
        });

        it("should deny provider accepting a cancelled manual invite", async () => {
            await seedProvider("provider1");
            await seedPedido("order_manual_invite_cancelled", {
                status: "cancelado",
                estado: "cancelado",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertFails(
                provider.firestore().collection("pedidos").doc("order_manual_invite_cancelled").update(
                    manualInviteAcceptPatch("provider1")
                )
            );
        });

        it("should deny provider accepting a concluded manual invite", async () => {
            await seedProvider("provider1");
            await seedPedido("order_manual_invite_concluded", {
                status: "concluido",
                estado: "concluido",
                prestadorId: "provider1",
                historico: [],
                precoFinal: 100,
                commissionPlatform: 15,
                earningsProvider: 85,
                earningsTotal: 100,
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertFails(
                provider.firestore().collection("pedidos").doc("order_manual_invite_concluded").update(
                    manualInviteAcceptPatch("provider1")
                )
            );
        });

        it("should deny client accepting a manual invite as provider", async () => {
            await seedProvider("provider1");
            await seedPedido("order_manual_invite_client_accept_attack", {
                status: "aguarda_resposta_prestador",
                estado: "aguarda_resposta_prestador",
                prestadorId: "provider1",
                historico: [],
            });

            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("pedidos").doc("order_manual_invite_client_accept_attack").update(
                    manualInviteAcceptPatch("provider1")
                )
            );
        });

        it("should deny client manipulation of provider earnings", async () => {
            await seedPedido("order_client_earnings_attack", {
                status: "em_andamento",
                estado: "em_andamento",
                prestadorId: "provider1",
                precoPropostoPrestador: 100,
                commissionPlatform: 15,
                earningsProvider: 85,
                earningsTotal: 100,
            });

            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("pedidos").doc("order_client_earnings_attack").update({
                    earningsProvider: 999,
                })
            );
        });

        it("should deny provider manipulation of final price fields", async () => {
            await seedPedido("order_provider_price_attack", {
                status: "em_andamento",
                estado: "em_andamento",
                prestadorId: "provider1",
                precoPropostoPrestador: 100,
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertFails(
                provider.firestore().collection("pedidos").doc("order_provider_price_attack").update({
                    precoFinal: 200,
                    commissionPlatform: 0,
                    earningsProvider: 200,
                    earningsTotal: 200,
                })
            );
        });

        it("should deny reopening a concluded order", async () => {
            await seedPedido("order_reopen_concluded", {
                status: "concluido",
                estado: "concluido",
                prestadorId: "provider1",
                precoFinal: 100,
                commissionPlatform: 15,
                earningsProvider: 85,
                earningsTotal: 100,
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertFails(
                provider.firestore().collection("pedidos").doc("order_reopen_concluded").update({
                    status: "em_andamento",
                    estado: "em_andamento",
                })
            );
        });

        it("should deny reopening a cancelled order", async () => {
            await seedPedido("order_reopen_cancelled", {
                status: "cancelado",
                estado: "cancelado",
                prestadorId: "provider1",
            });

            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("pedidos").doc("order_reopen_cancelled").update({
                    status: "aceito",
                    estado: "aceito",
                })
            );
        });

        it("should deny final confirmation with manipulated commission split", async () => {
            await seedPedido("order_bad_commission", {
                status: "aguarda_confirmacao_valor",
                estado: "aguarda_confirmacao_valor",
                prestadorId: "provider1",
                precoPropostoPrestador: 100,
                statusConfirmacaoValor: "pendente_cliente",
            });

            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("pedidos").doc("order_bad_commission").update({
                    status: "concluido",
                    estado: "concluido",
                    precoFinal: 100,
                    preco: 100,
                    statusConfirmacaoValor: "confirmado_cliente",
                    commissionPlatform: 99,
                    earningsProvider: 1,
                    earningsTotal: 100,
                    concluidoEm: new Date(),
                })
            );
        });

        it("should allow owner client to cancel their open order with audit history", async () => {
            await seedPedido("order_client_cancel_created", {
                historico: [
                    {
                        evento: "criado",
                        timestamp: new Date(),
                        userId: "client1",
                        descricao: "Pedido criado",
                    },
                ],
            });

            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore().collection("pedidos").doc("order_client_cancel_created").update({
                    status: "cancelado",
                    estado: "cancelado",
                    canceladoPor: "cliente",
                    motivoCancelamento: "",
                    tipoReembolso: "total",
                    updatedAt: serverTimestamp(),
                    historico: arrayUnion({
                        evento: "cancelado",
                        timestamp: Timestamp.now(),
                        userId: "client1",
                        descricao: "",
                    }),
                })
            );
        });

        it("should deny another client cancelling someone else's order", async () => {
            await seedPedido("order_other_client_cancel", {
                historico: [],
            });

            const otherClient = testEnv.authenticatedContext("client2");
            await assertFails(
                otherClient.firestore().collection("pedidos").doc("order_other_client_cancel").update({
                    status: "cancelado",
                    estado: "cancelado",
                    canceladoPor: "cliente",
                    motivoCancelamento: "",
                    tipoReembolso: "total",
                    updatedAt: serverTimestamp(),
                    historico: arrayUnion({
                        evento: "cancelado",
                        timestamp: Timestamp.now(),
                        userId: "client2",
                        descricao: "",
                    }),
                })
            );
        });

        it("should deny provider cancelling an open order as client", async () => {
            await seedProvider("provider1");
            await seedPedido("order_provider_cancel_as_client", {
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertFails(
                provider.firestore().collection("pedidos").doc("order_provider_cancel_as_client").update({
                    status: "cancelado",
                    estado: "cancelado",
                    canceladoPor: "cliente",
                    motivoCancelamento: "",
                    tipoReembolso: "total",
                    updatedAt: serverTimestamp(),
                    historico: arrayUnion({
                        evento: "cancelado",
                        timestamp: Timestamp.now(),
                        userId: "provider1",
                        descricao: "",
                    }),
                })
            );
        });

        it("should deny client cancellation of a concluded order", async () => {
            await seedPedido("order_cancel_concluded", {
                status: "concluido",
                estado: "concluido",
                prestadorId: "provider1",
                precoFinal: 100,
                commissionPlatform: 15,
                earningsProvider: 85,
                earningsTotal: 100,
                historico: [],
            });

            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("pedidos").doc("order_cancel_concluded").update({
                    status: "cancelado",
                    estado: "cancelado",
                    canceladoPor: "cliente",
                    motivoCancelamento: "",
                    tipoReembolso: "total",
                    updatedAt: serverTimestamp(),
                    historico: arrayUnion({
                        evento: "cancelado",
                        timestamp: Timestamp.now(),
                        userId: "client1",
                        descricao: "",
                    }),
                })
            );
        });

        it("should deny client changing economic fields during cancellation", async () => {
            await seedPedido("order_cancel_economic_attack", {
                historico: [],
            });

            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("pedidos").doc("order_cancel_economic_attack").update({
                    status: "cancelado",
                    estado: "cancelado",
                    canceladoPor: "cliente",
                    motivoCancelamento: "",
                    tipoReembolso: "total",
                    precoFinal: 1,
                    commissionPlatform: 0,
                    earningsProvider: 1,
                    earningsTotal: 1,
                    updatedAt: serverTimestamp(),
                    historico: arrayUnion({
                        evento: "cancelado",
                        timestamp: Timestamp.now(),
                        userId: "client1",
                        descricao: "",
                    }),
                })
            );
        });

        it("should deny client changing provider during cancellation", async () => {
            await seedPedido("order_cancel_provider_attack", {
                historico: [],
            });

            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("pedidos").doc("order_cancel_provider_attack").update({
                    status: "cancelado",
                    estado: "cancelado",
                    prestadorId: "provider1",
                    canceladoPor: "cliente",
                    motivoCancelamento: "",
                    tipoReembolso: "total",
                    updatedAt: serverTimestamp(),
                    historico: arrayUnion({
                        evento: "cancelado",
                        timestamp: Timestamp.now(),
                        userId: "client1",
                        descricao: "",
                    }),
                })
            );
        });

        it("should allow assigned provider to report no-show without hitting generic update", async () => {
            await seedProvider("provider1");
            await seedPedido("order_noshow_provider", {
                clienteId: "client1",
                status: "aceito",
                estado: "aceito",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");

            await assertSucceeds(
                provider.firestore()
                    .collection("pedidos")
                    .doc("order_noshow_provider")
                    .update(noShowPatch("prestador"))
            );
        });

        it("should allow owner client to report no-show", async () => {
            await seedProvider("provider1");
            await seedPedido("order_noshow_client", {
                clienteId: "client1",
                status: "aceito",
                estado: "aceito",
                prestadorId: "provider1",
                historico: [],
            });

            const client = testEnv.authenticatedContext("client1");

            await assertSucceeds(
                client.firestore()
                    .collection("pedidos")
                    .doc("order_noshow_client")
                    .update(noShowPatch("cliente"))
            );
        });

        it("should deny outsider reporting no-show", async () => {
            await seedProvider("provider1");
            await seedPedido("order_noshow_outsider", {
                clienteId: "client1",
                status: "aceito",
                estado: "aceito",
                prestadorId: "provider1",
                historico: [],
            });

            const outsider = testEnv.authenticatedContext("outsider");

            await assertFails(
                outsider.firestore()
                    .collection("pedidos")
                    .doc("order_noshow_outsider")
                    .update(noShowPatch("cliente"))
            );
        });

        it("should deny provider reporting no-show for unassigned order", async () => {
            await seedProvider("provider1");
            await seedPedido("order_noshow_unassigned", {
                clienteId: "client1",
                status: "criado",
                estado: "criado",
                prestadorId: null,
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");

            await assertFails(
                provider.firestore()
                    .collection("pedidos")
                    .doc("order_noshow_unassigned")
                    .update(noShowPatch("prestador"))
            );
        });

        it("should deny no-show changing economic fields", async () => {
            await seedProvider("provider1");
            await seedPedido("order_noshow_money", {
                clienteId: "client1",
                status: "aceito",
                estado: "aceito",
                prestadorId: "provider1",
                precoFinal: null,
                commissionPlatform: null,
                earningsProvider: null,
                earningsTotal: null,
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");

            await assertFails(
                provider.firestore()
                    .collection("pedidos")
                    .doc("order_noshow_money")
                    .update(noShowPatch("prestador", {
                        precoFinal: 999,
                        commissionPlatform: 999,
                        earningsProvider: 999,
                        earningsTotal: 999,
                    }))
            );
        });

        it("should deny no-show changing prestadorId", async () => {
            await seedProvider("provider1");
            await seedProvider("provider2");
            await seedPedido("order_noshow_swap_provider", {
                clienteId: "client1",
                status: "aceito",
                estado: "aceito",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");

            await assertFails(
                provider.firestore()
                    .collection("pedidos")
                    .doc("order_noshow_swap_provider")
                    .update(noShowPatch("prestador", {
                        prestadorId: "provider2",
                    }))
            );
        });

        it("should deny no-show changing clienteId", async () => {
            await seedProvider("provider1");
            await seedPedido("order_noshow_swap_client", {
                clienteId: "client1",
                status: "aceito",
                estado: "aceito",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");

            await assertFails(
                provider.firestore()
                    .collection("pedidos")
                    .doc("order_noshow_swap_client")
                    .update(noShowPatch("prestador", {
                        clienteId: "client2",
                    }))
            );
        });

        it("should deny no-show changing order state", async () => {
            await seedProvider("provider1");
            await seedPedido("order_noshow_state_attack", {
                clienteId: "client1",
                status: "aceito",
                estado: "aceito",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");

            await assertFails(
                provider.firestore()
                    .collection("pedidos")
                    .doc("order_noshow_state_attack")
                    .update(noShowPatch("prestador", {
                        status: "em_andamento",
                        estado: "em_andamento",
                    }))
            );
        });

        it("should deny no-show on completed order", async () => {
            await seedProvider("provider1");
            await seedPedido("order_noshow_completed", {
                clienteId: "client1",
                status: "concluido",
                estado: "concluido",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");

            await assertFails(
                provider.firestore()
                    .collection("pedidos")
                    .doc("order_noshow_completed")
                    .update(noShowPatch("prestador"))
            );
        });

        it("should deny no-show on canceled order", async () => {
            await seedProvider("provider1");
            await seedPedido("order_noshow_canceled", {
                clienteId: "client1",
                status: "cancelado",
                estado: "cancelado",
                prestadorId: "provider1",
                historico: [],
            });

            const provider = testEnv.authenticatedContext("provider1");

            await assertFails(
                provider.firestore()
                    .collection("pedidos")
                    .doc("order_noshow_canceled")
                    .update(noShowPatch("prestador"))
            );
        });

        it("should allow final confirmation with the expected commission split", async () => {
            await seedPedido("order_good_commission", {
                status: "aguarda_confirmacao_valor",
                estado: "aguarda_confirmacao_valor",
                prestadorId: "provider1",
                precoPropostoPrestador: 100,
                statusConfirmacaoValor: "pendente_cliente",
            });

            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore().collection("pedidos").doc("order_good_commission").update({
                    status: "concluido",
                    estado: "concluido",
                    precoFinal: 100,
                    preco: 100,
                    statusConfirmacaoValor: "confirmado_cliente",
                    commissionPlatform: 15,
                    earningsProvider: 85,
                    earningsTotal: 100,
                    concluidoEm: new Date(),
                })
            );
        });

        it("should deny client spoofing authoritative function marker", async () => {
            await seedPedido("order_spoof_authoritative_marker", {
                status: "aguarda_confirmacao_valor",
                estado: "aguarda_confirmacao_valor",
                prestadorId: "provider1",
                precoPropostoPrestador: 100,
                statusConfirmacaoValor: "pendente_cliente",
            });

            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("pedidos").doc("order_spoof_authoritative_marker").update({
                    status: "concluido",
                    estado: "concluido",
                    precoFinal: 100,
                    preco: 100,
                    statusConfirmacaoValor: "confirmado_cliente",
                    commissionPlatform: 15,
                    earningsProvider: 85,
                    earningsTotal: 100,
                    concluidoEm: new Date(),
                    lastAuthoritativeFunction: "confirmarValorFinalPedido",
                })
            );
        });

        it("should allow assigned provider to start service", async () => {
            await seedPedido("order_start_service", {
                status: "aceito",
                estado: "aceito",
                prestadorId: "provider1",
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertSucceeds(
                provider.firestore().collection("pedidos").doc("order_start_service").update({
                    status: "em_andamento",
                    estado: "em_andamento",
                })
            );
        });

        it("should allow assigned provider to send quote range", async () => {
            await seedProvider("provider1");
            await seedPedido("order_quote_range", {
                status: "aceito",
                estado: "aceito",
                prestadorId: "provider1",
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertSucceeds(
                provider.firestore().collection("pedidos").doc("order_quote_range").update({
                    status: "aguarda_resposta_cliente",
                    estado: "aguarda_resposta_cliente",
                    prestadorId: "provider1",
                    valorMinEstimadoPrestador: 20,
                    valorMaxEstimadoPrestador: 35,
                    statusProposta: "pendente_cliente",
                    statusConfirmacaoValor: "nenhum",
                    precoPropostoPrestador: null,
                    precoFinal: null,
                    commissionPlatform: null,
                    earningsProvider: null,
                    earningsTotal: null,
                })
            );
        });

        it("should allow client to accept provider quote range", async () => {
            await seedPedido("order_accept_quote_range", {
                status: "aguarda_resposta_cliente",
                estado: "aguarda_resposta_cliente",
                prestadorId: "provider1",
                valorMinEstimadoPrestador: 20,
                valorMaxEstimadoPrestador: 35,
                statusProposta: "pendente_cliente",
                statusConfirmacaoValor: "nenhum",
                precoPropostoPrestador: null,
                precoFinal: null,
                commissionPlatform: null,
                earningsProvider: null,
                earningsTotal: null,
            });

            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore().collection("pedidos").doc("order_accept_quote_range").update({
                    status: "aceito",
                    estado: "aceito",
                    statusProposta: "aceita_cliente",
                })
            );
        });

        it("should allow assigned provider to propose final value", async () => {
            await seedPedido("order_final_value", {
                status: "em_andamento",
                estado: "em_andamento",
                prestadorId: "provider1",
            });

            const provider = testEnv.authenticatedContext("provider1");
            await assertSucceeds(
                provider.firestore().collection("pedidos").doc("order_final_value").update({
                    status: "aguarda_confirmacao_valor",
                    estado: "aguarda_confirmacao_valor",
                    precoPropostoPrestador: 100,
                    statusConfirmacaoValor: "pendente_cliente",
                })
            );
        });
    });

    describe("FCM tokens", () => {
        it("should deny writing another user's token subcollection", async () => {
            const alice = testEnv.authenticatedContext("alice");
            await assertFails(
                alice.firestore().collection("users").doc("bob")
                    .collection("fcmTokens").doc("token1").set({
                        token: "token1",
                    })
            );
        });
    });

    describe("Chats Collection", () => {
        beforeEach(async () => {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                const adminDb = context.firestore();
                await adminDb.collection("pedidos").doc("order_chat_1").set({
                    clienteId: "client1",
                    prestadorId: "provider1",
                    status: "aceito",
                    estado: "aceito",
                });
                await adminDb.collection("chats").doc("order_chat_1").set({
                    pedidoId: "order_chat_1",
                    clienteId: "client1",
                    prestadorId: "provider1",
                    lastMessageAt: new Date(),
                });
                await adminDb
                    .collection("chats")
                    .doc("order_chat_1")
                    .collection("messages")
                    .doc("msg1")
                    .set({
                        pedidoId: "order_chat_1",
                        text: "Mensagem de teste",
                        senderId: "client1",
                        senderRole: "cliente",
                        createdAt: new Date(),
                    });
                await adminDb.collection("pedidos").doc("order_chat_open").set({
                    clienteId: "client1",
                    prestadorId: null,
                    status: "criado",
                    estado: "criado",
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
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context.firestore().collection("pedidos").doc("order_chat_missing_meta").set({
                    clienteId: "client1",
                    prestadorId: "provider1",
                    status: "aceito",
                    estado: "aceito",
                });
            });

            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("chats").doc("order_chat_missing_meta").set(
                    {
                        updatedAt: new Date(),
                        clienteNome: "Cliente",
                    },
                    {merge: true}
                )
            );
        });

        it("should allow client participant to list chat messages", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore()
                    .collection("chats")
                    .doc("order_chat_1")
                    .collection("messages")
                    .orderBy("createdAt", "desc")
                    .limit(50)
                    .get()
            );
        });

        it("should allow provider participant to list chat messages", async () => {
            const provider = testEnv.authenticatedContext("provider1");
            await assertSucceeds(
                provider.firestore()
                    .collection("chats")
                    .doc("order_chat_1")
                    .collection("messages")
                    .orderBy("createdAt", "desc")
                    .limit(50)
                    .get()
            );
        });

        it("should deny outsider listing chat messages", async () => {
            const outsider = testEnv.authenticatedContext("outsider1");
            await assertFails(
                outsider.firestore()
                    .collection("chats")
                    .doc("order_chat_1")
                    .collection("messages")
                    .orderBy("createdAt", "desc")
                    .limit(50)
                    .get()
            );
        });

        it("should deny unauthenticated listing chat messages", async () => {
            const unauth = testEnv.unauthenticatedContext();
            await assertFails(
                unauth.firestore()
                    .collection("chats")
                    .doc("order_chat_1")
                    .collection("messages")
                    .orderBy("createdAt", "desc")
                    .limit(50)
                    .get()
            );
        });

        it("should allow participants to get individual chat messages", async () => {
            const provider = testEnv.authenticatedContext("provider1");
            await assertSucceeds(
                provider.firestore()
                    .collection("chats")
                    .doc("order_chat_1")
                    .collection("messages")
                    .doc("msg1")
                    .get()
            );
        });

        it("should deny outsiders getting individual chat messages", async () => {
            const outsider = testEnv.authenticatedContext("outsider1");
            await assertFails(
                outsider.firestore()
                    .collection("chats")
                    .doc("order_chat_1")
                    .collection("messages")
                    .doc("msg1")
                    .get()
            );
        });

        it("should deny provider listing messages before they are assigned to the order", async () => {
            const provider = testEnv.authenticatedContext("provider1");
            await assertFails(
                provider.firestore()
                    .collection("chats")
                    .doc("order_chat_open")
                    .collection("messages")
                    .orderBy("createdAt", "desc")
                    .limit(50)
                    .get()
            );
        });
    });

    describe("Trust & Safety reports", () => {
        function validReportPayload(overrides = {}) {
            return {
                reporterId: "client1",
                targetType: "provider_profile",
                targetId: "provider1",
                reasonCode: "fraud",
                severity: "high",
                status: "pending_review",
                details: "Perfil parece enganoso",
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp(),
                ...overrides,
            };
        }

        async function seedReport(id = "report1", data = {}) {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context.firestore().collection("reports").doc(id).set({
                    reporterId: "client1",
                    targetType: "provider_profile",
                    targetId: "provider1",
                    reasonCode: "fraud",
                    severity: "high",
                    status: "pending_review",
                    createdAt: new Date(),
                    updatedAt: new Date(),
                    ...data,
                });
            });
        }

        it("should allow an authenticated user to create a valid report", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore().collection("reports").doc("report1").set(validReportPayload())
            );
        });

        it("should deny unauthenticated report creation", async () => {
            const unauth = testEnv.unauthenticatedContext();
            await assertFails(
                unauth.firestore().collection("reports").doc("report1").set(validReportPayload())
            );
        });

        it("should deny reports with reporterId different from auth uid", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("reports").doc("report1").set(
                    validReportPayload({ reporterId: "client2" })
                )
            );
        });

        it("should deny reports with invalid targetType", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("reports").doc("report1").set(
                    validReportPayload({ targetType: "bad_target" })
                )
            );
        });

        it("should deny reports with invalid reasonCode", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("reports").doc("report1").set(
                    validReportPayload({ reasonCode: "bad_reason" })
                )
            );
        });

        it("should deny reports with invalid severity", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("reports").doc("report1").set(
                    validReportPayload({ severity: "urgent" })
                )
            );
        });

        it("should deny reports with a non-pending initial status", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("reports").doc("report1").set(
                    validReportPayload({ status: "approved" })
                )
            );
        });

        it("should deny reports with details above the limit", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("reports").doc("report1").set(
                    validReportPayload({ details: "x".repeat(1001) })
                )
            );
        });

        it("should deny reports with extra fields", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("reports").doc("report1").set(
                    validReportPayload({ reviewedBy: "client1" })
                )
            );
        });

        it("should deny reports with client-controlled timestamps", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("reports").doc("report1").set(
                    validReportPayload({ createdAt: new Date("2026-05-01T12:00:00Z") })
                )
            );
        });

        it("should deny common users from updating report status", async () => {
            await seedReport();
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("reports").doc("report1").update({
                    status: "approved",
                    updatedAt: serverTimestamp(),
                })
            );
        });

        it("should deny common users from deleting reports", async () => {
            await seedReport();
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore().collection("reports").doc("report1").delete()
            );
        });

        it("should allow reporter to read their own report", async () => {
            await seedReport();
            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore().collection("reports").doc("report1").get()
            );
        });

        it("should deny another user reading someone else's report", async () => {
            await seedReport();
            const other = testEnv.authenticatedContext("client2");
            await assertFails(
                other.firestore().collection("reports").doc("report1").get()
            );
        });
    });

    describe("Trust & Safety blocked users", () => {
        function validBlockPayload(overrides = {}) {
            return {
                blockedUid: "provider1",
                createdAt: serverTimestamp(),
                reason: "Nao quero receber novas mensagens",
                source: "chat",
                ...overrides,
            };
        }

        async function seedBlock(ownerId = "client1", blockedUid = "provider1", data = {}) {
            await testEnv.withSecurityRulesDisabled(async (context) => {
                await context.firestore()
                    .collection("users")
                    .doc(ownerId)
                    .collection("blockedUsers")
                    .doc(blockedUid)
                    .set({
                        blockedUid,
                        createdAt: new Date(),
                        ...data,
                    });
            });
        }

        it("should allow an authenticated user to block another user", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore()
                    .collection("users")
                    .doc("client1")
                    .collection("blockedUsers")
                    .doc("provider1")
                    .set(validBlockPayload())
            );
        });

        it("should deny unauthenticated block creation", async () => {
            const unauth = testEnv.unauthenticatedContext();
            await assertFails(
                unauth.firestore()
                    .collection("users")
                    .doc("client1")
                    .collection("blockedUsers")
                    .doc("provider1")
                    .set(validBlockPayload())
            );
        });

        it("should deny creating a block under another user's path", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore()
                    .collection("users")
                    .doc("client2")
                    .collection("blockedUsers")
                    .doc("provider1")
                    .set(validBlockPayload())
            );
        });

        it("should deny blocks where blockedUid differs from document id", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore()
                    .collection("users")
                    .doc("client1")
                    .collection("blockedUsers")
                    .doc("provider1")
                    .set(validBlockPayload({ blockedUid: "provider2" }))
            );
        });

        it("should deny users blocking themselves", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore()
                    .collection("users")
                    .doc("client1")
                    .collection("blockedUsers")
                    .doc("client1")
                    .set(validBlockPayload({ blockedUid: "client1" }))
            );
        });

        it("should deny blocked user records with extra fields", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore()
                    .collection("users")
                    .doc("client1")
                    .collection("blockedUsers")
                    .doc("provider1")
                    .set(validBlockPayload({ moderationStatus: "hidden" }))
            );
        });

        it("should deny blocked user records with client-controlled createdAt", async () => {
            const client = testEnv.authenticatedContext("client1");
            await assertFails(
                client.firestore()
                    .collection("users")
                    .doc("client1")
                    .collection("blockedUsers")
                    .doc("provider1")
                    .set(validBlockPayload({ createdAt: new Date("2026-05-01T12:00:00Z") }))
            );
        });

        it("should allow users to read their own blocked users", async () => {
            await seedBlock();
            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore()
                    .collection("users")
                    .doc("client1")
                    .collection("blockedUsers")
                    .doc("provider1")
                    .get()
            );
        });

        it("should deny users reading another user's blocked users", async () => {
            await seedBlock();
            const other = testEnv.authenticatedContext("client2");
            await assertFails(
                other.firestore()
                    .collection("users")
                    .doc("client1")
                    .collection("blockedUsers")
                    .doc("provider1")
                    .get()
            );
        });

        it("should allow users to remove their own block", async () => {
            await seedBlock();
            const client = testEnv.authenticatedContext("client1");
            await assertSucceeds(
                client.firestore()
                    .collection("users")
                    .doc("client1")
                    .collection("blockedUsers")
                    .doc("provider1")
                    .delete()
            );
        });
    });
});
