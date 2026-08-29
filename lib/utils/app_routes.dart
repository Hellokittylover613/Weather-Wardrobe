import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/main_shell.dart';
import '../screens/widget_practice.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String practice = '/practice';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    home: (context) => const MainShell(),
    practice: (context) => const PracticeScreen(),
  };
}
