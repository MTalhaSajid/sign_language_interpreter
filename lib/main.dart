import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'core/routing/router.dart';
import 'core/theme/theme.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/home/controller/home_controller.dart';
import 'features/settings/controller/settings_controller.dart';
import 'providers/theme_provider.dart';
import 'services/connectivity_service.dart';
import 'services/dialog_service.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Init storage (must come first — ThemeProvider reads from it)
  await LocalStorageService.init();

  // 2. Configure environment
  AppConfig.setup(AppEnvironment.dev); // swap to AppEnvironment.prod for release

  // 3. Wire up DI
  await setupServiceLocator();

  // 4. Init theme from storage
  await sl<ThemeProvider>().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter();
    _listenConnectivity();
  }

  void _listenConnectivity() {
    sl<ConnectivityService>().onConnectivityChanged.listen((isOnline) {
      if (!isOnline) {
        DialogService.showCustomSnackbar(
          message: 'No internet connection',
          icon: Icons.wifi_off,
          backgroundColor: Colors.red.shade700,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: sl<ThemeProvider>()),
        ChangeNotifierProvider<AuthController>.value(value: sl<AuthController>()),
        ChangeNotifierProvider<HomeController>.value(value: sl<HomeController>()),
        ChangeNotifierProvider<SettingsController>.value(
            value: sl<SettingsController>()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            scaffoldMessengerKey: DialogService.messengerKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
          );
        },
      ),
    );
  }
}
