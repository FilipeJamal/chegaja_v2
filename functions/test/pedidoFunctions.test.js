const assert = require("assert");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "chegaja-ac88d";

const functions = require("../index");

describe("Pedido value Functions", () => {
    const db = functions.__test__.db;
    const {
        confirmarValorFinalPedidoCore,
        proporValorFinalPedidoCore,
    } = functions.__test__.pedidos;

    async function clearPedidos() {
        const snap = await db.collection("pedidos").get();
        const batch = db.batch();
        snap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
    }

    async function seedPedido(id, data = {}) {
        await db.collection("pedidos").doc(id).set({
            clienteId: "client1",
            prestadorId: "provider1",
            status: "em_andamento",
            estado: "em_andamento",
            createdAt: new Date(),
            historico: [],
            ...data,
        });
    }

    beforeEach(async () => {
        await clearPedidos();
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
        assert.strictEqual(pedido.commissionPlatform, 15);
        assert.strictEqual(pedido.earningsProvider, 85);
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
