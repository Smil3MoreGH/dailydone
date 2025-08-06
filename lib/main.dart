import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize database
    await DatabaseService.instance.initDatabase();

    // Check and reset goals if it's a new day
    await _checkAndResetDailyGoals();

    // Initialize theme service
    await ThemeService.instance.init();

    // Initialize notifications with error handling
    try {
      await NotificationService.instance.init();
      await NotificationService.instance.updateAllNotifications();
    } catch (e) {
      print('Notification initialization error: $e');
      // Continue running the app even if notifications fail
    }

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  } catch (e) {
    print('Initialization error: $e');
  }

  runApp(const MyApp());
}

Future<void> _checkAndResetDailyGoals() async {
  final prefs = await SharedPreferences.getInstance();
  final lastResetDate = prefs.getString('last_goal_reset_date');
  final today = DateTime.now();
  final todayString = '${today.year}-${today.month}-${today.day}';

  if (lastResetDate != todayString) {
    // It's a new day, reset goals
    await DatabaseService.instance.resetDailyGoals();
    await prefs.setString('last_goal_reset_date', todayString);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'DailyDone',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          home: const HomeScreen(),
        );
      },
    );
  }
}