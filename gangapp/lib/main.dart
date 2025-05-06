import 'package:flutter/material.dart';
import 'views/auth/Login_views.dart';
import 'views/home/Home_Page.dart';
import 'views/groups/groups.dart';
import 'controllers/auth_controller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final AuthController _authController = AuthController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gang App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006C5F)),
        useMaterial3: true,
      ),
      routes: {
        '/home': (context) => const HomePage(),
        '/groups': (context) => const GroupsPage(),
        '/login': (context) => const LoginPage(),
      },
      home: FutureBuilder<bool>(
        future: _authController.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data == true ? const HomePage() : const LoginPage();
        },
      ),
    );
  }
}
