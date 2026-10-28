# Plaid Integration

Kind Banking can link an account at another bank through **Plaid Link**, using Plaid's Flutter plugin [`plaid_link_flutter`](https://github.com/plaid/plaid-link-flutter) `^1.2.1`. It runs against the Plaid **Sandbox** only and exists to learn the SDK.

- **Commit:** `04af27f add the plaid sdk`
- **Status:** Built and tested with fakes. Not yet run against real Plaid: Sandbox keys are still needed (see [Running it](#running-it)).
- **Entry point:** Hub → **Link Bank** tile → `/linked-accounts`

---

## 1. Plaid in 2 minutes

Plaid Link is a ready-made UI where the user picks their bank and signs in. Your app never sees their bank password. The whole flow runs on **three tokens**, and only one of them is safe to keep on the phone:

| Token | Who creates it | Where it lives | Lifetime |
|---|---|---|---|
| `link_token` | Server, via Plaid `/link/token/create` | Sent to the app to open Link | 4 hours |
| `public_token` | Plaid Link, returned on success | App → sent straight to the server | 30 minutes, single use |
| `access_token` | Server, via Plaid `/item/public_token/exchange` | **Server only, never the app** | Until the bank link is removed |

Creating a `link_token` and exchanging a `public_token` both need the Plaid **secret**, so **a backend is required**. Mockoon cannot fake this, because Plaid rejects made-up link tokens.

### The flow

```
App                      Token server (localhost:3001)        Plaid
 │  POST /link-token  ──────▶  /link/token/create  ─────────▶  │
 │  ◀──── link_token  ───────                                  │
 │                                                             │
 │  open Plaid Link UI  ──────────────────────────────────────▶│  user picks bank, signs in
 │  ◀──── public_token (onSuccess) ────────────────────────────│
 │                                                             │
 │  POST /exchange  ─────────▶  /item/public_token/exchange ──▶│
 │                              /accounts/get  ───────────────▶│
 │  ◀──── accounts  ─────────   (keeps access_token)           │
```

---

## 2. Architecture

```
LinkedAccountsScreen
      │
LinkedAccountsBloc ── LinkedAccountsUseCase
                          │                 │
                    ApiClient          AccountLinkingService   ← interface (provider-neutral)
                (token server)              │
                                 PlaidAccountLinkingService     ← the ONLY file that imports plaid_link_flutter
```

**The wrapper.** The Plaid SDK sits behind `AccountLinkingService`, the same pattern as `SpeechService` and `TtsService`. The rest of the app never sees a Plaid type.

```dart
abstract class AccountLinkingService {
  Future<AccountLinkResult> link(String linkToken); // throws AccountLinkException
  String get serviceName;
}

sealed class AccountLinkResult {}
class AccountLinkSuccess   extends AccountLinkResult { final String publicToken; }
class AccountLinkCancelled extends AccountLinkResult { final String? errorMessage; } // null = user just closed it
```

`PlaidAccountLinkingService` turns Plaid's callback API (`onSuccess` / `onExit` / `onEvent`) into one `Future<AccountLinkResult>`.

**Swapping Plaid for another provider:**

1. Write `XyzAccountLinkingService implements AccountLinkingService`.
2. Change one line in `AppLocator.accountLinkingService` (`lib/core/locator.dart`).
3. Remove `plaid_link_flutter` from `pubspec.yaml`.
4. Update the token server for the new provider. The server URLs still say `plaid` (see [Known limits](#7-known-limits)).

---

## 3. Every change

### New files

| File | What it does |
|---|---|
| `lib/core/account_linking/account_linking_service.dart` | Provider-neutral interface, result types, `AccountLinkException` |
| `lib/core/account_linking/plaid_account_linking_service.dart` | Plaid implementation. Logs Link event names in debug builds only |
| `lib/core/account_linking/account_linking.dart` | Barrel export |
| `lib/linked_accounts/model/linked_account.dart` | `LinkedAccount` model (`id`, `institution`, `name`, `mask`, `type`, `balance`, `currency`) |
| `lib/linked_accounts/bloc/linked_accounts_entity.dart` | State: `accounts`, `isLoading`, `isLinking`, `errorMessage` |
| `lib/linked_accounts/bloc/linked_accounts_view_model.dart` | View model (`hasError`, `isEmpty`) |
| `lib/linked_accounts/bloc/linked_accounts_use_case.dart` | Loads accounts. Link flow: get token → open Link → exchange |
| `lib/linked_accounts/bloc/linked_accounts_bloc.dart` | Pipes: `viewModelPipe`, `refreshPipe`, `linkPipe` |
| `lib/linked_accounts/ui/linked_accounts_screen.dart` | Loading, error, empty and list states, plus a "Link account" button |
| `tool/plaid_server/bin/server.dart` | Local token server (Dart `shelf`). Holds the secret and access tokens |
| `tool/plaid_server/pubspec.yaml` | Server's own dependencies (`shelf`, `http`), kept out of the app |
| `test/core/account_linking/plaid_account_linking_service_test.dart` | Adapter tests with a fake Plaid platform (4 tests) |
| `test/linked_accounts/linked_accounts_use_case_test.dart` | Use case tests with a fake linking service (5 tests) |

### Changed files

| File | Change |
|---|---|
| `pubspec.yaml` | `plaid_link_flutter: ^1.2.1` |
| `ios/Podfile.lock` | Adds the `plaid_link_flutter` pod |
| `lib/core/locator.dart` | `AppLocator.accountLinkingService`, the place to swap providers |
| `lib/core/config/app_config.dart` | `plaidServerUrl`: `http://localhost:3001` in development, `baseUrl` otherwise |
| `lib/core/network/api_client.dart` | Skips response-body logging for `plaid/` paths, so tokens never reach the console |
| `lib/core/routing/routes.dart` | `Routes.linkedAccounts = '/linked-accounts'` |
| `lib/core/routing/app_router.dart` | `GoRoute` named `linkedAccounts` |
| `lib/core/routing/deep_link_handler.dart` | `/linked-accounts` deep link, requires auth |
| `lib/core/security/sensitive_routes.dart` | New route covered by the fraud-protection overlay guard |
| `lib/hub/ui/simple_hub_screen.dart` | "Link Bank" quick action |

**No platform changes were needed.** The SDK needs iOS 15.0+ and Android minSdk 26. The app already targets iOS 16.0 and minSdk 26.

---

## 4. Token server API

The server binds to `127.0.0.1:3001` only. All responses are JSON, and errors are `{"message": "..."}`.

| Method & path | Body | Returns | Notes |
|---|---|---|---|
| `POST /api/v1/plaid/link-token` | none | `{"link_token": "link-sandbox-..."}` | Products `auth`, country `US`, `android_package_name: com.example.sample_banking` |
| `POST /api/v1/plaid/exchange` | `{"public_token": "public-..."}` | `{"accounts": [...]}` | Rejects tokens that don't start with `public-` (400). Stores the `access_token` in memory |
| `GET /api/v1/plaid/accounts` | none | `{"accounts": [...]}` | Empty list until something is linked. Makes no Plaid call when empty |

| Situation | Status |
|---|---|
| Keys missing | `503` with "Plaid keys not set…" (the app shows this message) |
| Plaid returned an error | `502` with `ERROR_CODE: message` |
| Bad JSON / bad `public_token` | `400` |

---

## 5. Running it

### Without keys (works today)

```bash
cd tool/plaid_server && dart pub get && dart run bin/server.dart
```

The app opens Linked Accounts and shows the empty state. Tapping **Link account** shows "Plaid keys not set".

### With keys (once you have them)

1. Sign up at [dashboard.plaid.com](https://dashboard.plaid.com) and copy the **Sandbox** `client_id` and `secret`.
2. In the Dashboard, register the Android package name `com.example.sample_banking` (needed for Android Link).
3. Start the server with the keys. Keys are read from the environment only; nothing is written to disk.

   ```bash
   cd tool/plaid_server && PLAID_CLIENT_ID=xxx PLAID_SECRET=yyy dart run bin/server.dart
   ```

4. In the app: Hub → **Link Bank** → **Link account** → pick a test bank (e.g. *First Platypus Bank*) → sign in with **`user_good` / `pass_good`**.

**Android emulator:** `localhost` on the emulator is the emulator itself. Point `plaidServerUrl` at `http://10.0.2.2:3001`. The existing Mockoon URL has the same issue.

### Tests

```bash
flutter test test/linked_accounts test/core/account_linking
```

---

## 6. Plaid SDK quick reference

| Item | Value |
|---|---|
| Package | `plaid_link_flutter` 1.2.1 (pub.dev shows an *unverified uploader*; the source is the official `plaid` GitHub org) |
| Native SDKs | iOS LinkKit 7.2.3, Android `com.plaid.link:sdk-core` 6.3.1 |
| Minimums | iOS 15.0, Android minSdk 26, Flutter 3.29.3, Dart 3.7 |
| Platforms | iOS and Android only (no web or desktop) |

**API we use:**

```dart
final session = await createPlaidLinkSession(LinkTokenConfiguration(
  token: linkToken,
  onSuccess: (LinkSuccess s) { /* s.publicToken, s.metadata.institution */ },
  onExit:    (LinkExit e)    { /* e.error == null → user just closed it */ },
  onEvent:   (LinkEvent e)   { /* e.eventName.value, e.metadata.institutionName */ },
));
await session.open();
```

- **`onSuccess` and `onExit` are terminal.** Exactly one fires, then the session cleans itself up.
- **`onEvent`** fires many times (e.g. `OPEN`, `SELECT_INSTITUTION`, `HANDOFF`). It is useful for analytics and debugging.
- **Errors** come as `PlaidLinkException` (`type`, `code`, `message`), thrown by `createPlaidLinkSession` or `open()`.
- **`session.dispose()`** abandons a session that was created but never opened.
- **`PlaidLink.sdkVersion`** returns the *native* SDK version, not the Flutter package version.

**SDK features we don't use yet:**

| Feature | What it is |
|---|---|
| Layer (`createPlaidLayerSession`) | Phone-number-based quick onboarding |
| Headless (`createPlaidHeadlessSession`) | Link with no UI |
| `PlaidEmbeddedSearchView` | Institution search embedded in your own screen |
| FinanceKit (`syncFinanceKit`) | Apple Card / Apple Cash data. iOS 17.4+, needs an Apple entitlement |
| OAuth institutions | Bank opens in its own app or site and returns via a redirect URI. Needs Universal Links and a real device |

---

## 7. Known limits

- **Sandbox only.** The server hard-codes `https://sandbox.plaid.com`.
- **In-memory storage.** Restarting the token server forgets linked accounts (marked `shortcut:` in `server.dart`).
- **Plaid name outside the wrapper.** It still appears in the server URLs (`api/v1/plaid/...`), `AppConfig.plaidServerUrl`, `tool/plaid_server` and the `ApiClient` log filter. These belong to the backend, so they change when the server changes.
- **Not verified on a device or emulator.** Only the iOS simulator build was checked. The end-to-end run waits for Sandbox keys.
- **Flutter warns** that `plaid_link_flutter` hasn't adopted Swift Package Manager yet. This is harmless today, but Flutter says it will become an error in a future version.
- **No l10n.** Screen strings are hard-coded, like the rest of the app.

---

## 8. Security checklist for reviewers

- [ ] Plaid `secret` exists only in the token server's environment. It is not in the app, git, or any file.
- [ ] `access_token` never leaves the server. The app only receives account summaries (name, last 4 digits, type, balance).
- [ ] `public_token` goes from Link straight to `/exchange` and is not stored on the device.
- [ ] No token is logged. `ApiClient` skips bodies for `plaid/` paths, and Link event logs print only the event and institution name, in debug builds only.
- [ ] `/linked-accounts` is in `SensitiveRoutes`, so the overlay and tapjacking guard is on.
- [ ] Token server listens on loopback only.

---

## Links

- Plugin: https://github.com/plaid/plaid-link-flutter
- pub.dev: https://pub.dev/packages/plaid_link_flutter
- Plaid docs: https://plaid.com/docs/link/
- Sandbox test credentials: https://plaid.com/docs/sandbox/test-credentials/
- PRD (Claude Doc): https://claude.ai/artifact/UccKuAVfshjUnUG1G2RUfv
