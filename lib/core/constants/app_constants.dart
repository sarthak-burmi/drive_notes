import 'package:drive_notes/core/constants/app_config.dart';
import 'package:drive_notes/core/constants/myconfig.dart';

class AppConstants {
  static const String appName = 'DriveNotes';

  // Auth-related constants
  static const String tokenKey = 'oauth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String expiryTimeKey = 'token_expiry_time';
  static const String idTokenKey = "auth_id_token";

  // Get credentials from config
  static String get googleClientId => AppConfig.googleClientId;
  static String get googleClientSecret => AppConfig.googleClientSecret;

  // Scopes for Google Drive access
  static const List<String> scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
    'email',
    'profile',
  ];

  // Storage-related constants
  static const int maxOfflineNotes = 50;
}
