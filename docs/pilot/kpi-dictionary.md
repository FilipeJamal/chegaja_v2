# Dicionário de métricas do piloto

Todas as métricas usam apenas participantes ativos da allowlist e pedidos em que Cliente ou Prestador pertence ao piloto. Snapshots são agregados e não contêm UIDs.

| Métrica | Definição | Fonte | Decisão suportada |
|---|---|---|---|
| Primeiro trabalho pago em 30 dias | Prestadores cuja primeira conclusão com valor ocorre até 720 horas após `enrolledAt` / Prestadores ativos da coorte | `pilot_participants`, `pedidos` | Métrica central de missão e liquidez |
| Tempo até primeiro rendimento | Mediana de horas entre entrada e primeira conclusão paga | Mesmas fontes | Fricção de ativação |
| Primeira oportunidade | Prestador com pelo menos um matching/push registado | `provider_opportunities` | Cobertura de procura |
| Pedido com resposta | Pedido com Prestador atribuído ou estado aceito/em andamento/concluído | `pedidos` | Liquidez do lado Cliente |
| Taxa de conclusão | Pedidos concluídos / pedidos criados no escopo | `pedidos` | Qualidade do matching/operação |
| Valor gerado | Soma de `earningsProvider` em MZN | `pedidos` | Impacto económico real |
| GMV | Soma do valor final confirmado em MZN | `pedidos` | Escala transacionada |
| Cliente recorrente | Cliente com pelo menos dois pedidos concluídos | `pedidos` | Retenção/valor ao Cliente |
| Prestador ativo 30/90 | Prestador com conclusão nos últimos 30/90 dias | `pedidos` | Sustentabilidade da oferta |
| Comissão cobrada | Soma de recebimentos de comissão confirmados | `commission_payments` | Viabilidade do modelo cash |
| Taxa de cobrança | Comissão cobrada / comissão devida | `commission_payments`, `pedidos` | Adequação de preço/processo |
| Disputa resolvida | Denúncia/ticket operacional encerrado / abertos | `reports`, `support_tickets` | Capacidade de proteção |

## Limitações conhecidas

- “Oportunidade” mede entrega do matching, não leitura consciente pelo Prestador.
- Pagamento em dinheiro é confirmado pelas partes e pode exigir auditoria/amostragem.
- Atividade 90 dias só se torna interpretável depois de a coorte atingir essa idade.
- Os cálculos atuais limitam cada coleção a 5.000 documentos, suficiente para piloto; o backoffice mostra estes limites no payload. Antes de escala, migrar para agregações incrementais/BigQuery.
- Nenhuma destas métricas substitui entrevistas, investigação de fraude ou análise de incidentes.
