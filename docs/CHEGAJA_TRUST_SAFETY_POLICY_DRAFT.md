# ChegaJa - Trust & Safety Policy Draft

Data: 2026-05-29

## Estado

Rascunho de politica interna para orientar produto, UI, Rules, moderacao e
futuro backoffice. Nao e ainda politica legal final nem substitui revisao
juridica.

## Porque Isto Existe

O ChegaJa tera conteudo gerado por utilizadores:

```text
perfil publico
bio/descricao
foto/avatar
portfolio
futuro video
servicos personalizados
chat
avaliacoes
comentarios futuros
```

Apps com UGC precisam de mecanismos claros de denuncia, bloqueio, moderacao e
resposta a abuso. Apple e Google documentam exigencias para apps com conteudo
gerado por utilizadores, incluindo filtro/moderacao, report, block e resposta a
conteudo abusivo.

## Conteudo Proibido

O ChegaJa nao deve permitir:

```text
prostituicao ou facilitacao de exploracao sexual
trafico humano
venda ou promocao de drogas ilegais
armas ilegais
violencia, ameacas ou extorsao
fraude e burla
conteudo sexual explicito
odio, assedio ou discriminacao
servicos ilegais ou sem licenca obrigatoria
documentos falsos
imagens roubadas ou enganadoras
spam
tentativa de contornar pagamentos/comissao quando houver pagamentos reais
```

## Categorias Sensíveis

Algumas categorias podem exigir aprovacao futura antes de publicacao:

```text
eletricidade
gas
saude/bem-estar sensivel
cuidados com criancas/idosos
seguranca privada
alimentacao profissional
servicos com acesso a casa do Cliente
servicos que exijam licenca ou certificacao local
```

Estado recomendado:

```text
MVP/beta: bloquear ou marcar como "em analise" quando necessario.
Futuro: comprovativo profissional, fila de aprovacao e auditoria.
```

## Denuncia e Bloqueio

Futuro minimo antes de escala publica:

```text
Denunciar perfil
Denunciar portfolio/media
Denunciar mensagem
Denunciar avaliacao/comentario
Bloquear utilizador em chat/interacao
```

Cada denuncia deve guardar:

```text
reporterId
targetType
targetId
motivo
descricao opcional
createdAt
status
assignedTo futuro
decision futuro
audit log
```

## Moderacao

Estados recomendados:

```text
pending
approved
rejected
hidden
needs_review
blocked
appealed
```

Moderacao deve ser aplicada primeiro a:

```text
servicos personalizados
perfil publico
portfolio
avaliacoes publicas
mensagens reportadas
```

## Niveis de Confianca

Niveis permitidos sem KYC real:

```text
Perfil ativo
Foto adicionada
Area definida
Portfolio adicionado
Avaliacao de clientes, quando houver dados reais
```

Niveis proibidos sem processo real:

```text
Identidade verificada
Documento verificado
Prestador certificado
Pagamento seguro
Garantido pelo ChegaJa
Profissional aprovado oficialmente
```

Futuro com KYC:

```text
Documento submetido
Documento em analise
Identidade verificada
Comprovativo profissional aprovado
Categoria sensivel aprovada
```

## Contactos

Regras recomendadas:

```text
contacto pessoal fica privado por defeito
contacto profissional publico deve ser opt-in
mostrar contacto so quando houver contexto de servico ou consentimento claro
separar dados privados do perfil publico
nao expor telefone em listas/search sem decisao explicita
```

## Avaliacoes e Comentarios

Estado atual:

```text
M2.15.2 fechou a seguranca das avaliacoes e agregados.
M2.15.3 deve melhorar UI pos-servico.
M2.15.4 pode mostrar reputacao leve no perfil publico.
```

Politica:

```text
avaliacao so depois de pedido concluido
cliente so avalia pedido proprio
sem avaliacao duplicada
comentario publico fica fora ate existir decisao de privacidade/moderacao
rating medio so com dados reais
```

## Admin e Suporte

Backoffice futuro deve permitir:

```text
ver denuncias
decidir ocultar/restaurar conteudo
ver historico de decisoes
gerir categorias sensiveis
gerir perfis bloqueados
gerir recursos/apelos
ver metricas de abuso
```

## Fora do Escopo Imediato

```text
KYC completo
moderacao automatica pesada
analise de video
resposta do prestador a reviews
ranking publico complexo
pagamentos reais
Play Store/App Store submission
```

## Referencias Externas Verificadas

```text
Apple App Store Review Guidelines:
https://developer.apple.com/app-store/review/guidelines/

Google Play User Generated Content policy:
https://support.google.com/googleplay/android-developer/answer/9876937
```
