# Regras de teste e commit do ChegaJá

## Princípio

Não acumular muitas alterações sem commit.

Cada commit deve representar uma melhoria estável.

## Quando fazer commit

Fazer commit quando:

- Uma funcionalidade pequena ficou pronta.
- Um bug foi corrigido e testado.
- Uma tela ficou visualmente estável.
- Um bloqueio foi resolvido.
- Antes de começar uma alteração arriscada.

## Quando não fazer commit

Não fazer commit quando:

- Os testes falharam.
- A app não compila.
- A alteração ainda está experimental e suja.
- O Codex mexeu em ficheiros inesperados.
- Há secrets ou tokens no diff.
- O relatório final não está claro.

## Comandos antes de commit

```powershell
git status --short
flutter test --no-pub
cd functions
npm.cmd test
cd ..
```

Se mexeu em scripts:

```powershell
npm.cmd run test:scripts
```

Se mexeu em Firebase:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

## Mensagem de commit

Formato:

```txt
Avancar <milestone> <descrição curta>
```

Exemplos:

```txt
Avancar M2.9 proposta de orçamento
Avancar M2.9.1 ajuste visual pedido detalhe
Avancar M2.9.2 testes fluxo cliente prestador
```

## Relatório pós-commit

O Codex deve devolver:

```txt
Commit:
<hash>
<mensagem>

Validações:
- flutter test --no-pub: passou/falhou
- functions npm test: passou/falhou
- scripts: passou/falhou
- emulator tests: passou/falhou/não aplicável

Observações:
...
```
