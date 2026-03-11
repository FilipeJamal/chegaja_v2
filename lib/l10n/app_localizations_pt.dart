// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'ChegaJá';

  @override
  String get roleSelectorWelcome => 'Bem-vindo ao ChegaJá';

  @override
  String get roleSelectorPrompt => 'Escolhe como queres usar o app:';

  @override
  String get roleCustomerTitle => 'Sou cliente';

  @override
  String get roleCustomerDescription =>
      'Quero encontrar prestadores de serviço perto de mim.';

  @override
  String get roleProviderTitle => 'Sou prestador';

  @override
  String get roleProviderDescription =>
      'Quero receber pedidos de clientes e ganhar mais.';

  @override
  String get invalidSession => 'Sessão inválida.';

  @override
  String get paymentsTitle => 'Pagamentos (Stripe)';

  @override
  String get paymentsHeading => 'Receber pagamentos online';

  @override
  String get paymentsDescription =>
      'Para receber pagamentos via app, precisas criar uma conta Stripe (Connect Express).\nO onboarding abre no teu browser e demora 2–3 minutos.';

  @override
  String get paymentsActive => 'Pagamentos online ATIVOS.';

  @override
  String get paymentsInactive =>
      'Pagamentos ainda não ativos. Faz o onboarding.';

  @override
  String stripeAccountLabel(Object accountId) {
    return 'Stripe account: $accountId';
  }

  @override
  String get onboardingOpened =>
      'Onboarding aberto. Depois de concluíres, volta aqui para ver o estado.';

  @override
  String onboardingStartError(Object error) {
    return 'Erro ao iniciar onboarding: $error';
  }

  @override
  String get manageStripeAccount => 'Gerir conta Stripe';

  @override
  String get activatePayments => 'Ativar pagamentos';

  @override
  String get technicalNotesTitle => 'Notas técnicas';

  @override
  String get technicalNotesBody =>
      '• O Stripe é configurado via Cloud Functions (server-side).\n• A comissão da plataforma é aplicada automaticamente no PaymentIntent.\n• Em produção, adiciona o webhook do Stripe e guarda a webhook secret nas Functions.';

  @override
  String kycTitle(Object status) {
    return 'Verificação de identidade: $status';
  }

  @override
  String get kycDescription =>
      'Envia um documento (foto ou PDF). A validação completa fica para v2.6.';

  @override
  String get kycSendDocument => 'Enviar documento';

  @override
  String get kycAddDocument => 'Adicionar documento';

  @override
  String get kycStatusApproved => 'Aprovado';

  @override
  String get kycStatusRejected => 'Rejeitado';

  @override
  String get kycStatusInReview => 'Em análise';

  @override
  String get kycStatusNotStarted => 'Não iniciado';

  @override
  String get kycFileReadError => 'Não consegui ler o ficheiro.';

  @override
  String get kycFileTooLarge => 'Ficheiro muito grande (máx. 10MB).';

  @override
  String get kycUploading => 'A enviar documento...';

  @override
  String get kycUploadSuccess => 'Documento enviado para análise.';

  @override
  String kycUploadError(Object error) {
    return 'Erro ao enviar documento: $error';
  }

  @override
  String get statusCancelledByYou => 'Cancelado por ti';

  @override
  String get statusCancelledByProvider => 'Cancelado pelo prestador';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusLookingForProvider => 'A procurar prestador';

  @override
  String get statusProviderPreparingQuote =>
      'Prestador encontrado (a preparar orçamento)';

  @override
  String get statusQuoteToDecide => 'Tens um orçamento para decidir';

  @override
  String get statusProviderFound => 'Prestador encontrado';

  @override
  String get statusServiceInProgress => 'Serviço em andamento';

  @override
  String get statusAwaitingValueConfirmation =>
      'A aguardar tua confirmação de valor';

  @override
  String get statusServiceCompleted => 'Serviço concluído';

  @override
  String valueToConfirm(Object value) {
    return '$value (a confirmar)';
  }

  @override
  String valueProposed(Object value) {
    return '$value (proposto)';
  }

  @override
  String valueEstimatedRange(Object min, Object max) {
    return '$min a $max (estimado)';
  }

  @override
  String valueEstimatedFrom(Object min) {
    return 'Desde $min (estimado)';
  }

  @override
  String valueEstimatedUpTo(Object max) {
    return 'Até $max (estimado)';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get priceFixed => 'Preço fixo';

  @override
  String get priceByQuote => 'Por orçamento';

  @override
  String get priceToArrange => 'Preço a combinar';

  @override
  String get paymentOnlineBefore => 'Pagamento online (antes)';

  @override
  String get paymentOnlineAfter => 'Pagamento online (depois)';

  @override
  String get paymentCash => 'Pagamento em dinheiro';

  @override
  String get pendingActionQuoteToReview =>
      'Tens um orçamento/proposta para analisar.';

  @override
  String get pendingActionValueToConfirm =>
      'O prestador lançou o valor final. Falta confirmares.';

  @override
  String get pendingActionProviderPreparingQuote =>
      'Prestador encontrado. Ele está a preparar o orçamento.';

  @override
  String get pendingActionProviderChat =>
      'Prestador encontrado. Podes falar com ele no chat.';

  @override
  String get roleLabelCustomer => 'Cliente';

  @override
  String get navHome => 'Início';

  @override
  String get navMyOrders => 'Meus pedidos';

  @override
  String get navMessages => 'Mensagens';

  @override
  String get navProfile => 'Perfil';

  @override
  String get homeGreeting => 'Olá';

  @override
  String get homeSubtitle => 'Do que precisas hoje?';

  @override
  String get homePendingTitle => 'Tens algo para decidir';

  @override
  String get homePendingCta =>
      'Toca aqui para abrir o próximo pedido e decidir.';

  @override
  String servicesLoadError(Object error) {
    return 'Erro ao carregar serviços: $error';
  }

  @override
  String get servicesEmptyMessage =>
      'Ainda não há serviços configurados.\\nEm breve vais ver aqui categorias para escolher 😉';

  @override
  String get availableServicesTitle => 'Serviços disponíveis';

  @override
  String get serviceTabImmediate => 'Imediato';

  @override
  String get serviceTabScheduled => 'Agendado';

  @override
  String get serviceTabQuote => 'Por orçamento';

  @override
  String get unreadMessagesTitle => 'Tens novas mensagens';

  @override
  String get unreadMessagesCta => 'Toca aqui para abrir o chat.';

  @override
  String get serviceSearchHint => 'Procurar serviço...';

  @override
  String get serviceSearchEmpty =>
      'Não encontrámos serviços para esta pesquisa.';

  @override
  String get serviceModeImmediateDescription =>
      'Um prestador vem já hoje, o mais rápido possível.';

  @override
  String get serviceModeScheduledDescription =>
      'Marca dia e hora para o serviço.';

  @override
  String get serviceModeQuoteDescription =>
      'Pede orçamento (o prestador envia faixa min/max).';

  @override
  String get userNotAuthenticatedError => 'Erro: utilizador não autenticado.';

  @override
  String get myOrdersTitle => 'Meus pedidos';

  @override
  String get ordersTabPending => 'Pendentes';

  @override
  String get ordersTabCompleted => 'Concluídos';

  @override
  String get ordersTabCancelled => 'Cancelados';

  @override
  String ordersLoadError(Object error) {
    return 'Erro a carregar pedidos: $error';
  }

  @override
  String get ordersEmptyPending =>
      'Não tens pedidos pendentes.\\nCria um novo pedido no Início.';

  @override
  String get ordersEmptyCompleted => 'Ainda não tens pedidos concluídos.';

  @override
  String get ordersEmptyCancelled => 'Ainda não tens pedidos cancelados.';

  @override
  String get orderQuoteScheduled => 'Orçamento (agendado)';

  @override
  String get orderQuoteImmediate => 'Orçamento (imediato)';

  @override
  String get orderScheduled => 'Serviço agendado';

  @override
  String get orderImmediate => 'Serviço imediato';

  @override
  String get categoryNotDefined => 'Categoria não definida';

  @override
  String orderStateLabel(Object state) {
    return 'Estado: $state';
  }

  @override
  String orderPriceModelLabel(Object model) {
    return 'Modelo de preço: $model';
  }

  @override
  String orderPaymentLabel(Object payment) {
    return 'Pagamento: $payment';
  }

  @override
  String orderValueLabel(Object value) {
    return 'Valor: $value';
  }

  @override
  String accountTitle(Object role) {
    return 'Conta ($role)';
  }

  @override
  String get accountNameTitle => 'O teu nome';

  @override
  String get accountProfileSubtitle => 'Perfil';

  @override
  String get accountSettings => 'Definições';

  @override
  String get accountHelpSupport => 'Ajuda e suporte';

  @override
  String get navMyJobs => 'Meus trabalhos';

  @override
  String get roleLabelProvider => 'Prestador';

  @override
  String get enableLocationToGoOnline =>
      'Ativa a localização para ficar online.';

  @override
  String get nearbyOrdersTitle => 'Pedidos perto de ti';

  @override
  String get noOrdersAvailableMessage => 'Não há pedidos disponíveis agora.';

  @override
  String get configureServiceAreaMessage =>
      'Configura a tua área e serviços para começar a receber pedidos.';

  @override
  String get configureAction => 'Configurar';

  @override
  String get offlineEnableOnlineMessage =>
      'Estás offline. Fica online para receber pedidos.';

  @override
  String get noMatchingOrdersMessage =>
      'Sem pedidos compatíveis com os teus serviços e área.';

  @override
  String get orderAcceptedMessage => 'Pedido aceite.';

  @override
  String get orderAcceptedCanSendQuote =>
      'Pedido aceite. Podes enviar o orçamento mais tarde.';

  @override
  String orderAcceptError(Object error) {
    return 'Erro ao aceitar pedido: $error';
  }

  @override
  String get orderAcceptedDialogTitle => 'Pedido aceite';

  @override
  String get orderAcceptedBudgetPrompt =>
      'Este pedido é por orçamento.\\n\\nQueres enviar o orçamento (faixa min/max) agora?';

  @override
  String get actionLater => 'Mais tarde';

  @override
  String get actionSendNow => 'Enviar agora';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSend => 'Enviar';

  @override
  String get actionIgnore => 'Ignorar';

  @override
  String get actionAccept => 'Aceitar';

  @override
  String get actionNo => 'Não';

  @override
  String get actionYesCancel => 'Sim, cancelar';

  @override
  String get proposalDialogTitle => 'Propor serviço';

  @override
  String get proposalDialogDescription =>
      'Define uma faixa de preço para este serviço.\\nInclui deslocação e mão de obra.';

  @override
  String proposalMinValueLabel(Object currency) {
    return 'Valor mínimo ($currency)';
  }

  @override
  String get proposalMinValueHint => 'Ex.: 20';

  @override
  String proposalMaxValueLabel(Object currency) {
    return 'Valor máximo ($currency)';
  }

  @override
  String get proposalMaxValueHint => 'Ex.: 35';

  @override
  String get proposalMessageLabel => 'Mensagem para o cliente (opcional)';

  @override
  String get proposalMessageHint =>
      'Ex.: Inclui deslocação. Materiais grandes à parte.';

  @override
  String get proposalInvalidValues =>
      'Preenche valores mínimo e máximo válidos.';

  @override
  String get proposalMinGreaterThanMax =>
      'O mínimo não pode ser maior que o máximo.';

  @override
  String get proposalSent => 'Proposta enviada ao cliente.';

  @override
  String proposalSendError(Object error) {
    return 'Erro ao enviar proposta: $error';
  }

  @override
  String get providerHomeGreeting => 'Olá, prestador';

  @override
  String get providerHomeSubtitle => 'Fica online para receber novos pedidos.';

  @override
  String get providerStatusOnline => 'Estás ONLINE';

  @override
  String get providerStatusOffline => 'Estás OFFLINE';

  @override
  String providerSettingsLoadError(Object error) {
    return 'Erro ao carregar definições: $error';
  }

  @override
  String providerSettingsSaveError(Object error) {
    return 'Erro ao guardar definições: $error';
  }

  @override
  String get serviceAreaTitle => 'Área de atuação';

  @override
  String get serviceAreaHeading => 'Onde queres receber pedidos?';

  @override
  String get serviceAreaSubtitle =>
      'Define os serviços que fazes e o raio máximo em torno da tua cidade base.';

  @override
  String get serviceAreaBaseLocation => 'Localização base';

  @override
  String get serviceAreaRadius => 'Raio de atuação';

  @override
  String get serviceAreaSaved => 'Área de atuação guardada com sucesso.';

  @override
  String get serviceAreaInfoNote =>
      'No futuro vamos usar estas definições para filtrar pedidos por proximidade e tipo de serviço. Por agora, isto ajuda-nos a preparar o motor de matching.';

  @override
  String get availabilityTitle => 'Disponibilidade';

  @override
  String get servicesYouProvideTitle => 'Serviços que realizas';

  @override
  String get servicesCatalogEmpty =>
      'Ainda não há serviços configurados no catálogo.';

  @override
  String get servicesSearchPrompt =>
      'Escreve para pesquisar e adicionar serviços.';

  @override
  String get servicesSearchNoResults => 'Nenhum serviço encontrado.';

  @override
  String get servicesSelectedTitle => 'Serviços selecionados';

  @override
  String get serviceUnnamed => 'Serviço sem nome';

  @override
  String get serviceModeQuote => 'Orçamento';

  @override
  String get serviceModeScheduled => 'Agendado';

  @override
  String get serviceModeImmediate => 'Imediato';

  @override
  String get providerServicesSelectAtLeastOne =>
      'Escolhe pelo menos um serviço que realizas.';

  @override
  String get countryLabel => 'País';

  @override
  String get cityLabel => 'Cidade';

  @override
  String get stateLabelDistrict => 'Distrito';

  @override
  String get stateLabelProvince => 'Província';

  @override
  String get stateLabelState => 'Estado';

  @override
  String get stateLabelRegion => 'Região';

  @override
  String get stateLabelCounty => 'Condado';

  @override
  String get stateLabelRegionOrState => 'Região/Estado';

  @override
  String get searchHint => 'Pesquisar...';

  @override
  String get searchCountryHint => 'Escreve para pesquisar países';

  @override
  String get searchGenericHint => 'Escreve para pesquisar';

  @override
  String get searchServicesHint => 'Pesquisar serviços';

  @override
  String get openCountriesListTooltip => 'Ver lista de países';

  @override
  String get openListTooltip => 'Ver lista';

  @override
  String get selectCountryTitle => 'Escolher país';

  @override
  String get selectCityTitle => 'Escolher cidade';

  @override
  String selectFieldTitle(Object field) {
    return 'Escolher $field';
  }

  @override
  String get saveChanges => 'Guardar alterações';

  @override
  String get supportTitle => 'Ajuda e suporte';

  @override
  String get supportSubtitle => 'Tens dúvidas? Contacta-nos.';

  @override
  String get myScheduleTitle => 'Minha Agenda';

  @override
  String get myScheduleSubtitle => 'Definir horários e dias de folga';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageModeManual => 'Manual';

  @override
  String get languageModeAuto => 'Auto';

  @override
  String languageModeLabel(Object code, Object mode) {
    return '$code - $mode';
  }

  @override
  String get languageAutoSystem => 'Auto (Sistema)';

  @override
  String get providerCategoriesTitle => 'Categorias de atuação';

  @override
  String get providerCategoriesSubtitle =>
      'Usamos as categorias para filtrar pedidos compatíveis.';

  @override
  String get providerCategoriesEmpty => 'Nenhuma categoria selecionada.';

  @override
  String get providerCategoriesSelect => 'Selecionar categorias';

  @override
  String get providerCategoriesEdit => 'Adicionar ou editar categorias';

  @override
  String get providerCategoriesRequiredMessage =>
      'Seleciona categorias para receber pedidos compatíveis.';

  @override
  String get providerKpiEarningsToday => 'Ganhos hoje (líquido)';

  @override
  String get providerKpiServicesThisMonth => 'Serviços este mês';

  @override
  String providerKpiGrossFeeSubtitle(Object gross, Object fee) {
    return 'Bruto: $gross - Taxa: $fee';
  }

  @override
  String get providerHighlightTitle => 'Tens um trabalho para gerir';

  @override
  String get providerHighlightCta => 'Toca aqui para abrir o próximo trabalho.';

  @override
  String get providerPendingActionAccepted =>
      'Tens um trabalho aceite, pronto para iniciar.';

  @override
  String get providerPendingActionInProgress =>
      'Tens um serviço em andamento. Marca como concluído quando terminares.';

  @override
  String get providerPendingActionSetFinalValue =>
      'Define e envia o valor final do serviço.';

  @override
  String get providerUnreadMessagesTitle => 'Tens novas mensagens de clientes';

  @override
  String providerUnreadMessagesJob(Object jobTitle) {
    return 'No trabalho: $jobTitle';
  }

  @override
  String get providerJobsTitle => 'Meus trabalhos';

  @override
  String get providerJobsTabOpen => 'Em aberto';

  @override
  String get providerJobsTabCompleted => 'Concluídos';

  @override
  String get providerJobsTabCancelled => 'Cancelados';

  @override
  String providerJobsLoadError(Object error) {
    return 'Erro a carregar trabalhos: $error';
  }

  @override
  String get providerJobsEmptyOpen =>
      'Ainda não tens trabalhos em aberto.\\nVai à aba Início e aceita um pedido.';

  @override
  String get providerJobsEmptyCompleted =>
      'Ainda não tens trabalhos concluídos.';

  @override
  String get providerJobsEmptyCancelled =>
      'Ainda não tens trabalhos cancelados.';

  @override
  String scheduledForDate(Object date) {
    return 'Agendado: $date';
  }

  @override
  String get viewDetailsTooltip => 'Ver detalhe';

  @override
  String clientPaidValueLabel(Object value) {
    return 'Valor pago pelo cliente: $value';
  }

  @override
  String providerEarningsFeeLabel(Object value, Object fee) {
    return 'Tu recebes: $value - Taxa: $fee';
  }

  @override
  String serviceValueLabel(Object value) {
    return 'Valor do serviço: $value';
  }

  @override
  String get cancelJobTitle => 'Cancelar trabalho';

  @override
  String get cancelJobPrompt =>
      'Tens a certeza que queres cancelar este trabalho?\\nO pedido pode voltar a ficar disponível para outros prestadores.';

  @override
  String get cancelJobReasonLabel => 'Motivo do cancelamento (opcional):';

  @override
  String get cancelJobReasonFieldLabel => 'Motivo';

  @override
  String get cancelJobDetailLabel => 'Detalhe do motivo';

  @override
  String get cancelJobDetailRequired => 'Informe um detalhe.';

  @override
  String get cancelJobSuccess => 'Trabalho cancelado.';

  @override
  String cancelJobError(Object error) {
    return 'Erro ao cancelar trabalho: $error';
  }

  @override
  String get providerAccountProfileTitle => 'Ver o meu perfil';

  @override
  String get providerAccountProfileSubtitle => 'Perfil de Prestador';

  @override
  String get activateOnlinePaymentsSubtitle => 'Ativar recebimentos online';

  @override
  String get statusProviderWaiting => 'Novo pedido';

  @override
  String get statusQuoteWaitingCustomer => 'Aguarda resposta do cliente';

  @override
  String get statusAcceptedToStart => 'Aceite (pronto a iniciar)';

  @override
  String get statusInProgress => 'Em andamento';

  @override
  String get statusCompleted => 'Concluído';

  @override
  String get orderDefaultImmediateTitle => 'Serviço urgente';

  @override
  String get locationServiceDisabled =>
      'O serviço de localização está desativado no dispositivo.';

  @override
  String get locationPermissionDenied =>
      'Permissão de localização negada.\\nNão foi possível obter a localização atual.';

  @override
  String get locationPermissionDeniedForever =>
      'Permissão de localização negada permanentemente.\\nAtiva a localização nas definições do dispositivo.';

  @override
  String locationFetchError(Object error) {
    return 'Erro ao obter localização: $error';
  }

  @override
  String get formNotReadyError =>
      'O formulário ainda não está pronto. Tenta novamente.';

  @override
  String get missingRequiredFieldsError =>
      'Faltam campos obrigatórios. Verifica os campos em vermelho.';

  @override
  String get scheduleDateTimeRequiredError =>
      'Escolhe a data e hora do serviço.';

  @override
  String get scheduleDateTimeFutureError => 'Escolhe uma data/hora no futuro.';

  @override
  String get categoryRequiredError => 'Escolhe uma categoria.';

  @override
  String get orderUpdatedSuccess => 'Pedido atualizado com sucesso!';

  @override
  String get orderCreatedSuccess => 'Pedido criado! A procurar um prestador...';

  @override
  String orderUpdateError(Object error) {
    return 'Erro ao atualizar pedido: $error';
  }

  @override
  String orderCreateError(Object error) {
    return 'Erro ao criar pedido: $error';
  }

  @override
  String get orderTitleExamplePlumbing =>
      'Ex.: Canalização a verter debaixo do lava-louça';

  @override
  String get orderTitleExampleElectric =>
      'Ex.: Tomada não funciona na sala + ligar candeeiro de teto';

  @override
  String get orderTitleExampleCleaning =>
      'Ex.: Limpeza completa de apartamento T2 (cozinha, WC, janelas e chão).';

  @override
  String get orderTitleHintImmediate =>
      'Explica rapidamente o que está a acontecer e o que precisas.';

  @override
  String get orderTitleHintScheduled =>
      'Indica para quando queres o serviço, detalhes do local e o que deve ser feito.';

  @override
  String get orderTitleHintQuote =>
      'Descreve o serviço desejado para receber propostas.';

  @override
  String get orderTitleHintDefault => 'Descreve o serviço que precisas.';

  @override
  String get orderDescriptionExampleCleaning =>
      'Ex.: Limpeza completa de apartamento T2 (cozinha, WC, janelas e chão).';

  @override
  String get orderDescriptionHintImmediate =>
      'Explica rapidamente o que está a acontecer e o que precisas.';

  @override
  String get orderDescriptionHintScheduled =>
      'Indica para quando queres o serviço, detalhes do local e o que deve ser feito.';

  @override
  String get orderDescriptionHintQuote =>
      'Descreve o serviço desejado, orçamento aproximado (se tiveres) e detalhes importantes.';

  @override
  String get orderDescriptionHintDefault =>
      'Explica com algum detalhe o que precisas.';

  @override
  String get priceModelTitle => 'Modelo de preço';

  @override
  String get priceModelQuoteInfo =>
      'Este serviço é por orçamento. O prestador vai propor o valor final.';

  @override
  String get priceTypeLabel => 'Tipo de preço';

  @override
  String get paymentTypeLabel => 'Tipo de pagamento';

  @override
  String get orderHeaderQuoteTitle => 'Pedido por orçamento';

  @override
  String get orderHeaderQuoteSubtitle =>
      'Descreve o que precisas e o prestador pode enviar uma faixa (mín/máx).';

  @override
  String get orderHeaderImmediateTitle => 'Serviço imediato';

  @override
  String get orderHeaderImmediateSubtitle =>
      'Um prestador disponível será chamado o mais rápido possível.';

  @override
  String get orderHeaderScheduledTitle => 'Serviço por agendamento';

  @override
  String get orderHeaderScheduledSubtitle =>
      'Escolhe o dia e hora para o prestador ir até ti.';

  @override
  String get orderHeaderDefaultTitle => 'Novo pedido';

  @override
  String get orderHeaderDefaultSubtitle => 'Descreve o serviço que precisas.';

  @override
  String get orderEditTitle => 'Editar pedido';

  @override
  String get orderNewTitle => 'Novo pedido';

  @override
  String get whenServiceNeededLabel => 'Quando precisas do serviço?';

  @override
  String get categoryLabel => 'Categoria';

  @override
  String get categoryHint => 'Escolhe a categoria do serviço';

  @override
  String get orderTitleLabel => 'Título do pedido';

  @override
  String get orderTitleRequiredError => 'Escreve um título para o pedido.';

  @override
  String get orderDescriptionOptionalLabel => 'Descrição (opcional)';

  @override
  String get locationApproxLabel => 'Localização aproximada';

  @override
  String get locationSelectedLabel => 'Localização selecionada.';

  @override
  String get locationSelectPrompt =>
      'Escolhe onde o serviço será feito (aproximado).';

  @override
  String get locationAddressHint =>
      'Rua, nº, andar, referência (opcional, mas ajuda muito)';

  @override
  String get locationGetting => 'A obter localização...';

  @override
  String get locationUseCurrent => 'Usar localização atual';

  @override
  String get locationChooseOnMap => 'Escolher no mapa';

  @override
  String get serviceDateTimeLabel => 'Data e hora do serviço';

  @override
  String get serviceDateTimePick => 'Escolhe dia e hora';

  @override
  String get saveChangesButton => 'Guardar alterações';

  @override
  String get submitOrderButton => 'Pedir serviço';

  @override
  String get mapSelectTitle => 'Escolher localização no mapa';

  @override
  String get mapSelectInstruction =>
      'Arrasta o mapa até ao local aproximado do serviço, depois confirma.';

  @override
  String get mapSelectConfirm => 'Confirmar localização';

  @override
  String get orderDetailsTitle => 'Detalhe do pedido';

  @override
  String orderLoadError(Object error) {
    return 'Erro a carregar pedido: $error';
  }

  @override
  String get orderNotFound => 'Pedido não encontrado.';

  @override
  String get scheduledNoDate => 'Agendado (sem data definida)';

  @override
  String get orderValueRejectedTitle => 'O cliente rejeitou o valor proposto.';

  @override
  String get orderValueRejectedBody =>
      'Conversem pelo chat e propõe um novo valor quando estiverem alinhados.';

  @override
  String get actionProposeNewValue => 'Propor novo valor';

  @override
  String get noShowReportedTitle => 'No-show reportado';

  @override
  String noShowReportedBy(Object role) {
    return 'Reportado por: $role';
  }

  @override
  String noShowReportedAt(Object date) {
    return 'Em: $date';
  }

  @override
  String get noShowTitle => 'No-show';

  @override
  String get noShowDescription =>
      'Se a outra pessoa não apareceu, podes reportar.';

  @override
  String get noShowReportAction => 'Reportar no-show';

  @override
  String get orderInfoTitle => 'Informações do pedido';

  @override
  String get orderInfoIdLabel => 'ID do pedido';

  @override
  String get orderInfoCreatedAtLabel => 'Criado em';

  @override
  String get orderInfoStatusLabel => 'Estado';

  @override
  String get orderInfoModeLabel => 'Modo';

  @override
  String get orderInfoValueLabel => 'Valor';

  @override
  String get orderLocationTitle => 'Localização do pedido';

  @override
  String get orderDescriptionTitle => 'Descrição do pedido';

  @override
  String get providerMessageTitle => 'Mensagem do prestador';

  @override
  String get actionEditOrder => 'Editar pedido';

  @override
  String get actionCancelOrder => 'Cancelar pedido';

  @override
  String get cancelOrderTitle => 'Cancelar pedido';

  @override
  String get orderCancelInProgressWarning =>
      'O serviço já está em andamento.\nAo cancelar agora, o reembolso pode não ser total.';

  @override
  String get orderCancelConfirmPrompt =>
      'Tens a certeza que queres cancelar este pedido?';

  @override
  String get orderCancelReasonLabel => 'Motivo do cancelamento';

  @override
  String get orderCancelReasonOptionalLabel => 'Motivo (opcional)';

  @override
  String orderCancelledSnack(Object message) {
    return 'Pedido cancelado. $message.';
  }

  @override
  String orderCancelError(Object error) {
    return 'Erro ao cancelar pedido: $error';
  }

  @override
  String get noShowReportDialogTitle => 'Reportar no-show';

  @override
  String get noShowReportDialogDescription =>
      'Usa esta opção apenas se a outra pessoa não apareceu.';

  @override
  String get noShowReasonOptionalLabel => 'Motivo (opcional)';

  @override
  String get actionReport => 'Reportar';

  @override
  String get noShowReportSuccess => 'No-show registado.';

  @override
  String noShowReportError(Object error) {
    return 'Erro ao reportar no-show: $error';
  }

  @override
  String get orderFinalValueTitle => 'Propor novo valor final';

  @override
  String get orderFinalValueLabel => 'Valor';

  @override
  String get orderFinalValueInvalid => 'Insere um valor válido.';

  @override
  String get orderFinalValueSent => 'Novo valor enviado ao cliente.';

  @override
  String orderFinalValueSendError(Object error) {
    return 'Erro ao enviar novo valor: $error';
  }

  @override
  String get ratingSentTitle => 'Avaliação enviada';

  @override
  String get ratingProviderTitle => 'Avaliação do prestador';

  @override
  String get ratingPrompt => 'Deixa uma nota de 1 a 5.';

  @override
  String get ratingCommentLabel => 'Comentário (opcional)';

  @override
  String get ratingSendAction => 'Enviar avaliação';

  @override
  String get ratingSelectError => 'Escolhe uma nota.';

  @override
  String get ratingSentSnack => 'Avaliação enviada.';

  @override
  String ratingSendError(Object error) {
    return 'Erro ao enviar avaliação: $error';
  }

  @override
  String get timelineCreated => 'Criado';

  @override
  String get timelineAccepted => 'Aceito';

  @override
  String get timelineInProgress => 'Em andamento';

  @override
  String get timelineCancelled => 'Cancelado';

  @override
  String get timelineCompleted => 'Concluído';

  @override
  String get lookingForProviderBanner =>
      'Ainda estamos a procurar um prestador para este pedido.';

  @override
  String get actionView => 'Ver';

  @override
  String get chatNoMessagesSubtitle => 'Sem mensagens ainda';

  @override
  String chatPreviewWithTime(Object preview, Object time) {
    return '$preview • $time';
  }

  @override
  String chatMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensagens',
      one: '1 mensagem',
    );
    return '$_temp0';
  }

  @override
  String get actionClose => 'Fechar';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get chatAuthRequired =>
      'Precisas estar autenticado para enviar mensagens.';

  @override
  String chatSendError(Object error) {
    return 'Erro ao enviar mensagem: $error';
  }

  @override
  String get todayLabel => 'Hoje';

  @override
  String get yesterdayLabel => 'Ontem';

  @override
  String chatLoadError(Object error) {
    return 'Erro ao carregar mensagens: $error';
  }

  @override
  String get chatEmptyMessage => 'Ainda não há mensagens.\nEnvia a primeira!';

  @override
  String get chatInputHint => 'Escreve uma mensagem...';

  @override
  String get chatLoginHint => 'Inicia sessão para enviar mensagens';

  @override
  String get roleLabelSystem => 'Sistema';

  @override
  String get youLabel => 'Tu';

  @override
  String distanceMeters(Object meters) {
    return '$meters m';
  }

  @override
  String distanceKilometers(Object kilometers) {
    return '$kilometers km';
  }

  @override
  String get etaLessThanMinute => '<1 min';

  @override
  String etaMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String etaHours(Object hours) {
    return '$hours h';
  }

  @override
  String etaHoursMinutes(Object hours, Object minutes) {
    return '$hours h $minutes m';
  }

  @override
  String mapEtaLabel(Object eta, Object distance) {
    return 'ETA $eta - $distance';
  }

  @override
  String get mapOpenAction => 'Abrir mapa';

  @override
  String get orderMapTitle => 'Mapa do pedido';

  @override
  String get orderChatTitle => 'Chat sobre este pedido';

  @override
  String get messagesTitle => 'Mensagens';

  @override
  String get messagesSearchHint => 'Pesquisar mensagens';

  @override
  String messagesLoadError(Object error) {
    return 'Erro ao carregar conversas: $error';
  }

  @override
  String get messagesEmpty =>
      'Ainda não tens conversas.\nQuando falares com um prestador/cliente, aparece aqui.';

  @override
  String get messagesNewConversationTitle => 'Nova conversa';

  @override
  String get messagesNewConversationBody =>
      'Para iniciar uma conversa com um prestador ou cliente, vai até aos teus \"Pedidos\" ou aceita um pedido novo.';

  @override
  String get messagesFilterAll => 'Tudo';

  @override
  String get messagesFilterUnread => 'Não lidas';

  @override
  String get messagesFilterFavorites => 'Favoritos';

  @override
  String get messagesFilterGroups => 'Grupos';

  @override
  String messagesFilterEmpty(Object filter) {
    return 'Nada em \"$filter\"';
  }

  @override
  String get messagesSearchNoResults => 'Nenhuma conversa encontrada.';

  @override
  String get messagesPinConversation => 'Fixar conversa';

  @override
  String get messagesUnpinConversation => 'Desfixar conversa';

  @override
  String get chatPresenceOnline => 'online';

  @override
  String chatPresenceLastSeenAt(Object time) {
    return 'visto por último às $time';
  }

  @override
  String chatPresenceLastSeenYesterdayAt(Object time) {
    return 'visto por último ontem às $time';
  }

  @override
  String chatPresenceLastSeenOn(Object date, Object time) {
    return 'visto por último em $date às $time';
  }

  @override
  String get chatImageTooLarge => 'Imagem muito grande (máx. 15MB).';

  @override
  String chatImageSendError(Object error) {
    return 'Erro ao enviar imagem: $error';
  }

  @override
  String get chatFileReadError => 'Não consegui ler o ficheiro.';

  @override
  String get chatFileTooLarge => 'Ficheiro muito grande (máx. 20MB).';

  @override
  String chatFileSendError(Object error) {
    return 'Erro ao enviar ficheiro: $error';
  }

  @override
  String get chatAudioReadError => 'Não consegui ler o áudio.';

  @override
  String get chatAudioTooLarge => 'Áudio muito grande (máx. 20MB).';

  @override
  String chatAudioSendError(Object error) {
    return 'Erro ao enviar áudio: $error';
  }

  @override
  String get chatAttachFile => 'Enviar ficheiro';

  @override
  String get chatAttachGallery => 'Enviar foto (galeria)';

  @override
  String get chatAttachCamera => 'Tirar foto (câmara)';

  @override
  String get chatAttachAudio => 'Enviar áudio (ficheiro)';

  @override
  String get chatAttachAudioSubtitle => 'Escolhe um áudio (mp3/m4a/wav/...).';

  @override
  String get chatOpenLink => 'Abrir link';

  @override
  String get chatAttachTooltip => 'Anexar';

  @override
  String get chatSendTooltip => 'Enviar';

  @override
  String get chatSearchAction => 'Pesquisar';

  @override
  String get chatSearchHint => 'Pesquisar mensagens';

  @override
  String get chatSearchEmpty => 'Escreve algo para pesquisar.';

  @override
  String get chatSearchNoResults => 'Nenhuma mensagem encontrada.';

  @override
  String get chatMediaAction => 'Mídia, links e arquivos';

  @override
  String get chatMediaTitle => 'Mídia, links e arquivos';

  @override
  String get chatMediaPhotosTab => 'Fotos';

  @override
  String get chatMediaLinksTab => 'Links';

  @override
  String get chatMediaAudioTab => 'Áudios';

  @override
  String get chatMediaFilesTab => 'Arquivos';

  @override
  String get chatMediaEmptyPhotos => 'Sem fotos ainda.';

  @override
  String get chatMediaEmptyLinks => 'Sem links ainda.';

  @override
  String get chatMediaEmptyAudio => 'Sem áudios ainda.';

  @override
  String get chatMediaEmptyFiles => 'Sem arquivos ainda.';

  @override
  String get chatFavoritesAction => 'Favoritos';

  @override
  String get chatFavoritesTitle => 'Mensagens favoritas';

  @override
  String get chatFavoritesEmpty => 'Ainda não tens mensagens favoritas.';

  @override
  String get chatStarAction => 'Adicionar aos favoritos';

  @override
  String get chatUnstarAction => 'Remover dos favoritos';

  @override
  String get chatViewProviderProfileAction => 'Ver perfil do prestador';

  @override
  String get chatViewCustomerProfileAction => 'Ver perfil do cliente';

  @override
  String get chatIncomingCall => 'Chamada a entrar';

  @override
  String get chatCallStartedVideo => 'Videochamada iniciada';

  @override
  String get chatCallStartedVoice => 'Chamada de voz iniciada';

  @override
  String get chatImageLabel => 'Imagem';

  @override
  String get chatAudioLabel => 'Áudio';

  @override
  String get chatFileLabel => 'Ficheiro';

  @override
  String get chatCallEntryLabel => 'Chamada';

  @override
  String get chatNoSession =>
      'Sem sessão ativa. Faz login para aceder ao chat.';

  @override
  String get chatTitleFallback => 'Chat';

  @override
  String get chatVideoCallAction => 'Videochamada';

  @override
  String get chatVoiceCallAction => 'Chamada';

  @override
  String get chatMarkReadAction => 'Marcar como lidas';

  @override
  String get chatCallMissingParticipant =>
      'Ainda não há outro utilizador neste pedido.';

  @override
  String get chatCallStartError => 'Não foi possível abrir a chamada.';

  @override
  String chatCallMessageVideo(Object url) {
    return 'Videochamada: $url';
  }

  @override
  String chatCallMessageVoice(Object url) {
    return 'Chamada: $url';
  }

  @override
  String get profileProviderTitle => 'Perfil do prestador';

  @override
  String get profileCustomerTitle => 'Perfil do cliente';

  @override
  String get profileAboutTitle => 'Sobre';

  @override
  String get profileLocationTitle => 'Localização';

  @override
  String get profileServicesTitle => 'Serviços';

  @override
  String get profilePortfolioTitle => 'Portfólio';

  @override
  String get chatOpenFullAction => 'Abrir chat completo';

  @override
  String get chatOpenFullUnavailable =>
      'Ainda não existe outro utilizador associado a este pedido.';

  @override
  String get chatReplyAction => 'Responder';

  @override
  String get chatCopyAction => 'Copiar';

  @override
  String get chatDeleteAction => 'Apagar';

  @override
  String get storyNewTitle => 'Novo Story';

  @override
  String get storyPublishing => 'A publicar story...';

  @override
  String get storyPublished => 'Story publicado! Expira em 24h.';

  @override
  String storyPublishError(Object error) {
    return 'Erro ao publicar: $error';
  }

  @override
  String get storyCaptionHint => 'Legenda (opcional)';

  @override
  String get actionPublish => 'Publicar';

  @override
  String get snackOrderRemoved => 'Pedido removido.';

  @override
  String get snackClientCancelledOrder => 'Cliente cancelou o pedido.';

  @override
  String get snackOrderCancelled => 'Pedido cancelado.';

  @override
  String get snackOrderAcceptedByAnother => 'Outro prestador aceitou o pedido.';

  @override
  String get snackOrderUpdated => 'Pedido atualizado.';

  @override
  String get snackUserNotAuthenticated => 'Utilizador não autenticado.';

  @override
  String get snackOrderAcceptedCanQuote =>
      'Pedido aceite. Podes enviar o orçamento no detalhe do pedido.';

  @override
  String get snackOrderAcceptedSuccess => 'Pedido aceite.';

  @override
  String snackErrorAcceptingOrder(Object error) {
    return 'Erro ao aceitar pedido: $error';
  }

  @override
  String get dialogTitleOrderAccepted => 'Pedido aceite ✅';

  @override
  String get dialogContentQuotePrompt =>
      'Este pedido é por orçamento.\n\nQueres enviar o orçamento (faixa min/max) agora?';

  @override
  String get dialogTitleProposeService => 'Propor serviço';

  @override
  String get dialogContentProposeService =>
      'Define uma faixa de preço para este serviço.\nInclui deslocação e mão de obra.';

  @override
  String get labelMinValue => 'Valor mínimo';

  @override
  String get labelMaxValue => 'Valor máximo';

  @override
  String get labelMessageOptional => 'Mensagem para o cliente (opcional)';

  @override
  String hintExampleValue(Object value) {
    return 'Ex.: $value';
  }

  @override
  String get hintProposalMessage =>
      'Ex.: Inclui deslocação. Materiais grandes à parte.';

  @override
  String get snackFillValidValues =>
      'Preenche valores mínimo e máximo válidos.';

  @override
  String get snackMinCannotBeGreaterThanMax =>
      'O mínimo não pode ser maior que o máximo.';

  @override
  String get snackProposalSent => 'Proposta enviada ao cliente.';

  @override
  String snackErrorSendingProposal(Object error) {
    return 'Erro ao enviar proposta: $error';
  }
}
