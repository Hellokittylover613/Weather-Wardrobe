import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'utils/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Listen for Firebase login/logout changes
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    print('========================================');

    if (user != null) {
      print('FIREBASE USER IS LOGGED IN');
      print('UID: ${user.uid}');
      print('Email: ${user.email}');
      print('Name: ${user.displayName}');
    } else {
      print('NO FIREBASE USER IS LOGGED IN');
    }

    print('========================================');
  });

  runApp(const WeatherWardrobe());
}

class WeatherWardrobe extends StatelessWidget {
  const WeatherWardrobe({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Wardrobe',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6FA8DC),
          brightness: Brightness.light,
        ),
      ),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}