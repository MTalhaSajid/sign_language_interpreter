Add a new API endpoint method to an existing feature service in this Flutter boilerplate.

Arguments: $ARGUMENTS
Expected format: `<featureName> <description>`
Example: `home fetch single user by id`
Example: `auth refresh token`
Example: `product create new product`

---

## Step 1 — Parse arguments and read existing code

- `featureName` = first word (e.g. `home`, `auth`, `product`)
- `description` = remaining words describing what the endpoint does

Before writing anything, read:
1. `lib/features/<featureName>/service/<featureName>_service.dart` — existing service methods and Dio usage
2. `lib/features/<featureName>/model/<featureName>_model.dart` — existing models
3. `lib/features/<featureName>/controller/<featureName>_controller.dart` — how the controller calls the service

---

## Step 2 — Determine HTTP method and return type

From the description, infer:
- `GET` → fetch / list / search
- `POST` → create / login / submit
- `PUT` / `PATCH` → update / edit
- `DELETE` → delete / remove

Determine the return type:
- Listing → `ApiResult<List<Model>>`
- Single item → `ApiResult<Model>`
- Create/update → `ApiResult<Model>` (return the saved object)
- Delete/logout → `ApiResult<void>` or `Future<void>`

If a new model is needed (e.g. a request body or a different response shape), create it in `lib/features/<featureName>/model/`.

---

## Step 3 — Add method to the service

Add to `lib/features/<featureName>/service/<featureName>_service.dart`:

```dart
// Document the expected API contract above the method:
// POST /endpoint   { field: value }  → { returnedField: value }
Future<ApiResult<ReturnType>> methodName(/* params */) async {
  try {
    final response = await _apiClient.dio.post(         // change verb as needed
      '/endpoint',
      data: requestObject.toJson(),                     // remove if GET/DELETE
      queryParameters: {'key': value},                  // add if needed
    );
    return ApiResult.success(ReturnType.fromJson(response.data));
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

---

## Step 4 — Add controller method that calls the service

Add to `lib/features/<featureName>/controller/<featureName>_controller.dart`:

```dart
Future<void> methodName(/* params */) async {
  isLoading = true;
  notifyListeners();

  final result = await _service.methodName(/* params */);

  if (result.isSuccess) {
    // update local state, e.g.: item = result.data!;
    AppLogger.i('methodName succeeded');
  } else {
    AppLogger.e('methodName failed', result.error);
    DialogService.showCustomSnackbar(
      message: result.error!.message,
      icon: Icons.error_outline,
      backgroundColor: Colors.red.shade700,
    );
  }

  isLoading = false;
  notifyListeners();
}
```

---

## Step 5 — Wire up from the view (if a UI trigger exists)

If there is an obvious UI element that should call this (button, list tile tap, form submit), show the developer exactly where to add the call:

```dart
onPressed: () => context.read<<FeatureName>Controller>().methodName(/* args */),
```

---

## Step 6 — Add a unit test for the new service method (optional but recommended)

Suggest the test structure in `test/unit/<featureName>_service_test.dart`:

```dart
// Mock: @GenerateMocks([ApiClient])
// Test: success path stores / returns data
// Test: DioException mapped to AppException correctly
```

---

## Step 7 — Verify

```bash
flutter analyze
flutter test
```

Report:
- The service method signature added
- The controller method signature added
- The HTTP verb and endpoint path used
- Any new model files created
- Any TODOs the developer must fill in (actual endpoint URL, request fields, response fields)
