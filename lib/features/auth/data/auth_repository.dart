import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/errors/failure.dart';
import 'seller_session.dart';

/// Authentication contract for the FastAPI integration.
/// Passwords are only ever sent over HTTPS to the server — never stored.
abstract interface class AuthRepository {
  Future<void> login({required String mobile, required String password});
  Future<void> requestOtp(String mobile);
  Future<void> resetPassword({required String mobile, required String code, required String newPassword});
  Future<void> logout();
}

class PreviewAuthRepository implements AuthRepository {
  @override
  Future<void> login({required String mobile, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Preview only: lets the main app be explored. No credentials are checked.
    if (!AppConfig.previewAuth) throw const NotConnectedFailure();
  }

  // OTP and password recovery must never be simulated.
  @override
  Future<void> requestOtp(String mobile) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    throw const NotConnectedFailure();
  }

  @override
  Future<void> resetPassword({required String mobile, required String code, required String newPassword}) async =>
      throw const NotConnectedFailure();

  @override
  Future<void> logout() async {}
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AppConfig.previewAuth
    ? PreviewAuthRepository()
    : ApiAuthRepository(ref.watch(sellerSessionProvider)));

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this.session);
  final SellerSession session;

  @override
  Future<void> login({required String mobile, required String password}) async {
    final response = await session.api.post('/auth/login', {
      'identifier': mobile,
      'password': password,
    });
    await session.signIn(response as Map);
  }

  @override
  Future<void> requestOtp(String mobile) async {
    await session.api.post('/auth/password/otp', {'mobile': mobile});
  }

  @override
  Future<void> resetPassword({
    required String mobile,
    required String code,
    required String newPassword,
  }) async {
    await session.api.post('/auth/password/reset', {
      'mobile': mobile,
      'code': code,
      'new_password': newPassword,
    });
    await session.clear();
  }

  @override
  Future<void> logout() => session.clear();
}
