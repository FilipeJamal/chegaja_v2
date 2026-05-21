# M2.11 - Beta Interna Controlada

Data: 2026-05-21

## Estado

```text
M2.11: planeada para beta interna controlada
M2.11.1: avancado com troca de modo Cliente/Prestador pela UI
M2.6: continua pendente de Android fisico real
```

## M2.11.1 - Troca de modo Cliente/Prestador pela UI

Problema corrigido:

```text
Antes, o app dependia de ?role=cliente ou ?role=prestador na URL para abrir o
modo inicial. Isso era aceitavel para desenvolvimento, mas inadequado para beta
interna, porque o tester nao deve precisar editar a URL.
```

Implementacao:

```text
RoleModeService criado para resolver e persistir o modo local.
Ordem de resolucao mantida:
1. role da URL, para desenvolvimento e automacao;
2. role persistido localmente;
3. DEFAULT_ROLE;
4. RoleSelectorScreen.

Conta Cliente ganhou acao "Mudar para modo prestador".
Conta Prestador ganhou acao "Mudar para modo cliente".
RoleSelectorScreen agora grava o modo escolhido localmente.
ChegaJaApp escuta RoleModeService e troca a home renderizada sem exigir nova
sessao.
```

Ficheiros principais:

```text
lib/core/services/role_mode_service.dart
lib/features/common/widgets/role_mode_switch_tile.dart
lib/app.dart
lib/features/auth/role_selector_screen.dart
lib/features/cliente/cliente_home_screen.dart
lib/features/prestador/prestador_home_screen.dart
```

Testes adicionados:

```text
test/core/services/role_mode_service_test.dart
test/features/common/widgets/role_mode_switch_tile_test.dart
test/app_role_mode_test.dart
```

Validação executada:

```text
flutter test: 149/149 passou
```

## Fora do escopo mantido

```text
backend novo
Firestore Rules
Storage Rules
Cloud Functions
deploy real
smoke real
cleanup real
health real
Android fisico real
pagamentos reais
Play Store
package id final
HTTPS App Links
fecho da M2.6
```

## Proximo passo recomendado

```text
Preparar roteiro executavel da beta interna:
- BETA_INTERNAL_TEST_SCRIPT
- BETA_FEEDBACK_TEMPLATE
- contas/roles de teste
- checklist de Web/Windows
```

## Plano de execucao

Plano criado:

```text
docs/superpowers/plans/2026-05-21-m2-11-beta-interna-controlada.md
```

Ordem recomendada:

```text
1. Consolidar status M2.11.
2. Criar roteiro executavel da beta interna.
3. Criar template de feedback e bugs.
4. Criar checklist tecnico de build e validacao.
5. Rodar validacoes tecnicas Web/Windows.
6. Atualizar resultados e decidir aprovacao, bloqueio ou ajustes.
```

Validacoes finais previstas:

```cmd
flutter test
npm.cmd run test:scripts
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
flutter build web --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
flutter build windows --dart-define=RUN_FIREBASE_EMULATOR_TESTS=true
```
