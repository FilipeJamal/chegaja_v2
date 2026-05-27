# Prompt — Corrigir bug visual com screenshot

```txt
Vou anexar uma screenshot da tela do ChegaJá.

Problema visível:
- [problema 1]
- [problema 2]
- [problema 3]

Comportamento esperado:
- [como deve ficar]

Escopo:
Corrigir apenas este problema visual/comportamental.

Regras:
- Não alterar Firestore rules.
- Não alterar Functions.
- Não alterar estados dos pedidos.
- Não refatorar arquitetura.
- Não mudar textos/fluxos que não estejam relacionados.
- Preservar comportamento atual.
- Se precisares mexer num widget partilhado, explica o impacto.

Depois da correção:
- correr `flutter test --no-pub`;
- explicar ficheiros alterados;
- dizer como testar manualmente;
- se a correção afetar mobile/desktop, indicar ambos.
```
