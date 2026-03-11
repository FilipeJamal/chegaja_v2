// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ChegaJa';

  @override
  String get roleSelectorWelcome => 'Willkommen bei ChegaJa';

  @override
  String get roleSelectorPrompt =>
      'Wählen Sie, wie Sie die App nutzen möchten:';

  @override
  String get roleCustomerTitle => 'Ich bin Kunde';

  @override
  String get roleCustomerDescription =>
      'Ich möchte Dienstleister in meiner Nähe finden.';

  @override
  String get roleProviderTitle => 'Ich bin ein Anbieter';

  @override
  String get roleProviderDescription =>
      'Ich möchte Kundenanfragen erhalten und mehr verdienen.';

  @override
  String get invalidSession => 'Ungültige Sitzung.';

  @override
  String get paymentsTitle => 'Zahlungen (Stripe)';

  @override
  String get paymentsHeading => 'Erhalten Sie Online-Zahlungen';

  @override
  String get paymentsDescription =>
      'Um Zahlungen über die App zu erhalten, müssen Sie ein Stripe-Konto (Connect Express) erstellen.\nDas Onboarding öffnet sich in Ihrem Browser und dauert 2–3 Minuten.';

  @override
  String get paymentsActive => 'Online-Zahlungen AKTIV.';

  @override
  String get paymentsInactive =>
      'Online-Zahlungen sind noch nicht aktiv. Komplettes Onboarding.';

  @override
  String stripeAccountLabel(Object accountId) {
    return 'Stripe-Konto: $accountId';
  }

  @override
  String get onboardingOpened =>
      'Onboarding eröffnet. Kommen Sie nach Abschluss noch einmal zurück, um den Status zu überprüfen.';

  @override
  String onboardingStartError(Object error) {
    return 'Fehler beim Starten des Onboardings: $error';
  }

  @override
  String get manageStripeAccount => 'Stripe-Konto verwalten';

  @override
  String get activatePayments => 'Zahlungen aktivieren';

  @override
  String get technicalNotesTitle => 'Technische Hinweise';

  @override
  String get technicalNotesBody =>
      '• Stripe wird über Cloud Functions (serverseitig) konfiguriert.\n• Die Plattformprovision wird automatisch im PaymentIntent angewendet.\n• Fügen Sie in der Produktion den Stripe-Webhook hinzu und speichern Sie das Webhook-Geheimnis in den Funktionen.';

  @override
  String kycTitle(Object status) {
    return 'Identitätsüberprüfung: $status';
  }

  @override
  String get kycDescription =>
      'Senden Sie ein Dokument (Foto oder PDF). Die vollständige Validierung erfolgt in Version 2.6.';

  @override
  String get kycSendDocument => 'Dokument senden';

  @override
  String get kycAddDocument => 'Dokument hinzufügen';

  @override
  String get kycStatusApproved => 'Genehmigt';

  @override
  String get kycStatusRejected => 'Abgelehnt';

  @override
  String get kycStatusInReview => 'Im Rückblick';

  @override
  String get kycStatusNotStarted => 'Nicht gestartet';

  @override
  String get kycFileReadError => 'Die Datei konnte nicht gelesen werden.';

  @override
  String get kycFileTooLarge => 'Datei zu groß (max. 10 MB).';

  @override
  String get kycUploading => 'Dokument wird hochgeladen...';

  @override
  String get kycUploadSuccess => 'Dokument zur Überprüfung gesendet.';

  @override
  String kycUploadError(Object error) {
    return 'Fehler beim Senden des Dokuments: $error';
  }

  @override
  String get statusCancelledByYou => 'Von Ihnen storniert';

  @override
  String get statusCancelledByProvider => 'Vom Anbieter storniert';

  @override
  String get statusCancelled => 'Abgesagt';

  @override
  String get statusLookingForProvider => 'Anbieter gesucht';

  @override
  String get statusProviderPreparingQuote =>
      'Anbieter gefunden (Angebot wird erstellt)';

  @override
  String get statusQuoteToDecide => 'Sie müssen über ein Angebot entscheiden';

  @override
  String get statusProviderFound => 'Anbieter gefunden';

  @override
  String get statusServiceInProgress => 'Dienst läuft';

  @override
  String get statusAwaitingValueConfirmation =>
      'Warten auf Ihre Wertbestätigung';

  @override
  String get statusServiceCompleted => 'Service abgeschlossen';

  @override
  String valueToConfirm(Object value) {
    return '$value (zur Bestätigung)';
  }

  @override
  String valueProposed(Object value) {
    return '$value (vorgeschlagen)';
  }

  @override
  String valueEstimatedRange(Object min, Object max) {
    return '$min bis $max (geschätzt)';
  }

  @override
  String valueEstimatedFrom(Object min) {
    return 'Ab $min (geschätzt)';
  }

  @override
  String valueEstimatedUpTo(Object max) {
    return 'Bis zu $max (geschätzt)';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get priceFixed => 'Festpreis';

  @override
  String get priceByQuote => 'Durch Zitat';

  @override
  String get priceToArrange => 'Zu vereinbaren';

  @override
  String get paymentOnlineBefore => 'Online-Zahlung (vorher)';

  @override
  String get paymentOnlineAfter => 'Online-Zahlung (nachher)';

  @override
  String get paymentCash => 'Barzahlung';

  @override
  String get pendingActionQuoteToReview =>
      'Sie möchten ein Angebot/einen Vorschlag prüfen.';

  @override
  String get pendingActionValueToConfirm =>
      'Der Anbieter hat den Endwert gesendet. Sie müssen bestätigen.';

  @override
  String get pendingActionProviderPreparingQuote =>
      'Anbieter gefunden. Sie bereiten das Angebot vor.';

  @override
  String get pendingActionProviderChat =>
      'Anbieter gefunden. Sie können mit ihnen chatten.';

  @override
  String get roleLabelCustomer => 'Kunde';

  @override
  String get navHome => 'Heim';

  @override
  String get navMyOrders => 'Meine Bestellungen';

  @override
  String get navMessages => 'Nachrichten';

  @override
  String get navProfile => 'Profil';

  @override
  String get homeGreeting => 'Hallo';

  @override
  String get homeSubtitle => 'Was brauchen Sie heute?';

  @override
  String get homePendingTitle => 'Sie müssen etwas entscheiden';

  @override
  String get homePendingCta =>
      'Tippen Sie hier, um die nächste Bestellung zu öffnen und zu entscheiden.';

  @override
  String servicesLoadError(Object error) {
    return 'Fehler beim Laden der Dienste: $error';
  }

  @override
  String get servicesEmptyMessage =>
      'Noch keine Dienste konfiguriert.\\nHier werden bald Kategorien angezeigt 🙂';

  @override
  String get availableServicesTitle => 'Verfügbare Dienste';

  @override
  String get serviceTabImmediate => 'Sofort';

  @override
  String get serviceTabScheduled => 'Geplant';

  @override
  String get serviceTabQuote => 'Durch Zitat';

  @override
  String get unreadMessagesTitle => 'Sie haben neue Nachrichten';

  @override
  String get unreadMessagesCta => 'Tippen Sie hier, um den Chat zu öffnen.';

  @override
  String get serviceSearchHint => 'Suchdienst...';

  @override
  String get serviceSearchEmpty =>
      'Für diese Suche wurden keine Dienste gefunden.';

  @override
  String get serviceModeImmediateDescription =>
      'Ein Anbieter kommt heute schnellstmöglich.';

  @override
  String get serviceModeScheduledDescription =>
      'Planen Sie einen Tag und eine Uhrzeit für den Gottesdienst.';

  @override
  String get serviceModeQuoteDescription =>
      'Fordern Sie ein Angebot an (Anbieter sendet einen Min/Max-Bereich).';

  @override
  String get userNotAuthenticatedError =>
      'Fehler: Benutzer nicht authentifiziert.';

  @override
  String get myOrdersTitle => 'Meine Bestellungen';

  @override
  String get ordersTabPending => 'Ausstehend';

  @override
  String get ordersTabCompleted => 'Vollendet';

  @override
  String get ordersTabCancelled => 'Abgesagt';

  @override
  String ordersLoadError(Object error) {
    return 'Fehler beim Laden der Bestellungen: $error';
  }

  @override
  String get ordersEmptyPending =>
      'Sie haben keine ausstehenden Bestellungen.\\nErstellen Sie eine neue Bestellung von der Startseite aus.';

  @override
  String get ordersEmptyCompleted =>
      'Sie haben noch keine Bestellungen abgeschlossen.';

  @override
  String get ordersEmptyCancelled =>
      'Sie haben noch keine Bestellungen storniert.';

  @override
  String get orderQuoteScheduled => 'Angebot (geplant)';

  @override
  String get orderQuoteImmediate => 'Angebot (sofort)';

  @override
  String get orderScheduled => 'Geplanter Service';

  @override
  String get orderImmediate => 'Sofortiger Service';

  @override
  String get categoryNotDefined => 'Kategorie nicht definiert';

  @override
  String orderStateLabel(Object state) {
    return 'Status: $state';
  }

  @override
  String orderPriceModelLabel(Object model) {
    return 'Preismodell: $model';
  }

  @override
  String orderPaymentLabel(Object payment) {
    return 'Zahlung: $payment';
  }

  @override
  String orderValueLabel(Object value) {
    return 'Wert: $value';
  }

  @override
  String accountTitle(Object role) {
    return 'Konto ($role)';
  }

  @override
  String get accountNameTitle => 'Ihr Name';

  @override
  String get accountProfileSubtitle => 'Profil';

  @override
  String get accountSettings => 'Einstellungen';

  @override
  String get accountHelpSupport => 'Hilfe und Unterstützung';

  @override
  String get navMyJobs => 'Meine Jobs';

  @override
  String get roleLabelProvider => 'Anbieter';

  @override
  String get enableLocationToGoOnline =>
      'Aktivieren Sie den Standort, um online zu gehen.';

  @override
  String get nearbyOrdersTitle => 'Bestellungen in Ihrer Nähe';

  @override
  String get noOrdersAvailableMessage =>
      'Derzeit sind keine Bestellungen verfügbar.';

  @override
  String get configureServiceAreaMessage =>
      'Legen Sie Ihren Servicebereich und Ihre Dienste fest, um mit dem Empfang von Bestellungen zu beginnen.';

  @override
  String get configureAction => 'Konfigurieren';

  @override
  String get offlineEnableOnlineMessage =>
      'Du bist offline. Aktivieren Sie den Online-Status, um Bestellungen zu erhalten.';

  @override
  String get noMatchingOrdersMessage =>
      'Keine passenden Bestellungen für Ihre Dienste und Region.';

  @override
  String get orderAcceptedMessage => 'Bestellung angenommen.';

  @override
  String get orderAcceptedCanSendQuote =>
      'Bestellung angenommen. Sie können das Angebot später senden.';

  @override
  String orderAcceptError(Object error) {
    return 'Fehler beim Akzeptieren der Bestellung: $error';
  }

  @override
  String get orderAcceptedDialogTitle => 'Bestellung angenommen';

  @override
  String get orderAcceptedBudgetPrompt =>
      'Diese Bestellung erfolgt nach Angebot.\\n\\nMöchten Sie den Angebotsbereich jetzt senden?';

  @override
  String get actionLater => 'Später';

  @override
  String get actionSendNow => 'Jetzt senden';

  @override
  String get actionCancel => 'Stornieren';

  @override
  String get actionSend => 'Schicken';

  @override
  String get actionIgnore => 'Ignorieren';

  @override
  String get actionAccept => 'Akzeptieren';

  @override
  String get actionNo => 'NEIN';

  @override
  String get actionYesCancel => 'Ja, stornieren';

  @override
  String get proposalDialogTitle => 'Senden Sie ein Angebot';

  @override
  String get proposalDialogDescription =>
      'Legen Sie eine Preisspanne für diesen Service fest.\\nBerücksichtigen Sie Reise- und Arbeitskosten.';

  @override
  String proposalMinValueLabel(Object currency) {
    return 'Mindestwert ($currency)';
  }

  @override
  String get proposalMinValueHint => 'Bsp.: 20';

  @override
  String proposalMaxValueLabel(Object currency) {
    return 'Maximalwert ($currency)';
  }

  @override
  String get proposalMaxValueHint => 'Bsp.: 35';

  @override
  String get proposalMessageLabel => 'Nachricht an den Kunden (optional)';

  @override
  String get proposalMessageHint =>
      'Bsp.: Reisen inklusive. Große Materialien sind extra.';

  @override
  String get proposalInvalidValues =>
      'Geben Sie gültige Mindest- und Höchstwerte ein.';

  @override
  String get proposalMinGreaterThanMax =>
      'Das Minimum kann nicht größer als das Maximum sein.';

  @override
  String get proposalSent => 'Angebot an den Kunden gesendet.';

  @override
  String proposalSendError(Object error) {
    return 'Fehler beim Senden des Vorschlags: $error';
  }

  @override
  String get providerHomeGreeting => 'Hallo Anbieter';

  @override
  String get providerHomeSubtitle =>
      'Gehen Sie online, um neue Bestellungen zu erhalten.';

  @override
  String get providerStatusOnline => 'Du bist ONLINE';

  @override
  String get providerStatusOffline => 'Du bist OFFLINE';

  @override
  String providerSettingsLoadError(Object error) {
    return 'Fehler beim Laden der Einstellungen: $error';
  }

  @override
  String providerSettingsSaveError(Object error) {
    return 'Fehler beim Speichern der Einstellungen: $error';
  }

  @override
  String get serviceAreaTitle => 'Servicebereich';

  @override
  String get serviceAreaHeading => 'Wo möchten Sie Bestellungen erhalten?';

  @override
  String get serviceAreaSubtitle =>
      'Legen Sie die von Ihnen angebotenen Dienste und den maximalen Umkreis um Ihre Basisstadt fest.';

  @override
  String get serviceAreaBaseLocation => 'Basisstandort';

  @override
  String get serviceAreaRadius => 'Serviceradius';

  @override
  String get serviceAreaSaved => 'Servicebereich erfolgreich gespeichert.';

  @override
  String get serviceAreaInfoNote =>
      'In Zukunft werden wir diese Einstellungen verwenden, um Bestellungen nach Nähe und Servicetyp zu filtern. Dies hilft uns vorerst bei der Vorbereitung der passenden Engine.';

  @override
  String get availabilityTitle => 'Verfügbarkeit';

  @override
  String get servicesYouProvideTitle =>
      'Von Ihnen bereitgestellte Dienstleistungen';

  @override
  String get servicesCatalogEmpty =>
      'Im Katalog sind noch keine Dienste konfiguriert.';

  @override
  String get servicesSearchPrompt =>
      'Geben Sie ein, um Dienste zu suchen und hinzuzufügen.';

  @override
  String get servicesSearchNoResults => 'Keine Dienste gefunden.';

  @override
  String get servicesSelectedTitle => 'Ausgewählte Dienstleistungen';

  @override
  String get serviceUnnamed => 'Unbenannter Dienst';

  @override
  String get serviceModeQuote => 'Zitat';

  @override
  String get serviceModeScheduled => 'Geplant';

  @override
  String get serviceModeImmediate => 'Sofort';

  @override
  String get providerServicesSelectAtLeastOne =>
      'Wählen Sie mindestens einen Dienst aus, den Sie anbieten.';

  @override
  String get countryLabel => 'Land';

  @override
  String get cityLabel => 'Stadt';

  @override
  String get stateLabelDistrict => 'Bezirk';

  @override
  String get stateLabelProvince => 'Provinz';

  @override
  String get stateLabelState => 'Zustand';

  @override
  String get stateLabelRegion => 'Region';

  @override
  String get stateLabelCounty => 'County';

  @override
  String get stateLabelRegionOrState => 'Region/Bundesland';

  @override
  String get searchHint => 'Suchen...';

  @override
  String get searchCountryHint => 'Geben Sie ein, um nach Ländern zu suchen';

  @override
  String get searchGenericHint => 'Geben Sie ein, um zu suchen';

  @override
  String get searchServicesHint => 'Suchdienste';

  @override
  String get openCountriesListTooltip => 'Länderliste anzeigen';

  @override
  String get openListTooltip => 'Liste anzeigen';

  @override
  String get selectCountryTitle => 'Land auswählen';

  @override
  String get selectCityTitle => 'Stadt auswählen';

  @override
  String selectFieldTitle(Object field) {
    return 'Wählen Sie $field';
  }

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get supportTitle => 'Hilfe und Support';

  @override
  String get supportSubtitle => 'Haben Sie Fragen? Kontaktieren Sie uns.';

  @override
  String get myScheduleTitle => 'Mein Zeitplan';

  @override
  String get myScheduleSubtitle => 'Legen Sie freie Stunden und Tage fest';

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageModeManual => 'Handbuch';

  @override
  String get languageModeAuto => 'Auto';

  @override
  String languageModeLabel(Object code, Object mode) {
    return '$code - $mode';
  }

  @override
  String get languageAutoSystem => 'Auto (System)';

  @override
  String get providerCategoriesTitle => 'Servicekategorien';

  @override
  String get providerCategoriesSubtitle =>
      'Wir verwenden Kategorien, um kompatible Bestellungen zu filtern.';

  @override
  String get providerCategoriesEmpty => 'Keine Kategorie ausgewählt.';

  @override
  String get providerCategoriesSelect => 'Wählen Sie Kategorien aus';

  @override
  String get providerCategoriesEdit => 'Kategorien hinzufügen oder bearbeiten';

  @override
  String get providerCategoriesRequiredMessage =>
      'Wählen Sie Ihre Kategorien aus, um passende Bestellungen zu erhalten.';

  @override
  String get providerKpiEarningsToday => 'Verdienst heute (netto)';

  @override
  String get providerKpiServicesThisMonth => 'Gottesdienste diesen Monat';

  @override
  String providerKpiGrossFeeSubtitle(Object gross, Object fee) {
    return 'Brutto: $gross - Gebühr: $fee';
  }

  @override
  String get providerHighlightTitle => 'Sie haben einen Job zu bewältigen';

  @override
  String get providerHighlightCta =>
      'Tippen Sie hier, um den nächsten Job zu öffnen.';

  @override
  String get providerPendingActionAccepted =>
      'Sie haben einen angenommenen Job und können loslegen.';

  @override
  String get providerPendingActionInProgress =>
      'Sie haben einen Auftrag in Bearbeitung. Markieren Sie es als erledigt, wenn Sie fertig sind.';

  @override
  String get providerPendingActionSetFinalValue =>
      'Legen Sie den endgültigen Servicewert fest und senden Sie ihn.';

  @override
  String get providerUnreadMessagesTitle =>
      'Sie haben neue Nachrichten von Kunden';

  @override
  String providerUnreadMessagesJob(Object jobTitle) {
    return 'Im Job: $jobTitle';
  }

  @override
  String get providerJobsTitle => 'Meine Jobs';

  @override
  String get providerJobsTabOpen => 'Offen';

  @override
  String get providerJobsTabCompleted => 'Vollendet';

  @override
  String get providerJobsTabCancelled => 'Abgesagt';

  @override
  String providerJobsLoadError(Object error) {
    return 'Fehler beim Laden von Jobs: $error';
  }

  @override
  String get providerJobsEmptyOpen =>
      'Sie haben noch keine offenen Stellen.\\nGehen Sie zur Startseite und nehmen Sie eine Bestellung an.';

  @override
  String get providerJobsEmptyCompleted =>
      'Sie haben noch keine abgeschlossenen Aufträge.';

  @override
  String get providerJobsEmptyCancelled =>
      'Sie haben noch keine Jobs storniert.';

  @override
  String scheduledForDate(Object date) {
    return 'Geplant: $date';
  }

  @override
  String get viewDetailsTooltip => 'Details anzeigen';

  @override
  String clientPaidValueLabel(Object value) {
    return 'Vom Kunden bezahlt: $value';
  }

  @override
  String providerEarningsFeeLabel(Object value, Object fee) {
    return 'Sie erhalten: $value - Gebühr: $fee';
  }

  @override
  String serviceValueLabel(Object value) {
    return 'Servicewert: $value';
  }

  @override
  String get cancelJobTitle => 'Auftrag abbrechen';

  @override
  String get cancelJobPrompt =>
      'Sind Sie sicher, dass Sie diesen Auftrag stornieren möchten?\\nDie Bestellung wird möglicherweise für andere Anbieter verfügbar.';

  @override
  String get cancelJobReasonLabel => 'Stornierungsgrund (optional):';

  @override
  String get cancelJobReasonFieldLabel => 'Grund';

  @override
  String get cancelJobDetailLabel => 'Stornierungsdetails';

  @override
  String get cancelJobDetailRequired => 'Bitte fügen Sie ein Detail hinzu.';

  @override
  String get cancelJobSuccess => 'Auftrag abgebrochen.';

  @override
  String cancelJobError(Object error) {
    return 'Fehler beim Abbrechen des Jobs: $error';
  }

  @override
  String get providerAccountProfileTitle => 'Sehen Sie sich mein Profil an';

  @override
  String get providerAccountProfileSubtitle => 'Anbieterprofil';

  @override
  String get activateOnlinePaymentsSubtitle =>
      'Aktivieren Sie Online-Zahlungen';

  @override
  String get statusProviderWaiting => 'Neue Anfrage';

  @override
  String get statusQuoteWaitingCustomer => 'Warten auf die Antwort des Kunden';

  @override
  String get statusAcceptedToStart => 'Akzeptiert (bereit zum Start)';

  @override
  String get statusInProgress => 'Im Gange';

  @override
  String get statusCompleted => 'Vollendet';

  @override
  String get orderDefaultImmediateTitle => 'Dringender Service';

  @override
  String get locationServiceDisabled =>
      'Der Standortdienst ist auf dem Gerät deaktiviert.';

  @override
  String get locationPermissionDenied =>
      'Standortberechtigung verweigert.\\nDer aktuelle Standort konnte nicht abgerufen werden.';

  @override
  String get locationPermissionDeniedForever =>
      'Die Standortberechtigung wurde dauerhaft verweigert.\\nStandort in den Geräteeinstellungen aktivieren.';

  @override
  String locationFetchError(Object error) {
    return 'Fehler beim Abrufen des Standorts: $error';
  }

  @override
  String get formNotReadyError =>
      'Das Formular ist noch nicht fertig. Versuchen Sie es erneut.';

  @override
  String get missingRequiredFieldsError =>
      'Erforderliche Felder fehlen. Überprüfen Sie die rot markierten Felder.';

  @override
  String get scheduleDateTimeRequiredError =>
      'Wählen Sie Datum und Uhrzeit des Service aus.';

  @override
  String get scheduleDateTimeFutureError =>
      'Wählen Sie ein Datum/eine Uhrzeit in der Zukunft.';

  @override
  String get categoryRequiredError => 'Wählen Sie eine Kategorie.';

  @override
  String get orderUpdatedSuccess => 'Bestellung erfolgreich aktualisiert!';

  @override
  String get orderCreatedSuccess =>
      'Auftrag erstellt! Auf der Suche nach einem Anbieter...';

  @override
  String orderUpdateError(Object error) {
    return 'Fehler beim Aktualisieren der Bestellung: $error';
  }

  @override
  String orderCreateError(Object error) {
    return 'Fehler beim Erstellen der Bestellung: $error';
  }

  @override
  String get orderTitleExamplePlumbing => 'Bsp.: Wasserleck unter der Spüle';

  @override
  String get orderTitleExampleElectric =>
      'Bsp.: Steckdose funktioniert im Wohnzimmer nicht + Deckenleuchte installieren';

  @override
  String get orderTitleExampleCleaning =>
      'Bsp.: Vollständige Reinigung einer 2-Zimmer-Wohnung (Küche, WC, Fenster, Boden).';

  @override
  String get orderTitleHintImmediate =>
      'Erklären Sie kurz, was passiert und was Sie brauchen.';

  @override
  String get orderTitleHintScheduled =>
      'Sagen Sie, wann Sie den Service wünschen, geben Sie Standortdetails an und sagen Sie, was zu tun ist.';

  @override
  String get orderTitleHintQuote =>
      'Beschreiben Sie den Service, für den Sie Vorschläge erhalten möchten.';

  @override
  String get orderTitleHintDefault =>
      'Beschreiben Sie den Service, den Sie benötigen.';

  @override
  String get orderDescriptionExampleCleaning =>
      'Bsp.: Vollständige Reinigung einer 2-Zimmer-Wohnung (Küche, WC, Fenster, Boden).';

  @override
  String get orderDescriptionHintImmediate =>
      'Erklären Sie kurz, was passiert und was Sie brauchen.';

  @override
  String get orderDescriptionHintScheduled =>
      'Sagen Sie, wann Sie den Service wünschen, geben Sie Standortdetails an und sagen Sie, was zu tun ist.';

  @override
  String get orderDescriptionHintQuote =>
      'Beschreiben Sie den gewünschten Service, das ungefähre Budget (falls vorhanden) und wichtige Details.';

  @override
  String get orderDescriptionHintDefault =>
      'Erklären Sie etwas genauer, was Sie brauchen.';

  @override
  String get priceModelTitle => 'Preismodell';

  @override
  String get priceModelQuoteInfo =>
      'Dieser Service erfolgt nach Angebot. Der Anbieter schlägt Ihnen den Endpreis vor.';

  @override
  String get priceTypeLabel => 'Preistyp';

  @override
  String get paymentTypeLabel => 'Zahlungsart';

  @override
  String get orderHeaderQuoteTitle => 'Angebotsanfrage';

  @override
  String get orderHeaderQuoteSubtitle =>
      'Beschreiben Sie, was Sie benötigen, und der Anbieter kann einen Bereich (Min./Max.) senden.';

  @override
  String get orderHeaderImmediateTitle => 'Sofortiger Service';

  @override
  String get orderHeaderImmediateSubtitle =>
      'Ein verfügbarer Anbieter wird schnellstmöglich angerufen.';

  @override
  String get orderHeaderScheduledTitle => 'Geplanter Service';

  @override
  String get orderHeaderScheduledSubtitle =>
      'Wählen Sie den Tag und die Uhrzeit, zu der der Anbieter zu Ihnen kommen soll.';

  @override
  String get orderHeaderDefaultTitle => 'Neue Ordnung';

  @override
  String get orderHeaderDefaultSubtitle =>
      'Beschreiben Sie den Service, den Sie benötigen.';

  @override
  String get orderEditTitle => 'Bestellung bearbeiten';

  @override
  String get orderNewTitle => 'Neue Ordnung';

  @override
  String get whenServiceNeededLabel => 'Wann benötigen Sie den Service?';

  @override
  String get categoryLabel => 'Kategorie';

  @override
  String get categoryHint => 'Wählen Sie die Servicekategorie';

  @override
  String get orderTitleLabel => 'Bestelltitel';

  @override
  String get orderTitleRequiredError =>
      'Geben Sie einen Titel für die Bestellung ein.';

  @override
  String get orderDescriptionOptionalLabel => 'Beschreibung (optional)';

  @override
  String get locationApproxLabel => 'Ungefährer Standort';

  @override
  String get locationSelectedLabel => 'Standort ausgewählt.';

  @override
  String get locationSelectPrompt =>
      'Wählen Sie den Ort aus, an dem die Dienstleistung erbracht werden soll (ungefähr).';

  @override
  String get locationAddressHint =>
      'Straße, Hausnummer, Stockwerk, Referenz (optional, hilft aber sehr)';

  @override
  String get locationGetting => 'Standort ermitteln...';

  @override
  String get locationUseCurrent => 'Aktuellen Standort verwenden';

  @override
  String get locationChooseOnMap => 'Wählen Sie auf der Karte';

  @override
  String get serviceDateTimeLabel => 'Datum und Uhrzeit des Service';

  @override
  String get serviceDateTimePick => 'Wählen Sie Tag und Uhrzeit';

  @override
  String get saveChangesButton => 'Änderungen speichern';

  @override
  String get submitOrderButton => 'Service anfordern';

  @override
  String get mapSelectTitle => 'Wählen Sie den Standort auf der Karte';

  @override
  String get mapSelectInstruction =>
      'Ziehen Sie die Karte zum ungefähren Servicestandort und bestätigen Sie dann.';

  @override
  String get mapSelectConfirm => 'Standort bestätigen';

  @override
  String get orderDetailsTitle => 'Bestelldetails';

  @override
  String orderLoadError(Object error) {
    return 'Fehler beim Laden der Reihenfolge: $error';
  }

  @override
  String get orderNotFound => 'Bestellung nicht gefunden.';

  @override
  String get scheduledNoDate => 'Geplant (kein Datum festgelegt)';

  @override
  String get orderValueRejectedTitle =>
      'Der Kunde lehnte den vorgeschlagenen Wert ab.';

  @override
  String get orderValueRejectedBody =>
      'Chatten Sie mit dem Kunden und schlagen Sie bei Abstimmung einen neuen Wert vor.';

  @override
  String get actionProposeNewValue => 'Schlagen Sie einen neuen Wert vor';

  @override
  String get noShowReportedTitle => 'Nichterscheinen gemeldet';

  @override
  String noShowReportedBy(Object role) {
    return 'Gemeldet von: $role';
  }

  @override
  String noShowReportedAt(Object date) {
    return 'Um: $date';
  }

  @override
  String get noShowTitle => 'No-Show';

  @override
  String get noShowDescription =>
      'Wenn die andere Person nicht erschienen ist, können Sie dies melden.';

  @override
  String get noShowReportAction => 'Nichterscheinen melden';

  @override
  String get orderInfoTitle => 'Bestellinformationen';

  @override
  String get orderInfoIdLabel => 'Bestell-ID';

  @override
  String get orderInfoCreatedAtLabel => 'Erstellt bei';

  @override
  String get orderInfoStatusLabel => 'Status';

  @override
  String get orderInfoModeLabel => 'Modus';

  @override
  String get orderInfoValueLabel => 'Wert';

  @override
  String get orderLocationTitle => 'Bestellort';

  @override
  String get orderDescriptionTitle => 'Bestellbeschreibung';

  @override
  String get providerMessageTitle => 'Anbieternachricht';

  @override
  String get actionEditOrder => 'Bestellung bearbeiten';

  @override
  String get actionCancelOrder => 'Bestellung stornieren';

  @override
  String get cancelOrderTitle => 'Bestellung stornieren';

  @override
  String get orderCancelInProgressWarning =>
      'Der Dienst ist bereits in Bearbeitung.\nWenn Sie jetzt stornieren, kann es zu einer teilweisen Rückerstattung kommen.';

  @override
  String get orderCancelConfirmPrompt =>
      'Sind Sie sicher, dass Sie diese Bestellung stornieren möchten?';

  @override
  String get orderCancelReasonLabel => 'Stornierungsgrund';

  @override
  String get orderCancelReasonOptionalLabel => 'Grund (optional)';

  @override
  String orderCancelledSnack(Object message) {
    return 'Bestellung storniert. $message.';
  }

  @override
  String orderCancelError(Object error) {
    return 'Fehler beim Stornieren der Bestellung: $error';
  }

  @override
  String get noShowReportDialogTitle => 'Nichterscheinen melden';

  @override
  String get noShowReportDialogDescription =>
      'Verwenden Sie dies nur, wenn die andere Person nicht erschienen ist.';

  @override
  String get noShowReasonOptionalLabel => 'Grund (optional)';

  @override
  String get actionReport => 'Bericht';

  @override
  String get noShowReportSuccess => 'Nichterscheinen gemeldet.';

  @override
  String noShowReportError(Object error) {
    return 'Fehler bei der Meldung von Nichterscheinen: $error';
  }

  @override
  String get orderFinalValueTitle => 'Schlagen Sie einen neuen Endwert vor';

  @override
  String get orderFinalValueLabel => 'Wert';

  @override
  String get orderFinalValueInvalid => 'Geben Sie einen gültigen Wert ein.';

  @override
  String get orderFinalValueSent => 'Neuer Wert an den Kunden gesendet.';

  @override
  String orderFinalValueSendError(Object error) {
    return 'Fehler beim Senden des neuen Werts: $error';
  }

  @override
  String get ratingSentTitle => 'Bewertung gesendet';

  @override
  String get ratingProviderTitle => 'Anbieterbewertung';

  @override
  String get ratingPrompt => 'Hinterlassen Sie eine Bewertung von 1 bis 5.';

  @override
  String get ratingCommentLabel => 'Kommentar (optional)';

  @override
  String get ratingSendAction => 'Bewertung senden';

  @override
  String get ratingSelectError => 'Wählen Sie eine Bewertung.';

  @override
  String get ratingSentSnack => 'Bewertung gesendet.';

  @override
  String ratingSendError(Object error) {
    return 'Fehler beim Senden der Bewertung: $error';
  }

  @override
  String get timelineCreated => 'Erstellt';

  @override
  String get timelineAccepted => 'Akzeptiert';

  @override
  String get timelineInProgress => 'Im Gange';

  @override
  String get timelineCancelled => 'Abgesagt';

  @override
  String get timelineCompleted => 'Vollendet';

  @override
  String get lookingForProviderBanner =>
      'Für diesen Auftrag suchen wir noch einen Anbieter.';

  @override
  String get actionView => 'Sicht';

  @override
  String get chatNoMessagesSubtitle => 'Noch keine Nachrichten';

  @override
  String chatPreviewWithTime(Object preview, Object time) {
    return '$preview • $time';
  }

  @override
  String chatMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten',
      one: '1 Nachricht',
    );
    return '$_temp0';
  }

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionOpen => 'Offen';

  @override
  String get chatAuthRequired =>
      'Sie müssen authentifiziert sein, um Nachrichten senden zu können.';

  @override
  String chatSendError(Object error) {
    return 'Fehler beim Senden der Nachricht: $error';
  }

  @override
  String get todayLabel => 'Heute';

  @override
  String get yesterdayLabel => 'Gestern';

  @override
  String chatLoadError(Object error) {
    return 'Fehler beim Laden der Nachrichten: $error';
  }

  @override
  String get chatEmptyMessage =>
      'Noch keine Nachrichten.\nSchicken Sie den ersten!';

  @override
  String get chatInputHint => 'Nachricht schreiben...';

  @override
  String get chatLoginHint => 'Melden Sie sich an, um Nachrichten zu senden';

  @override
  String get roleLabelSystem => 'System';

  @override
  String get youLabel => 'Du';

  @override
  String distanceMeters(Object meters) {
    return '$meters m';
  }

  @override
  String distanceKilometers(Object kilometers) {
    return '$kilometers km';
  }

  @override
  String get etaLessThanMinute => '<1 Min';

  @override
  String etaMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String etaHours(Object hours) {
    return '$hours Std';
  }

  @override
  String etaHoursMinutes(Object hours, Object minutes) {
    return '$hours h $minutes m';
  }

  @override
  String mapEtaLabel(Object eta, Object distance) {
    return 'Voraussichtliche Ankunftszeit $eta - $distance';
  }

  @override
  String get mapOpenAction => 'Karte öffnen';

  @override
  String get orderMapTitle => 'Karte bestellen';

  @override
  String get orderChatTitle => 'Chatten Sie über diese Bestellung';

  @override
  String get messagesTitle => 'Nachrichten';

  @override
  String get messagesSearchHint => 'Nachrichten durchsuchen';

  @override
  String messagesLoadError(Object error) {
    return 'Fehler beim Laden der Konversationen: $error';
  }

  @override
  String get messagesEmpty =>
      'Sie führen noch keine Gespräche.\nSobald Sie mit einem Anbieter/Kunden chatten, wird dieser hier angezeigt.';

  @override
  String get messagesNewConversationTitle => 'Neues Gespräch';

  @override
  String get messagesNewConversationBody =>
      'Um ein Gespräch mit einem Anbieter oder Kunden zu beginnen, gehen Sie zu Ihren „Bestellungen“ oder nehmen Sie eine neue Bestellung an.';

  @override
  String get messagesFilterAll => 'Alle';

  @override
  String get messagesFilterUnread => 'Ungelesen';

  @override
  String get messagesFilterFavorites => 'Favoriten';

  @override
  String get messagesFilterGroups => 'Gruppen';

  @override
  String messagesFilterEmpty(Object filter) {
    return 'Nichts in „$filter“';
  }

  @override
  String get messagesSearchNoResults => 'Keine Gespräche gefunden.';

  @override
  String get messagesPinConversation => 'Konversation anpinnen';

  @override
  String get messagesUnpinConversation => 'Konversation lösen';

  @override
  String get chatPresenceOnline => 'online';

  @override
  String chatPresenceLastSeenAt(Object time) {
    return 'zuletzt gesehen am $time';
  }

  @override
  String chatPresenceLastSeenYesterdayAt(Object time) {
    return 'zuletzt gesehen gestern um $time';
  }

  @override
  String chatPresenceLastSeenOn(Object date, Object time) {
    return 'zuletzt gesehen am $date um $time';
  }

  @override
  String get chatImageTooLarge => 'Bild zu groß (maximal 15 MB).';

  @override
  String chatImageSendError(Object error) {
    return 'Fehler beim Senden des Bildes: $error';
  }

  @override
  String get chatFileReadError => 'Die Datei konnte nicht gelesen werden.';

  @override
  String get chatFileTooLarge => 'Datei zu groß (maximal 20 MB).';

  @override
  String chatFileSendError(Object error) {
    return 'Fehler beim Senden der Datei: $error';
  }

  @override
  String get chatAudioReadError => 'Der Ton konnte nicht gelesen werden.';

  @override
  String get chatAudioTooLarge => 'Audio zu groß (maximal 20 MB).';

  @override
  String chatAudioSendError(Object error) {
    return 'Fehler beim Senden von Audio: $error';
  }

  @override
  String get chatAttachFile => 'Datei senden';

  @override
  String get chatAttachGallery => 'Foto senden (Galerie)';

  @override
  String get chatAttachCamera => 'Foto machen (Kamera)';

  @override
  String get chatAttachAudio => 'Audio (Datei) senden';

  @override
  String get chatAttachAudioSubtitle =>
      'Wählen Sie eine Audiodatei (mp3/m4a/wav/...).';

  @override
  String get chatOpenLink => 'Link öffnen';

  @override
  String get chatAttachTooltip => 'Befestigen';

  @override
  String get chatSendTooltip => 'Schicken';

  @override
  String get chatSearchAction => 'Suchen';

  @override
  String get chatSearchHint => 'Nachrichten durchsuchen';

  @override
  String get chatSearchEmpty =>
      'Geben Sie etwas ein, nach dem gesucht werden soll.';

  @override
  String get chatSearchNoResults => 'Keine Nachrichten gefunden.';

  @override
  String get chatMediaAction => 'Medien, Links und Dateien';

  @override
  String get chatMediaTitle => 'Medien, Links und Dateien';

  @override
  String get chatMediaPhotosTab => 'Fotos';

  @override
  String get chatMediaLinksTab => 'Links';

  @override
  String get chatMediaAudioTab => 'Audio';

  @override
  String get chatMediaFilesTab => 'Dateien';

  @override
  String get chatMediaEmptyPhotos => 'Noch keine Fotos.';

  @override
  String get chatMediaEmptyLinks => 'Noch keine Links.';

  @override
  String get chatMediaEmptyAudio => 'Noch kein Ton.';

  @override
  String get chatMediaEmptyFiles => 'Noch keine Dateien.';

  @override
  String get chatFavoritesAction => 'Mit einem Stern versehen';

  @override
  String get chatFavoritesTitle => 'Markierte Nachrichten';

  @override
  String get chatFavoritesEmpty =>
      'Sie haben noch keine markierten Nachrichten.';

  @override
  String get chatStarAction => 'Zu Favoriten hinzufügen';

  @override
  String get chatUnstarAction => 'Aus Favoriten entfernen';

  @override
  String get chatViewProviderProfileAction => 'Anbieterprofil ansehen';

  @override
  String get chatViewCustomerProfileAction => 'Kundenprofil ansehen';

  @override
  String get chatIncomingCall => 'Eingehender Anruf';

  @override
  String get chatCallStartedVideo => 'Videoanruf gestartet';

  @override
  String get chatCallStartedVoice => 'Sprachanruf gestartet';

  @override
  String get chatImageLabel => 'Bild';

  @override
  String get chatAudioLabel => 'Audio';

  @override
  String get chatFileLabel => 'Datei';

  @override
  String get chatCallEntryLabel => 'Anruf';

  @override
  String get chatNoSession =>
      'Keine aktive Sitzung. Melden Sie sich an, um auf den Chat zuzugreifen.';

  @override
  String get chatTitleFallback => 'Chatten';

  @override
  String get chatVideoCallAction => 'Videoanruf';

  @override
  String get chatVoiceCallAction => 'Anruf';

  @override
  String get chatMarkReadAction => 'Als gelesen markieren';

  @override
  String get chatCallMissingParticipant =>
      'Der andere Teilnehmer ist dieser Bestellung noch nicht zugeordnet.';

  @override
  String get chatCallStartError => 'Der Anruf konnte nicht gestartet werden.';

  @override
  String chatCallMessageVideo(Object url) {
    return 'Videoanruf: $url';
  }

  @override
  String chatCallMessageVoice(Object url) {
    return 'Anruf: $url';
  }

  @override
  String get profileProviderTitle => 'Anbieterprofil';

  @override
  String get profileCustomerTitle => 'Kundenprofil';

  @override
  String get profileAboutTitle => 'Um';

  @override
  String get profileLocationTitle => 'Standort';

  @override
  String get profileServicesTitle => 'Dienstleistungen';

  @override
  String get profilePortfolioTitle => 'Portfolio';

  @override
  String get chatOpenFullAction => 'Vollständigen Chat öffnen';

  @override
  String get chatOpenFullUnavailable =>
      'Der andere Teilnehmer ist diesem Auftrag noch nicht zugeordnet.';

  @override
  String get chatReplyAction => 'Antwort';

  @override
  String get chatCopyAction => 'Kopie';

  @override
  String get chatDeleteAction => 'Löschen';

  @override
  String get storyNewTitle => 'Neue Geschichte';

  @override
  String get storyPublishing => 'Veröffentlichungsgeschichte...';

  @override
  String get storyPublished =>
      'Geschichte veröffentlicht! Läuft in 24 Stunden ab.';

  @override
  String storyPublishError(Object error) {
    return 'Fehler beim Veröffentlichen der Story: $error';
  }

  @override
  String get storyCaptionHint => 'Bildunterschrift (optional)';

  @override
  String get actionPublish => 'Veröffentlichen';

  @override
  String get snackOrderRemoved => 'Bestellung entfernt.';

  @override
  String get snackClientCancelledOrder =>
      'Der Kunde hat die Bestellung storniert.';

  @override
  String get snackOrderCancelled => 'Bestellung storniert.';

  @override
  String get snackOrderAcceptedByAnother =>
      'Ein anderer Anbieter hat die Bestellung angenommen.';

  @override
  String get snackOrderUpdated => 'Bestellung aktualisiert.';

  @override
  String get snackUserNotAuthenticated => 'Benutzer nicht authentifiziert.';

  @override
  String get snackOrderAcceptedCanQuote =>
      'Bestellung angenommen. Sie können das Angebot in den Bestelldetails senden.';

  @override
  String get snackOrderAcceptedSuccess => 'Bestellung angenommen.';

  @override
  String snackErrorAcceptingOrder(Object error) {
    return 'Fehler beim Akzeptieren der Bestellung: $error';
  }

  @override
  String get dialogTitleOrderAccepted => 'Bestellung angenommen';

  @override
  String get dialogContentQuotePrompt =>
      'Diese Bestellung erfolgt nach Angebot.\n\nMöchten Sie den Angebotsbereich jetzt senden?';

  @override
  String get dialogTitleProposeService => 'Service vorschlagen';

  @override
  String get dialogContentProposeService =>
      'Legen Sie eine Preisspanne für diesen Service fest.\nBerücksichtigen Sie Reise- und Arbeitskosten.';

  @override
  String get labelMinValue => 'Mindestwert';

  @override
  String get labelMaxValue => 'Maximalwert';

  @override
  String get labelMessageOptional => 'Nachricht an den Kunden (optional)';

  @override
  String hintExampleValue(Object value) {
    return 'Bsp.: $value';
  }

  @override
  String get hintProposalMessage =>
      'Bsp.: Reisen inklusive. Große Materialien sind extra.';

  @override
  String get snackFillValidValues =>
      'Geben Sie gültige Mindest- und Höchstwerte ein.';

  @override
  String get snackMinCannotBeGreaterThanMax =>
      'Das Minimum kann nicht größer als das Maximum sein.';

  @override
  String get snackProposalSent => 'Angebot an den Kunden gesendet.';

  @override
  String snackErrorSendingProposal(Object error) {
    return 'Fehler beim Senden des Vorschlags: $error';
  }
}
