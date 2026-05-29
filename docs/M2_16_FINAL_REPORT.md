# M2.16 - Relatorio Final

Data: 2026-05-29

## Objetivo

A M2.16 teve como objetivo criar a base de pesquisa manual e discovery de
prestadores, permitindo que o Cliente encontre prestadores por nome, servico,
categoria ou localizacao textual, abra o perfil publico unico, veja dados
publicos seguros e guarde favoritos, sem depender apenas do matching automatico
de pedidos.

## Estado Final

```text
M2.16.1: fechada
M2.16.2: fechada
M2.16.3: fechada
M2.16.4: fechada
M2.16.5: fechada
M2.16.6: fechada
M2.16: fechada no escopo atual
Bloco F: parcial
Bloco H: parcial
R: pausado
M: pausado
R1: pendente
M2.6: pendente
```

## Fases

| Fase | Resultado | Commit |
| --- | --- | --- |
| M2.16.1 | Spec e auditoria da pesquisa manual/discovery | `0d04b037233767cf37f3207cbe2de22ab5fc8e5c` |
| M2.16.2 | Modelo e normalizacao de perfil pesquisavel | `f482ecacf52a0f0fe5d231fac75e2fd65c88f9e0` |
| M2.16.3 | UI de pesquisa manual estilo Instagram | `264ebfb2cc20f385935cb40531604aa978a2f6fb` |
| M2.16.4 | Integracao com perfil publico, favoritos e pedido | `1c4c812d333646955a0d749e75fd2e1cb0d895c1` |
| M2.16.5 | Sugestoes compactas na Home Cliente | `b79bca3df543f2654859d3e522970e8ae9e5c7c3` |
| M2.16.6 | QA final, E2E e documentacao | este commit |

## O Que Foi Implementado

```text
ProviderSearchProfile como modelo seguro de perfil pesquisavel;
ProviderSearchNormalizer para normalizacao textual;
matchesProviderSearch e scoreProviderSearch;
ProviderSearchScreen;
ProviderSearchCard;
ProviderSearchEmptyState;
ProviderSuggestionsSection;
ProviderSuggestionCompactCard;
CTA "Pesquisar prestadores" na Home Cliente;
favoritar/desfavoritar prestador na pesquisa;
abertura de PublicProfileScreen via openPublicProfile;
secao "Prestadores para conhecer" na Home Cliente.
```

## Decisoes Tecnicas

```text
prestadores e a fonte inicial da pesquisa, nao users;
users nao deve ser superficie principal de discovery publico;
PublicProfileScreen continua a tela unica de perfil publico;
dados privados nao entram nos cards de search/home;
rating leve aparece apenas quando ratingAvg/ratingCount sao validos;
pedido direto a partir da pesquisa foi adiado porque NovoPedidoScreen ainda depende de servico/categoria;
publicProfiles/providerSearchIndex ficam preparados para futuro, nao criados agora;
ranking complexo e patrocinados ficaram fora.
```

## O Que Foi Testado

```text
mapper de perfil pesquisavel;
normalizacao textual;
matcher e score simples;
ProviderSearchCard;
ProviderSearchScreen;
ProviderSuggestionsSection;
Home Cliente com a nova secao;
suite Flutter completa;
Functions/Rules com emulador configurado;
build Web release;
E2E dual completo;
E2E orcamento min-max;
QA visual headless;
matriz visual Cliente/Prestador.
```

## Fora do Escopo

```text
ranking complexo;
patrocinados;
destaques pagos;
pagamentos reais;
KYC;
moderacao;
denuncias;
Trust & Safety implementation;
admin/backoffice completo;
publicProfiles;
providerSearchIndex;
handle publico real;
link publico;
partilha social;
pedido direto completo a partir da pesquisa;
alteracao de Rules;
alteracao de Functions;
deploy;
Android fisico;
tester externo;
fechar R;
fechar M;
fechar R1;
fechar M2.6.
```

## Riscos Remanescentes

```text
search ainda filtra client-side com limite local;
prestadores ainda nao possuem campos formais isPublic/isSearchable/moderationStatus;
nao ha Trust & Safety completo para bloquear perfis/servicos proibidos;
nao ha ranking inteligente ou proximidade robusta;
publicProfiles/providerSearchIndex continuam futuros;
pedido direto com prestador pre-selecionado ainda exige desenho de fluxo.
```

## Proximo Passo

```text
M2.17 - Trust & Safety, servicos proibidos e moderacao basica
```

A M2.17 deve preparar denuncia, bloqueio, moderacao leve e filtros de conteudo
antes de expandir discovery publico, comentarios publicos, ranking ou videos.
