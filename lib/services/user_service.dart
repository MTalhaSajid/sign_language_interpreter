import 'dart:convert';
import 'package:boilerplate_flutter/models/user_model.dart';
import 'package:http/http.dart' as http;
import '../core/utils/api_result.dart';
import '../core/utils/app_exception.dart';

class UserService {
  final String baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<ApiResult<List<UserModel>>> fetchUsers(
      {int start = 0, int limit = 10}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/users?_start=$start&_limit=$limit'));

      if (response.statusCode == 200) {
        final List jsonData = json.decode(response.body);
        final users = jsonData.map((e) => UserModel.fromJson(e)).toList();
        return ApiResult.success(users);
      } else {
        return ApiResult.failure(AppException.serverError());
      }
    } catch (e) {
      return ApiResult.failure(AppException.networkError());
    }
  }
}
