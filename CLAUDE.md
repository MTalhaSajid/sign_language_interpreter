# CLAUDE.md — Flutter Boilerplate

This file is the source of truth for AI-assisted development on this project.
Read it in full before making any changes.

---

## Project Overview

Production-ready Flutter boilerplate for mid-level projects.
Uses **feature-sliced architecture** with Provider, GoRouter, Dio, and GetIt.

**Target:** Mid-level mobile apps that need auth flow, real HTTP, DI, theme persistence, connectivity handling, and CI — without over-engineering.

---

## Tech Stack

| Concern | Package | Version |
|---|---|---|
| State management | `provider` + `ChangeNotifier` | ^6.1.4 |
| Navigation | `go_router` | ^15.1.1 |
| HTTP client | `dio` | ^5.8.0+1 |
| Dependency injection | `get_it` | ^8.0.3 |
| Local storage | `shared_preferences` | ^2.5.3 |
| Connectivity | `connectivity_plus` | ^6.1.4 |
| Logging | `logger` | ^2.5.0 |
| Splash screen | `flutter_native_splash` | ^2.4.5 |
| Fonts | `google_fonts` | ^6.2.1 |

**Do NOT** switch state management to Riverpod, Bloc, or MobX without an explicit user decision.

---

## Architecture Rules (Non-Negotiable)

### 1. Feature-sliced layout
Every feature owns its own model, service, controller, and view.
```
lib/features/<name>/
├── model/        ← data classes (fromJson/toJson)
├── service/      ← API calls, receives ApiClient via constructor
├── controller/   ← ChangeNotifier, receives service via constructor
└── view/         ← Screens and widgets for this feature
```

### 2. Global services only in lib/services/
Only services that are **truly cross-cutting** (not tied to one feature) live here:
- `connectivity_service.dart`
- `dialog_service.dart`
- `local_storage_service.dart`

### 3. Constructor injection — never service locator inside controllers
```dart
// CORRECT
class HomeController extends ChangeNotifier {
  HomeController(this._userService);        // injected
}

// WRONG — don't do this
class HomeController extends ChangeNotifier {
  final _userService = sl<UserService>();   // never sl inside a class body
}
```

### 4. Services never call other services directly
Services only talk to `ApiClient` and `LocalStorageService`. Cross-service orchestration belongs in a controller.

### 5. LocalStorageService is static — never inject it
```dart
// CORRECT
final token = LocalStorageService.getString(AppConstants.kTokenKey);

// WRONG
sl.registerSingleton<LocalStorageService>(LocalStorageService()); // don't do this
```

### 6. ApiResult wraps every service return value
```dart
Future<ApiResult<MyModel>> fetchSomething() async { ... }
```
Never throw raw exceptions out of a service. Catch → wrap → return `ApiResult.failure(appEx)`.

### 7. Logging — use AppLogger, never print/debugPrint
```dart
AppLogger.d('debug');
AppLogger.i('info');
AppLogger.w('warning');
AppLogger.e('error', error, stackTrace);
```
`AppLogger` is automatically silent in release builds.

---

## Folder Structure

```
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart         ← AppEnvironment enum, base URL per env
│   │   └── app_constants.dart      ← SharedPrefs keys, timeouts, pagination
│   ├── di/
│   │   └── service_locator.dart    ← GetIt wiring (sl)
│   ├── network/
│   │   ├── api_client.dart         ← Dio singleton with interceptors
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart    ← Injects Bearer token on every request
│   │       ├── error_interceptor.dart   ← Maps DioException → AppException
│   │       └── logging_interceptor.dart ← Logs req/res in dev only
│   ├── routing/
│   │   └── router.dart             ← buildRouter(), auth guard, all routes
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_fonts.dart
│   │   ├── app_styles.dart
│   │   └── theme.dart
│   ├── utils/
│   │   ├── api_result.dart         ← ApiResult<T> success/failure wrapper
│   │   ├── app_exception.dart      ← AppException + fromDioException factory
│   │   ├── app_logger.dart         ← Static AppLogger.d/i/w/e
│   │   └── size_config.dart        ← SizeConfig.w() / .h() for responsive sizes
│   └── widgets/
│       ├── custom_loader.dart
│       ├── custom_snackbar.dart
│       └── primary_button.dart
│
├── features/
│   ├── auth/
│   │   ├── controller/auth_controller.dart
│   │   ├── model/auth_model.dart         ← LoginRequest, AuthResponse
│   │   ├── service/auth_service.dart
│   │   └── view/login_screen.dart
│   ├── home/
│   │   ├── controller/home_controller.dart
│   │   ├── model/user_model.dart
│   │   ├── service/user_service.dart
│   │   └── view/home_screen.dart
│   └── settings/
│       ├── controller/settings_controller.dart
│       └── view/setting_screen.dart
│
├── providers/
│   └── theme_provider.dart         ← ThemeMode + persistence
│
├── services/                       ← ONLY cross-cutting global services
│   ├── connectivity_service.dart
│   ├── dialog_service.dart
│   └── local_storage_service.dart
│
└── main.dart                       ← Bootstrap sequence (see below)
```

---

## Bootstrap Sequence (main.dart)

