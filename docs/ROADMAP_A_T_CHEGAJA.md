# Roadmap ChegaJa - Blocos A-T

Data: 2026-05-23

## Legenda

```text
FECHADO: feito/fechado
PARCIAL: parcial, em andamento ou pendente
ATIVO: bloco em execucao atual
PAUSADO: pendente por dependencia externa
PROXIMO: proximo passo oficial
FUTURO: falta/futuro
```

## Mapa Principal

| Bloco | Estado | Nome | Situacao atual |
| --- | --- | --- | --- |
| A | FECHADO | Fundacao tecnica do projeto | Flutter, Firebase, estrutura base, Auth, Firestore, Hosting e ambiente Windows/Web estao montados. |
| B | FECHADO | Marketplace MVP Cliente/Prestador | Criar pedido, aceitar, iniciar, concluir, cancelar, orcamento, valor final e no-show funcionam em fluxo Web/E2E. |
| C | PARCIAL | Valores, ganhos, comissao e financeiro interno | Comissao 15/85, valor final e Functions autoritativas estao feitos. Falta pagamento real. |
| D | PARCIAL | Mapa, localizacao, raio e ETA | Existe base de localizacao/raio e prestador online. Falta produto final de mapa/ETA mais completo. |
| E | PARCIAL | Notificacoes e deep links | FCM/Functions existem, mas Android fisico real ainda falta validar. |
| F | ATIVO | Perfil, portfolio e identidade do prestador | Proximo bloco ativo via M2.14: fortalecer perfil publico, portfolio e confianca leve do prestador. |
| G | FECHADO | Chat e mensagens | Chat Cliente/Prestador passou nos E2E; mensagens foram redesenhadas e validadas. |
| H | FUTURO | Avaliacoes, reputacao e confianca | Falta sistema completo de avaliacoes, reviews, confianca, denuncias e reputacao publica. |
| I | FUTURO | Pagamentos reais e monetizacao | Falta Stripe/MB WAY/outros, pagamentos reais, planos PRO, comissoes reais e faturacao. |
| J | PARCIAL | Admin, catalogo e gestao interna | Catalogo de servicos existe e foi expandido visualmente. Backoffice/admin completo ainda falta. |
| K | FECHADO | Seguranca, Rules e producao Firebase | Firestore/Storage Rules endurecidas, Functions autoritativas, deploy real e smoke real ja foram feitos. |
| L | FECHADO | Operacoes, CI e manutencao | Runbook, cleanup auditavel, health check, CI sem deploy, QA e docs operacionais ja existem. |
| M | PAUSADO | Android release e dispositivo fisico | APK/AAB passam e Android em emulador passa, mas o bloco fica pausado ate existir dispositivo Android fisico real. |
| N | FECHADO | Web/Windows beta tecnica | Web automatizada e Windows tecnico passaram. Builds e E2E principais estao aprovados. |
| O | FECHADO | Visual Product System | M2.10 fechada: design system, Home Cliente, Home Prestador, pedidos, mensagens, conta e catalogo visual. |
| P | FECHADO | Beta interna controlada | M2.11 fechada: dual e orcamento passaram; bugs criticos corrigidos; beta Web/Windows aprovada. |
| Q | FECHADO | Pacote de entrega beta para tester real | Builds Web/Windows, guia, roteiro, checklist, templates e manifest de entrega foram preparados. |
| R | PAUSADO | Beta externa/tester real | Bloco iniciado e pacote preparado, mas pausado ate existir tester humano real para receber/executar a beta. |
| S | FUTURO | Preparacao de lancamento publico | Falta package id final, Play Store, politica de privacidade, App Links, textos oficiais e release publico. |
| T | FUTURO | Escala, operacao e negocio real | Falta suporte, moderacao, analytics real, backoffice robusto, legal, pagamentos e operacao continua. |

## Bloco A - Fundacao Tecnica

| Subfase | Estado | Descricao |
| --- | --- | --- |
| A1 | FECHADO | Criar projeto Flutter base |
| A2 | FECHADO | Ligar Firebase |
| A3 | FECHADO | Auth anonima |
| A4 | FECHADO | Firestore base |
| A5 | FECHADO | Estrutura Cliente/Prestador |
| A6 | FECHADO | Hosting/Web base |
| A7 | FECHADO | Repo GitHub e fluxo de commits |

Estado: fechado.

## Bloco B - Marketplace MVP Cliente/Prestador

