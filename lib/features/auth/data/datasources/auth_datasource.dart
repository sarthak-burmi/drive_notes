import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:drive_notes/core/constants/app_constants.dart';
import 'package:drive_notes/core/error/app_exceptions.dart';
import 'package:drive_notes/features/auth/data/models/user_model.dart';

class AuthDataSource {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final GoogleSignIn _googleSignIn;

  AuthDataSource({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
    required GoogleSignIn googleSignIn,
  }) : _dio = dio,
       _secureStorage = secureStorage,
       _googleSignIn = googleSignIn;

  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      print("Starting Google Sign-In process");

      // Create a new instance for this sign-in attempt
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: AppConstants.scopes,
      );

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      print("Sign-In result: ${googleUser != null ? 'Success' : 'Canceled'}");

      if (googleUser == null) {
        throw AuthException('Google Sign-In was canceled by the user');
      }

      print("Getting authentication tokens");
      // Get auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print("Token received: ${googleAuth.accessToken != null ? 'Yes' : 'No'}");

      // Store the credentials securely
      await _storeCredentials(googleAuth);

      print("Getting user info");
      // Get user info from Google
      final userInfo = await _getUserInfo(googleAuth.accessToken!);

      print("Sign-In completed successfully");
      return userInfo;
    } catch (e) {
      print("Google Sign-In error: $e");
      throw AuthException('Google Sign-In failed: ${e.toString()}');
    }
  }

  // Store credentials securely
  Future<void> _storeCredentials(GoogleSignInAuthentication auth) async {
    await _secureStorage.write(
      key: AppConstants.tokenKey,
      value: auth.accessToken,
    );

    // Store ID token as well (useful for backend verification)
    await _secureStorage.write(
      key: AppConstants.idTokenKey,
      value: auth.idToken,
    );

    // Calculate expiry time (if not available, assume 1 hour)
    final expiryTime =
        DateTime.now()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch
            .toString();

    await _secureStorage.write(
      key: AppConstants.expiryTimeKey,
      value: expiryTime,
    );
  }

  // Get user info from Google
  Future<UserModel> _getUserInfo(String accessToken) async {
    try {
      final response = await _dio.get(
        'https://www.googleapis.com/oauth2/v2/userinfo',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final Map<String, dynamic> userMap = response.data;

      return UserModel(
        id: userMap['id'],
        email: userMap['email'],
        displayName: userMap['name'],
        photoUrl: userMap['picture'],
      );
    } catch (e) {
      throw AuthException('Failed to get user info: ${e.toString()}');
    }
  }

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      // Fall back to checking stored token if GoogleSignIn fails
      final token = await _secureStorage.read(key: AppConstants.tokenKey);
      final expiryTimeStr = await _secureStorage.read(
        key: AppConstants.expiryTimeKey,
      );

      if (token == null || expiryTimeStr == null) {
        return false;
      }

      final expiryTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(expiryTimeStr),
      );

      return !expiryTime.isBefore(DateTime.now());
    }
  }

  // Get the current user if they're signed in
  Future<UserModel?> getCurrentUser() async {
    final isSignedIn = await this.isSignedIn();
    if (!isSignedIn) {
      return null;
    }

    try {
      final googleUser = _googleSignIn.currentUser;
      if (googleUser != null) {
        // Try to get fresh auth token
        final googleAuth = await googleUser.authentication;
        return await _getUserInfo(googleAuth.accessToken!);
      }

      // Fall back to stored token if GoogleSignIn.currentUser is null
      final accessToken = await getAccessToken();
      return await _getUserInfo(accessToken);
    } catch (e) {
      throw AuthException('Failed to get current user: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore errors from GoogleSignIn, continue with clearing storage
    } finally {
      await _secureStorage.delete(key: AppConstants.tokenKey);
      await _secureStorage.delete(key: AppConstants.idTokenKey);
      await _secureStorage.delete(key: AppConstants.expiryTimeKey);
    }
  }

  // Get access token
  Future<String> getAccessToken() async {
    try {
      // Try to get a fresh token first
      final googleUser = _googleSignIn.currentUser;
      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;

        // Update stored token
        await _secureStorage.write(
          key: AppConstants.tokenKey,
          value: googleAuth.accessToken,
        );

        return googleAuth.accessToken!;
      }
    } catch (e) {
      // Fall back to stored token
    }

    // If getting fresh token failed, use stored one
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    if (token == null) {
      throw AuthException('Token not found');
    }

    return token;
  }

  // Refresh token (handled automatically by GoogleSignIn)
  Future<void> refreshAccessToken() async {
    final isSignedIn = await this.isSignedIn();
    if (!isSignedIn) {
      throw AuthException('User is not signed in');
    }

    try {
      final googleUser = _googleSignIn.currentUser;
      if (googleUser != null) {
        // This will refresh the token if needed
        final googleAuth = await googleUser.authentication;
        await _storeCredentials(googleAuth);
      } else {
        throw AuthException('No signed-in user found');
      }
    } catch (e) {
      throw AuthException('Failed to refresh token: ${e.toString()}');
    }
  }
}
