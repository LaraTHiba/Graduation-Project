import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'languages/language.dart';
import 'views/auth/Login_views.dart';
import 'views/home/Home_Page.dart';
import 'views/profile/Profile_Page.dart';
// import 'views/groups/groups.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Language()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<Language>();
    final authController = context.watch<AuthController>();
    final themeController = context.watch<ThemeController>();

    if (!language.isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: language.get('app_name'),
      themeMode: themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: language.isRTL ? 'Cairo' : 'Roboto',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: language.isRTL ? 'Cairo' : 'Roboto',
        brightness: Brightness.dark,
      ),
      locale: language.isRTL ? const Locale('ar') : const Locale('en'),
      home: _SplashScreen(authController: authController),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  final AuthController authController;

  const _SplashScreen({required this.authController});

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final isLoggedIn = await widget.authController.isLoggedIn();
      if (!mounted) return;

      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
