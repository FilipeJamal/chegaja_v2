// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '切加贾';

  @override
  String get roleSelectorWelcome => '欢迎来到ChegaJa';

  @override
  String get roleSelectorPrompt => '选择您想要如何使用该应用程序：';

  @override
  String get roleCustomerTitle => '我是顾客';

  @override
  String get roleCustomerDescription => '我想找到我附近的服务提供商。';

  @override
  String get roleProviderTitle => '我是供应商';

  @override
  String get roleProviderDescription => '我希望收到客户的请求并赚取更多。';

  @override
  String get invalidSession => '无效会话。';

  @override
  String get paymentsTitle => '付款（条纹）';

  @override
  String get paymentsHeading => '接收在线付款';

  @override
  String get paymentsDescription =>
      '要通过应用程序接收付款，您需要创建一个 Stripe 帐户 (Connect Express)。\n入门将在浏览器中打开，需要 2-3 分钟。';

  @override
  String get paymentsActive => '在线支付活跃。';

  @override
  String get paymentsInactive => '在线支付尚未激活。完成入职。';

  @override
  String stripeAccountLabel(Object accountId) {
    return '条带帐户：$accountId';
  }

  @override
  String get onboardingOpened => '入职开放。完成后，回来查看状态。';

  @override
  String onboardingStartError(Object error) {
    return '开始加入时出错：$error';
  }

  @override
  String get manageStripeAccount => '管理 Stripe 帐户';

  @override
  String get activatePayments => '激活付款';

  @override
  String get technicalNotesTitle => '技术说明';

  @override
  String get technicalNotesBody =>
      '• Stripe 通过Cloud Functions（服务器端）进行配置。\n• 平台佣金自动应用到PaymentIntent 中。\n• 在生产中，添加Stripe Webhook 并将Webhook 密钥存储在Functions 中。';

  @override
  String kycTitle(Object status) {
    return '身份验证：$status';
  }

  @override
  String get kycDescription => '发送文档（照片或 PDF）。 v2.6 中提供了完整的验证。';

  @override
  String get kycSendDocument => '发送文件';

  @override
  String get kycAddDocument => '添加文档';

  @override
  String get kycStatusApproved => '得到正式认可的';

  @override
  String get kycStatusRejected => '被拒绝';

  @override
  String get kycStatusInReview => '审核中';

  @override
  String get kycStatusNotStarted => '未开始';

  @override
  String get kycFileReadError => '无法读取文件。';

  @override
  String get kycFileTooLarge => '文件太大（最大 10MB）。';

  @override
  String get kycUploading => '正在上传文档...';

  @override
  String get kycUploadSuccess => '文件已送交审查。';

  @override
  String kycUploadError(Object error) {
    return '发送文档时出错：$error';
  }

  @override
  String get statusCancelledByYou => '已被您取消';

  @override
  String get statusCancelledByProvider => '被提供商取消';

  @override
  String get statusCancelled => '取消';

  @override
  String get statusLookingForProvider => '寻找供应商';

  @override
  String get statusProviderPreparingQuote => '找到供应商（准备报价）';

  @override
  String get statusQuoteToDecide => '您有一个报价来决定';

  @override
  String get statusProviderFound => '找到提供商';

  @override
  String get statusServiceInProgress => '服务进行中';

  @override
  String get statusAwaitingValueConfirmation => '等待您的价值确认';

  @override
  String get statusServiceCompleted => '服务完成';

  @override
  String valueToConfirm(Object value) {
    return '$value（确认）';
  }

  @override
  String valueProposed(Object value) {
    return '$value（建议）';
  }

  @override
  String valueEstimatedRange(Object min, Object max) {
    return '$min 至 $max（预计）';
  }

  @override
  String valueEstimatedFrom(Object min) {
    return '从$min开始（预计）';
  }

  @override
  String valueEstimatedUpTo(Object max) {
    return '最多 $max（估计）';
  }

  @override
  String get valueUnknown => '—';

  @override
  String get priceFixed => '定价';

  @override
  String get priceByQuote => '通过报价';

  @override
  String get priceToArrange => '待安排';

  @override
  String get paymentOnlineBefore => '网上支付（之前）';

  @override
  String get paymentOnlineAfter => '网上支付（后）';

  @override
  String get paymentCash => '现金支付';

  @override
  String get pendingActionQuoteToReview => '您有一份报价/建议需要审核。';

  @override
  String get pendingActionValueToConfirm => '提供商发送了最终值。你需要确认一下。';

  @override
  String get pendingActionProviderPreparingQuote => '找到提供者。他们正在准备报价。';

  @override
  String get pendingActionProviderChat => '找到提供者。你可以和他们聊天。';

  @override
  String get roleLabelCustomer => '顾客';

  @override
  String get navHome => '家';

  @override
  String get navMyOrders => '我的订单';

  @override
  String get navMessages => '留言';

  @override
  String get navProfile => '轮廓';

  @override
  String get homeGreeting => '你好';

  @override
  String get homeSubtitle => '今天你需要什么？';

  @override
  String get homePendingTitle => '你有一些事情需要决定';

  @override
  String get homePendingCta => '点击此处打开下一个订单并做出决定。';

  @override
  String servicesLoadError(Object error) {
    return '加载服务时出错：$error';
  }

  @override
  String get servicesEmptyMessage => '尚未配置服务。\\n您很快就会在此处看到类别 🙂';

  @override
  String get availableServicesTitle => '可用服务';

  @override
  String get serviceTabImmediate => '即时';

  @override
  String get serviceTabScheduled => '预定';

  @override
  String get serviceTabQuote => '通过报价';

  @override
  String get unreadMessagesTitle => '您有新消息';

  @override
  String get unreadMessagesCta => '点击此处打开聊天。';

  @override
  String get serviceSearchHint => '搜索服务...';

  @override
  String get serviceSearchEmpty => '没有找到适合此搜索的服务。';

  @override
  String get serviceModeImmediateDescription => '提供商今天会尽快到达。';

  @override
  String get serviceModeScheduledDescription => '安排服务的日期和时间。';

  @override
  String get serviceModeQuoteDescription => '请求报价（提供商发送最小/最大范围）。';

  @override
  String get userNotAuthenticatedError => '错误：用户未经过身份验证。';

  @override
  String get myOrdersTitle => '我的订单';

  @override
  String get ordersTabPending => '待办的';

  @override
  String get ordersTabCompleted => '完全的';

  @override
  String get ordersTabCancelled => '取消';

  @override
  String ordersLoadError(Object error) {
    return '加载订单时出错：$error';
  }

  @override
  String get ordersEmptyPending => '您没有待处理的订单。\\n从主页创建新订单。';

  @override
  String get ordersEmptyCompleted => '您还没有完成订单。';

  @override
  String get ordersEmptyCancelled => '您还没有取消订单。';

  @override
  String get orderQuoteScheduled => '报价（预定）';

  @override
  String get orderQuoteImmediate => '报价（即时）';

  @override
  String get orderScheduled => '预定服务';

  @override
  String get orderImmediate => '即时服务';

  @override
  String get categoryNotDefined => '类别未定义';

  @override
  String orderStateLabel(Object state) {
    return '州：$state';
  }

  @override
  String orderPriceModelLabel(Object model) {
    return '价格型号：$model';
  }

  @override
  String orderPaymentLabel(Object payment) {
    return '付款：$payment';
  }

  @override
  String orderValueLabel(Object value) {
    return '值：$value';
  }

  @override
  String accountTitle(Object role) {
    return '帐户 ($role)';
  }

  @override
  String get accountNameTitle => '你的名字';

  @override
  String get accountProfileSubtitle => '轮廓';

  @override
  String get accountSettings => '设置';

  @override
  String get accountHelpSupport => '帮助和支持';

  @override
  String get navMyJobs => '我的工作';

  @override
  String get roleLabelProvider => '提供者';

  @override
  String get enableLocationToGoOnline => '启用位置即可上网。';

  @override
  String get nearbyOrdersTitle => '您附近的订单';

  @override
  String get noOrdersAvailableMessage => '目前没有可用订单。';

  @override
  String get configureServiceAreaMessage => '设置您的服务区域和服务以开始接收订单。';

  @override
  String get configureAction => '配置';

  @override
  String get offlineEnableOnlineMessage => '你离线了。启用在线状态以接收订单。';

  @override
  String get noMatchingOrdersMessage => '没有与您的服务和区域匹配的订单。';

  @override
  String get orderAcceptedMessage => '订单已接受。';

  @override
  String get orderAcceptedCanSendQuote => '订单已接受。您可以稍后发送报价。';

  @override
  String orderAcceptError(Object error) {
    return '接受订单时出错：$error';
  }

  @override
  String get orderAcceptedDialogTitle => '订单已接受';

  @override
  String get orderAcceptedBudgetPrompt => '该订单是按报价的。\\n\\n您想立即发送报价范围吗？';

  @override
  String get actionLater => '之后';

  @override
  String get actionSendNow => '立即发送';

  @override
  String get actionCancel => '取消';

  @override
  String get actionSend => '发送';

  @override
  String get actionIgnore => '忽略';

  @override
  String get actionAccept => '接受';

  @override
  String get actionNo => '不';

  @override
  String get actionYesCancel => '是的，取消';

  @override
  String get proposalDialogTitle => '发送报价';

  @override
  String get proposalDialogDescription => '设置此服务的价格范围。\\n包括差旅费和人工费。';

  @override
  String proposalMinValueLabel(Object currency) {
    return '最小值 ($currency)';
  }

  @override
  String get proposalMinValueHint => '例如：20';

  @override
  String proposalMaxValueLabel(Object currency) {
    return '最大值 ($currency)';
  }

  @override
  String get proposalMaxValueHint => '例如：35';

  @override
  String get proposalMessageLabel => '给客户的消息（可选）';

  @override
  String get proposalMessageHint => '例如：包括旅行。大的材料是额外的。';

  @override
  String get proposalInvalidValues => '输入有效的最小值和最大值。';

  @override
  String get proposalMinGreaterThanMax => '最小值不能大于最大值。';

  @override
  String get proposalSent => '提案已发送给客户。';

  @override
  String proposalSendError(Object error) {
    return '发送提案时出错：$error';
  }

  @override
  String get providerHomeGreeting => '您好，提供商';

  @override
  String get providerHomeSubtitle => '上网接收新订单。';

  @override
  String get providerStatusOnline => '你在线';

  @override
  String get providerStatusOffline => '你离线了';

  @override
  String providerSettingsLoadError(Object error) {
    return '加载设置时出错：$error';
  }

  @override
  String providerSettingsSaveError(Object error) {
    return '保存设置时出错：$error';
  }

  @override
  String get serviceAreaTitle => '服务区';

  @override
  String get serviceAreaHeading => '您想在哪里接收订单？';

  @override
  String get serviceAreaSubtitle => '设置您提供的服务以及您的基地城市周围的最大半径。';

  @override
  String get serviceAreaBaseLocation => '基地位置';

  @override
  String get serviceAreaRadius => '服务半径';

  @override
  String get serviceAreaSaved => '服务区保存成功。';

  @override
  String get serviceAreaInfoNote =>
      '将来，我们将使用这些设置按邻近度和服务类型过滤订单。目前，这可以帮助我们准备匹配引擎。';

  @override
  String get availabilityTitle => '可用性';

  @override
  String get servicesYouProvideTitle => '您提供的服务';

  @override
  String get servicesCatalogEmpty => '目录中尚未配置任何服务。';

  @override
  String get servicesSearchPrompt => '键入以搜索和添加服务。';

  @override
  String get servicesSearchNoResults => '未找到任何服务。';

  @override
  String get servicesSelectedTitle => '精选服务';

  @override
  String get serviceUnnamed => '未命名服务';

  @override
  String get serviceModeQuote => '引用';

  @override
  String get serviceModeScheduled => '预定';

  @override
  String get serviceModeImmediate => '即时';

  @override
  String get providerServicesSelectAtLeastOne => '至少选择您提供的一项服务。';

  @override
  String get countryLabel => '国家';

  @override
  String get cityLabel => '城市';

  @override
  String get stateLabelDistrict => '区';

  @override
  String get stateLabelProvince => '省';

  @override
  String get stateLabelState => '状态';

  @override
  String get stateLabelRegion => '地区';

  @override
  String get stateLabelCounty => '县';

  @override
  String get stateLabelRegionOrState => '地区/州';

  @override
  String get searchHint => '搜索...';

  @override
  String get searchCountryHint => '输入搜索国家';

  @override
  String get searchGenericHint => '输入搜索';

  @override
  String get searchServicesHint => '搜寻服务';

  @override
  String get openCountriesListTooltip => '查看国家列表';

  @override
  String get openListTooltip => '查看列表';

  @override
  String get selectCountryTitle => '选择国家';

  @override
  String get selectCityTitle => '选择城市';

  @override
  String selectFieldTitle(Object field) {
    return '选择$field';
  }

  @override
  String get saveChanges => '保存更改';

  @override
  String get supportTitle => '帮助与支持';

  @override
  String get supportSubtitle => '有疑问吗？联系我们。';

  @override
  String get myScheduleTitle => '我的日程';

  @override
  String get myScheduleSubtitle => '设置休息时间和休息日';

  @override
  String get languageTitle => '语言';

  @override
  String get languageModeManual => '手动的';

  @override
  String get languageModeAuto => '汽车';

  @override
  String languageModeLabel(Object code, Object mode) {
    return '$code - $mode';
  }

  @override
  String get languageAutoSystem => '自动（系统）';

  @override
  String get providerCategoriesTitle => '服务类别';

  @override
  String get providerCategoriesSubtitle => '我们使用类别来过滤兼容订单。';

  @override
  String get providerCategoriesEmpty => '未选择类别。';

  @override
  String get providerCategoriesSelect => '选择类别';

  @override
  String get providerCategoriesEdit => '添加或编辑类别';

  @override
  String get providerCategoriesRequiredMessage => '选择您的类别以接收匹配的订单。';

  @override
  String get providerKpiEarningsToday => '今日收益（净值）';

  @override
  String get providerKpiServicesThisMonth => '本月服务';

  @override
  String providerKpiGrossFeeSubtitle(Object gross, Object fee) {
    return '毛额：$gross - 费用：$fee';
  }

  @override
  String get providerHighlightTitle => '你有工作需要管理';

  @override
  String get providerHighlightCta => '点击此处打开下一个作业。';

  @override
  String get providerPendingActionAccepted => '你有一份被接受的工作，准备开始。';

  @override
  String get providerPendingActionInProgress => '您有一项工作正在进行中。完成后将其标记为已完成。';

  @override
  String get providerPendingActionSetFinalValue => '设置并发送最终服务值。';

  @override
  String get providerUnreadMessagesTitle => '您有来自客户的新消息';

  @override
  String providerUnreadMessagesJob(Object jobTitle) {
    return '在职：$jobTitle';
  }

  @override
  String get providerJobsTitle => '我的职位';

  @override
  String get providerJobsTabOpen => '打开';

  @override
  String get providerJobsTabCompleted => '完全的';

  @override
  String get providerJobsTabCancelled => '取消';

  @override
  String providerJobsLoadError(Object error) {
    return '加载作业时出错：$error';
  }

  @override
  String get providerJobsEmptyOpen => '您还没有空缺职位。\\n转到主页并接受订单。';

  @override
  String get providerJobsEmptyCompleted => '您还没有完成作业。';

  @override
  String get providerJobsEmptyCancelled => '您还没有取消作业。';

  @override
  String scheduledForDate(Object date) {
    return '预定时间：$date';
  }

  @override
  String get viewDetailsTooltip => '查看详情';

  @override
  String clientPaidValueLabel(Object value) {
    return '客户付款：$value';
  }

  @override
  String providerEarningsFeeLabel(Object value, Object fee) {
    return '您收到：$value - 费用：$fee';
  }

  @override
  String serviceValueLabel(Object value) {
    return '服务价值：$value';
  }

  @override
  String get cancelJobTitle => '取消作业';

  @override
  String get cancelJobPrompt => '您确定要取消此作业吗？\\n该订单可能可供其他提供商使用。';

  @override
  String get cancelJobReasonLabel => '取消原因（可选）：';

  @override
  String get cancelJobReasonFieldLabel => '原因';

  @override
  String get cancelJobDetailLabel => '取消详情';

  @override
  String get cancelJobDetailRequired => '请添加详细信息。';

  @override
  String get cancelJobSuccess => '作业取消了。';

  @override
  String cancelJobError(Object error) {
    return '取消作业时出错：$error';
  }

  @override
  String get providerAccountProfileTitle => '查看我的个人资料';

  @override
  String get providerAccountProfileSubtitle => '供应商简介';

  @override
  String get activateOnlinePaymentsSubtitle => '启用在线支付';

  @override
  String get statusProviderWaiting => '新请求';

  @override
  String get statusQuoteWaitingCustomer => '等待客户回复';

  @override
  String get statusAcceptedToStart => '已接受（准备开始）';

  @override
  String get statusInProgress => '进行中';

  @override
  String get statusCompleted => '完全的';

  @override
  String get orderDefaultImmediateTitle => '加急服务';

  @override
  String get locationServiceDisabled => '设备上的位置服务已禁用。';

  @override
  String get locationPermissionDenied => '位置权限被拒绝。\\n无法获取当前位置。';

  @override
  String get locationPermissionDeniedForever => '位置权限被永久拒绝。\\n在设备设置中启用位置。';

  @override
  String locationFetchError(Object error) {
    return '获取位置时出错：$error';
  }

  @override
  String get formNotReadyError => '表格还没有准备好。再试一次。';

  @override
  String get missingRequiredFieldsError => '缺少必填字段。检查红色字段。';

  @override
  String get scheduleDateTimeRequiredError => '选择服务日期和时间。';

  @override
  String get scheduleDateTimeFutureError => '选择未来的日期/时间。';

  @override
  String get categoryRequiredError => '选择一个类别。';

  @override
  String get orderUpdatedSuccess => '订单更新成功！';

  @override
  String get orderCreatedSuccess => '订单已创建！寻找供应商...';

  @override
  String orderUpdateError(Object error) {
    return '更新订单时出错：$error';
  }

  @override
  String orderCreateError(Object error) {
    return '创建订单时出错：$error';
  }

  @override
  String get orderTitleExamplePlumbing => '例如：水槽下方的水管漏水';

  @override
  String get orderTitleExampleElectric => '例如：客厅插座坏了+安装吸顶灯';

  @override
  String get orderTitleExampleCleaning => '例如：全面清洁两居室公寓（厨房、卫生间、窗户、地板）。';

  @override
  String get orderTitleHintImmediate => '简要解释发生了什么以及您需要什么。';

  @override
  String get orderTitleHintScheduled => '说明您何时需要服务、详细位置以及需要做什么。';

  @override
  String get orderTitleHintQuote => '描述您想要接收提案的服务。';

  @override
  String get orderTitleHintDefault => '描述您需要的服务。';

  @override
  String get orderDescriptionExampleCleaning => '例如：全面清洁两居室公寓（厨房、卫生间、窗户、地板）。';

  @override
  String get orderDescriptionHintImmediate => '简要解释发生了什么以及您需要什么。';

  @override
  String get orderDescriptionHintScheduled => '说明您何时需要服务、详细位置以及需要做什么。';

  @override
  String get orderDescriptionHintQuote => '描述您想要的服务、大致预算（如果您有的话）以及重要细节。';

  @override
  String get orderDescriptionHintDefault => '更详细地解释一下您需要什么。';

  @override
  String get priceModelTitle => '价格模型';

  @override
  String get priceModelQuoteInfo => '这项服务是按报价提供的。提供商将提出最终价格。';

  @override
  String get priceTypeLabel => '价格类型';

  @override
  String get paymentTypeLabel => '支付方式';

  @override
  String get orderHeaderQuoteTitle => '报价请求';

  @override
  String get orderHeaderQuoteSubtitle => '描述您的需求，提供商可以发送一个范围（最小/最大）。';

  @override
  String get orderHeaderImmediateTitle => '即时服务';

  @override
  String get orderHeaderImmediateSubtitle => '我们将尽快致电可用的提供商。';

  @override
  String get orderHeaderScheduledTitle => '预定服务';

  @override
  String get orderHeaderScheduledSubtitle => '选择提供商来找您的日期和时间。';

  @override
  String get orderHeaderDefaultTitle => '新订单';

  @override
  String get orderHeaderDefaultSubtitle => '描述您需要的服务。';

  @override
  String get orderEditTitle => '编辑订单';

  @override
  String get orderNewTitle => '新订单';

  @override
  String get whenServiceNeededLabel => '您什么时候需要该服务？';

  @override
  String get categoryLabel => '类别';

  @override
  String get categoryHint => '选择服务类别';

  @override
  String get orderTitleLabel => '订单标题';

  @override
  String get orderTitleRequiredError => '为订单写一个标题。';

  @override
  String get orderDescriptionOptionalLabel => '说明（可选）';

  @override
  String get locationApproxLabel => '大概位置';

  @override
  String get locationSelectedLabel => '地点选定。';

  @override
  String get locationSelectPrompt => '选择执行服务的地点（大约）。';

  @override
  String get locationAddressHint => '街道、门牌号、楼层、参考号（可选，但很有帮助）';

  @override
  String get locationGetting => '获取位置...';

  @override
  String get locationUseCurrent => '使用当前位置';

  @override
  String get locationChooseOnMap => '在地图上选择';

  @override
  String get serviceDateTimeLabel => '服务日期和时间';

  @override
  String get serviceDateTimePick => '选择日期和时间';

  @override
  String get saveChangesButton => '保存更改';

  @override
  String get submitOrderButton => '请求服务';

  @override
  String get mapSelectTitle => '在地图上选择位置';

  @override
  String get mapSelectInstruction => '将地图拖至大概的服务位置，然后确认。';

  @override
  String get mapSelectConfirm => '确认位置';

  @override
  String get orderDetailsTitle => '订单详情';

  @override
  String orderLoadError(Object error) {
    return '加载订单时出错：$error';
  }

  @override
  String get orderNotFound => '未找到订单。';

  @override
  String get scheduledNoDate => '预定（未设定日期）';

  @override
  String get orderValueRejectedTitle => '客户拒绝了建议的价值。';

  @override
  String get orderValueRejectedBody => '与客户聊天并在一致后提出新的价值。';

  @override
  String get actionProposeNewValue => '提出新价值';

  @override
  String get noShowReportedTitle => '报告未出现';

  @override
  String noShowReportedBy(Object role) {
    return '报告人：$role';
  }

  @override
  String noShowReportedAt(Object date) {
    return '于：$date';
  }

  @override
  String get noShowTitle => '缺席';

  @override
  String get noShowDescription => '如果对方没有出现，您可以举报。';

  @override
  String get noShowReportAction => '报告未出现';

  @override
  String get orderInfoTitle => '订单信息';

  @override
  String get orderInfoIdLabel => '订单号';

  @override
  String get orderInfoCreatedAtLabel => '创建于';

  @override
  String get orderInfoStatusLabel => '地位';

  @override
  String get orderInfoModeLabel => '模式';

  @override
  String get orderInfoValueLabel => '价值';

  @override
  String get orderLocationTitle => '订单地点';

  @override
  String get orderDescriptionTitle => '订单说明';

  @override
  String get providerMessageTitle => '提供者消息';

  @override
  String get actionEditOrder => '编辑订单';

  @override
  String get actionCancelOrder => '取消订单';

  @override
  String get cancelOrderTitle => '取消订单';

  @override
  String get orderCancelInProgressWarning => '该服务已经在进行中。\n现在取消可能会导致部分退款。';

  @override
  String get orderCancelConfirmPrompt => '您确定要取消此订单吗？';

  @override
  String get orderCancelReasonLabel => '取消原因';

  @override
  String get orderCancelReasonOptionalLabel => '原因（可选）';

  @override
  String orderCancelledSnack(Object message) {
    return '订单已取消。 $message。';
  }

  @override
  String orderCancelError(Object error) {
    return '取消订单时出错：$error';
  }

  @override
  String get noShowReportDialogTitle => '报告未出现';

  @override
  String get noShowReportDialogDescription => '仅当其他人没有出现时才使用此功能。';

  @override
  String get noShowReasonOptionalLabel => '原因（可选）';

  @override
  String get actionReport => '报告';

  @override
  String get noShowReportSuccess => '报告未出现。';

  @override
  String noShowReportError(Object error) {
    return '报告未出现错误：$error';
  }

  @override
  String get orderFinalValueTitle => '提出新的最终值';

  @override
  String get orderFinalValueLabel => '价值';

  @override
  String get orderFinalValueInvalid => '输入有效值。';

  @override
  String get orderFinalValueSent => '发送给客户的新价值。';

  @override
  String orderFinalValueSendError(Object error) {
    return '发送新值时出错：$error';
  }

  @override
  String get ratingSentTitle => '评级已发送';

  @override
  String get ratingProviderTitle => '提供商评级';

  @override
  String get ratingPrompt => '留下 1 到 5 的评分。';

  @override
  String get ratingCommentLabel => '评论（可选）';

  @override
  String get ratingSendAction => '发送评级';

  @override
  String get ratingSelectError => '选择一个评级。';

  @override
  String get ratingSentSnack => '评级已发送。';

  @override
  String ratingSendError(Object error) {
    return '发送评级时出错：$error';
  }

  @override
  String get timelineCreated => '已创建';

  @override
  String get timelineAccepted => '公认';

  @override
  String get timelineInProgress => '进行中';

  @override
  String get timelineCancelled => '取消';

  @override
  String get timelineCompleted => '完全的';

  @override
  String get lookingForProviderBanner => '我们仍在寻找该订单的供应商。';

  @override
  String get actionView => '看法';

  @override
  String get chatNoMessagesSubtitle => '还没有消息';

  @override
  String chatPreviewWithTime(Object preview, Object time) {
    return '$preview • $time';
  }

  @override
  String chatMessageCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ???',
      one: '1 ???',
    );
    return '$_temp0';
  }

  @override
  String get actionClose => '关闭';

  @override
  String get actionOpen => '打开';

  @override
  String get chatAuthRequired => '您需要经过身份验证才能发送消息。';

  @override
  String chatSendError(Object error) {
    return '发送消息时出错：$error';
  }

  @override
  String get todayLabel => '今天';

  @override
  String get yesterdayLabel => '昨天';

  @override
  String chatLoadError(Object error) {
    return '加载消息时出错：$error';
  }

  @override
  String get chatEmptyMessage => '还没有消息。\n送第一张吧！';

  @override
  String get chatInputHint => '写留言...';

  @override
  String get chatLoginHint => '登录以发送消息';

  @override
  String get roleLabelSystem => '系统';

  @override
  String get youLabel => '你';

  @override
  String distanceMeters(Object meters) {
    return '$meters 米';
  }

  @override
  String distanceKilometers(Object kilometers) {
    return '$kilometers 公里';
  }

  @override
  String get etaLessThanMinute => '<1分钟';

  @override
  String etaMinutes(Object minutes) {
    return '$minutes 分钟';
  }

  @override
  String etaHours(Object hours) {
    return '$hours 小时';
  }

  @override
  String etaHoursMinutes(Object hours, Object minutes) {
    return '$hours 小时 $minutes 米';
  }

  @override
  String mapEtaLabel(Object eta, Object distance) {
    return '预计到达时间 $eta - $distance';
  }

  @override
  String get mapOpenAction => '打开地图';

  @override
  String get orderMapTitle => '订单图';

  @override
  String get orderChatTitle => '讨论此订单';

  @override
  String get messagesTitle => '留言';

  @override
  String get messagesSearchHint => '搜索消息';

  @override
  String messagesLoadError(Object error) {
    return '加载对话时出错：$error';
  }

  @override
  String get messagesEmpty => '你们还没有任何对话。\n一旦您与提供商/客户聊天，他们就会出现在此处。';

  @override
  String get messagesNewConversationTitle => '新对话';

  @override
  String get messagesNewConversationBody => '要与提供商或客户开始对话，请转到您的“订单”或接受新订单。';

  @override
  String get messagesFilterAll => '全部';

  @override
  String get messagesFilterUnread => '未读';

  @override
  String get messagesFilterFavorites => '收藏夹';

  @override
  String get messagesFilterGroups => '团体';

  @override
  String messagesFilterEmpty(Object filter) {
    return '“$filter”中没有任何内容';
  }

  @override
  String get messagesSearchNoResults => '未找到任何对话。';

  @override
  String get messagesPinConversation => '固定对话';

  @override
  String get messagesUnpinConversation => '取消固定对话';

  @override
  String get chatPresenceOnline => '在线的';

  @override
  String chatPresenceLastSeenAt(Object time) {
    return '最后一次出现在 $time';
  }

  @override
  String chatPresenceLastSeenYesterdayAt(Object time) {
    return '最后一次出现在昨天，时间为 $time';
  }

  @override
  String chatPresenceLastSeenOn(Object date, Object time) {
    return '最后一次出现于 $date 的 $time';
  }

  @override
  String get chatImageTooLarge => '图片太大（最大 15MB）。';

  @override
  String chatImageSendError(Object error) {
    return '发送图像时出错：$error';
  }

  @override
  String get chatFileReadError => '无法读取文件。';

  @override
  String get chatFileTooLarge => '文件太大（最大 20MB）。';

  @override
  String chatFileSendError(Object error) {
    return '发送文件时出错：$error';
  }

  @override
  String get chatAudioReadError => '无法读取音频。';

  @override
  String get chatAudioTooLarge => '音频太大（最大 20MB）。';

  @override
  String chatAudioSendError(Object error) {
    return '发送音频时出错：$error';
  }

  @override
  String get chatAttachFile => '发送文件';

  @override
  String get chatAttachGallery => '发送照片（图库）';

  @override
  String get chatAttachCamera => '拍照（相机）';

  @override
  String get chatAttachAudio => '发送音频（文件）';

  @override
  String get chatAttachAudioSubtitle => '选择一个音频文件（mp3/m4a/wav/...）。';

  @override
  String get chatOpenLink => '打开链接';

  @override
  String get chatAttachTooltip => '附';

  @override
  String get chatSendTooltip => '发送';

  @override
  String get chatSearchAction => '搜索';

  @override
  String get chatSearchHint => '搜索消息';

  @override
  String get chatSearchEmpty => '输入要搜索的内容。';

  @override
  String get chatSearchNoResults => '没有找到消息。';

  @override
  String get chatMediaAction => '媒体、链接和文件';

  @override
  String get chatMediaTitle => '媒体、链接和文件';

  @override
  String get chatMediaPhotosTab => '照片';

  @override
  String get chatMediaLinksTab => '链接';

  @override
  String get chatMediaAudioTab => '声音的';

  @override
  String get chatMediaFilesTab => '文件';

  @override
  String get chatMediaEmptyPhotos => '还没有照片。';

  @override
  String get chatMediaEmptyLinks => '还没有链接。';

  @override
  String get chatMediaEmptyAudio => '还没有音频。';

  @override
  String get chatMediaEmptyFiles => '还没有文件。';

  @override
  String get chatFavoritesAction => '已加星标';

  @override
  String get chatFavoritesTitle => '加星标的消息';

  @override
  String get chatFavoritesEmpty => '您还没有加星标的消息。';

  @override
  String get chatStarAction => '添加到收藏夹';

  @override
  String get chatUnstarAction => '从收藏夹中删除';

  @override
  String get chatViewProviderProfileAction => '查看提供商资料';

  @override
  String get chatViewCustomerProfileAction => '查看客户资料';

  @override
  String get chatIncomingCall => '来电';

  @override
  String get chatCallStartedVideo => '视频通话开始';

  @override
  String get chatCallStartedVoice => '语音通话开始';

  @override
  String get chatImageLabel => '图像';

  @override
  String get chatAudioLabel => '声音的';

  @override
  String get chatFileLabel => '文件';

  @override
  String get chatCallEntryLabel => '称呼';

  @override
  String get chatNoSession => '没有活动会话。登录以访问聊天。';

  @override
  String get chatTitleFallback => '聊天';

  @override
  String get chatVideoCallAction => '视频电话';

  @override
  String get chatVoiceCallAction => '称呼';

  @override
  String get chatMarkReadAction => '标记为已读';

  @override
  String get chatCallMissingParticipant => '其他参与者尚未分配到此订单。';

  @override
  String get chatCallStartError => '无法开始通话。';

  @override
  String chatCallMessageVideo(Object url) {
    return '视频通话：$url';
  }

  @override
  String chatCallMessageVoice(Object url) {
    return '致电：$url';
  }

  @override
  String get profileProviderTitle => '供应商简介';

  @override
  String get profileCustomerTitle => '客户简介';

  @override
  String get profileAboutTitle => '关于';

  @override
  String get profileLocationTitle => '地点';

  @override
  String get profileServicesTitle => '服务';

  @override
  String get profilePortfolioTitle => '文件夹';

  @override
  String get chatOpenFullAction => '打开完整聊天';

  @override
  String get chatOpenFullUnavailable => '其他参与者尚未分配到此订单。';

  @override
  String get chatReplyAction => '回复';

  @override
  String get chatCopyAction => '复制';

  @override
  String get chatDeleteAction => '删除';

  @override
  String get storyNewTitle => '新故事';

  @override
  String get storyPublishing => '发布故事...';

  @override
  String get storyPublished => '故事发表！ 24 小时后到期。';

  @override
  String storyPublishError(Object error) {
    return '发布故事时出错：$error';
  }

  @override
  String get storyCaptionHint => '标题（可选）';

  @override
  String get actionPublish => '发布';

  @override
  String get snackOrderRemoved => '订单已删除。';

  @override
  String get snackClientCancelledOrder => '客户取消订单。';

  @override
  String get snackOrderCancelled => '订单已取消。';

  @override
  String get snackOrderAcceptedByAnother => '另一家供应商接受了订单。';

  @override
  String get snackOrderUpdated => '订单已更新。';

  @override
  String get snackUserNotAuthenticated => '用户未经过身份验证。';

  @override
  String get snackOrderAcceptedCanQuote => '订单已接受。您可以在订单详细信息中发送报价。';

  @override
  String get snackOrderAcceptedSuccess => '订单已接受。';

  @override
  String snackErrorAcceptingOrder(Object error) {
    return '接受订单时出错：$error';
  }

  @override
  String get dialogTitleOrderAccepted => '订单已接受';

  @override
  String get dialogContentQuotePrompt => '该订单采用报价方式。\n\n您想现在发送报价范围吗？';

  @override
  String get dialogTitleProposeService => '提出服务建议';

  @override
  String get dialogContentProposeService => '设置此服务的价格范围。\n包括旅行和劳务。';

  @override
  String get labelMinValue => '最小值';

  @override
  String get labelMaxValue => '最大值';

  @override
  String get labelMessageOptional => '给客户的消息（可选）';

  @override
  String hintExampleValue(Object value) {
    return '例如：$value';
  }

  @override
  String get hintProposalMessage => '例如：包括旅行。大的材料是额外的。';

  @override
  String get snackFillValidValues => '输入有效的最小值和最大值。';

  @override
  String get snackMinCannotBeGreaterThanMax => '最小值不能大于最大值。';

  @override
  String get snackProposalSent => '提案已发送给客户。';

  @override
  String snackErrorSendingProposal(Object error) {
    return '发送提案时出错：$error';
  }
}
