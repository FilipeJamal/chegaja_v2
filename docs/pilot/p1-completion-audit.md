# Auditoria consolidada P1

Data: 2026-07-20
Projeto Firebase: `chegaja-ac88d`
Decisão atual: **NOT READY para piloto externo**

## Resultado executivo

As dez frentes P1 têm implementação técnica e procedimentos de operação. A
preparação produtiva segura já inclui migração aditiva, catálogo server-side,
TTL, segredo de eliminação e configuração Play Integrity para distribuição
fora da Play Store. O P1 operacional ainda não está fechado: faltam identidade
de produção, validação jurídica, aparelho físico, enforcement App Check e a
execução real do piloto.

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
| P1.9 Legal/eliminação/suporte | Concluída no código | Segredo ativo; entidade e parecer jurídico pendentes | `firebase-account-deletion-secret.json` |
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

- Flutter: **504 testes aprovados**.
- Análise estática Flutter: **0 erros**; 20 avisos e 309 informações não fatais.
- Functions/Firestore/Storage: **94 testes aprovados**; o emulador carregou as
  63 definições locais sem erro de descoberta.
- Scripts operacionais: **11 grupos de testes aprovados**.
- APK release: 123074500 bytes, assinatura v2, um signatário RSA 2048.
- SHA-256 APK:
  `7cf15ca9a0a07948fa2565378288d0846cb8957a5662129654de84d1b0694781`.
- Fingerprint das 351 entradas de release:
  `a788eed07625aafdb425bd6acbcc88e7a1197dc774d152e28997917ee4c32f73`.
- Emulador Android 14/API 34: instalação limpa, seletor em português, nenhuma
  permissão no arranque e zero padrões fatais.
- Readiness: **8/14 gates aprovados**.

## Seis gates externos em falta

1. Substituir `com.example.chegaja_v2` pelo identificador de produção escolhido
   pelo titular do domínio/marca e registar a nova app Firebase. A verificação
   read-only encontrou apenas `com.example.chegaja` e
   `com.example.chegaja_v2` entre as apps Android atuais do projeto.
2. Configurar nome, email e endereço reais da entidade responsável.
3. Obter parecer jurídico versionado para os termos e privacidade.
4. Executar os 12 casos num Android físico API 33+ com a APK final.
5. Fazer o corte controlado e comprovar App Check `ENFORCED` em Firestore,
   Storage, Authentication e Functions. A evidência tem de corresponder aos
   hashes exatos da APK, das duas Rules e de `functions/index.js`, além de
   registar a repetição final da migração.
6. Executar e encerrar o piloto real com consentimento e métricas agregadas.

## Ordem obrigatória do corte

1. Fixar entidade jurídica e `applicationId` de produção.
2. Registar a app Firebase/Play Integrity, reconstruir e repetir a assinatura.
3. Aprovar a matriz no Android físico.
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
