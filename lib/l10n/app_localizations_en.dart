// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ChegaJa';

  @override
  String get roleSelectorWelcome => 'Welcome to ChegaJa';

  @override
  String get roleSelectorPrompt => 'Choose how you want to use the app:';

  @override
  String get roleCustomerTitle => 'I\'m a customer';

  @override
  String get roleCustomerDescription => 'I want to find service providers near me.';

  @override
  String get roleProviderTitle => 'I\'m a provider';

  @override
  String get roleProviderDescription => 'I want to receive customer requests and earn more.';

  @override
  String get invalidSession => 'Invalid session.';

  @override
  String get paymentsTitle => 'Payments (Stripe)';

  @override
  String get paymentsHeading => 'Receive online payments';

  @override
  String get paymentsDescription => 'To receive payments via the app, you need to create a Stripe account (Connect Express).\nThe onboarding opens in your browser and takes 2–3 minutes.';

  @override
  String get paymentsActive => 'Online payments ACTIVE.';

  @override
  String get paymentsInactive => 'Online payments are not active yet. Complete onboarding.';

  @override
  String stripeAccountLabel(Object accountId) {
    return 'Stripe account: $accountId';
  }

  @override
  String get onboardingOpened => 'Onboarding opened. After finishing, come back to check the status.';

  @override
  String onboardingStartError(Object error) {
    return 'Error starting onboarding: $error';
  }

  @override
  String get manageStripeAccount => 'Manage Stripe account';

  @override
  String get activatePayments => 'Activate payments';

  @override
  String get technicalNotesTitle => 'Technical notes';

  @override
  String get technicalNotesBody => '• Stripe is configured via Cloud Functions (server-side).\n• The platform commission is applied automatically in the PaymentIntent.\n• In production, add the Stripe webhook and store the webhook secret in Functions.';

  @override
  String kycTitle(Object status) {
    return 'Identity verification: $status';
  }

  @override
  String get kycDescription => 'Send a document (photo or PDF). Full validation comes in v2.6.';

  @override
  String get kycSendDocument => 'Send document';

  @override
  String get kycAddDocument => 'Add document';

  @override
  String get kycStatusApproved => 'Approved';

  @override
  String get kycStatusRejected => 'Rejected';

  @override
  String get kycStatusInReview => 'In review';

  @override
  String get kycStatusNotStarted => 'Not started';

  @override
  String get kycFileReadError => 'Could not read the file.';

  @override
  String get kycFileTooLarge => 'File too large (max. 10MB).';

  @override
  String get kycUploading => 'Uploading document...';

  @override
  String get kycUploadSuccess => 'Document sent for review.';

  @override
  String kycUploadError(Object error) {
    return 'Error sending document: $error';
  }

  @override
  String get statusCancelledByYou => 'Cancelled by you';

  @override
  String get statusCancelledByProvider => 'Cancelled by provider';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusLookingForProvider => 'Looking for provider';

  @override
  String get statusProviderPreparingQuote => 'Provider found (preparing quote)';

  @override
  String get statusQuoteToDecide => 'You have a quote to decide';

  @override
  String get statusProviderFound => 'Provider found';

  @override
  String get statusServiceInProgress => 'Service in progress';

  @override
  String get statusAwaitingValueConfirmation => 'Awaiting your value confirmation';

  @override
  String get statusServiceCompleted => 'Service completed';

  @override
  String valueToConfirm(Object value) {
    return '$value (to confirm)';
  }

  @override
  String valueProposed(Object value) {
    return '$value (proposed)';
  }

  @override
  String valueEstimatedRange(Object min, Object max) {
    return '$min to $max (estimated)';
  }

  @override
  String valueEstimatedFrom(Object min) {
    return 'From $min (estimated)';
  }

  @override
  String valueEstimatedUpTo(Object max) {
    return 'Up to $max (estimated)';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get priceFixed => 'Fixed price';

  @override
  String get priceByQuote => 'By quote';

  @override
  String get priceToArrange => 'To be arranged';

  @override
  String get paymentOnlineBefore => 'Online payment (before)';

  @override
  String get paymentOnlineAfter => 'Online payment (after)';

  @override
  String get paymentCash => 'Cash payment';

  @override
  String get pendingActionQuoteToReview => 'You have a quote/proposal to review.';

  @override
  String get pendingActionValueToConfirm => 'The provider sent the final value. You need to confirm.';

  @override
  String get pendingActionProviderPreparingQuote => 'Provider found. They are preparing the quote.';

  @override
  String get pendingActionProviderChat => 'Provider found. You can chat with them.';

  @override
  String get roleLabelCustomer => 'Customer';

  @override
  String get navHome => 'Home';

  @override
  String get navMyOrders => 'My Orders';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profile';

  @override
  String get homeGreeting => 'Hello';

  @override
  String get homeSubtitle => 'What do you need today?';

  @override
  String get homePendingTitle => 'You have something to decide';

  @override
  String get homePendingCta => 'Tap here to open the next order and decide.';

  @override
  String servicesLoadError(Object error) {
    return 'Error loading services: $error';
  }

  @override
  String get servicesEmptyMessage => 'No services configured yet.\\nYou\'ll see categories here soon 🙂';

  @override
  String get availableServicesTitle => 'Available services';

  @override
  String get serviceTabImmediate => 'Immediate';

  @override
  String get serviceTabScheduled => 'Scheduled';

  @override
  String get serviceTabQuote => 'By quote';

  @override
  String get unreadMessagesTitle => 'You have new messages';

  @override
  String get unreadMessagesCta => 'Tap here to open the chat.';

  @override
  String get serviceSearchHint => 'Search service...';

  @override
  String get serviceSearchEmpty => 'No services found for this search.';

  @override
  String get serviceModeImmediateDescription => 'A provider comes today as quickly as possible.';

  @override
  String get serviceModeScheduledDescription => 'Schedule a day and time for the service.';

  @override
  String get serviceModeQuoteDescription => 'Request a quote (provider sends a min/max range).';

  @override
  String get userNotAuthenticatedError => 'Error: user not authenticated.';

  @override
  String get myOrdersTitle => 'My orders';

  @override
  String get ordersTabPending => 'Pending';

  @override
  String get ordersTabCompleted => 'Completed';

  @override
  String get ordersTabCancelled => 'Cancelled';

  @override
  String ordersLoadError(Object error) {
    return 'Error loading orders: $error';
  }

  @override
  String get ordersEmptyPending => 'You have no pending orders.\\nCreate a new order from Home.';

  @override
  String get ordersEmptyCompleted => 'You don\'t have completed orders yet.';

  @override
  String get ordersEmptyCancelled => 'You don\'t have cancelled orders yet.';

  @override
  String get orderQuoteScheduled => 'Quote (scheduled)';

  @override
  String get orderQuoteImmediate => 'Quote (immediate)';

  @override
  String get orderScheduled => 'Scheduled service';

  @override
  String get orderImmediate => 'Immediate service';

  @override
  String get categoryNotDefined => 'Category not defined';

  @override
  String orderStateLabel(Object state) {
    return 'State: $state';
  }

  @override
  String orderPriceModelLabel(Object model) {
    return 'Price model: $model';
  }

  @override
  String orderPaymentLabel(Object payment) {
    return 'Payment: $payment';
  }

  @override
  String orderValueLabel(Object value) {
    return 'Value: $value';
  }

  @override
  String accountTitle(Object role) {
    return 'Account ($role)';
  }

  @override
  String get accountNameTitle => 'Your name';

  @override
  String get accountProfileSubtitle => 'Profile';

  @override
  String get accountSettings => 'Settings';

  @override
  String get accountHelpSupport => 'Help and support';

  @override
  String get navMyJobs => 'My Jobs';

  @override
  String get roleLabelProvider => 'Provider';

  @override
  String get enableLocationToGoOnline => 'Enable location to go online.';

  @override
  String get nearbyOrdersTitle => 'Orders near you';

  @override
  String get noOrdersAvailableMessage => 'No orders available right now.';

  @override
  String get configureServiceAreaMessage => 'Set your service area and services to start receiving orders.';

  @override
  String get configureAction => 'Configure';

  @override
  String get offlineEnableOnlineMessage => 'You\'re offline. Enable online status to receive orders.';

  @override
  String get noMatchingOrdersMessage => 'No matching orders for your services and area.';

  @override
  String get orderAcceptedMessage => 'Order accepted.';

  @override
  String get orderAcceptedCanSendQuote => 'Order accepted. You can send the quote later.';

  @override
  String orderAcceptError(Object error) {
    return 'Error accepting order: $error';
  }

  @override
  String get orderAcceptedDialogTitle => 'Order accepted';

  @override
  String get orderAcceptedBudgetPrompt => 'This order is by quote.\\n\\nDo you want to send the quote range now?';

  @override
  String get actionLater => 'Later';

  @override
  String get actionSendNow => 'Send now';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSend => 'Send';

  @override
  String get actionIgnore => 'Ignore';

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionNo => 'No';

  @override
  String get actionYesCancel => 'Yes, cancel';

  @override
  String get proposalDialogTitle => 'Send a quote';

  @override
  String get proposalDialogDescription => 'Set a price range for this service.\\nInclude travel and labor.';

  @override
  String proposalMinValueLabel(Object currency) {
    return 'Minimum value ($currency)';
  }

  @override
  String get proposalMinValueHint => 'Ex.: 20';

  @override
  String proposalMaxValueLabel(Object currency) {
    return 'Maximum value ($currency)';
  }

  @override
  String get proposalMaxValueHint => 'Ex.: 35';

  @override
  String get proposalMessageLabel => 'Message to the customer (optional)';

  @override
  String get proposalMessageHint => 'Ex.: Includes travel. Large materials are extra.';

  @override
  String get proposalInvalidValues => 'Enter valid minimum and maximum values.';

  @override
  String get proposalMinGreaterThanMax => 'The minimum can\'t be greater than the maximum.';

  @override
  String get proposalSent => 'Proposal sent to the customer.';

  @override
  String proposalSendError(Object error) {
    return 'Error sending proposal: $error';
  }

  @override
  String get providerHomeGreeting => 'Hello, provider';

  @override
  String get providerHomeSubtitle => 'Go online to receive new orders.';

  @override
  String get providerStatusOnline => 'You\'re ONLINE';

  @override
  String get providerStatusOffline => 'You\'re OFFLINE';

  @override
  String get providerKpiEarningsToday => 'Earnings today (net)';

  @override
  String get providerKpiServicesThisMonth => 'Services this month';

  @override
  String providerKpiGrossFeeSubtitle(Object gross, Object fee) {
    return 'Gross: $gross - Fee: $fee';
  }

  @override
  String get providerHighlightTitle => 'You have a job to manage';

  @override
  String get providerHighlightCta => 'Tap here to open the next job.';

  @override
  String get providerPendingActionAccepted => 'You have an accepted job, ready to start.';

  @override
  String get providerPendingActionInProgress => 'You have a job in progress. Mark it completed when you finish.';

  @override
  String get providerPendingActionSetFinalValue => 'Set and send the final service value.';

  @override
  String get providerUnreadMessagesTitle => 'You have new messages from customers';

  @override
  String providerUnreadMessagesJob(Object jobTitle) {
    return 'In job: $jobTitle';
  }

  @override
  String get providerJobsTitle => 'My jobs';

  @override
  String get providerJobsTabOpen => 'Open';

  @override
  String get providerJobsTabCompleted => 'Completed';

  @override
  String get providerJobsTabCancelled => 'Cancelled';

  @override
  String providerJobsLoadError(Object error) {
    return 'Error loading jobs: $error';
  }

  @override
  String get providerJobsEmptyOpen => 'You don\'t have open jobs yet.\\nGo to Home and accept an order.';

  @override
  String get providerJobsEmptyCompleted => 'You don\'t have completed jobs yet.';

  @override
  String get providerJobsEmptyCancelled => 'You don\'t have cancelled jobs yet.';

  @override
  String scheduledForDate(Object date) {
    return 'Scheduled: $date';
  }

  @override
  String get viewDetailsTooltip => 'View details';

  @override
  String clientPaidValueLabel(Object value) {
    return 'Customer paid: $value';
  }

  @override
  String providerEarningsFeeLabel(Object value, Object fee) {
    return 'You receive: $value - Fee: $fee';
  }

  @override
  String serviceValueLabel(Object value) {
    return 'Service value: $value';
  }

  @override
  String get cancelJobTitle => 'Cancel job';

  @override
  String get cancelJobPrompt => 'Are you sure you want to cancel this job?\\nThe order may become available to other providers.';

  @override
  String get cancelJobReasonLabel => 'Cancellation reason (optional):';

  @override
  String get cancelJobReasonFieldLabel => 'Reason';

  @override
  String get cancelJobSuccess => 'Job cancelled.';

  @override
  String cancelJobError(Object error) {
    return 'Error cancelling job: $error';
  }

  @override
  String get providerAccountProfileTitle => 'View my profile';

  @override
  String get providerAccountProfileSubtitle => 'Provider profile';

  @override
  String get activateOnlinePaymentsSubtitle => 'Enable online payments';

  @override
  String get statusProviderWaiting => 'New request';

  @override
  String get statusQuoteWaitingCustomer => 'Waiting for customer response';

  @override
  String get statusAcceptedToStart => 'Accepted (ready to start)';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get orderDefaultImmediateTitle => 'Urgent service';

  @override
  String get locationServiceDisabled => 'Location service is disabled on the device.';

  @override
  String get locationPermissionDenied => 'Location permission denied.\\nCouldn\'t get the current location.';

  @override
  String get locationPermissionDeniedForever => 'Location permission permanently denied.\\nEnable location in device settings.';

  @override
  String locationFetchError(Object error) {
    return 'Error getting location: $error';
  }

  @override
  String get formNotReadyError => 'The form isn\'t ready yet. Try again.';

  @override
  String get missingRequiredFieldsError => 'Required fields are missing. Check the fields in red.';

  @override
  String get scheduleDateTimeRequiredError => 'Choose the service date and time.';

  @override
  String get scheduleDateTimeFutureError => 'Choose a future date/time.';

  @override
  String get categoryRequiredError => 'Choose a category.';

  @override
  String get orderUpdatedSuccess => 'Order updated successfully!';

  @override
  String get orderCreatedSuccess => 'Order created! Looking for a provider...';

  @override
  String orderUpdateError(Object error) {
    return 'Error updating order: $error';
  }

  @override
  String orderCreateError(Object error) {
    return 'Error creating order: $error';
  }

  @override
  String get orderTitleExamplePlumbing => 'Ex.: Plumbing leak under the sink';

  @override
  String get orderTitleExampleElectric => 'Ex.: Outlet doesn\'t work in the living room + install ceiling light';

  @override
  String get orderTitleExampleCleaning => 'Ex.: Full cleaning of a 2-bedroom apartment (kitchen, WC, windows, floor).';

  @override
  String get orderTitleHintImmediate => 'Briefly explain what\'s happening and what you need.';

  @override
  String get orderTitleHintScheduled => 'Say when you want the service, location details, and what needs to be done.';

  @override
  String get orderTitleHintQuote => 'Describe the service you want to receive proposals for.';

  @override
  String get orderTitleHintDefault => 'Describe the service you need.';

  @override
  String get orderDescriptionExampleCleaning => 'Ex.: Full cleaning of a 2-bedroom apartment (kitchen, WC, windows, floor).';

  @override
  String get orderDescriptionHintImmediate => 'Briefly explain what\'s happening and what you need.';

  @override
  String get orderDescriptionHintScheduled => 'Say when you want the service, location details, and what needs to be done.';

  @override
  String get orderDescriptionHintQuote => 'Describe the service you want, approximate budget (if you have one), and important details.';

  @override
  String get orderDescriptionHintDefault => 'Explain in a bit more detail what you need.';

  @override
  String get priceModelTitle => 'Price model';

  @override
  String get priceModelQuoteInfo => 'This service is by quote. The provider will propose the final price.';

  @override
  String get priceTypeLabel => 'Price type';

  @override
  String get paymentTypeLabel => 'Payment type';

  @override
  String get orderHeaderQuoteTitle => 'Quote request';

  @override
  String get orderHeaderQuoteSubtitle => 'Describe what you need and the provider can send a range (min/max).';

  @override
  String get orderHeaderImmediateTitle => 'Immediate service';

  @override
  String get orderHeaderImmediateSubtitle => 'An available provider will be called as soon as possible.';

  @override
  String get orderHeaderScheduledTitle => 'Scheduled service';

  @override
  String get orderHeaderScheduledSubtitle => 'Choose the day and time for the provider to come to you.';

  @override
  String get orderHeaderDefaultTitle => 'New order';

  @override
  String get orderHeaderDefaultSubtitle => 'Describe the service you need.';

  @override
  String get orderEditTitle => 'Edit order';

  @override
  String get orderNewTitle => 'New order';

  @override
  String get whenServiceNeededLabel => 'When do you need the service?';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryHint => 'Choose the service category';

  @override
  String get orderTitleLabel => 'Order title';

  @override
  String get orderTitleRequiredError => 'Write a title for the order.';

  @override
  String get orderDescriptionOptionalLabel => 'Description (optional)';

  @override
  String get locationApproxLabel => 'Approximate location';

  @override
  String get locationSelectedLabel => 'Location selected.';

  @override
  String get locationSelectPrompt => 'Choose where the service will be performed (approximate).';

  @override
  String get locationAddressHint => 'Street, number, floor, reference (optional, but helps a lot)';

  @override
  String get locationGetting => 'Getting location...';

  @override
  String get locationUseCurrent => 'Use current location';

  @override
  String get locationChooseOnMap => 'Choose on map';

  @override
  String get serviceDateTimeLabel => 'Service date and time';

  @override
  String get serviceDateTimePick => 'Choose day and time';

  @override
  String get saveChangesButton => 'Save changes';

  @override
  String get submitOrderButton => 'Request service';

  @override
  String get mapSelectTitle => 'Choose location on map';

  @override
  String get mapSelectInstruction => 'Drag the map to the approximate service location, then confirm.';

  @override
  String get mapSelectConfirm => 'Confirm location';

  @override
  String get orderDetailsTitle => 'Order details';

  @override
  String orderLoadError(Object error) {
    return 'Error loading order: $error';
  }

  @override
  String get orderNotFound => 'Order not found.';

  @override
  String get scheduledNoDate => 'Scheduled (no date set)';

  @override
  String get orderValueRejectedTitle => 'The customer rejected the proposed value.';

  @override
  String get orderValueRejectedBody => 'Chat with the customer and propose a new value when aligned.';

  @override
  String get actionProposeNewValue => 'Propose new value';

  @override
  String get noShowReportedTitle => 'No-show reported';

  @override
  String noShowReportedBy(Object role) {
    return 'Reported by: $role';
  }

  @override
  String noShowReportedAt(Object date) {
    return 'At: $date';
  }

  @override
  String get noShowTitle => 'No-show';

  @override
  String get noShowDescription => 'If the other person didn\'t show up, you can report it.';

  @override
  String get noShowReportAction => 'Report no-show';

  @override
  String get orderInfoTitle => 'Order information';

  @override
  String get orderInfoIdLabel => 'Order ID';

  @override
  String get orderInfoCreatedAtLabel => 'Created at';

  @override
  String get orderInfoStatusLabel => 'Status';

  @override
  String get orderInfoModeLabel => 'Mode';

  @override
  String get orderInfoValueLabel => 'Value';

  @override
  String get orderLocationTitle => 'Order location';

  @override
  String get orderDescriptionTitle => 'Order description';

  @override
  String get providerMessageTitle => 'Provider message';

  @override
  String get actionEditOrder => 'Edit order';

  @override
  String get actionCancelOrder => 'Cancel order';

  @override
  String get cancelOrderTitle => 'Cancel order';

  @override
  String get orderCancelInProgressWarning => 'The service is already in progress.\nCanceling now may result in a partial refund.';

  @override
  String get orderCancelConfirmPrompt => 'Are you sure you want to cancel this order?';

  @override
  String get orderCancelReasonLabel => 'Cancellation reason';

  @override
  String get orderCancelReasonOptionalLabel => 'Reason (optional)';

  @override
  String orderCancelledSnack(Object message) {
    return 'Order cancelled. $message.';
  }

  @override
  String orderCancelError(Object error) {
    return 'Error cancelling order: $error';
  }

  @override
  String get noShowReportDialogTitle => 'Report no-show';

  @override
  String get noShowReportDialogDescription => 'Use this only if the other person didn\'t show up.';

  @override
  String get noShowReasonOptionalLabel => 'Reason (optional)';

  @override
  String get actionReport => 'Report';

  @override
  String get noShowReportSuccess => 'No-show reported.';

  @override
  String noShowReportError(Object error) {
    return 'Error reporting no-show: $error';
  }

  @override
  String get orderFinalValueTitle => 'Propose new final value';

  @override
  String get orderFinalValueLabel => 'Value';

  @override
  String get orderFinalValueInvalid => 'Enter a valid value.';

  @override
  String get orderFinalValueSent => 'New value sent to the customer.';

  @override
  String orderFinalValueSendError(Object error) {
    return 'Error sending new value: $error';
  }

  @override
  String get ratingSentTitle => 'Rating sent';

  @override
  String get ratingProviderTitle => 'Provider rating';

  @override
  String get ratingPrompt => 'Leave a rating from 1 to 5.';

  @override
  String get ratingCommentLabel => 'Comment (optional)';

  @override
  String get ratingSendAction => 'Send rating';

  @override
  String get ratingSelectError => 'Choose a rating.';

  @override
  String get ratingSentSnack => 'Rating sent.';

  @override
  String ratingSendError(Object error) {
    return 'Error sending rating: $error';
  }

  @override
  String get timelineCreated => 'Created';

  @override
  String get timelineAccepted => 'Accepted';

  @override
  String get timelineInProgress => 'In progress';

  @override
  String get timelineCancelled => 'Cancelled';

  @override
  String get timelineCompleted => 'Completed';

  @override
  String get lookingForProviderBanner => 'We\'re still looking for a provider for this order.';

  @override
  String get actionView => 'View';

  @override
  String get chatNoMessagesSubtitle => 'No messages yet';

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
  String get actionClose => 'Close';

  @override
  String get actionOpen => 'Open';

  @override
  String get chatAuthRequired => 'You need to be authenticated to send messages.';

  @override
  String chatSendError(Object error) {
    return 'Error sending message: $error';
  }

  @override
  String get todayLabel => 'Today';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String chatLoadError(Object error) {
    return 'Error loading messages: $error';
  }

  @override
  String get chatEmptyMessage => 'No messages yet.\nSend the first one!';

  @override
  String get chatInputHint => 'Write a message...';

  @override
  String get chatLoginHint => 'Sign in to send messages';

  @override
  String get roleLabelSystem => 'System';

  @override
  String get youLabel => 'You';

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
  String get mapOpenAction => 'Open map';

  @override
  String get orderMapTitle => 'Order map';

  @override
  String get orderChatTitle => 'Chat about this order';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesSearchHint => 'Search messages';

  @override
  String messagesLoadError(Object error) {
    return 'Error loading conversations: $error';
  }

  @override
  String get messagesEmpty => 'You don\'t have any conversations yet.\nOnce you chat with a provider/customer, they\'ll appear here.';

  @override
  String get chatPresenceOnline => 'online';

  @override
  String chatPresenceLastSeenAt(Object time) {
    return 'last seen at $time';
  }

  @override
  String chatPresenceLastSeenYesterdayAt(Object time) {
    return 'last seen yesterday at $time';
  }

  @override
  String chatPresenceLastSeenOn(Object date, Object time) {
    return 'last seen on $date at $time';
  }

  @override
  String get chatImageTooLarge => 'Image too large (max 15MB).';

  @override
  String chatImageSendError(Object error) {
    return 'Error sending image: $error';
  }

  @override
  String get chatFileReadError => 'Couldn\'t read the file.';

  @override
  String get chatFileTooLarge => 'File too large (max 20MB).';

  @override
  String chatFileSendError(Object error) {
    return 'Error sending file: $error';
  }

  @override
  String get chatAudioReadError => 'Couldn\'t read the audio.';

  @override
  String get chatAudioTooLarge => 'Audio too large (max 20MB).';

  @override
  String chatAudioSendError(Object error) {
    return 'Error sending audio: $error';
  }

  @override
  String get chatAttachFile => 'Send file';

  @override
  String get chatAttachGallery => 'Send photo (gallery)';

  @override
  String get chatAttachCamera => 'Take photo (camera)';

  @override
  String get chatAttachAudio => 'Send audio (file)';

  @override
  String get chatAttachAudioSubtitle => 'Choose an audio file (mp3/m4a/wav/...).';

  @override
  String get chatOpenLink => 'Open link';

  @override
  String get chatAttachTooltip => 'Attach';

  @override
  String get chatSendTooltip => 'Send';

  @override
  String get chatSearchAction => 'Search';

  @override
  String get chatSearchHint => 'Search messages';

  @override
  String get chatSearchEmpty => 'Type something to search.';

  @override
  String get chatSearchNoResults => 'No messages found.';

  @override
  String get chatMediaAction => 'Media, links and files';

  @override
  String get chatMediaTitle => 'Media, links and files';

  @override
  String get chatMediaPhotosTab => 'Photos';

  @override
  String get chatMediaLinksTab => 'Links';

  @override
  String get chatMediaAudioTab => 'Audio';

  @override
  String get chatMediaFilesTab => 'Files';

  @override
  String get chatMediaEmptyPhotos => 'No photos yet.';

  @override
  String get chatMediaEmptyLinks => 'No links yet.';

  @override
  String get chatMediaEmptyAudio => 'No audio yet.';

  @override
  String get chatMediaEmptyFiles => 'No files yet.';

  @override
  String get chatFavoritesAction => 'Starred';

  @override
  String get chatFavoritesTitle => 'Starred messages';

  @override
  String get chatFavoritesEmpty => 'You have no starred messages yet.';

  @override
  String get chatStarAction => 'Add to favorites';

  @override
  String get chatUnstarAction => 'Remove from favorites';

  @override
  String get chatViewProviderProfileAction => 'View provider profile';

  @override
  String get chatViewCustomerProfileAction => 'View customer profile';

  @override
  String get chatIncomingCall => 'Incoming call';

  @override
  String get chatCallStartedVideo => 'Video call started';

  @override
  String get chatCallStartedVoice => 'Voice call started';

  @override
  String get chatImageLabel => 'Image';

  @override
  String get chatAudioLabel => 'Audio';

  @override
  String get chatFileLabel => 'File';

  @override
  String get chatCallEntryLabel => 'Call';

  @override
  String get chatNoSession => 'No active session. Sign in to access the chat.';

  @override
  String get chatTitleFallback => 'Chat';

  @override
  String get chatVideoCallAction => 'Video call';

  @override
  String get chatVoiceCallAction => 'Call';

  @override
  String get chatMarkReadAction => 'Mark as read';

  @override
  String get chatCallMissingParticipant => 'The other participant isn\'t assigned to this order yet.';

  @override
  String get chatCallStartError => 'Couldn\'t start the call.';

  @override
  String chatCallMessageVideo(Object url) {
    return 'Video call: $url';
  }

  @override
  String chatCallMessageVoice(Object url) {
    return 'Call: $url';
  }

  @override
  String get profileProviderTitle => 'Provider profile';

  @override
  String get profileCustomerTitle => 'Customer profile';

  @override
  String get profileAboutTitle => 'About';

  @override
  String get profileLocationTitle => 'Location';

  @override
  String get profileServicesTitle => 'Services';

  @override
  String get profilePortfolioTitle => 'Portfolio';

  @override
  String get chatOpenFullAction => 'Open full chat';

  @override
  String get chatOpenFullUnavailable => 'The other participant hasn\'t been assigned to this order yet.';
}
