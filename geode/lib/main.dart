import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/vault_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const GeodeApp());
}

class GeodeApp extends StatelessWidget {
  const GeodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VaultProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Geode',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
