// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'ChegaJa';

  @override
  String get roleSelectorWelcome => 'Bienvenido a ChegaJa';

  @override
  String get roleSelectorPrompt => 'Elige cómo quieres usar la aplicación:';

  @override
  String get roleCustomerTitle => 'soy un cliente';

  @override
  String get roleCustomerDescription =>
      'Quiero encontrar proveedores de servicios cerca de mí.';

  @override
  String get roleProviderTitle => 'soy un proveedor';

  @override
  String get roleProviderDescription =>
      'Quiero recibir solicitudes de clientes y ganar más.';

  @override
  String get invalidSession => 'Sesión no válida.';

  @override
  String get paymentsTitle => 'Pagos (franja)';

  @override
  String get paymentsHeading => 'Reciba pagos en línea';

  @override
  String get paymentsDescription =>
      'Para recibir pagos a través de la aplicación, debe crear una cuenta Stripe (Connect Express).\nLa incorporación se abre en su navegador y tarda entre 2 y 3 minutos.';

  @override
  String get paymentsActive => 'Pagos en línea ACTIVOS.';

  @override
  String get paymentsInactive =>
      'Los pagos en línea aún no están activos. Incorporación completa.';

  @override
  String stripeAccountLabel(Object accountId) {
    return 'Cuenta de Stripe: $accountId';
  }

  @override
  String get onboardingOpened =>
      'Se abrió la incorporación. Después de terminar, regrese para verificar el estado.';

  @override
  String onboardingStartError(Object error) {
    return 'Error al iniciar la incorporación: $error';
  }

  @override
  String get manageStripeAccount => 'Administrar cuenta de Stripe';

  @override
  String get activatePayments => 'Activar pagos';

  @override
  String get technicalNotesTitle => 'Notas técnicas';

  @override
  String get technicalNotesBody =>
      '• Stripe se configura a través de Cloud Functions (del lado del servidor).\n• La comisión de la plataforma se aplica automáticamente en el PaymentIntent.\n• En producción, agregue el webhook de Stripe y almacene el secreto del webhook en Functions.';

  @override
  String kycTitle(Object status) {
    return 'Verificación de identidad: $status';
  }

  @override
  String get kycDescription =>
      'Enviar un documento (foto o PDF). La validación completa viene en la versión 2.6.';

  @override
  String get kycSendDocument => 'Enviar documento';

  @override
  String get kycAddDocument => 'Agregar documento';

  @override
  String get kycStatusApproved => 'Aprobado';

  @override
  String get kycStatusRejected => 'Rechazado';

  @override
  String get kycStatusInReview => 'En revisión';

  @override
  String get kycStatusNotStarted => 'No iniciado';

  @override
  String get kycFileReadError => 'No se pudo leer el archivo.';

  @override
  String get kycFileTooLarge => 'Archivo demasiado grande (máx. 10 MB).';

  @override
  String get kycUploading => 'Subiendo documento...';

  @override
  String get kycUploadSuccess => 'Documento enviado para revisión.';

  @override
  String kycUploadError(Object error) {
    return 'Error al enviar el documento: $error';
  }

  @override
  String get statusCancelledByYou => 'Cancelado por ti';

  @override
  String get statusCancelledByProvider => 'Cancelado por el proveedor';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusLookingForProvider => 'Buscando proveedor';

  @override
  String get statusProviderPreparingQuote =>
      'Proveedor encontrado (preparando cotización)';

  @override
  String get statusQuoteToDecide => 'Tienes una cotización para decidir';

  @override
  String get statusProviderFound => 'Proveedor encontrado';

  @override
  String get statusServiceInProgress => 'Servicio en progreso';

  @override
  String get statusAwaitingValueConfirmation =>
      'Esperando su confirmación de valor';

  @override
  String get statusServiceCompleted => 'Servicio completado';

  @override
  String valueToConfirm(Object value) {
    return '$value (para confirmar)';
  }

  @override
  String valueProposed(Object value) {
    return '$value (propuesto)';
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
    return 'Hasta $max (estimado)';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get priceFixed => 'Precio fijo';

  @override
  String get priceByQuote => 'Por cotización';

  @override
  String get priceToArrange => 'Por arreglar';

  @override
  String get paymentOnlineBefore => 'Pago en línea (antes)';

  @override
  String get paymentOnlineAfter => 'Pago en línea (después)';

  @override
  String get paymentCash => 'Pago al contado';

  @override
  String get pendingActionQuoteToReview =>
      'Tienes una cotización/propuesta para revisar.';

  @override
  String get pendingActionValueToConfirm =>
      'El proveedor envió el valor final. Necesitas confirmar.';

  @override
  String get pendingActionProviderPreparingQuote =>
      'Proveedor encontrado. Están preparando la cotización.';

  @override
  String get pendingActionProviderChat =>
      'Proveedor encontrado. Puedes chatear con ellos.';

  @override
  String get roleLabelCustomer => 'Cliente';

  @override
  String get navHome => 'Hogar';

  @override
  String get navMyOrders => 'Mis pedidos';

  @override
  String get navMessages => 'Mensajes';

  @override
  String get navProfile => 'Perfil';

  @override
  String get homeGreeting => 'Hola';

  @override
  String get homeSubtitle => '¿Qué necesitas hoy?';

  @override
  String get homePendingTitle => 'Tienes algo que decidir';

  @override
  String get homePendingCta =>
      'Toca aquí para abrir el siguiente pedido y decidir.';

  @override
  String servicesLoadError(Object error) {
    return 'Error al cargar servicios: $error';
  }

  @override
  String get servicesEmptyMessage =>
      'Aún no hay servicios configurados.\\nVerás categorías aquí pronto 🙂';

  @override
  String get availableServicesTitle => 'Servicios disponibles';

  @override
  String get serviceTabImmediate => 'Inmediato';

  @override
  String get serviceTabScheduled => 'Programado';

  @override
  String get serviceTabQuote => 'Por cotización';

  @override
  String get unreadMessagesTitle => 'Tienes nuevos mensajes';

  @override
  String get unreadMessagesCta => 'Toque aquí para abrir el chat.';

  @override
  String get serviceSearchHint => 'Servicio de búsqueda...';

  @override
  String get serviceSearchEmpty =>
      'No se encontraron servicios para esta búsqueda.';

  @override
  String get serviceModeImmediateDescription =>
      'Un proveedor llega hoy lo más rápido posible.';

  @override
  String get serviceModeScheduledDescription =>
      'Agendar día y hora para el servicio.';

  @override
  String get serviceModeQuoteDescription =>
      'Solicite una cotización (el proveedor envía un rango mínimo/máximo).';

  @override
  String get userNotAuthenticatedError => 'Error: usuario no autenticado.';

  @override
  String get myOrdersTitle => 'mis pedidos';

  @override
  String get ordersTabPending => 'Pendiente';

  @override
  String get ordersTabCompleted => 'Terminado';

  @override
  String get ordersTabCancelled => 'Cancelado';

  @override
  String ordersLoadError(Object error) {
    return 'Error al cargar pedidos: $error';
  }

  @override
  String get ordersEmptyPending =>
      'No tienes pedidos pendientes.\\nCrea un nuevo pedido desde Inicio.';

  @override
  String get ordersEmptyCompleted => 'Aún no has completado los pedidos.';

  @override
  String get ordersEmptyCancelled => 'Aún no has cancelado pedidos.';

  @override
  String get orderQuoteScheduled => 'Cotización (programada)';

  @override
  String get orderQuoteImmediate => 'Cotización (inmediata)';

  @override
  String get orderScheduled => 'Servicio programado';

  @override
  String get orderImmediate => 'Servicio inmediato';

  @override
  String get categoryNotDefined => 'Categoría no definida';

  @override
  String orderStateLabel(Object state) {
    return 'Estado: $state';
  }

  @override
  String orderPriceModelLabel(Object model) {
    return 'Modelo de precio: $model';
  }

  @override
  String orderPaymentLabel(Object payment) {
    return 'Pago: $payment';
  }

  @override
  String orderValueLabel(Object value) {
    return 'Valor: $value';
  }

  @override
  String accountTitle(Object role) {
    return 'Cuenta ($role)';
  }

  @override
  String get accountNameTitle => 'Su nombre';

  @override
  String get accountProfileSubtitle => 'Perfil';

  @override
  String get accountSettings => 'Ajustes';

  @override
  String get accountHelpSupport => 'Ayuda y soporte';

  @override
  String get navMyJobs => 'Mis trabajos';

  @override
  String get roleLabelProvider => 'Proveedor';

  @override
  String get enableLocationToGoOnline =>
      'Habilite la ubicación para conectarse.';

  @override
  String get nearbyOrdersTitle => 'Pedidos cerca de ti';

  @override
  String get noOrdersAvailableMessage =>
      'No hay pedidos disponibles en este momento.';

  @override
  String get configureServiceAreaMessage =>
      'Configura tu área de servicio y servicios para comenzar a recibir pedidos.';

  @override
  String get configureAction => 'Configurar';

  @override
  String get offlineEnableOnlineMessage =>
      'Estás desconectado. Habilite el estado en línea para recibir pedidos.';

  @override
  String get noMatchingOrdersMessage =>
      'No hay pedidos coincidentes para sus servicios y área.';

  @override
  String get orderAcceptedMessage => 'Pedido aceptado.';

  @override
  String get orderAcceptedCanSendQuote =>
      'Pedido aceptado. Puedes enviar la cotización más tarde.';

  @override
  String orderAcceptError(Object error) {
    return 'Error al aceptar el pedido: $error';
  }

  @override
  String get orderAcceptedDialogTitle => 'Pedido aceptado';

  @override
  String get orderAcceptedBudgetPrompt =>
      'Este pedido es por cotización.\\n\\n¿Quieres enviar el rango de cotización ahora?';

  @override
  String get actionLater => 'Más tarde';

  @override
  String get actionSendNow => 'Enviar ahora';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionSend => 'Enviar';

  @override
  String get actionIgnore => 'Ignorar';

  @override
  String get actionAccept => 'Aceptar';

  @override
  String get actionNo => 'No';

  @override
  String get actionYesCancel => 'Sí, cancelar';

  @override
  String get proposalDialogTitle => 'Enviar una cotización';

  @override
  String get proposalDialogDescription =>
      'Establezca un rango de precios para este servicio.\\nIncluya viajes y mano de obra.';

  @override
  String proposalMinValueLabel(Object currency) {
    return 'Valor mínimo ($currency)';
  }

  @override
  String get proposalMinValueHint => 'Ej.: 20';

  @override
  String proposalMaxValueLabel(Object currency) {
    return 'Valor máximo ($currency)';
  }

  @override
  String get proposalMaxValueHint => 'Ej.: 35';

  @override
  String get proposalMessageLabel => 'Mensaje al cliente (opcional)';

  @override
  String get proposalMessageHint =>
      'Ej.: Incluye viajes. Los materiales grandes son adicionales.';

  @override
  String get proposalInvalidValues =>
      'Introduzca valores mínimos y máximos válidos.';

  @override
  String get proposalMinGreaterThanMax =>
      'El mínimo no puede ser mayor que el máximo.';

  @override
  String get proposalSent => 'Propuesta enviada al cliente.';

  @override
  String proposalSendError(Object error) {
    return 'Error al enviar la propuesta: $error';
  }

  @override
  String get providerHomeGreeting => 'Hola proveedor';

  @override
  String get providerHomeSubtitle =>
      'Conéctese en línea para recibir nuevos pedidos.';

  @override
  String get providerStatusOnline => 'Estás en línea';

  @override
  String get providerStatusOffline => 'Estás SIN CONEXIÓN';

  @override
  String providerSettingsLoadError(Object error) {
    return 'Error al cargar la configuración: $error';
  }

  @override
  String providerSettingsSaveError(Object error) {
    return 'Error al guardar la configuración: $error';
  }

  @override
  String get serviceAreaTitle => 'Vía de Servício';

  @override
  String get serviceAreaHeading => '¿Dónde quieres recibir pedidos?';

  @override
  String get serviceAreaSubtitle =>
      'Establece los servicios que brindas y el radio máximo alrededor de tu ciudad base.';

  @override
  String get serviceAreaBaseLocation => 'Ubicación de la base';

  @override
  String get serviceAreaRadius => 'Radio de servicio';

  @override
  String get serviceAreaSaved => 'Área de servicio guardada exitosamente.';

  @override
  String get serviceAreaInfoNote =>
      'En el futuro usaremos esta configuración para filtrar pedidos por proximidad y tipo de servicio. Por ahora, esto nos ayuda a preparar el motor correspondiente.';

  @override
  String get availabilityTitle => 'Disponibilidad';

  @override
  String get servicesYouProvideTitle => 'Servicios que proporcionas';

  @override
  String get servicesCatalogEmpty =>
      'Aún no hay servicios configurados en el catálogo.';

  @override
  String get servicesSearchPrompt => 'Escriba para buscar y agregar servicios.';

  @override
  String get servicesSearchNoResults => 'No se encontraron servicios.';

  @override
  String get servicesSelectedTitle => 'Servicios seleccionados';

  @override
  String get serviceUnnamed => 'Servicio sin nombre';

  @override
  String get serviceModeQuote => 'Cita';

  @override
  String get serviceModeScheduled => 'Programado';

  @override
  String get serviceModeImmediate => 'Inmediato';

  @override
  String get providerServicesSelectAtLeastOne =>
      'Seleccione al menos un servicio que brinde.';

  @override
  String get countryLabel => 'País';

  @override
  String get cityLabel => 'Ciudad';

  @override
  String get stateLabelDistrict => 'Distrito';

  @override
  String get stateLabelProvince => 'Provincia';

  @override
  String get stateLabelState => 'Estado';

  @override
  String get stateLabelRegion => 'Región';

  @override
  String get stateLabelCounty => 'Condado';

  @override
  String get stateLabelRegionOrState => 'Región/Estado';

  @override
  String get searchHint => 'Buscar...';

  @override
  String get searchCountryHint => 'Escribe para buscar países';

  @override
  String get searchGenericHint => 'Escribe para buscar';

  @override
  String get searchServicesHint => 'Servicios de búsqueda';

  @override
  String get openCountriesListTooltip => 'Ver lista de países';

  @override
  String get openListTooltip => 'Ver lista';

  @override
  String get selectCountryTitle => 'Seleccionar país';

  @override
  String get selectCityTitle => 'Selecciona ciudad';

  @override
  String selectFieldTitle(Object field) {
    return 'Seleccione $field';
  }

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get supportTitle => 'Ayuda y soporte';

  @override
  String get supportSubtitle => '¿Tiene preguntas? Contáctenos.';

  @override
  String get myScheduleTitle => 'mi horario';

  @override
  String get myScheduleSubtitle => 'Establecer horas y días libres';

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
  String get languageAutoSystem => 'Automático (sistema)';

  @override
  String get providerCategoriesTitle => 'Categorías de servicio';

  @override
  String get providerCategoriesSubtitle =>
      'Usamos categorías para filtrar pedidos compatibles.';

  @override
  String get providerCategoriesEmpty => 'Ninguna categoría seleccionada.';

  @override
  String get providerCategoriesSelect => 'Seleccionar categorías';

  @override
  String get providerCategoriesEdit => 'Agregar o editar categorías';

  @override
  String get providerCategoriesRequiredMessage =>
      'Seleccione sus categorías para recibir pedidos coincidentes.';

  @override
  String get providerKpiEarningsToday => 'Ganancias hoy (netas)';

  @override
  String get providerKpiServicesThisMonth => 'Servicios este mes';

  @override
  String providerKpiGrossFeeSubtitle(Object gross, Object fee) {
    return 'Bruto: $gross - Tarifa: $fee';
  }

  @override
  String get providerHighlightTitle => 'Tienes un trabajo que gestionar.';

  @override
  String get providerHighlightCta =>
      'Toque aquí para abrir el siguiente trabajo.';

  @override
  String get providerPendingActionAccepted =>
      'Tienes un trabajo aceptado, listo para empezar.';

  @override
  String get providerPendingActionInProgress =>
      'Tienes un trabajo en progreso. Márcalo como completado cuando termines.';

  @override
  String get providerPendingActionSetFinalValue =>
      'Establecer y enviar el valor final del servicio.';

  @override
  String get providerUnreadMessagesTitle =>
      'Tienes nuevos mensajes de clientes.';

  @override
  String providerUnreadMessagesJob(Object jobTitle) {
    return 'En el trabajo: $jobTitle';
  }

  @override
  String get providerJobsTitle => 'mis trabajos';

  @override
  String get providerJobsTabOpen => 'Abierto';

  @override
  String get providerJobsTabCompleted => 'Terminado';

  @override
  String get providerJobsTabCancelled => 'Cancelado';

  @override
  String providerJobsLoadError(Object error) {
    return 'Error al cargar trabajos: $error';
  }

  @override
  String get providerJobsEmptyOpen =>
      'Aún no tienes trabajos abiertos.\\nVaya a Inicio y acepte un pedido.';

  @override
  String get providerJobsEmptyCompleted =>
      'Aún no has completado los trabajos.';

  @override
  String get providerJobsEmptyCancelled => 'Aún no has cancelado trabajos.';

  @override
  String scheduledForDate(Object date) {
    return 'Programado: $date';
  }

  @override
  String get viewDetailsTooltip => 'Ver detalles';

  @override
  String clientPaidValueLabel(Object value) {
    return 'Cliente pagado: $value';
  }

  @override
  String providerEarningsFeeLabel(Object value, Object fee) {
    return 'Recibes: $value - Tarifa: $fee';
  }

  @override
  String serviceValueLabel(Object value) {
    return 'Valor del servicio: $value';
  }

  @override
  String get cancelJobTitle => 'Cancelar trabajo';

  @override
  String get cancelJobPrompt =>
      '¿Está seguro de que desea cancelar este trabajo?\\nEs posible que el pedido esté disponible para otros proveedores.';

  @override
  String get cancelJobReasonLabel => 'Motivo de cancelación (opcional):';

  @override
  String get cancelJobReasonFieldLabel => 'Razón';

  @override
  String get cancelJobDetailLabel => 'Detalles de cancelación';

  @override
  String get cancelJobDetailRequired => 'Por favor agregue un detalle.';

  @override
  String get cancelJobSuccess => 'Trabajo cancelado.';

  @override
  String cancelJobError(Object error) {
    return 'Error al cancelar el trabajo: $error';
  }

  @override
  String get providerAccountProfileTitle => 'Ver mi perfil';

  @override
  String get providerAccountProfileSubtitle => 'Perfil de proveedor';

  @override
  String get activateOnlinePaymentsSubtitle => 'Habilitar pagos en línea';

  @override
  String get statusProviderWaiting => 'Nueva solicitud';

  @override
  String get statusQuoteWaitingCustomer => 'Esperando respuesta del cliente';

  @override
  String get statusAcceptedToStart => 'Aceptado (listo para comenzar)';

  @override
  String get statusInProgress => 'En curso';

  @override
  String get statusCompleted => 'Terminado';

  @override
  String get orderDefaultImmediateTitle => 'Servicio urgente';

  @override
  String get locationServiceDisabled =>
      'El servicio de ubicación está deshabilitado en el dispositivo.';

  @override
  String get locationPermissionDenied =>
      'Permiso de ubicación denegado.\\nNo se pudo obtener la ubicación actual.';

  @override
  String get locationPermissionDeniedForever =>
      'Permiso de ubicación denegado permanentemente.\\nHabilite la ubicación en la configuración del dispositivo.';

  @override
  String locationFetchError(Object error) {
    return 'Error al obtener la ubicación: $error';
  }

  @override
  String get formNotReadyError =>
      'El formulario aún no está listo. Intentar otra vez.';

  @override
  String get missingRequiredFieldsError =>
      'Faltan campos obligatorios. Marque los campos en rojo.';

  @override
  String get scheduleDateTimeRequiredError =>
      'Elija la fecha y hora del servicio.';

  @override
  String get scheduleDateTimeFutureError => 'Elija una fecha/hora futura.';

  @override
  String get categoryRequiredError => 'Elige una categoría.';

  @override
  String get orderUpdatedSuccess => '¡Pedido actualizado exitosamente!';

  @override
  String get orderCreatedSuccess => '¡Pedido creado! Se busca proveedor...';

  @override
  String orderUpdateError(Object error) {
    return 'Error al actualizar el pedido: $error';
  }

  @override
  String orderCreateError(Object error) {
    return 'Error al crear el pedido: $error';
  }

  @override
  String get orderTitleExamplePlumbing =>
      'Ej.: fuga de plomería debajo del fregadero';

  @override
  String get orderTitleExampleElectric =>
      'Ej.: El tomacorriente no funciona en la sala + instalar luz de techo';

  @override
  String get orderTitleExampleCleaning =>
      'Ej.: Limpieza completa de un apartamento de 2 dormitorios (cocina, aseo, ventanas, suelo).';

  @override
  String get orderTitleHintImmediate =>
      'Explique brevemente qué está pasando y qué necesita.';

  @override
  String get orderTitleHintScheduled =>
      'Indique cuándo desea el servicio, los detalles de la ubicación y qué se debe hacer.';

  @override
  String get orderTitleHintQuote =>
      'Describe el servicio para el que deseas recibir propuestas.';

  @override
  String get orderTitleHintDefault => 'Describe el servicio que necesitas.';

  @override
  String get orderDescriptionExampleCleaning =>
      'Ej.: Limpieza completa de un apartamento de 2 dormitorios (cocina, aseo, ventanas, suelo).';

  @override
  String get orderDescriptionHintImmediate =>
      'Explique brevemente qué está pasando y qué necesita.';

  @override
  String get orderDescriptionHintScheduled =>
      'Indique cuándo desea el servicio, los detalles de la ubicación y qué se debe hacer.';

  @override
  String get orderDescriptionHintQuote =>
      'Describe el servicio que deseas, presupuesto aproximado (si tienes uno) y detalles importantes.';

  @override
  String get orderDescriptionHintDefault =>
      'Explica con un poco más de detalle lo que necesitas.';

  @override
  String get priceModelTitle => 'Modelo de precio';

  @override
  String get priceModelQuoteInfo =>
      'Este servicio es mediante cotización. El proveedor propondrá el precio final.';

  @override
  String get priceTypeLabel => 'Tipo de precio';

  @override
  String get paymentTypeLabel => 'Tipo de pago';

  @override
  String get orderHeaderQuoteTitle => 'Solicitud de cotización';

  @override
  String get orderHeaderQuoteSubtitle =>
      'Describe lo que necesitas y el proveedor podrá enviarte un rango (mínimo/máximo).';

  @override
  String get orderHeaderImmediateTitle => 'Servicio inmediato';

  @override
  String get orderHeaderImmediateSubtitle =>
      'Se llamará a un proveedor disponible lo antes posible.';

  @override
  String get orderHeaderScheduledTitle => 'Servicio programado';

  @override
  String get orderHeaderScheduledSubtitle =>
      'Elija el día y la hora para que el proveedor acuda a usted.';

  @override
  String get orderHeaderDefaultTitle => 'Nuevo orden';

  @override
  String get orderHeaderDefaultSubtitle =>
      'Describe el servicio que necesitas.';

  @override
  String get orderEditTitle => 'Editar orden';

  @override
  String get orderNewTitle => 'Nuevo orden';

  @override
  String get whenServiceNeededLabel => '¿Cuándo necesitas el servicio?';

  @override
  String get categoryLabel => 'Categoría';

  @override
  String get categoryHint => 'Elija la categoría de servicio';

  @override
  String get orderTitleLabel => 'Título del pedido';

  @override
  String get orderTitleRequiredError => 'Escribe un título para el pedido.';

  @override
  String get orderDescriptionOptionalLabel => 'Descripción (opcional)';

  @override
  String get locationApproxLabel => 'Ubicación aproximada';

  @override
  String get locationSelectedLabel => 'Ubicación seleccionada.';

  @override
  String get locationSelectPrompt =>
      'Elija dónde se realizará el servicio (aproximado).';

  @override
  String get locationAddressHint =>
      'Calle, número, piso, referencia (opcional, pero ayuda mucho)';

  @override
  String get locationGetting => 'Obteniendo ubicación...';

  @override
  String get locationUseCurrent => 'Usar ubicación actual';

  @override
  String get locationChooseOnMap => 'Elige en el mapa';

  @override
  String get serviceDateTimeLabel => 'Fecha y hora del servicio';

  @override
  String get serviceDateTimePick => 'Elige día y hora';

  @override
  String get saveChangesButton => 'Guardar cambios';

  @override
  String get submitOrderButton => 'Solicitar servicio';

  @override
  String get mapSelectTitle => 'Elige ubicación en el mapa';

  @override
  String get mapSelectInstruction =>
      'Arrastre el mapa hasta la ubicación aproximada del servicio y luego confirme.';

  @override
  String get mapSelectConfirm => 'Confirmar ubicación';

  @override
  String get orderDetailsTitle => 'Detalles del pedido';

  @override
  String orderLoadError(Object error) {
    return 'Error al cargar orden: $error';
  }

  @override
  String get orderNotFound => 'Orden no encontrada.';

  @override
  String get scheduledNoDate => 'Programado (sin fecha fijada)';

  @override
  String get orderValueRejectedTitle =>
      'El cliente rechazó el valor propuesto.';

  @override
  String get orderValueRejectedBody =>
      'Charle con el cliente y proponga un nuevo valor cuando esté alineado.';

  @override
  String get actionProposeNewValue => 'Proponer nuevo valor';

  @override
  String get noShowReportedTitle => 'No se presentó reportado';

  @override
  String noShowReportedBy(Object role) {
    return 'Reportado por: $role';
  }

  @override
  String noShowReportedAt(Object date) {
    return 'En: $date';
  }

  @override
  String get noShowTitle => 'No presentarse';

  @override
  String get noShowDescription =>
      'Si la otra persona no se presentó, puedes denunciarlo.';

  @override
  String get noShowReportAction => 'Informar de no presentarse';

  @override
  String get orderInfoTitle => 'Información del pedido';

  @override
  String get orderInfoIdLabel => 'ID de pedido';

  @override
  String get orderInfoCreatedAtLabel => 'Creado en';

  @override
  String get orderInfoStatusLabel => 'Estado';

  @override
  String get orderInfoModeLabel => 'Modo';

  @override
  String get orderInfoValueLabel => 'Valor';

  @override
  String get orderLocationTitle => 'Ubicación del pedido';

  @override
  String get orderDescriptionTitle => 'Descripción del pedido';

  @override
  String get providerMessageTitle => 'Mensaje del proveedor';

  @override
  String get actionEditOrder => 'Editar orden';

  @override
  String get actionCancelOrder => 'Cancelar pedido';

  @override
  String get cancelOrderTitle => 'Cancelar pedido';

  @override
  String get orderCancelInProgressWarning =>
      'El servicio ya está en marcha.\nCancelar ahora puede resultar en un reembolso parcial.';

  @override
  String get orderCancelConfirmPrompt =>
      '¿Estás seguro de que deseas cancelar este pedido?';

  @override
  String get orderCancelReasonLabel => 'Motivo de cancelación';

  @override
  String get orderCancelReasonOptionalLabel => 'Razón (opcional)';

  @override
  String orderCancelledSnack(Object message) {
    return 'Pedido cancelado. $message.';
  }

  @override
  String orderCancelError(Object error) {
    return 'Error al cancelar el pedido: $error';
  }

  @override
  String get noShowReportDialogTitle => 'Informar de no presentarse';

  @override
  String get noShowReportDialogDescription =>
      'Utilice esto sólo si la otra persona no apareció.';

  @override
  String get noShowReasonOptionalLabel => 'Razón (opcional)';

  @override
  String get actionReport => 'Informe';

  @override
  String get noShowReportSuccess => 'Se informó que no se presentó.';

  @override
  String noShowReportError(Object error) {
    return 'Error al informar de no presentarse: $error';
  }

  @override
  String get orderFinalValueTitle => 'Proponer nuevo valor final';

  @override
  String get orderFinalValueLabel => 'Valor';

  @override
  String get orderFinalValueInvalid => 'Introduzca un valor válido.';

  @override
  String get orderFinalValueSent => 'Nuevo valor enviado al cliente.';

  @override
  String orderFinalValueSendError(Object error) {
    return 'Error al enviar nuevo valor: $error';
  }

  @override
  String get ratingSentTitle => 'Calificación enviada';

  @override
  String get ratingProviderTitle => 'Calificación del proveedor';

  @override
  String get ratingPrompt => 'Dejar una valoración del 1 al 5.';

  @override
  String get ratingCommentLabel => 'Comentario (opcional)';

  @override
  String get ratingSendAction => 'Enviar calificación';

  @override
  String get ratingSelectError => 'Elija una calificación.';

  @override
  String get ratingSentSnack => 'Calificación enviada.';

  @override
  String ratingSendError(Object error) {
    return 'Error al enviar la calificación: $error';
  }

  @override
  String get timelineCreated => 'Creado';

  @override
  String get timelineAccepted => 'Aceptado';

  @override
  String get timelineInProgress => 'En curso';

  @override
  String get timelineCancelled => 'Cancelado';

  @override
  String get timelineCompleted => 'Terminado';

  @override
  String get lookingForProviderBanner =>
      'Todavía estamos buscando un proveedor para este pedido.';

  @override
  String get actionView => 'Vista';

  @override
  String get chatNoMessagesSubtitle => 'Aún no hay mensajes';

  @override
  String chatPreviewWithTime(Object preview, Object time) {
    return '$preview • $time';
  }

  @override
  String chatMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes',
      one: '1 mensaje',
    );
    return '$_temp0';
  }

  @override
  String get actionClose => 'Cerca';

  @override
  String get actionOpen => 'Abierto';

  @override
  String get chatAuthRequired =>
      'Debes estar autenticado para enviar mensajes.';

  @override
  String chatSendError(Object error) {
    return 'Error al enviar mensaje: $error';
  }

  @override
  String get todayLabel => 'Hoy';

  @override
  String get yesterdayLabel => 'Ayer';

  @override
  String chatLoadError(Object error) {
    return 'Error al cargar mensajes: $error';
  }

  @override
  String get chatEmptyMessage => 'Aún no hay mensajes.\n¡Envía el primero!';

  @override
  String get chatInputHint => 'Escribe un mensaje...';

  @override
  String get chatLoginHint => 'Inicia sesión para enviar mensajes';

  @override
  String get roleLabelSystem => 'Sistema';

  @override
  String get youLabel => 'Tú';

  @override
  String distanceMeters(Object meters) {
    return '${meters}m';
  }

  @override
  String distanceKilometers(Object kilometers) {
    return '$kilometers kilómetros';
  }

  @override
  String get etaLessThanMinute => '<1 minuto';

  @override
  String etaMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String etaHours(Object hours) {
    return '$hours horas';
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
  String get orderMapTitle => 'Ordenar mapa';

  @override
  String get orderChatTitle => 'Charla sobre este pedido';

  @override
  String get messagesTitle => 'Mensajes';

  @override
  String get messagesSearchHint => 'Buscar mensajes';

  @override
  String messagesLoadError(Object error) {
    return 'Error al cargar conversaciones: $error';
  }

  @override
  String get messagesEmpty =>
      'Aún no tienes ninguna conversación.\nUna vez que chatee con un proveedor/cliente, aparecerá aquí.';

  @override
  String get messagesNewConversationTitle => 'Nueva conversación';

  @override
  String get messagesNewConversationBody =>
      'Para iniciar una conversación con un proveedor o cliente, vaya a \"Pedidos\" o acepte un nuevo pedido.';

  @override
  String get messagesFilterAll => 'Todo';

  @override
  String get messagesFilterUnread => 'No leído';

  @override
  String get messagesFilterFavorites => 'Favoritos';

  @override
  String get messagesFilterGroups => 'Grupos';

  @override
  String messagesFilterEmpty(Object filter) {
    return 'Nada en \"$filter\"';
  }

  @override
  String get messagesSearchNoResults => 'No se encontraron conversaciones.';

  @override
  String get messagesPinConversation => 'Fijar conversación';

  @override
  String get messagesUnpinConversation => 'Desanclar conversación';

  @override
  String get chatPresenceOnline => 'en línea';

  @override
  String chatPresenceLastSeenAt(Object time) {
    return 'visto por última vez a las $time';
  }

  @override
  String chatPresenceLastSeenYesterdayAt(Object time) {
    return 'visto por última vez ayer a las $time';
  }

  @override
  String chatPresenceLastSeenOn(Object date, Object time) {
    return 'visto por última vez el $date a las $time';
  }

  @override
  String get chatImageTooLarge => 'Imagen demasiado grande (máximo 15 MB).';

  @override
  String chatImageSendError(Object error) {
    return 'Error al enviar la imagen: $error';
  }

  @override
  String get chatFileReadError => 'No se pudo leer el archivo.';

  @override
  String get chatFileTooLarge => 'Archivo demasiado grande (máximo 20 MB).';

  @override
  String chatFileSendError(Object error) {
    return 'Error al enviar el archivo: $error';
  }

  @override
  String get chatAudioReadError => 'No se pudo leer el audio.';

  @override
  String get chatAudioTooLarge => 'Audio demasiado grande (máximo 20 MB).';

  @override
  String chatAudioSendError(Object error) {
    return 'Error al enviar audio: $error';
  }

  @override
  String get chatAttachFile => 'enviar archivo';

  @override
  String get chatAttachGallery => 'Enviar foto (galería)';

  @override
  String get chatAttachCamera => 'Tomar foto (cámara)';

  @override
  String get chatAttachAudio => 'Enviar audio (archivo)';

  @override
  String get chatAttachAudioSubtitle =>
      'Elija un archivo de audio (mp3/m4a/wav/...).';

  @override
  String get chatOpenLink => 'Abrir enlace';

  @override
  String get chatAttachTooltip => 'Adjuntar';

  @override
  String get chatSendTooltip => 'Enviar';

  @override
  String get chatSearchAction => 'Buscar';

  @override
  String get chatSearchHint => 'Buscar mensajes';

  @override
  String get chatSearchEmpty => 'Escribe algo para buscar.';

  @override
  String get chatSearchNoResults => 'No se encontraron mensajes.';

  @override
  String get chatMediaAction => 'Medios, enlaces y archivos.';

  @override
  String get chatMediaTitle => 'Medios, enlaces y archivos.';

  @override
  String get chatMediaPhotosTab => 'Fotos';

  @override
  String get chatMediaLinksTab => 'Campo de golf';

  @override
  String get chatMediaAudioTab => 'Audio';

  @override
  String get chatMediaFilesTab => 'Archivos';

  @override
  String get chatMediaEmptyPhotos => 'Aún no hay fotos.';

  @override
  String get chatMediaEmptyLinks => 'Aún no hay enlaces.';

  @override
  String get chatMediaEmptyAudio => 'Aún no hay audio.';

  @override
  String get chatMediaEmptyFiles => 'Aún no hay archivos.';

  @override
  String get chatFavoritesAction => 'Sembrado de estrellas';

  @override
  String get chatFavoritesTitle => 'Mensajes destacados';

  @override
  String get chatFavoritesEmpty => 'Aún no tienes mensajes destacados.';

  @override
  String get chatStarAction => 'Añadir a favoritos';

  @override
  String get chatUnstarAction => 'Quitar de favoritos';

  @override
  String get chatViewProviderProfileAction => 'Ver perfil de proveedor';

  @override
  String get chatViewCustomerProfileAction => 'Ver perfil de cliente';

  @override
  String get chatIncomingCall => 'Llamada entrante';

  @override
  String get chatCallStartedVideo => 'Videollamada iniciada';

  @override
  String get chatCallStartedVoice => 'Llamada de voz iniciada';

  @override
  String get chatImageLabel => 'Imagen';

  @override
  String get chatAudioLabel => 'Audio';

  @override
  String get chatFileLabel => 'Archivo';

  @override
  String get chatCallEntryLabel => 'Llamar';

  @override
  String get chatNoSession =>
      'Ninguna sesión activa. Inicia sesión para acceder al chat.';

  @override
  String get chatTitleFallback => 'Charlar';

  @override
  String get chatVideoCallAction => 'Videollamada';

  @override
  String get chatVoiceCallAction => 'Llamar';

  @override
  String get chatMarkReadAction => 'Marcar como leído';

  @override
  String get chatCallMissingParticipant =>
      'El otro participante aún no está asignado a este pedido.';

  @override
  String get chatCallStartError => 'No se pudo iniciar la llamada.';

  @override
  String chatCallMessageVideo(Object url) {
    return 'Videollamada: $url';
  }

  @override
  String chatCallMessageVoice(Object url) {
    return 'Llamada: $url';
  }

  @override
  String get profileProviderTitle => 'Perfil de proveedor';

  @override
  String get profileCustomerTitle => 'Perfil del cliente';

  @override
  String get profileAboutTitle => 'Acerca de';

  @override
  String get profileLocationTitle => 'Ubicación';

  @override
  String get profileServicesTitle => 'Servicios';

  @override
  String get profilePortfolioTitle => 'Cartera';

  @override
  String get chatOpenFullAction => 'Abrir chat completo';

  @override
  String get chatOpenFullUnavailable =>
      'El otro participante aún no está asignado a esta orden.';

  @override
  String get chatReplyAction => 'Responder';

  @override
  String get chatCopyAction => 'Copiar';

  @override
  String get chatDeleteAction => 'Borrar';

  @override
  String get storyNewTitle => 'Nueva historia';

  @override
  String get storyPublishing => 'Publicando historia...';

  @override
  String get storyPublished => '¡Historia publicada! Caduca en 24h.';

  @override
  String storyPublishError(Object error) {
    return 'Error al publicar la historia: $error';
  }

  @override
  String get storyCaptionHint => 'Título (opcional)';

  @override
  String get actionPublish => 'Publicar';

  @override
  String get snackOrderRemoved => 'Orden eliminada.';

  @override
  String get snackClientCancelledOrder => 'El cliente canceló el pedido.';

  @override
  String get snackOrderCancelled => 'Pedido cancelado.';

  @override
  String get snackOrderAcceptedByAnother => 'Otro proveedor aceptó el pedido.';

  @override
  String get snackOrderUpdated => 'Orden actualizada.';

  @override
  String get snackUserNotAuthenticated => 'Usuario no autenticado.';

  @override
  String get snackOrderAcceptedCanQuote =>
      'Pedido aceptado. Puede enviar el presupuesto en los detalles del pedido.';

  @override
  String get snackOrderAcceptedSuccess => 'Pedido aceptado.';

  @override
  String snackErrorAcceptingOrder(Object error) {
    return 'Error al aceptar el pedido: $error';
  }

  @override
  String get dialogTitleOrderAccepted => 'Pedido aceptado';

  @override
  String get dialogContentQuotePrompt =>
      'Este pedido es por cotización.\n\n¿Quieres enviar el rango de cotización ahora?';

  @override
  String get dialogTitleProposeService => 'Proponer servicio';

  @override
  String get dialogContentProposeService =>
      'Establezca un rango de precios para este servicio.\nIncluye viajes y mano de obra.';

  @override
  String get labelMinValue => 'Valor mínimo';

  @override
  String get labelMaxValue => 'Valor máximo';

  @override
  String get labelMessageOptional => 'Mensaje al cliente (opcional)';

  @override
  String hintExampleValue(Object value) {
    return 'Ej.: $value';
  }

  @override
  String get hintProposalMessage =>
      'Ej.: Incluye viajes. Los materiales grandes son adicionales.';

  @override
  String get snackFillValidValues =>
      'Introduzca valores mínimos y máximos válidos.';

  @override
  String get snackMinCannotBeGreaterThanMax =>
      'El mínimo no puede ser mayor que el máximo.';

  @override
  String get snackProposalSent => 'Propuesta enviada al cliente.';

  @override
  String snackErrorSendingProposal(Object error) {
    return 'Error al enviar la propuesta: $error';
  }
}
