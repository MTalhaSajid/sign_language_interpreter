Walk me through setting up this Flutter boilerplate for a brand new project.

Project details (if provided): $ARGUMENTS

If no project details are given, ask the user for:
1. New project name (e.g. `my_app`)
2. Bundle/package ID (e.g. `com.company.myapp`)
3. Dev API base URL
4. Prod API base URL
5. App display name shown on device

Then execute the following checklist step by step, confirming each step with the user before proceeding to the next.

---

## PHASE 1 — Repository

### 1.1 Clone the boilerplate
```bash
git clone <boilerplate-repo-url> <new-project-name>
cd <new-project-name>
```

### 1.2 Reset git history (fresh start)
```bash
rm -rf .git
git init
git add .
git commit -m "Initial commit from boilerplate"
```

---

## PHASE 2 — Rename the package

### 2.1 Update pubspec.yaml
Open `pubspec.yaml` and change:
```yaml
name: boilerplate_flutter        # → new snake_case name
description: "A new Flutter project."  # → your app description
version: 1.0.0+1                 # reset or keep
```

### 2.2 Update Android package name
Files to edit:
- `android/app/build.gradle` → `applicationId "com.company.myapp"`
- `android/app/src/main/AndroidManifest.xml` → `package="com.company.myapp"`
- `android/app/src/main/kotlin/.../MainActivity.kt` → rename folder path + update `package` declaration
- `android/app/src/debug/AndroidManifest.xml` → update package
- `android/app/src/profile/AndroidManifest.xml` → update package

### 2.3 Update iOS bundle ID
- Open `ios/Runner.xcodeproj` in Xcode → Runner target → Bundle Identifier → `com.company.myapp`
- Or edit `ios/Runner/Info.plist` → `CFBundleIdentifier`

### 2.4 Update all Dart import prefixes
Search for `boilerplate_flutter` across all `.dart` files and replace with the new package name:
```bash
# Preview changes
grep -r "boilerplate_flutter" lib/ test/

# Replace (run from project root)
find lib test -name "*.dart" -exec sed -i '' 's/boilerplate_flutter/<new_package_name>/g' {} +
```

---

## PHASE 3 — Configure environment

### 3.1 Set API base URLs
Open `lib/core/config/app_config.dart`:
```dart
baseUrl = env == AppEnvironment.dev
    ? '<DEV_API_URL>'      // ← replace
    : '<PROD_API_URL>';    // ← replace
```

### 3.2 Set app display name
- **Android:** `android/app/src/main/AndroidManifest.xml` → `android:label="<App Name>"`
- **iOS:** `ios/Runner/Info.plist` → `CFBundleDisplayName`
- **macOS:** `macos/Runner/Info.plist` → `CFBundleDisplayName`

---

## PHASE 4 — Splash screen

### 4.1 Update colors in pubspec.yaml
```yaml
flutter_native_splash:
  color: "#YOUR_BRAND_COLOR"
  color_dark: "#YOUR_DARK_COLOR"
  image: assets/splash_logo.png   # add if you have a logo asset
```

### 4.2 Add your logo asset (if using one)
Place image in `assets/` and declare it:
```yaml
flutter:
  assets:
    - assets/
```

### 4.3 Generate splash
```bash
dart run flutter_native_splash:create
```

---

## PHASE 5 — Clean up demo code

Remove or replace these files that are tied to the JSONPlaceholder demo:

| File | Action |
|---|---|
| `lib/features/home/model/user_model.dart` | Replace with your first real model |
| `lib/features/home/service/user_service.dart` | Replace with your first real service |
| `lib/features/home/controller/home_controller.dart` | Update to use your service |
| `lib/features/home/view/home_screen.dart` | Replace with your home UI |

Also:
- Update `lib/features/auth/service/auth_service.dart` with your real auth endpoint path
- Update `lib/features/auth/model/auth_model.dart` fields to match your API's login response

---

## PHASE 6 — Update app theme

### 6.1 Brand colors
Open `lib/core/theme/app_colors.dart`:
```dart
static const primary = Color(0xFFYOURCOLOR);
static const secondary = Color(0xFFYOURCOLOR);
```

### 6.2 Font (optional)
Open `lib/core/theme/app_fonts.dart` and change `GoogleFonts.poppins` to your preferred font.

---

## PHASE 7 — CI

### 7.1 Update Flutter version in CI
Open `.github/workflows/ci.yml` and set:
```yaml
flutter-version: '3.x.x'   # ← pin to your team's version
```

### 7.2 Connect to your repository
```bash
git remote add origin <your-new-repo-url>
git push -u origin main
```

---

## PHASE 8 — Verify everything works

Run in order, fixing issues before moving to the next:

```bash
flutter pub get
flutter analyze         # must be 0 issues
flutter test            # all tests must pass
flutter run             # boots on simulator/device
```

Manual smoke test checklist:
- [ ] Splash screen displays correctly
- [ ] App redirects to `/login` when no token
- [ ] Login screen renders (form validates)
- [ ] Theme toggle works and persists on restart
- [ ] Settings screen shows correct app name / version
- [ ] Offline snackbar appears when network is off

---

## PHASE 9 — Housekeeping

- [ ] Update `README.md` — replace boilerplate description with your project name and real API
- [ ] Update `CLAUDE.md` — replace placeholder API URLs with real ones
- [ ] Add real app icons (`flutter_launcher_icons` package or replace manually)
- [ ] Set up signing for Android (`key.properties`) and iOS (Xcode signing)
- [ ] Create `.env` or environment-specific config if needed for secrets

---

After completing all phases, confirm with:
```bash
flutter analyze && flutter test
```

Report a summary of every file changed and every TODO still remaining for the developer.
