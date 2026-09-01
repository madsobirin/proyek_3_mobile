// import 'dart:convert';
import 'package:fitlife/pages/dashboard/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/auth/login.dart';
import 'pages/auth/register.dart';
import 'pages/dashboard/profile_page.dart';
import 'pages/splash/onboarding.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitLifeApp());
}

class FitLifeApp extends StatelessWidget {
  const FitLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitLife.id',
      initialRoute: '/check',
      routes: {
        '/check': (context) => const AuthCheckScreen(),
        '/splash': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => Home(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

/// Screen that checks if user is logged in, then redirects
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user');

    if (!mounted) return;

    if (userData != null && userData.isNotEmpty) {
      // User is logged in, go to home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Not logged in, go to splash/onboarding
      Navigator.pushReplacementNamed(context, '/splash');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FFFA),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF00FF66))),
    );
  }
}
