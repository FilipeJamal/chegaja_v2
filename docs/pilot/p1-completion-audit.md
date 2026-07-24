# Auditoria consolidada P1

Data: 2026-07-20
Projeto Firebase: `chegaja-ac88d`
Decisão atual: **NOT READY para piloto externo**

## Correção U0 de 2026-07-20

Uma auditoria posterior encontrou caminhos Firestore/Storage que não exigiam
simultaneamente telefone confirmado e pertença ativa à coorte, além de uma
prévia client-side de comissão divergente da política server-side. A branch U0
corrige esses contratos e acrescenta testes negativos. Encontrou também que os
hashes da preparação produtiva não correspondem aos fontes atuais.

A mesma revisão tornou anexos partilhados imutáveis para participantes e
passou a calcular hashes textuais de forma canónica entre sistemas operativos.
O fingerprint de Functions inclui também os manifests de dependências. O
comando `npm run p1:source:hashes` apenas imprime estes hashes; não substitui a
repetição da migração nem aprova o cutover.

Consequentemente, «implementação concluída» abaixo significa apenas que existe
uma implementação local em validação. A prova produtiva anterior não pode ser
reutilizada no cutover; deve ser regenerada sobre o commit exato aprovado.
O readiness só aceita a nova prova real
`docs/pilot/evidence/p1-cutover-migration.json`; o ficheiro de exemplo permanece
inválido e a ausência da prova mantém o gate fechado.

Esta auditoria P1 foi originalmente executada para a baseline Maputo/MZN. A
decisão posterior é Coimbra/Portugal como primeiro piloto operacional. Por isso,
as referências a Maputo, MZN e integração local abaixo são evidência histórica,
não o plano de lançamento vigente. A adaptação Coimbra/EUR requer os contratos
de mercado definidos em
`docs/product/MARKET_LEADERSHIP_SOURCE_OF_TRUTH.md`; não pode ser feita por mera
substituição de texto.

## Resultado executivo

As dez frentes P1 têm implementação técnica e procedimentos de operação para a
baseline histórica Maputo/MZN. A
preparação produtiva segura já inclui migração aditiva, catálogo server-side,
TTL, segredo de eliminação, identificador Android final e configuração Play
Integrity para distribuição fora da Play Store. O promotor individual também
está identificado sem apresentar o projeto como empresa constituída. O P1
operacional ainda não está fechado e não constitui readiness de Coimbra:
faltam completar os contactos jurídicos,
obter validação jurídica, validar um aparelho físico, aplicar enforcement App
Check e executar o piloto real.

Não foi feito deploy das Rules e Functions P1. A produção contém 86 utilizadores,
42 prestadores e 29 pedidos no modelo legado; as Rules novas fecham totalmente
essas coleções. Publicá-las antes de distribuir a APK final e preparar o corte
interromperia clientes existentes. Essa interrupção exige uma janela de
manutenção deliberada, não pode ser inferida silenciosamente.

## Estado por frente

| Frente | Implementação | Produção/operação | Evidência principal |
|---|---|---|---|
| P1.1 Dados públicos/privados | Concluída | Migração aditiva executada; corte de Rules pendente | `p1-production-preparation-2026-07-20.json` |
| P1.2 Pedidos/localização | Concluída | Projeção sanitizada testada; deploy pendente | `pedidoDispatch.test.js`, `p1DataBoundaries.test.js` |
| P1.3 Phone Auth | Concluída | Migração anónima implementada; prova em número real depende do aparelho | `phone_verification_screen.dart`, testes de auth |
| P1.4 KYC seguro | Concluída e desligada | Continua indisponível no piloto até aprovação própria | `kyc.test.js`, `storage.test.js` |
| P1.5 Catálogo/Trust & Safety | Concluída | 55 políticas semeadas, 11 sujeitas a aprovação adicional | `pedidoSafety.test.js` |
| P1.6 Endpoints/quotas/App Check | Concluída no código | TTL ativo e Play Integrity preparado; enforcement/deploy pendente | `firebase-app-check-status-2026-07-20.json` |
| P1.7 Pagamentos/MZN (baseline histórica) | Concluída | Dinheiro habilitado; M-Pesa, e-Mola e Stripe continuam desligados; EUR/Portugal ainda não adaptado | `paymentPolicy.test.js` |
| P1.8 Android/permissões | APK e emulador concluídos | Matriz em Android físico pendente | `p1-8-physical-device-validation.md` |
| P1.9 Legal/eliminação/suporte | Concluída no código | Promotor confirmado; email, morada e parecer jurídico pendentes | `docs/legal/operator-identity.md`, `firebase-account-deletion-secret.json` |
| P1.10 Piloto Maputo (baseline histórica) | Produto, backoffice e runbooks concluídos | Não executar como piloto vigente; Coimbra requer runbook próprio e continua pendente | `maputo-pilot-runbook.md` |

