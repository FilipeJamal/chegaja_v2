# U1 — Flags, analytics e contratos de motores

Data: 2026-07-24

## Feature flags

O contrato tipado declara 22 capacidades desde a base P1 até U12.

Regras:

1. todos os valores remotos começam desligados;
2. kill switch global ou individual tem precedência absoluta;
3. uma capacidade protegida precisa, conforme o risco, de gate local, valor
   remoto, capacidade de backend e suporte da plataforma;
4. ausência não significa autorização;
5. snapshots incompatíveis falham fechados;
6. snapshots antigos falham fechados em capacidades sensíveis ou críticas;
7. alterações podem ser observadas sem acoplar a UI diretamente ao Firebase.

O ficheiro `remoteconfig.template.json` é apenas um template versionado. Não é
prova de publicação nem altera o Remote Config de produção.

Para QA visual local existe o define `U1_PREVIEW=true`. Ele só é considerado
num build não-release (`debug` ou `profile`); builds `release` ignoram-no. A
captura deve também usar
`FAST_DEV_MODE=true` para impedir que um fetch remoto substitua o snapshot de
pré-visualização. Este caminho não ativa flags de risco.

### Capacidades críticas mantidas fechadas

- KYC;
- Stripe, M-Pesa e e-Mola;
- subscrições;
- Windows público;
- motores U3–U8 que dependem de decisões autoritativas;
- analytics/experimentação U11;
- internacionalização operacional U12.

O backend não fornece aprovações por omissão. Mesmo que uma variável local seja
ativada, a capacidade continua fechada quando o contrato exige autorização
server-side.

## Analytics base

`AnalyticsService` aceita apenas `AnalyticsEvent` tipado e usa
`NoOpAnalyticsSink` por omissão.

Os SDKs `firebase_analytics`, `firebase_crashlytics` e
`firebase_performance` não fazem parte da aplicação U1. A aplicação também
mantém desligadas, nos manifestos Android e Apple, as chaves de recolha nativa
de Analytics, identificadores publicitários, Crashlytics e Performance. Não há
handlers Dart a encaminhar erros para Crashlytics.

Esta defesa em profundidade impede recolha automática nativa antes de
consentimento, incluindo eventos que não passariam pelo sink Dart. O U11 só
poderá reintroduzir um SDK ou sink externo com consentimento, retenção,
configuração nativa fail-closed, configuração de mercado e gates aprovados.

Dimensões permitidas:

- mercado e país;
- idioma;
- plataforma;
- versão e canal;
- papel;
- modo do serviço;
- tipo de preço;
- estado agregado;
- resultado;
- versão do schema.

São rejeitados por desenho:

- UID, ID de pedido, ID de sessão ou dispositivo;
- nome, telefone, email ou morada;
- coordenadas;
- URL;
- descrição, pesquisa ou outro texto livre.

A ponte temporária `logPedidoEvent` mantém os chamadores existentes
compatíveis, mas descarta `pedidoId` antes do sink. Falhas de analytics nunca
interrompem o fluxo do produto.

O U1 não ativa recolha real. A ausência dos três SDKs e as chaves nativas
desligadas são verificadas por teste de contrato; qualquer reintrodução exige
uma alteração explícita e revista.

## Contrato comum dos motores

Versão: `u1.1`

Todo input recebe `EngineExecutionContext`, composto por:

- mercado (`pt-coimbra` no primeiro piloto);
- país;
- moeda;
- locale;
- fuso horário;
- instante UTC;
- `correlationId` opaco e obrigatório para ligar decisão, auditoria e
  observabilidade sem expor PII;
- versão do contrato.

Toda decisão devolve:

- estado;
- valor tipado;
- versão do motor;
- `reasonCodes` estáveis;
- evento de auditoria tipado com o mesmo `correlationId`;
- instante UTC de avaliação;
- versão do contrato.

Transições de trabalho e operações de pagamento exigem ainda uma
`idempotencyKey` explícita. Repetir a mesma intenção não pode criar duas
transições ou dois movimentos financeiros.

## Onze portas

| Porta | Método | Fase que implementará a lógica |
| --- | --- | --- |
| `ServiceIntentEnginePort` | `classify` | U2 |
| `RequestScopingEnginePort` | `scope` | U2 |
| `MatchingEnginePort` | `match` | U3 |
| `PricingEnginePort` | `price` | U4 |
| `TrustPolicyEnginePort` | `evaluate` | U7 |
| `JobOrchestratorPort` | `transition` | U5 |
| `PaymentOrchestratorPort` | `process` | U6 |
| `ReputationEnginePort` | `evaluate` | U7 |
| `SupportCaseEnginePort` | `route` | U8 |
| `GrowthEnginePort` | `recommend` | U10 |
| `AnalyticsEnginePort` | `ingest` | U11 |

O U1 define contratos, estados, inputs, outputs e códigos de razão. Não
implementa algoritmos, não escreve no Firebase e não autoriza decisões
financeiras ou de confiança.

## Compatibilidade

- modelos atuais continuam compiláveis;
- adapters explícitos convertem modos de serviço e estados de trabalho
  históricos para os enums U1, com round-trip testado;
- a ponte antiga de analytics permanece disponível e sanitizada;
- IDs de referência dos motores são opacos e não entram em analytics;
- `pt-coimbra` e `mz-maputo` usam o mesmo formato canónico de mercado;
- mudanças futuras devem ser aditivas ou exigir nova versão de contrato.

## Testes

Os testes verificam:

- defaults e template sincronizados;
- precedência de gates e kill switches;
- snapshots incompatíveis e antigos;
- Remote Config injetável sem Firebase real;
- rejeição de PII e identificadores;
- isolamento de falhas do sink;
- imutabilidade de eventos e decisões;
- unicidade e round-trip dos `reasonCodes`;
- correlação obrigatória entre contexto e evento de auditoria;
- idempotência obrigatória nos contratos críticos de trabalho e pagamento;
- round-trip dos adapters legados;
- existência independente das onze portas;
- contexto de mercado obrigatório em todos os inputs.
