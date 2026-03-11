// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'चेगाजा';

  @override
  String get roleSelectorWelcome => 'चेगाजा में आपका स्वागत है';

  @override
  String get roleSelectorPrompt =>
      'चुनें कि आप ऐप का उपयोग कैसे करना चाहते हैं:';

  @override
  String get roleCustomerTitle => 'मैं एक ग्राहक हूं';

  @override
  String get roleCustomerDescription =>
      'मैं अपने आस-पास सेवा प्रदाताओं को ढूंढना चाहता हूं।';

  @override
  String get roleProviderTitle => 'मैं एक प्रदाता हूँ';

  @override
  String get roleProviderDescription =>
      'मैं ग्राहकों के अनुरोध प्राप्त करना और अधिक कमाना चाहता हूं।';

  @override
  String get invalidSession => 'अमान्य सत्र.';

  @override
  String get paymentsTitle => 'भुगतान (पट्टी)';

  @override
  String get paymentsHeading => 'ऑनलाइन भुगतान प्राप्त करें';

  @override
  String get paymentsDescription =>
      'ऐप के माध्यम से भुगतान प्राप्त करने के लिए, आपको एक स्ट्राइप खाता (कनेक्ट एक्सप्रेस) बनाना होगा।\nऑनबोर्डिंग आपके ब्राउज़र में खुलती है और इसमें 2-3 मिनट लगते हैं।';

  @override
  String get paymentsActive => 'ऑनलाइन भुगतान सक्रिय।';

  @override
  String get paymentsInactive =>
      'ऑनलाइन भुगतान अभी सक्रिय नहीं हैं. पूर्ण ऑनबोर्डिंग.';

  @override
  String stripeAccountLabel(Object accountId) {
    return 'स्ट्राइप खाता: $accountId';
  }

  @override
  String get onboardingOpened =>
      'ऑनबोर्डिंग खोली गई. समाप्त करने के बाद, स्थिति की जाँच करने के लिए वापस आएँ।';

  @override
  String onboardingStartError(Object error) {
    return 'ऑनबोर्डिंग प्रारंभ करने में त्रुटि: $error';
  }

  @override
  String get manageStripeAccount => 'स्ट्राइप खाता प्रबंधित करें';

  @override
  String get activatePayments => 'भुगतान सक्रिय करें';

  @override
  String get technicalNotesTitle => 'तकनीकी नोट्स';

  @override
  String get technicalNotesBody =>
      '• स्ट्राइप को क्लाउड फ़ंक्शंस (सर्वर-साइड) के माध्यम से कॉन्फ़िगर किया गया है।\n• पेमेंटइंटेंट में प्लेटफ़ॉर्म कमीशन स्वचालित रूप से लागू होता है।\n• उत्पादन में, स्ट्राइप वेबहुक जोड़ें और वेबहुक रहस्य को फ़ंक्शंस में संग्रहीत करें।';

  @override
  String kycTitle(Object status) {
    return 'पहचान सत्यापन: $status';
  }

  @override
  String get kycDescription =>
      'एक दस्तावेज़ (फोटो या पीडीएफ) भेजें। पूर्ण सत्यापन v2.6 में आता है।';

  @override
  String get kycSendDocument => 'दस्तावेज़ भेजें';

  @override
  String get kycAddDocument => 'दस्तावेज़ जोड़ें';

  @override
  String get kycStatusApproved => 'अनुमत';

  @override
  String get kycStatusRejected => 'अस्वीकार कर दिया';

  @override
  String get kycStatusInReview => 'समीक्षा में';

  @override
  String get kycStatusNotStarted => 'शुरू नहीं';

  @override
  String get kycFileReadError => 'फ़ाइल को पढ़ा नहीं जा सका.';

  @override
  String get kycFileTooLarge => 'फ़ाइल बहुत बड़ी है (अधिकतम 10 एमबी)।';

  @override
  String get kycUploading => 'दस्तावेज़ अपलोड हो रहा है...';

  @override
  String get kycUploadSuccess => 'दस्तावेज़ समीक्षा के लिए भेजा गया.';

  @override
  String kycUploadError(Object error) {
    return 'दस्तावेज़ भेजने में त्रुटि: $error';
  }

  @override
  String get statusCancelledByYou => 'आपके द्वारा रद्द कर दिया गया';

  @override
  String get statusCancelledByProvider => 'प्रदाता द्वारा रद्द कर दिया गया';

  @override
  String get statusCancelled => 'रद्द कर दिया गया';

  @override
  String get statusLookingForProvider => 'प्रदाता की तलाश है';

  @override
  String get statusProviderPreparingQuote =>
      'प्रदाता मिल गया (उद्धरण तैयार किया जा रहा है)';

  @override
  String get statusQuoteToDecide => 'आपके पास निर्णय लेने के लिए एक उद्धरण है';

  @override
  String get statusProviderFound => 'प्रदाता मिल गया';

  @override
  String get statusServiceInProgress => 'सेवा प्रगति पर है';

  @override
  String get statusAwaitingValueConfirmation =>
      'आपके मूल्य की पुष्टि की प्रतीक्षा है';

  @override
  String get statusServiceCompleted => 'सेवा पूर्ण हुई';

  @override
  String valueToConfirm(Object value) {
    return '$value (पुष्टि करने के लिए)';
  }

  @override
  String valueProposed(Object value) {
    return '$value (प्रस्तावित)';
  }

  @override
  String valueEstimatedRange(Object min, Object max) {
    return '$min से $max (अनुमानित)';
  }

  @override
  String valueEstimatedFrom(Object min) {
    return '$min से (अनुमानित)';
  }

  @override
  String valueEstimatedUpTo(Object max) {
    return '$max तक (अनुमानित)';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get priceFixed => 'एक ही दाम';

  @override
  String get priceByQuote => 'उद्धरण से';

  @override
  String get priceToArrange => 'व्यवस्थित किया जाना है';

  @override
  String get paymentOnlineBefore => 'ऑनलाइन भुगतान (पहले)';

  @override
  String get paymentOnlineAfter => 'ऑनलाइन भुगतान (बाद में)';

  @override
  String get paymentCash => 'नकद भुगतान';

  @override
  String get pendingActionQuoteToReview =>
      'आपके पास समीक्षा के लिए एक उद्धरण/प्रस्ताव है।';

  @override
  String get pendingActionValueToConfirm =>
      'प्रदाता ने अंतिम मूल्य भेजा. आपको पुष्टि करनी होगी.';

  @override
  String get pendingActionProviderPreparingQuote =>
      'प्रदाता मिल गया. वे कोटेशन तैयार कर रहे हैं.';

  @override
  String get pendingActionProviderChat =>
      'प्रदाता मिल गया. आप उनसे चैट कर सकते हैं.';

  @override
  String get roleLabelCustomer => 'ग्राहक';

  @override
  String get navHome => 'घर';

  @override
  String get navMyOrders => 'मेरे आदेश';

  @override
  String get navMessages => 'संदेशों';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get homeGreeting => 'नमस्ते';

  @override
  String get homeSubtitle => 'आज तुम्हें क्या चाहिए?';

  @override
  String get homePendingTitle => 'आपको कुछ निर्णय लेना है';

  @override
  String get homePendingCta =>
      'अगला ऑर्डर खोलने और निर्णय लेने के लिए यहां टैप करें।';

  @override
  String servicesLoadError(Object error) {
    return 'सेवाएँ लोड करने में त्रुटि: $error';
  }

  @override
  String get servicesEmptyMessage =>
      'अभी तक कोई सेवा कॉन्फ़िगर नहीं की गई है।\\nआप जल्द ही यहां श्रेणियां देखेंगे 🙂';

  @override
  String get availableServicesTitle => 'उपलब्ध सेवाएँ';

  @override
  String get serviceTabImmediate => 'तुरंत';

  @override
  String get serviceTabScheduled => 'अनुसूचित';

  @override
  String get serviceTabQuote => 'उद्धरण से';

  @override
  String get unreadMessagesTitle => 'आपके पास नए संदेश हैं';

  @override
  String get unreadMessagesCta => 'चैट खोलने के लिए यहां टैप करें.';

  @override
  String get serviceSearchHint => 'खोज सेवा...';

  @override
  String get serviceSearchEmpty => 'इस खोज के लिए कोई सेवाएँ नहीं मिलीं.';

  @override
  String get serviceModeImmediateDescription => 'एक प्रदाता आज यथाशीघ्र आये।';

  @override
  String get serviceModeScheduledDescription =>
      'सेवा के लिए एक दिन और समय निर्धारित करें।';

  @override
  String get serviceModeQuoteDescription =>
      'कोटेशन का अनुरोध करें (प्रदाता न्यूनतम/अधिकतम सीमा भेजता है)।';

  @override
  String get userNotAuthenticatedError =>
      'त्रुटि: उपयोगकर्ता प्रमाणित नहीं है.';

  @override
  String get myOrdersTitle => 'मेरे आदेश';

  @override
  String get ordersTabPending => 'लंबित';

  @override
  String get ordersTabCompleted => 'पुरा होना।';

  @override
  String get ordersTabCancelled => 'रद्द कर दिया गया';

  @override
  String ordersLoadError(Object error) {
    return 'ऑर्डर लोड करने में त्रुटि: $error';
  }

  @override
  String get ordersEmptyPending =>
      'आपके पास कोई लंबित ऑर्डर नहीं है।\\nहोम से एक नया ऑर्डर बनाएं।';

  @override
  String get ordersEmptyCompleted => 'आपने अभी तक ऑर्डर पूरे नहीं किए हैं.';

  @override
  String get ordersEmptyCancelled => 'आपने अभी तक ऑर्डर रद्द नहीं किया है.';

  @override
  String get orderQuoteScheduled => 'उद्धरण (अनुसूचित)';

  @override
  String get orderQuoteImmediate => 'उद्धरण (तत्काल)';

  @override
  String get orderScheduled => 'अनुसूचित सेवा';

  @override
  String get orderImmediate => 'तत्काल सेवा';

  @override
  String get categoryNotDefined => 'श्रेणी परिभाषित नहीं';

  @override
  String orderStateLabel(Object state) {
    return 'राज्य: $state';
  }

  @override
  String orderPriceModelLabel(Object model) {
    return 'मूल्य मॉडल: $model';
  }

  @override
  String orderPaymentLabel(Object payment) {
    return 'भुगतान: $payment';
  }

  @override
  String orderValueLabel(Object value) {
    return 'मान: $value';
  }

  @override
  String accountTitle(Object role) {
    return 'खाता ($role)';
  }

  @override
  String get accountNameTitle => 'आपका नाम';

  @override
  String get accountProfileSubtitle => 'प्रोफ़ाइल';

  @override
  String get accountSettings => 'सेटिंग्स';

  @override
  String get accountHelpSupport => 'सहायता और समर्थन';

  @override
  String get navMyJobs => 'मेरे काम';

  @override
  String get roleLabelProvider => 'प्रदाता';

  @override
  String get enableLocationToGoOnline => 'ऑनलाइन जाने के लिए स्थान सक्षम करें.';

  @override
  String get nearbyOrdersTitle => 'आपके पास ऑर्डर';

  @override
  String get noOrdersAvailableMessage => 'अभी कोई ऑर्डर उपलब्ध नहीं है.';

  @override
  String get configureServiceAreaMessage =>
      'ऑर्डर प्राप्त करना शुरू करने के लिए अपना सेवा क्षेत्र और सेवाएँ निर्धारित करें।';

  @override
  String get configureAction => 'कॉन्फ़िगर';

  @override
  String get offlineEnableOnlineMessage =>
      'आप ऑफ़लाइन हैं. ऑर्डर प्राप्त करने के लिए ऑनलाइन स्थिति सक्षम करें।';

  @override
  String get noMatchingOrdersMessage =>
      'आपकी सेवाओं और क्षेत्र के लिए कोई मिलान आदेश नहीं।';

  @override
  String get orderAcceptedMessage => 'आदेश स्वीकार किया गया.';

  @override
  String get orderAcceptedCanSendQuote =>
      'आदेश स्वीकार किया गया. आप उद्धरण बाद में भेज सकते हैं.';

  @override
  String orderAcceptError(Object error) {
    return 'आदेश स्वीकार करने में त्रुटि: $error';
  }

  @override
  String get orderAcceptedDialogTitle => 'आदेश स्वीकार कर लिया गया';

  @override
  String get orderAcceptedBudgetPrompt =>
      'यह ऑर्डर कोटेशन द्वारा है.\\n\\nक्या आप कोटेशन रेंज अभी भेजना चाहते हैं?';

  @override
  String get actionLater => 'बाद में';

  @override
  String get actionSendNow => 'अब भेजें';

  @override
  String get actionCancel => 'रद्द करना';

  @override
  String get actionSend => 'भेजना';

  @override
  String get actionIgnore => 'अनदेखा करना';

  @override
  String get actionAccept => 'स्वीकार करना';

  @override
  String get actionNo => 'नहीं';

  @override
  String get actionYesCancel => 'हाँ, रद्द करें';

  @override
  String get proposalDialogTitle => 'एक उद्धरण भेजें';

  @override
  String get proposalDialogDescription =>
      'इस सेवा के लिए एक मूल्य सीमा निर्धारित करें।\\nयात्रा और श्रम शामिल करें।';

  @override
  String proposalMinValueLabel(Object currency) {
    return 'न्यूनतम मान ($currency)';
  }

  @override
  String get proposalMinValueHint => 'उदाहरण: 20';

  @override
  String proposalMaxValueLabel(Object currency) {
    return 'अधिकतम मान ($currency)';
  }

  @override
  String get proposalMaxValueHint => 'उदाहरण: 35';

  @override
  String get proposalMessageLabel => 'ग्राहक को संदेश (वैकल्पिक)';

  @override
  String get proposalMessageHint =>
      'उदाहरण: यात्रा शामिल है। बड़ी सामग्री अतिरिक्त हैं.';

  @override
  String get proposalInvalidValues => 'मान्य न्यूनतम और अधिकतम मान दर्ज करें.';

  @override
  String get proposalMinGreaterThanMax =>
      'न्यूनतम अधिकतम से अधिक नहीं हो सकता.';

  @override
  String get proposalSent => 'ग्राहक को प्रस्ताव भेजा गया.';

  @override
  String proposalSendError(Object error) {
    return 'प्रस्ताव भेजने में त्रुटि: $error';
  }

  @override
  String get providerHomeGreeting => 'नमस्ते, प्रदाता';

  @override
  String get providerHomeSubtitle =>
      'नए ऑर्डर प्राप्त करने के लिए ऑनलाइन जाएँ।';

  @override
  String get providerStatusOnline => 'आप ऑनलाइन हैं';

  @override
  String get providerStatusOffline => 'आप ऑफ़लाइन हैं';

  @override
  String providerSettingsLoadError(Object error) {
    return 'सेटिंग लोड करने में त्रुटि: $error';
  }

  @override
  String providerSettingsSaveError(Object error) {
    return 'सेटिंग सहेजने में त्रुटि: $error';
  }

  @override
  String get serviceAreaTitle => 'सेवा क्षेत्र';

  @override
  String get serviceAreaHeading => 'आप कहां से ऑर्डर प्राप्त करना चाहते हैं?';

  @override
  String get serviceAreaSubtitle =>
      'आपके द्वारा प्रदान की जाने वाली सेवाएँ और अपने आधार शहर के आसपास का अधिकतम दायरा निर्धारित करें।';

  @override
  String get serviceAreaBaseLocation => 'आधार स्थान';

  @override
  String get serviceAreaRadius => 'सेवा त्रिज्या';

  @override
  String get serviceAreaSaved => 'सेवा क्षेत्र सफलतापूर्वक सहेजा गया.';

  @override
  String get serviceAreaInfoNote =>
      'भविष्य में हम निकटता और सेवा प्रकार के आधार पर ऑर्डर फ़िल्टर करने के लिए इन सेटिंग्स का उपयोग करेंगे। अभी के लिए, इससे हमें मिलान इंजन तैयार करने में मदद मिलती है।';

  @override
  String get availabilityTitle => 'उपलब्धता';

  @override
  String get servicesYouProvideTitle =>
      'आपके द्वारा प्रदान की जाने वाली सेवाएँ';

  @override
  String get servicesCatalogEmpty =>
      'कैटलॉग में अभी तक कोई सेवा कॉन्फ़िगर नहीं की गई है.';

  @override
  String get servicesSearchPrompt => 'खोजने और सेवाएँ जोड़ने के लिए टाइप करें।';

  @override
  String get servicesSearchNoResults => 'कोई सेवा नहीं मिली.';

  @override
  String get servicesSelectedTitle => 'चयनित सेवाएँ';

  @override
  String get serviceUnnamed => 'अनाम सेवा';

  @override
  String get serviceModeQuote => 'उद्धरण';

  @override
  String get serviceModeScheduled => 'अनुसूचित';

  @override
  String get serviceModeImmediate => 'तुरंत';

  @override
  String get providerServicesSelectAtLeastOne =>
      'आपके द्वारा प्रदान की जाने वाली कम से कम एक सेवा का चयन करें।';

  @override
  String get countryLabel => 'देश';

  @override
  String get cityLabel => 'शहर';

  @override
  String get stateLabelDistrict => 'ज़िला';

  @override
  String get stateLabelProvince => 'प्रांत';

  @override
  String get stateLabelState => 'राज्य';

  @override
  String get stateLabelRegion => 'क्षेत्र';

  @override
  String get stateLabelCounty => 'काउंटी';

  @override
  String get stateLabelRegionOrState => 'क्षेत्र/राज्य';

  @override
  String get searchHint => 'खोज...';

  @override
  String get searchCountryHint => 'देश खोजने के लिए टाइप करें';

  @override
  String get searchGenericHint => 'खोजने के लिए टाइप करें';

  @override
  String get searchServicesHint => 'सेवाएँ खोजें';

  @override
  String get openCountriesListTooltip => 'देश सूची देखें';

  @override
  String get openListTooltip => 'सूची देखें';

  @override
  String get selectCountryTitle => 'देश चुनें';

  @override
  String get selectCityTitle => 'शहर चुनें';

  @override
  String selectFieldTitle(Object field) {
    return '$field चुनें';
  }

  @override
  String get saveChanges => 'परिवर्तनों को सुरक्षित करें';

  @override
  String get supportTitle => 'सहायता एवं समर्थन';

  @override
  String get supportSubtitle => 'प्रश्न हैं? हमसे संपर्क करें.';

  @override
  String get myScheduleTitle => 'मेरी अनुसूची';

  @override
  String get myScheduleSubtitle => 'छुट्टी के घंटे और दिन निर्धारित करें';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageModeManual => 'नियमावली';

  @override
  String get languageModeAuto => 'ऑटो';

  @override
  String languageModeLabel(Object code, Object mode) {
    return '$code - $mode';
  }

  @override
  String get languageAutoSystem => 'ऑटो (सिस्टम)';

  @override
  String get providerCategoriesTitle => 'सेवा श्रेणियाँ';

  @override
  String get providerCategoriesSubtitle =>
      'हम संगत ऑर्डर फ़िल्टर करने के लिए श्रेणियों का उपयोग करते हैं।';

  @override
  String get providerCategoriesEmpty => 'कोई श्रेणी चयनित नहीं.';

  @override
  String get providerCategoriesSelect => 'श्रेणियां चुनें';

  @override
  String get providerCategoriesEdit => 'श्रेणियां जोड़ें या संपादित करें';

  @override
  String get providerCategoriesRequiredMessage =>
      'मिलान आदेश प्राप्त करने के लिए अपनी श्रेणियां चुनें।';

  @override
  String get providerKpiEarningsToday => 'आज की कमाई (शुद्ध)';

  @override
  String get providerKpiServicesThisMonth => 'इस महीने सेवाएं';

  @override
  String providerKpiGrossFeeSubtitle(Object gross, Object fee) {
    return 'सकल: $gross - शुल्क: $fee';
  }

  @override
  String get providerHighlightTitle => 'आपके पास प्रबंधन करने का काम है';

  @override
  String get providerHighlightCta => 'अगला कार्य खोलने के लिए यहां टैप करें।';

  @override
  String get providerPendingActionAccepted =>
      'आपके पास एक स्वीकृत नौकरी है, जो शुरू करने के लिए तैयार है।';

  @override
  String get providerPendingActionInProgress =>
      'आपका कोई कार्य प्रगति पर है. जब आप समाप्त कर लें तो इसे पूर्ण चिह्नित करें।';

  @override
  String get providerPendingActionSetFinalValue =>
      'अंतिम सेवा मूल्य सेट करें और भेजें।';

  @override
  String get providerUnreadMessagesTitle => 'आपके पास ग्राहकों से नए संदेश हैं';

  @override
  String providerUnreadMessagesJob(Object jobTitle) {
    return 'नौकरी में: $jobTitle';
  }

  @override
  String get providerJobsTitle => 'मेरे काम';

  @override
  String get providerJobsTabOpen => 'खुला';

  @override
  String get providerJobsTabCompleted => 'पुरा होना।';

  @override
  String get providerJobsTabCancelled => 'रद्द कर दिया गया';

  @override
  String providerJobsLoadError(Object error) {
    return 'कार्य लोड करने में त्रुटि: $error';
  }

  @override
  String get providerJobsEmptyOpen =>
      'आपके पास अभी तक खुली नौकरियां नहीं हैं।\\nहोम पर जाएं और ऑर्डर स्वीकार करें।';

  @override
  String get providerJobsEmptyCompleted =>
      'आपने अभी तक कार्य पूरे नहीं किए हैं.';

  @override
  String get providerJobsEmptyCancelled =>
      'आपने अभी तक नौकरियाँ रद्द नहीं की हैं.';

  @override
  String scheduledForDate(Object date) {
    return 'शेड्यूल: $date';
  }

  @override
  String get viewDetailsTooltip => 'विवरण देखें';

  @override
  String clientPaidValueLabel(Object value) {
    return 'ग्राहक को भुगतान: $value';
  }

  @override
  String providerEarningsFeeLabel(Object value, Object fee) {
    return 'आपको प्राप्त होता है: $value - शुल्क: $fee';
  }

  @override
  String serviceValueLabel(Object value) {
    return 'सेवा मूल्य: $value';
  }

  @override
  String get cancelJobTitle => 'नौकरी रद्द करें';

  @override
  String get cancelJobPrompt =>
      'क्या आप वाकई यह कार्य रद्द करना चाहते हैं?\\nआदेश अन्य प्रदाताओं के लिए उपलब्ध हो सकता है।';

  @override
  String get cancelJobReasonLabel => 'रद्द करने का कारण (वैकल्पिक):';

  @override
  String get cancelJobReasonFieldLabel => 'कारण';

  @override
  String get cancelJobDetailLabel => 'रद्दीकरण विवरण';

  @override
  String get cancelJobDetailRequired => 'कृपया विवरण जोड़ें.';

  @override
  String get cancelJobSuccess => 'नौकरी रद्द कर दी गई.';

  @override
  String cancelJobError(Object error) {
    return 'कार्य रद्द करने में त्रुटि: $error';
  }

  @override
  String get providerAccountProfileTitle => 'मेरी प्रोफ़ाइल देखें';

  @override
  String get providerAccountProfileSubtitle => 'प्रदाता प्रोफ़ाइल';

  @override
  String get activateOnlinePaymentsSubtitle => 'ऑनलाइन भुगतान सक्षम करें';

  @override
  String get statusProviderWaiting => 'नया अनुरोध';

  @override
  String get statusQuoteWaitingCustomer => 'ग्राहक की प्रतिक्रिया का इंतजार है';

  @override
  String get statusAcceptedToStart => 'स्वीकृत (शुरू करने के लिए तैयार)';

  @override
  String get statusInProgress => 'प्रगति पर है';

  @override
  String get statusCompleted => 'पुरा होना।';

  @override
  String get orderDefaultImmediateTitle => 'तत्काल सेवा';

  @override
  String get locationServiceDisabled => 'डिवाइस पर स्थान सेवा अक्षम है.';

  @override
  String get locationPermissionDenied =>
      'स्थान की अनुमति अस्वीकृत.\\nवर्तमान स्थान प्राप्त नहीं किया जा सका.';

  @override
  String get locationPermissionDeniedForever =>
      'स्थान की अनुमति स्थायी रूप से अस्वीकृत.\\nडिवाइस सेटिंग में स्थान सक्षम करें.';

  @override
  String locationFetchError(Object error) {
    return 'स्थान प्राप्त करने में त्रुटि: $error';
  }

  @override
  String get formNotReadyError => 'फॉर्म अभी तैयार नहीं है. पुनः प्रयास करें।';

  @override
  String get missingRequiredFieldsError =>
      'आवश्यक फ़ील्ड अनुपलब्ध हैं. फ़ील्ड को लाल रंग से जांचें.';

  @override
  String get scheduleDateTimeRequiredError => 'सेवा दिनांक और समय चुनें.';

  @override
  String get scheduleDateTimeFutureError => 'भविष्य की तारीख/समय चुनें.';

  @override
  String get categoryRequiredError => 'एक श्रेणी चुनें.';

  @override
  String get orderUpdatedSuccess => 'ऑर्डर सफलतापूर्वक अपडेट किया गया!';

  @override
  String get orderCreatedSuccess => 'ऑर्डर बनाया गया! एक प्रदाता की तलाश है...';

  @override
  String orderUpdateError(Object error) {
    return 'ऑर्डर अपडेट करने में त्रुटि: $error';
  }

  @override
  String orderCreateError(Object error) {
    return 'ऑर्डर बनाने में त्रुटि: $error';
  }

  @override
  String get orderTitleExamplePlumbing =>
      'उदाहरण: सिंक के नीचे पाइपलाइन का रिसाव';

  @override
  String get orderTitleExampleElectric =>
      'उदाहरण: लिविंग रूम में आउटलेट काम नहीं करता + सीलिंग लाइट स्थापित करें';

  @override
  String get orderTitleExampleCleaning =>
      'उदाहरण: 2-बेडरूम अपार्टमेंट (रसोईघर, शौचालय, खिड़कियां, फर्श) की पूरी सफाई।';

  @override
  String get orderTitleHintImmediate =>
      'संक्षेप में बताएं कि क्या हो रहा है और आपको क्या चाहिए।';

  @override
  String get orderTitleHintScheduled =>
      'बताएं कि आपको कब सेवा चाहिए, स्थान का विवरण और क्या करने की आवश्यकता है।';

  @override
  String get orderTitleHintQuote =>
      'उस सेवा का वर्णन करें जिसके लिए आप प्रस्ताव प्राप्त करना चाहते हैं।';

  @override
  String get orderTitleHintDefault =>
      'आपको जिस सेवा की आवश्यकता है उसका वर्णन करें.';

  @override
  String get orderDescriptionExampleCleaning =>
      'उदाहरण: 2-बेडरूम अपार्टमेंट (रसोईघर, शौचालय, खिड़कियां, फर्श) की पूरी सफाई।';

  @override
  String get orderDescriptionHintImmediate =>
      'संक्षेप में बताएं कि क्या हो रहा है और आपको क्या चाहिए।';

  @override
  String get orderDescriptionHintScheduled =>
      'बताएं कि आपको कब सेवा चाहिए, स्थान का विवरण और क्या करने की आवश्यकता है।';

  @override
  String get orderDescriptionHintQuote =>
      'आप जो सेवा चाहते हैं, उसका अनुमानित बजट (यदि आपके पास है), और महत्वपूर्ण विवरण बताएं।';

  @override
  String get orderDescriptionHintDefault =>
      'आपको जो चाहिए उसे थोड़ा और विस्तार से बताएं।';

  @override
  String get priceModelTitle => 'मूल्य मॉडल';

  @override
  String get priceModelQuoteInfo =>
      'यह सेवा उद्धरण द्वारा है. प्रदाता अंतिम कीमत प्रस्तावित करेगा.';

  @override
  String get priceTypeLabel => 'मूल्य प्रकार';

  @override
  String get paymentTypeLabel => 'भुगतान प्रकार';

  @override
  String get orderHeaderQuoteTitle => 'बोली का अनुरोध';

  @override
  String get orderHeaderQuoteSubtitle =>
      'बताएं कि आपको क्या चाहिए और प्रदाता एक सीमा (न्यूनतम/अधिकतम) भेज सकता है।';

  @override
  String get orderHeaderImmediateTitle => 'तत्काल सेवा';

  @override
  String get orderHeaderImmediateSubtitle =>
      'यथाशीघ्र उपलब्ध प्रदाता को बुलाया जाएगा।';

  @override
  String get orderHeaderScheduledTitle => 'अनुसूचित सेवा';

  @override
  String get orderHeaderScheduledSubtitle =>
      'प्रदाता के आपके पास आने का दिन और समय चुनें।';

  @override
  String get orderHeaderDefaultTitle => 'नए आदेश';

  @override
  String get orderHeaderDefaultSubtitle =>
      'आपको जिस सेवा की आवश्यकता है उसका वर्णन करें.';

  @override
  String get orderEditTitle => 'आदेश संपादित करें';

  @override
  String get orderNewTitle => 'नए आदेश';

  @override
  String get whenServiceNeededLabel => 'आपको सेवा की आवश्यकता कब होगी?';

  @override
  String get categoryLabel => 'वर्ग';

  @override
  String get categoryHint => 'सेवा श्रेणी चुनें';

  @override
  String get orderTitleLabel => 'आदेश का शीर्षक';

  @override
  String get orderTitleRequiredError => 'ऑर्डर के लिए एक शीर्षक लिखें.';

  @override
  String get orderDescriptionOptionalLabel => 'विवरण (वैकल्पिक)';

  @override
  String get locationApproxLabel => 'अनुमानित स्थान';

  @override
  String get locationSelectedLabel => 'स्थान चयनित.';

  @override
  String get locationSelectPrompt =>
      'चुनें कि सेवा कहाँ निष्पादित की जाएगी (अनुमानित)।';

  @override
  String get locationAddressHint =>
      'सड़क, नंबर, फर्श, संदर्भ (वैकल्पिक, लेकिन बहुत मदद करता है)';

  @override
  String get locationGetting => 'स्थान प्राप्त हो रहा है...';

  @override
  String get locationUseCurrent => 'वर्तमान स्थान का उपयोग करें';

  @override
  String get locationChooseOnMap => 'मानचित्र पर चुनें';

  @override
  String get serviceDateTimeLabel => 'सेवा दिनांक और समय';

  @override
  String get serviceDateTimePick => 'दिन और समय चुनें';

  @override
  String get saveChangesButton => 'परिवर्तनों को सुरक्षित करें';

  @override
  String get submitOrderButton => 'सेवा का अनुरोध करें';

  @override
  String get mapSelectTitle => 'मानचित्र पर स्थान चुनें';

  @override
  String get mapSelectInstruction =>
      'मानचित्र को अनुमानित सेवा स्थान पर खींचें, फिर पुष्टि करें।';

  @override
  String get mapSelectConfirm => 'स्थान की पुष्टि करें';

  @override
  String get orderDetailsTitle => 'ऑर्डर का विवरण';

  @override
  String orderLoadError(Object error) {
    return 'ऑर्डर लोड करने में त्रुटि: $error';
  }

  @override
  String get orderNotFound => 'ऑर्डर नहीं मिला.';

  @override
  String get scheduledNoDate => 'निर्धारित (कोई तिथि निर्धारित नहीं)';

  @override
  String get orderValueRejectedTitle =>
      'ग्राहक ने प्रस्तावित मूल्य को अस्वीकार कर दिया.';

  @override
  String get orderValueRejectedBody =>
      'ग्राहक के साथ चैट करें और संरेखित होने पर एक नया मान प्रस्तावित करें।';

  @override
  String get actionProposeNewValue => 'नया मान प्रस्तावित करें';

  @override
  String get noShowReportedTitle => 'नो-शो की सूचना दी गई';

  @override
  String noShowReportedBy(Object role) {
    return 'रिपोर्टकर्ता: $role';
  }

  @override
  String noShowReportedAt(Object date) {
    return 'यहां: $date';
  }

  @override
  String get noShowTitle => 'कोई शो नहीं';

  @override
  String get noShowDescription =>
      'यदि दूसरा व्यक्ति नहीं आया, तो आप इसकी रिपोर्ट कर सकते हैं।';

  @override
  String get noShowReportAction => 'रिपोर्ट नो-शो';

  @override
  String get orderInfoTitle => 'आदेश की जानकारी';

  @override
  String get orderInfoIdLabel => 'आदेश कामतत्व';

  @override
  String get orderInfoCreatedAtLabel => 'पर बनाया गया';

  @override
  String get orderInfoStatusLabel => 'स्थिति';

  @override
  String get orderInfoModeLabel => 'तरीका';

  @override
  String get orderInfoValueLabel => 'कीमत';

  @override
  String get orderLocationTitle => 'ऑर्डर स्थान';

  @override
  String get orderDescriptionTitle => 'आदेश विवरण';

  @override
  String get providerMessageTitle => 'प्रदाता संदेश';

  @override
  String get actionEditOrder => 'आदेश संपादित करें';

  @override
  String get actionCancelOrder => 'आदेश रद्द';

  @override
  String get cancelOrderTitle => 'आदेश रद्द';

  @override
  String get orderCancelInProgressWarning =>
      'सेवा पहले से ही प्रगति पर है.\nअभी रद्द करने पर आंशिक धनवापसी हो सकती है।';

  @override
  String get orderCancelConfirmPrompt =>
      'क्या आप वाकई यह ऑर्डर रद्द करना चाहते हैं?';

  @override
  String get orderCancelReasonLabel => 'रद्दीकरण का कारण';

  @override
  String get orderCancelReasonOptionalLabel => 'कारण (वैकल्पिक)';

  @override
  String orderCancelledSnack(Object message) {
    return 'आदेश रद्द किया गया। $message.';
  }

  @override
  String orderCancelError(Object error) {
    return 'ऑर्डर रद्द करने में त्रुटि: $error';
  }

  @override
  String get noShowReportDialogTitle => 'रिपोर्ट नो-शो';

  @override
  String get noShowReportDialogDescription =>
      'इसका उपयोग केवल तभी करें जब दूसरा व्यक्ति उपस्थित न हो।';

  @override
  String get noShowReasonOptionalLabel => 'कारण (वैकल्पिक)';

  @override
  String get actionReport => 'प्रतिवेदन';

  @override
  String get noShowReportSuccess => 'नो-शो की सूचना दी गई।';

  @override
  String noShowReportError(Object error) {
    return 'नो-शो रिपोर्ट करने में त्रुटि: $error';
  }

  @override
  String get orderFinalValueTitle => 'नया अंतिम मान प्रस्तावित करें';

  @override
  String get orderFinalValueLabel => 'कीमत';

  @override
  String get orderFinalValueInvalid => 'एक मान्य मान दर्ज करें.';

  @override
  String get orderFinalValueSent => 'ग्राहक को नया मूल्य भेजा गया.';

  @override
  String orderFinalValueSendError(Object error) {
    return 'नया मान भेजने में त्रुटि: $error';
  }

  @override
  String get ratingSentTitle => 'रेटिंग भेजी गई';

  @override
  String get ratingProviderTitle => 'प्रदाता रेटिंग';

  @override
  String get ratingPrompt => '1 से 5 तक रेटिंग छोड़ें।';

  @override
  String get ratingCommentLabel => 'टिप्पणी (वैकल्पिक)';

  @override
  String get ratingSendAction => 'रेटिंग भेजें';

  @override
  String get ratingSelectError => 'एक रेटिंग चुनें.';

  @override
  String get ratingSentSnack => 'रेटिंग भेजी गई.';

  @override
  String ratingSendError(Object error) {
    return 'रेटिंग भेजने में त्रुटि: $error';
  }

  @override
  String get timelineCreated => 'बनाया था';

  @override
  String get timelineAccepted => 'स्वीकृत';

  @override
  String get timelineInProgress => 'प्रगति पर है';

  @override
  String get timelineCancelled => 'रद्द कर दिया गया';

  @override
  String get timelineCompleted => 'पुरा होना।';

  @override
  String get lookingForProviderBanner =>
      'हम अभी भी इस ऑर्डर के लिए प्रदाता की तलाश कर रहे हैं।';

  @override
  String get actionView => 'देखना';

  @override
  String get chatNoMessagesSubtitle => 'अभी तक कोई संदेश नहीं';

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
      one: '1 ?????',
    );
    return '$_temp0';
  }

  @override
  String get actionClose => 'बंद करना';

  @override
  String get actionOpen => 'खुला';

  @override
  String get chatAuthRequired =>
      'संदेश भेजने के लिए आपको प्रमाणित होना आवश्यक है.';

  @override
  String chatSendError(Object error) {
    return 'संदेश भेजने में त्रुटि: $error';
  }

  @override
  String get todayLabel => 'आज';

  @override
  String get yesterdayLabel => 'कल';

  @override
  String chatLoadError(Object error) {
    return 'संदेश लोड करने में त्रुटि: $error';
  }

  @override
  String get chatEmptyMessage => 'अभी तक कोई संदेश नहीं.\nसबसे पहले भेजें!';

  @override
  String get chatInputHint => 'एक सन्देश लिखिए...';

  @override
  String get chatLoginHint => 'संदेश भेजने के लिए साइन इन करें';

  @override
  String get roleLabelSystem => 'प्रणाली';

  @override
  String get youLabel => 'आप';

  @override
  String distanceMeters(Object meters) {
    return '$meters मी';
  }

  @override
  String distanceKilometers(Object kilometers) {
    return '$kilometers किमी';
  }

  @override
  String get etaLessThanMinute => '<1 मिनट';

  @override
  String etaMinutes(Object minutes) {
    return '$minutes मिनट';
  }

  @override
  String etaHours(Object hours) {
    return '$hours घंटा';
  }

  @override
  String etaHoursMinutes(Object hours, Object minutes) {
    return '$hours घंटा $minutes मी';
  }

  @override
  String mapEtaLabel(Object eta, Object distance) {
    return 'ईटीए $eta - $distance';
  }

  @override
  String get mapOpenAction => 'मानचित्र खोलें';

  @override
  String get orderMapTitle => 'आदेश मानचित्र';

  @override
  String get orderChatTitle => 'इस आदेश के बारे में बातचीत करें';

  @override
  String get messagesTitle => 'संदेशों';

  @override
  String get messagesSearchHint => 'संदेश खोजें';

  @override
  String messagesLoadError(Object error) {
    return 'बातचीत लोड करने में त्रुटि: $error';
  }

  @override
  String get messagesEmpty =>
      'आपने अभी तक कोई बातचीत नहीं की है.\nएक बार जब आप किसी प्रदाता/ग्राहक से चैट करेंगे, तो वे यहां दिखाई देंगे।';

  @override
  String get messagesNewConversationTitle => 'नई बातचीत';

  @override
  String get messagesNewConversationBody =>
      'किसी प्रदाता या ग्राहक के साथ बातचीत शुरू करने के लिए, अपने \"ऑर्डर\" पर जाएं या नया ऑर्डर स्वीकार करें।';

  @override
  String get messagesFilterAll => 'सभी';

  @override
  String get messagesFilterUnread => 'अपठित ग';

  @override
  String get messagesFilterFavorites => 'पसंदीदा';

  @override
  String get messagesFilterGroups => 'समूह';

  @override
  String messagesFilterEmpty(Object filter) {
    return '\"$filter\" में कुछ भी नहीं';
  }

  @override
  String get messagesSearchNoResults => 'कोई बातचीत नहीं मिली.';

  @override
  String get messagesPinConversation => 'वार्तालाप पिन करें';

  @override
  String get messagesUnpinConversation => 'बातचीत अनपिन करें';

  @override
  String get chatPresenceOnline => 'ऑनलाइन';

  @override
  String chatPresenceLastSeenAt(Object time) {
    return 'अंतिम बार $time पर देखा गया';
  }

  @override
  String chatPresenceLastSeenYesterdayAt(Object time) {
    return 'आखिरी बार कल $time पर देखा गया';
  }

  @override
  String chatPresenceLastSeenOn(Object date, Object time) {
    return 'अंतिम बार $date को $time पर देखा गया';
  }

  @override
  String get chatImageTooLarge => 'छवि बहुत बड़ी है (अधिकतम 15एमबी)।';

  @override
  String chatImageSendError(Object error) {
    return 'छवि भेजने में त्रुटि: $error';
  }

  @override
  String get chatFileReadError => 'फ़ाइल को पढ़ा नहीं जा सका.';

  @override
  String get chatFileTooLarge => 'फ़ाइल बहुत बड़ी है (अधिकतम 20MB).';

  @override
  String chatFileSendError(Object error) {
    return 'फ़ाइल भेजने में त्रुटि: $error';
  }

  @override
  String get chatAudioReadError => 'ऑडियो पढ़ा नहीं जा सका.';

  @override
  String get chatAudioTooLarge => 'ऑडियो बहुत बड़ा (अधिकतम 20 एमबी)।';

  @override
  String chatAudioSendError(Object error) {
    return 'ऑडियो भेजने में त्रुटि: $error';
  }

  @override
  String get chatAttachFile => 'लेख्यपत्र भेज दें';

  @override
  String get chatAttachGallery => 'फोटो भेजें (गैलरी)';

  @override
  String get chatAttachCamera => 'फ़ोटो लें (कैमरा)';

  @override
  String get chatAttachAudio => 'ऑडियो भेजें (फ़ाइल)';

  @override
  String get chatAttachAudioSubtitle =>
      'एक ऑडियो फ़ाइल चुनें (mp3/m4a/wav/...)।';

  @override
  String get chatOpenLink => 'खुला लिंक';

  @override
  String get chatAttachTooltip => 'संलग्न करना';

  @override
  String get chatSendTooltip => 'भेजना';

  @override
  String get chatSearchAction => 'खोज';

  @override
  String get chatSearchHint => 'संदेश खोजें';

  @override
  String get chatSearchEmpty => 'खोजने के लिए कुछ लिखें.';

  @override
  String get chatSearchNoResults => 'कोई संदेश नहीं मिला.';

  @override
  String get chatMediaAction => 'मीडिया, लिंक और फ़ाइलें';

  @override
  String get chatMediaTitle => 'मीडिया, लिंक और फ़ाइलें';

  @override
  String get chatMediaPhotosTab => 'तस्वीरें';

  @override
  String get chatMediaLinksTab => 'लिंक';

  @override
  String get chatMediaAudioTab => 'ऑडियो';

  @override
  String get chatMediaFilesTab => 'फ़ाइलें';

  @override
  String get chatMediaEmptyPhotos => 'अभी तक कोई फ़ोटो नहीं.';

  @override
  String get chatMediaEmptyLinks => 'अभी तक कोई लिंक नहीं.';

  @override
  String get chatMediaEmptyAudio => 'अभी तक कोई ऑडियो नहीं.';

  @override
  String get chatMediaEmptyFiles => 'अभी तक कोई फ़ाइल नहीं.';

  @override
  String get chatFavoritesAction => 'तारांकित';

  @override
  String get chatFavoritesTitle => 'तारांकित संदेश';

  @override
  String get chatFavoritesEmpty =>
      'आपके पास अभी तक कोई तारांकित संदेश नहीं है.';

  @override
  String get chatStarAction => 'पसंदीदा में जोड़े';

  @override
  String get chatUnstarAction => 'पसंदीदा से हटाएँ';

  @override
  String get chatViewProviderProfileAction => 'प्रदाता प्रोफ़ाइल देखें';

  @override
  String get chatViewCustomerProfileAction => 'ग्राहक प्रोफ़ाइल देखें';

  @override
  String get chatIncomingCall => 'एक फोन आ रहा है';

  @override
  String get chatCallStartedVideo => 'वीडियो कॉल शुरू हुई';

  @override
  String get chatCallStartedVoice => 'वॉइस कॉल प्रारंभ हुई';

  @override
  String get chatImageLabel => 'छवि';

  @override
  String get chatAudioLabel => 'ऑडियो';

  @override
  String get chatFileLabel => 'फ़ाइल';

  @override
  String get chatCallEntryLabel => 'पुकारना';

  @override
  String get chatNoSession =>
      'कोई सक्रिय सत्र नहीं. चैट तक पहुंचने के लिए साइन इन करें.';

  @override
  String get chatTitleFallback => 'बात करना';

  @override
  String get chatVideoCallAction => 'वीडियो कॉल';

  @override
  String get chatVoiceCallAction => 'पुकारना';

  @override
  String get chatMarkReadAction => 'पढ़े हुए का चिह्न';

  @override
  String get chatCallMissingParticipant =>
      'अन्य भागीदार को अभी तक यह आदेश नहीं सौंपा गया है।';

  @override
  String get chatCallStartError => 'कॉल प्रारंभ नहीं हो सकी.';

  @override
  String chatCallMessageVideo(Object url) {
    return 'वीडियो कॉल: $url';
  }

  @override
  String chatCallMessageVoice(Object url) {
    return 'कॉल करें: $url';
  }

  @override
  String get profileProviderTitle => 'प्रदाता प्रोफ़ाइल';

  @override
  String get profileCustomerTitle => 'ग्राहक प्रोफाइल';

  @override
  String get profileAboutTitle => 'के बारे में';

  @override
  String get profileLocationTitle => 'जगह';

  @override
  String get profileServicesTitle => 'सेवाएं';

  @override
  String get profilePortfolioTitle => 'पोर्टफोलियो';

  @override
  String get chatOpenFullAction => 'पूरी चैट खोलें';

  @override
  String get chatOpenFullUnavailable =>
      'अन्य प्रतिभागी को अभी तक यह आदेश नहीं सौंपा गया है।';

  @override
  String get chatReplyAction => 'जवाब';

  @override
  String get chatCopyAction => 'प्रतिलिपि';

  @override
  String get chatDeleteAction => 'मिटाना';

  @override
  String get storyNewTitle => 'नई कहानी';

  @override
  String get storyPublishing => 'कहानी प्रकाशित हो रही है...';

  @override
  String get storyPublished => 'कहानी प्रकाशित! 24 घंटे में समाप्त हो रहा है.';

  @override
  String storyPublishError(Object error) {
    return 'कहानी प्रकाशित करने में त्रुटि: $error';
  }

  @override
  String get storyCaptionHint => 'कैप्शन (वैकल्पिक)';

  @override
  String get actionPublish => 'प्रकाशित करना';

  @override
  String get snackOrderRemoved => 'आदेश हटा दिया गया.';

  @override
  String get snackClientCancelledOrder => 'ग्राहक ने ऑर्डर रद्द कर दिया.';

  @override
  String get snackOrderCancelled => 'आदेश रद्द किया गया।';

  @override
  String get snackOrderAcceptedByAnother =>
      'किसी अन्य प्रदाता ने आदेश स्वीकार कर लिया.';

  @override
  String get snackOrderUpdated => 'ऑर्डर अपडेट किया गया.';

  @override
  String get snackUserNotAuthenticated => 'उपयोगकर्ता प्रमाणित नहीं है.';

  @override
  String get snackOrderAcceptedCanQuote =>
      'आदेश स्वीकार किया गया. आप ऑर्डर विवरण में उद्धरण भेज सकते हैं।';

  @override
  String get snackOrderAcceptedSuccess => 'आदेश स्वीकार किया गया.';

  @override
  String snackErrorAcceptingOrder(Object error) {
    return 'आदेश स्वीकार करने में त्रुटि: $error';
  }

  @override
  String get dialogTitleOrderAccepted => 'आदेश स्वीकार कर लिया गया';

  @override
  String get dialogContentQuotePrompt =>
      'यह आदेश उद्धरणानुसार है.\n\nक्या आप अभी कोटेशन श्रेणी भेजना चाहते हैं?';

  @override
  String get dialogTitleProposeService => 'सेवा का प्रस्ताव रखें';

  @override
  String get dialogContentProposeService =>
      'इस सेवा के लिए एक मूल्य सीमा निर्धारित करें.\nयात्रा और श्रम शामिल करें।';

  @override
  String get labelMinValue => 'न्यूनतम मूल्य';

  @override
  String get labelMaxValue => 'अधिकतम मूल्य';

  @override
  String get labelMessageOptional => 'ग्राहक को संदेश (वैकल्पिक)';

  @override
  String hintExampleValue(Object value) {
    return 'उदाहरण: $value';
  }

  @override
  String get hintProposalMessage =>
      'उदाहरण: यात्रा शामिल है। बड़ी सामग्री अतिरिक्त हैं.';

  @override
  String get snackFillValidValues => 'मान्य न्यूनतम और अधिकतम मान दर्ज करें.';

  @override
  String get snackMinCannotBeGreaterThanMax =>
      'न्यूनतम अधिकतम से अधिक नहीं हो सकता.';

  @override
  String get snackProposalSent => 'ग्राहक को प्रस्ताव भेजा गया.';

  @override
  String snackErrorSendingProposal(Object error) {
    return 'प्रस्ताव भेजने में त्रुटि: $error';
  }
}
