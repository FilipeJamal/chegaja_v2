# Auditoria consolidada P1

Data: 2026-07-20
Projeto Firebase: `chegaja-ac88d`
Decisão atual: **NOT READY para piloto externo**

## Resultado executivo

As dez frentes P1 têm implementação técnica e procedimentos de operação. A
preparação produtiva segura já inclui migração aditiva, catálogo server-side,
TTL, segredo de eliminação, identificador Android final e configuração Play
Integrity para distribuição fora da Play Store. O promotor individual também
está identificado sem apresentar o projeto como empresa constituída. O P1
operacional ainda não está fechado: faltam completar os contactos jurídicos,
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
| P1.7 Pagamentos/MZN | Concluída | Dinheiro habilitado; M-Pesa, e-Mola e Stripe continuam desligados | `paymentPolicy.test.js` |
| P1.8 Android/permissões | APK e emulador concluídos | Matriz em Android físico pendente | `p1-8-physical-device-validation.md` |
| P1.9 Legal/eliminação/suporte | Concluída no código | Promotor confirmado; email, morada e parecer jurídico pendentes | `docs/legal/operator-identity.md`, `firebase-account-deletion-secret.json` |
| P1.10 Piloto Maputo | Produto, backoffice e runbooks concluídos | Participantes e execução real pendentes | `maputo-pilot-runbook.md` |

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

- Flutter: **506 testes aprovados**.
- Análise estática Flutter: **0 erros**; 20 avisos e 309 informações não fatais.
- Functions/Firestore/Storage: **94 testes aprovados**; o emulador carregou as
  63 definições locais sem erro de descoberta.
- Scripts operacionais: **11 grupos de testes aprovados**.
- APK release: 123074424 bytes, assinatura v2, um signatário RSA 2048.
- SHA-256 APK:
  `f9d29a1d38dca520e9cb68eb83dd72666c177a0442c6012f535bb36d5589ad13`.
- Fingerprint das 351 entradas de release:
  `3e22cfa0c4a5366e6866ba5c011e6da9e4b2e86d708f0b2edd500e2fe2d7cae3`.
- Emulador Android 14/API 34: instalação limpa, seletor em português, nenhuma
  permissão no arranque e zero padrões fatais.
- Identidade Android: `com.chegaja.app`, app Firebase
  `1:767588494857:android:4198384a2a6387055252d8`, certificados release/debug
  registados e App Links ligados ao certificado release.
- Readiness: **9/14 gates aprovados**.

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

## Cinco gates externos em falta

1. Configurar email jurídico/privacidade e morada oficial reais do responsável
   já identificado.
2. Obter parecer jurídico versionado para os termos e privacidade.
3. Executar os 12 casos num Android físico API 33+ com a APK final.
4. Fazer o corte controlado e comprovar App Check `ENFORCED` em Firestore,
   Storage, Authentication e Functions. A evidência tem de corresponder aos
   hashes exatos da APK, das duas Rules e de `functions/index.js`, além de
   registar a repetição final da migração.
5. Executar e encerrar o piloto real com consentimento e métricas agregadas.

## Ordem obrigatória do corte

1. Completar email, morada e revisão jurídica do responsável; o promotor e o
   `applicationId` de produção já estão identificados.
2. Aprovar a matriz no Android físico com a app Firebase/Play Integrity e APK
   final já registadas, reconstruídas e assinadas.
3. Confirmar que a APK física usa o mesmo hash e certificado desta auditoria.
4. Definir a coorte e a janela de manutenção.
5. Congelar writes legados e repetir a migração aditiva para capturar alterações
   posteriores a 2026-07-20.
6. Fazer deploy de Functions, índices, Firestore Rules e Storage Rules.
7. Inscrever a coorte pela operação administrativa auditada e distribuir a APK.
8. Confirmar tráfego App Check válido e só então ativar enforcement dos serviços.
9. Executar o piloto, incidentes, suporte, pagamentos e métricas de missão.
10. Arquivar os quatro artefactos reais em `docs/pilot/evidence/` e exigir
    `npm run p1:pilot:readiness:strict` com resultado `READY`.

Os modelos de evidência são inválidos por defeito. Não devem ser convertidos em
aprovação ou execução sem a ação humana/operacional correspondente.
