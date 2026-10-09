import 'package:firebase_core/firebase_core.dart';

class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

class FirebaseExceptionHandler {
  static AppException handleException(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return AppException('You do not have permission to perform this action.');
        case 'unavailable':
          return AppException('Service is currently unavailable. Please try again later.');
        case 'network-request-failed':
          return AppException('Network error. Please check your internet connection.');
        default:
          return AppException('Firebase Error: ${error.message ?? 'Unknown error occurred'}');
      }
    }
    return AppException('An unexpected error occurred: $error');
  }
}