| Subfase | Estado | Descricao |
| --- | --- | --- |
| B1 | FECHADO | Cliente cria pedido |
| B2 | FECHADO | Prestador ve pedido disponivel |
| B3 | FECHADO | Prestador aceita pedido |
| B4 | FECHADO | Prestador inicia servico |
| B5 | FECHADO | Prestador conclui/envia valor final |
| B6 | FECHADO | Cliente confirma valor final |
| B7 | FECHADO | Historico e estados do pedido |
| B8 | FECHADO | Cancelamento Cliente |
| B9 | FECHADO | No-show Prestador |
| B10 | FECHADO | Convite manual Prestador |

Estado: fechado. O fluxo principal ja passou no E2E Web.

## Bloco C - Valores, Comissao e Financeiro Interno

| Subfase | Estado | Descricao |
| --- | --- | --- |
| C1 | FECHADO | Valor final do prestador |
| C2 | FECHADO | Confirmacao de valor pelo cliente |
| C3 | FECHADO | Comissao simulada 15% plataforma / 85% prestador |
| C4 | FECHADO | Functions autoritativas para valor final |
| C5 | FECHADO | Rules protegem campos economicos |
| C6 | PARCIAL | Relatorios/ganhos mais completos |
| C7 | FUTURO | Pagamentos reais |
| C8 | FUTURO | Faturacao/recibos reais |

Estado: financeiro interno suficiente para beta; pagamentos reais ainda faltam.

## Bloco D - Mapa, Localizacao, Raio e ETA

| Subfase | Estado | Descricao |
| --- | --- | --- |
| D1 | FECHADO | Base de localizacao/prestador online |
| D2 | PARCIAL | Raio/categorias para matching |
| D3 | PARCIAL | Pedidos perto do prestador |
| D4 | FUTURO | Mapa premium com acompanhamento |
| D5 | FUTURO | ETA real |
| D6 | FUTURO | Rota/posicao em tempo real completa |

Estado: parcial. Funciona para logica de matching, mas ainda nao e experiencia tipo Uber/Bolt completa.

## Bloco E - Notificacoes e Deep Links

| Subfase | Estado | Descricao |
| --- | --- | --- |
| E1 | FECHADO | Cloud Functions para notificar |
| E2 | FECHADO | FCM configurado |
| E3 | FECHADO | Tokens guardados |
| E4 | PARCIAL | Deep link/web parcialmente tratado |
| E5 | PARCIAL | Clique real em notificacao Android |
| E6 | PARCIAL | Push real Android fisico |

Estado: tecnicamente avancado, mas dependente do Android fisico para fechar de verdade.

## Bloco F - Perfil, Portfolio e Identidade do Prestador

| Subfase | Estado | Descricao |
| --- | --- | --- |
| F1 | FECHADO | Perfil Cliente/Prestador visualmente melhorado |
| F2 | FECHADO | Conta/Perfil redesenhados |
| F3 | PARCIAL | Portfolio do prestador |
| F4 | PARCIAL | Upload/gestao de imagens |
| F5 | FUTURO | Verificacao/KYC |
| F6 | FUTURO | Badges de confianca |
| F7 | FUTURO | Perfil publico premium do prestador |

Estado: parcial. Visual e base existem; confianca/verificacao ainda faltam.

### M2.14 - Perfil, Portfolio e Confianca do Prestador

| Fase | Estado | Descricao |
| --- | --- | --- |
| M2.14.1 | FECHADO | Spec perfil, portfolio e confianca do prestador |
| M2.14.2 | FECHADO | Auditoria da base atual de perfil/portfolio |
| M2.14.3 | FECHADO | Melhorar perfil publico do prestador |
| M2.14.4 | FECHADO | Melhorar gestao do portfolio no perfil do prestador |
| M2.14.5 | PROXIMO | Consolidar confianca/badges sem KYC real |
| M2.14.6 | FUTURO | Integrar perfil publico nos pontos principais do fluxo Cliente |
| M2.14.7 | FUTURO | Testes, QA visual e documentacao |

Estado: M2.14 e o bloco ativo enquanto R fica pausado por falta de tester
humano e M fica pausado por falta de Android fisico real.

## Bloco G - Chat e Mensagens

| Subfase | Estado | Descricao |
| --- | --- | --- |
| G1 | FECHADO | Chat Cliente/Prestador |
| G2 | FECHADO | Mensagens redesenhadas |
| G3 | FECHADO | Conversa validada no E2E |
| G4 | FECHADO | Rules de mensagens ajustadas |
| G5 | PARCIAL | Chamadas/audio/video se existentes |
| G6 | FUTURO | UX completa tipo Instagram/WhatsApp |

Estado: suficiente para beta Web/Windows.

## Bloco H - Avaliacoes, Reputacao e Confianca

