# Evidência dos gates externos

Esta pasta define os artefactos esperados, mas não contém aprovações fictícias.
Os modelos em `templates/` falham deliberadamente o readiness checker até
serem substituídos por evidência real.

- `legal-approval.md`: entidade, revisor, data, versão jurídica e referência
  de aprovação reais.
- `p1-cutover-migration.json`: prova não dry-run da janela real de corte, com
  writes congelados, migração concluída sem deletes ou campos públicos
  sensíveis, reconciliação de grants de Prestador, Storage privado sem tokens
  persistentes, índices Firestore obrigatórios em `READY`, deploy concluído e
  hashes atuais de Rules e Functions. A prova tem de ter estado `COMPLETED`.
- `firebase-app-check-enforcement.json`: estado `ENFORCED` de Firestore,
  Storage e Authentication, mais referência do deploy das callable Functions
  que usam `enforceAppCheck`. A prova tem de corresponder ao SHA-256 da APK,
  das Rules e dos fontes completos de Functions, e referenciar a mesma janela,
  migração e deploy do cutover. Do congelamento de writes ao enforcement não
  podem decorrer mais de 24 horas.
- `firebase-account-deletion-secret.json`: apenas metadados do segredo de
  eliminação ativo; o valor nunca é exportado ou guardado.
- `android-physical-validation.json`: aparelho físico API 33+, SHA-256 exato da
  APK e os 12 casos obrigatórios aprovados.
- `real-pilot-execution.json`: coorte, datas, versão da APK e métricas apenas
  agregadas; nunca nomes, telefones, emails, moradas, documentos, tokens ou
  identificadores de participantes.

## Contrato de proveniência v3

Screenshot, XML de acessibilidade, logcat redigido e atestação da APK usados
pelo gate Android ficam versionados em
`docs/android/evidence/u0-2026-07-21/`. O JSON de runtime guarda o SHA-256 do
log e o checker rejeita a prova se o conteúdo contiver qualquer padrão fatal
declarado. Os equivalentes em `build/` são apenas a origem local ignorada e
nunca a única prova aceite.

Os JSON de cutover e App Check usam `p1-deployment-evidence-v4`; Android físico
e piloto real usam os respetivos schemas `v2`. Os schemas são fechados: campos
desconhecidos, chaves de PII disfarçadas e valores de exemplo fazem o gate
falhar.

O cutover inclui `pedido-grant-reconciliation-v1`. A execução final tem de ser
real, não dry-run, sem deletes, com todas as contagens inteiras e coerentes,
`scanned > 0`, `collectionTotalObserved` igual a `scanned`, SHA-256 do output
redigido, `manualReview: 0` e `inconsistentAfter: 0`. O comando de migração
nunca deve ser executado a partir de um checkout diferente do commit registado
na prova.

O mesmo ficheiro inclui `firestore-index-deployment-v3`. O `projectId` tem de
ser o projeto produtivo, `manifestSha256` tem de corresponder byte a byte ao
`firestore.indexes.json` versionado e a verificação tem de ocorrer depois do
deploy dentro da janela de cutover. A lista `declaredIndexes` deve ser copiada
da verificação cloud e corresponder um-a-um a **todos** os índices compostos do
manifesto: a mesma quantidade, as mesmas definições, nenhum duplicado, omissão
ou índice extra, e estado `READY` em cada entrada. A lista
`declaredFieldOverrides` tem os mesmos requisitos para cada configuração de
campo do manifesto, incluindo políticas TTL, e
`allDeclaredFieldOverridesReady` tem de ser verdadeiro. Isto inclui obrigatoriamente
o índice de grants de `pedidos`, com `status` e
`providerAccessGrantedAt`. Qualquer estado como `BUILDING` faz o gate falhar.

A prova de índices também referencia um artefacto JSON redigido em
`docs/pilot/evidence/audits/`, obtido da saída real de
`gcloud firestore indexes composite list --project=chegaja-ac88d --format=json`
e `gcloud firestore fields list --project=chegaja-ac88d --format=json`.
O envelope usa `firestore-index-cloud-output-v2`, repete exatamente o
`projectId`, o `checkedAt` e a lista com os estados observados, e declara
`redacted: true` e `containsParticipantIdentifiers: false`. O readiness lê o
ficheiro (ou o conteúdo injetado nos testes), recalcula o SHA-256 dos bytes e
exige igualdade integral entre artefacto, atestação e manifesto. Não se deve
preencher a prova antes de executar o comando contra o projeto produtivo.

O cutover inclui também `p1-effective-backend-config-v1`, ligado ao mesmo
projeto, número e commit Git. O manifesto guarda somente a allowlist
obrigatória, flags backend de KYC/pagamentos desligadas, referências de versão
da configuração e nomes/números de versão dos Secrets ativos. Valores de
Secrets, configuração livre, caminhos locais, participantes e PII nunca
pertencem ao manifesto. O SHA-256 é calculado sobre JSON canónico.

Cada gate operacional referencia um artefacto redigido em
`docs/pilot/evidence/audits/`. O artefacto usa `p1-provider-audit-v1`, guarda a
referência do log/operação do sistema de origem e tem SHA-256 conferido pelo
readiness. Um JSON de conclusão sem o ficheiro auditável correspondente não é
aceite.

Todos os instantes operacionais são timestamps UTC reais, não futuros e
cronologicamente estritos. A janela de cutover continua limitada a 24 horas. O
piloto real exige pelo menos 30 dias, oportunidades, trabalhos, pedidos e valor
gerado não nulos, percentagem matematicamente coerente e contagens que não
ultrapassem a coorte ou os pedidos publicados.

Copiar o modelo apropriado, retirar o sufixo `.example` e preencher apenas
depois da ação externa acontecer. Executar:

```text
npm run p1:pilot:readiness:strict
```

O piloto permanece **NOT READY** se um ficheiro estiver ausente, malformado,
incompleto, tiver placeholders ou não corresponder à APK release e à prova de
cutover atuais.
