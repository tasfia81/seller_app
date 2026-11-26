import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/api_client.dart';
import 'auth_models.dart';

/// One shared HTTP client for the whole app.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));

/// Login, sign-up and KYC calls. The token lives in the phone's secure storage
/// (Android Keystore), never in plain preferences.
class AuthRepository {
  AuthRepository(this._api, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  final ApiClient _api;
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'ss_investor_token';

  /// Restores a saved session. Returns null when there is none or it expired.
  Future<AuthUser?> restore() async {
    String? token;
    try {
      token = await _storage.read(key: _tokenKey);
    } catch (_) {
      token = null; // Unreadable keystore entry (e.g. after a backup restore): sign in again.
    }
    if (token == null || token.isEmpty) return null;
    _api.token = token;
    try {
      return await me();
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.status == 403) {
        await clear();
        return null;
      }
      rethrow; // Offline etc.: the caller decides what to show.
    }
  }

  Future<AuthUser> me() async => AuthUser.fromJson(Map<String, dynamic>.from(await _api.get('/auth/me') as Map));

  Future<AuthUser> login(String mobile, String password) async {
    final res = Map<String, dynamic>.from(await _api.post('/auth/login', {'identifier': mobile, 'password': password}) as Map);
    final user = AuthUser.fromJson(Map<String, dynamic>.from(res['user'] as Map));
    if (user.id.isEmpty || res['access_token'] == null) {
      throw const ApiException('সার্ভারের উত্তর বোঝা যায়নি। আবার চেষ্টা করুন।');
    }
    final role = (res['user'] as Map)['role'];
    if (role != 'investor') {
      throw const ApiException('এই অ্যাপ শুধু বিনিয়োগকারীদের জন্য। সেলার বা অ্যাডমিন নিজেদের অ্যাপ/প্যানেল ব্যবহার করুন।', code: 'wrong_app');
    }
    await _save('${res['access_token']}');
    return user;
  }

  Future<void> clear() async {
    _api.token = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }

  Future<void> _save(String token) async {
    _api.token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> requestApplicationOtp(String mobile) async {
    await _api.post('/investor/application/otp', {'mobile': mobile});
  }

  Future<void> requestPasswordOtp(String mobile) async {
    await _api.post('/investor/password/otp', {'mobile': mobile});
  }

  Future<void> resetPassword(String mobile, String code, String password) async {
    await _api.post('/investor/password/reset', {
      'mobile': mobile, 'code': code, 'new_password': password,
    });
  }

  /// True when no account uses this mobile yet.
  Future<bool> mobileAvailable(String mobile) async {
    final res = await _api.post('/investor/mobile-check', {'mobile': mobile}) as Map;
    return res['available'] == true;
  }

  /// Creates the application and signs the applicant in.
  Future<AuthUser> submitApplication(Map<String, dynamic> body) async {
    final res = Map<String, dynamic>.from(await _api.post('/investor/applications', body) as Map);
    await _save('${res['access_token']}');
    return AuthUser.fromJson(Map<String, dynamic>.from(res['user'] as Map));
  }

  Future<ApplicationStatus> uploadDocument(String kind, Uint8List bytes) async =>
      ApplicationStatus.fromJson(Map<String, dynamic>.from(await _api.upload('/investor/application/documents/$kind', bytes, name: kind) as Map));

  Future<ApplicationStatus> myApplication() async =>
      ApplicationStatus.fromJson(Map<String, dynamic>.from(await _api.get('/investor/application') as Map));

  Future<ApplicationStatus> resubmit() async =>
      ApplicationStatus.fromJson(Map<String, dynamic>.from(await _api.post('/investor/application/resubmit') as Map));
}
