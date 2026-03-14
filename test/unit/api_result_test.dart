import 'package:boilerplate_flutter/core/utils/api_result.dart';
import 'package:boilerplate_flutter/core/utils/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiResult', () {
    test('success holds data and no error', () {
      final result = ApiResult<String>.success('hello');
      expect(result.isSuccess, isTrue);
      expect(result.data, 'hello');
      expect(result.error, isNull);
    });

    test('failure holds error and no data', () {
      final result = ApiResult<String>.failure(AppException.networkError());
      expect(result.isSuccess, isFalse);
      expect(result.data, isNull);
      expect(result.error, isNotNull);
    });
  });
}
