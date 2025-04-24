import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => themeProvider.toggleTheme(),
          child: const Text("Toggle Theme"),
        ),
      ),
    );
  }
}
