# Flutter Boilerplate

Production-ready Flutter starter for mid-level projects — feature-sliced architecture, DI, Dio, auth flow, theme persistence, connectivity handling, and CI.

---

## Tech Stack

| Concern | Package |
|---|---|
| State management | `provider` + `ChangeNotifier` |
| Navigation | `go_router` |
| HTTP client | `dio` |
| Dependency injection | `get_it` |
| Local storage | `shared_preferences` |
| Connectivity | `connectivity_plus` |
| Logging | `logger` |
| Splash screen | `flutter_native_splash` |
| Fonts | `google_fonts` |

---

## Folder Structure

```
lib/
├── core/
│   ├── config/         # AppConfig (env), AppConstants (keys, timeouts)
│   ├── di/             # GetIt service locator
│   ├── network/        # ApiClient (Dio) + auth/error/logging interceptors
│   ├── routing/        # GoRouter with auth guard
│   ├── theme/          # Light/dark ThemeData
│   ├── utils/          # ApiResult, AppException, AppLogger, SizeConfig
│   └── widgets/        # PrimaryButton, CustomLoader, CustomSnackbar
│
├── features/
│   ├── auth/           # Login screen, AuthController, AuthService, AuthModel
│   ├── home/           # Home screen, HomeController, UserService, UserModel
│   └── settings/       # Settings screen, SettingsController
│
├── providers/
│   └── theme_provider.dart   # Persisted theme toggle
│
├── services/           # Cross-cutting global services only
│   ├── connectivity_service.dart
│   ├── dialog_service.dart
│   └── local_storage_service.dart
│
└── main.dart           # Bootstrap: storage init → env → DI → theme → runApp
```

**Rule:** Services and models live inside their feature folder. Only truly cross-cutting services go in `lib/services/`.

---

## How to Run

### Dev (default)
```bash
flutter pub get
flutter run
```
The app boots against `https://jsonplaceholder.typicode.com` (dev base URL).

### Production
In `lib/main.dart` change:
```dart
AppConfig.setup(AppEnvironment.dev);
// →
AppConfig.setup(AppEnvironment.prod);
```
Update the prod URL in `lib/core/config/app_config.dart`.

### Native splash screen
```bash
dart run flutter_native_splash:create
```

---

## How to Add a New Feature

Checklist for adding, say, a **Profile** feature:

1. **Model** — `lib/features/profile/model/profile_model.dart`
2. **Service** — `lib/features/profile/service/profile_service.dart` (takes `ApiClient` via constructor)
3. **Controller** — `lib/features/profile/controller/profile_controller.dart` (takes service via constructor)
4. **View** — `lib/features/profile/view/profile_screen.dart`
5. **Route** — add `GoRoute(path: '/profile', ...)` in `lib/core/routing/router.dart`
6. **DI** — register service + controller in `lib/core/di/service_locator.dart`
7. **Provider** — add `ChangeNotifierProvider<ProfileController>.value(value: sl<ProfileController>())` in `main.dart`

---

## Environment

| Key | Dev | Prod |
|---|---|---|
| Base URL | `https://jsonplaceholder.typicode.com` | `https://api.example.com` |
| Logging | Enabled | Disabled |

Configure in `lib/core/config/app_config.dart`.

---

## Tests

```bash
flutter test          # run all tests
flutter test --coverage  # with coverage report
```

Test files:
- `test/unit/app_exception_test.dart`
- `test/unit/api_result_test.dart`
- `test/widget/primary_button_test.dart`

---

## CI

GitHub Actions runs on every push / PR to `main`:
1. `flutter pub get`
2. `flutter analyze --fatal-infos`
3. `flutter test --coverage`

See `.github/workflows/ci.yml`.
