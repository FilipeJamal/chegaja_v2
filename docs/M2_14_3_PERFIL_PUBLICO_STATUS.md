# M2.14.3 - Perfil Publico do Prestador

Data: 2026-05-28

## Estado

```text
M2.14.3: concluida
Bloco F: ativo
Bloco R: pausado por falta de tester humano real
Bloco M: pausado por falta de Android fisico real
R1: continua pendente
M2.6: continua pendente
```

## Objetivo

Melhorar o perfil publico do prestador para que o Cliente consiga avaliar melhor
quem e o prestador, onde atende, que servicos faz e se tem sinais minimos de
confianca antes de contactar, convidar ou aceitar uma proposta.

## Alteracoes Executadas

```text
PublicProfileScreen evoluido sem criar tela duplicada.
API publica preservada: userId, role, initialName e initialPhotoUrl.
Injecao opcional de FirebaseFirestore adicionada apenas para testes.
Leitura preservada:
- prestadores/{userId} quando role == prestador
- users/{userId} para outros roles
```

## UI/UX

```text
Header premium com avatar, nome, papel e localizacao.
Cartao de confianca para prestadores.
Secao Sobre com estado de perfil incompleto.
Secao Area atendida com cidade/pais e radiusKm quando existe.
Secao Servicos com chips responsivos.
Secao Portfolio com contagem, estado vazio, loadingBuilder e errorBuilder.
Secao Contacto preservada quando telefone ja existe.
Layout responsivo com largura maxima para desktop/wide.
Dark mode usa ColorScheme em vez de cores fixas escuras/claras.
```

## Badges Leves

Badges permitidos e implementados:

```text
Foto adicionada
Area definida
Portfolio adicionado
Perfil ativo
```

Badges que continuam fora:

```text
Prestador disponivel
Servicos concluidos
Identidade verificada
Documento verificado
Prestador certificado
Pagamento seguro
Profissional aprovado oficialmente
```

## Portfolio Publico

```text
portfolioUrls e portfolioImages continuam suportados.
URLs vazios sao removidos.
Duplicados sao removidos.
Contagem de imagens e mostrada.
Estado vazio orienta o Cliente sem inventar dados.
Imagem quebrada nao quebra a tela.
Clique em imagem continua a abrir MediaViewerScreen.
```

## Testes Criados

Ficheiro:

```text
test/features/common/perfil_publico_screen_test.dart
```

Cobertura:

```text
renderiza nome, bio, localizacao, servicos e portfolio
mostra fallback com inicial quando nao ha foto
mostra Foto adicionada
mostra Area definida
mostra Portfolio adicionado
mostra Perfil ativo
mostra estado vazio de portfolio
nao mostra badges proibidos
imagem quebrada no portfolio nao quebra a tela
dark mode usa contraste do tema nos blocos principais
```

## Fora do Escopo Mantido

```text
Nao houve KYC real.
Nao houve verificacao documental.
Nao houve pagamentos reais.
Nao houve reviews completas.
Nao houve moderacao/denuncias.
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
M2.14.4 - Melhorar gestao do portfolio no perfil do prestador
```
