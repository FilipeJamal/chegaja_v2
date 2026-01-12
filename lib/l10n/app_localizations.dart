import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ChegaJa'**
  String get appTitle;

  /// No description provided for @roleSelectorWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ChegaJa'**
  String get roleSelectorWelcome;

  /// No description provided for @roleSelectorPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to use the app:'**
  String get roleSelectorPrompt;

  /// No description provided for @roleCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m a customer'**
  String get roleCustomerTitle;

  /// No description provided for @roleCustomerDescription.
  ///
  /// In en, this message translates to:
  /// **'I want to find service providers near me.'**
  String get roleCustomerDescription;

  /// No description provided for @roleProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'I\'m a provider'**
  String get roleProviderTitle;

  /// No description provided for @roleProviderDescription.
  ///
  /// In en, this message translates to:
  /// **'I want to receive customer requests and earn more.'**
  String get roleProviderDescription;

  /// No description provided for @invalidSession.
  ///
  /// In en, this message translates to:
  /// **'Invalid session.'**
  String get invalidSession;

  /// No description provided for @paymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments (Stripe)'**
  String get paymentsTitle;

  /// No description provided for @paymentsHeading.
  ///
  /// In en, this message translates to:
  /// **'Receive online payments'**
  String get paymentsHeading;

  /// No description provided for @paymentsDescription.
  ///
  /// In en, this message translates to:
  /// **'To receive payments via the app, you need to create a Stripe account (Connect Express).\nThe onboarding opens in your browser and takes 2–3 minutes.'**
  String get paymentsDescription;

  /// No description provided for @paymentsActive.
  ///
  /// In en, this message translates to:
  /// **'Online payments ACTIVE.'**
  String get paymentsActive;

  /// No description provided for @paymentsInactive.
  ///
  /// In en, this message translates to:
  /// **'Online payments are not active yet. Complete onboarding.'**
  String get paymentsInactive;

  /// No description provided for @stripeAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Stripe account: {accountId}'**
  String stripeAccountLabel(Object accountId);

  /// No description provided for @onboardingOpened.
  ///
  /// In en, this message translates to:
  /// **'Onboarding opened. After finishing, come back to check the status.'**
  String get onboardingOpened;

  /// No description provided for @onboardingStartError.
  ///
  /// In en, this message translates to:
  /// **'Error starting onboarding: {error}'**
  String onboardingStartError(Object error);

  /// No description provided for @manageStripeAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage Stripe account'**
  String get manageStripeAccount;

  /// No description provided for @activatePayments.
  ///
  /// In en, this message translates to:
  /// **'Activate payments'**
  String get activatePayments;

  /// No description provided for @technicalNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical notes'**
  String get technicalNotesTitle;

  /// No description provided for @technicalNotesBody.
  ///
  /// In en, this message translates to:
  /// **'• Stripe is configured via Cloud Functions (server-side).\n• The platform commission is applied automatically in the PaymentIntent.\n• In production, add the Stripe webhook and store the webhook secret in Functions.'**
  String get technicalNotesBody;

  /// No description provided for @kycTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity verification: {status}'**
  String kycTitle(Object status);

  /// No description provided for @kycDescription.
  ///
  /// In en, this message translates to:
  /// **'Send a document (photo or PDF). Full validation comes in v2.6.'**
  String get kycDescription;

  /// No description provided for @kycSendDocument.
  ///
  /// In en, this message translates to:
  /// **'Send document'**
  String get kycSendDocument;

  /// No description provided for @kycAddDocument.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get kycAddDocument;

  /// No description provided for @kycStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get kycStatusApproved;

  /// No description provided for @kycStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get kycStatusRejected;

  /// No description provided for @kycStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get kycStatusInReview;

  /// No description provided for @kycStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get kycStatusNotStarted;

  /// No description provided for @kycFileReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file.'**
  String get kycFileReadError;

  /// No description provided for @kycFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large (max. 10MB).'**
  String get kycFileTooLarge;

  /// No description provided for @kycUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading document...'**
  String get kycUploading;

  /// No description provided for @kycUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Document sent for review.'**
  String get kycUploadSuccess;

  /// No description provided for @kycUploadError.
  ///
  /// In en, this message translates to:
  /// **'Error sending document: {error}'**
  String kycUploadError(Object error);

  /// No description provided for @statusCancelledByYou.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by you'**
  String get statusCancelledByYou;

  /// No description provided for @statusCancelledByProvider.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by provider'**
  String get statusCancelledByProvider;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusLookingForProvider.
  ///
  /// In en, this message translates to:
  /// **'Looking for provider'**
  String get statusLookingForProvider;

  /// No description provided for @statusProviderPreparingQuote.
  ///
  /// In en, this message translates to:
  /// **'Provider found (preparing quote)'**
  String get statusProviderPreparingQuote;

  /// No description provided for @statusQuoteToDecide.
  ///
  /// In en, this message translates to:
  /// **'You have a quote to decide'**
  String get statusQuoteToDecide;

  /// No description provided for @statusProviderFound.
  ///
  /// In en, this message translates to:
  /// **'Provider found'**
  String get statusProviderFound;

  /// No description provided for @statusServiceInProgress.
  ///
  /// In en, this message translates to:
  /// **'Service in progress'**
  String get statusServiceInProgress;

  /// No description provided for @statusAwaitingValueConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting your value confirmation'**
  String get statusAwaitingValueConfirmation;

  /// No description provided for @statusServiceCompleted.
  ///
  /// In en, this message translates to:
  /// **'Service completed'**
  String get statusServiceCompleted;

  /// No description provided for @valueToConfirm.
  ///
  /// In en, this message translates to:
  /// **'{value} (to confirm)'**
  String valueToConfirm(Object value);

  /// No description provided for @valueProposed.
  ///
  /// In en, this message translates to:
  /// **'{value} (proposed)'**
  String valueProposed(Object value);

  /// No description provided for @valueEstimatedRange.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max} (estimated)'**
  String valueEstimatedRange(Object min, Object max);

  /// No description provided for @valueEstimatedFrom.
  ///
  /// In en, this message translates to:
  /// **'From {min} (estimated)'**
  String valueEstimatedFrom(Object min);

  /// No description provided for @valueEstimatedUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} (estimated)'**
  String valueEstimatedUpTo(Object max);

  /// No description provided for @valueUnknown.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get valueUnknown;

  /// No description provided for @priceFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed price'**
  String get priceFixed;

  /// No description provided for @priceByQuote.
  ///
  /// In en, this message translates to:
  /// **'By quote'**
  String get priceByQuote;

  /// No description provided for @priceToArrange.
  ///
  /// In en, this message translates to:
  /// **'To be arranged'**
  String get priceToArrange;

  /// No description provided for @paymentOnlineBefore.
  ///
  /// In en, this message translates to:
  /// **'Online payment (before)'**
  String get paymentOnlineBefore;

  /// No description provided for @paymentOnlineAfter.
  ///
  /// In en, this message translates to:
  /// **'Online payment (after)'**
  String get paymentOnlineAfter;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash payment'**
  String get paymentCash;

  /// No description provided for @pendingActionQuoteToReview.
  ///
  /// In en, this message translates to:
  /// **'You have a quote/proposal to review.'**
  String get pendingActionQuoteToReview;

  /// No description provided for @pendingActionValueToConfirm.
  ///
  /// In en, this message translates to:
  /// **'The provider sent the final value. You need to confirm.'**
  String get pendingActionValueToConfirm;

  /// No description provided for @pendingActionProviderPreparingQuote.
  ///
  /// In en, this message translates to:
  /// **'Provider found. They are preparing the quote.'**
  String get pendingActionProviderPreparingQuote;

  /// No description provided for @pendingActionProviderChat.
  ///
  /// In en, this message translates to:
  /// **'Provider found. You can chat with them.'**
  String get pendingActionProviderChat;

  /// No description provided for @roleLabelCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleLabelCustomer;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMyOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get navMyOrders;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What do you need today?'**
  String get homeSubtitle;

  /// No description provided for @homePendingTitle.
  ///
  /// In en, this message translates to:
  /// **'You have something to decide'**
  String get homePendingTitle;

  /// No description provided for @homePendingCta.
  ///
  /// In en, this message translates to:
  /// **'Tap here to open the next order and decide.'**
  String get homePendingCta;

  /// No description provided for @servicesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading services: {error}'**
  String servicesLoadError(Object error);

  /// No description provided for @servicesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No services configured yet.\\nYou\'ll see categories here soon 🙂'**
  String get servicesEmptyMessage;

  /// No description provided for @availableServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Available services'**
  String get availableServicesTitle;

  /// No description provided for @serviceTabImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get serviceTabImmediate;

  /// No description provided for @serviceTabScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get serviceTabScheduled;

  /// No description provided for @serviceTabQuote.
  ///
  /// In en, this message translates to:
  /// **'By quote'**
  String get serviceTabQuote;

  /// No description provided for @unreadMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'You have new messages'**
  String get unreadMessagesTitle;

  /// No description provided for @unreadMessagesCta.
  ///
  /// In en, this message translates to:
  /// **'Tap here to open the chat.'**
  String get unreadMessagesCta;

  /// No description provided for @serviceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search service...'**
  String get serviceSearchHint;

  /// No description provided for @serviceSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No services found for this search.'**
  String get serviceSearchEmpty;

  /// No description provided for @serviceModeImmediateDescription.
  ///
  /// In en, this message translates to:
  /// **'A provider comes today as quickly as possible.'**
  String get serviceModeImmediateDescription;

  /// No description provided for @serviceModeScheduledDescription.
  ///
  /// In en, this message translates to:
  /// **'Schedule a day and time for the service.'**
  String get serviceModeScheduledDescription;

  /// No description provided for @serviceModeQuoteDescription.
  ///
  /// In en, this message translates to:
  /// **'Request a quote (provider sends a min/max range).'**
  String get serviceModeQuoteDescription;

  /// No description provided for @userNotAuthenticatedError.
  ///
  /// In en, this message translates to:
  /// **'Error: user not authenticated.'**
  String get userNotAuthenticatedError;

  /// No description provided for @myOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get myOrdersTitle;

  /// No description provided for @ordersTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ordersTabPending;

  /// No description provided for @ordersTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get ordersTabCompleted;

  /// No description provided for @ordersTabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get ordersTabCancelled;

  /// No description provided for @ordersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading orders: {error}'**
  String ordersLoadError(Object error);

  /// No description provided for @ordersEmptyPending.
  ///
  /// In en, this message translates to:
  /// **'You have no pending orders.\\nCreate a new order from Home.'**
  String get ordersEmptyPending;

  /// No description provided for @ordersEmptyCompleted.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have completed orders yet.'**
  String get ordersEmptyCompleted;

  /// No description provided for @ordersEmptyCancelled.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have cancelled orders yet.'**
  String get ordersEmptyCancelled;

  /// No description provided for @orderQuoteScheduled.
  ///
  /// In en, this message translates to:
  /// **'Quote (scheduled)'**
  String get orderQuoteScheduled;

  /// No description provided for @orderQuoteImmediate.
  ///
  /// In en, this message translates to:
  /// **'Quote (immediate)'**
  String get orderQuoteImmediate;

  /// No description provided for @orderScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled service'**
  String get orderScheduled;

  /// No description provided for @orderImmediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate service'**
  String get orderImmediate;

  /// No description provided for @categoryNotDefined.
  ///
  /// In en, this message translates to:
  /// **'Category not defined'**
  String get categoryNotDefined;

  /// No description provided for @orderStateLabel.
  ///
  /// In en, this message translates to:
  /// **'State: {state}'**
  String orderStateLabel(Object state);

  /// No description provided for @orderPriceModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Price model: {model}'**
  String orderPriceModelLabel(Object model);

  /// No description provided for @orderPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment: {payment}'**
  String orderPaymentLabel(Object payment);

  /// No description provided for @orderValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value: {value}'**
  String orderValueLabel(Object value);

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account ({role})'**
  String accountTitle(Object role);

  /// No description provided for @accountNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get accountNameTitle;

  /// No description provided for @accountProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get accountProfileSubtitle;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountSettings;

  /// No description provided for @accountHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help and support'**
  String get accountHelpSupport;

  /// No description provided for @navMyJobs.
  ///
  /// In en, this message translates to:
  /// **'My Jobs'**
  String get navMyJobs;

  /// No description provided for @roleLabelProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get roleLabelProvider;

  /// No description provided for @enableLocationToGoOnline.
  ///
  /// In en, this message translates to:
  /// **'Enable location to go online.'**
  String get enableLocationToGoOnline;

  /// No description provided for @nearbyOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders near you'**
  String get nearbyOrdersTitle;

  /// No description provided for @noOrdersAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'No orders available right now.'**
  String get noOrdersAvailableMessage;

  /// No description provided for @configureServiceAreaMessage.
  ///
  /// In en, this message translates to:
  /// **'Set your service area and services to start receiving orders.'**
  String get configureServiceAreaMessage;

  /// No description provided for @configureAction.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get configureAction;

  /// No description provided for @offlineEnableOnlineMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Enable online status to receive orders.'**
  String get offlineEnableOnlineMessage;

  /// No description provided for @noMatchingOrdersMessage.
  ///
  /// In en, this message translates to:
  /// **'No matching orders for your services and area.'**
  String get noMatchingOrdersMessage;

  /// No description provided for @orderAcceptedMessage.
  ///
  /// In en, this message translates to:
  /// **'Order accepted.'**
  String get orderAcceptedMessage;

  /// No description provided for @orderAcceptedCanSendQuote.
  ///
  /// In en, this message translates to:
  /// **'Order accepted. You can send the quote later.'**
  String get orderAcceptedCanSendQuote;

  /// No description provided for @orderAcceptError.
  ///
  /// In en, this message translates to:
  /// **'Error accepting order: {error}'**
  String orderAcceptError(Object error);

  /// No description provided for @orderAcceptedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Order accepted'**
  String get orderAcceptedDialogTitle;

  /// No description provided for @orderAcceptedBudgetPrompt.
  ///
  /// In en, this message translates to:
  /// **'This order is by quote.\\n\\nDo you want to send the quote range now?'**
  String get orderAcceptedBudgetPrompt;

  /// No description provided for @actionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get actionLater;

  /// No description provided for @actionSendNow.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get actionSendNow;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get actionSend;

  /// No description provided for @actionIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get actionIgnore;

  /// No description provided for @actionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// No description provided for @actionNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get actionNo;

  /// No description provided for @actionYesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get actionYesCancel;

  /// No description provided for @proposalDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a quote'**
  String get proposalDialogTitle;

  /// No description provided for @proposalDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Set a price range for this service.\\nInclude travel and labor.'**
  String get proposalDialogDescription;

  /// No description provided for @proposalMinValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum value ({currency})'**
  String proposalMinValueLabel(Object currency);

  /// No description provided for @proposalMinValueHint.
  ///
  /// In en, this message translates to:
  /// **'Ex.: 20'**
  String get proposalMinValueHint;

  /// No description provided for @proposalMaxValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum value ({currency})'**
  String proposalMaxValueLabel(Object currency);

  /// No description provided for @proposalMaxValueHint.
  ///
  /// In en, this message translates to:
  /// **'Ex.: 35'**
  String get proposalMaxValueHint;

  /// No description provided for @proposalMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message to the customer (optional)'**
  String get proposalMessageLabel;

  /// No description provided for @proposalMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Ex.: Includes travel. Large materials are extra.'**
  String get proposalMessageHint;

  /// No description provided for @proposalInvalidValues.
  ///
  /// In en, this message translates to:
  /// **'Enter valid minimum and maximum values.'**
  String get proposalInvalidValues;

  /// No description provided for @proposalMinGreaterThanMax.
  ///
  /// In en, this message translates to:
  /// **'The minimum can\'t be greater than the maximum.'**
  String get proposalMinGreaterThanMax;

  /// No description provided for @proposalSent.
  ///
  /// In en, this message translates to:
  /// **'Proposal sent to the customer.'**
  String get proposalSent;

  /// No description provided for @proposalSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending proposal: {error}'**
  String proposalSendError(Object error);

  /// No description provided for @providerHomeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, provider'**
  String get providerHomeGreeting;

  /// No description provided for @providerHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Go online to receive new orders.'**
  String get providerHomeSubtitle;

  /// No description provided for @providerStatusOnline.
  ///
  /// In en, this message translates to:
  /// **'You\'re ONLINE'**
  String get providerStatusOnline;

  /// No description provided for @providerStatusOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re OFFLINE'**
  String get providerStatusOffline;

  /// No description provided for @providerKpiEarningsToday.
  ///
  /// In en, this message translates to:
  /// **'Earnings today (net)'**
  String get providerKpiEarningsToday;

  /// No description provided for @providerKpiServicesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Services this month'**
  String get providerKpiServicesThisMonth;

  /// No description provided for @providerKpiGrossFeeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gross: {gross} - Fee: {fee}'**
  String providerKpiGrossFeeSubtitle(Object gross, Object fee);

  /// No description provided for @providerHighlightTitle.
  ///
  /// In en, this message translates to:
  /// **'You have a job to manage'**
  String get providerHighlightTitle;

  /// No description provided for @providerHighlightCta.
  ///
  /// In en, this message translates to:
  /// **'Tap here to open the next job.'**
  String get providerHighlightCta;

  /// No description provided for @providerPendingActionAccepted.
  ///
  /// In en, this message translates to:
  /// **'You have an accepted job, ready to start.'**
  String get providerPendingActionAccepted;

  /// No description provided for @providerPendingActionInProgress.
  ///
  /// In en, this message translates to:
  /// **'You have a job in progress. Mark it completed when you finish.'**
  String get providerPendingActionInProgress;

  /// No description provided for @providerPendingActionSetFinalValue.
  ///
  /// In en, this message translates to:
  /// **'Set and send the final service value.'**
  String get providerPendingActionSetFinalValue;

  /// No description provided for @providerUnreadMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'You have new messages from customers'**
  String get providerUnreadMessagesTitle;

  /// No description provided for @providerUnreadMessagesJob.
  ///
  /// In en, this message translates to:
  /// **'In job: {jobTitle}'**
  String providerUnreadMessagesJob(Object jobTitle);

  /// No description provided for @providerJobsTitle.
  ///
  /// In en, this message translates to:
  /// **'My jobs'**
  String get providerJobsTitle;

  /// No description provided for @providerJobsTabOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get providerJobsTabOpen;

  /// No description provided for @providerJobsTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get providerJobsTabCompleted;

  /// No description provided for @providerJobsTabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get providerJobsTabCancelled;

  /// No description provided for @providerJobsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading jobs: {error}'**
  String providerJobsLoadError(Object error);

  /// No description provided for @providerJobsEmptyOpen.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have open jobs yet.\\nGo to Home and accept an order.'**
  String get providerJobsEmptyOpen;

  /// No description provided for @providerJobsEmptyCompleted.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have completed jobs yet.'**
  String get providerJobsEmptyCompleted;

  /// No description provided for @providerJobsEmptyCancelled.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have cancelled jobs yet.'**
  String get providerJobsEmptyCancelled;

  /// No description provided for @scheduledForDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled: {date}'**
  String scheduledForDate(Object date);

  /// No description provided for @viewDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetailsTooltip;

  /// No description provided for @clientPaidValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer paid: {value}'**
  String clientPaidValueLabel(Object value);

  /// No description provided for @providerEarningsFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'You receive: {value} - Fee: {fee}'**
  String providerEarningsFeeLabel(Object value, Object fee);

  /// No description provided for @serviceValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Service value: {value}'**
  String serviceValueLabel(Object value);

  /// No description provided for @cancelJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel job'**
  String get cancelJobTitle;

  /// No description provided for @cancelJobPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this job?\\nThe order may become available to other providers.'**
  String get cancelJobPrompt;

  /// No description provided for @cancelJobReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason (optional):'**
  String get cancelJobReasonLabel;

  /// No description provided for @cancelJobReasonFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get cancelJobReasonFieldLabel;

  /// No description provided for @cancelJobSuccess.
  ///
  /// In en, this message translates to:
  /// **'Job cancelled.'**
  String get cancelJobSuccess;

  /// No description provided for @cancelJobError.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling job: {error}'**
  String cancelJobError(Object error);

  /// No description provided for @providerAccountProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'View my profile'**
  String get providerAccountProfileTitle;

  /// No description provided for @providerAccountProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provider profile'**
  String get providerAccountProfileSubtitle;

  /// No description provided for @activateOnlinePaymentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable online payments'**
  String get activateOnlinePaymentsSubtitle;

  /// No description provided for @statusProviderWaiting.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get statusProviderWaiting;

  /// No description provided for @statusQuoteWaitingCustomer.
  ///
  /// In en, this message translates to:
  /// **'Waiting for customer response'**
  String get statusQuoteWaitingCustomer;

  /// No description provided for @statusAcceptedToStart.
  ///
  /// In en, this message translates to:
  /// **'Accepted (ready to start)'**
  String get statusAcceptedToStart;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @orderDefaultImmediateTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent service'**
  String get orderDefaultImmediateTitle;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service is disabled on the device.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.\\nCouldn\'t get the current location.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied.\\nEnable location in device settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @locationFetchError.
  ///
  /// In en, this message translates to:
  /// **'Error getting location: {error}'**
  String locationFetchError(Object error);

  /// No description provided for @formNotReadyError.
  ///
  /// In en, this message translates to:
  /// **'The form isn\'t ready yet. Try again.'**
  String get formNotReadyError;

  /// No description provided for @missingRequiredFieldsError.
  ///
  /// In en, this message translates to:
  /// **'Required fields are missing. Check the fields in red.'**
  String get missingRequiredFieldsError;

  /// No description provided for @scheduleDateTimeRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Choose the service date and time.'**
  String get scheduleDateTimeRequiredError;

  /// No description provided for @scheduleDateTimeFutureError.
  ///
  /// In en, this message translates to:
  /// **'Choose a future date/time.'**
  String get scheduleDateTimeFutureError;

  /// No description provided for @categoryRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Choose a category.'**
  String get categoryRequiredError;

  /// No description provided for @orderUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order updated successfully!'**
  String get orderUpdatedSuccess;

  /// No description provided for @orderCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order created! Looking for a provider...'**
  String get orderCreatedSuccess;

  /// No description provided for @orderUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating order: {error}'**
  String orderUpdateError(Object error);

  /// No description provided for @orderCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error creating order: {error}'**
  String orderCreateError(Object error);

  /// No description provided for @orderTitleExamplePlumbing.
  ///
  /// In en, this message translates to:
  /// **'Ex.: Plumbing leak under the sink'**
  String get orderTitleExamplePlumbing;

  /// No description provided for @orderTitleExampleElectric.
  ///
  /// In en, this message translates to:
  /// **'Ex.: Outlet doesn\'t work in the living room + install ceiling light'**
  String get orderTitleExampleElectric;

  /// No description provided for @orderTitleExampleCleaning.
  ///
  /// In en, this message translates to:
  /// **'Ex.: Full cleaning of a 2-bedroom apartment (kitchen, WC, windows, floor).'**
  String get orderTitleExampleCleaning;

  /// No description provided for @orderTitleHintImmediate.
  ///
  /// In en, this message translates to:
  /// **'Briefly explain what\'s happening and what you need.'**
  String get orderTitleHintImmediate;

  /// No description provided for @orderTitleHintScheduled.
  ///
  /// In en, this message translates to:
  /// **'Say when you want the service, location details, and what needs to be done.'**
  String get orderTitleHintScheduled;

  /// No description provided for @orderTitleHintQuote.
  ///
  /// In en, this message translates to:
  /// **'Describe the service you want to receive proposals for.'**
  String get orderTitleHintQuote;

  /// No description provided for @orderTitleHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Describe the service you need.'**
  String get orderTitleHintDefault;

  /// No description provided for @orderDescriptionExampleCleaning.
  ///
  /// In en, this message translates to:
  /// **'Ex.: Full cleaning of a 2-bedroom apartment (kitchen, WC, windows, floor).'**
  String get orderDescriptionExampleCleaning;

  /// No description provided for @orderDescriptionHintImmediate.
  ///
  /// In en, this message translates to:
  /// **'Briefly explain what\'s happening and what you need.'**
  String get orderDescriptionHintImmediate;

  /// No description provided for @orderDescriptionHintScheduled.
  ///
  /// In en, this message translates to:
  /// **'Say when you want the service, location details, and what needs to be done.'**
  String get orderDescriptionHintScheduled;

  /// No description provided for @orderDescriptionHintQuote.
  ///
  /// In en, this message translates to:
  /// **'Describe the service you want, approximate budget (if you have one), and important details.'**
  String get orderDescriptionHintQuote;

  /// No description provided for @orderDescriptionHintDefault.
  ///
  /// In en, this message translates to:
  /// **'Explain in a bit more detail what you need.'**
  String get orderDescriptionHintDefault;

  /// No description provided for @priceModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Price model'**
  String get priceModelTitle;

  /// No description provided for @priceModelQuoteInfo.
  ///
  /// In en, this message translates to:
  /// **'This service is by quote. The provider will propose the final price.'**
  String get priceModelQuoteInfo;

  /// No description provided for @priceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Price type'**
  String get priceTypeLabel;

  /// No description provided for @paymentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment type'**
  String get paymentTypeLabel;

  /// No description provided for @orderHeaderQuoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Quote request'**
  String get orderHeaderQuoteTitle;

  /// No description provided for @orderHeaderQuoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need and the provider can send a range (min/max).'**
  String get orderHeaderQuoteSubtitle;

  /// No description provided for @orderHeaderImmediateTitle.
  ///
  /// In en, this message translates to:
  /// **'Immediate service'**
  String get orderHeaderImmediateTitle;

  /// No description provided for @orderHeaderImmediateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An available provider will be called as soon as possible.'**
  String get orderHeaderImmediateSubtitle;

  /// No description provided for @orderHeaderScheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled service'**
  String get orderHeaderScheduledTitle;

  /// No description provided for @orderHeaderScheduledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the day and time for the provider to come to you.'**
  String get orderHeaderScheduledSubtitle;

  /// No description provided for @orderHeaderDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get orderHeaderDefaultTitle;

  /// No description provided for @orderHeaderDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe the service you need.'**
  String get orderHeaderDefaultSubtitle;

  /// No description provided for @orderEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit order'**
  String get orderEditTitle;

  /// No description provided for @orderNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get orderNewTitle;

  /// No description provided for @whenServiceNeededLabel.
  ///
  /// In en, this message translates to:
  /// **'When do you need the service?'**
  String get whenServiceNeededLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the service category'**
  String get categoryHint;

  /// No description provided for @orderTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Order title'**
  String get orderTitleLabel;

  /// No description provided for @orderTitleRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Write a title for the order.'**
  String get orderTitleRequiredError;

  /// No description provided for @orderDescriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get orderDescriptionOptionalLabel;

  /// No description provided for @locationApproxLabel.
  ///
  /// In en, this message translates to:
  /// **'Approximate location'**
  String get locationApproxLabel;

  /// No description provided for @locationSelectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Location selected.'**
  String get locationSelectedLabel;

  /// No description provided for @locationSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose where the service will be performed (approximate).'**
  String get locationSelectPrompt;

  /// No description provided for @locationAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Street, number, floor, reference (optional, but helps a lot)'**
  String get locationAddressHint;

  /// No description provided for @locationGetting.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get locationGetting;

  /// No description provided for @locationUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get locationUseCurrent;

  /// No description provided for @locationChooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get locationChooseOnMap;

  /// No description provided for @serviceDateTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Service date and time'**
  String get serviceDateTimeLabel;

  /// No description provided for @serviceDateTimePick.
  ///
  /// In en, this message translates to:
  /// **'Choose day and time'**
  String get serviceDateTimePick;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChangesButton;

  /// No description provided for @submitOrderButton.
  ///
  /// In en, this message translates to:
  /// **'Request service'**
  String get submitOrderButton;

  /// No description provided for @mapSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose location on map'**
  String get mapSelectTitle;

  /// No description provided for @mapSelectInstruction.
  ///
  /// In en, this message translates to:
  /// **'Drag the map to the approximate service location, then confirm.'**
  String get mapSelectInstruction;

  /// No description provided for @mapSelectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get mapSelectConfirm;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetailsTitle;

  /// No description provided for @orderLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading order: {error}'**
  String orderLoadError(Object error);

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get orderNotFound;

  /// No description provided for @scheduledNoDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled (no date set)'**
  String get scheduledNoDate;

  /// No description provided for @orderValueRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'The customer rejected the proposed value.'**
  String get orderValueRejectedTitle;

  /// No description provided for @orderValueRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Chat with the customer and propose a new value when aligned.'**
  String get orderValueRejectedBody;

  /// No description provided for @actionProposeNewValue.
  ///
  /// In en, this message translates to:
  /// **'Propose new value'**
  String get actionProposeNewValue;

  /// No description provided for @noShowReportedTitle.
  ///
  /// In en, this message translates to:
  /// **'No-show reported'**
  String get noShowReportedTitle;

  /// No description provided for @noShowReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by: {role}'**
  String noShowReportedBy(Object role);

  /// No description provided for @noShowReportedAt.
  ///
  /// In en, this message translates to:
  /// **'At: {date}'**
  String noShowReportedAt(Object date);

  /// No description provided for @noShowTitle.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get noShowTitle;

  /// No description provided for @noShowDescription.
  ///
  /// In en, this message translates to:
  /// **'If the other person didn\'t show up, you can report it.'**
  String get noShowDescription;

  /// No description provided for @noShowReportAction.
  ///
  /// In en, this message translates to:
  /// **'Report no-show'**
  String get noShowReportAction;

  /// No description provided for @orderInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Order information'**
  String get orderInfoTitle;

  /// No description provided for @orderInfoIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderInfoIdLabel;

  /// No description provided for @orderInfoCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get orderInfoCreatedAtLabel;

  /// No description provided for @orderInfoStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get orderInfoStatusLabel;

  /// No description provided for @orderInfoModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get orderInfoModeLabel;

  /// No description provided for @orderInfoValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get orderInfoValueLabel;

  /// No description provided for @orderLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Order location'**
  String get orderLocationTitle;

  /// No description provided for @orderDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Order description'**
  String get orderDescriptionTitle;

  /// No description provided for @providerMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider message'**
  String get providerMessageTitle;

  /// No description provided for @actionEditOrder.
  ///
  /// In en, this message translates to:
  /// **'Edit order'**
  String get actionEditOrder;

  /// No description provided for @actionCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get actionCancelOrder;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrderTitle;

  /// No description provided for @orderCancelInProgressWarning.
  ///
  /// In en, this message translates to:
  /// **'The service is already in progress.\nCanceling now may result in a partial refund.'**
  String get orderCancelInProgressWarning;

  /// No description provided for @orderCancelConfirmPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get orderCancelConfirmPrompt;

  /// No description provided for @orderCancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get orderCancelReasonLabel;

  /// No description provided for @orderCancelReasonOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get orderCancelReasonOptionalLabel;

  /// No description provided for @orderCancelledSnack.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled. {message}.'**
  String orderCancelledSnack(Object message);

  /// No description provided for @orderCancelError.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling order: {error}'**
  String orderCancelError(Object error);

  /// No description provided for @noShowReportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Report no-show'**
  String get noShowReportDialogTitle;

  /// No description provided for @noShowReportDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Use this only if the other person didn\'t show up.'**
  String get noShowReportDialogDescription;

  /// No description provided for @noShowReasonOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get noShowReasonOptionalLabel;

  /// No description provided for @actionReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get actionReport;

  /// No description provided for @noShowReportSuccess.
  ///
  /// In en, this message translates to:
  /// **'No-show reported.'**
  String get noShowReportSuccess;

  /// No description provided for @noShowReportError.
  ///
  /// In en, this message translates to:
  /// **'Error reporting no-show: {error}'**
  String noShowReportError(Object error);

  /// No description provided for @orderFinalValueTitle.
  ///
  /// In en, this message translates to:
  /// **'Propose new final value'**
  String get orderFinalValueTitle;

  /// No description provided for @orderFinalValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get orderFinalValueLabel;

  /// No description provided for @orderFinalValueInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid value.'**
  String get orderFinalValueInvalid;

  /// No description provided for @orderFinalValueSent.
  ///
  /// In en, this message translates to:
  /// **'New value sent to the customer.'**
  String get orderFinalValueSent;

  /// No description provided for @orderFinalValueSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending new value: {error}'**
  String orderFinalValueSendError(Object error);

  /// No description provided for @ratingSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Rating sent'**
  String get ratingSentTitle;

  /// No description provided for @ratingProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider rating'**
  String get ratingProviderTitle;

  /// No description provided for @ratingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Leave a rating from 1 to 5.'**
  String get ratingPrompt;

  /// No description provided for @ratingCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get ratingCommentLabel;

  /// No description provided for @ratingSendAction.
  ///
  /// In en, this message translates to:
  /// **'Send rating'**
  String get ratingSendAction;

  /// No description provided for @ratingSelectError.
  ///
  /// In en, this message translates to:
  /// **'Choose a rating.'**
  String get ratingSelectError;

  /// No description provided for @ratingSentSnack.
  ///
  /// In en, this message translates to:
  /// **'Rating sent.'**
  String get ratingSentSnack;

  /// No description provided for @ratingSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending rating: {error}'**
  String ratingSendError(Object error);

  /// No description provided for @timelineCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get timelineCreated;

  /// No description provided for @timelineAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get timelineAccepted;

  /// No description provided for @timelineInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get timelineInProgress;

  /// No description provided for @timelineCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get timelineCancelled;

  /// No description provided for @timelineCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get timelineCompleted;

  /// No description provided for @lookingForProviderBanner.
  ///
  /// In en, this message translates to:
  /// **'We\'re still looking for a provider for this order.'**
  String get lookingForProviderBanner;

  /// No description provided for @actionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get actionView;

  /// No description provided for @chatNoMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesSubtitle;

  /// No description provided for @chatPreviewWithTime.
  ///
  /// In en, this message translates to:
  /// **'{preview} • {time}'**
  String chatPreviewWithTime(Object preview, Object time);

  /// No description provided for @chatMessageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 message} other{{count} messages}}'**
  String chatMessageCount(num count);

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get actionOpen;

  /// No description provided for @chatAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to be authenticated to send messages.'**
  String get chatAuthRequired;

  /// No description provided for @chatSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending message: {error}'**
  String chatSendError(Object error);

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @yesterdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayLabel;

  /// No description provided for @chatLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading messages: {error}'**
  String chatLoadError(Object error);

  /// No description provided for @chatEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.\nSend the first one!'**
  String get chatEmptyMessage;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get chatInputHint;

  /// No description provided for @chatLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to send messages'**
  String get chatLoginHint;

  /// No description provided for @roleLabelSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get roleLabelSystem;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(Object meters);

  /// No description provided for @distanceKilometers.
  ///
  /// In en, this message translates to:
  /// **'{kilometers} km'**
  String distanceKilometers(Object kilometers);

  /// No description provided for @etaLessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'<1 min'**
  String get etaLessThanMinute;

  /// No description provided for @etaMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String etaMinutes(Object minutes);

  /// No description provided for @etaHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String etaHours(Object hours);

  /// No description provided for @etaHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} m'**
  String etaHoursMinutes(Object hours, Object minutes);

  /// No description provided for @mapEtaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA {eta} - {distance}'**
  String mapEtaLabel(Object eta, Object distance);

  /// No description provided for @mapOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get mapOpenAction;

  /// No description provided for @orderMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Order map'**
  String get orderMapTitle;

  /// No description provided for @orderChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat about this order'**
  String get orderChatTitle;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @messagesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get messagesSearchHint;

  /// No description provided for @messagesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading conversations: {error}'**
  String messagesLoadError(Object error);

  /// No description provided for @messagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any conversations yet.\nOnce you chat with a provider/customer, they\'ll appear here.'**
  String get messagesEmpty;

  /// No description provided for @chatPresenceOnline.
  ///
  /// In en, this message translates to:
  /// **'online'**
  String get chatPresenceOnline;

  /// No description provided for @chatPresenceLastSeenAt.
  ///
  /// In en, this message translates to:
  /// **'last seen at {time}'**
  String chatPresenceLastSeenAt(Object time);

  /// No description provided for @chatPresenceLastSeenYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'last seen yesterday at {time}'**
  String chatPresenceLastSeenYesterdayAt(Object time);

  /// No description provided for @chatPresenceLastSeenOn.
  ///
  /// In en, this message translates to:
  /// **'last seen on {date} at {time}'**
  String chatPresenceLastSeenOn(Object date, Object time);

  /// No description provided for @chatImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image too large (max 15MB).'**
  String get chatImageTooLarge;

  /// No description provided for @chatImageSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending image: {error}'**
  String chatImageSendError(Object error);

  /// No description provided for @chatFileReadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the file.'**
  String get chatFileReadError;

  /// No description provided for @chatFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large (max 20MB).'**
  String get chatFileTooLarge;

  /// No description provided for @chatFileSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending file: {error}'**
  String chatFileSendError(Object error);

  /// No description provided for @chatAudioReadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the audio.'**
  String get chatAudioReadError;

  /// No description provided for @chatAudioTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Audio too large (max 20MB).'**
  String get chatAudioTooLarge;

  /// No description provided for @chatAudioSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending audio: {error}'**
  String chatAudioSendError(Object error);

  /// No description provided for @chatAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Send file'**
  String get chatAttachFile;

  /// No description provided for @chatAttachGallery.
  ///
  /// In en, this message translates to:
  /// **'Send photo (gallery)'**
  String get chatAttachGallery;

  /// No description provided for @chatAttachCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo (camera)'**
  String get chatAttachCamera;

  /// No description provided for @chatAttachAudio.
  ///
  /// In en, this message translates to:
  /// **'Send audio (file)'**
  String get chatAttachAudio;

  /// No description provided for @chatAttachAudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an audio file (mp3/m4a/wav/...).'**
  String get chatAttachAudioSubtitle;

  /// No description provided for @chatOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get chatOpenLink;

  /// No description provided for @chatAttachTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get chatAttachTooltip;

  /// No description provided for @chatSendTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSendTooltip;

  /// No description provided for @chatSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get chatSearchAction;

  /// No description provided for @chatSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get chatSearchHint;

  /// No description provided for @chatSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type something to search.'**
  String get chatSearchEmpty;

  /// No description provided for @chatSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No messages found.'**
  String get chatSearchNoResults;

  /// No description provided for @chatMediaAction.
  ///
  /// In en, this message translates to:
  /// **'Media, links and files'**
  String get chatMediaAction;

  /// No description provided for @chatMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Media, links and files'**
  String get chatMediaTitle;

  /// No description provided for @chatMediaPhotosTab.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get chatMediaPhotosTab;

  /// No description provided for @chatMediaLinksTab.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get chatMediaLinksTab;

  /// No description provided for @chatMediaAudioTab.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get chatMediaAudioTab;

  /// No description provided for @chatMediaFilesTab.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get chatMediaFilesTab;

  /// No description provided for @chatMediaEmptyPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos yet.'**
  String get chatMediaEmptyPhotos;

  /// No description provided for @chatMediaEmptyLinks.
  ///
  /// In en, this message translates to:
  /// **'No links yet.'**
  String get chatMediaEmptyLinks;

  /// No description provided for @chatMediaEmptyAudio.
  ///
  /// In en, this message translates to:
  /// **'No audio yet.'**
  String get chatMediaEmptyAudio;

  /// No description provided for @chatMediaEmptyFiles.
  ///
  /// In en, this message translates to:
  /// **'No files yet.'**
  String get chatMediaEmptyFiles;

  /// No description provided for @chatFavoritesAction.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get chatFavoritesAction;

  /// No description provided for @chatFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Starred messages'**
  String get chatFavoritesTitle;

  /// No description provided for @chatFavoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have no starred messages yet.'**
  String get chatFavoritesEmpty;

  /// No description provided for @chatStarAction.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get chatStarAction;

  /// No description provided for @chatUnstarAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get chatUnstarAction;

  /// No description provided for @chatViewProviderProfileAction.
  ///
  /// In en, this message translates to:
  /// **'View provider profile'**
  String get chatViewProviderProfileAction;

  /// No description provided for @chatViewCustomerProfileAction.
  ///
  /// In en, this message translates to:
  /// **'View customer profile'**
  String get chatViewCustomerProfileAction;

  /// No description provided for @chatIncomingCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming call'**
  String get chatIncomingCall;

  /// No description provided for @chatCallStartedVideo.
  ///
  /// In en, this message translates to:
  /// **'Video call started'**
  String get chatCallStartedVideo;

  /// No description provided for @chatCallStartedVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice call started'**
  String get chatCallStartedVoice;

  /// No description provided for @chatImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get chatImageLabel;

  /// No description provided for @chatAudioLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get chatAudioLabel;

  /// No description provided for @chatFileLabel.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get chatFileLabel;

  /// No description provided for @chatCallEntryLabel.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get chatCallEntryLabel;

  /// No description provided for @chatNoSession.
  ///
  /// In en, this message translates to:
  /// **'No active session. Sign in to access the chat.'**
  String get chatNoSession;

  /// No description provided for @chatTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitleFallback;

  /// No description provided for @chatVideoCallAction.
  ///
  /// In en, this message translates to:
  /// **'Video call'**
  String get chatVideoCallAction;

  /// No description provided for @chatVoiceCallAction.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get chatVoiceCallAction;

  /// No description provided for @chatMarkReadAction.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get chatMarkReadAction;

  /// No description provided for @chatCallMissingParticipant.
  ///
  /// In en, this message translates to:
  /// **'The other participant isn\'t assigned to this order yet.'**
  String get chatCallMissingParticipant;

  /// No description provided for @chatCallStartError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the call.'**
  String get chatCallStartError;

  /// No description provided for @chatCallMessageVideo.
  ///
  /// In en, this message translates to:
  /// **'Video call: {url}'**
  String chatCallMessageVideo(Object url);

  /// No description provided for @chatCallMessageVoice.
  ///
  /// In en, this message translates to:
  /// **'Call: {url}'**
  String chatCallMessageVoice(Object url);

  /// No description provided for @profileProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider profile'**
  String get profileProviderTitle;

  /// No description provided for @profileCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer profile'**
  String get profileCustomerTitle;

  /// No description provided for @profileAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAboutTitle;

  /// No description provided for @profileLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileLocationTitle;

  /// No description provided for @profileServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get profileServicesTitle;

  /// No description provided for @profilePortfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get profilePortfolioTitle;

  /// No description provided for @chatOpenFullAction.
  ///
  /// In en, this message translates to:
  /// **'Open full chat'**
  String get chatOpenFullAction;

  /// No description provided for @chatOpenFullUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The other participant hasn\'t been assigned to this order yet.'**
  String get chatOpenFullUnavailable;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
