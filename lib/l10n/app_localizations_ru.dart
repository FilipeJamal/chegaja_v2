// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ЧегаЯ';

  @override
  String get roleSelectorWelcome => 'Добро пожаловать в ЧегаЯ';

  @override
  String get roleSelectorPrompt =>
      'Выберите, как вы хотите использовать приложение:';

  @override
  String get roleCustomerTitle => 'я клиент';

  @override
  String get roleCustomerDescription =>
      'Я хочу найти поставщиков услуг рядом со мной.';

  @override
  String get roleProviderTitle => 'я провайдер';

  @override
  String get roleProviderDescription =>
      'Я хочу получать запросы клиентов и зарабатывать больше.';

  @override
  String get invalidSession => 'Неверная сессия.';

  @override
  String get paymentsTitle => 'Платежи (полоса)';

  @override
  String get paymentsHeading => 'Получайте онлайн-платежи';

  @override
  String get paymentsDescription =>
      'Чтобы получать платежи через приложение, вам необходимо создать учетную запись Stripe (Connect Express).\nОнбординг открывается в вашем браузере и занимает 2–3 минуты.';

  @override
  String get paymentsActive => 'Онлайн-платежи АКТИВНЫ.';

  @override
  String get paymentsInactive =>
      'Онлайн-платежи пока не активны. Полная адаптация.';

  @override
  String stripeAccountLabel(Object accountId) {
    return 'Учетная запись Stripe: $accountId';
  }

  @override
  String get onboardingOpened =>
      'Регистрация открыта. После завершения вернитесь, чтобы проверить статус.';

  @override
  String onboardingStartError(Object error) {
    return 'Ошибка при запуске регистрации: $error.';
  }

  @override
  String get manageStripeAccount => 'Управление учетной записью Stripe';

  @override
  String get activatePayments => 'Активировать платежи';

  @override
  String get technicalNotesTitle => 'Технические примечания';

  @override
  String get technicalNotesBody =>
      '• Stripe настраивается с помощью облачных функций (на стороне сервера).\n• Комиссия платформы применяется автоматически в PaymentIntent.\n• В рабочей среде добавьте веб-перехватчик Stripe и сохраните секрет веб-перехватчика в функциях.';

  @override
  String kycTitle(Object status) {
    return 'Проверка личности: $status';
  }

  @override
  String get kycDescription =>
      'Отправьте документ (фото или PDF). Полная проверка появилась в версии 2.6.';

  @override
  String get kycSendDocument => 'Отправить документ';

  @override
  String get kycAddDocument => 'Добавить документ';

  @override
  String get kycStatusApproved => 'Одобренный';

  @override
  String get kycStatusRejected => 'Отклоненный';

  @override
  String get kycStatusInReview => 'На рассмотрении';

  @override
  String get kycStatusNotStarted => 'Не запущено';

  @override
  String get kycFileReadError => 'Не удалось прочитать файл.';

  @override
  String get kycFileTooLarge => 'Файл слишком большой (макс. 10 МБ).';

  @override
  String get kycUploading => 'Загрузка документа...';

  @override
  String get kycUploadSuccess => 'Документ отправлен на рассмотрение.';

  @override
  String kycUploadError(Object error) {
    return 'Ошибка отправки документа: $error';
  }

  @override
  String get statusCancelledByYou => 'Отменено вами';

  @override
  String get statusCancelledByProvider => 'Отменено провайдером';

  @override
  String get statusCancelled => 'Отменено';

  @override
  String get statusLookingForProvider => 'Ищу провайдера';

  @override
  String get statusProviderPreparingQuote =>
      'Поставщик найден (подготавливается коммерческое предложение)';

  @override
  String get statusQuoteToDecide =>
      'У вас есть предложение, чтобы принять решение';

  @override
  String get statusProviderFound => 'Провайдер найден';

  @override
  String get statusServiceInProgress => 'Обслуживание в процессе';

  @override
  String get statusAwaitingValueConfirmation =>
      'Ожидаем подтверждения стоимости';

  @override
  String get statusServiceCompleted => 'Обслуживание завершено';

  @override
  String valueToConfirm(Object value) {
    return '$value (для подтверждения)';
  }

  @override
  String valueProposed(Object value) {
    return '$value (предлагается)';
  }

  @override
  String valueEstimatedRange(Object min, Object max) {
    return 'От $min до $max (приблизительно)';
  }

  @override
  String valueEstimatedFrom(Object min) {
    return 'С $min (приблизительно)';
  }

  @override
  String valueEstimatedUpTo(Object max) {
    return 'До $max (оценка)';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get priceFixed => 'Фиксированная цена';

  @override
  String get priceByQuote => 'По цитате';

  @override
  String get priceToArrange => 'Быть организованным';

  @override
  String get paymentOnlineBefore => 'Онлайн оплата (раньше)';

  @override
  String get paymentOnlineAfter => 'Онлайн оплата (после)';

  @override
  String get paymentCash => 'Оплата наличными';

  @override
  String get pendingActionQuoteToReview =>
      'У вас есть предложение/цена для рассмотрения.';

  @override
  String get pendingActionValueToConfirm =>
      'Поставщик отправил окончательное значение. Вам нужно подтвердить.';

  @override
  String get pendingActionProviderPreparingQuote =>
      'Провайдер найден. Они готовят предложение.';

  @override
  String get pendingActionProviderChat =>
      'Провайдер найден. Вы можете пообщаться с ними.';

  @override
  String get roleLabelCustomer => 'Клиент';

  @override
  String get navHome => 'Дом';

  @override
  String get navMyOrders => 'Мои заказы';

  @override
  String get navMessages => 'Сообщения';

  @override
  String get navProfile => 'Профиль';

  @override
  String get homeGreeting => 'Привет';

  @override
  String get homeSubtitle => 'Что вам нужно сегодня?';

  @override
  String get homePendingTitle => 'Вам есть что решить';

  @override
  String get homePendingCta =>
      'Нажмите здесь, чтобы открыть следующий заказ и принять решение.';

  @override
  String servicesLoadError(Object error) {
    return 'Ошибка загрузки служб: $error.';
  }

  @override
  String get servicesEmptyMessage =>
      'Службы пока не настроены.\\nСкоро здесь появятся категории 🙂';

  @override
  String get availableServicesTitle => 'Доступные услуги';

  @override
  String get serviceTabImmediate => 'Немедленный';

  @override
  String get serviceTabScheduled => 'Запланировано';

  @override
  String get serviceTabQuote => 'По цитате';

  @override
  String get unreadMessagesTitle => 'У вас есть новые сообщения';

  @override
  String get unreadMessagesCta => 'Нажмите здесь, чтобы открыть чат.';

  @override
  String get serviceSearchHint => 'Поисковый сервис...';

  @override
  String get serviceSearchEmpty => 'По данному запросу услуги не найдены.';

  @override
  String get serviceModeImmediateDescription =>
      'Поставщик приезжает сегодня как можно быстрее.';

  @override
  String get serviceModeScheduledDescription =>
      'Назначьте день и время оказания услуги.';

  @override
  String get serviceModeQuoteDescription =>
      'Запросить цену (поставщик отправляет минимальный/максимальный диапазон).';

  @override
  String get userNotAuthenticatedError =>
      'Ошибка: пользователь не аутентифицирован.';

  @override
  String get myOrdersTitle => 'Мои заказы';

  @override
  String get ordersTabPending => 'В ожидании';

  @override
  String get ordersTabCompleted => 'Завершенный';

  @override
  String get ordersTabCancelled => 'Отменено';

  @override
  String ordersLoadError(Object error) {
    return 'Ошибка при загрузке заказов: $error.';
  }

  @override
  String get ordersEmptyPending =>
      'У вас нет отложенных ордеров.\\nСоздайте новый заказ на главном экране.';

  @override
  String get ordersEmptyCompleted => 'У вас еще нет выполненных заказов.';

  @override
  String get ordersEmptyCancelled => 'У вас еще нет отмененных заказов.';

  @override
  String get orderQuoteScheduled => 'Цитата (по расписанию)';

  @override
  String get orderQuoteImmediate => 'Цитата (сразу)';

  @override
  String get orderScheduled => 'Плановое обслуживание';

  @override
  String get orderImmediate => 'Немедленное обслуживание';

  @override
  String get categoryNotDefined => 'Категория не определена';

  @override
  String orderStateLabel(Object state) {
    return 'Состояние: $state';
  }

  @override
  String orderPriceModelLabel(Object model) {
    return 'Ценовая модель: $model';
  }

  @override
  String orderPaymentLabel(Object payment) {
    return 'Оплата: $payment';
  }

  @override
  String orderValueLabel(Object value) {
    return 'Значение: $value';
  }

  @override
  String accountTitle(Object role) {
    return 'Аккаунт ($role)';
  }

  @override
  String get accountNameTitle => 'Ваше имя';

  @override
  String get accountProfileSubtitle => 'Профиль';

  @override
  String get accountSettings => 'Настройки';

  @override
  String get accountHelpSupport => 'Помощь и поддержка';

  @override
  String get navMyJobs => 'Мои вакансии';

  @override
  String get roleLabelProvider => 'Поставщик';

  @override
  String get enableLocationToGoOnline =>
      'Включите местоположение для выхода в Интернет.';

  @override
  String get nearbyOrdersTitle => 'Заказы рядом с вами';

  @override
  String get noOrdersAvailableMessage => 'На данный момент заказов нет.';

  @override
  String get configureServiceAreaMessage =>
      'Установите зону обслуживания и услуги, чтобы начать получать заказы.';

  @override
  String get configureAction => 'Настроить';

  @override
  String get offlineEnableOnlineMessage =>
      'Вы оффлайн. Включите онлайн-статус для получения заказов.';

  @override
  String get noMatchingOrdersMessage =>
      'Нет подходящих заказов для ваших услуг и региона.';

  @override
  String get orderAcceptedMessage => 'Заказ принят.';

  @override
  String get orderAcceptedCanSendQuote =>
      'Заказ принят. Вы можете отправить ценовое предложение позже.';

  @override
  String orderAcceptError(Object error) {
    return 'Ошибка принятия заказа: $error.';
  }

  @override
  String get orderAcceptedDialogTitle => 'Заказ принят';

  @override
  String get orderAcceptedBudgetPrompt =>
      'Этот заказ осуществляется по котировке.\\n\\nХотите отправить диапазон котировок сейчас?';

  @override
  String get actionLater => 'Позже';

  @override
  String get actionSendNow => 'Отправить сейчас';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionSend => 'Отправлять';

  @override
  String get actionIgnore => 'игнорировать';

  @override
  String get actionAccept => 'Принимать';

  @override
  String get actionNo => 'Нет';

  @override
  String get actionYesCancel => 'Да, отменить';

  @override
  String get proposalDialogTitle => 'Отправить предложение';

  @override
  String get proposalDialogDescription =>
      'Установите диапазон цен на эту услугу.\\nВключите проезд и работу.';

  @override
  String proposalMinValueLabel(Object currency) {
    return 'Минимальное значение ($currency)';
  }

  @override
  String get proposalMinValueHint => 'Пример: 20';

  @override
  String proposalMaxValueLabel(Object currency) {
    return 'Максимальное значение ($currency)';
  }

  @override
  String get proposalMaxValueHint => 'Пример: 35';

  @override
  String get proposalMessageLabel => 'Сообщение клиенту (необязательно)';

  @override
  String get proposalMessageHint =>
      'Пример: Включает поездку. Крупногабаритные материалы оплачиваются дополнительно.';

  @override
  String get proposalInvalidValues =>
      'Введите допустимые минимальные и максимальные значения.';

  @override
  String get proposalMinGreaterThanMax =>
      'Минимум не может быть больше максимума.';

  @override
  String get proposalSent => 'Предложение отправлено заказчику.';

  @override
  String proposalSendError(Object error) {
    return 'Ошибка отправки предложения: $error.';
  }

  @override
  String get providerHomeGreeting => 'Привет, провайдер';

  @override
  String get providerHomeSubtitle =>
      'Заходите в Интернет, чтобы получать новые заказы.';

  @override
  String get providerStatusOnline => 'Ты ОНЛАЙН';

  @override
  String get providerStatusOffline => 'Ты ОФФЛАЙН';

  @override
  String providerSettingsLoadError(Object error) {
    return 'Ошибка загрузки настроек: $error.';
  }

  @override
  String providerSettingsSaveError(Object error) {
    return 'Ошибка сохранения настроек: $error.';
  }

  @override
  String get serviceAreaTitle => 'Зона обслуживания';

  @override
  String get serviceAreaHeading => 'Где вы хотите получать заказы?';

  @override
  String get serviceAreaSubtitle =>
      'Установите предоставляемые вами услуги и максимальный радиус вокруг вашего базового города.';

  @override
  String get serviceAreaBaseLocation => 'Базовое расположение';

  @override
  String get serviceAreaRadius => 'Радиус обслуживания';

  @override
  String get serviceAreaSaved => 'Зона обслуживания успешно сохранена.';

  @override
  String get serviceAreaInfoNote =>
      'В будущем мы будем использовать эти настройки для фильтрации заказов по близости и типу услуги. На данный момент это помогает нам подготовить соответствующий движок.';

  @override
  String get availabilityTitle => 'Доступность';

  @override
  String get servicesYouProvideTitle => 'Услуги, которые вы предоставляете';

  @override
  String get servicesCatalogEmpty =>
      'В каталоге пока не настроено ни одной службы.';

  @override
  String get servicesSearchPrompt => 'Введите для поиска и добавления услуг.';

  @override
  String get servicesSearchNoResults => 'Сервисы не найдены.';

  @override
  String get servicesSelectedTitle => 'Выбранные услуги';

  @override
  String get serviceUnnamed => 'Безымянный сервис';

  @override
  String get serviceModeQuote => 'Цитировать';

  @override
  String get serviceModeScheduled => 'Запланировано';

  @override
  String get serviceModeImmediate => 'Немедленный';

  @override
  String get providerServicesSelectAtLeastOne =>
      'Выберите хотя бы одну услугу, которую вы предоставляете.';

  @override
  String get countryLabel => 'Страна';

  @override
  String get cityLabel => 'Город';

  @override
  String get stateLabelDistrict => 'Округ';

  @override
  String get stateLabelProvince => 'Провинция';

  @override
  String get stateLabelState => 'Состояние';

  @override
  String get stateLabelRegion => 'Область';

  @override
  String get stateLabelCounty => 'Графство';

  @override
  String get stateLabelRegionOrState => 'Регион/штат';

  @override
  String get searchHint => 'Поиск...';

  @override
  String get searchCountryHint => 'Введите для поиска стран';

  @override
  String get searchGenericHint => 'Введите для поиска';

  @override
  String get searchServicesHint => 'Поисковые сервисы';

  @override
  String get openCountriesListTooltip => 'Посмотреть список стран';

  @override
  String get openListTooltip => 'Посмотреть список';

  @override
  String get selectCountryTitle => 'Выберите страну';

  @override
  String get selectCityTitle => 'Выберите город';

  @override
  String selectFieldTitle(Object field) {
    return 'Выберите $field';
  }

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get supportTitle => 'Помощь и поддержка';

  @override
  String get supportSubtitle => 'Есть вопросы? Связаться с нами.';

  @override
  String get myScheduleTitle => 'Мое расписание';

  @override
  String get myScheduleSubtitle => 'Установить часы и выходные дни';

  @override
  String get languageTitle => 'Язык';

  @override
  String get languageModeManual => 'Руководство';

  @override
  String get languageModeAuto => 'Авто';

  @override
  String languageModeLabel(Object code, Object mode) {
    return '$code – $mode';
  }

  @override
  String get languageAutoSystem => 'Авто (система)';

  @override
  String get providerCategoriesTitle => 'Категории услуг';

  @override
  String get providerCategoriesSubtitle =>
      'Мы используем категории для фильтрации совместимых заказов.';

  @override
  String get providerCategoriesEmpty => 'Категория не выбрана.';

  @override
  String get providerCategoriesSelect => 'Выберите категории';

  @override
  String get providerCategoriesEdit => 'Добавить или изменить категории';

  @override
  String get providerCategoriesRequiredMessage =>
      'Выберите категории, чтобы получать соответствующие заказы.';

  @override
  String get providerKpiEarningsToday => 'Прибыль сегодня (чистая)';

  @override
  String get providerKpiServicesThisMonth => 'Услуги в этом месяце';

  @override
  String providerKpiGrossFeeSubtitle(Object gross, Object fee) {
    return 'Валовая сумма: $gross - Комиссия: $fee';
  }

  @override
  String get providerHighlightTitle =>
      'У вас есть работа, которой нужно управлять';

  @override
  String get providerHighlightCta =>
      'Нажмите здесь, чтобы открыть следующее задание.';

  @override
  String get providerPendingActionAccepted =>
      'У вас есть принятая работа, и вы готовы приступить к ней.';

  @override
  String get providerPendingActionInProgress =>
      'У вас есть работа. Отметьте его завершенным, когда закончите.';

  @override
  String get providerPendingActionSetFinalValue =>
      'Установите и отправьте окончательное значение услуги.';

  @override
  String get providerUnreadMessagesTitle =>
      'У вас есть новые сообщения от клиентов';

  @override
  String providerUnreadMessagesJob(Object jobTitle) {
    return 'На работе: $jobTitle';
  }

  @override
  String get providerJobsTitle => 'Мои работы';

  @override
  String get providerJobsTabOpen => 'Открыть';

  @override
  String get providerJobsTabCompleted => 'Завершенный';

  @override
  String get providerJobsTabCancelled => 'Отменено';

  @override
  String providerJobsLoadError(Object error) {
    return 'Ошибка загрузки заданий: $error.';
  }

  @override
  String get providerJobsEmptyOpen =>
      'У вас пока нет открытых вакансий.\\nПерейдите на главную и примите заказ.';

  @override
  String get providerJobsEmptyCompleted => 'У вас еще нет завершенных работ.';

  @override
  String get providerJobsEmptyCancelled => 'У вас еще нет отмененных заданий.';

  @override
  String scheduledForDate(Object date) {
    return 'Запланировано: $date';
  }

  @override
  String get viewDetailsTooltip => 'Посмотреть детали';

  @override
  String clientPaidValueLabel(Object value) {
    return 'Клиент заплатил: $value';
  }

  @override
  String providerEarningsFeeLabel(Object value, Object fee) {
    return 'Вы получаете: $value - Комиссия: $fee';
  }

  @override
  String serviceValueLabel(Object value) {
    return 'Стоимость услуги: $value';
  }

  @override
  String get cancelJobTitle => 'Отменить задание';

  @override
  String get cancelJobPrompt =>
      'Вы уверены, что хотите отменить это задание?\\nЗаказ может стать доступен другим поставщикам.';

  @override
  String get cancelJobReasonLabel => 'Причина отмены (необязательно):';

  @override
  String get cancelJobReasonFieldLabel => 'Причина';

  @override
  String get cancelJobDetailLabel => 'Подробности отмены';

  @override
  String get cancelJobDetailRequired => 'Пожалуйста, добавьте деталь.';

  @override
  String get cancelJobSuccess => 'Работа отменена.';

  @override
  String cancelJobError(Object error) {
    return 'Ошибка отмены задания: $error.';
  }

  @override
  String get providerAccountProfileTitle => 'Посмотреть мой профиль';

  @override
  String get providerAccountProfileSubtitle => 'Профиль провайдера';

  @override
  String get activateOnlinePaymentsSubtitle => 'Включить онлайн-платежи';

  @override
  String get statusProviderWaiting => 'Новый запрос';

  @override
  String get statusQuoteWaitingCustomer => 'Ожидание ответа клиента';

  @override
  String get statusAcceptedToStart => 'Принято (готово к запуску)';

  @override
  String get statusInProgress => 'В ходе выполнения';

  @override
  String get statusCompleted => 'Завершенный';

  @override
  String get orderDefaultImmediateTitle => 'Срочная услуга';

  @override
  String get locationServiceDisabled =>
      'На устройстве отключена служба определения местоположения.';

  @override
  String get locationPermissionDenied =>
      'Разрешение на определение местоположения отклонено.\\nНе удалось получить текущее местоположение.';

  @override
  String get locationPermissionDeniedForever =>
      'Разрешение на определение местоположения навсегда отклонено.\\nВключите определение местоположения в настройках устройства.';

  @override
  String locationFetchError(Object error) {
    return 'Ошибка получения местоположения: $error.';
  }

  @override
  String get formNotReadyError => 'Форма еще не готова. Попробуйте еще раз.';

  @override
  String get missingRequiredFieldsError =>
      'Обязательные поля отсутствуют. Проверьте поля, выделенные красным.';

  @override
  String get scheduleDateTimeRequiredError =>
      'Выберите дату и время оказания услуги.';

  @override
  String get scheduleDateTimeFutureError => 'Выберите будущую дату/время.';

  @override
  String get categoryRequiredError => 'Выберите категорию.';

  @override
  String get orderUpdatedSuccess => 'Заказ успешно обновлен!';

  @override
  String get orderCreatedSuccess => 'Заказ создан! Ищем провайдера...';

  @override
  String orderUpdateError(Object error) {
    return 'Ошибка обновления заказа: $error.';
  }

  @override
  String orderCreateError(Object error) {
    return 'Ошибка при создании заказа: $error.';
  }

  @override
  String get orderTitleExamplePlumbing =>
      'Пример: Течь водопровода под раковиной.';

  @override
  String get orderTitleExampleElectric =>
      'Пример: не работает розетка в гостиной + установите потолочный светильник.';

  @override
  String get orderTitleExampleCleaning =>
      'Пример: Полная уборка 2-комнатной квартиры (кухня, санузел, окна, пол).';

  @override
  String get orderTitleHintImmediate =>
      'Кратко объясните, что происходит и что вам нужно.';

  @override
  String get orderTitleHintScheduled =>
      'Скажите, когда вам нужна услуга, подробности о местоположении и что нужно сделать.';

  @override
  String get orderTitleHintQuote =>
      'Опишите услугу, по которой вы хотите получать предложения.';

  @override
  String get orderTitleHintDefault => 'Опишите услугу, которая вам нужна.';

  @override
  String get orderDescriptionExampleCleaning =>
      'Пример: Полная уборка 2-комнатной квартиры (кухня, санузел, окна, пол).';

  @override
  String get orderDescriptionHintImmediate =>
      'Кратко объясните, что происходит и что вам нужно.';

  @override
  String get orderDescriptionHintScheduled =>
      'Скажите, когда вам нужна услуга, подробности о местоположении и что нужно сделать.';

  @override
  String get orderDescriptionHintQuote =>
      'Опишите желаемую услугу, приблизительный бюджет (если он у вас есть) и важные детали.';

  @override
  String get orderDescriptionHintDefault =>
      'Опишите немного подробнее, что вам нужно.';

  @override
  String get priceModelTitle => 'Цена модели';

  @override
  String get priceModelQuoteInfo =>
      'Эта услуга предоставляется по цитате. Поставщик предложит окончательную цену.';

  @override
  String get priceTypeLabel => 'Тип цены';

  @override
  String get paymentTypeLabel => 'Тип платежа';

  @override
  String get orderHeaderQuoteTitle => 'Запрос цены';

  @override
  String get orderHeaderQuoteSubtitle =>
      'Опишите, что вам нужно, и провайдер может прислать диапазон (мин/макс).';

  @override
  String get orderHeaderImmediateTitle => 'Немедленное обслуживание';

  @override
  String get orderHeaderImmediateSubtitle =>
      'Доступный поставщик будет вызван как можно скорее.';

  @override
  String get orderHeaderScheduledTitle => 'Плановое обслуживание';

  @override
  String get orderHeaderScheduledSubtitle =>
      'Выберите день и время, когда провайдер приедет к вам.';

  @override
  String get orderHeaderDefaultTitle => 'Новый заказ';

  @override
  String get orderHeaderDefaultSubtitle => 'Опишите услугу, которая вам нужна.';

  @override
  String get orderEditTitle => 'Изменить заказ';

  @override
  String get orderNewTitle => 'Новый заказ';

  @override
  String get whenServiceNeededLabel => 'Когда вам нужна услуга?';

  @override
  String get categoryLabel => 'Категория';

  @override
  String get categoryHint => 'Выберите категорию услуги';

  @override
  String get orderTitleLabel => 'Название заказа';

  @override
  String get orderTitleRequiredError => 'Напишите название заказа.';

  @override
  String get orderDescriptionOptionalLabel => 'Описание (необязательно)';

  @override
  String get locationApproxLabel => 'Примерное местоположение';

  @override
  String get locationSelectedLabel => 'Место выбрано.';

  @override
  String get locationSelectPrompt =>
      'Выберите, где будет оказана услуга (приблизительно).';

  @override
  String get locationAddressHint =>
      'Улица, номер, этаж, ссылка (необязательно, но очень помогает)';

  @override
  String get locationGetting => 'Получение местоположения...';

  @override
  String get locationUseCurrent => 'Использовать текущее местоположение';

  @override
  String get locationChooseOnMap => 'Выбрать на карте';

  @override
  String get serviceDateTimeLabel => 'Дата и время обслуживания';

  @override
  String get serviceDateTimePick => 'Выберите день и время';

  @override
  String get saveChangesButton => 'Сохранить изменения';

  @override
  String get submitOrderButton => 'Запросить услугу';

  @override
  String get mapSelectTitle => 'Выберите местоположение на карте';

  @override
  String get mapSelectInstruction =>
      'Перетащите карту к приблизительному местоположению службы, затем подтвердите.';

  @override
  String get mapSelectConfirm => 'Подтвердить местоположение';

  @override
  String get orderDetailsTitle => 'Детали заказа';

  @override
  String orderLoadError(Object error) {
    return 'Ошибка загрузки заказа: $error.';
  }

  @override
  String get orderNotFound => 'Заказ не найден.';

  @override
  String get scheduledNoDate => 'Запланировано (дата не установлена)';

  @override
  String get orderValueRejectedTitle =>
      'Заказчик отклонил предложенную стоимость.';

  @override
  String get orderValueRejectedBody =>
      'Поговорите с клиентом и предложите новое значение после согласования.';

  @override
  String get actionProposeNewValue => 'Предложите новую ценность';

  @override
  String get noShowReportedTitle => 'Сообщено о неявке';

  @override
  String noShowReportedBy(Object role) {
    return 'Сообщил: $role';
  }

  @override
  String noShowReportedAt(Object date) {
    return 'В: $date';
  }

  @override
  String get noShowTitle => 'Неявка';

  @override
  String get noShowDescription =>
      'Если другой человек не явился, вы можете сообщить об этом.';

  @override
  String get noShowReportAction => 'Сообщить о неявке';

  @override
  String get orderInfoTitle => 'Информация о заказе';

  @override
  String get orderInfoIdLabel => 'Идентификатор заказа';

  @override
  String get orderInfoCreatedAtLabel => 'Создано в';

  @override
  String get orderInfoStatusLabel => 'Статус';

  @override
  String get orderInfoModeLabel => 'Режим';

  @override
  String get orderInfoValueLabel => 'Ценить';

  @override
  String get orderLocationTitle => 'Место заказа';

  @override
  String get orderDescriptionTitle => 'Описание заказа';

  @override
  String get providerMessageTitle => 'Сообщение поставщика';

  @override
  String get actionEditOrder => 'Изменить заказ';

  @override
  String get actionCancelOrder => 'Отменить заказ';

  @override
  String get cancelOrderTitle => 'Отменить заказ';

  @override
  String get orderCancelInProgressWarning =>
      'Услуга уже выполняется.\nОтмена сейчас может привести к частичному возврату средств.';

  @override
  String get orderCancelConfirmPrompt =>
      'Вы уверены, что хотите отменить этот заказ?';

  @override
  String get orderCancelReasonLabel => 'Причина отмены';

  @override
  String get orderCancelReasonOptionalLabel => 'Причина (необязательно)';

  @override
  String orderCancelledSnack(Object message) {
    return 'Заказ отменен. $message.';
  }

  @override
  String orderCancelError(Object error) {
    return 'Ошибка отмены заказа: $error.';
  }

  @override
  String get noShowReportDialogTitle => 'Сообщить о неявке';

  @override
  String get noShowReportDialogDescription =>
      'Используйте это, только если другой человек не появился.';

  @override
  String get noShowReasonOptionalLabel => 'Причина (необязательно)';

  @override
  String get actionReport => 'Отчет';

  @override
  String get noShowReportSuccess => 'Сообщается о неявке.';

  @override
  String noShowReportError(Object error) {
    return 'Ошибка сообщения о неявке: $error';
  }

  @override
  String get orderFinalValueTitle => 'Предложить новое окончательное значение';

  @override
  String get orderFinalValueLabel => 'Ценить';

  @override
  String get orderFinalValueInvalid => 'Введите допустимое значение.';

  @override
  String get orderFinalValueSent => 'Новое значение отправлено клиенту.';

  @override
  String orderFinalValueSendError(Object error) {
    return 'Ошибка отправки нового значения: $error.';
  }

  @override
  String get ratingSentTitle => 'Оценка отправлена';

  @override
  String get ratingProviderTitle => 'Рейтинг провайдера';

  @override
  String get ratingPrompt => 'Оставьте оценку от 1 до 5.';

  @override
  String get ratingCommentLabel => 'Комментарий (необязательно)';

  @override
  String get ratingSendAction => 'Отправить оценку';

  @override
  String get ratingSelectError => 'Выберите рейтинг.';

  @override
  String get ratingSentSnack => 'Оценка отправлена.';

  @override
  String ratingSendError(Object error) {
    return 'Ошибка отправки рейтинга: $error';
  }

  @override
  String get timelineCreated => 'Созданный';

  @override
  String get timelineAccepted => 'Принял';

  @override
  String get timelineInProgress => 'В ходе выполнения';

  @override
  String get timelineCancelled => 'Отменено';

  @override
  String get timelineCompleted => 'Завершенный';

  @override
  String get lookingForProviderBanner =>
      'Мы все еще ищем поставщика для этого заказа.';

  @override
  String get actionView => 'Вид';

  @override
  String get chatNoMessagesSubtitle => 'Сообщений пока нет';

  @override
  String chatPreviewWithTime(Object preview, Object time) {
    return '$preview • $time';
  }

  @override
  String chatMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ?????????',
      one: '1 ?????????',
    );
    return '$_temp0';
  }

  @override
  String get actionClose => 'Закрывать';

  @override
  String get actionOpen => 'Открыть';

  @override
  String get chatAuthRequired =>
      'Для отправки сообщений вам необходимо пройти аутентификацию.';

  @override
  String chatSendError(Object error) {
    return 'Ошибка отправки сообщения: $error';
  }

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get yesterdayLabel => 'Вчера';

  @override
  String chatLoadError(Object error) {
    return 'Ошибка загрузки сообщений: $error.';
  }

  @override
  String get chatEmptyMessage => 'Сообщений пока нет.\nОтправьте первый!';

  @override
  String get chatInputHint => 'Напишите сообщение...';

  @override
  String get chatLoginHint => 'Войдите, чтобы отправлять сообщения';

  @override
  String get roleLabelSystem => 'Система';

  @override
  String get youLabel => 'Ты';

  @override
  String distanceMeters(Object meters) {
    return '$meters м';
  }

  @override
  String distanceKilometers(Object kilometers) {
    return '$kilometers км';
  }

  @override
  String get etaLessThanMinute => '<1 мин.';

  @override
  String etaMinutes(Object minutes) {
    return '$minutes мин.';
  }

  @override
  String etaHours(Object hours) {
    return '$hours ч.';
  }

  @override
  String etaHoursMinutes(Object hours, Object minutes) {
    return '$hours ч. $minutes мин.';
  }

  @override
  String mapEtaLabel(Object eta, Object distance) {
    return 'Расчетное время прибытия $eta – $distance';
  }

  @override
  String get mapOpenAction => 'Открыть карту';

  @override
  String get orderMapTitle => 'Заказать карту';

  @override
  String get orderChatTitle => 'Обсудить этот заказ';

  @override
  String get messagesTitle => 'Сообщения';

  @override
  String get messagesSearchHint => 'Поиск сообщений';

  @override
  String messagesLoadError(Object error) {
    return 'Ошибка загрузки бесед: $error.';
  }

  @override
  String get messagesEmpty =>
      'У вас пока нет разговоров.\nКогда вы пообщаетесь с поставщиком/клиентом, они появятся здесь.';

  @override
  String get messagesNewConversationTitle => 'Новый разговор';

  @override
  String get messagesNewConversationBody =>
      'Чтобы начать разговор с поставщиком или клиентом, перейдите в раздел «Заказы» или примите новый заказ.';

  @override
  String get messagesFilterAll => 'Все';

  @override
  String get messagesFilterUnread => 'Непрочитано';

  @override
  String get messagesFilterFavorites => 'Избранное';

  @override
  String get messagesFilterGroups => 'Группы';

  @override
  String messagesFilterEmpty(Object filter) {
    return 'Ничего в \"$filter\"';
  }

  @override
  String get messagesSearchNoResults => 'Ни одного разговора не найдено.';

  @override
  String get messagesPinConversation => 'Закрепить беседу';

  @override
  String get messagesUnpinConversation => 'Открепить беседу';

  @override
  String get chatPresenceOnline => 'онлайн';

  @override
  String chatPresenceLastSeenAt(Object time) {
    return 'последний раз видели $time';
  }

  @override
  String chatPresenceLastSeenYesterdayAt(Object time) {
    return 'последний раз видели вчера в $time';
  }

  @override
  String chatPresenceLastSeenOn(Object date, Object time) {
    return 'последний раз видели $date в $time';
  }

  @override
  String get chatImageTooLarge =>
      'Изображение слишком большое (максимум 15 МБ).';

  @override
  String chatImageSendError(Object error) {
    return 'Ошибка отправки изображения: $error';
  }

  @override
  String get chatFileReadError => 'Не удалось прочитать файл.';

  @override
  String get chatFileTooLarge => 'Файл слишком большой (максимум 20 МБ).';

  @override
  String chatFileSendError(Object error) {
    return 'Ошибка отправки файла: $error';
  }

  @override
  String get chatAudioReadError => 'Не удалось прочитать аудио.';

  @override
  String get chatAudioTooLarge => 'Звук слишком большой (максимум 20 МБ).';

  @override
  String chatAudioSendError(Object error) {
    return 'Ошибка отправки аудио: $error';
  }

  @override
  String get chatAttachFile => 'Отправить файл';

  @override
  String get chatAttachGallery => 'Отправить фото (галерея)';

  @override
  String get chatAttachCamera => 'Сфотографировать (камерой)';

  @override
  String get chatAttachAudio => 'Отправить аудио (файл)';

  @override
  String get chatAttachAudioSubtitle => 'Выберите аудиофайл (mp3/m4a/wav/...).';

  @override
  String get chatOpenLink => 'Открыть ссылку';

  @override
  String get chatAttachTooltip => 'Прикреплять';

  @override
  String get chatSendTooltip => 'Отправлять';

  @override
  String get chatSearchAction => 'Поиск';

  @override
  String get chatSearchHint => 'Поиск сообщений';

  @override
  String get chatSearchEmpty => 'Введите что-нибудь для поиска.';

  @override
  String get chatSearchNoResults => 'Сообщений не найдено.';

  @override
  String get chatMediaAction => 'Медиа, ссылки и файлы';

  @override
  String get chatMediaTitle => 'Медиа, ссылки и файлы';

  @override
  String get chatMediaPhotosTab => 'Фотографии';

  @override
  String get chatMediaLinksTab => 'Ссылки';

  @override
  String get chatMediaAudioTab => 'Аудио';

  @override
  String get chatMediaFilesTab => 'Файлы';

  @override
  String get chatMediaEmptyPhotos => 'Фото пока нет.';

  @override
  String get chatMediaEmptyLinks => 'Ссылок пока нет.';

  @override
  String get chatMediaEmptyAudio => 'Звука пока нет.';

  @override
  String get chatMediaEmptyFiles => 'Файлов пока нет.';

  @override
  String get chatFavoritesAction => 'Помечено';

  @override
  String get chatFavoritesTitle => 'Помеченные сообщения';

  @override
  String get chatFavoritesEmpty => 'У вас пока нет помеченных сообщений.';

  @override
  String get chatStarAction => 'Добавить в избранное';

  @override
  String get chatUnstarAction => 'Удалить из избранного';

  @override
  String get chatViewProviderProfileAction => 'Посмотреть профиль провайдера';

  @override
  String get chatViewCustomerProfileAction => 'Посмотреть профиль клиента';

  @override
  String get chatIncomingCall => 'Входящий звонок';

  @override
  String get chatCallStartedVideo => 'Видеозвонок начался';

  @override
  String get chatCallStartedVoice => 'Голосовой вызов начался';

  @override
  String get chatImageLabel => 'Изображение';

  @override
  String get chatAudioLabel => 'Аудио';

  @override
  String get chatFileLabel => 'Файл';

  @override
  String get chatCallEntryLabel => 'Вызов';

  @override
  String get chatNoSession =>
      'Нет активной сессии. Войдите, чтобы получить доступ к чату.';

  @override
  String get chatTitleFallback => 'Чат';

  @override
  String get chatVideoCallAction => 'Видеозвонок';

  @override
  String get chatVoiceCallAction => 'Вызов';

  @override
  String get chatMarkReadAction => 'Отметить как прочитанное';

  @override
  String get chatCallMissingParticipant =>
      'Другой участник еще не назначен этому заказу.';

  @override
  String get chatCallStartError => 'Не удалось начать звонок.';

  @override
  String chatCallMessageVideo(Object url) {
    return 'Видеозвонок: $url';
  }

  @override
  String chatCallMessageVoice(Object url) {
    return 'Звонок: $url';
  }

  @override
  String get profileProviderTitle => 'Профиль провайдера';

  @override
  String get profileCustomerTitle => 'Профиль клиента';

  @override
  String get profileAboutTitle => 'О';

  @override
  String get profileLocationTitle => 'Расположение';

  @override
  String get profileServicesTitle => 'Услуги';

  @override
  String get profilePortfolioTitle => 'Портфель';

  @override
  String get chatOpenFullAction => 'Открыть полный чат';

  @override
  String get chatOpenFullUnavailable =>
      'Другой участник еще не назначен этому заказу.';

  @override
  String get chatReplyAction => 'Отвечать';

  @override
  String get chatCopyAction => 'Копировать';

  @override
  String get chatDeleteAction => 'Удалить';

  @override
  String get storyNewTitle => 'Новая история';

  @override
  String get storyPublishing => 'Публикация истории...';

  @override
  String get storyPublished =>
      'История опубликована! Срок действия истекает через 24 часа.';

  @override
  String storyPublishError(Object error) {
    return 'Ошибка публикации истории: $error.';
  }

  @override
  String get storyCaptionHint => 'Подпись (необязательно)';

  @override
  String get actionPublish => 'Публиковать';

  @override
  String get snackOrderRemoved => 'Заказ удален.';

  @override
  String get snackClientCancelledOrder => 'Клиент отменил заказ.';

  @override
  String get snackOrderCancelled => 'Заказ отменен.';

  @override
  String get snackOrderAcceptedByAnother => 'Другой поставщик принял заказ.';

  @override
  String get snackOrderUpdated => 'Заказ обновлен.';

  @override
  String get snackUserNotAuthenticated => 'Пользователь не аутентифицирован.';

  @override
  String get snackOrderAcceptedCanQuote =>
      'Заказ принят. Вы можете отправить ценовое предложение в деталях заказа.';

  @override
  String get snackOrderAcceptedSuccess => 'Заказ принят.';

  @override
  String snackErrorAcceptingOrder(Object error) {
    return 'Ошибка принятия заказа: $error.';
  }

  @override
  String get dialogTitleOrderAccepted => 'Заказ принят';

  @override
  String get dialogContentQuotePrompt =>
      'Этот заказ является ценовым.\n\nХотите отправить диапазон котировок сейчас?';

  @override
  String get dialogTitleProposeService => 'Предложить услугу';

  @override
  String get dialogContentProposeService =>
      'Установите ценовой диапазон для этой услуги.\nВключите командировки и работу.';

  @override
  String get labelMinValue => 'Минимальное значение';

  @override
  String get labelMaxValue => 'Максимальное значение';

  @override
  String get labelMessageOptional => 'Сообщение клиенту (необязательно)';

  @override
  String hintExampleValue(Object value) {
    return 'Пример: $value';
  }

  @override
  String get hintProposalMessage =>
      'Пример: Включает поездку. Крупногабаритные материалы оплачиваются дополнительно.';

  @override
  String get snackFillValidValues =>
      'Введите допустимые минимальные и максимальные значения.';

  @override
  String get snackMinCannotBeGreaterThanMax =>
      'Минимум не может быть больше максимума.';

  @override
  String get snackProposalSent => 'Предложение отправлено заказчику.';

  @override
  String snackErrorSendingProposal(Object error) {
    return 'Ошибка отправки предложения: $error.';
  }
}
