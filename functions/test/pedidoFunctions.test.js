const assert = require("assert");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "chegaja-ac88d";
const originalCommissionEnv = {
    DEFAULT_CASH_COMMISSION_RATE: process.env.DEFAULT_CASH_COMMISSION_RATE,
    COMMISSION_FREE_FIRST_JOBS: process.env.COMMISSION_FREE_FIRST_JOBS,
    DEFAULT_CURRENCY_CODE: process.env.DEFAULT_CURRENCY_CODE,
};
process.env.DEFAULT_CASH_COMMISSION_RATE = "0.10";
process.env.COMMISSION_FREE_FIRST_JOBS = "2";
process.env.DEFAULT_CURRENCY_CODE = "MZN";

const functions = require("../index");

describe("Pedido value Functions", () => {
    const db = functions.__test__.getDb();
    const {
        acceptPedidoDispatchCore,
        confirmarValorFinalPedidoCore,
        proporValorFinalPedidoCore,
    } = functions.__test__.pedidos;
    const {
        enforceCommissionDebtCore,
        recordCommissionPaymentCore,
    } = functions.__test__.payments;
    const legalVersion = functions.__test__.legal.LEGAL_DOCUMENT_VERSION;

    async function clearPedidos() {
        const snap = await db.collection("pedidos").get();
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        const providerSnap = await db.collection("provider_private").get();
        providerSnap.docs.forEach((doc) => batch.delete(doc.ref));
        for (const collection of ["provider_public", "provider_dispatch_private", "provider_opportunities", "provider_acceptance_limits", "payments", "commission_payments", "pilot_participants", "users_private"]) {
            const collectionSnap = await db.collection(collection).get();
            collectionSnap.docs.forEach((doc) => batch.delete(doc.ref));
        }
        await batch.commit();
    }

    async function seedPedido(id, data = {}) {
        await db.collection("provider_private").doc("provider1").set({
            providerId: "provider1",
            completedJobsCount: 0,
            commissionBalanceDue: 0,
            financialStatus: "active",
        }, { merge: true });
        await db.collection("pedidos").doc(id).set({
            clienteId: "client1",
            prestadorId: "provider1",
            providerAccessGranted: true,
            providerAccessGrantedTo: "provider1",
            providerAccessGrantedAt: new Date(),
            status: "em_andamento",
            estado: "em_andamento",
            createdAt: new Date(),
            historico: [],
            ...data,
        });
    }

    beforeEach(async () => {
        // Other suites deliberately exercise missing payment configuration and
        // restore their own environment. Reassert this suite's explicit pilot
        // policy so results never depend on Mocha file loading order.
        process.env.DEFAULT_CASH_COMMISSION_RATE = "0.10";
        process.env.COMMISSION_FREE_FIRST_JOBS = "2";
        process.env.DEFAULT_CURRENCY_CODE = "MZN";
        await clearPedidos();
    });

    after(() => {
        for (const [key, value] of Object.entries(originalCommissionEnv)) {
            if (value === undefined) delete process.env[key];
            else process.env[key] = value;
        }
    });

    it("allows assigned provider to propose final value", async () => {
        await seedPedido("order_propose_ok");

        await proporValorFinalPedidoCore({
            db,
            uid: "provider1",
            data: {
                pedidoId: "order_propose_ok",
                valorFinal: 100,
                comentario: "Servico terminado",
            },
        });

        const snap = await db.collection("pedidos").doc("order_propose_ok").get();
        const pedido = snap.data();

        assert.strictEqual(pedido.status, "aguarda_confirmacao_valor");
        assert.strictEqual(pedido.estado, "aguarda_confirmacao_valor");
        assert.strictEqual(pedido.statusConfirmacaoValor, "pendente_cliente");
        assert.strictEqual(pedido.precoPropostoPrestador, 100);
        assert.strictEqual(pedido.mensagemPropostaPrestador, "Servico terminado");
    });

    it("blocks another provider from proposing final value", async () => {
        await seedPedido("order_propose_wrong_provider");

        await assert.rejects(
            () => proporValorFinalPedidoCore({
                db,
                uid: "provider2",
                data: {
                    pedidoId: "order_propose_wrong_provider",
                    valorFinal: 100,
                },
            }),
            (err) => err.code === "permission-denied"
        );
    });

    it("allows client to confirm final value and calculates split server-side", async () => {
        await seedPedido("order_confirm_ok", {
            status: "aguarda_confirmacao_valor",
            estado: "aguarda_confirmacao_valor",
            precoPropostoPrestador: 100,
            statusConfirmacaoValor: "pendente_cliente",
        });

        await confirmarValorFinalPedidoCore({
            db,
            uid: "client1",
            data: {
                pedidoId: "order_confirm_ok",
                commissionPlatform: 0,
                earningsProvider: 999,
            },
        });

        const snap = await db.collection("pedidos").doc("order_confirm_ok").get();
        const pedido = snap.data();

        assert.strictEqual(pedido.status, "concluido");
        assert.strictEqual(pedido.estado, "concluido");
        assert.strictEqual(pedido.statusConfirmacaoValor, "confirmado_cliente");
        assert.strictEqual(pedido.precoFinal, 100);
        assert.strictEqual(pedido.preco, 100);
        assert.strictEqual(pedido.earningsTotal, 100);
        assert.strictEqual(pedido.commissionPlatform, 0);
        assert.strictEqual(pedido.earningsProvider, 100);
        assert.strictEqual(pedido.currency, "MZN");

        const provider = (await db.collection("provider_private").doc("provider1").get()).data();
        assert.strictEqual(provider.completedJobsCount, 1);
        assert.strictEqual(provider.commissionBalanceDue, 0);
        assert.strictEqual(provider.financialStatus, "active");
    });

    it("charges the configured cash commission after the two pilot-free jobs", async () => {
        await seedPedido("order_confirm_commission", {
            status: "aguarda_confirmacao_valor",
            estado: "aguarda_confirmacao_valor",
            precoPropostoPrestador: 1000,
            statusConfirmacaoValor: "pendente_cliente",
            tipoPagamento: "dinheiro",
        });
        await db.collection("provider_private").doc("provider1").set({
            completedJobsCount: 2,
        }, { merge: true });

        await confirmarValorFinalPedidoCore({
            db,
            uid: "client1",
            data: { pedidoId: "order_confirm_commission" },
        });

        const pedido = (await db.collection("pedidos").doc("order_confirm_commission").get()).data();
        const provider = (await db.collection("provider_private").doc("provider1").get()).data();
        const payment = (await db.collection("payments").doc("cash_order_confirm_commission").get()).data();
        assert.strictEqual(pedido.commissionPlatform, 100);
        assert.strictEqual(pedido.earningsProvider, 900);
        assert.strictEqual(provider.commissionBalanceDue, 100);
        assert.strictEqual(provider.financialBalance, -100);
        assert.strictEqual(provider.financialStatus, "payment_due");
        assert.strictEqual(payment.method, "cash");
        assert.strictEqual(payment.status, "commission_due");
    });

    it("suspends only new work after the commission deadline and restores it after payment", async () => {
        await db.collection("provider_private").doc("provider1").set({
            providerId: "provider1",
            commissionBalanceDue: 75,
            financialBalance: -75,
            financialStatus: "payment_due",
            commissionDueAt: new Date(Date.now() - 60_000),
        });
        await db.collection("provider_dispatch_private").doc("provider1").set({
            providerId: "provider1",
            acceptingNewJobs: true,
        });

        const enforcement = await enforceCommissionDebtCore({ database: db });
        assert.strictEqual(enforcement.suspended, 1);
        let provider = (await db.collection("provider_private").doc("provider1").get()).data();
        let dispatch = (await db.collection("provider_dispatch_private").doc("provider1").get()).data();
        assert.strictEqual(provider.financialStatus, "suspended_new_jobs");
        assert.strictEqual(dispatch.acceptingNewJobs, false);

        await recordCommissionPaymentCore({
            database: db,
            auth: { uid: "admin1", token: { admin: true } },
            data: { providerId: "provider1", amount: 75, reference: "MPESA-TEST-001" },
        });
        provider = (await db.collection("provider_private").doc("provider1").get()).data();
        dispatch = (await db.collection("provider_dispatch_private").doc("provider1").get()).data();
        assert.strictEqual(provider.commissionBalanceDue, 0);
        assert.strictEqual(provider.financialStatus, "active");
        assert.strictEqual(dispatch.acceptingNewJobs, true);
    });

    it("prevents a financially suspended provider from accepting a request", async () => {
        await Promise.all([
            db.collection("users_private").doc("provider1").set({
                accountStatus: "active",
                legalConsent: {
                    version: legalVersion,
                    termsAccepted: true,
                    privacyAccepted: true,
                    ageConfirmed: true,
                },
            }),
            db.collection("pilot_participants").doc("provider1").set({
                status: "active",
                roles: ["prestador"],
                city: "Maputo",
            }),
        ]);
        await db.collection("provider_public").doc("provider1").set({
            uid: "provider1",
            servicos: ["plumbing"],
            isSearchable: true,
        });
        await db.collection("provider_private").doc("provider1").set({
            providerId: "provider1",
            financialStatus: "suspended_new_jobs",
        });
        await db.collection("provider_dispatch_private").doc("provider1").set({
            providerId: "provider1",
            acceptingNewJobs: true,
            isOnline: true,
        });
        await db.collection("pedidos").doc("blocked_accept").set({
            clienteId: "client1",
            prestadorId: null,
            servicoId: "plumbing",
            status: "criado",
            estado: "criado",
            moderationStatus: "approved",
        });
        await db.collection("provider_opportunities").doc("blocked_accept_provider1").set({
            pedidoId: "blocked_accept",
            providerId: "provider1",
            approximateDistanceKm: 1,
            matchedRadiusKm: 10,
            status: "active",
            expiresAt: new Date(Date.now() + 15 * 60 * 1000),
        });

        await assert.rejects(
            () => acceptPedidoDispatchCore({
                database: db,
                auth: { uid: "provider1", token: { phone_number: "+258840000000" } },
                pedidoId: "blocked_accept",
            }),
            (err) => err.code === "failed-precondition"
        );
    });

    it("blocks non-client confirmation", async () => {
        await seedPedido("order_confirm_wrong_user", {
            status: "aguarda_confirmacao_valor",
            estado: "aguarda_confirmacao_valor",
            precoPropostoPrestador: 100,
            statusConfirmacaoValor: "pendente_cliente",
        });

        await assert.rejects(
            () => confirmarValorFinalPedidoCore({
                db,
                uid: "provider1",
                data: { pedidoId: "order_confirm_wrong_user" },
            }),
            (err) => err.code === "permission-denied"
        );
    });

    it("blocks confirmation outside pending final value state", async () => {
        await seedPedido("order_confirm_bad_state", {
            status: "cancelado",
            estado: "cancelado",
            precoPropostoPrestador: 100,
            statusConfirmacaoValor: "pendente_cliente",
        });

        await assert.rejects(
            () => confirmarValorFinalPedidoCore({
                db,
                uid: "client1",
                data: { pedidoId: "order_confirm_bad_state" },
            }),
            (err) => err.code === "failed-precondition"
        );
    });
});
