import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'firebase_options.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'presentation/viewmodels/theme_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupDependencies();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeViewModel = sl<ThemeViewModel>();

    return SignalBuilder(
      builder: (context) {
        final isDark = themeViewModel.isDarkMode.value;
        return MaterialApp.router(
          title: 'Piramid Game',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          routerConfig: appRouter,
        );
      },
    );
  }
}
