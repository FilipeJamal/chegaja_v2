// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ChegaJa';

  @override
  String get roleSelectorWelcome => 'Bienvenue sur ChegaJa';

  @override
  String get roleSelectorPrompt =>
      'Choisissez comment vous souhaitez utiliser l\'application :';

  @override
  String get roleCustomerTitle => 'je suis client';

  @override
  String get roleCustomerDescription =>
      'Je souhaite trouver des prestataires de services près de chez moi.';

  @override
  String get roleProviderTitle => 'je suis un fournisseur';

  @override
  String get roleProviderDescription =>
      'Je souhaite recevoir les demandes des clients et gagner plus.';

  @override
  String get invalidSession => 'Séance invalide.';

  @override
  String get paymentsTitle => 'Paiements (Stripe)';

  @override
  String get paymentsHeading => 'Recevez des paiements en ligne';

  @override
  String get paymentsDescription =>
      'Pour recevoir des paiements via l\'application, vous devez créer un compte Stripe (Connect Express).\nL\'intégration s\'ouvre dans votre navigateur et prend 2 à 3 minutes.';

  @override
  String get paymentsActive => 'Paiements en ligne ACTIF.';

  @override
  String get paymentsInactive =>
      'Les paiements en ligne ne sont pas encore actifs. Intégration complète.';

  @override
  String stripeAccountLabel(Object accountId) {
    return 'Compte Stripe : $accountId';
  }

  @override
  String get onboardingOpened =>
      'Intégration ouverte. Après avoir terminé, revenez pour vérifier l’état.';

  @override
  String onboardingStartError(Object error) {
    return 'Erreur lors du démarrage de l\'intégration : $error';
  }

  @override
  String get manageStripeAccount => 'Gérer le compte Stripe';

  @override
  String get activatePayments => 'Activer les paiements';

  @override
  String get technicalNotesTitle => 'Notes techniques';

  @override
  String get technicalNotesBody =>
      '• Stripe est configuré via Cloud Functions (côté serveur).\n• La commission de la plateforme est appliquée automatiquement dans le PaymentIntent.\n• En production, ajoutez le webhook Stripe et stockez le secret du webhook dans Functions.';

  @override
  String kycTitle(Object status) {
    return 'Vérification d\'identité : $status';
  }

  @override
  String get kycDescription =>
      'Envoyez un document (photo ou PDF). La validation complète arrive dans la v2.6.';

  @override
  String get kycSendDocument => 'Envoyer le document';

  @override
  String get kycAddDocument => 'Ajouter un document';

  @override
  String get kycStatusApproved => 'Approuvé';

  @override
  String get kycStatusRejected => 'Rejeté';

  @override
  String get kycStatusInReview => 'En revue';

  @override
  String get kycStatusNotStarted => 'Pas commencé';

  @override
  String get kycFileReadError => 'Impossible de lire le fichier.';

  @override
  String get kycFileTooLarge => 'Fichier trop volumineux (max. 10 Mo).';

  @override
  String get kycUploading => 'Téléchargement du document...';

  @override
  String get kycUploadSuccess => 'Document envoyé pour examen.';

  @override
  String kycUploadError(Object error) {
    return 'Erreur lors de l\'envoi du document : $error';
  }

  @override
  String get statusCancelledByYou => 'Annulé par vous';

  @override
  String get statusCancelledByProvider => 'Annulé par le fournisseur';

  @override
  String get statusCancelled => 'Annulé';

  @override
  String get statusLookingForProvider => 'À la recherche d\'un fournisseur';

  @override
  String get statusProviderPreparingQuote =>
      'Prestataire trouvé (établissement du devis)';

  @override
  String get statusQuoteToDecide => 'Vous avez un devis pour décider';

  @override
  String get statusProviderFound => 'Fournisseur trouvé';

  @override
  String get statusServiceInProgress => 'Prestation en cours';

  @override
  String get statusAwaitingValueConfirmation =>
      'En attente de votre confirmation de valeur';

  @override
  String get statusServiceCompleted => 'Prestation terminée';

  @override
  String valueToConfirm(Object value) {
    return '$value (à confirmer)';
  }

  @override
  String valueProposed(Object value) {
    return '$value (proposé)';
  }

  @override
  String valueEstimatedRange(Object min, Object max) {
    return '$min à $max (estimation)';
  }

  @override
  String valueEstimatedFrom(Object min) {
    return 'À partir de $min (estimation)';
  }

  @override
  String valueEstimatedUpTo(Object max) {
    return 'Jusqu\'à $max (estimé)';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get priceFixed => 'Prix ​​fixe';

  @override
  String get priceByQuote => 'Par devis';

  @override
  String get priceToArrange => 'A aménager';

  @override
  String get paymentOnlineBefore => 'Paiement en ligne (avant)';

  @override
  String get paymentOnlineAfter => 'Paiement en ligne (après)';

  @override
  String get paymentCash => 'Paiement en espèces';

  @override
  String get pendingActionQuoteToReview =>
      'Vous avez un devis/proposition à examiner.';

  @override
  String get pendingActionValueToConfirm =>
      'Le fournisseur a envoyé la valeur finale. Vous devez confirmer.';

  @override
  String get pendingActionProviderPreparingQuote =>
      'Fournisseur trouvé. Ils préparent le devis.';

  @override
  String get pendingActionProviderChat =>
      'Fournisseur trouvé. Vous pouvez discuter avec eux.';

  @override
  String get roleLabelCustomer => 'Client';

  @override
  String get navHome => 'Maison';

  @override
  String get navMyOrders => 'Mes commandes';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profil';

  @override
  String get homeGreeting => 'Bonjour';

  @override
  String get homeSubtitle => 'De quoi as-tu besoin aujourd’hui ?';

  @override
  String get homePendingTitle => 'Tu as quelque chose à décider';

  @override
  String get homePendingCta =>
      'Appuyez ici pour ouvrir la commande suivante et décider.';

  @override
  String servicesLoadError(Object error) {
    return 'Erreur lors du chargement des services : $error';
  }

  @override
  String get servicesEmptyMessage =>
      'Aucun service configuré pour l\'instant.\\nVous verrez bientôt les catégories ici 🙂';

  @override
  String get availableServicesTitle => 'Services disponibles';

  @override
  String get serviceTabImmediate => 'Immédiat';

  @override
  String get serviceTabScheduled => 'Programmé';

  @override
  String get serviceTabQuote => 'Par devis';

  @override
  String get unreadMessagesTitle => 'Vous avez de nouveaux messages';

  @override
  String get unreadMessagesCta => 'Appuyez ici pour ouvrir le chat.';

  @override
  String get serviceSearchHint => 'Service de recherche...';

  @override
  String get serviceSearchEmpty => 'Aucun service trouvé pour cette recherche.';

  @override
  String get serviceModeImmediateDescription =>
      'Un prestataire arrive aujourd\'hui le plus rapidement possible.';

  @override
  String get serviceModeScheduledDescription =>
      'Planifiez un jour et une heure pour le service.';

  @override
  String get serviceModeQuoteDescription =>
      'Demandez un devis (le fournisseur envoie une plage min/max).';

  @override
  String get userNotAuthenticatedError =>
      'Erreur : utilisateur non authentifié.';

  @override
  String get myOrdersTitle => 'Mes commandes';

  @override
  String get ordersTabPending => 'En attente';

  @override
  String get ordersTabCompleted => 'Complété';

  @override
  String get ordersTabCancelled => 'Annulé';

  @override
  String ordersLoadError(Object error) {
    return 'Erreur lors du chargement des commandes : $error';
  }

  @override
  String get ordersEmptyPending =>
      'Vous n\'avez aucune commande en attente.\\nCréez une nouvelle commande depuis l\'accueil.';

  @override
  String get ordersEmptyCompleted =>
      'Vous n\'avez pas encore de commandes terminées.';

  @override
  String get ordersEmptyCancelled =>
      'Vous n\'avez pas encore de commandes annulées.';

  @override
  String get orderQuoteScheduled => 'Devis (planifié)';

  @override
  String get orderQuoteImmediate => 'Devis (immédiat)';

  @override
  String get orderScheduled => 'Service programmé';

  @override
  String get orderImmediate => 'Service immédiat';

  @override
  String get categoryNotDefined => 'Catégorie non définie';

  @override
  String orderStateLabel(Object state) {
    return 'État : $state';
  }

  @override
  String orderPriceModelLabel(Object model) {
    return 'Modèle de prix : $model';
  }

  @override
  String orderPaymentLabel(Object payment) {
    return 'Paiement : $payment';
  }

  @override
  String orderValueLabel(Object value) {
    return 'Valeur : $value';
  }

  @override
  String accountTitle(Object role) {
    return 'Compte ($role)';
  }

  @override
  String get accountNameTitle => 'Votre nom';

  @override
  String get accountProfileSubtitle => 'Profil';

  @override
  String get accountSettings => 'Paramètres';

  @override
  String get accountHelpSupport => 'Aide et support';

  @override
  String get navMyJobs => 'Mes emplois';

  @override
  String get roleLabelProvider => 'Fournisseur';

  @override
  String get enableLocationToGoOnline =>
      'Activez la localisation pour aller en ligne.';

  @override
  String get nearbyOrdersTitle => 'Commandes près de chez vous';

  @override
  String get noOrdersAvailableMessage =>
      'Aucune commande disponible pour le moment.';

  @override
  String get configureServiceAreaMessage =>
      'Définissez votre zone de service et vos services pour commencer à recevoir des commandes.';

  @override
  String get configureAction => 'Configurer';

  @override
  String get offlineEnableOnlineMessage =>
      'Vous êtes hors ligne. Activez le statut en ligne pour recevoir des commandes.';

  @override
  String get noMatchingOrdersMessage =>
      'Aucune commande correspondante pour vos services et votre région.';

  @override
  String get orderAcceptedMessage => 'Commande acceptée.';

  @override
  String get orderAcceptedCanSendQuote =>
      'Commande acceptée. Vous pourrez envoyer le devis plus tard.';

  @override
  String orderAcceptError(Object error) {
    return 'Erreur lors de l\'acceptation de la commande : $error';
  }

  @override
  String get orderAcceptedDialogTitle => 'Commande acceptée';

  @override
  String get orderAcceptedBudgetPrompt =>
      'Cette commande se fait par devis.\\n\\nVoulez-vous envoyer la plage de devis maintenant ?';

  @override
  String get actionLater => 'Plus tard';

  @override
  String get actionSendNow => 'Envoyer maintenant';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionSend => 'Envoyer';

  @override
  String get actionIgnore => 'Ignorer';

  @override
  String get actionAccept => 'Accepter';

  @override
  String get actionNo => 'Non';

  @override
  String get actionYesCancel => 'Oui, annuler';

  @override
  String get proposalDialogTitle => 'Envoyer un devis';

  @override
  String get proposalDialogDescription =>
      'Définissez une fourchette de prix pour ce service.\\nIncluez les déplacements et la main d\'œuvre.';

  @override
  String proposalMinValueLabel(Object currency) {
    return 'Valeur minimale ($currency)';
  }

  @override
  String get proposalMinValueHint => 'Ex. : 20';

  @override
  String proposalMaxValueLabel(Object currency) {
    return 'Valeur maximale ($currency)';
  }

  @override
  String get proposalMaxValueHint => 'Ex. : 35';

  @override
  String get proposalMessageLabel => 'Message au client (facultatif)';

  @override
  String get proposalMessageHint =>
      'Ex. : Comprend les déplacements. Les gros matériaux sont en sus.';

  @override
  String get proposalInvalidValues =>
      'Entrez des valeurs minimales et maximales valides.';

  @override
  String get proposalMinGreaterThanMax =>
      'Le minimum ne peut pas être supérieur au maximum.';

  @override
  String get proposalSent => 'Proposition envoyée au client.';

  @override
  String proposalSendError(Object error) {
    return 'Erreur lors de l\'envoi de la proposition : $error';
  }

  @override
  String get providerHomeGreeting => 'Bonjour, fournisseur';

  @override
  String get providerHomeSubtitle =>
      'Allez en ligne pour recevoir de nouvelles commandes.';

  @override
  String get providerStatusOnline => 'Vous êtes EN LIGNE';

  @override
  String get providerStatusOffline => 'Vous êtes HORS LIGNE';

  @override
  String providerSettingsLoadError(Object error) {
    return 'Erreur lors du chargement des paramètres : $error';
  }

  @override
  String providerSettingsSaveError(Object error) {
    return 'Erreur lors de l\'enregistrement des paramètres : $error';
  }

  @override
  String get serviceAreaTitle => 'Aire de service';

  @override
  String get serviceAreaHeading => 'Où souhaitez-vous recevoir les commandes ?';

  @override
  String get serviceAreaSubtitle =>
      'Définissez les services que vous fournissez et le rayon maximum autour de votre ville de base.';

  @override
  String get serviceAreaBaseLocation => 'Emplacement de base';

  @override
  String get serviceAreaRadius => 'Rayon de service';

  @override
  String get serviceAreaSaved => 'Zone de service enregistrée avec succès.';

  @override
  String get serviceAreaInfoNote =>
      'À l\'avenir, nous utiliserons ces paramètres pour filtrer les commandes par proximité et type de service. Pour l\'instant, cela nous aide à préparer le moteur de correspondance.';

  @override
  String get availabilityTitle => 'Disponibilité';

  @override
  String get servicesYouProvideTitle => 'Services que vous fournissez';

  @override
  String get servicesCatalogEmpty =>
      'Aucun service configuré dans le catalogue pour le moment.';

  @override
  String get servicesSearchPrompt =>
      'Tapez pour rechercher et ajouter des services.';

  @override
  String get servicesSearchNoResults => 'Aucun service trouvé.';

  @override
  String get servicesSelectedTitle => 'Prestations sélectionnées';

  @override
  String get serviceUnnamed => 'Service sans nom';

  @override
  String get serviceModeQuote => 'Citation';

  @override
  String get serviceModeScheduled => 'Programmé';

  @override
  String get serviceModeImmediate => 'Immédiat';

  @override
  String get providerServicesSelectAtLeastOne =>
      'Sélectionnez au moins un service que vous fournissez.';

  @override
  String get countryLabel => 'Pays';

  @override
  String get cityLabel => 'Ville';

  @override
  String get stateLabelDistrict => 'District';

  @override
  String get stateLabelProvince => 'Province';

  @override
  String get stateLabelState => 'État';

  @override
  String get stateLabelRegion => 'Région';

  @override
  String get stateLabelCounty => 'Comté';

  @override
  String get stateLabelRegionOrState => 'Région/État';

  @override
  String get searchHint => 'Recherche...';

  @override
  String get searchCountryHint => 'Tapez pour rechercher des pays';

  @override
  String get searchGenericHint => 'Tapez pour rechercher';

  @override
  String get searchServicesHint => 'Services de recherche';

  @override
  String get openCountriesListTooltip => 'Afficher la liste des pays';

  @override
  String get openListTooltip => 'Afficher la liste';

  @override
  String get selectCountryTitle => 'Sélectionnez un pays';

  @override
  String get selectCityTitle => 'Sélectionnez la ville';

  @override
  String selectFieldTitle(Object field) {
    return 'Sélectionnez $field';
  }

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get supportTitle => 'Aide et assistance';

  @override
  String get supportSubtitle => 'Vous avez des questions ? Contactez-nous.';

  @override
  String get myScheduleTitle => 'Mon emploi du temps';

  @override
  String get myScheduleSubtitle => 'Définir les heures et les jours de congé';

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageModeManual => 'Manuel';

  @override
  String get languageModeAuto => 'Auto';

  @override
  String languageModeLabel(Object code, Object mode) {
    return '$code - $mode';
  }

  @override
  String get languageAutoSystem => 'Automatique (système)';

  @override
  String get providerCategoriesTitle => 'Catégories de services';

  @override
  String get providerCategoriesSubtitle =>
      'Nous utilisons des catégories pour filtrer les commandes compatibles.';

  @override
  String get providerCategoriesEmpty => 'Aucune catégorie sélectionnée.';

  @override
  String get providerCategoriesSelect => 'Sélectionnez les catégories';

  @override
  String get providerCategoriesEdit => 'Ajouter ou modifier des catégories';

  @override
  String get providerCategoriesRequiredMessage =>
      'Sélectionnez vos catégories pour recevoir les commandes correspondantes.';

  @override
  String get providerKpiEarningsToday => 'Gains aujourd\'hui (nets)';

  @override
  String get providerKpiServicesThisMonth => 'Services ce mois-ci';

  @override
  String providerKpiGrossFeeSubtitle(Object gross, Object fee) {
    return 'Brut : $gross - Frais : $fee';
  }

  @override
  String get providerHighlightTitle => 'Vous avez un travail à gérer';

  @override
  String get providerHighlightCta =>
      'Appuyez ici pour ouvrir le travail suivant.';

  @override
  String get providerPendingActionAccepted =>
      'Vous avez un travail accepté, prêt à commencer.';

  @override
  String get providerPendingActionInProgress =>
      'Vous avez un travail en cours. Marquez-le comme terminé lorsque vous avez terminé.';

  @override
  String get providerPendingActionSetFinalValue =>
      'Définissez et envoyez la valeur finale du service.';

  @override
  String get providerUnreadMessagesTitle =>
      'Vous avez de nouveaux messages de clients';

  @override
  String providerUnreadMessagesJob(Object jobTitle) {
    return 'En poste : $jobTitle';
  }

  @override
  String get providerJobsTitle => 'Mes emplois';

  @override
  String get providerJobsTabOpen => 'Ouvrir';

  @override
  String get providerJobsTabCompleted => 'Complété';

  @override
  String get providerJobsTabCancelled => 'Annulé';

  @override
  String providerJobsLoadError(Object error) {
    return 'Erreur lors du chargement des tâches : $error';
  }

  @override
  String get providerJobsEmptyOpen =>
      'Vous n\'avez pas encore d\'offres d\'emploi disponibles.\\nAccédez à l\'accueil et acceptez une commande.';

  @override
  String get providerJobsEmptyCompleted =>
      'Vous n\'avez pas encore de tâches terminées.';

  @override
  String get providerJobsEmptyCancelled =>
      'Vous n\'avez pas encore de tâches annulées.';

  @override
  String scheduledForDate(Object date) {
    return 'Programmé : $date';
  }

  @override
  String get viewDetailsTooltip => 'Afficher les détails';

  @override
  String clientPaidValueLabel(Object value) {
    return 'Client payé : $value';
  }

  @override
  String providerEarningsFeeLabel(Object value, Object fee) {
    return 'Vous recevez : $value - Frais : $fee';
  }

  @override
  String serviceValueLabel(Object value) {
    return 'Valeur du service : $value';
  }

  @override
  String get cancelJobTitle => 'Annuler le travail';

  @override
  String get cancelJobPrompt =>
      'Êtes-vous sûr de vouloir annuler cette tâche ?\\nLa commande peut devenir disponible pour d\'autres fournisseurs.';

  @override
  String get cancelJobReasonLabel => 'Motif d\'annulation (facultatif) :';

  @override
  String get cancelJobReasonFieldLabel => 'Raison';

  @override
  String get cancelJobDetailLabel => 'Détails de l\'annulation';

  @override
  String get cancelJobDetailRequired => 'Veuillez ajouter un détail.';

  @override
  String get cancelJobSuccess => 'Travail annulé.';

  @override
  String cancelJobError(Object error) {
    return 'Erreur lors de l\'annulation de la tâche : $error';
  }

  @override
  String get providerAccountProfileTitle => 'Voir mon profil';

  @override
  String get providerAccountProfileSubtitle => 'Profil du fournisseur';

  @override
  String get activateOnlinePaymentsSubtitle => 'Activer les paiements en ligne';

  @override
  String get statusProviderWaiting => 'Nouvelle demande';

  @override
  String get statusQuoteWaitingCustomer => 'En attente de la réponse du client';

  @override
  String get statusAcceptedToStart => 'Accepté (prêt à démarrer)';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusCompleted => 'Complété';

  @override
  String get orderDefaultImmediateTitle => 'Service urgent';

  @override
  String get locationServiceDisabled =>
      'Le service de localisation est désactivé sur l\'appareil.';

  @override
  String get locationPermissionDenied =>
      'Autorisation de localisation refusée.\\nImpossible d\'obtenir la position actuelle.';

  @override
  String get locationPermissionDeniedForever =>
      'Autorisation de localisation définitivement refusée.\\nActivez la localisation dans les paramètres de l\'appareil.';

  @override
  String locationFetchError(Object error) {
    return 'Erreur lors de l\'obtention de la position : $error';
  }

  @override
  String get formNotReadyError =>
      'Le formulaire n\'est pas encore prêt. Essayer à nouveau.';

  @override
  String get missingRequiredFieldsError =>
      'Les champs obligatoires sont manquants. Vérifiez les champs en rouge.';

  @override
  String get scheduleDateTimeRequiredError =>
      'Choisissez la date et l\'heure du service.';

  @override
  String get scheduleDateTimeFutureError => 'Choisissez une date/heure future.';

  @override
  String get categoryRequiredError => 'Choisissez une catégorie.';

  @override
  String get orderUpdatedSuccess => 'Commande mise à jour avec succès !';

  @override
  String get orderCreatedSuccess =>
      'Commande créée ! A la recherche d\'un prestataire...';

  @override
  String orderUpdateError(Object error) {
    return 'Erreur lors de la mise à jour de la commande : $error';
  }

  @override
  String orderCreateError(Object error) {
    return 'Erreur lors de la création de la commande : $error';
  }

  @override
  String get orderTitleExamplePlumbing =>
      'Ex. : Fuite de plomberie sous l’évier';

  @override
  String get orderTitleExampleElectric =>
      'Ex. : La prise ne fonctionne pas dans le salon + installer un plafonnier';

  @override
  String get orderTitleExampleCleaning =>
      'Ex. : Nettoyage complet d\'un appartement 2 chambres (cuisine, WC, fenêtres, sol).';

  @override
  String get orderTitleHintImmediate =>
      'Expliquez brièvement ce qui se passe et ce dont vous avez besoin.';

  @override
  String get orderTitleHintScheduled =>
      'Dites quand vous souhaitez bénéficier du service, les détails de l\'emplacement et ce qui doit être fait.';

  @override
  String get orderTitleHintQuote =>
      'Décrivez le service pour lequel vous souhaitez recevoir des propositions.';

  @override
  String get orderTitleHintDefault =>
      'Décrivez le service dont vous avez besoin.';

  @override
  String get orderDescriptionExampleCleaning =>
      'Ex. : Nettoyage complet d\'un appartement 2 chambres (cuisine, WC, fenêtres, sol).';

  @override
  String get orderDescriptionHintImmediate =>
      'Expliquez brièvement ce qui se passe et ce dont vous avez besoin.';

  @override
  String get orderDescriptionHintScheduled =>
      'Dites quand vous souhaitez bénéficier du service, les détails de l\'emplacement et ce qui doit être fait.';

  @override
  String get orderDescriptionHintQuote =>
      'Décrivez le service que vous souhaitez, le budget approximatif (si vous en avez un) et les détails importants.';

  @override
  String get orderDescriptionHintDefault =>
      'Expliquez un peu plus en détail ce dont vous avez besoin.';

  @override
  String get priceModelTitle => 'Modèle de prix';

  @override
  String get priceModelQuoteInfo =>
      'Cette prestation se fait sur devis. Le prestataire proposera le prix final.';

  @override
  String get priceTypeLabel => 'Type de prix';

  @override
  String get paymentTypeLabel => 'Type de paiement';

  @override
  String get orderHeaderQuoteTitle => 'Demande de devis';

  @override
  String get orderHeaderQuoteSubtitle =>
      'Décrivez ce dont vous avez besoin et le fournisseur peut envoyer une plage (min/max).';

  @override
  String get orderHeaderImmediateTitle => 'Service immédiat';

  @override
  String get orderHeaderImmediateSubtitle =>
      'Un prestataire disponible sera appelé dans les plus brefs délais.';

  @override
  String get orderHeaderScheduledTitle => 'Service programmé';

  @override
  String get orderHeaderScheduledSubtitle =>
      'Choisissez le jour et l’heure à laquelle le prestataire viendra chez vous.';

  @override
  String get orderHeaderDefaultTitle => 'Nouvelle commande';

  @override
  String get orderHeaderDefaultSubtitle =>
      'Décrivez le service dont vous avez besoin.';

  @override
  String get orderEditTitle => 'Modifier la commande';

  @override
  String get orderNewTitle => 'Nouvelle commande';

  @override
  String get whenServiceNeededLabel => 'Quand avez-vous besoin du service ?';

  @override
  String get categoryLabel => 'Catégorie';

  @override
  String get categoryHint => 'Choisissez la catégorie de service';

  @override
  String get orderTitleLabel => 'Titre de la commande';

  @override
  String get orderTitleRequiredError => 'Écrivez un titre pour la commande.';

  @override
  String get orderDescriptionOptionalLabel => 'Description (facultatif)';

  @override
  String get locationApproxLabel => 'Localisation approximative';

  @override
  String get locationSelectedLabel => 'Emplacement sélectionné.';

  @override
  String get locationSelectPrompt =>
      'Choisissez où le service sera effectué (approximatif).';

  @override
  String get locationAddressHint =>
      'Rue, numéro, étage, référence (facultatif, mais aide beaucoup)';

  @override
  String get locationGetting => 'Obtenir l\'emplacement...';

  @override
  String get locationUseCurrent => 'Utiliser l\'emplacement actuel';

  @override
  String get locationChooseOnMap => 'Choisissez sur la carte';

  @override
  String get serviceDateTimeLabel => 'Date et heure du service';

  @override
  String get serviceDateTimePick => 'Choisissez le jour et l\'heure';

  @override
  String get saveChangesButton => 'Enregistrer les modifications';

  @override
  String get submitOrderButton => 'Demander un service';

  @override
  String get mapSelectTitle => 'Choisissez un emplacement sur la carte';

  @override
  String get mapSelectInstruction =>
      'Faites glisser la carte vers l\'emplacement approximatif du service, puis confirmez.';

  @override
  String get mapSelectConfirm => 'Confirmer l\'emplacement';

  @override
  String get orderDetailsTitle => 'Détails de la commande';

  @override
  String orderLoadError(Object error) {
    return 'Erreur de chargement de l\'ordre : $error';
  }

  @override
  String get orderNotFound => 'Commande introuvable.';

  @override
  String get scheduledNoDate => 'Programmé (aucune date fixée)';

  @override
  String get orderValueRejectedTitle =>
      'Le client a rejeté la valeur proposée.';

  @override
  String get orderValueRejectedBody =>
      'Discutez avec le client et proposez une nouvelle valeur une fois aligné.';

  @override
  String get actionProposeNewValue => 'Proposer une nouvelle valeur';

  @override
  String get noShowReportedTitle => 'Non-présentation signalée';

  @override
  String noShowReportedBy(Object role) {
    return 'Signalé par : $role';
  }

  @override
  String noShowReportedAt(Object date) {
    return 'À : $date';
  }

  @override
  String get noShowTitle => 'Non-présentation';

  @override
  String get noShowDescription =>
      'Si l\'autre personne ne s\'est pas présentée, vous pouvez le signaler.';

  @override
  String get noShowReportAction => 'Signaler une non-présentation';

  @override
  String get orderInfoTitle => 'Informations sur la commande';

  @override
  String get orderInfoIdLabel => 'Numéro de commande';

  @override
  String get orderInfoCreatedAtLabel => 'Créé à';

  @override
  String get orderInfoStatusLabel => 'Statut';

  @override
  String get orderInfoModeLabel => 'Mode';

  @override
  String get orderInfoValueLabel => 'Valeur';

  @override
  String get orderLocationTitle => 'Lieu de commande';

  @override
  String get orderDescriptionTitle => 'Description de la commande';

  @override
  String get providerMessageTitle => 'Message du fournisseur';

  @override
  String get actionEditOrder => 'Modifier la commande';

  @override
  String get actionCancelOrder => 'Annuler la commande';

  @override
  String get cancelOrderTitle => 'Annuler la commande';

  @override
  String get orderCancelInProgressWarning =>
      'Le service est déjà en cours.\nL\'annulation maintenant peut entraîner un remboursement partiel.';

  @override
  String get orderCancelConfirmPrompt =>
      'Êtes-vous sûr de vouloir annuler cette commande ?';

  @override
  String get orderCancelReasonLabel => 'Motif d\'annulation';

  @override
  String get orderCancelReasonOptionalLabel => 'Raison (facultatif)';

  @override
  String orderCancelledSnack(Object message) {
    return 'Commande annulée. $message.';
  }

  @override
  String orderCancelError(Object error) {
    return 'Erreur lors de l\'annulation de la commande : $error';
  }

  @override
  String get noShowReportDialogTitle => 'Signaler une non-présentation';

  @override
  String get noShowReportDialogDescription =>
      'Utilisez-le uniquement si l\'autre personne ne s\'est pas présentée.';

  @override
  String get noShowReasonOptionalLabel => 'Raison (facultatif)';

  @override
  String get actionReport => 'Rapport';

  @override
  String get noShowReportSuccess => 'Non-présentation signalée.';

  @override
  String noShowReportError(Object error) {
    return 'Erreur signalant une non-présentation : $error';
  }

  @override
  String get orderFinalValueTitle => 'Proposer une nouvelle valeur finale';

  @override
  String get orderFinalValueLabel => 'Valeur';

  @override
  String get orderFinalValueInvalid => 'Entrez une valeur valide.';

  @override
  String get orderFinalValueSent => 'Nouvelle valeur envoyée au client.';

  @override
  String orderFinalValueSendError(Object error) {
    return 'Erreur lors de l\'envoi d\'une nouvelle valeur : $error';
  }

  @override
  String get ratingSentTitle => 'Note envoyée';

  @override
  String get ratingProviderTitle => 'Évaluation du fournisseur';

  @override
  String get ratingPrompt => 'Laissez une note de 1 à 5.';

  @override
  String get ratingCommentLabel => 'Commentaire (facultatif)';

  @override
  String get ratingSendAction => 'Envoyer une note';

  @override
  String get ratingSelectError => 'Choisissez une note.';

  @override
  String get ratingSentSnack => 'Note envoyée.';

  @override
  String ratingSendError(Object error) {
    return 'Erreur lors de l\'envoi de la note : $error';
  }

  @override
  String get timelineCreated => 'Créé';

  @override
  String get timelineAccepted => 'Accepté';

  @override
  String get timelineInProgress => 'En cours';

  @override
  String get timelineCancelled => 'Annulé';

  @override
  String get timelineCompleted => 'Complété';

  @override
  String get lookingForProviderBanner =>
      'Nous recherchons toujours un fournisseur pour cette commande.';

  @override
  String get actionView => 'Voir';

  @override
  String get chatNoMessagesSubtitle => 'Pas encore de messages';

  @override
  String chatPreviewWithTime(Object preview, Object time) {
    return '$preview • $time';
  }

  @override
  String chatMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionOpen => 'Ouvrir';

  @override
  String get chatAuthRequired =>
      'Vous devez être authentifié pour envoyer des messages.';

  @override
  String chatSendError(Object error) {
    return 'Erreur lors de l\'envoi du message : $error';
  }

  @override
  String get todayLabel => 'Aujourd\'hui';

  @override
  String get yesterdayLabel => 'Hier';

  @override
  String chatLoadError(Object error) {
    return 'Messages d\'erreur lors du chargement : $error';
  }

  @override
  String get chatEmptyMessage =>
      'Aucun message pour l\'instant.\nEnvoyez le premier !';

  @override
  String get chatInputHint => 'Écrire un message...';

  @override
  String get chatLoginHint => 'Connectez-vous pour envoyer des messages';

  @override
  String get roleLabelSystem => 'Système';

  @override
  String get youLabel => 'Toi';

  @override
  String distanceMeters(Object meters) {
    return '$meters mois';
  }

  @override
  String distanceKilometers(Object kilometers) {
    return '$kilometers km';
  }

  @override
  String get etaLessThanMinute => '<1 minute';

  @override
  String etaMinutes(Object minutes) {
    return '$minutes min';
  }

  @override
  String etaHours(Object hours) {
    return '$hours heures';
  }

  @override
  String etaHoursMinutes(Object hours, Object minutes) {
    return '$hours heures $minutes heures';
  }

  @override
  String mapEtaLabel(Object eta, Object distance) {
    return 'ETA $eta - $distance';
  }

  @override
  String get mapOpenAction => 'Ouvrir la carte';

  @override
  String get orderMapTitle => 'Plan de commande';

  @override
  String get orderChatTitle => 'Discutez de cette commande';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesSearchHint => 'Rechercher des messages';

  @override
  String messagesLoadError(Object error) {
    return 'Erreur lors du chargement des conversations : $error';
  }

  @override
  String get messagesEmpty =>
      'Vous n\'avez encore aucune conversation.\nUne fois que vous aurez discuté avec un fournisseur/client, celui-ci apparaîtra ici.';

  @override
  String get messagesNewConversationTitle => 'Nouvelle conversation';

  @override
  String get messagesNewConversationBody =>
      'Pour démarrer une conversation avec un fournisseur ou un client, rendez-vous dans vos « Commandes » ou acceptez une nouvelle commande.';

  @override
  String get messagesFilterAll => 'Tous';

  @override
  String get messagesFilterUnread => 'Non lu';

  @override
  String get messagesFilterFavorites => 'Favoris';

  @override
  String get messagesFilterGroups => 'Groupes';

  @override
  String messagesFilterEmpty(Object filter) {
    return 'Rien dans \"$filter\"';
  }

  @override
  String get messagesSearchNoResults => 'Aucune conversation trouvée.';

  @override
  String get messagesPinConversation => 'Épingler la conversation';

  @override
  String get messagesUnpinConversation => 'Désépingler la conversation';

  @override
  String get chatPresenceOnline => 'en ligne';

  @override
  String chatPresenceLastSeenAt(Object time) {
    return 'vu pour la dernière fois à $time';
  }

  @override
  String chatPresenceLastSeenYesterdayAt(Object time) {
    return 'vu pour la dernière fois hier à $time';
  }

  @override
  String chatPresenceLastSeenOn(Object date, Object time) {
    return 'vu pour la dernière fois le $date à $time';
  }

  @override
  String get chatImageTooLarge => 'Image trop grande (max 15 Mo).';

  @override
  String chatImageSendError(Object error) {
    return 'Erreur lors de l\'envoi de l\'image : $error';
  }

  @override
  String get chatFileReadError => 'Impossible de lire le fichier.';

  @override
  String get chatFileTooLarge => 'Fichier trop volumineux (max 20 Mo).';

  @override
  String chatFileSendError(Object error) {
    return 'Erreur lors de l\'envoi du fichier : $error';
  }

  @override
  String get chatAudioReadError => 'Impossible de lire l\'audio.';

  @override
  String get chatAudioTooLarge => 'Audio trop volumineux (max 20 Mo).';

  @override
  String chatAudioSendError(Object error) {
    return 'Erreur lors de l\'envoi de l\'audio : $error';
  }

  @override
  String get chatAttachFile => 'Envoyer le fichier';

  @override
  String get chatAttachGallery => 'Envoyer une photo (galerie)';

  @override
  String get chatAttachCamera => 'Prendre une photo (appareil photo)';

  @override
  String get chatAttachAudio => 'Envoyer de l\'audio (fichier)';

  @override
  String get chatAttachAudioSubtitle =>
      'Choisissez un fichier audio (mp3/m4a/wav/...).';

  @override
  String get chatOpenLink => 'Ouvrir le lien';

  @override
  String get chatAttachTooltip => 'Attacher';

  @override
  String get chatSendTooltip => 'Envoyer';

  @override
  String get chatSearchAction => 'Recherche';

  @override
  String get chatSearchHint => 'Rechercher des messages';

  @override
  String get chatSearchEmpty => 'Tapez quelque chose à rechercher.';

  @override
  String get chatSearchNoResults => 'Aucun message trouvé.';

  @override
  String get chatMediaAction => 'Médias, liens et fichiers';

  @override
  String get chatMediaTitle => 'Médias, liens et fichiers';

  @override
  String get chatMediaPhotosTab => 'Photos';

  @override
  String get chatMediaLinksTab => 'Links';

  @override
  String get chatMediaAudioTab => 'Audio';

  @override
  String get chatMediaFilesTab => 'Fichiers';

  @override
  String get chatMediaEmptyPhotos => 'Pas encore de photos.';

  @override
  String get chatMediaEmptyLinks => 'Pas encore de liens.';

  @override
  String get chatMediaEmptyAudio => 'Pas encore de son.';

  @override
  String get chatMediaEmptyFiles => 'Aucun fichier pour l\'instant.';

  @override
  String get chatFavoritesAction => 'Favoris';

  @override
  String get chatFavoritesTitle => 'Messages favoris';

  @override
  String get chatFavoritesEmpty =>
      'Vous n\'avez pas encore de messages favoris.';

  @override
  String get chatStarAction => 'Ajouter aux favoris';

  @override
  String get chatUnstarAction => 'Supprimer des favoris';

  @override
  String get chatViewProviderProfileAction =>
      'Afficher le profil du fournisseur';

  @override
  String get chatViewCustomerProfileAction => 'Afficher le profil du client';

  @override
  String get chatIncomingCall => 'Appel entrant';

  @override
  String get chatCallStartedVideo => 'Appel vidéo démarré';

  @override
  String get chatCallStartedVoice => 'Appel vocal démarré';

  @override
  String get chatImageLabel => 'Image';

  @override
  String get chatAudioLabel => 'Audio';

  @override
  String get chatFileLabel => 'Déposer';

  @override
  String get chatCallEntryLabel => 'Appel';

  @override
  String get chatNoSession =>
      'Aucune session active. Connectez-vous pour accéder au chat.';

  @override
  String get chatTitleFallback => 'Chat';

  @override
  String get chatVideoCallAction => 'Appel vidéo';

  @override
  String get chatVoiceCallAction => 'Appel';

  @override
  String get chatMarkReadAction => 'Marquer comme lu';

  @override
  String get chatCallMissingParticipant =>
      'L\'autre participant n\'est pas encore affecté à cette commande.';

  @override
  String get chatCallStartError => 'Impossible de démarrer l\'appel.';

  @override
  String chatCallMessageVideo(Object url) {
    return 'Appel vidéo : $url';
  }

  @override
  String chatCallMessageVoice(Object url) {
    return 'Appel : $url';
  }

  @override
  String get profileProviderTitle => 'Profil du fournisseur';

  @override
  String get profileCustomerTitle => 'Profil client';

  @override
  String get profileAboutTitle => 'À propos';

  @override
  String get profileLocationTitle => 'Emplacement';

  @override
  String get profileServicesTitle => 'Services';

  @override
  String get profilePortfolioTitle => 'Portefeuille';

  @override
  String get chatOpenFullAction => 'Ouvrir le chat complet';

  @override
  String get chatOpenFullUnavailable =>
      'L\'autre participant n\'est pas encore affecté à cette commande.';

  @override
  String get chatReplyAction => 'Répondre';

  @override
  String get chatCopyAction => 'Copie';

  @override
  String get chatDeleteAction => 'Supprimer';

  @override
  String get storyNewTitle => 'Nouvelle histoire';

  @override
  String get storyPublishing => 'Histoire de publication...';

  @override
  String get storyPublished => 'Histoire publiée ! Expire dans 24h.';

  @override
  String storyPublishError(Object error) {
    return 'Erreur de publication de l\'histoire : $error';
  }

  @override
  String get storyCaptionHint => 'Légende (facultatif)';

  @override
  String get actionPublish => 'Publier';

  @override
  String get snackOrderRemoved => 'Commande supprimée.';

  @override
  String get snackClientCancelledOrder => 'Le client a annulé la commande.';

  @override
  String get snackOrderCancelled => 'Commande annulée.';

  @override
  String get snackOrderAcceptedByAnother =>
      'Un autre fournisseur a accepté la commande.';

  @override
  String get snackOrderUpdated => 'Commande mise à jour.';

  @override
  String get snackUserNotAuthenticated => 'Utilisateur non authentifié.';

  @override
  String get snackOrderAcceptedCanQuote =>
      'Commande acceptée. Vous pouvez envoyer le devis dans les détails de la commande.';

  @override
  String get snackOrderAcceptedSuccess => 'Commande acceptée.';

  @override
  String snackErrorAcceptingOrder(Object error) {
    return 'Erreur lors de l\'acceptation de la commande : $error';
  }

  @override
  String get dialogTitleOrderAccepted => 'Commande acceptée';

  @override
  String get dialogContentQuotePrompt =>
      'Cette commande se fait sur devis.\n\nVoulez-vous envoyer la fourchette de devis maintenant ?';

  @override
  String get dialogTitleProposeService => 'Proposer une prestation';

  @override
  String get dialogContentProposeService =>
      'Fixez une fourchette de prix pour ce service.\nIncluez les déplacements et la main d’œuvre.';

  @override
  String get labelMinValue => 'Valeur minimale';

  @override
  String get labelMaxValue => 'Valeur maximale';

  @override
  String get labelMessageOptional => 'Message au client (facultatif)';

  @override
  String hintExampleValue(Object value) {
    return 'Ex. : $value';
  }

  @override
  String get hintProposalMessage =>
      'Ex. : Comprend les déplacements. Les gros matériaux sont en sus.';

  @override
  String get snackFillValidValues =>
      'Entrez des valeurs minimales et maximales valides.';

  @override
  String get snackMinCannotBeGreaterThanMax =>
      'Le minimum ne peut pas être supérieur au maximum.';

  @override
  String get snackProposalSent => 'Proposition envoyée au client.';

  @override
  String snackErrorSendingProposal(Object error) {
    return 'Erreur lors de l\'envoi de la proposition : $error';
  }
}
