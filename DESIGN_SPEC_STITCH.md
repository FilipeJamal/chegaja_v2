# DESIGN SPEC - CHEGAJA (STITCH MCP)

Fonte Stitch MCP usada para este spec:
- `stitch.get_project` em `projects/17053801360028606122` retornou `designTheme`: `colorMode=LIGHT`, `font=INTER`, `roundness=ROUND_EIGHT`, `customColor=#12ba9b`, `saturation=3`.
- `stitch.get_screen` em `projectId=9058762646960833039` e `screenId=126b4bbacff54430a09285412cc8001e` retornou HTML exportado.
- Tokens extraidos do HTML Stitch (`stitch_screen_126b4b.html`): `#137fec`, `#f6f7f8`, `#101922`, `#111418`, `font=Inter`, `rounded-xl`, `shadow-sm`, `shadow-lg`.

A) Brand & Feel
- Premium urbano, rapido e confiavel, com forte leitura em movimento.
- Camadas visuais inspiradas em ride-hailing: mapa como contexto e sheets/cards como acao.
- Linguagem visual limpa, com contraste alto e foco em decisao rapida.
- Microinteracoes discretas para estados de toque, sem ruido visual.
- Tom de produto direto e objetivo: previsibilidade de tempo, preco e status.

B) Color tokens (hex) + roles + estados
- `primary`: base `#12BA9B`, hover `#0FA98C`, pressed `#0C8E77`, disabled `#9FDFD1`.
- `secondary`: base `#0B3C5D`, hover `#09324E`, pressed `#07293F`, disabled `#9FB4C3`.
- `surface`: base `#FFFFFF`, hover `#F6F7F8`, pressed `#ECEFF2`, disabled `#DDE3E8`.
- `error`: base `#E5484D`, hover `#D63E43`, pressed `#B83539`, disabled `#F3BEC0`.
- `success`: base `#22C55E`, hover `#1FB254`, pressed `#199747`, disabled `#C2ECCE`.
- `warn`: base `#F59E0B`, hover `#E08F0A`, pressed `#C77C08`, disabled `#F4D7A6`.
- `text-primary`: `#111418`.
- `text-secondary`: `#6B7280`.
- `bg-app-light`: `#F6F7F8`.
- `bg-app-dark`: `#101922`.

C) Typography tokens (display/title/body/label)
- `font-family-base`: `Inter`.
- `display-lg`: `34/40`, weight `800`.
- `display-md`: `30/36`, weight `700`.
- `title-lg`: `24/30`, weight `700`.
- `title-md`: `20/26`, weight `700`.
- `body-lg`: `16/24`, weight `500`.
- `body-md`: `14/20`, weight `400`.
- `label-lg`: `14/18`, weight `600`.
- `label-md`: `12/16`, weight `600`.

D) Spacing scale e layout grid
- Escala base 4pt: `4, 8, 12, 16, 20, 24, 32, 40, 48`.
- Grid mobile: 4 colunas, margem horizontal `16`, gutter `12`.
- Largura alvo mobile: `360-390`.
- `maxWidth` para tablet/web: `480` (single column), `960` (2 colunas quando aplicavel).
- Touch targets minimos: `48x48`.
- Safe areas: top `>=24`, bottom `>=16`.

E) Radius + elevation/shadows
- `radius-xs`: `8`.
- `radius-sm`: `10`.
- `radius-md`: `12`.
- `radius-lg`: `16`.
- `radius-xl`: `24`.
- `radius-sheet-top`: `40` (equivalente visual de `rounded-b-[2.5rem]` no stitch sample).
- `shadow-1`: `0 1px 2px rgba(17,20,24,0.08)`.
- `shadow-2`: `0 4px 12px rgba(17,20,24,0.12)`.
- `shadow-3`: `0 8px 24px rgba(17,20,24,0.16)`.
- `shadow-4`: `0 16px 32px rgba(17,20,24,0.20)`.

F) Component library (variantes + estados + tamanhos)
- `AppButton`: variantes `primary`, `secondary`, `ghost`; estados `default`, `hover`, `pressed`, `disabled`, `loading`; tamanhos `sm=36h`, `md=44h`, `lg=52h`; suporte a icone leading/trailing.
- `AppTextField`: variantes `filled`, `outlined`; estados `default`, `focus`, `error`, `disabled`; tamanhos `sm=40h`, `md=48h`, `lg=56h`; suporte a helper, prefix e clear action.
- `AppCard`: variantes `elevated`, `outlined`, `flat`; estados `default`, `pressed`, `disabled`; tamanhos `compact`, `regular`, `large`; radius `md/lg`.
- `AppChip`: variantes `filter`, `choice`, `status`; estados `unselected`, `selected`, `disabled`; tamanhos `sm=28h`, `md=32h`.
- `AppBottomSheet`: niveis `collapsed`, `half`, `full`; `collapsed` mostra resumo+CTA, `half` mostra lista interativa, `full` mostra fluxo completo; drag handle fixo e scrim configuravel.
- `AppTopBar`: variantes `standard`, `search`, `contextual`; estados `default`, `scrolled`, `disabled-action`; altura base `56`.
- `AppTabBar`: variante principal com 4 tabs; estados `active`, `inactive`, `disabled`; icone `24` e label `11-12`.
- `AppListTile`: variantes `default`, `withLeading`, `withTrailingAction`; estados `default`, `pressed`, `disabled`; altura minima `56`.
- `Loading`: `skeleton list`, `skeleton card`, `inline spinner` para acao secundaria.
- `Empty`: ilustracao simples + titulo curto + descricao + CTA primaria.
- `Error`: bloco com icone + mensagem clara + CTA `tentar novamente`.

G) Screen templates (estrutura e hierarquia)
- `HomeCliente`: camada 1 mapa full-screen; camada 2 top search com local atual; camada 3 chips de categoria; camada 4 bottom sheet `collapsed` com pedido rapido, ETA e preco; camada 5 CTA primaria.
- `NovoPedido`: header contextual; seletor de modo `IMEDIATO/AGENDADO/POR_PROPOSTA`; bloco origem/destino com swap; bloco estimativa tempo/preco; bloco pagamento; bottom sheet resumo com CTA confirmar.
- `Pedidos`: topbar com busca; linha de filtros por status/periodo; lista cronologica com `AppListTile` + `status chip`; estados loading/empty/error.
- `PedidoDetalhe`: mapa compacto no topo; timeline vertical de status; card motorista/veiculo; card custo; entradas para chat e suporte; acoes contextuais no rodape.
- `Chat`: lista de conversas com status e ultima mensagem; tela de conversa com bolhas alinhadas por autor; composer fixo com anexo/audio/enviar; fallback empty/error.
- `Conta`: card perfil; secoes `documentos`, `pagamentos`, `idioma`, `moeda`, `seguranca`, `ajuda`; acoes de preferencia em list tiles; logout destacado no fim.
- `HomePrestador`: toggle `online/offline` no topo; mapa e oportunidades proximas; lista de pedidos disponiveis com ganhos estimados; painel de ganhos do dia e taxa de aceitacao.

