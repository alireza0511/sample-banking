/// Route path constants for the app
/// These map to deep link URIs: kindbanking://[path]
class Routes {
  Routes._();

  // Auth routes
  static const String login = '/login';

  // Main routes
  static const String hub = '/hub';
  static const String balance = '/balance';
  static const String transfer = '/transfer';
  static const String transferConfirm = '/transfer/confirm';
  static const String transactions = '/transactions';
  static const String transactionDetail = '/transactions/:id';
  static const String payBills = '/pay-bills';
  static const String cards = '/cards';
  static const String cardDetail = '/cards/:id';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String settingsPrivacy = '/settings/privacy';

  // AI Dashboard
  static const String aiDashboard = '/ai-dashboard';

  // Dev routes (only available in debug mode)
  static const String devDeepLinkTest = '/dev/deep-links';
  static const String devLlmStatus = '/dev/llm-status';

  // Initial route
  static const String initial = hub;
}

/// Route parameter names
class RouteParams {
  RouteParams._();

  static const String id = 'id';
  static const String accountId = 'account_id';
  static const String to = 'to';
  static const String amount = 'amount';
  static const String billerId = 'biller_id';
  static const String filter = 'filter';
  static const String prompt = 'prompt';
  static const String section = 'section';
  static const String redirect = 'redirect';
  static const String action = 'action';
  static const String transferId = 'transfer_id';
}
