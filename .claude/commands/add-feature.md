Scaffold a complete new feature in this Flutter boilerplate. The feature name is: $ARGUMENTS

Follow every step below in order. Do not skip any step.

---

## Step 1 — Derive names

From the argument (e.g. "product" or "order history"):
- `featureName` = snake_case folder name (e.g. `product`, `order_history`)
- `FeatureName` = PascalCase prefix (e.g. `Product`, `OrderHistory`)
- Route path = `/<feature_name>` (e.g. `/product`, `/order-history`)

---

## Step 2 — Create folder structure

Create these empty directories under `lib/features/<featureName>/`:
```
lib/features/<featureName>/
├── model/
├── service/
├── controller/
└── view/
```

---

## Step 3 — Model (`lib/features/<featureName>/model/<featureName>_model.dart`)

```dart
class <FeatureName>Model {
  final int id;
  // TODO: add fields matching the API response

  const <FeatureName>Model({required this.id});

  factory <FeatureName>Model.fromJson(Map<String, dynamic> json) =>
      <FeatureName>Model(id: json['id'] as int);

  Map<String, dynamic> toJson() => {'id': id};
}
```

---

## Step 4 — Service (`lib/features/<featureName>/service/<featureName>_service.dart`)

```dart
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/api_result.dart';
import '../../../core/utils/app_exception.dart';
import '../model/<featureName>_model.dart';

// API contract:
//   GET /<featureName>s           → List<<FeatureName>Model>
//   GET /<featureName>s/:id       → <FeatureName>Model
class <FeatureName>Service {
  final ApiClient _apiClient;

  <FeatureName>Service(this._apiClient);

  Future<ApiResult<List<<FeatureName>Model>>> fetchAll() async {
    try {
      final response = await _apiClient.dio.get('/<featureName>s');
      final list = (response.data as List<dynamic>)
          .map((e) => <FeatureName>Model.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
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
```

---

## Step 5 — Controller (`lib/features/<featureName>/controller/<featureName>_controller.dart`)

```dart
import 'package:flutter/material.dart';
import '../../../core/utils/app_logger.dart';
import '../../../services/dialog_service.dart';
import '../model/<featureName>_model.dart';
import '../service/<featureName>_service.dart';

class <FeatureName>Controller extends ChangeNotifier {
  final <FeatureName>Service _service;

  <FeatureName>Controller(this._service);

  List<<FeatureName>Model> items = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadAll() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _service.fetchAll();

    if (result.isSuccess) {
      items = result.data!;
      AppLogger.i('Loaded ${items.length} <featureName>s');
    } else {
      errorMessage = result.error!.message;
      AppLogger.e('Failed to load <featureName>s', result.error);
      DialogService.showCustomSnackbar(
        message: result.error!.message,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade700,
      );
    }

    isLoading = false;
    notifyListeners();
  }
}
```

---

## Step 6 — View (`lib/features/<featureName>/view/<featureName>_screen.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/<featureName>_controller.dart';

class <FeatureName>Screen extends StatefulWidget {
  const <FeatureName>Screen({super.key});

  @override
  State<<FeatureName>Screen> createState() => _<FeatureName>ScreenState();
}

class _<FeatureName>ScreenState extends State<<FeatureName>Screen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<<FeatureName>Controller>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<<FeatureName>Controller>();

    return Scaffold(
      appBar: AppBar(title: const Text('<FeatureName>')),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage != null
              ? Center(child: Text(controller.errorMessage!))
              : ListView.builder(
                  itemCount: controller.items.length,
                  itemBuilder: (context, index) {
                    final item = controller.items[index];
                    return ListTile(title: Text('Item ${item.id}'));
                  },
                ),
    );
  }
}
```

---

## Step 7 — Register in service_locator.dart

Open `lib/core/di/service_locator.dart` and add:

```dart
// Import at the top
import '../../features/<featureName>/service/<featureName>_service.dart';
import '../../features/<featureName>/controller/<featureName>_controller.dart';

// Inside setupServiceLocator(), after existing registrations:
sl.registerLazySingleton<<FeatureName>Service>(
  () => <FeatureName>Service(sl<ApiClient>()),
);
sl.registerLazySingleton<<FeatureName>Controller>(
  () => <FeatureName>Controller(sl<<FeatureName>Service>()),
);
```

---

## Step 8 — Register Provider in main.dart

Open `lib/main.dart`. Add the import and add to `MultiProvider`:

```dart
import 'features/<featureName>/controller/<featureName>_controller.dart';

// Inside MultiProvider providers list:
ChangeNotifierProvider<<FeatureName>Controller>.value(
  value: sl<<FeatureName>Controller>(),
),
```

---

## Step 9 — Add route in router.dart

Open `lib/core/routing/router.dart`. Add the import and new route:

```dart
import '../../features/<featureName>/view/<featureName>_screen.dart';

// Inside routes list:
GoRoute(
  path: '/<featureName>',
  builder: (context, state) => const <FeatureName>Screen(),
),
```

---

## Step 10 — Verify

Run the following and fix any issues before finishing:
```bash
flutter analyze
flutter test
```

Report what was created, any TODOs the developer needs to fill in (fields in model, endpoint URL), and how to navigate to the new screen (`context.go('/<featureName>')`).
