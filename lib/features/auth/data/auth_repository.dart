import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/errors/failure.dart';

/// Authentication contract for the FastAPI integration.
/// Passwords are only ever sent over HTTPS to the server — never stored.
abstract interface class AuthRepository {
  Future<void> login({required String mobile, required String password});
  Future<void> requestOtp(String mobile);
  Future<void> verifyOtp({required String mobile, required String code});
  Future<void> resetPassword({required String mobile, required String newPassword});
  Future<void> logout();
}

class PreviewAuthRepository implements AuthRepository {
  @override
  Future<void> login({required String mobile, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Preview only: lets the main app be explored. No credentials are checked.
    if (!AppConfig.demoMode) throw const NotConnectedFailure();
  }

  // OTP and password recovery must never be simulated.
  @override
  Future<void> requestOtp(String mobile) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    throw const NotConnectedFailure();
  }

  @override
  Future<void> verifyOtp({required String mobile, required String code}) async =>
      throw const NotConnectedFailure();

  @override
  Future<void> resetPassword({required String mobile, required String newPassword}) async =>
      throw const NotConnectedFailure();

  @override
  Future<void> logout() async {}
}

final authRepositoryProvider = Provider<AuthRepository>((_) => PreviewAuthRepository());
