import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_models.dart';
import 'auth_repository.dart';

/// Who is using the app right now.
sealed class AuthState {
  const AuthState();
}

/// Still reading the saved session (splash).
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class SignedOut extends AuthState {
  const SignedOut({this.sessionExpired = false});

  /// True when the server ended the session (shows a notice on the login screen).
  final bool sessionExpired;
}

class SignedIn extends AuthState {
  const SignedIn(this.user);
  final AuthUser user;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Any 401 on a signed-in request (token revoked / expired) signs the user out.
    ref.read(apiClientProvider).onUnauthorized = () {
      if (state is SignedIn) {
        _repo.clear();
        state = const SignedOut(sessionExpired: true);
      }
    };
    return const AuthUnknown();
  }

  /// Splash: restore the saved session. Throws [ApiException] when offline so
  /// the splash can offer a retry instead of logging the user out.
  Future<void> restore() async {
    final user = await _repo.restore();
    state = user == null ? const SignedOut() : SignedIn(user);
  }

  Future<AuthUser> login(String mobile, String password) async {
    final user = await _repo.login(mobile, password);
    state = SignedIn(user);
    return user;
  }

  /// After the application is created the applicant is signed in.
  Future<AuthUser> submitApplication(Map<String, dynamic> body) async {
    final user = await _repo.submitApplication(body);
    state = SignedIn(user);
    return user;
  }

  /// Re-reads the user (e.g. after approval) so the app opens the right screen.
  Future<AuthUser> refreshUser() async {
    final user = await _repo.me();
    state = SignedIn(user);
    return user;
  }

  Future<void> logout() async {
    await _repo.clear();
    state = const SignedOut();
  }
}
