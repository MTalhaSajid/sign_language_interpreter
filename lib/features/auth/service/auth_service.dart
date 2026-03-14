import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_result.dart';
import '../../../core/utils/app_exception.dart';
import '../../../core/config/app_constants.dart';
import '../../../services/local_storage_service.dart';
import '../model/auth_model.dart';

// Expected backend contract:
//   POST /auth/login   { email, password } → { token, refreshToken? }
//   DELETE /auth/logout  (Authorization: Bearer <token>)
class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  bool get isLoggedIn {
    final token = LocalStorageService.getString(AppConstants.kTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<ApiResult<AuthResponse>> login(LoginRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: request.toJson(),
      );
      final authResponse = AuthResponse.fromJson(
          response.data as Map<String, dynamic>);
      await LocalStorageService.saveString(
          AppConstants.kTokenKey, authResponse.token);
      return ApiResult.success(authResponse);
    } on DioException catch (e) {
      final appEx = e.error is AppException
          ? e.error as AppException
          : AppException.fromDioException(e);
      return ApiResult.failure(appEx);
    } catch (_) {
      return ApiResult.failure(AppException.unknown());
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.delete('/auth/logout');
    } catch (_) {
      // Best-effort — always clear local token regardless
    } finally {
      await LocalStorageService.remove(AppConstants.kTokenKey);
    }
  }
}
