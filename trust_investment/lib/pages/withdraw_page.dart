// lib/withdraw_page.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class WithdrawPage extends StatefulWidget {
  final String token;
  const WithdrawPage({super.key, required this.token});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isProcessing = false;
  String? _message;
  double _currentBalance = 0.0;

  String? _selectedBank;
  final List<String> _banks = [
    'CBE',
    'Awash Buna',
    'Abay',
    'Amhara',
    'Anbesa',
    'Bank of Oromia',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    try {
      final profile = await ApiService.getProfile(widget.token);
      if (profile != null) {
        setState(() {
          _currentBalance = (profile['balance'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      setState(() {
        _message = "Failed to fetch balance: $e";
      });
    }
  }

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _message = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/withdraw/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'amount': _amountController.text,
          'bank': _selectedBank,
          'account_number': _accountController.text,
          'withdraw_password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _message = '✅ Withdrawal successful!';
          _amountController.clear();
          _accountController.clear();
          _passwordController.clear();
          _selectedBank = null;
        });
        _fetchBalance();
      } else {
        setState(() {
          _message = '❌ Error: ${data['error'] ?? data['detail'] ?? 'Failed'}';
        });
      }
    } catch (e) {
      setState(() {
        _message = '⚠️ Exception: $e';
      });
    } finally {
      setState(() => _isProcessing = false);
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _message = null);
      });
    }
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) return "This field is required";
    final number = num.tryParse(value);
    if (number == null) return "Please enter a valid number";
    return null;
  }

  String? _validateText(String? value) {
    if (value == null || value.isEmpty) return "This field is required";
    final number = num.tryParse(value);
    if (number != null) return "Please enter valid text";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      body: Stack(
        children: [
          // Header
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
                  "Withdraw Funds",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Body content
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        "Current Balance",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Birr ${_currentBalance.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004AAD),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Amount
                      _buildInputField(
                        controller: _amountController,
                        label: "Amount",
                        keyboardType: TextInputType.number,
                        validator: _validateNumber,
                      ),
                      const SizedBox(height: 20),

                      // Bank dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedBank,
                        decoration: _inputDecoration("Select Bank Type"),
                        dropdownColor: Colors.white,
                        iconEnabledColor: const Color(0xFF004AAD),
                        style: const TextStyle(color: Colors.black87),
                        items: _banks
                            .map(
                              (bank) => DropdownMenuItem(
                                value: bank,
                                child: Text(bank),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedBank = val);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select a bank";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Account number
                      _buildInputField(
                        controller: _accountController,
                        label: "Account Number",
                        keyboardType: TextInputType.number,
                        validator: _validateNumber,
                      ),
                      const SizedBox(height: 20),

                      // Withdraw password
                      _buildInputField(
                        controller: _passwordController,
                        label: "Withdraw Password",
                        obscureText: true,
                        validator: _validateText,
                      ),

                      const SizedBox(height: 25),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _handleWithdraw,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004AAD),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Withdraw",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_message != null)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF004AAD).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF004AAD).withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            _message!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF004AAD)),
                      ),
                    ),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF004AAD), width: 2),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }
}

