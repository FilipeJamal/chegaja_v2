# M2.15.4 - Reputacao Leve no Perfil Publico

Data: 2026-05-29

## Estado

```text
M2.15.4: concluida
M2.15.5: proximo passo - testes, E2E, QA visual e documentacao final da M2.15
Bloco H: ativo
Bloco F: parcial
R: pausado por falta de tester humano real
M: pausado por falta de Android fisico real
R1: pendente
M2.6: pendente
```

## Resultado

O perfil publico do prestador passou a mostrar reputacao leve baseada apenas em
agregados seguros do documento `prestadores/{prestadorId}`:

```text
ratingAvg
ratingCount
```

A media so aparece quando:

```text
role == prestador
ratingCount > 0
ratingAvg e numerico
ratingAvg esta entre 1 e 5
```

## Como Aparece

Com avaliacao valida:

```text
Avaliacao media
4,8 de 5
Baseado em 12 avaliacoes
```

Com uma avaliacao:

```text
Baseado em 1 avaliacao
```

Sem avaliacao valida:

```text
Ainda sem avaliacoes publicas
Quando clientes concluirem servicos e avaliarem, a media aparecera aqui.
```

## Guardrails Mantidos

```text
Nao lista documentos da colecao avaliacoes.
Nao usa AvaliacaoRepo no perfil publico.
Nao mostra comentarios publicos.
Nao mostra nome/foto de Cliente.
Nao abre leitura publica de avaliacoes.
Nao cria ranking.
Nao cria badge novo de verificacao/certificacao.
```

## Textos Proibidos Mantidos Fora

```text
Prestador verificado
Prestador certificado
Garantido pelo ChegaJa
Pagamento seguro
Identidade confirmada
Verificado oficialmente
Servicos concluidos
Prestador disponivel
```

## Rules, Functions e Deploy

```text
Firestore Rules: nao alteradas nesta fase
Storage Rules: nao alteradas nesta fase
Cloud Functions: nao alteradas nesta fase
Deploy: nao feito
```

## Testes

Foram atualizados testes em:

```text
test/features/common/perfil_publico_screen_test.dart
```

Cobertura adicionada:

```text
prestador com ratingAvg/ratingCount validos mostra reputacao media
ratingAvg e mostrado com uma casa decimal
ratingCount 1 usa singular
ratingCount > 1 usa plural
perfil sem rating mostra estado neutro
ratingCount 0 mostra estado neutro
ratingAvg ausente mostra estado neutro
ratingAvg abaixo de 1 nao mostra media
ratingAvg acima de 5 nao mostra media
perfil de cliente nao mostra reputacao de prestador
textos proibidos continuam fora
dark mode renderiza sem excecao
```

## Decisao

A M2.15.4 fica fechada no escopo de reputacao leve no perfil publico.

Comentarios publicos, reviews completas, moderacao, denuncias, ranking e
discovery continuam fora desta fase.

## Proximo Passo

```text
M2.15.5 - Testes, E2E, QA visual e documentacao final da M2.15
```
