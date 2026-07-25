# ChegaJá — fonte canónica de produto, piloto e captação

Data da decisão: 2026-07-20

Última atualização de execução: 2026-07-25

Estado: programa U0–U12 ativo; U0 integrado; U1 em validação final

Responsável atual: Filipe Bento Jamal, pessoa singular e promotor do projeto

Este documento prevalece sobre o roadmap A–T e sobre os materiais de
investimento de 2026-06-06 quando existir conflito. Documentos anteriores
continuam úteis como histórico técnico, mas não devem ser usados para afirmar o
estado atual, o primeiro mercado ou o valor da ronda.

## Missão

O ChegaJá transforma competências formais e informais em oportunidades de
trabalho, rendimento independente, reputação e autonomia económica.

O produto não promete emprego formal nem rendimento garantido. A promessa que
pode ser validada é reduzir a distância entre uma competência e o primeiro
trabalho remunerado, com segurança proporcional ao risco.

## Estado verdadeiro

| Dimensão | Estado |
| --- | --- |
| Visão e missão | muito fortes |
| Produto técnico demonstrável | avançado |
| Produto público seguro | ainda não |
| Validação de mercado | ainda não realizada |
| Piloto externo | `NOT READY` |

O ChegaJá é um MVP funcional com uma missão forte, mas ainda não é uma
plataforma autorizada a operar publicamente com identidades, moradas,
documentos e dinheiro reais. Código implementado não equivale a deploy,
enforcement, aprovação jurídica, validação num aparelho físico ou tração.

## Decisão de mercado

- Primeiro piloto operacional: Coimbra, Portugal.
- Moçambique: mercado de origem e adaptação seguinte, não lançamento
  simultâneo.
- O runbook Maputo/Matola e a configuração MZN existentes são uma baseline
  histórica/técnica. Não são o plano operacional vigente.
- A mudança para Coimbra exige configuração autoritativa de mercado: país,
  zonas, limites geográficos, moeda, locale, fuso horário, telefone, legal,
  pagamentos, suporte e coorte.
- Não se deve substituir «Maputo» por «Coimbra» em texto sem adaptar estes
  contratos.

## Decisão de captação

| Campo | Valor canónico |
| --- | --- |
| Ronda anunciada | €300.000 |
| Mínimo operacional | €250.000 |
| Primeiro fecho | €150.000–€200.000 |
| Hard cap | €350.000 |
| Runway principal | 18 meses |
| Modelo financeiro | 24 meses, incluindo a ponte pós-runway |

Estes valores são uma tese de captação, não uma oferta pública nem uma
avaliação fechada. Estrutura, instrumento, fiscalidade e diluição exigem revisão
jurídica e contabilística antes de circulação externa.

Não devem ser comunicados como tração:

- documentos migrados de produção;
- contas ou pedidos legados;
- testes automatizados;
- categorias ou funcionalidades construídas;
- métricas, testemunhos ou tempos de resposta sem evidência real.

## Métrica de missão

Métrica norte:

> Percentagem de Prestadores que realizam o primeiro trabalho remunerado nos
> primeiros 30 dias após entrarem numa coorte válida.

Guardrails obrigatórios: disputas, incidentes de segurança, tempo de resolução,
cancelamentos, concentração de oportunidades, retenção de Prestadores e
Clientes, margem do Prestador e comissão efetivamente cobrada.

## Programa U0–U12

| Bloco | Objetivo | Estado em 2026-07-25 |
| --- | --- | --- |
| U0 | proteger e normalizar a base | integrado na `main` pelo PR #5 |
| U1 | Design System 2.0, navegação, flags, analytics e contratos de motores | implementação concluída; validações e integração em curso |
| U2 | descoberta e pedido adaptativos | pendente |
| U3 | matching e dispatch explicáveis | pendente |
| U4 | preço e propostas | pendente |
| U5 | execução, alterações de escopo e conclusão | pendente |
| U6 | pagamentos, carteira e reconciliação | pendente; nenhum provedor digital autorizado |
| U7 | confiança, KYC e Passaporte de Competências | pendente; KYC permanece desligado |
| U8 | segurança, suporte, garantia e substituição | pendente |
| U9 | sistema operacional do Prestador | pendente |
| U10 | retenção e crescimento | pendente |
| U11 | analytics e experimentação | pendente |
| U12 | internacionalização e adaptação africana | pendente |

## Ordem de entrega

1. U0 — auditoria, fronteiras de segurança, proveniência e baseline.
2. U1 — fundação de produto sem mudar silenciosamente os fluxos existentes.
3. U2 — experiência adaptativa por categoria e modelo de trabalho.
4. U3–U5 — matching, propostas e execução.
5. U7–U8 — confiança, Passaporte, segurança e suporte.
6. U6 — pagamentos, apenas depois dos gates legais, fiscais e operacionais.
7. U9–U12 — operação, retenção, medição e expansão.
8. Pacote de captação e data room com factos comprováveis.
9. Outreach em vagas, depois de os materiais e canais profissionais existirem.

Cada bloco usa branch e pull request próprios, feature flags desligadas por
omissão, testes de regressão Cliente/Prestador e CI verde. Não há deploy de
produção implícito no merge.

## Gates que o código não pode fechar sozinho

- email profissional e contactos jurídicos reais;
- morada oficial adequada para os documentos legais;
- revisão por advogado e contabilista;
- constituição/forma jurídica quando necessária;
- liderança técnica humana e plano de contratação executável;
- Android físico API 33+;
- corte produtivo e enforcement App Check;
- integração contratual e técnica de pagamentos;
- recrutamento, consentimento e execução de coorte real;
- entrevistas, manifestações de interesse e métricas de mercado;
- gravação de vídeo real e envio de mensagens a investidores.

Templates e código podem preparar estes gates, mas nunca os podem marcar como
aprovados sem a ação e a prova externas correspondentes.

## Regra de integridade competitiva

O objetivo é construir uma experiência superior às alternativas relevantes,
mas o repositório não pode afirmar liderança de mercado. Essa conclusão só pode
vir de comparação verificável e resultados de piloto: tempo até primeira
resposta/rendimento, conclusão, recorrência, segurança, satisfação e economia
unitária.

## Documentos históricos

- `docs/ROADMAP_A_T_CHEGAJA.md`: histórico de construção A–T.
- `docs/pilot/maputo-pilot-runbook.md`: baseline operacional Maputo/Matola.
- `docs/investor/P0_*`: pacote de 2026-06-06, desatualizado.
- `docs/pilot/p1-completion-audit.md`: auditoria técnica P1, sujeita a
  proveniência exata dos fontes e aos gates externos.
