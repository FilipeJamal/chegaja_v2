# Playbook de incidentes — piloto Maputo

## Severidade

- P0: risco físico iminente, exposição de documento/morada/coordenada em massa, conta admin comprometida, pagamento indevido sistémico.
- P1: acesso indevido individual, fraude credível, bypass de identidade/allowlist, ameaça/assédio, saldo incorreto que bloqueia trabalho.
- P2: falha funcional sem exposição, atraso de suporte, erro recuperável de matching/comissão.
- P3: defeito cosmético, texto/confusão sem impacto operacional imediato.

## Primeiros passos

1. Proteger pessoas: recomendar emergência/autoridades quando houver risco físico; não prometer capacidade policial.
2. Conter: pausar novas entradas/pedidos ou desligar a feature afetada; manter chat/suporte para trabalhos ativos quando seguro.
3. Preservar: IDs, timestamps, audit logs e versão do APK. Não copiar documentos para tickets ou canais informais.
4. Avaliar dados: que campos, pessoas, período e sistemas foram afetados.
5. Corrigir e validar em emulador/staging; revisão por segunda pessoa para P0/P1.
6. Comunicar de forma clara às pessoas afetadas e cumprir obrigações aplicáveis após orientação jurídica.
7. Fechar com causa, impacto, ações, proprietário e prevenção; nunca esconder o incidente em métricas agregadas.

## Rotas específicas

- Localização exposta: remover dispatch, suspender criação, verificar Rules/projeção e avisar a pessoa afetada.
- Conta comprometida: revogar tokens, desativar allowlist/perfil, preservar audit log, recuperar Phone Auth.
- Fraude/assédio: impedir novos trabalhos, manter contestação, preservar mensagens estritamente necessárias, encaminhar moderação.
- Comissão incorreta: suspender enforcement financeiro, recalcular server-side, corrigir ledger e comunicar antes de reativar.
- Documento em chat/suporte: restringir acesso, remover do canal, orientar envio apenas pelo KYC seguro quando/ se ativado.

## Contactos

Antes da Onda 0 devem ser preenchidos fora do repositório: responsável operacional, suplente, responsável técnico, aconselhamento jurídico e contacto de emergência local. Sem estes responsáveis, o piloto não abre.
