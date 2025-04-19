import 'package:drive_notes/core/error/app_exceptions.dart';
import 'package:drive_notes/features/auth/data/datasources/auth_datasource.dart';
import 'package:drive_notes/features/auth/data/models/user_model.dart';

class AuthRepository {
  final AuthDataSource _authDataSource;

  AuthRepository({required AuthDataSource authDataSource})
    : _authDataSource = authDataSource;

  Future<UserModel> signInWithGoogle() async {
    try {
      return await _authDataSource.signInWithGoogle();
    } catch (e) {
      throw AuthException('Sign-in failed: ${e.toString()}');
    }
  }

  Future<bool> isSignedIn() async {
    try {
      return await _authDataSource.isSignedIn();
    } catch (e) {
      return false;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      return await _authDataSource.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _authDataSource.signOut();
    } catch (e) {
      throw AuthException('Sign-out failed: ${e.toString()}');
    }
  }

  Future<String> getAccessToken() async {
    try {
      return await _authDataSource.getAccessToken();
    } catch (e) {
      throw AuthException('Failed to get access token: ${e.toString()}');
    }
  }

  Future<void> refreshAccessToken() async {
    try {
      await _authDataSource.refreshAccessToken();
    } catch (e) {
      throw AuthException('Failed to refresh token: ${e.toString()}');
    }
  }
}
