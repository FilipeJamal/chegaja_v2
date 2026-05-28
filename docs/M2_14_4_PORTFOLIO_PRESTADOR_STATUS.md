# M2.14.4 - Gestao do Portfolio do Prestador

Data: 2026-05-28

## Estado

```text
M2.14.4: concluida
Bloco F: ativo
Bloco R: pausado por falta de tester humano real
Bloco M: pausado por falta de Android fisico real
R1: continua pendente
M2.6: continua pendente
```

## Objetivo

Melhorar a experiencia do Prestador ao gerir o proprio portfolio, mantendo o
modelo atual de `portfolioUrls`, Storage em `prestadores/{uid}/portfolio/...`
e preview com `MediaViewerScreen`.

## Alteracoes Executadas

```text
PrestadorPerfilScreen passou a usar uma secao dedicada de portfolio.
Criado PrestadorPortfolioManagerSection como widget puro e testavel.
Estado vazio mais humano e explicativo.
Contador/limite recomendado visivel: 0/12, 5/12, etc.
Botao de adicionar imagens mostra estado de carregamento.
Upload evita duplo clique enquanto esta ativo.
Upload preserva imagens que subiram se houver falha parcial.
Remocao agora pede confirmacao antes de alterar portfolioUrls.
Remocao restaura lista local se a gravacao em Firestore falhar.
Preview continua a abrir com MediaViewerScreen.
Grid responsiva para mobile/tablet/desktop.
Dark mode usa ColorScheme, sem texto preto hardcoded na nova secao.
```

## Modelo Preservado

```text
portfolioUrls continua a ser o campo principal.
ImagePicker.pickMultiImage(imageQuality: 85) foi preservado.
Upload continua em prestadores/{uid}/portfolio/...
Firestore doc prestadores/{uid} continua a guardar portfolioUrls.
Storage Rules nao foram alteradas.
Firestore Rules nao foram alteradas.
Cloud Functions nao foram alteradas.
```

## Testes Criados

Ficheiro:

```text
test/features/prestador/prestador_perfil_portfolio_test.dart
```

Cobertura:

```text
estado vazio e contador recomendado
imagens existentes e callback de preview
botao de upload bloqueado durante carregamento
dialogo de confirmacao antes de remover imagem
cancelar no dialogo nao remove
confirmar no dialogo chama callback de remocao
dark mode usa cores do tema
layout aguenta varias imagens sem overflow
```

## Fora do Escopo Mantido

```text
Nao houve KYC real.
Nao houve verificacao documental.
Nao houve pagamentos reais.
Nao houve reviews completas.
Nao houve moderacao/denuncias.
Nao houve reordenacao manual de imagens.
Nao houve legendas ricas.
Nao houve video no portfolio.
Nao houve compressao avancada propria.
Nao houve backend novo.
Nao houve alteracao em Firestore Rules.
Nao houve alteracao em Storage Rules.
Nao houve alteracao em Cloud Functions.
Nao houve deploy.
Nao houve Android fisico.
Nao houve tester externo.
R1 nao foi fechado.
M2.6 nao foi fechada.
```

## Proximo Passo

```text
M2.14.5 - Consolidar confianca/badges sem KYC real
```

Nota: parte dos badges leves e do cartao de confianca ja entrou na M2.14.3.
A M2.14.5 deve consolidar textos, limites e documentacao sem repetir trabalho
nem criar KYC, verificacao oficial ou promessas de certificacao.
