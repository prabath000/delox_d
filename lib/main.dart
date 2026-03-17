import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'services/notification_service.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';

import 'providers/theme_provider.dart';
import 'screens/get_started_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationService = NotificationService();
  await notificationService.init();

  final userProvider = UserProvider();
  await userProvider.init();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Delox App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: FutureBuilder<bool>(
            future: _checkFirstLaunch(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              final bool hasSeenGetStarted = snapshot.data ?? false;
              if (!hasSeenGetStarted) {
                return const GetStartedScreen();
              }

              return Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  if (userProvider.isAuthenticated) {
                    return const MainScaffold();
                  } else {
                    return const LoginScreen();
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasSeenGetStarted') ?? false;
  }
}
