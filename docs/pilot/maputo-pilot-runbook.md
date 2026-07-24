# P1.10 — Piloto controlado ChegaJá em Maputo

Estado em 20 de julho de 2026: **ensaio técnico executado; piloto com pessoas reais ainda não iniciado**.

> **Baseline histórica:** a decisão operacional atual é preparar primeiro um
> piloto em Coimbra, Portugal. Este runbook não deve ser executado nem
> renomeado sem adaptar mercado, moeda, limites geográficos, telefone, legal,
> pagamentos, suporte e coorte. Ver
> `docs/product/MARKET_LEADERSHIP_SOURCE_OF_TRUTH.md`.

Este documento é o procedimento operacional. Não transforma ausência de participantes, validação jurídica ou dispositivo físico em aprovação.

## Objetivo

Provar, com segurança, que Prestadores em Maputo/Matola recebem oportunidades e conseguem concluir o primeiro trabalho remunerado, e que Clientes obtêm resposta e voltam a usar o ChegaJá.

Métrica central:

> Percentagem de Prestadores ativos na coorte que concluem o primeiro trabalho remunerado até 30 dias após a entrada no piloto.

O backend calcula esta métrica em `admin_getPilotMetrics` e cria snapshots agregados diários em `pilot_metrics_daily`. Cada push de matching gera um registo privado em `provider_opportunities`; nenhum snapshot diário contém UIDs.

## Escopo fixo

- Plataforma: Android release assinado.
- Idioma: português.
- Área: Maputo e Matola; coordenadas fora da bounding box configurada são rejeitadas server-side.
- Moeda: MZN/MT.
- Acesso: somente UIDs ativos em `pilot_participants`, adicionados pelo backoffice e auditados.
- Elegibilidade: pelo menos 18 anos, telefone confirmado, Termos/Privacidade atuais e função autorizada na coorte.
- Pagamento: dinheiro. M-Pesa/e-Mola/Stripe permanecem desligados até validação própria.
- Categorias promovidas: limpeza, beleza, alimentação por encomenda, reparações domésticas, tecnologia, eventos/fotografia.
- Catálogo: permanece amplo. “Outro serviço” entra em revisão server-side.
- Cuidados de crianças/pessoas e categorias de risco: não são promovidos; exigem política/aprovação específica ou permanecem indisponíveis.

Fora do piloto por feature flag e Rules: stories, chamadas de áudio/vídeo, subscrições, KYC, Stripe, ranking avançado, outros idiomas e aplicação pública Windows/web.

## Ondas

Os números abaixo são limites operacionais, não metas comerciais.

1. Onda 0 — equipa: até 4 Clientes e 4 Prestadores conhecidos; pedidos simulados e sem dados desnecessários.
2. Onda 1 — controlada: até 30 Clientes e 15 Prestadores, distribuídos pelos seis grupos promovidos.
3. Onda 2 — expansão: só após sete dias sem incidente P0/P1, suporte dentro da capacidade e gates de conversão/segurança aprovados.

Não adicionar todos os participantes de uma vez. Um Prestador só fica pesquisável após: allowlist ativa, telefone, consentimento, serviços aprovados e perfil mínimo.

## Entrada de participante

1. Confirmar 18+, Maputo/Matola, função e consentimento de participação.
2. Instalar o APK pelo canal interno aprovado; nunca enviar keystore ou ficheiros de configuração.
3. Criar/associar conta a Phone Auth. A sessão anónima é ligada à conta para preservar favoritos e pedidos.
4. O operador obtém o Firebase UID no backoffice e abre **Piloto Maputo**.
5. Seleciona Cliente/Prestador, cidade e coorte; não grava telefone, documento ou morada em notas.
6. O backend valida que a conta existe, grava `pilot_participants`, atualiza visibilidade e cria audit log.
7. Prestador completa perfil/serviços. Categoria sensível só fica ativa após decisão do backoffice.

## Roteiro do primeiro trabalho

