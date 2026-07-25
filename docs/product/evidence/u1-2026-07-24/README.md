# Evidência U1 — 2026-07-24

Esta pasta reúne provas versionáveis do Design System ChegaJá 2.0.

## Referência e implementação

- `u1-selected-visual.png`: síntese visual aprovada pelo fundador.
- `u1-selected-visual-390x844.png`: referência normalizada para o viewport
  final.
- `u1-client-home-widget-final.png`: captura determinística dos componentes de
  produção, no estado carregado, a `390 × 844`.
- `u1-home-side-by-side.png`: referência e implementação no mesmo viewport e
  estado.
- `u1-role-selector-android.png`: prova complementar do seletor de papel em
  execução no Android.
- `u1-client-home-android.png`: prova complementar anterior da Home em execução
  no Android; não é a captura final de fidelidade.
- `../../../../assets/illustrations/coimbra_services_hero.png`: ilustração
  original criada para a primeira experiência em Coimbra.

## Relatórios

- `../../../../design-qa.md`: metodologia, severidades e decisão visual final.
- `u1-validation-results.md`: comandos e resultados técnicos finais.
- `u1-build-manifest.json`: artefactos, hashes e contexto de compilação.

## Estado das provas

- [x] referência normalizada para `390 × 844`;
- [x] implementação final no mesmo viewport e estado;
- [x] comparação lado a lado;
- [x] relatório de Design QA;
- [x] validações técnicas finais;
- [x] manifestos Android, Web e Windows;
- [x] integridade do diff e exclusão de ficheiros pessoais/temporários.

O pull request, a CI e o merge são estados externos registados diretamente no
GitHub; o histórico do PR é a fonte de verdade para esses estados.

## Integridade

- Nenhuma imagem desta pasta constitui prova de piloto real, tração ou uso
  público.
- O APK é uma compilação privada de validação, não um lançamento de produção.
- A captura final determinística prova a composição dos componentes; a captura
  Android prova execução anterior. A validação mais recente num aparelho
  Android físico continua a ser um gate externo.
- Nenhuma credencial, identificador pessoal, documento KYC ou valor de segredo
  entra nesta pasta.
