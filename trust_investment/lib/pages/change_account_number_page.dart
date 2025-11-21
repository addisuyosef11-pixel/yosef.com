import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChangeAccountNumberPage extends StatefulWidget {
  final String token;
  const ChangeAccountNumberPage({super.key, required this.token});

  @override
  State<ChangeAccountNumberPage> createState() => _ChangeAccountNumberPageState();
}

class _ChangeAccountNumberPageState extends State<ChangeAccountNumberPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _updateAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:8000/api/change_account_number/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'account_number': _accountController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _message = "✅ Account number updated successfully!");
      } else {
        final data = jsonDecode(response.body);
        setState(() =>
            _message = "❌ ${data['error'] ?? data['detail'] ?? 'Error occurred'}");
      }
    } catch (e) {
      setState(() => _message = "⚠️ Exception: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      body: Stack(
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF001F3F), Color(0xFF004AAD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "Change Account Number",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _accountController,
                      decoration: _inputDecoration("New Account Number"),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter account number" : null,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateAccount,
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
                                "Update Account",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _message!.contains("✅")
                              ? Colors.green
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF004AAD), width: 2),
      ),
    );
  }
}
