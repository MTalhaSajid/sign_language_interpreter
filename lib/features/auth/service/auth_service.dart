// import 'package:dio/dio.dart';
// import '../../../core/network/api_client.dart';
// import '../../../core/utils/api_result.dart';
// import '../../../core/utils/app_exception.dart';
// import '../../../core/config/app_constants.dart';
// import '../../../services/local_storage_service.dart';
// import '../model/auth_model.dart';

// // Expected backend contract:
// //   POST /auth/login      { email, password }        → { token, refreshToken? }
// //   POST /auth/register   { name, email, password }  → { token, refreshToken? }
// //   DELETE /auth/logout   (Authorization: Bearer <token>)
// class AuthService {
  // final ApiClient _apiClient;

//   AuthService(this._apiClient);

//   bool get isLoggedIn {
//     final token = LocalStorageService.getString(AppConstants.kTokenKey);
//     return token != null && token.isNotEmpty;
//   }

//   Future<ApiResult<AuthResponse>> login(LoginRequest request) async {
//     try {
//       final response = await _apiClient.dio.post(
//         '/auth/login',
//         data: request.toJson(),
//       );
//       final authResponse =
//           AuthResponse.fromJson(response.data as Map<String, dynamic>);
//       await LocalStorageService.saveString(
//           AppConstants.kTokenKey, authResponse.token);
//       return ApiResult.success(authResponse);
//     } on DioException catch (e) {
//       final appEx = e.error is AppException
//           ? e.error as AppException
//           : AppException.fromDioException(e);
//       return ApiResult.failure(appEx);
//     } catch (_) {
//       return ApiResult.failure(AppException.unknown());
//     }
//   }

//   Future<ApiResult<AuthResponse>> register(RegisterRequest request) async {
//     try {
//       final response = await _apiClient.dio.post(
//         '/auth/register',
//         data: request.toJson(),
//       );
//       final authResponse =
//           AuthResponse.fromJson(response.data as Map<String, dynamic>);
//       await LocalStorageService.saveString(
//           AppConstants.kTokenKey, authResponse.token);
//       return ApiResult.success(authResponse);
//     } on DioException catch (e) {
//       final appEx = e.error is AppException
//           ? e.error as AppException
//           : AppException.fromDioException(e);
//       return ApiResult.failure(appEx);
//     } catch (_) {
//       return ApiResult.failure(AppException.unknown());
//     }
//   }

//   Future<void> logout() async {
//     try {
//       await _apiClient.dio.delete('/auth/logout');
//     } catch (_) {
//       // Best-effort — always clear local token regardless
//     } finally {
//       await LocalStorageService.remove(AppConstants.kTokenKey);
//     }
//   }
// }



import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/api_result.dart';
import '../../../core/utils/app_exception.dart';
import '../model/auth_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Auth state ─────────────────────────────────────────────────────────────
  bool get isLoggedIn => _auth.currentUser != null;

  AuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<ApiResult<AuthUser>> login(LoginRequest request) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );
      final user = credential.user!;
      return ApiResult.success(AuthUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      ));
    } on FirebaseAuthException catch (e) {
      return ApiResult.failure(AppException(_mapFirebaseError(e.code)));
    } catch (_) {
      return ApiResult.failure(AppException.unknown());
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<ApiResult<AuthUser>> register(RegisterRequest request) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: request.email,
        password: request.password,
      );
      // Save display name
      await credential.user!.updateDisplayName(request.name);
      await credential.user!.reload();

      final user = _auth.currentUser!;
      return ApiResult.success(AuthUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
      ));
    } on FirebaseAuthException catch (e) {
      return ApiResult.failure(AppException(_mapFirebaseError(e.code)));
    } catch (_) {
      return ApiResult.failure(AppException.unknown());
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Map Firebase error codes to human-readable messages ───────────────────
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}