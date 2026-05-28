# M2.14.5 - Confianca e Badges do Prestador

Data: 2026-05-28

## Estado

```text
M2.14.5: concluida
Bloco F: ativo
Bloco R: pausado por falta de tester humano real
Bloco M: pausado por falta de Android fisico real
R1: continua pendente
M2.6: continua pendente
```

## Decisao

A M2.14.5 consolidou a camada de confianca leve do perfil publico do
prestador sem criar KYC real, verificacao documental, certificacao oficial ou
promessa de pagamento seguro.

Os badges continuam a ser inferidos apenas de dados ja existentes no perfil.
Eles ajudam o Cliente a perceber se o perfil esta minimamente preenchido, mas
nao representam aprovacao oficial do ChegaJa.

## Badges Permitidos

| Badge | Fonte de dados | Risco | Decisao |
| --- | --- | --- | --- |
| Foto adicionada | `photoUrl`, `fotoUrl`, `avatarUrl` ou `initialPhotoUrl` com URL valida | Baixo | Mantido |
| Area definida | cidade/pais ou `radiusKm` valido | Baixo | Mantido |
| Portfolio adicionado | `portfolioUrls` ou `portfolioImages` com pelo menos uma URL valida | Baixo | Mantido |
| Perfil ativo | nome + pelo menos um dado real complementar: bio, foto, servicos, localizacao ou portfolio | Baixo | Mantido |

## Badges e Textos Proibidos

Estes textos continuam proibidos nesta fase:

```text
Identidade verificada
Documento verificado
Prestador certificado
Pagamento seguro
Profissional aprovado oficialmente
Verificado oficialmente
Certificado pelo ChegaJa
Garantido pelo ChegaJa
```

Motivo:

```text
O produto ainda nao tem KYC real, validacao documental, moderacao oficial,
certificacao formal ou pagamentos reais fechados.
```

## Textos Adiados

```text
Prestador disponivel
Servicos concluidos
```

Motivo:

```text
Ainda falta uma fonte consolidada e validada para disponibilidade real e
contagem confiavel de servicos concluidos. Estes textos nao devem aparecer no
perfil publico ate essa base existir.
```

## Testes

Ficheiro atualizado:

```text
test/features/common/perfil_publico_screen_test.dart
```

Cobertura reforcada:

```text
perfil com dados reais mostra os quatro badges permitidos
perfil incompleto nao mostra badges de confianca
tela nao mostra textos de verificacao/certificacao/pagamento seguro
tela continua sem "Prestador disponivel" e "Servicos concluidos"
dark mode do perfil publico continua validado
```

## Fora do Escopo Mantido

```text
KYC real
verificacao documental
pagamentos reais
reviews completas
ranking de reputacao
moderacao
denuncias
Firestore Rules
Storage Rules
Cloud Functions
deploy
Android fisico
tester externo
fechar R
fechar R1
fechar M
fechar M2.6
```

## Resultado

```text
A camada de confianca ficou honesta e segura para a fase atual.
Nenhum badge promete verificacao oficial.
Nenhum campo novo foi criado.
Nenhuma Rule/Function foi alterada.
```

## Proximo Passo

```text
M2.14.6 - Integrar perfil publico nos pontos principais do fluxo Cliente
```
