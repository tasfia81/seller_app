import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seller_app/core/api/api_client.dart';
import 'package:seller_app/core/errors/failure.dart';
import 'package:seller_app/features/auth/data/auth_repository.dart';
import 'package:seller_app/features/auth/data/seller_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('seller login stores a session and logout clears it', () async {
    final user = {'role': 'seller', 'seller_status': 'active'};
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/login') {
        expect(jsonDecode(request.body), {
          'identifier': '01712345678',
          'password': 'seller1234',
        });
        return http.Response(jsonEncode({'user': user, 'access_token': 'seller-token'}), 200);
      }
      expect(request.url.path, '/api/v1/auth/me');
      expect(request.headers['authorization'], 'Bearer seller-token');
      return http.Response(jsonEncode(user), 200);
    });
    SellerSession createSession() => SellerSession(
      ApiClient(client: client, baseUrl: 'https://example.test/api/v1'),
    );

    await ApiAuthRepository(createSession()).login(mobile: '01712345678', password: 'seller1234');
    final restored = createSession();
    await restored.restore();
    expect(restored.active, isTrue);
    await restored.clear();
    expect(restored.user, isNull);
    expect(restored.api.token, isNull);
    final signedOut = createSession();
    await signedOut.restore();
    expect(signedOut.user, isNull);
  });

  test('seller session rejects a token for another role', () async {
    final session = SellerSession(ApiClient());
    await expectLater(session.signIn({
      'user': {'role': 'investor'},
      'access_token': 'investor-token',
    }), throwsA(isA<PermissionFailure>()));
    expect(session.user, isNull);
    expect(session.api.token, isNull);
  });
}
