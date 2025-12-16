import 'package:flutter/material.dart';
import 'api_service.dart';

class AccountNumberPage extends StatefulWidget {
  final String token; // Receive the token from previous page

  const AccountNumberPage({Key? key, required this.token}) : super(key: key);

  @override
  State<AccountNumberPage> createState() => _AccountNumberPageState();
}

class _AccountNumberPageState extends State<AccountNumberPage> {
  final TextEditingController _accountController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _updateAccountNumber() async {
    final String newAccount = _accountController.text.trim();

    if (newAccount.isEmpty) {
      setState(() => _error = "Please enter an account number");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use ApiService with the token passed from previous page
      final success = await ApiService.accountnumberUpdate(
        token: widget.token,
        newAccountNumber: newAccount,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account number updated successfully!')),
        );
        _accountController.clear();
      } else {
        setState(() => _error = "Failed to update account number");
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Account Number')),
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
                const Text(
                  "Update Account Number",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Account Number",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                  onTapDown: (_) => setState(() => _isLoading = true),
                  onTapUp: (_) {
                    if (!_isLoading) _updateAccountNumber();
                  },
                  onTapCancel: () => setState(() => _isLoading = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: double.infinity,
                    height: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isLoading
                          ? [
                              const BoxShadow(
                                  color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)
                            ]
                          : [
                              const BoxShadow(
                                  color: Colors.black38, offset: Offset(0, 6), blurRadius: 10)
                            ],
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "UPDATE",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
}
