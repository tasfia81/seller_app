import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/failure.dart';

final sellerSessionProvider = Provider((ref) {
  final session = SellerSession(ApiClient());
  ref.onDispose(session.dispose);
  return session;
});

class SellerSession extends ChangeNotifier {
  SellerSession(this.api) {
    api.onUnauthorized = () => unawaited(clear().catchError((Object _) {}));
  }

  final ApiClient api;
  final _storage = const FlutterSecureStorage();
  static const _key = 'street_sales_seller_token';
  Map<String, dynamic>? user;
  bool get active => user?['seller_status'] == 'active';

  Future<void> signIn(Map response) async {
    final account = Map<String, dynamic>.from(response['user'] as Map);
    final token = response['access_token'];
    if (account['role'] != 'seller' || token is! String || token.isEmpty) {
      throw const PermissionFailure();
    }
    await _storage.write(key: _key, value: token);
    api.token = token;
    user = account;
    notifyListeners();
  }

  Future<void> restore() async {
    api.token = await _storage.read(key: _key);
    if (api.token == null) return;
    try {
      final account = Map<String, dynamic>.from(await api.get('/auth/me') as Map);
      if (account['role'] != 'seller') {
        await clear();
        return;
      }
      user = account;
      notifyListeners();
    } on ApiException catch (error) {
      if (error.status == 401 || error.status == 403) await clear();
      rethrow;
    }
  }

  Future<void> clear() async {
    api.token = null;
    user = null;
    notifyListeners();
    await _storage.delete(key: _key);
  }
}