1. Cliente escolhe serviço, modo e localização em Maputo/Matola.
2. O backend valida catálogo, texto, pagamento e área; cria pedido privado e dispatch sanitizado.
3. Prestadores elegíveis recebem oportunidade; morada exata não aparece no dispatch.
4. Um Prestador aceita pelo callable; o dispatch aberto é removido.
5. Participantes usam chat apenas no pedido legítimo.
6. Prestador propõe valor final; Cliente confirma.
7. Cliente paga diretamente em dinheiro e confirma no fluxo.
8. Comissão e prazo aparecem apenas no estado financeiro privado do Prestador.
9. Cliente pode avaliar; ambos podem denunciar/contestar pelo suporte.

## Rotina operacional

Antes de abrir cada dia:

- rever tickets, denúncias, no-show, anomalias financeiras e pedidos de categoria;
- confirmar que KYC, Stripe, stories e chamadas continuam desligados;
- rever métricas agregadas e capacidade de suporte;
- confirmar que não há incidente aberto sem responsável.

Durante o dia:

- responder imediatamente a risco físico, localização exposta, fraude ou conta comprometida;
- não pedir documentos no chat/suporte;
- registar decisões no backoffice com motivo;
- não reduzir alcance de forma invisível por dívida de comissão.

Fim do dia:

- conferir pedidos criados/respondidos/concluídos, GMV, comissões e disputas;
- limpar apenas dados de teste identificados; nunca apagar pedidos reais sem política;
- registar incidentes, decisões e ações para o dia seguinte.

## Critérios de paragem imediata

Pausar novas entradas e novos pedidos se ocorrer qualquer um:

- leitura não autorizada de telefone, morada, coordenadas, documentos ou saldo;
- morada exata visível antes da aceitação;
- bypass de Phone Auth, consentimento ou allowlist;
- KYC/Stripe/outro meio desativado aparecer ao participante;
- cobrança, comissão ou saldo incorreto sem mecanismo de correção;
- ameaça à segurança física, exploração, fraude coordenada ou conta administrativa comprometida;
- crash/bloqueio que impeça suporte, contestação ou conclusão de trabalhos ativos.

Não apagar evidência. Desligar a superfície afetada, preservar logs mínimos, apoiar pessoas afetadas e seguir o playbook de incidentes.

## Gates para Onda 1

Todos são obrigatórios:

- `npm run p1:pilot:readiness:strict` sem falhas;
- identidade jurídica/contacto reais e revisão jurídica arquivada;
- App Check enforced no Firebase e evidência arquivada;
- package Android definitivo e build distribuído pelo canal interno;
- SHA-1/SHA-256 release registados no Firebase;
- matriz de permissões num Android físico aprovada;
- Rules/Functions/Storage testadas e implementadas no projeto alvo;
- pelo menos um operador e um suplente treinados no backoffice;
- participantes reais adicionados à allowlist e consentimento de piloto documentado;
- método de suporte e escalonamento disponível durante toda a janela.

## Saída e decisão

Após 30 dias da primeira coorte, avaliar métrica central, tempo para rendimento, resposta, conclusão, retorno de Clientes, atividade 30/90 dias, valor gerado, comissões cobradas e resolução de disputas. Expandir apenas se a segurança permanecer aceitável e a liquidez melhorar; ajustar categoria/preço/operação se houver procura sem conclusão; pausar se o risco superar a capacidade de proteção.

## Estado real desta máquina

- APK release: construído, assinado, permissões inspecionadas e executado num
  emulador temporário Android 15/API 35 x86_64.
- Certificado release: SHA-1 e SHA-256 registados na app Firebase atual.
- Android físico: não ligado; matriz física pendente.
- Package Android: `com.chegaja.app`, registado na app Firebase de produção
  `1:767588494857:android:4198384a2a6387055252d8` com certificados
  release/debug e Play Integrity preparado.
- Identidade jurídica: promotor individual identificado; email jurídico, morada
  oficial e parecer jurídico continuam pendentes.
- App Check console enforcement: não demonstrado por artefacto exportado.
- Participantes reais e trabalhos reais: não existem como evidência neste workspace.
- Deploy das mudanças P1: não deve ser feito para o projeto alvo antes de cadastrar a primeira coorte, porque a allowlist de produção bloqueia ações críticas por defeito.

Por isso, o código e a operação estão preparados para ensaio controlado, mas **o piloto real não pode ser declarado executado**.