| Subfase | Estado | Descricao |
| --- | --- | --- |
| H1 | FUTURO | Cliente avalia prestador |
| H2 | FUTURO | Prestador recebe reputacao publica |
| H3 | FUTURO | Comentarios/reviews |
| H4 | FUTURO | Denuncias |
| H5 | FUTURO | Moderacao |
| H6 | FUTURO | Ranking de confianca |

Estado: falta.

## Bloco I - Pagamentos Reais e Monetizacao

| Subfase | Estado | Descricao |
| --- | --- | --- |
| I1 | FUTURO | Pagamento real |
| I2 | FUTURO | Stripe/MB WAY/outros |
| I3 | FUTURO | Comissao real da plataforma |
| I4 | FUTURO | Planos PRO |
| I5 | FUTURO | Assinaturas |
| I6 | FUTURO | Historico financeiro real |
| I7 | FUTURO | Reembolsos reais |

Estado: futuro. Nao iniciar antes de beta real estar mais madura.

## Bloco J - Admin, Catalogo e Gestao Interna

| Subfase | Estado | Descricao |
| --- | --- | --- |
| J1 | FECHADO | Colecao servicos dinamica |
| J2 | FECHADO | Catalogo visual de servicos |
| J3 | PARCIAL | Admin/backoffice base |
| J4 | FUTURO | Gestao completa de servicos |
| J5 | FUTURO | Gestao de utilizadores |
| J6 | FUTURO | Gestao de pedidos/conflitos |
| J7 | FUTURO | Moderacao/admin real |

Estado: parcial.

## Bloco K - Seguranca, Rules e Producao Firebase

| Subfase | Estado | Descricao |
| --- | --- | --- |
| K1 | FECHADO | Firestore Rules endurecidas |
| K2 | FECHADO | Storage Rules endurecidas |
| K3 | FECHADO | Rules para pedidos/valores |
| K4 | FECHADO | Rules para cancelamento |
| K5 | FECHADO | Rules para convite manual |
| K6 | FECHADO | Rules para chat/mensagens |
| K7 | FECHADO | Rules para no-show |
| K8 | FECHADO | Functions autoritativas |
| K9 | FECHADO | Deploy real Firebase |
| K10 | FECHADO | Node.js 22 |

Estado: fechado para a fase atual.

## Bloco L - Operacoes, CI e Manutencao

| Subfase | Estado | Descricao |
| --- | --- | --- |
| L1 | FECHADO | Runbook de producao |
| L2 | FECHADO | Cleanup auditavel |
| L3 | FECHADO | Health check read-only |
| L4 | FECHADO | CI sem deploy |
| L5 | FECHADO | Validacao remota CI |
| L6 | FECHADO | Scripts de QA visual |
| L7 | FECHADO | Documentacao operacional |

Estado: fechado.

## Bloco M - Android Release e Dispositivo Fisico

| Subfase | Estado | Descricao |
| --- | --- | --- |
| M1 | FECHADO | Android build debug |
| M2 | FECHADO | APK release |
| M3 | FECHADO | AAB release |
| M4 | FECHADO | Android emulator tests |
| M5 | PARCIAL | Teste em Android fisico |
| M6 | PARCIAL | Push real Android |
| M7 | PARCIAL | Upload nativo de anexos |
| M8 | PARCIAL | Permissoes negadas |
| M9 | FUTURO | Preparacao Play Store |

Estado: pausado/bloqueado por falta de Android fisico real. Nao fechar M2.6
sem prova em dispositivo fisico.

## Bloco N - Web/Windows Beta Tecnica

| Subfase | Estado | Descricao |
| --- | --- | --- |
| N1 | FECHADO | Web build |
| N2 | FECHADO | Windows build debug |
| N3 | FECHADO | Windows cross-role |
| N4 | FECHADO | E2E Web dual |
| N5 | FECHADO | E2E orcamento |
| N6 | FECHADO | Beta interna Web/Windows aprovada |

Estado: fechado.

## Bloco O - Visual Product System

| Subfase | Estado | Descricao |
| --- | --- | --- |
| O1 | FECHADO | Auditoria visual |
| O2 | FECHADO | Design system foundation |
| O3 | FECHADO | Home Cliente redesign |
| O4 | FECHADO | Home Prestador redesign |
| O5 | FECHADO | Pedido/listas/detalhe polish |
| O6 | FECHADO | Mensagens/Pedidos/Conta alinhados |
| O7 | FECHADO | Navegacao desktop/mobile premium |
| O8 | FECHADO | Catalogo visual de servicos |
| O9 | FECHADO | QA visual/responsividade |

Estado: fechado.

## Bloco P - Beta Interna Controlada

