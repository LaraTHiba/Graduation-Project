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
      home: FutureBuilder<bool>(
        future: authController.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return snapshot.data == true ? const HomePage() : const LoginPage();
        },
      ),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/explore': (context) =>
            const HomePage(), // Temporarily using HomePage for explore
      },
    );
  }
}
