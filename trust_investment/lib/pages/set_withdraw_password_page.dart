import 'package:flutter/material.dart';
import 'api_service.dart';

class SetWithdrawPasswordPage extends StatefulWidget {
  final String token;
  const SetWithdrawPasswordPage({super.key, required this.token});

  @override
  State<SetWithdrawPasswordPage> createState() => _SetWithdrawPasswordPageState();
}

class _SetWithdrawPasswordPageState extends State<SetWithdrawPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _setPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // Call the ApiService method that matches your Django endpoint
      final success = await ApiService.setWithdrawPassword(
        token: widget.token,
        withdrawPassword: _passwordController.text,
      );

      if (success) {
        setState(() {
          _message = "✅ Withdraw password set successfully!";
        });
      } else {
        setState(() {
          _message = "❌ Failed to set withdraw password";
        });
      }
    } catch (e) {
      setState(() {
        _message = "⚠️ Error: $e";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      appBar: AppBar(
        title: const Text("Set Withdraw Password"),
        backgroundColor: const Color(0xFF004AAD),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration("New Withdraw Password"),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter password" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration("Confirm Password"),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Confirm password";
                      if (v != _passwordController.text) return "Passwords do not match";
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _setPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004AAD),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Set Password",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.contains("✅") ? Colors.green : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF004AAD), width: 2),
      ),
    );
  }
}
