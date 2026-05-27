# AGENTS.md — Regras do Codex para o ChegaJá v2

## Papel do agente

És um agente de desenvolvimento a trabalhar no projeto ChegaJá v2, uma app Flutter + Firebase com fluxos Cliente/Prestador, pedidos, notificações, hosting, Firestore, Functions, Storage, Android, Windows e testes automatizados.

Trabalha como engenheiro cuidadoso, não como “vibe coder”.

## Regra principal

Nunca faças alterações grandes sem primeiro:
1. Entender o objetivo.
2. Identificar ficheiros prováveis.
3. Fazer uma alteração pequena e testável.
4. Correr validações.
5. Reportar claramente o que mudou.

## Regras de segurança do projeto

- Não apagar ficheiros temporários `~$...pptx`.
- Não alterar regras Firestore, Storage ou Functions sem necessidade explícita.
- Não alterar arquitetura global sem justificar.
- Não mudar nomes de coleções ou estados sem mapear impacto.
- Não trocar Firebase Hosting clássico por App Hosting.
- Não guardar tokens, secrets, credenciais, chaves privadas ou `.env` sensíveis no repositório.
- Não dizer que deploy, teste, build, commit ou push foi feito sem prova real no terminal.
- Não esconder falhas. Se algo falhar, explicar o erro e a correção proposta.

## Filosofia retirada do workflow do vídeo

O Codex é útil quando o humano guia bem:

- Para UI, usar referências visuais, screenshots e feedback específico.
- Para funcionalidades frágeis, fazer primeiro um protótipo pequeno.
- Para bugs, reproduzir, tirar screenshot/log, corrigir e testar de novo.
- Para cada mudança, verificar se não quebrou fluxos antigos.
- Fazer commit quando a alteração está estável antes de adicionar mais trabalho.

## Fluxos fundamentais do ChegaJá

Preservar estes fluxos:

- Cliente cria pedido.
- Prestador vê pedidos perto de si.
- Prestador aceita pedido.
- Cliente vê prestador encontrado.
- Pedido por orçamento/proposta permite proposta do prestador e decisão do cliente.
- Estados principais: `criado`, `aguarda_resposta_cliente`, `aceito`, `em_andamento`, `aguarda_confirmacao_valor`, `concluido`, `cancelado`.
- Ganhos do prestador só entram quando o pedido é corretamente concluído.
- Notificações FCM e deep links devem continuar coerentes.

## Comandos mínimos de validação

Sempre que a alteração tocar Flutter:

```powershell
flutter test --no-pub
```

Sempre que tocar Functions:

```powershell
cd functions
npm.cmd test
cd ..
```

Sempre que tocar scripts:

```powershell
npm.cmd run test:scripts
```

Sempre que tocar em Firestore/Storage/Functions:

```powershell
npx.cmd firebase emulators:exec --only firestore,storage,functions "cd functions && npm.cmd test"
```

Antes de commit importante:

```powershell
git status --short
flutter test --no-pub
cd functions && npm.cmd test
```

## Relatório final obrigatório

No fim de cada tarefa, responder com:

- Objetivo da tarefa.
- Ficheiros alterados.
- O que foi implementado.
- Testes executados.
- Resultado dos testes.
- O que não foi possível validar.
- Próximo passo recomendado.
- Commit hash, se foi feito commit.
