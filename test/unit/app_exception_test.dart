import 'package:boilerplate_flutter/core/utils/app_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppException factories', () {
    test('networkError has expected message', () {
      final e = AppException.networkError();
      expect(e.message, contains('internet'));
      expect(e.statusCode, isNull);
    });

    test('serverError carries status code', () {
      final e = AppException.serverError(503);
      expect(e.statusCode, 503);
    });

    test('unauthorized has status 401', () {
      final e = AppException.unauthorized();
      expect(e.statusCode, 401);
    });

    test('timeout has expected message', () {
      final e = AppException.timeout();
      expect(e.message, contains('timed out'));
    });

    test('fromDioException maps connectionTimeout to timeout message', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );
      final e = AppException.fromDioException(dioEx);
      expect(e.message, contains('timed out'));
    });

    test('fromDioException maps 401 response to unauthorized', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
      );
      final e = AppException.fromDioException(dioEx);
      expect(e.statusCode, 401);
    });

    test('fromDioException maps 500 response to server error', () {
      final dioEx = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );
      final e = AppException.fromDioException(dioEx);
      expect(e.statusCode, 500);
    });

    test('toString returns message', () {
      final e = AppException.unknown();
      expect(e.toString(), e.message);
    });
  });
}
