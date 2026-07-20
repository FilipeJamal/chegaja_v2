# Retenção, eliminação e suporte — piloto ChegaJá

Estado: implementação técnica do piloto, sujeita a validação jurídica e operacional antes de participantes externos.

## Princípios

- Recolher apenas dados necessários ao serviço, segurança, suporte e obrigações aplicáveis.
- Manter dados públicos separados dos privados por coleção, Storage e regras server-side.
- Não usar chat ou suporte para documentos de identidade, PINs ou dados completos de pagamento.
- Dar ao utilizador acesso a suporte, contestação e eliminação dentro da aplicação.
- Não definir períodos legais absolutos sem validação de advogado e da entidade financeira aplicável.

## Ciclo de eliminação

1. O utilizador autenticado e com telefone confirmado aceita a versão jurídica atual e escreve `ELIMINAR`.
2. O backend recusa o pedido se existirem trabalhos ativos, para não abandonar a outra parte sem resolução.
3. O perfil público é escondido imediatamente e a aceitação de novos trabalhos é suspensa.
4. Existe um prazo reversível de 7 dias. O próprio utilizador pode cancelar durante esse prazo.
5. Após o prazo, uma tarefa server-side elimina autenticação, perfis, dados privados, KYC e ficheiros pessoais conhecidos.
6. Chat e suporte do utilizador são eliminados. Identificadores em pedidos, avaliações e registos financeiros necessários são substituídos por um pseudónimo HMAC não reversível.
7. O backend conserva apenas um registo técnico pseudonimizado da conclusão da eliminação.

O segredo `ACCOUNT_DELETION_PEPPER` é obrigatório em produção, deve ter alta entropia e não pode existir no cliente ou no repositório.

## Quarentena de migração do Storage

Objetos antigos sem qualquer referência ativa são movidos para
`migration_quarantine/`, sem token de download e sem leitura por clientes. O
bucket elimina automaticamente apenas esse prefixo após 30 dias. A quarentena
existe para recuperação operacional curta durante o corte; não é um arquivo
permanente nem pode ser usada para novas submissões.

Uploads temporários em `temp/` são eliminados automaticamente após 2 dias. O
pedido final usa uma cópia privada em `pedidos/{pedidoId}/anexos/`; nenhum URL
persistente é guardado no documento do pedido.

## Retenção por classe

| Classe | Estado no piloto | Regra operacional |
|---|---|---|
| Perfil público e privado | Ativo enquanto a conta existir | Eliminar no fim do prazo de 7 dias |
| Localização exata | Apenas no pedido privado legítimo | Redigir ao eliminar a conta; nunca copiar para dispatch público |
| Chat | Durante conta/trabalho/disputa | Eliminar com a conta, salvo preservação específica e documentada por disputa ativa |
| Suporte | Enquanto necessário para resolver o ticket | Eliminar com a conta; não aceitar documentos de identidade |
| Pedidos concluídos | Necessário para histórico operacional/financeiro | Pseudonimizar ao eliminar a conta |
| Pagamentos e comissões | Conforme necessidade contabilística, financeira e de disputa | Pseudonimizar; período final depende de validação jurídica/contabilística |
| KYC | Feature flag desligada | Quando ativado: Storage privado, acesso auditado e retenção configurada; implementação atual apaga documentos aos 90 dias |
| Logs de segurança | Prazo mínimo proporcional ao risco | TTL final deve ser aprovado antes do piloto externo |

## Incidentes, pedidos e contestação

- O formulário de suporte cria tickets exclusivamente por callable; o cliente não escolhe estado, identidade ou timestamps.
- O utilizador vê os próprios tickets; administradores autorizados gerem estados com audit log.
- Decisões de moderação, finanças ou segurança devem indicar motivo quando seguro e oferecer contestação.
- Um incidente com dados deve ser registado, contido, avaliado e comunicado conforme risco e lei aplicável.

## Aprovações obrigatórias antes do piloto externo

- Identidade jurídica, endereço e contacto reais do responsável pelo ChegaJá.
- Revisão dos Termos e Política de Privacidade por advogado em Moçambique.
- Prazos de retenção contabilística, fiscal, financeira, de disputas e segurança.
- Processo de resposta a pedidos de acesso, correção, eliminação e incidentes.
- Contratos e transferências internacionais com fornecedores de infraestrutura e pagamentos.

## Referências oficiais usadas na preparação

- Constituição da República de Moçambique, incluindo acesso e retificação de dados informatizados: <https://www.portaldogoverno.gov.mz/por/content/download/4423/32819/version/1/file/constituicao.pdf>
- Lei n.º 3/2017, de 9 de Janeiro, Lei das Transacções Electrónicas: <https://www.inm.gov.mz/pt-br/content/br-n%C2%BA-5-de-090117-boletim-da-rep%C3%BAblica-i-serie>
- Banco de Moçambique, Conduta e Proteção do Consumidor Financeiro: <https://www.bancomoc.mz/pt/areas-de-actuacao/supervisao/conduta/>

Estas referências não substituem aconselhamento jurídico para a operação concreta do piloto.
