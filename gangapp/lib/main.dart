import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'languages/language.dart';
import 'views/auth/Login_views.dart';
import 'views/home/Home_Page.dart';
// import 'views/groups/groups.dart';
import 'controllers/auth_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Language()),
        Provider(create: (_) => AuthController()),
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
    final authController = context.read<AuthController>();

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
      title: language.get('app_name'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: language.isRTL ? 'Cairo' : 'Roboto',
      ),
      locale: language.isRTL ? const Locale('ar') : const Locale('en'),
      home: _AuthWrapper(authController: authController),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/explore': (context) => const HomePage(),
      },
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  final AuthController authController;

  const _AuthWrapper({
    required this.authController,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: authController.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If there's an error or the user is not logged in, show login page
        if (snapshot.hasError || snapshot.data != true) {
          return const LoginPage();
        }

        // If the user is logged in, show home page
        return const HomePage();
      },
    );
  }
}
