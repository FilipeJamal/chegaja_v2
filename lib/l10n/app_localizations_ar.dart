// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ChegaJa';

  @override
  String get roleSelectorWelcome => 'مرحبا بكم في تشيغاجا';

  @override
  String get roleSelectorPrompt =>
      'اختر الطريقة التي تريد بها استخدام التطبيق:';

  @override
  String get roleCustomerTitle => 'أنا عميل';

  @override
  String get roleCustomerDescription => 'أريد أن أجد مقدمي الخدمة بالقرب مني.';

  @override
  String get roleProviderTitle => 'أنا مقدم';

  @override
  String get roleProviderDescription => 'أريد تلقي طلبات العملاء وكسب المزيد.';

  @override
  String get invalidSession => 'جلسة غير صالحة.';

  @override
  String get paymentsTitle => 'المدفوعات (شريط)';

  @override
  String get paymentsHeading => 'تلقي المدفوعات عبر الإنترنت';

  @override
  String get paymentsDescription =>
      'لتلقي المدفوعات عبر التطبيق، تحتاج إلى إنشاء حساب Stripe (Connect Express).\nيتم فتح عملية الإعداد في متصفحك وتستغرق من 2 إلى 3 دقائق.';

  @override
  String get paymentsActive => 'المدفوعات عبر الإنترنت نشطة.';

  @override
  String get paymentsInactive =>
      'المدفوعات عبر الإنترنت ليست نشطة بعد. استكمال الإعداد.';

  @override
  String stripeAccountLabel(Object accountId) {
    return 'حساب الشريط: $accountId';
  }

  @override
  String get onboardingOpened =>
      'تم فتح عملية الإعداد. بعد الانتهاء، عد للتحقق من الحالة.';

  @override
  String onboardingStartError(Object error) {
    return 'خطأ في بدء الإعداد: $error';
  }

  @override
  String get manageStripeAccount => 'إدارة حساب الشريط';

  @override
  String get activatePayments => 'تفعيل المدفوعات';

  @override
  String get technicalNotesTitle => 'ملاحظات فنية';

  @override
  String get technicalNotesBody =>
      '• تم تكوين Stripe عبر وظائف السحابة (من جانب الخادم).\n• يتم تطبيق عمولة المنصة تلقائيًا في PaymentIntent.\n• في مرحلة الإنتاج، قم بإضافة خطاف الويب Stripe وقم بتخزين سر خطاف الويب في الوظائف.';

  @override
  String kycTitle(Object status) {
    return 'التحقق من الهوية: $status';
  }

  @override
  String get kycDescription =>
      'أرسل مستندًا (صورة أو PDF). التحقق الكامل يأتي في v2.6.';

  @override
  String get kycSendDocument => 'إرسال الوثيقة';

  @override
  String get kycAddDocument => 'أضف وثيقة';

  @override
  String get kycStatusApproved => 'موافقة';

  @override
  String get kycStatusRejected => 'مرفوض';

  @override
  String get kycStatusInReview => 'قيد المراجعة';

  @override
  String get kycStatusNotStarted => 'لم يبدأ';

  @override
  String get kycFileReadError => 'لا يمكن قراءة الملف.';

  @override
  String get kycFileTooLarge => 'الملف كبير جدًا (بحد أقصى 10 ميجابايت).';

  @override
  String get kycUploading => 'جارٍ تحميل المستند...';

  @override
  String get kycUploadSuccess => 'تم إرسال المستند للمراجعة.';

  @override
  String kycUploadError(Object error) {
    return 'خطأ في إرسال المستند: $error';
  }

  @override
  String get statusCancelledByYou => 'تم الإلغاء بواسطتك';

  @override
  String get statusCancelledByProvider => 'تم الإلغاء بواسطة الموفر';

  @override
  String get statusCancelled => 'تم الإلغاء';

  @override
  String get statusLookingForProvider => 'أبحث عن مزود';

  @override
  String get statusProviderPreparingQuote =>
      'تم العثور على المزود (جارٍ إعداد عرض الأسعار)';

  @override
  String get statusQuoteToDecide => 'لديك اقتباس لتقرر';

  @override
  String get statusProviderFound => 'تم العثور على المزود';

  @override
  String get statusServiceInProgress => 'الخدمة قيد التقدم';

  @override
  String get statusAwaitingValueConfirmation =>
      'في انتظار تأكيد القيمة الخاصة بك';

  @override
  String get statusServiceCompleted => 'اكتملت الخدمة';

  @override
  String valueToConfirm(Object value) {
    return '$value (للتأكيد)';
  }

  @override
  String valueProposed(Object value) {
    return '$value (مقترح)';
  }

  @override
  String valueEstimatedRange(Object min, Object max) {
    return '$min إلى $max (تقديري)';
  }

  @override
  String valueEstimatedFrom(Object min) {
    return 'من $min (تقديري)';
  }

  @override
  String valueEstimatedUpTo(Object max) {
    return 'ما يصل إلى $max (تقديري)';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get priceFixed => 'سعر ثابت';

  @override
  String get priceByQuote => 'بالاقتباس';

  @override
  String get priceToArrange => 'ليتم ترتيبها';

  @override
  String get paymentOnlineBefore => 'الدفع عبر الإنترنت (قبل)';

  @override
  String get paymentOnlineAfter => 'الدفع عبر الإنترنت (بعد)';

  @override
  String get paymentCash => 'الدفع نقدا';

  @override
  String get pendingActionQuoteToReview => 'لديك عرض أسعار/اقتراح للمراجعة.';

  @override
  String get pendingActionValueToConfirm =>
      'أرسل الموفر القيمة النهائية. تحتاج إلى تأكيد.';

  @override
  String get pendingActionProviderPreparingQuote =>
      'تم العثور على المزود. إنهم يعدون الاقتباس.';

  @override
  String get pendingActionProviderChat =>
      'تم العثور على المزود. يمكنك الدردشة معهم.';

  @override
  String get roleLabelCustomer => 'عميل';

  @override
  String get navHome => 'بيت';

  @override
  String get navMyOrders => 'طلباتي';

  @override
  String get navMessages => 'رسائل';

  @override
  String get navProfile => 'حساب تعريفي';

  @override
  String get homeGreeting => 'مرحبًا';

  @override
  String get homeSubtitle => 'ماذا تحتاج اليوم؟';

  @override
  String get homePendingTitle => 'لديك شيء لتقرره';

  @override
  String get homePendingCta => 'انقر هنا لفتح الطلب التالي واتخاذ القرار.';

  @override
  String servicesLoadError(Object error) {
    return 'خطأ في تحميل الخدمات: $error';
  }

  @override
  String get servicesEmptyMessage =>
      'لم يتم تكوين أي خدمات حتى الآن.\\nسترى الفئات هنا قريبًا 🙂';

  @override
  String get availableServicesTitle => 'الخدمات المتاحة';

  @override
  String get serviceTabImmediate => 'مباشر';

  @override
  String get serviceTabScheduled => 'المقرر';

  @override
  String get serviceTabQuote => 'بالاقتباس';

  @override
  String get unreadMessagesTitle => 'لديك رسائل جديدة';

  @override
  String get unreadMessagesCta => 'اضغط هنا لفتح الدردشة.';

  @override
  String get serviceSearchHint => 'خدمة البحث...';

  @override
  String get serviceSearchEmpty => 'لم يتم العثور على خدمات لهذا البحث.';

  @override
  String get serviceModeImmediateDescription =>
      'يأتي المزود اليوم في أسرع وقت ممكن.';

  @override
  String get serviceModeScheduledDescription => 'تحديد يوم ووقت للخدمة.';

  @override
  String get serviceModeQuoteDescription =>
      'طلب عرض أسعار (يرسل المزود نطاقًا أدنى/أقصى).';

  @override
  String get userNotAuthenticatedError => 'خطأ: لم تتم مصادقة المستخدم.';

  @override
  String get myOrdersTitle => 'أوامري';

  @override
  String get ordersTabPending => 'قيد الانتظار';

  @override
  String get ordersTabCompleted => 'مكتمل';

  @override
  String get ordersTabCancelled => 'تم الإلغاء';

  @override
  String ordersLoadError(Object error) {
    return 'خطأ في تحميل الطلبات: $error';
  }

  @override
  String get ordersEmptyPending =>
      'ليس لديك أية طلبات معلقة.\\nقم بإنشاء طلب جديد من الصفحة الرئيسية.';

  @override
  String get ordersEmptyCompleted => 'لم تكتمل الطلبات بعد.';

  @override
  String get ordersEmptyCancelled => 'لم تقم بإلغاء الطلبات بعد.';

  @override
  String get orderQuoteScheduled => 'عرض الأسعار (مجدول)';

  @override
  String get orderQuoteImmediate => 'اقتباس (فوري)';

  @override
  String get orderScheduled => 'الخدمة المجدولة';

  @override
  String get orderImmediate => 'خدمة فورية';

  @override
  String get categoryNotDefined => 'الفئة غير محددة';

  @override
  String orderStateLabel(Object state) {
    return 'الولاية: $state';
  }

  @override
  String orderPriceModelLabel(Object model) {
    return 'نموذج السعر: $model';
  }

  @override
  String orderPaymentLabel(Object payment) {
    return 'الدفع: $payment';
  }

  @override
  String orderValueLabel(Object value) {
    return 'القيمة: $value';
  }

  @override
  String accountTitle(Object role) {
    return 'الحساب ($role)';
  }

  @override
  String get accountNameTitle => 'اسمك';

  @override
  String get accountProfileSubtitle => 'حساب تعريفي';

  @override
  String get accountSettings => 'إعدادات';

  @override
  String get accountHelpSupport => 'المساعدة والدعم';

  @override
  String get navMyJobs => 'وظائفي';

  @override
  String get roleLabelProvider => 'مزود';

  @override
  String get enableLocationToGoOnline => 'تمكين الموقع للاتصال بالإنترنت.';

  @override
  String get nearbyOrdersTitle => 'أوامر بالقرب منك';

  @override
  String get noOrdersAvailableMessage => 'لا توجد طلبات متاحة الآن.';

  @override
  String get configureServiceAreaMessage =>
      'قم بتعيين منطقة الخدمة والخدمات الخاصة بك لبدء تلقي الطلبات.';

  @override
  String get configureAction => 'تكوين';

  @override
  String get offlineEnableOnlineMessage =>
      'أنت غير متصل بالإنترنت. تمكين حالة الاتصال بالإنترنت لتلقي الطلبات.';

  @override
  String get noMatchingOrdersMessage => 'لا توجد طلبات مطابقة لخدماتك ومنطقتك.';

  @override
  String get orderAcceptedMessage => 'تم قبول الطلب.';

  @override
  String get orderAcceptedCanSendQuote =>
      'تم قبول الطلب. يمكنك إرسال الاقتباس في وقت لاحق.';

  @override
  String orderAcceptError(Object error) {
    return 'خطأ في قبول الطلب: $error';
  }

  @override
  String get orderAcceptedDialogTitle => 'تم قبول الطلب';

  @override
  String get orderAcceptedBudgetPrompt =>
      'هذا الطلب حسب عرض الأسعار.\\n\\nهل تريد إرسال نطاق عرض الأسعار الآن؟';

  @override
  String get actionLater => 'لاحقاً';

  @override
  String get actionSendNow => 'أرسل الآن';

  @override
  String get actionCancel => 'يلغي';

  @override
  String get actionSend => 'يرسل';

  @override
  String get actionIgnore => 'يتجاهل';

  @override
  String get actionAccept => 'يقبل';

  @override
  String get actionNo => 'لا';

  @override
  String get actionYesCancel => 'نعم، قم بالإلغاء';

  @override
  String get proposalDialogTitle => 'إرسال الاقتباس';

  @override
  String get proposalDialogDescription =>
      'قم بتعيين نطاق سعري لهذه الخدمة.\\nيشمل السفر والعمالة.';

  @override
  String proposalMinValueLabel(Object currency) {
    return 'الحد الأدنى للقيمة ($currency)';
  }

  @override
  String get proposalMinValueHint => 'مثال: 20';

  @override
  String proposalMaxValueLabel(Object currency) {
    return 'الحد الأقصى للقيمة ($currency)';
  }

  @override
  String get proposalMaxValueHint => 'مثال: 35';

  @override
  String get proposalMessageLabel => 'رسالة إلى العميل (اختياري)';

  @override
  String get proposalMessageHint =>
      'على سبيل المثال: يشمل السفر. المواد الكبيرة اضافية.';

  @override
  String get proposalInvalidValues =>
      'أدخل الحد الأدنى والحد الأقصى للقيم الصالحة.';

  @override
  String get proposalMinGreaterThanMax =>
      'لا يمكن أن يكون الحد الأدنى أكبر من الحد الأقصى.';

  @override
  String get proposalSent => 'تم إرسال الاقتراح إلى العميل.';

  @override
  String proposalSendError(Object error) {
    return 'خطأ في إرسال الاقتراح: $error';
  }

  @override
  String get providerHomeGreeting => 'مرحبا، مقدم';

  @override
  String get providerHomeSubtitle => 'اتصل بالإنترنت لتلقي الطلبات الجديدة.';

  @override
  String get providerStatusOnline => 'أنت متصل';

  @override
  String get providerStatusOffline => 'أنت غير متصل بالإنترنت';

  @override
  String providerSettingsLoadError(Object error) {
    return 'خطأ في تحميل الإعدادات: $error';
  }

  @override
  String providerSettingsSaveError(Object error) {
    return 'خطأ في حفظ الإعدادات: $error';
  }

  @override
  String get serviceAreaTitle => 'منطقة الخدمة';

  @override
  String get serviceAreaHeading => 'أين تريد تلقي الطلبات؟';

  @override
  String get serviceAreaSubtitle =>
      'قم بتعيين الخدمات التي تقدمها والحد الأقصى لنصف القطر حول مدينتك الأساسية.';

  @override
  String get serviceAreaBaseLocation => 'الموقع الأساسي';

  @override
  String get serviceAreaRadius => 'دائرة نصف قطرها الخدمة';

  @override
  String get serviceAreaSaved => 'تم حفظ منطقة الخدمة بنجاح.';

  @override
  String get serviceAreaInfoNote =>
      'في المستقبل، سنستخدم هذه الإعدادات لتصفية الطلبات حسب مدى القرب ونوع الخدمة. في الوقت الحالي، يساعدنا هذا في إعداد المحرك المطابق.';

  @override
  String get availabilityTitle => 'التوفر';

  @override
  String get servicesYouProvideTitle => 'الخدمات التي تقدمها';

  @override
  String get servicesCatalogEmpty =>
      'لم يتم تكوين أي خدمات في الكتالوج حتى الآن.';

  @override
  String get servicesSearchPrompt => 'اكتب للبحث وإضافة الخدمات.';

  @override
  String get servicesSearchNoResults => 'لم يتم العثور على الخدمات.';

  @override
  String get servicesSelectedTitle => 'خدمات مختارة';

  @override
  String get serviceUnnamed => 'خدمة بدون اسم';

  @override
  String get serviceModeQuote => 'يقتبس';

  @override
  String get serviceModeScheduled => 'المقرر';

  @override
  String get serviceModeImmediate => 'مباشر';

  @override
  String get providerServicesSelectAtLeastOne =>
      'حدد خدمة واحدة على الأقل تقدمها.';

  @override
  String get countryLabel => 'دولة';

  @override
  String get cityLabel => 'مدينة';

  @override
  String get stateLabelDistrict => 'يصرف';

  @override
  String get stateLabelProvince => 'مقاطعة';

  @override
  String get stateLabelState => 'ولاية';

  @override
  String get stateLabelRegion => 'منطقة';

  @override
  String get stateLabelCounty => 'مقاطعة';

  @override
  String get stateLabelRegionOrState => 'المنطقة/الولاية';

  @override
  String get searchHint => 'يبحث...';

  @override
  String get searchCountryHint => 'اكتب للبحث في البلدان';

  @override
  String get searchGenericHint => 'اكتب للبحث';

  @override
  String get searchServicesHint => 'خدمات البحث';

  @override
  String get openCountriesListTooltip => 'عرض قائمة البلاد';

  @override
  String get openListTooltip => 'عرض القائمة';

  @override
  String get selectCountryTitle => 'اختر البلد';

  @override
  String get selectCityTitle => 'اختر المدينة';

  @override
  String selectFieldTitle(Object field) {
    return 'حدد $field';
  }

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get supportTitle => 'المساعدة والدعم';

  @override
  String get supportSubtitle => 'هل لديك أسئلة؟ اتصل بنا.';

  @override
  String get myScheduleTitle => 'الجدول الزمني الخاص بي';

  @override
  String get myScheduleSubtitle => 'تحديد ساعات وأيام العطلة';

  @override
  String get languageTitle => 'لغة';

  @override
  String get languageModeManual => 'يدوي';

  @override
  String get languageModeAuto => 'آلي';

  @override
  String languageModeLabel(Object code, Object mode) {
    return '$code - $mode';
  }

  @override
  String get languageAutoSystem => 'تلقائي (نظام)';

  @override
  String get providerCategoriesTitle => 'فئات الخدمة';

  @override
  String get providerCategoriesSubtitle =>
      'نحن نستخدم الفئات لتصفية الطلبات المتوافقة.';

  @override
  String get providerCategoriesEmpty => 'لم يتم تحديد فئة.';

  @override
  String get providerCategoriesSelect => 'حدد الفئات';

  @override
  String get providerCategoriesEdit => 'إضافة أو تحرير الفئات';

  @override
  String get providerCategoriesRequiredMessage =>
      'حدد الفئات الخاصة بك لتلقي الطلبات المطابقة.';

  @override
  String get providerKpiEarningsToday => 'أرباح اليوم (صافي)';

  @override
  String get providerKpiServicesThisMonth => 'الخدمات هذا الشهر';

  @override
  String providerKpiGrossFeeSubtitle(Object gross, Object fee) {
    return 'الإجمالي: $gross - الرسوم: $fee';
  }

  @override
  String get providerHighlightTitle => 'لديك وظيفة لإدارتها';

  @override
  String get providerHighlightCta => 'اضغط هنا لفتح الوظيفة التالية.';

  @override
  String get providerPendingActionAccepted =>
      'لديك وظيفة مقبولة، وعلى استعداد للبدء.';

  @override
  String get providerPendingActionInProgress =>
      'لديك وظيفة في التقدم. ضع علامة \"مكتمل\" عند الانتهاء.';

  @override
  String get providerPendingActionSetFinalValue =>
      'ضبط وإرسال قيمة الخدمة النهائية.';

  @override
  String get providerUnreadMessagesTitle => 'لديك رسائل جديدة من العملاء';

  @override
  String providerUnreadMessagesJob(Object jobTitle) {
    return 'في الوظيفة: $jobTitle';
  }

  @override
  String get providerJobsTitle => 'وظائفي';

  @override
  String get providerJobsTabOpen => 'يفتح';

  @override
  String get providerJobsTabCompleted => 'مكتمل';

  @override
  String get providerJobsTabCancelled => 'تم الإلغاء';

  @override
  String providerJobsLoadError(Object error) {
    return 'خطأ في تحميل المهام: $error';
  }

  @override
  String get providerJobsEmptyOpen =>
      'ليس لديك وظائف مفتوحة حتى الآن.\\nانتقل إلى الصفحة الرئيسية واقبل الطلب.';

  @override
  String get providerJobsEmptyCompleted => 'ليس لديك وظائف مكتملة بعد.';

  @override
  String get providerJobsEmptyCancelled => 'لم تقم بإلغاء الوظائف بعد.';

  @override
  String scheduledForDate(Object date) {
    return 'مجدولة: $date';
  }

  @override
  String get viewDetailsTooltip => 'عرض التفاصيل';

  @override
  String clientPaidValueLabel(Object value) {
    return 'العميل المدفوع: $value';
  }

  @override
  String providerEarningsFeeLabel(Object value, Object fee) {
    return 'تتلقى: $value - الرسوم: $fee';
  }

  @override
  String serviceValueLabel(Object value) {
    return 'قيمة الخدمة: $value';
  }

  @override
  String get cancelJobTitle => 'إلغاء المهمة';

  @override
  String get cancelJobPrompt =>
      'هل أنت متأكد من رغبتك في إلغاء هذه المهمة؟\\nقد يصبح الطلب متاحاً لموفرين آخرين.';

  @override
  String get cancelJobReasonLabel => 'سبب الإلغاء (اختياري):';

  @override
  String get cancelJobReasonFieldLabel => 'سبب';

  @override
  String get cancelJobDetailLabel => 'تفاصيل الإلغاء';

  @override
  String get cancelJobDetailRequired => 'الرجاء إضافة التفاصيل.';

  @override
  String get cancelJobSuccess => 'تم إلغاء الوظيفة.';

  @override
  String cancelJobError(Object error) {
    return 'خطأ في إلغاء المهمة: $error';
  }

  @override
  String get providerAccountProfileTitle => 'عرض ملفي الشخصي';

  @override
  String get providerAccountProfileSubtitle => 'الملف الشخصي للمزود';

  @override
  String get activateOnlinePaymentsSubtitle => 'تمكين المدفوعات عبر الإنترنت';

  @override
  String get statusProviderWaiting => 'طلب جديد';

  @override
  String get statusQuoteWaitingCustomer => 'في انتظار استجابة العملاء';

  @override
  String get statusAcceptedToStart => 'مقبول (جاهز للبدء)';

  @override
  String get statusInProgress => 'في تَقَدم';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get orderDefaultImmediateTitle => 'خدمة عاجلة';

  @override
  String get locationServiceDisabled => 'تم تعطيل خدمة الموقع على الجهاز.';

  @override
  String get locationPermissionDenied =>
      'تم رفض إذن تحديد الموقع.\\nتعذر الحصول على الموقع الحالي.';

  @override
  String get locationPermissionDeniedForever =>
      'تم رفض إذن تحديد الموقع نهائيًا.\\nقم بتمكين الموقع في إعدادات الجهاز.';

  @override
  String locationFetchError(Object error) {
    return 'خطأ في الحصول على الموقع: $error';
  }

  @override
  String get formNotReadyError => 'النموذج ليس جاهزا بعد. حاول ثانية.';

  @override
  String get missingRequiredFieldsError =>
      'الحقول المطلوبة مفقودة. تحقق من الحقول باللون الأحمر.';

  @override
  String get scheduleDateTimeRequiredError => 'اختر تاريخ ووقت الخدمة.';

  @override
  String get scheduleDateTimeFutureError => 'اختر تاريخًا/وقتًا في المستقبل.';

  @override
  String get categoryRequiredError => 'اختر فئة.';

  @override
  String get orderUpdatedSuccess => 'تم تحديث الطلب بنجاح!';

  @override
  String get orderCreatedSuccess => 'تم إنشاء الطلب! أبحث عن مزود...';

  @override
  String orderUpdateError(Object error) {
    return 'حدث خطأ أثناء تحديث الطلب: $error';
  }

  @override
  String orderCreateError(Object error) {
    return 'خطأ في إنشاء الطلب: $error';
  }

  @override
  String get orderTitleExamplePlumbing => 'مثال: تسرب السباكة تحت الحوض';

  @override
  String get orderTitleExampleElectric =>
      'مثال: منفذ لا يعمل في غرفة المعيشة + تركيب ضوء السقف';

  @override
  String get orderTitleExampleCleaning =>
      'مثال: تنظيف كامل لشقة مكونة من غرفتي نوم (مطبخ، تواليت، نوافذ، أرضية).';

  @override
  String get orderTitleHintImmediate => 'اشرح بإيجاز ما يحدث وما تحتاجه.';

  @override
  String get orderTitleHintScheduled =>
      'قل متى تريد الخدمة وتفاصيل الموقع وما يجب القيام به.';

  @override
  String get orderTitleHintQuote =>
      'قم بوصف الخدمة التي ترغب في تلقي مقترحات بشأنها.';

  @override
  String get orderTitleHintDefault => 'قم بوصف الخدمة التي تحتاجها.';

  @override
  String get orderDescriptionExampleCleaning =>
      'مثال: تنظيف كامل لشقة مكونة من غرفتي نوم (مطبخ، تواليت، نوافذ، أرضية).';

  @override
  String get orderDescriptionHintImmediate => 'اشرح بإيجاز ما يحدث وما تحتاجه.';

  @override
  String get orderDescriptionHintScheduled =>
      'قل متى تريد الخدمة وتفاصيل الموقع وما يجب القيام به.';

  @override
  String get orderDescriptionHintQuote =>
      'قم بوصف الخدمة التي تريدها، والميزانية التقريبية (إذا كانت لديك واحدة)، والتفاصيل المهمة.';

  @override
  String get orderDescriptionHintDefault => 'اشرح بمزيد من التفصيل ما تحتاجه.';

  @override
  String get priceModelTitle => 'نموذج السعر';

  @override
  String get priceModelQuoteInfo =>
      'هذه الخدمة عن طريق الاقتباس. سيقترح المزود السعر النهائي.';

  @override
  String get priceTypeLabel => 'نوع السعر';

  @override
  String get paymentTypeLabel => 'نوع الدفع';

  @override
  String get orderHeaderQuoteTitle => 'طلب الاقتباس';

  @override
  String get orderHeaderQuoteSubtitle =>
      'قم بوصف ما تحتاجه ويمكن للموفر إرسال نطاق (الحد الأدنى/الحد الأقصى).';

  @override
  String get orderHeaderImmediateTitle => 'خدمة فورية';

  @override
  String get orderHeaderImmediateSubtitle =>
      'سيتم الاتصال بمزود الخدمة المتاح في أقرب وقت ممكن.';

  @override
  String get orderHeaderScheduledTitle => 'الخدمة المجدولة';

  @override
  String get orderHeaderScheduledSubtitle =>
      'اختر اليوم والوقت الذي سيأتي فيه مقدم الخدمة إليك.';

  @override
  String get orderHeaderDefaultTitle => 'طلب جديد';

  @override
  String get orderHeaderDefaultSubtitle => 'قم بوصف الخدمة التي تحتاجها.';

  @override
  String get orderEditTitle => 'تحرير الطلب';

  @override
  String get orderNewTitle => 'طلب جديد';

  @override
  String get whenServiceNeededLabel => 'متى تحتاج الخدمة؟';

  @override
  String get categoryLabel => 'فئة';

  @override
  String get categoryHint => 'اختر فئة الخدمة';

  @override
  String get orderTitleLabel => 'عنوان الطلب';

  @override
  String get orderTitleRequiredError => 'اكتب عنوانا للطلب.';

  @override
  String get orderDescriptionOptionalLabel => 'الوصف (اختياري)';

  @override
  String get locationApproxLabel => 'الموقع التقريبي';

  @override
  String get locationSelectedLabel => 'تم اختيار الموقع.';

  @override
  String get locationSelectPrompt =>
      'اختيار المكان الذي سيتم تنفيذ الخدمة فيه (تقريبي).';

  @override
  String get locationAddressHint =>
      'الشارع، الرقم، الطابق، المرجع (اختياري، لكنه يساعد كثيرًا)';

  @override
  String get locationGetting => 'جارٍ الحصول على الموقع...';

  @override
  String get locationUseCurrent => 'استخدام الموقع الحالي';

  @override
  String get locationChooseOnMap => 'اختر على الخريطة';

  @override
  String get serviceDateTimeLabel => 'تاريخ ووقت الخدمة';

  @override
  String get serviceDateTimePick => 'اختر اليوم والوقت';

  @override
  String get saveChangesButton => 'حفظ التغييرات';

  @override
  String get submitOrderButton => 'طلب الخدمة';

  @override
  String get mapSelectTitle => 'اختر الموقع على الخريطة';

  @override
  String get mapSelectInstruction =>
      'اسحب الخريطة إلى موقع الخدمة التقريبي، ثم قم بالتأكيد.';

  @override
  String get mapSelectConfirm => 'تأكيد الموقع';

  @override
  String get orderDetailsTitle => 'تفاصيل الطلب';

  @override
  String orderLoadError(Object error) {
    return 'خطأ في تحميل الطلب: $error';
  }

  @override
  String get orderNotFound => 'لم يتم العثور على الطلب.';

  @override
  String get scheduledNoDate => 'مجدولة (لم يتم تحديد تاريخ)';

  @override
  String get orderValueRejectedTitle => 'رفض العميل القيمة المقترحة.';

  @override
  String get orderValueRejectedBody =>
      'قم بالدردشة مع العميل واقترح قيمة جديدة عند التوافق.';

  @override
  String get actionProposeNewValue => 'اقتراح قيمة جديدة';

  @override
  String get noShowReportedTitle => 'تم الإبلاغ عن عدم الحضور';

  @override
  String noShowReportedBy(Object role) {
    return 'تم الإبلاغ بواسطة: $role';
  }

  @override
  String noShowReportedAt(Object date) {
    return 'في: $date';
  }

  @override
  String get noShowTitle => 'عدم الحضور';

  @override
  String get noShowDescription => 'إذا لم يحضر الشخص الآخر، يمكنك الإبلاغ عنه.';

  @override
  String get noShowReportAction => 'الإبلاغ عن عدم الحضور';

  @override
  String get orderInfoTitle => 'معلومات الطلب';

  @override
  String get orderInfoIdLabel => 'معرف الطلب';

  @override
  String get orderInfoCreatedAtLabel => 'تم الإنشاء في';

  @override
  String get orderInfoStatusLabel => 'حالة';

  @override
  String get orderInfoModeLabel => 'وضع';

  @override
  String get orderInfoValueLabel => 'قيمة';

  @override
  String get orderLocationTitle => 'موقع الطلب';

  @override
  String get orderDescriptionTitle => 'وصف الطلب';

  @override
  String get providerMessageTitle => 'رسالة المزود';

  @override
  String get actionEditOrder => 'تحرير الطلب';

  @override
  String get actionCancelOrder => 'إلغاء الطلب';

  @override
  String get cancelOrderTitle => 'إلغاء الطلب';

  @override
  String get orderCancelInProgressWarning =>
      'الخدمة قيد التقدم بالفعل.\nقد يؤدي الإلغاء الآن إلى استرداد جزء من المبلغ.';

  @override
  String get orderCancelConfirmPrompt =>
      'هل أنت متأكد أنك تريد إلغاء هذا الطلب؟';

  @override
  String get orderCancelReasonLabel => 'سبب الإلغاء';

  @override
  String get orderCancelReasonOptionalLabel => 'السبب (اختياري)';

  @override
  String orderCancelledSnack(Object message) {
    return 'تم إلغاء الطلب. $message.';
  }

  @override
  String orderCancelError(Object error) {
    return 'حدث خطأ أثناء إلغاء الطلب: $error';
  }

  @override
  String get noShowReportDialogTitle => 'الإبلاغ عن عدم الحضور';

  @override
  String get noShowReportDialogDescription =>
      'استخدم هذا فقط إذا لم يظهر الشخص الآخر.';

  @override
  String get noShowReasonOptionalLabel => 'السبب (اختياري)';

  @override
  String get actionReport => 'تقرير';

  @override
  String get noShowReportSuccess => 'تم الإبلاغ عن عدم الحضور.';

  @override
  String noShowReportError(Object error) {
    return 'خطأ في الإبلاغ عن عدم الحضور: $error';
  }

  @override
  String get orderFinalValueTitle => 'اقتراح القيمة النهائية الجديدة';

  @override
  String get orderFinalValueLabel => 'قيمة';

  @override
  String get orderFinalValueInvalid => 'أدخل قيمة صالحة.';

  @override
  String get orderFinalValueSent => 'القيمة الجديدة المرسلة إلى العميل.';

  @override
  String orderFinalValueSendError(Object error) {
    return 'خطأ في إرسال قيمة جديدة: $error';
  }

  @override
  String get ratingSentTitle => 'تم إرسال التقييم';

  @override
  String get ratingProviderTitle => 'تصنيف المزود';

  @override
  String get ratingPrompt => 'اترك تقييمًا من 1 إلى 5.';

  @override
  String get ratingCommentLabel => 'تعليق (اختياري)';

  @override
  String get ratingSendAction => 'إرسال التقييم';

  @override
  String get ratingSelectError => 'اختر التقييم.';

  @override
  String get ratingSentSnack => 'تم إرسال التقييم.';

  @override
  String ratingSendError(Object error) {
    return 'حدث خطأ أثناء إرسال التقييم: $error';
  }

  @override
  String get timelineCreated => 'مخلوق';

  @override
  String get timelineAccepted => 'مقبول';

  @override
  String get timelineInProgress => 'في تَقَدم';

  @override
  String get timelineCancelled => 'تم الإلغاء';

  @override
  String get timelineCompleted => 'مكتمل';

  @override
  String get lookingForProviderBanner => 'ما زلنا نبحث عن مزود لهذا الطلب.';

  @override
  String get actionView => 'منظر';

  @override
  String get chatNoMessagesSubtitle => 'لا توجد رسائل حتى الآن';

  @override
  String chatPreviewWithTime(Object preview, Object time) {
    return '$preview • $time';
  }

  @override
  String chatMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ?????',
      one: '????? ?????',
    );
    return '$_temp0';
  }

  @override
  String get actionClose => 'يغلق';

  @override
  String get actionOpen => 'يفتح';

  @override
  String get chatAuthRequired => 'تحتاج إلى المصادقة لإرسال الرسائل.';

  @override
  String chatSendError(Object error) {
    return 'خطأ في إرسال الرسالة: $error';
  }

  @override
  String get todayLabel => 'اليوم';

  @override
  String get yesterdayLabel => 'أمس';

  @override
  String chatLoadError(Object error) {
    return 'حدث خطأ أثناء تحميل الرسائل: $error';
  }

  @override
  String get chatEmptyMessage => 'لا توجد رسائل حتى الآن.\nأرسل أول واحد!';

  @override
  String get chatInputHint => 'أكتب رسالة...';

  @override
  String get chatLoginHint => 'قم بتسجيل الدخول لإرسال الرسائل';

  @override
  String get roleLabelSystem => 'نظام';

  @override
  String get youLabel => 'أنت';

  @override
  String distanceMeters(Object meters) {
    return '$meters م';
  }

  @override
  String distanceKilometers(Object kilometers) {
    return '$kilometers كم';
  }

  @override
  String get etaLessThanMinute => '<1 دقيقة';

  @override
  String etaMinutes(Object minutes) {
    return '$minutes دقيقة';
  }

  @override
  String etaHours(Object hours) {
    return '$hours ح';
  }

  @override
  String etaHoursMinutes(Object hours, Object minutes) {
    return '$hours ح $minutes م';
  }

  @override
  String mapEtaLabel(Object eta, Object distance) {
    return 'الوقت المتوقع $eta - $distance';
  }

  @override
  String get mapOpenAction => 'افتح الخريطة';

  @override
  String get orderMapTitle => 'خريطة النظام';

  @override
  String get orderChatTitle => 'الدردشة حول هذا الطلب';

  @override
  String get messagesTitle => 'رسائل';

  @override
  String get messagesSearchHint => 'بحث في الرسائل';

  @override
  String messagesLoadError(Object error) {
    return 'خطأ في تحميل المحادثات: $error';
  }

  @override
  String get messagesEmpty =>
      'ليس لديك أية محادثات حتى الآن.\nبمجرد الدردشة مع مقدم الخدمة/العميل، سيظهرون هنا.';

  @override
  String get messagesNewConversationTitle => 'محادثة جديدة';

  @override
  String get messagesNewConversationBody =>
      'لبدء محادثة مع موفر خدمة أو عميل، انتقل إلى \"الطلبات\" أو اقبل طلبًا جديدًا.';

  @override
  String get messagesFilterAll => 'الجميع';

  @override
  String get messagesFilterUnread => 'غير مقروءة';

  @override
  String get messagesFilterFavorites => 'المفضلة';

  @override
  String get messagesFilterGroups => 'المجموعات';

  @override
  String messagesFilterEmpty(Object filter) {
    return 'لا شيء في \"$filter\"';
  }

  @override
  String get messagesSearchNoResults => 'لم يتم العثور على أي محادثات.';

  @override
  String get messagesPinConversation => 'تثبيت المحادثة';

  @override
  String get messagesUnpinConversation => 'إزالة تثبيت المحادثة';

  @override
  String get chatPresenceOnline => 'متصل';

  @override
  String chatPresenceLastSeenAt(Object time) {
    return 'شوهد آخر مرة في $time';
  }

  @override
  String chatPresenceLastSeenYesterdayAt(Object time) {
    return 'شوهد آخر مرة بالأمس في $time';
  }

  @override
  String chatPresenceLastSeenOn(Object date, Object time) {
    return 'شوهد آخر مرة في $date في $time';
  }

  @override
  String get chatImageTooLarge => 'الصورة كبيرة جدًا (بحد أقصى 15 ميجابايت).';

  @override
  String chatImageSendError(Object error) {
    return 'خطأ في إرسال الصورة: $error';
  }

  @override
  String get chatFileReadError => 'تعذرت قراءة الملف.';

  @override
  String get chatFileTooLarge => 'الملف كبير جدًا (بحد أقصى 20 ميجابايت).';

  @override
  String chatFileSendError(Object error) {
    return 'خطأ في إرسال الملف: $error';
  }

  @override
  String get chatAudioReadError => 'لا يمكن قراءة الصوت.';

  @override
  String get chatAudioTooLarge => 'الصوت كبير جدًا (بحد أقصى 20 ميجابايت).';

  @override
  String chatAudioSendError(Object error) {
    return 'خطأ في إرسال الصوت: $error';
  }

  @override
  String get chatAttachFile => 'إرسال الملف';

  @override
  String get chatAttachGallery => 'إرسال الصورة (معرض)';

  @override
  String get chatAttachCamera => 'التقاط صورة (الكاميرا)';

  @override
  String get chatAttachAudio => 'إرسال الصوت (ملف)';

  @override
  String get chatAttachAudioSubtitle => 'اختر ملفًا صوتيًا (mp3/m4a/wav/...).';

  @override
  String get chatOpenLink => 'فتح الرابط';

  @override
  String get chatAttachTooltip => 'نعلق';

  @override
  String get chatSendTooltip => 'يرسل';

  @override
  String get chatSearchAction => 'يبحث';

  @override
  String get chatSearchHint => 'بحث في الرسائل';

  @override
  String get chatSearchEmpty => 'اكتب شيئا للبحث.';

  @override
  String get chatSearchNoResults => 'لم يتم العثور على رسائل.';

  @override
  String get chatMediaAction => 'الوسائط والروابط والملفات';

  @override
  String get chatMediaTitle => 'الوسائط والروابط والملفات';

  @override
  String get chatMediaPhotosTab => 'صور';

  @override
  String get chatMediaLinksTab => 'روابط';

  @override
  String get chatMediaAudioTab => 'صوتي';

  @override
  String get chatMediaFilesTab => 'ملفات';

  @override
  String get chatMediaEmptyPhotos => 'لا توجد صور بعد.';

  @override
  String get chatMediaEmptyLinks => 'لا توجد روابط حتى الآن.';

  @override
  String get chatMediaEmptyAudio => 'لا يوجد صوت بعد.';

  @override
  String get chatMediaEmptyFiles => 'لا توجد ملفات حتى الآن.';

  @override
  String get chatFavoritesAction => 'المميزة بنجمة';

  @override
  String get chatFavoritesTitle => 'الرسائل المميزة بنجمة';

  @override
  String get chatFavoritesEmpty => 'ليس لديك رسائل مميزة بنجمة حتى الآن.';

  @override
  String get chatStarAction => 'أضف إلى المفضلة';

  @override
  String get chatUnstarAction => 'إزالة من المفضلة';

  @override
  String get chatViewProviderProfileAction => 'عرض الملف الشخصي للمزود';

  @override
  String get chatViewCustomerProfileAction => 'عرض ملف تعريف العميل';

  @override
  String get chatIncomingCall => 'مكالمة واردة';

  @override
  String get chatCallStartedVideo => 'بدأت مكالمة الفيديو';

  @override
  String get chatCallStartedVoice => 'بدأت المكالمة الصوتية';

  @override
  String get chatImageLabel => 'صورة';

  @override
  String get chatAudioLabel => 'صوتي';

  @override
  String get chatFileLabel => 'ملف';

  @override
  String get chatCallEntryLabel => 'يتصل';

  @override
  String get chatNoSession =>
      'لا توجد جلسة نشطة. قم بتسجيل الدخول للوصول إلى الدردشة.';

  @override
  String get chatTitleFallback => 'محادثة';

  @override
  String get chatVideoCallAction => 'مكالمة فيديو';

  @override
  String get chatVoiceCallAction => 'يتصل';

  @override
  String get chatMarkReadAction => 'وضع علامة كمقروءة';

  @override
  String get chatCallMissingParticipant =>
      'لم يتم تعيين المشارك الآخر لهذا الطلب بعد.';

  @override
  String get chatCallStartError => 'تعذر بدء المكالمة.';

  @override
  String chatCallMessageVideo(Object url) {
    return 'مكالمة فيديو: $url';
  }

  @override
  String chatCallMessageVoice(Object url) {
    return 'الاتصال: $url';
  }

  @override
  String get profileProviderTitle => 'الملف الشخصي للمزود';

  @override
  String get profileCustomerTitle => 'الملف الشخصي للعميل';

  @override
  String get profileAboutTitle => 'عن';

  @override
  String get profileLocationTitle => 'موقع';

  @override
  String get profileServicesTitle => 'خدمات';

  @override
  String get profilePortfolioTitle => 'مَلَفّ';

  @override
  String get chatOpenFullAction => 'فتح الدردشة الكاملة';

  @override
  String get chatOpenFullUnavailable =>
      'لم يتم تعيين المشارك الآخر لهذا الطلب بعد.';

  @override
  String get chatReplyAction => 'رد';

  @override
  String get chatCopyAction => 'ينسخ';

  @override
  String get chatDeleteAction => 'يمسح';

  @override
  String get storyNewTitle => 'قصة جديدة';

  @override
  String get storyPublishing => 'قصة النشر...';

  @override
  String get storyPublished => 'تم نشر القصة! تنتهي صلاحيته خلال 24 ساعة.';

  @override
  String storyPublishError(Object error) {
    return 'حدث خطأ أثناء نشر القصة: $error';
  }

  @override
  String get storyCaptionHint => 'التسمية التوضيحية (اختياري)';

  @override
  String get actionPublish => 'نشر';

  @override
  String get snackOrderRemoved => 'تمت إزالة الطلب.';

  @override
  String get snackClientCancelledOrder => 'ألغى العميل الطلب.';

  @override
  String get snackOrderCancelled => 'تم إلغاء الطلب.';

  @override
  String get snackOrderAcceptedByAnother => 'قبل مزود آخر الطلب.';

  @override
  String get snackOrderUpdated => 'تم تحديث الطلب.';

  @override
  String get snackUserNotAuthenticated => 'لم تتم مصادقة المستخدم.';

  @override
  String get snackOrderAcceptedCanQuote =>
      'تم قبول الطلب. يمكنك إرسال الاقتباس في تفاصيل الطلب.';

  @override
  String get snackOrderAcceptedSuccess => 'تم قبول الطلب.';

  @override
  String snackErrorAcceptingOrder(Object error) {
    return 'خطأ في قبول الطلب: $error';
  }

  @override
  String get dialogTitleOrderAccepted => 'تم قبول الطلب';

  @override
  String get dialogContentQuotePrompt =>
      'هذا الطلب عن طريق الاقتباس.\n\nهل تريد إرسال نطاق الاقتباس الآن؟';

  @override
  String get dialogTitleProposeService => 'اقتراح الخدمة';

  @override
  String get dialogContentProposeService =>
      'حدد النطاق السعري لهذه الخدمة.\nتشمل السفر والعمل.';

  @override
  String get labelMinValue => 'الحد الأدنى للقيمة';

  @override
  String get labelMaxValue => 'القيمة القصوى';

  @override
  String get labelMessageOptional => 'رسالة إلى العميل (اختياري)';

  @override
  String hintExampleValue(Object value) {
    return 'مثال: $value';
  }

  @override
  String get hintProposalMessage =>
      'على سبيل المثال: يشمل السفر. المواد الكبيرة اضافية.';

  @override
  String get snackFillValidValues =>
      'أدخل الحد الأدنى والحد الأقصى للقيم الصالحة.';

  @override
  String get snackMinCannotBeGreaterThanMax =>
      'لا يمكن أن يكون الحد الأدنى أكبر من الحد الأقصى.';

  @override
  String get snackProposalSent => 'تم إرسال الاقتراح إلى العميل.';

  @override
  String snackErrorSendingProposal(Object error) {
    return 'خطأ في إرسال الاقتراح: $error';
  }
}
