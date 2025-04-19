class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

class AuthException extends AppException {
  AuthException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

class DriveException extends AppException {
  DriveException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

class NotFoundException extends AppException {
  NotFoundException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

class OfflineException extends AppException {
  OfflineException()
    : super('No internet connection. Working in offline mode.');
}

class TokenExpiredException extends AuthException {
  TokenExpiredException()
    : super('Your session has expired. Please sign in again.');
}
