import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Login_views.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/email_validator.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authController = AuthController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String _selectedUserType = 'User';

  final List<String> _userTypes = ['User', 'Company'];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog("Registration Error", "Passwords do not match!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authController.register(
        username: _usernameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        password2: _confirmPasswordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _phoneController.text,
        userType: _selectedUserType,
      );

      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
          content: Text("Registration successful! Please login."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      }
    } catch (e) {
      if (mounted) {
      _showErrorDialog("Registration Failed", e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  @override
  Widget build(BuildContext context) {
    print('userType: $_selectedUserType');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: const Color(0xFF006C5F),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    width: 300,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SIGN UP',
                  style: GoogleFonts.mukta(
                    color: const Color(0xFF006C5F),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildUserTypeDropdown(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a username' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => EmailValidator.validateCompanyEmail(
                      value, _selectedUserType),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your first name'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your last name'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: !_passwordVisible,
                    suffixIcon: IconButton(
                    icon: Icon(_passwordVisible
                            ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a password' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock,
                  obscureText: !_confirmPasswordVisible,
                    suffixIcon: IconButton(
                    icon: Icon(_confirmPasswordVisible
                            ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () => setState(() =>
                        _confirmPasswordVisible = !_confirmPasswordVisible),
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please confirm your password'
                      : null,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006C5F),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'SIGN UP',
                            style: GoogleFonts.mukta(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUserType,
      decoration: _buildInputDecoration('User Type', Icons.person, null),
      items: _userTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() => _selectedUserType = newValue);
        }
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: _buildInputDecoration(label, icon, suffixIcon),
      validator: validator,
    );
  }

  InputDecoration _buildInputDecoration(
      String label, IconData prefixIcon, Widget? suffixIcon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF006C5F), width: 2),
      ),
    );
  }
}