| Subfase | Estado | Descricao |
| --- | --- | --- |
| P1 | FECHADO | Roteiro de teste |
| P2 | FECHADO | Template de bugs |
| P3 | FECHADO | Checklist Web/Windows |
| P4 | FECHADO | Troca Cliente/Prestador pela UI |
| P5 | FECHADO | Runner E2E Web robusto |
| P6 | FECHADO | Bugs Rules corrigidos |
| P7 | FECHADO | Dual E2E aprovado |
| P8 | FECHADO | Orcamento E2E aprovado |
| P9 | FECHADO | M2.11 fechada |

Estado: fechado.

## Bloco Q - Pacote de Entrega Beta para Tester Real

| Subfase | Estado | Descricao |
| --- | --- | --- |
| Q1 | FECHADO | Spec do pacote de entrega beta |
| Q2 | FECHADO | Build Web beta preparado |
| Q3 | FECHADO | Build Windows beta preparado |
| Q4 | FECHADO | Guia rapido para tester |
| Q5 | FECHADO | Roteiro simplificado |
| Q6 | FECHADO | Template de feedback externo |
| Q7 | FECHADO | Checklist de entrega |
| Q8 | FECHADO | Pasta/pacote final para tester |

Estado: fechado para entrega beta Web/Windows. Os builds e documentos estao preparados; o proximo passo depende de tester real.

## Bloco R - Beta Externa / Tester Real

| Subfase | Estado | Descricao |
| --- | --- | --- |
| R1 | PAUSADO | Entregar app ao tester; pacote, mensagem, instrucoes, feedback template e validacao solo preparados, envio real pendente ate existir tester humano |
| R2 | FUTURO | Tester real executa roteiro; beta solo Playwright ja validou fluxo tecnico |
| R3 | FUTURO | Recolher bugs reais |
| R4 | FUTURO | Classificar bugs |
| R5 | FUTURO | Corrigir bloqueadores |
| R6 | FUTURO | Decidir se beta externa passa |

Estado: pausado por dependencia externa. A spec/status da M2.13, a mensagem de
entrega, as instrucoes do tester, o template de feedback e a beta solo assistida
por Playwright foram preparados/executados. A beta solo tambem gerou correcoes
de usabilidade e contraste em dark mode; a entrega real ao tester humano ainda
esta pendente.

### Detalhe Atual da M2.13

| Fase | Estado | Descricao |
| --- | --- | --- |
| M2.13.1 | FECHADO/PREPARADO | Preparacao da entrega ao tester real |
| M2.13.2 | FECHADO | Beta solo assistida por Playwright |
| M2.13.3 | FECHADO/PREPARADO | Documentacao de entrega real ao tester |
| M2.13.4 | FECHADO | Correcao da pesquisa do catalogo Cliente |
| M2.13.5 | FECHADO | Correcao de modo escuro e localizacao do chat |
| M2.13.6 | FECHADO | Correcao de contraste dark mode transversal e resumo financeiro Prestador |
| M2.13.7 | PROXIMO | Registar envio real e feedback inicial do tester |

Estado: M2.13.6 esta concluida. R1 continua pendente porque nenhum tester
humano recebeu/executou a beta. M2.13.7 fica preparada como proximo passo de R,
mas o bloco R esta pausado ate existir tester humano.

## Bloco S - Lancamento Publico / Play Store

| Subfase | Estado | Descricao |
| --- | --- | --- |
| S1 | FUTURO | Package id final |
| S2 | FUTURO | Icone/app name final |
| S3 | FUTURO | Politica de privacidade |
| S4 | FUTURO | Termos de uso |
| S5 | FUTURO | HTTPS App Links |
| S6 | FUTURO | Play Store listing |
| S7 | FUTURO | Release candidate |
| S8 | FUTURO | Publicacao inicial |

Estado: falta.

## Bloco T - Escala, Operacao e Negocio Real

| Subfase | Estado | Descricao |
| --- | --- | --- |
| T1 | FUTURO | Suporte ao cliente |
| T2 | FUTURO | Moderacao |
| T3 | FUTURO | Analytics real |
| T4 | FUTURO | Observabilidade avancada |
| T5 | FUTURO | Backoffice completo |
| T6 | FUTURO | Gestao de disputas |
| T7 | FUTURO | Operacao financeira real |
| T8 | FUTURO | Escala multi-regiao/multi-pais |

Estado: futuro.

## Proximo Movimento

O proximo bloco ativo e:

```text
F - Perfil, portfolio e identidade do prestador
```

Fase operacional:

```text
M2.14.5 - Consolidar confianca/badges sem KYC real
```

Dependencias pausadas:

```text
R - Beta externa/tester real: pausado por falta de tester humano
M - Android release/dispositivo fisico: pausado por falta de Android fisico real
```
