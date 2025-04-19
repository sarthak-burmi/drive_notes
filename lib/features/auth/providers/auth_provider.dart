import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drive_notes/core/constants/app_constants.dart';
import 'package:drive_notes/features/auth/data/datasources/auth_datasource.dart';
import 'package:drive_notes/features/auth/data/models/user_model.dart';
import 'package:drive_notes/features/auth/data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// Provider for the secure storage
@riverpod
FlutterSecureStorage secureStorage(SecureStorageRef ref) {
  return const FlutterSecureStorage();
}

// Provider for the Dio client
@riverpod
Dio dio(DioRef ref) {
  return Dio();
}

// Provider for GoogleSignIn
@riverpod
GoogleSignIn googleSignIn(GoogleSignInRef ref) {
  return GoogleSignIn(scopes: AppConstants.scopes);
}

// Provider for the auth data source
@riverpod
AuthDataSource authDataSource(AuthDataSourceRef ref) {
  return AuthDataSource(
    dio: ref.watch(dioProvider),
    secureStorage: ref.watch(secureStorageProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  );
}

// Provider for the auth repository
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(authDataSource: ref.watch(authDataSourceProvider));
}

// Provider for the authentication state
@riverpod
class Auth extends _$Auth {
  @override
  Future<UserModel?> build() async {
    return _getCurrentUser();
  }

  Future<UserModel?> _getCurrentUser() async {
    final repository = ref.watch(authRepositoryProvider);
    return await repository.getCurrentUser();
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.watch(authRepositoryProvider);
      final user = await repository.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.watch(authRepositoryProvider);
      await repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<String> getAccessToken() async {
    final repository = ref.watch(authRepositoryProvider);
    return await repository.getAccessToken();
  }

  Future<void> refreshAccessToken() async {
    final repository = ref.watch(authRepositoryProvider);
    await repository.refreshAccessToken();
    // Update the current user
    final user = await _getCurrentUser();
    state = AsyncValue.data(user);
  }
}
