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
        '/home': (context) => HomePage(),
        '/groups': (context) => const GroupsPage(),
        '/login': (context) => LoginPage(),
      },
      home: FutureBuilder<bool>(
        future: _authController.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final isLoggedIn = snapshot.data ?? false;
          if (isLoggedIn) {
            return HomePage();
          } else {
            return LoginPage();
          }
        },
      ),
    );
  }
}
