// Local Plaid Sandbox token server. Keeps the Plaid secret and access_tokens
// off the device.
//
//   cd tool/plaid_server && dart pub get
//   PLAID_CLIENT_ID=... PLAID_SECRET=... dart run bin/server.dart
//
// Without keys it still starts: /accounts returns an empty list and
// /link-token answers 503 saying which keys are missing.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

const _port = 3001;
final _plaidBaseUrl = Uri.parse('https://sandbox.plaid.com');
final _clientId = Platform.environment['PLAID_CLIENT_ID'];
final _secret = Platform.environment['PLAID_SECRET'];

// shortcut: access tokens live in memory and vanish on restart; use a store
// if this ever goes beyond Sandbox.
final _accessTokens = <String>[];

Future<void> main() async {
  await io.serve(_handle, InternetAddress.loopbackIPv4, _port);
  stdout.writeln('Plaid token server on http://localhost:$_port '
      '(keys ${_hasKeys ? 'loaded' : 'MISSING'})');
}

bool get _hasKeys =>
    (_clientId?.isNotEmpty ?? false) && (_secret?.isNotEmpty ?? false);

Future<Response> _handle(Request request) async {
  try {
    switch ('${request.method} /${request.url.path}') {
      case 'POST /api/v1/plaid/link-token':
        final result = await _plaid('/link/token/create', {
          'client_name': 'Kind Banking',
          'language': 'en',
          'country_codes': ['US'],
          'user': {'client_user_id': 'kind-banking-sample-user'},
          'products': ['auth'],
          'android_package_name': 'com.example.sample_banking',
        });
        return _json({'link_token': result['link_token']});

      case 'POST /api/v1/plaid/exchange':
        final body = jsonDecode(await request.readAsString());
        final publicToken = body is Map ? body['public_token'] : null;
        if (publicToken is! String || !publicToken.startsWith('public-')) {
          return _json({'message': 'public_token is missing or invalid'}, 400);
        }
        final result = await _plaid(
          '/item/public_token/exchange',
          {'public_token': publicToken},
        );
        _accessTokens.add(result['access_token'] as String);
        return _json({'accounts': await _allAccounts()});

      case 'GET /api/v1/plaid/accounts':
        return _json({'accounts': await _allAccounts()});
    }
    return _json({'message': 'Not found'}, 404);
  } on _PlaidError catch (e) {
    stderr.writeln('Plaid error: ${e.message}');
    return _json({'message': e.message}, e.status);
  } on FormatException {
    return _json({'message': 'Body must be JSON'}, 400);
  }
}

Future<List<Map<String, Object?>>> _allAccounts() async {
  final accounts = <Map<String, Object?>>[];
  for (final token in _accessTokens) {
    final result = await _plaid('/accounts/get', {'access_token': token});
    final item = result['item'] as Map<String, dynamic>;
    final institution = item['institution_name'] ?? item['institution_id'];
    for (final a in (result['accounts'] as List).cast<Map<String, dynamic>>()) {
      final balances = a['balances'] as Map<String, dynamic>;
      accounts.add({
        'id': a['account_id'],
        'institution': institution,
        'name': a['name'],
        'mask': a['mask'],
        'type': a['subtype'] ?? a['type'],
        'balance': balances['current'],
        'currency': balances['iso_currency_code'] ?? 'USD',
      });
    }
  }
  return accounts;
}

Future<Map<String, dynamic>> _plaid(String path, Map<String, Object?> body) async {
  if (!_hasKeys) {
    throw _PlaidError(
      503,
      'Plaid keys not set. Restart the token server with '
      'PLAID_CLIENT_ID and PLAID_SECRET (Sandbox) in the environment.',
    );
  }
  final response = await http.post(
    _plaidBaseUrl.replace(path: path),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'client_id': _clientId, 'secret': _secret, ...body}),
  );
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  if (response.statusCode != 200) {
    throw _PlaidError(
      502,
      '${json['error_code']}: ${json['display_message'] ?? json['error_message']}',
    );
  }
  return json;
}

Response _json(Object body, [int status = 200]) => Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

class _PlaidError implements Exception {
  final int status;
  final String message;
  _PlaidError(this.status, this.message);
}
