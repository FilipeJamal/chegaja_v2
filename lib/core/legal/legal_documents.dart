import 'package:chegaja_v2/core/config/app_config.dart';

abstract final class LegalDocuments {
  static const version = 'legal-2026-07-20-pilot-v3';
  static const effectiveDate = '20 de julho de 2026';

  static String get _responsibleContactText {
    final pendingContact = AppConfig.legalContactConfigured
        ? ''
        : ' O email jurídico e a morada oficial ainda têm de ser '
            'configurados antes do piloto externo.';
    return 'O ChegaJá é um projeto promovido por '
        '${AppConfig.legalEntityName}, ${AppConfig.legalEntityRoleLabel}. '
        'Morada para contacto: ${AppConfig.legalContactAddress}. '
        'Contacto: ${AppConfig.legalContactEmail}.$pendingContact';
  }

  static List<LegalSection> get terms => [
        const LegalSection(
          '1. O que é o ChegaJá',
          'O ChegaJá é uma plataforma tecnológica que ajuda Clientes a encontrar Prestadores e transforma competências formais e informais em oportunidades de trabalho independente. O ChegaJá não é empregador, agência de emprego nem garante rendimento, contratação ou disponibilidade de serviços.',
        ),
        const LegalSection(
          '2. Piloto e elegibilidade',
          'O piloto é controlado, inicialmente em Maputo, e destina-se a pessoas com pelo menos 18 anos. A conta deve usar informação verdadeira e telefone confirmado antes de publicar, aceitar, conversar, pagar, avaliar ou denunciar. Uma pessoa não deve criar contas para contornar bloqueios.',
        ),
        const LegalSection(
          '3. Serviços e segurança',
          'Serviços proibidos são rejeitados. Categorias sensíveis podem exigir formação, referências, documentos ou aprovação adicional. Um perfil público, selo ou avaliação não constitui garantia de identidade, licença, qualidade ou segurança além do facto específico indicado pelo selo.',
        ),
        const LegalSection(
          '4. Pedidos e localização',
          'Antes da aceitação, o Prestador recebe apenas zona e distância aproximadas. Morada, coordenadas exatas e contacto só podem ser revelados ao Prestador atribuído quando forem necessários ao trabalho. Clientes e Prestadores não devem publicar telefone, morada, documentos ou dados de pagamento em campos públicos.',
        ),
        const LegalSection(
          '5. Preço, dinheiro e comissão',
          'No piloto, o meio ativo por defeito é dinheiro e os valores são apresentados em meticais (MZN/MT). O valor final deve ser confirmado no fluxo do pedido. A comissão, isenções, prazo e eventual teto são mostrados antes de se tornarem devidos. Saldo financeiro é privado e não altera estrelas. Dívida vencida ou acima do limite pode impedir apenas a aceitação de novos trabalhos, mantendo conclusão dos atuais, chat, histórico, contestação e suporte.',
        ),
        const LegalSection(
          '6. Pagamentos digitais',
          'M-Pesa, e-Mola e Stripe não são apresentados como disponíveis até existir validação técnica, comercial e regulatória. Quando um prestador externo for ativado, os seus termos, custos, reversões e tratamento de dados serão apresentados antes da utilização.',
        ),
        const LegalSection(
          '7. Conduta e conteúdo',
          'É proibido assediar, discriminar, ameaçar, explorar vulnerabilidade, praticar fraude, solicitar atividade ilegal, manipular avaliações ou usar documentos de terceiros. O utilizador mantém direitos sobre o conteúdo que envia e concede ao ChegaJá autorização limitada para o armazenar, apresentar e moderar enquanto necessário ao serviço e à segurança.',
        ),
        const LegalSection(
          '8. Cancelamentos, denúncias e disputas',
          'Cancelamentos e faltas podem ser registados. Uma decisão financeira, de moderação ou segurança pode ser contestada pelo suporte. O ChegaJá pode preservar evidência estritamente necessária enquanto a disputa estiver ativa e deve comunicar o resultado disponível ao utilizador afetado.',
        ),
        const LegalSection(
          '9. Suspensão e encerramento',
          'O ChegaJá pode limitar funcionalidades por risco de segurança, fraude, incumprimento financeiro transparente ou violação destes termos. Sempre que a segurança e a lei permitam, será indicado o motivo e a forma de contestar. O utilizador pode pedir eliminação da conta; obrigações, disputas e registos legalmente necessários podem ser retidos de forma limitada ou pseudonimizada.',
        ),
        const LegalSection(
          '10. Responsabilidade e alterações',
          'Cada parte é responsável pelas suas ações, acordos e obrigações legais. Nada nestes termos elimina direitos obrigatórios do consumidor ou limita responsabilidade que a lei não permita limitar. Alterações materiais serão apresentadas com nova versão e novo consentimento antes de ações relevantes.',
        ),
        const LegalSection(
          '11. Lei e contacto',
          'Estes termos são orientados pelas leis aplicáveis da República de Moçambique. O utilizador deve tentar primeiro o suporte dentro da aplicação, sem perder o direito de recorrer às autoridades ou tribunais competentes.',
        ),
      ];

