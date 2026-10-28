/// Abstract interface for linking external bank accounts
/// Allows easy swapping of providers (Plaid, MX, Finicity, etc.)
abstract class AccountLinkingService {
  /// Open the provider's linking UI with a server-issued [linkToken] and
  /// complete when the user finishes or leaves it.
  /// Throws [AccountLinkException] if the UI cannot be opened.
  Future<AccountLinkResult> link(String linkToken);

  /// Get the name of this linking provider
  String get serviceName;
}

/// Outcome of a linking session
sealed class AccountLinkResult {
  const AccountLinkResult();
}

/// User linked an account; [publicToken] must go straight to the server.
class AccountLinkSuccess extends AccountLinkResult {
  final String publicToken;

  const AccountLinkSuccess(this.publicToken);
}

/// User left the flow; [errorMessage] is set only if it ended on an error.
class AccountLinkCancelled extends AccountLinkResult {
  final String? errorMessage;

  const AccountLinkCancelled({this.errorMessage});
}

/// Thrown when the provider's linking UI cannot start
class AccountLinkException implements Exception {
  final String message;

  const AccountLinkException(this.message);

  @override
  String toString() => 'AccountLinkException: $message';
}
