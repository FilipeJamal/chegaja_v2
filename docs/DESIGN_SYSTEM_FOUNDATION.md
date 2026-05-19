# Design System Foundation

Data: 2026-05-19

## Objetivo

Esta foundation existe para dar consistencia visual ao redesign M2.10 do
ChegaJa em Web, Windows e Android.

## Componentes

### AppContentShell

Centraliza e limita a largura do conteudo conforme o contexto.

Uso recomendado:

```dart
AppContentShell(
  width: AppContentWidth.dashboard,
  child: MinhaTela(),
)
```

### AppPageScaffold

Cria uma estrutura de pagina com titulo, subtitulo, acoes opcionais e padding
responsivo. Deve ser usado dentro de `AppShellScaffold` ou como corpo de uma
tela operacional.

### AppSectionHeader

Padroniza titulos de secoes, subtitulos e acao lateral.

### AppStatusPill

Padroniza estados curtos como `Aberto`, `Em andamento`, `Concluido`,
`Pendente` e `Cancelado`.

### AppMetricTile

Mostra metricas operacionais, como pedidos ativos, ganhos estimados ou trabalhos
concluidos.

### AppActionPanel

Agrupa uma proxima acao com contexto e botoes. Deve ser usado para reduzir
botoes soltos em paginas de pedido, home e fluxo.

### AppResponsiveGrid

Organiza cards em uma ou mais colunas sem transformar desktop em mobile
esticado.

## Regras de uso

```text
nao criar estilos locais se um componente core resolver o caso
nao colocar cards dentro de cards
nao usar grids em mobile quando uma coluna for mais clara
preservar keys existentes de E2E/Android
manter regra de negocio fora dos widgets visuais
```

## Proximas fases

```text
M2.10.3: Home Cliente redesign
M2.10.4: Home Prestador redesign
M2.10.5: Pedido/listas/detalhe polish
M2.10.6: Responsividade Web/Windows/Android
M2.10.7: QA visual e fecho
```