## Produção preparada sem exposição adicional

- Migração aditiva executada: 86 `public_profiles`, 86 `users_private`, 42
  `provider_public`, 42 `provider_private` e 42 `provider_dispatch_private`.
- Zero documentos públicos com nomes de campos sensíveis proibidos na
  verificação pós-migração.
- Storage migrado: 3 fotos referenciadas foram movidas para `profile_public`,
  16 objetos sem referência foram isolados em quarentena privada e todos os
  tokens persistentes de áreas não públicas foram removidos. A quarentena tem
  eliminação automática aos 30 dias.
- Nenhum documento legado foi apagado.
- As coleções novas permanecem negadas por omissão nas Rules produtivas atuais.
- O catálogo produtivo contém 55 políticas e 8 requisitos distintos para as 11
  profissões que exigem análise adicional.
- TTL `ACTIVE` para `endpoint_rate_limits.expiresAt` e
  `kyc_upload_grants.expiresAt`.
- `ACCOUNT_DELETION_PEPPER` versão 2 está ativo no Secret Manager; a versão 1
  inválida foi destruída e nenhum valor foi guardado no repositório.
- Firebase Admin 14 modular e dependências do runtime das Functions com zero
  vulnerabilidades conhecidas no `npm audit`.

## Provas técnicas

- Flutter: **522 testes aprovados** em 105 ficheiros.
- Análise estática Dart/Flutter: **0 erros** e **328 avisos/informações não
  fatais**; permanecem visíveis no CI.
- Functions/Firestore/Storage: **167 testes aprovados** em 24 ficheiros; o emulador carregou as
  63 definições locais sem erro de descoberta.
- Scripts operacionais: **14 grupos de testes aprovados**.
- APK release: 123090808 bytes, assinatura v2, um signatário RSA 2048.
- SHA-256 APK:
  `e2be3d862ce6af3f6289b4dc2a84195bd54f0ba1bb0e83c08d5d7e0557503fa6`.
- Fingerprint de release `android-release-inputs-v2`, calculado sobre 470
  ficheiros e 1 entrada virtual:
  `d1e757c6d191a6a2b7a8d8afb99b38768985fde672668460ec9a85c510fd4356`.
- Emulador temporário Android 15/API 35 x86_64: instalação confirmada pelo
  Package Manager após timeout do cliente `adb install`, atividade em primeiro
  plano, processo vivo depois de scroll, seletor limpo em português e zero
  padrões fatais. Duas mensagens de ciclo de vida do Geolocator e quatro probes
  DEBUG de frameworks opcionais foram preservadas como diagnósticos não fatais.
- Identidade Android: `com.chegaja.app`, app Firebase
  `1:767588494857:android:4198384a2a6387055252d8`, certificados release/debug
  registados e App Links ligados ao certificado release.
- Readiness técnico histórico Maputo/MZN: **9/15 gates aprovados** após a nova
  prova de runtime e o endurecimento da validação de proveniência; os seis gates
  externos continuam fechados. Este número não é readiness operacional de
  Coimbra.

## Gate fechado nesta etapa

