# ChegaJa - Visao Mestre de Produto

Data: 2026-05-29

## Estado

Este documento consolida a visao de produto recolhida nos ficheiros externos:

```text
C:\Users\Jamal\Downloads\Texto colado .txt
C:\Users\Jamal\Downloads\Markdown colado (2).md
C:\Users\Jamal\Downloads\Markdown colado (3).md
C:\Users\Jamal\Downloads\deep-research-report.md
```

Serve como fonte-mestre de produto. Nao substitui o roadmap A-T nem fecha
fases pendentes sem validacao real.

## Visao Curta

O ChegaJa deve evoluir para um marketplace premium de prestacao de servicos
locais, aproximando Cliente e Prestador atraves de:

```text
proximidade
disponibilidade
perfil publico forte
portfolio
chat e negociacao antes do servico
favoritos
avaliacoes pos-servico
reputacao progressiva
seguranca e moderacao
admin/backoffice
validacao documental futura
monetizacao futura sem comprar confianca
```

O produto nao deve ser apenas "cliente cria pedido e prestador aceita". Deve
tambem permitir descoberta manual, repeticao de servicos com prestadores de
confianca e uma experiencia profissional para ambos os lados.

## Principios de Produto

```text
1. Aproximar Cliente e Prestador.
2. Dar visibilidade ao bom prestador.
3. Dar ao Cliente informacao suficiente antes de decidir.
4. Nunca prometer confianca que a plataforma ainda nao consegue provar.
5. Separar reputacao organica de destaque pago.
6. Separar contacto pessoal, perfil publico, KYC e dados privados.
7. Moderar conteudo gerado por utilizadores antes de escala publica.
8. Construir por fases pequenas, com testes e commits curtos.
```

## Fluxos Nucleares

### Cliente

O Cliente deve conseguir:

```text
entrar como Cliente
criar pedido imediato, agendado ou por orcamento
pesquisar prestadores manualmente
abrir perfil publico do prestador
ver foto, bio, portfolio, servicos e reputacao permitida
falar por chat antes/depois do servico quando fizer sentido
guardar prestadores favoritos
avaliar depois de pedido concluido
reportar problemas no futuro
```

### Prestador

O Prestador deve conseguir:

```text
entrar como Prestador
configurar perfil publico profissional
adicionar foto e portfolio
definir area/raio/categorias
receber pedidos compativeis
conversar com Cliente
enviar orcamento ou valor final
ganhar reputacao por servicos reais concluidos
acompanhar ganhos e desempenho
```

## Descoberta e Pesquisa Manual

A pesquisa manual deve aproximar-se de uma experiencia tipo rede social, mas
adaptada a servicos locais:

```text
pesquisa por nome
pesquisa por handle publico futuro
pesquisa por categoria/servico
pesquisa por cidade/area
cards compactos de prestadores
entrada rapida no perfil publico
favoritos e repeticao de servico
```

Esta frente nao deve entrar antes de a reputacao basica estar segura. A M2.15.2
ja protegeu agregados de avaliacao; a M2.15.3 e M2.15.4 devem consolidar UI e
exposicao leve antes de ranking/discovery.

## Matching Automatico

O matching automatico deve evoluir com sinais reais:

```text
proximidade
disponibilidade
categoria/servico
perfil completo
reputacao real
historico de conclusao
equilibrio para novos prestadores
```

Nao usar pagamento como sinal de qualidade. Destaques pagos, se existirem no
futuro, devem ser rotulados como patrocinados e separados do ranking organico.

## Perfil Publico

O perfil publico do prestador deve funcionar como montra profissional:

```text
foto/avatar
nome publico
bio/descricao
cidade/area atendida
servicos/categorias
portfolio
badges leves
reputacao real quando existir
contacto profissional opcional, se houver consentimento claro
```

O perfil nao deve mostrar:

```text
identidade verificada sem KYC real
certificacao sem processo real
pagamento seguro sem pagamento real
garantia absoluta
dados pessoais sensiveis sem opt-in
```

## Trust & Safety Como Produto

Como o ChegaJa tera conteudo gerado por utilizadores, a seguranca nao e um
extra. E parte do produto.

Conteudos que exigem controlo:

```text
perfil publico
foto/avatar
portfolio
futuro video
servicos personalizados
chat/mensagens
avaliacoes/comentarios
```

Antes de escala publica, o app deve ter uma base de:

```text
termos de uso
politica de conteudo proibido
denuncia
bloqueio
fila de moderacao
contacto de suporte
auditoria interna
```

## Admin e Operacao

O dono/equipa precisam de um backoffice gradual para:

```text
ver metricas basicas
ver prestadores ativos
ver pedidos
ver avaliacoes e denuncias
gerir categorias
gerir perfis reportados
acompanhar KYC futuro
acompanhar suporte
```

Isto pertence ao Bloco J/T e deve vir depois de os fluxos base e a reputacao
leve estarem seguros.

## Monetizacao Futura

Monetizacao deve vir depois de validacao de produto e seguranca:

```text
comissao real
pagamento real
planos PRO
destaque patrocinado com rotulo claro
prioridade de pedido
```

Regras:

```text
nao vender badge de confianca
nao vender "verificado"
nao misturar pago com qualidade organica
rever regras de Apple/Google antes de qualquer boost digital ou plano PRO
```

## Encaixe no Roadmap

Estado atual:

```text
M2.14: fechada no escopo de perfil, portfolio e confianca leve
M2.15.1: fechada
M2.15.2: fechada
M2.15.3: proximo passo - UI de avaliacao pos-servico
R: pausado por falta de tester humano
M: pausado por falta de Android fisico
```

Sequencia recomendada:

```text
M2.15.3 - UI de avaliacao pos-servico
M2.15.4 - reputacao leve no perfil publico
M2.15.5 - QA final da M2.15
M2.16 - discovery, pesquisa manual e perfis pesquisaveis
M2.17 - Trust & Safety base
M2.18 - admin/backoffice leve
```

## Referencias Externas Verificadas

```text
Apple App Store Review Guidelines:
https://developer.apple.com/app-store/review/guidelines/

Google Play User Generated Content policy:
https://support.google.com/googleplay/android-developer/answer/9876937

Firebase Firestore field rules:
https://firebase.google.com/docs/firestore/security/rules-fields

Firebase write-time aggregations:
https://firebase.google.com/docs/firestore/solutions/aggregation
```
