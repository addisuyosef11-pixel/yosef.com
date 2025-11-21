import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'otp_verification_page.dart';
import 'api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _refcodeController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _isPressed = false; // for button press effect

  void _signup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();
    final refcode = _refcodeController.text.trim().isEmpty ? null : _refcodeController.text.trim();

    if (username.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = "Please fill in all fields");
      return;
    }

    if (password != confirm) {
      setState(() => _error = "Passwords do not match");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ApiService.signup(username, email, password, phone, refcode);

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful! Please verify OTP.")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationPage(username: username),
          ),
        );
      } else {
        setState(() => _error = result['error'] ?? "Signup failed");
      }
    } catch (e) {
      setState(() => _error = "Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
      {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.green),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            "🇪🇹 +251",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.green),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "912345678",
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              if (!value.startsWith("+251")) _phoneController.text;
              if (value.length > 4) {
                final digits = value.substring(4).replaceAll(RegExp(r'[^0-9]'), '');
                _phoneController.text = "+251$digits";
              }
              _phoneController.selection = TextSelection.fromPosition(
                TextPosition(offset: _phoneController.text.length),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "CREATE ACCOUNT",
                  style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 32),
                _buildTextField(_usernameController, "Username", Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_emailController, "Email", Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildPhoneField(),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, "Password", Icons.lock_outline,
                    obscure: true),
                const SizedBox(height: 16),
                _buildTextField(_confirmController, "Confirm Password", Icons.lock_outline,
                    obscure: true),
                const SizedBox(height: 16),
                _buildTextField(_refcodeController, "Referral Code (Optional)", Icons.card_giftcard),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) {
                    setState(() => _isPressed = false);
                    if (!_loading) _signup();
                  },
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: double.infinity,
                    height: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isPressed
                          ? const [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: Colors.black38,
                                offset: Offset(0, 6),
                                blurRadius: 10,
                              ),
                            ],
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "SIGN UP",
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

