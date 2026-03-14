import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../../services/connectivity_service.dart';
import '../../services/dialog_service.dart';
import '../../features/auth/service/auth_service.dart';
import '../../features/home/service/user_service.dart';
import '../../features/auth/controller/auth_controller.dart';
import '../../features/home/controller/home_controller.dart';
import '../../features/settings/controller/settings_controller.dart';
import '../../providers/theme_provider.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ── Core ──────────────────────────────────────────────
  sl.registerSingleton<ApiClient>(ApiClient());

  // ── Global services ───────────────────────────────────
  // LocalStorageService uses static methods — no registration needed.
  sl.registerSingleton<DialogService>(DialogService());
  sl.registerSingleton<ConnectivityService>(ConnectivityService());

  // ── Feature services ──────────────────────────────────
  sl.registerLazySingleton<AuthService>(
    () => AuthService(sl<ApiClient>()),
  );
  sl.registerLazySingleton<UserService>(
    () => UserService(sl<ApiClient>()),
  );

  // ── Controllers ───────────────────────────────────────
  sl.registerLazySingleton<AuthController>(
    () => AuthController(sl<AuthService>()),
  );
  sl.registerLazySingleton<HomeController>(
    () => HomeController(sl<UserService>()),
  );
  sl.registerLazySingleton<SettingsController>(
    () => SettingsController(),
  );
  sl.registerLazySingleton<ThemeProvider>(
    () => ThemeProvider(),
  );
}
