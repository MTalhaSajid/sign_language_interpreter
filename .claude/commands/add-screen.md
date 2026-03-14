Add a new screen to an existing feature in this Flutter boilerplate.

Arguments: $ARGUMENTS
Expected format: `<featureName> <ScreenName> [optional description]`
Example: `home UserDetailScreen Shows a single user's full profile`

---

## Step 1 — Parse arguments

- `featureName` = first word, snake_case (e.g. `home`)
- `ScreenName` = second word, PascalCase (e.g. `UserDetailScreen`)
- Route path = derived from ScreenName, strip "Screen" suffix, snake_case (e.g. `/user-detail`)
- Any remaining words = description / context

Read the existing feature controller and model files to understand what data is already available before writing new code.

---

## Step 2 — Create the screen file

Location: `lib/features/<featureName>/view/<screen_name_snake>.dart`

Use this template:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// Import the feature controller if this screen reads from it:
// import '../controller/<featureName>_controller.dart';

class <ScreenName> extends StatefulWidget {
  // Add any required route parameters here, e.g.:
  // final int id;
  // const <ScreenName>({super.key, required this.id});
  const <ScreenName>({super.key});

  @override
  State<<ScreenName>> createState() => _<ScreenName>State();
}

class _<ScreenName>State extends State<<ScreenName>> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('<ScreenName>'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: const Center(
        child: Text('TODO: implement <ScreenName>'),
      ),
    );
  }
}
```

---

## Step 3 — Add route in router.dart

Open `lib/core/routing/router.dart`.

If the screen takes no parameters:
```dart
GoRoute(
  path: '/route-path',
  builder: (context, state) => const <ScreenName>(),
),
```

If the screen takes a path parameter (e.g. an id):
```dart
GoRoute(
  path: '/route-path/:id',
  builder: (context, state) {
    final id = int.parse(state.pathParameters['id']!);
    return <ScreenName>(id: id);
  },
),
```

Add the import at the top of router.dart:
```dart
import '../../features/<featureName>/view/<screen_file>.dart';
```

---

## Step 4 — Add navigation from the calling screen

Find the screen that should navigate to this new screen and add:

```dart
// Simple navigation (no params):
context.go('/route-path');

// With a path parameter:
context.go('/route-path/$id');

// Push (keeps back button):
context.push('/route-path');
```

---

## Step 5 — Verify

```bash
flutter analyze
flutter test
```

Report:
- Full path of the new file created
- The route path added
- How to navigate to it
- Any TODOs left for the developer to fill in