O identificador Android deixou de ser um bloqueio: `namespace`, `applicationId`,
`MainActivity`, FlutterFire, Firebase, App Links, APK e evidência de emulador
estão alinhados em `com.chegaja.app`. A app Firebase de produção tem as
fingerprints SHA-1/SHA-256 verificadas das chaves release e debug. Os clientes
Firebase antigos permanecem apenas para compatibilidade e não são a identidade
da APK final.

## Progresso de identidade nesta etapa

O responsável atual é **Filipe Bento Jamal**, como pessoa singular e promotor
do projeto ChegaJá. A app e os documentos deixaram de sugerir uma entidade
provisória ou uma empresa inexistente. NUIT/NIF pessoais não foram colocados no
repositório por minimização de dados e porque a natureza dos números deve ser
confirmada privadamente antes de qualquer uso jurídico ou fiscal. A versão de
consentimento passou a `legal-2026-07-20-pilot-v3`.

## Seis gates em falta

1. Repetir a preparação/migração imediatamente antes do cutover e arquivar
   `p1-cutover-migration.json` com estado `COMPLETED`, execução não dry-run,
   zero deletes, zero campos públicos sensíveis, zero tokens privados e os
   hashes exatos de Firestore Rules, Storage Rules e Functions do commit final.
2. Configurar email jurídico/privacidade e morada oficial reais do responsável
   já identificado.
3. Obter parecer jurídico versionado para os termos e privacidade.
4. Executar os 12 casos num Android físico API 33+ com a APK final.
5. Fazer o corte controlado e comprovar App Check `ENFORCED` em Firestore,
   Storage, Authentication e Functions. A evidência tem de corresponder aos
   hashes exatos da APK, das duas Rules e das Functions e referenciar exatamente
   a mesma janela, referência, repetição da migração e conclusão do deploy.
6. Executar e encerrar o piloto real com consentimento e métricas agregadas.

## Ordem obrigatória do corte

1. Completar email, morada e revisão jurídica do responsável; o promotor e o
   `applicationId` de produção já estão identificados.
2. Aprovar a matriz no Android físico com a app Firebase/Play Integrity e APK
   final já registadas, reconstruídas e assinadas.
3. Confirmar que a APK física usa o mesmo hash e certificado desta auditoria.
4. Definir a coorte e a janela de manutenção.
5. Congelar writes legados e repetir a migração aditiva para capturar alterações
   posteriores a 2026-07-20, sem apagar documentos, expor campos sensíveis ou
   deixar tokens persistentes em objetos privados.
6. Capturar a prova da migração e fazer deploy de Functions, índices, Firestore
   Rules e Storage Rules dentro da mesma janela identificada.
7. Inscrever a coorte pela operação administrativa auditada e distribuir a APK.
8. Confirmar tráfego App Check válido e só então ativar enforcement dos serviços,
   mantendo a mesma referência de cutover. A sequência completa desde o
   congelamento de writes até à captura do enforcement não pode exceder 24h.
9. Executar o piloto, incidentes, suporte, pagamentos e métricas de missão.
10. Arquivar os cinco artefactos reais em `docs/pilot/evidence/` e exigir
    `npm run p1:pilot:readiness:strict` com resultado `READY`.

## Contrato cronológico da prova de cutover

O readiness exige, por ordem não decrescente:

`writesFrozenAt` ≤ `migrationStartedAt` ≤ `migrationCompletedAt` ≤ `capturedAt`
≤ `deploymentCompletedAt` ≤ `firebase-app-check-enforcement.capturedAt`.

`migrationRerunAt` deve ser exatamente o instante de conclusão da migração. O
`cutoverWindowId`, a referência do cutover, a referência da execução da
migração, a referência do deploy e esse instante têm de coincidir entre as
provas de migração e App Check. IDs de
exemplo, `TODO`, dry-runs e janelas superiores a 24 horas são rejeitados.

Os modelos de evidência são inválidos por defeito. Não devem ser convertidos em
aprovação ou execução sem a ação humana/operacional correspondente.
