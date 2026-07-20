const assert = require("assert");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "chegaja-ac88d";

const functions = require("../index");

describe("Avaliacao rating aggregate Function", () => {
    const {
        onAvaliacaoCreatedCore,
    } = functions.__test__.avaliacoes;

    function createFakeDatabase(initialData = {}) {
        const store = new Map(Object.entries(initialData));

        function clone(data) {
            return data ? { ...data } : data;
        }

        return {
            store,
            collection(name) {
                return {
                    doc(id) {
                        return { path: `${name}/${id}` };
                    },
                };
            },
            async runTransaction(callback) {
                const tx = {
                    async get(ref) {
                        const data = store.get(ref.path);
                        return {
                            exists: data !== undefined,
                            data: () => clone(data),
                        };
                    },
                    set(ref, data, options = {}) {
                        const previous = options.merge ? (store.get(ref.path) || {}) : {};
                        store.set(ref.path, { ...previous, ...clone(data) });
                    },
                };
                return callback(tx);
            },
        };
    }

    function pedido(data = {}) {
        return {
            clienteId: "client1",
            prestadorId: "provider1",
            status: "concluido",
            estado: "concluido",
            createdAt: new Date(),
            ...data,
        };
    }

    function prestador(data = {}) {
        return {
            nome: "Prestador Teste",
            ratingCount: 0,
            ratingSum: 0,
            ratingAvg: 0,
            ...data,
        };
    }

    it("updates provider rating aggregates for a valid review", async () => {
        const fakeDb = createFakeDatabase({
            "provider_public/provider1": prestador(),
            "pedidos/order_rating_1": pedido(),
        });

        const result = await onAvaliacaoCreatedCore({
            database: fakeDb,
            avaliacaoId: "order_rating_1_client1",
            avaliacao: {
                pedidoId: "order_rating_1",
                clienteId: "client1",
                prestadorId: "provider1",
                estrelas: 5,
            },
        });

        const provider = fakeDb.store.get("provider_public/provider1");
        assert.strictEqual(result.updated, true);
        assert.strictEqual(provider.ratingCount, 1);
        assert.strictEqual(provider.ratingSum, 5);
        assert.strictEqual(provider.ratingAvg, 5);
    });

    it("recalculates average when another valid review is added", async () => {
        const fakeDb = createFakeDatabase({
            "provider_public/provider1": prestador({
                ratingCount: 1,
                ratingSum: 5,
                ratingAvg: 5,
            }),
            "pedidos/order_rating_2": pedido({
                clienteId: "client2",
            }),
        });

        const result = await onAvaliacaoCreatedCore({
            database: fakeDb,
            avaliacaoId: "order_rating_2_client2",
            avaliacao: {
                pedidoId: "order_rating_2",
                clienteId: "client2",
                prestadorId: "provider1",
                estrelas: 3,
            },
        });

        const provider = fakeDb.store.get("provider_public/provider1");
        assert.strictEqual(result.updated, true);
        assert.strictEqual(provider.ratingCount, 2);
        assert.strictEqual(provider.ratingSum, 8);
        assert.strictEqual(provider.ratingAvg, 4);
    });

    it("does not update aggregates for invalid ratings", async () => {
        const fakeDb = createFakeDatabase({
            "provider_public/provider1": prestador(),
            "pedidos/order_rating_invalid": pedido(),
        });

        const result = await onAvaliacaoCreatedCore({
            database: fakeDb,
            avaliacaoId: "order_rating_invalid_client1",
            avaliacao: {
                pedidoId: "order_rating_invalid",
                clienteId: "client1",
                prestadorId: "provider1",
                estrelas: 6,
            },
        });

        const provider = fakeDb.store.get("provider_public/provider1");
        assert.strictEqual(result.updated, false);
        assert.strictEqual(provider.ratingCount, 0);
        assert.strictEqual(provider.ratingSum, 0);
        assert.strictEqual(provider.ratingAvg, 0);
    });

    it("does not update aggregates when review document id does not match order and client", async () => {
        const fakeDb = createFakeDatabase({
            "provider_public/provider1": prestador(),
            "pedidos/order_rating_wrong_id": pedido(),
        });

        const result = await onAvaliacaoCreatedCore({
            database: fakeDb,
            avaliacaoId: "wrong_id",
            avaliacao: {
                pedidoId: "order_rating_wrong_id",
                clienteId: "client1",
                prestadorId: "provider1",
                estrelas: 5,
            },
        });

        const provider = fakeDb.store.get("provider_public/provider1");
        assert.strictEqual(result.updated, false);
        assert.strictEqual(provider.ratingCount, 0);
        assert.strictEqual(provider.ratingSum, 0);
        assert.strictEqual(provider.ratingAvg, 0);
    });
});
