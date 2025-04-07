import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/model/device_model.dart';
import 'package:smart_home/model/firebase_model.dart';
import 'authentication/spalshscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Load stored credentials
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  phoneNumber = prefs.getString("Login_Number") ?? '';
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitUp,
  ]).then((value) {
    runApp(const MyApp());
  });
}

String phoneNumber = '';
List<DeviceModel> devices = [];
FirebaseModel fire = FirebaseModel();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  getPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    phoneNumber = prefs.getString("Login_Number") ?? '';
  }

  @override
  Widget build(BuildContext context) {
    getPrefs();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        fontFamily: 'Lexend',
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Color(0xFF2C3E50),
          ),
          displayMedium: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w500,
            fontSize: 24,
            color: Color(0xFF2C3E50),
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 16,
            color: Color(0xFF2C3E50),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 14,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
