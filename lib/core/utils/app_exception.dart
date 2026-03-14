import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, {this.statusCode});

  factory AppException.networkError() =>
      AppException('No internet connection. Please check your network.');

  factory AppException.serverError([int? code]) =>
      AppException('A server error occurred. Please try again later.',
          statusCode: code);

  factory AppException.unauthorized() =>
      AppException('Session expired. Please log in again.', statusCode: 401);

  factory AppException.notFound() =>
      AppException('The requested resource was not found.', statusCode: 404);

  factory AppException.timeout() =>
      AppException('The request timed out. Please try again.');

  factory AppException.unknown() =>
      AppException('An unexpected error occurred.');

  factory AppException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException.timeout();
      case DioExceptionType.connectionError:
        return AppException.networkError();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return AppException.unauthorized();
        if (code == 404) return AppException.notFound();
        if (code != null && code >= 500) return AppException.serverError(code);
        final msg = e.response?.data?['message'] as String?;
        return AppException(msg ?? 'Request failed.', statusCode: code);
      case DioExceptionType.cancel:
        return AppException('Request was cancelled.');
      default:
        return AppException.unknown();
    }
  }

  @override
  String toString() => message;
}
