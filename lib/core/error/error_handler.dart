import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:drive_notes/core/error/app_exceptions.dart';

class ErrorHandler {
  // Handle exceptions and convert them to app-specific exceptions
  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is SocketException || error is HttpException) {
      return NetworkException('Network error: ${error.toString()}');
    }

    return AppException('An unexpected error occurred: ${error.toString()}');
  }

  // Handle Dio specific errors
  static AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout. Please try again.');

      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
        return NetworkException(
          'Connection error. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 401 || statusCode == 403) {
          if (data != null && data['error'] == 'invalid_token') {
            return TokenExpiredException();
          }
          return AuthException(
            'Authentication error',
            code: statusCode.toString(),
            details: data,
          );
        } else if (statusCode == 404) {
          return NotFoundException(
            'Resource not found',
            code: statusCode.toString(),
            details: data,
          );
        } else {
          return NetworkException(
            'Server error: ${statusCode ?? "Unknown"}',
            code: statusCode?.toString(),
            details: data,
          );
        }

      case DioExceptionType.cancel:
        return AppException('Request was cancelled');

      case DioExceptionType.unknown:
      default:
        if (error.message?.contains('SocketException') ?? false) {
          return OfflineException();
        }
        return AppException('Unknown error: ${error.message}');
    }
  }

  // Show error snackbar
  static void showErrorSnackBar(BuildContext context, AppException exception) {
    final snackBar = SnackBar(
      content: Text(exception.message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Theme.of(context).colorScheme.onError,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
