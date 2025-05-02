import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/Home_Page.dart';
import 'Sign_Up_views.dart';
import '../../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final loginController = TextEditingController();
  final passController = TextEditingController();
  bool passToggle = true;
  bool _isLoading = false;

  final AuthController _authController = AuthController();

  Future<void> _loginWithDjango(String username, String password) async {
    setState(() => _isLoading = true);

    try {
      await _authController.login(username, password);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      _showErrorDialog(
          "Login Failed", "Invalid credentials. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _login() async {
    final username = loginController.text;
    final password = passController.text;

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog(
          "Login Failed", "Username and password cannot be empty.");
      return;
    }

    await _loginWithDjango(username, password);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.1;

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                child: Center(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    width: 520,
                    height: 250,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 3),
                child: Text(
                  'SIGN IN',
                  style: GoogleFonts.mukta(
                      color: const Color(0xFF006C5F),
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 3),
                child: TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  controller: loginController,
                  decoration: InputDecoration(
                    labelText: 'Login',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF006C5F), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 3),
                child: TextFormField(
                  controller: passController,
                  obscureText: passToggle,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: InkWell(
                      onTap: () => setState(() => passToggle = !passToggle),
                      child: Icon(
                          passToggle ? Icons.visibility : Icons.visibility_off),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF006C5F), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 15),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 25),
                child: TextButton(
                  onPressed: _isLoading ? null : _login,
                  child: Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFF006C5F),
                          borderRadius: BorderRadius.circular(8)),
                      height: 50,
                      child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  'SIGN IN',
                                  style: GoogleFonts.mukta(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                )),
                    ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: TextStyle(color: Colors.grey[700])),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpPage()),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Color(0xFF006C5F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
