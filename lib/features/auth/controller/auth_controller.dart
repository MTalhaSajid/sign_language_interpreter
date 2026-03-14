import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../model/auth_model.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;

  AuthController(this._authService);

  bool isLoading = false;
  String? errorMessage;

  bool get isLoggedIn => _authService.isLoggedIn;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _authService.login(
      LoginRequest(email: email, password: password),
    );

    isLoading = false;

    if (result.isSuccess) {
      notifyListeners();
      return true;
    } else {
      errorMessage = result.error!.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }
}
