import 'package:get_it/get_it.dart';
import 'package:sign_language_interpreter/features/video_call/controller/call_controller.dart';
import 'package:sign_language_interpreter/features/video_call/service/call_service.dart';
import '../network/api_client.dart';
import '../../services/connectivity_service.dart';
import '../../services/dialog_service.dart';
import '../../features/auth/service/auth_service.dart';
import '../../features/home/service/user_service.dart';
import '../../features/auth/controller/auth_controller.dart';
import '../../features/home/controller/home_controller.dart';
import '../../features/settings/controller/settings_controller.dart';
import '../../features/interpreter/service/interpreter_service.dart';
import '../../features/interpreter/controller/interpreter_controller.dart';
import '../../providers/theme_provider.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ── Core ──────────────────────────────────────────────
  sl.registerSingleton<ApiClient>(ApiClient());

  // ── Global services ───────────────────────────────────
  sl.registerSingleton<DialogService>(DialogService());
  sl.registerSingleton<ConnectivityService>(ConnectivityService());

  // ── Feature services ──────────────────────────────────
  // AuthService uses Firebase directly — no ApiClient needed
  sl.registerLazySingleton<AuthService>(
    () => AuthService(),
  );
  sl.registerLazySingleton<UserService>(
    () => UserService(sl<ApiClient>()),
  );
  // InterpreterService — loads TFLite model + labels
  sl.registerLazySingleton<InterpreterService>(
    () => InterpreterService(),
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
  // InterpreterController — created fresh every time screen opens
  // (factory so camera/model state is clean each session)
  sl.registerFactory<InterpreterController>(
    () => InterpreterController(sl<InterpreterService>()),
  );
  sl.registerLazySingleton<ThemeProvider>(
    () => ThemeProvider(),
  );
  sl.registerFactory(() => CallController(sl<CallService>(), sl<InterpreterService>()));
  sl.registerLazySingleton(() => CallService());
}