Order matters — do not change it:
```
1. WidgetsFlutterBinding.ensureInitialized()
2. await LocalStorageService.init()       ← SharedPrefs must be ready first
3. AppConfig.setup(AppEnvironment.dev)    ← Sets base URL before ApiClient is built
4. await setupServiceLocator()            ← ApiClient reads AppConfig.baseUrl
5. await sl<ThemeProvider>().init()       ← Reads saved theme from storage
6. runApp(MyApp())
```

---

## DI Registration Pattern (service_locator.dart)

When you add a new feature, register in this order:

```dart
// 1. Service (lazy — only created when first requested)
sl.registerLazySingleton<MyService>(() => MyService(sl<ApiClient>()));

// 2. Controller (lazy)
sl.registerLazySingleton<MyController>(() => MyController(sl<MyService>()));
```

Then in `main.dart` → `MyApp._MyAppState.build()` → `MultiProvider`:
```dart
ChangeNotifierProvider<MyController>.value(value: sl<MyController>()),
```

---

## Router Pattern

All routes live in `lib/core/routing/router.dart` inside `buildRouter()`.
Add new routes inside the `routes:` list:
```dart
GoRoute(
  path: '/my-screen',
  builder: (context, state) => const MyScreen(),
),
```

Navigate from widgets:
```dart
context.go('/my-screen');      // replace stack
context.push('/my-screen');    // push onto stack
context.pop();                 // go back
```

The auth guard automatically redirects unauthenticated users to `/login`.
Any new route is protected by default. To make a route public, add it to the
allowlist in the `redirect` callback in `router.dart`.

---

## API Pattern

### Service method template
```dart
Future<ApiResult<MyModel>> fetchSomething({int id}) async {
  try {
    final response = await _apiClient.dio.get('/endpoint/$id');
    return ApiResult.success(MyModel.fromJson(response.data));
  } on DioException catch (e) {
    final appEx = e.error is AppException
        ? e.error as AppException
        : AppException.fromDioException(e);
    return ApiResult.failure(appEx);
  } catch (_) {
    return ApiResult.failure(AppException.unknown());
  }
}
```

### Controller consumption template
```dart
final result = await _myService.fetchSomething(id: 1);
if (result.isSuccess) {
  // use result.data
} else {
  AppLogger.e('Failed', result.error);
  DialogService.showCustomSnackbar(message: result.error!.message);
}
```

---

## Environment Configuration

Edit `lib/core/config/app_config.dart` to change base URLs:
```dart
baseUrl = env == AppEnvironment.dev
    ? 'https://dev-api.example.com'
    : 'https://api.example.com';
```

Switch environment in `main.dart`:
```dart
AppConfig.setup(AppEnvironment.dev);   // development
AppConfig.setup(AppEnvironment.prod);  // production / release
```

---

## Theme

- Light/dark themes defined in `lib/core/theme/theme.dart`
- Colors: `AppColors` in `app_colors.dart`
- Fonts: `AppFonts` (Poppins via google_fonts) in `app_fonts.dart`
- Toggle persists across restarts via `ThemeProvider.toggleTheme()` + SharedPrefs

---

## Testing Conventions

| Test type | Location | Pattern |
|---|---|---|
| Unit (logic, models, exceptions) | `test/unit/` | No Flutter imports needed |
| Widget | `test/widget/` | Wrap in `MaterialApp(home: ...)` |
| Smoke | `test/widget_test.dart` | Minimal, just proves widget boots |

**Run tests:**
```bash
flutter test
flutter test --coverage
```

**Mock services** with `mockito`. Annotate with `@GenerateMocks([MyService])` and run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Splash Screen

After changing colors/images in `pubspec.yaml` under `flutter_native_splash:`:
```bash
dart run flutter_native_splash:create
```

---

## Commands Reference

| Command | Purpose |
|---|---|
| `flutter pub get` | Install / update dependencies |
| `flutter analyze` | Static analysis (must return 0 issues) |
| `flutter test` | Run all tests |
| `dart run flutter_native_splash:create` | Regenerate native splash |
| `dart run build_runner build --delete-conflicting-outputs` | Generate mocks |

### Custom slash commands (Claude Code)

| Command | Purpose |
|---|---|
| `/add-feature <name>` | Scaffold a complete new feature (model + service + controller + view + DI + route) |
| `/add-screen <feature> <ScreenName>` | Add a new screen inside an existing feature |
| `/add-endpoint <feature> <description>` | Add a new API method to an existing feature service |
| `/new-project-setup` | Full checklist to clone and configure this boilerplate for a new project |

---

## Do's and Don'ts

### Do
- Keep features self-contained (model, service, controller, view in one folder)
- Use `ApiResult<T>` for every service return value
- Use `AppLogger` for all logging
- Use `AppConstants` for magic strings and numbers
- Register every new service + controller in `service_locator.dart`
- Run `flutter analyze` before committing (CI enforces it)

### Don't
- Don't use `debugPrint` or `print` — use `AppLogger`
- Don't throw raw exceptions from services — wrap in `ApiResult.failure()`
- Don't call `sl<>()` inside a class body — inject via constructor
- Don't put feature-specific services in `lib/services/`
- Don't add new global state without discussing architecture first
- Don't change state management library (Provider + ChangeNotifier is locked in)
- Don't commit with `flutter analyze` errors
