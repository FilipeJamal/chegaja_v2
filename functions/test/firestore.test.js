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
});
