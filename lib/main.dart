import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme.dart';
import 'core/routing/router.dart';
import 'providers/theme_provider.dart';
import 'services/dialog_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
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
