import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_result.dart';
import '../../../core/utils/app_exception.dart';
import '../model/user_model.dart';

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  Future<ApiResult<List<UserModel>>> fetchUsers({
    int start = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/users',
        queryParameters: {'_start': start, '_limit': limit},
      );
      final data = response.data as List<dynamic>;
      final users =
          data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
      return ApiResult.success(users);
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      return ApiResult.failure(appEx);
    } catch (_) {
      return ApiResult.failure(AppException.unknown());
    }
  }
}
