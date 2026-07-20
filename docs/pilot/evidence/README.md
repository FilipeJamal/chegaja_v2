# Evidência dos gates externos

Esta pasta define artefactos esperados, mas não contém aprovações fictícias.
Os modelos em `templates/` falham deliberadamente o readiness checker até
serem substituídos por evidência real.

- `legal-approval.md`: entidade, revisor, data, versão jurídica e referência
  de aprovação reais.
- `firebase-app-check-enforcement.json`: estado `ENFORCED` de Firestore,
  Storage e Authentication, mais referência do deploy das callable Functions
  que usam `enforceAppCheck`. A prova também tem de corresponder ao SHA-256 da
  APK, das Firestore/Storage Rules e de `functions/index.js` atuais, e registar
  a repetição final da migração antes do corte.
- `firebase-account-deletion-secret.json`: apenas metadados do segredo de
  eliminação ativo; o valor nunca é exportado ou guardado.
- `android-physical-validation.json`: aparelho físico API 33+, SHA-256 exato da
  APK e os 12 casos obrigatórios aprovados.
- `real-pilot-execution.json`: coorte, datas, versão da APK e métricas apenas
  agregadas; nunca nomes, telefones, emails, moradas, documentos, tokens ou
  identificadores de participantes.

Copiar o modelo apropriado, retirar o sufixo `.example` e preencher apenas
depois da ação externa acontecer. Executar:

```text
npm run p1:pilot:readiness:strict
```

O piloto permanece **NOT READY** se o ficheiro estiver ausente, malformado,
incompleto, tiver placeholders ou não corresponder à APK release atual.
