import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../utils/app_logger.dart';

class LoggingInterceptor extends Interceptor {
  final _stopwatch = Stopwatch();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.isDev) {
      _stopwatch
        ..reset()
        ..start();
      AppLogger.d('→ ${options.method} ${options.uri}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (AppConfig.isDev) {
      _stopwatch.stop();
      AppLogger.i(
        '← ${response.statusCode} ${response.requestOptions.uri} '
        '(${_stopwatch.elapsedMilliseconds}ms)',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppConfig.isDev) {
      AppLogger.e(
        '✗ ${err.requestOptions.method} ${err.requestOptions.uri}',
        err,
        err.stackTrace,
      );
    }
    handler.next(err);
  }
}