  static List<LegalSection> get privacy => [
        LegalSection(
          '1. Responsável e contacto',
          _responsibleContactText,
        ),
        const LegalSection(
          '2. Dados tratados',
          'Podemos tratar identificadores de conta e telefone, perfil profissional, cidade/zona, serviços, disponibilidade, pedidos, chat, anexos, avaliações, denúncias, suporte, localização operacional, dados técnicos de segurança e registos financeiros. KYC fica desativado até existir consentimento e infraestrutura próprios; documentos nunca devem ser enviados pelo chat ou suporte.',
        ),
        const LegalSection(
          '3. Finalidades',
          'Usamos dados para criar e proteger contas, fazer matching, executar pedidos, revelar detalhes ao Prestador atribuído, permitir comunicação, calcular comissões, resolver disputas, moderar risco, prevenir fraude, prestar suporte, medir se Prestadores conseguem trabalho e cumprir obrigações aplicáveis. Métricas devem ser agregadas sempre que possível.',
        ),
        const LegalSection(
          '4. Dados públicos e privados',
          'O perfil público pode mostrar nome profissional, fotografia autorizada, descrição, cidade/zona geral, serviços, portefólio, avaliações e sinais de confiança verdadeiros. Telefone, email, morada, coordenadas exatas, documentos, saldo, bloqueios e disputas são privados. A interface não é a barreira: Rules e backend aplicam esta separação.',
        ),
        const LegalSection(
          '5. Localização',
          'A autorização do dispositivo é pedida durante a utilização. Pedidos abertos usam uma projeção aproximada. Detalhes exatos só são partilhados com participantes legítimos quando necessários. Não fazemos tracking de localização em background no piloto.',
        ),
        const LegalSection(
          '6. Partilha e prestadores',
          'Partilhamos o mínimo necessário com o outro participante do trabalho, administradores autorizados e fornecedores técnicos como Firebase/Google. Um prestador de pagamento só recebe dados quando o método correspondente estiver ativo e for escolhido. Não vendemos dados pessoais nem pedimos identificador publicitário para o piloto.',
        ),
        const LegalSection(
          '7. Armazenamento internacional e segurança',
          'Fornecedores de infraestrutura podem processar dados fora de Moçambique. Aplicamos controlo de acesso, App Check, autenticação, Rules, caminhos privados, logs administrativos e retenção limitada. Nenhum sistema é infalível; incidentes devem ser investigados e comunicados conforme o risco e a lei aplicável.',
        ),
        const LegalSection(
          '8. Retenção',
          'Perfis e dados operacionais ficam enquanto a conta estiver ativa. Pedidos e chat são mantidos pelo período necessário ao serviço, suporte e disputas. KYC pendente, quando ativado, tem retenção própria. Pedidos de eliminação entram num prazo de segurança de 7 dias; depois, dados de perfil são apagados e registos transacionais necessários são eliminados, redigidos ou pseudonimizados conforme a política documentada.',
        ),
        const LegalSection(
          '9. Direitos e escolhas',
          'O utilizador pode consultar e corrigir o perfil, recusar permissões, pedir acesso, correção ou eliminação, contestar decisões e contactar suporte. A Constituição moçambicana reconhece acesso e retificação de dados pessoais informatizados. Uma recusa de permissão mantém alternativas manuais quando possível.',
        ),
        const LegalSection(
          '10. Crianças e alterações',
          'O piloto não aceita pessoas com menos de 18 anos. Se detetarmos conta de menor, limitamos o acesso e tratamos a eliminação segura. Alterações materiais desta política recebem nova versão e exigem novo consentimento antes de ações relevantes.',
        ),
      ];
}

class LegalSection {
  const LegalSection(this.title, this.body);

  final String title;
  final String body;
}
