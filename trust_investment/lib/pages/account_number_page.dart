import 'package:flutter/material.dart';
import 'api_service.dart';

class AccountNumberPage extends StatefulWidget {
  final String token; // Receive the token from previous page

  const AccountNumberPage({Key? key, required this.token}) : super(key: key);

  @override
  State<AccountNumberPage> createState() => _AccountNumberPageState();
}

class _AccountNumberPageState extends State<AccountNumberPage> {
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  String? _selectedBankType;
  bool _isLoading = false;
  String? _error;

  // Colors from your SettingsPage
  static const Color primaryColor = Color(0xFF9C27B0);
  static const Color secondaryColor = Color(0xFF7B1FA2);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color textColor = Colors.black87;
  static const Color subtitleColor = Colors.black54;

  // Bank type options
  final List<String> _bankTypes = [
    'Savings Account',
    'Current Account',
    'Fixed Deposit',
    'Joint Account',
    'Salary Account',
  ];

  @override
  void dispose() {
    _merchantController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _updateAccountDetails() async {
    final String merchantName = _merchantController.text.trim();
    final String accountNumber = _accountController.text.trim();

    if (merchantName.isEmpty) {
      setState(() => _error = "Please enter merchant name");
      return;
    }

    if (_selectedBankType == null) {
      setState(() => _error = "Please select bank type");
      return;
    }

    if (accountNumber.isEmpty) {
      setState(() => _error = "Please enter account number");
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
        merchantName: merchantName,
        bankType: _selectedBankType!,
        newAccountNumber: accountNumber,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account details updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // Clear form
        _merchantController.clear();
        _accountController.clear();
        setState(() => _selectedBankType = null);
      } else {
        setState(() => _error = "Failed to update account details");
      }
    } catch (e) {
      setState(() => _error = "Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Bank Account Details'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bank Account Details",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Update your bank account information",
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Merchant Name Field
                Text(
                  "Merchant Name",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _merchantController,
                  decoration: InputDecoration(
                    hintText: "Enter your merchant/business name",
                    hintStyle: TextStyle(color: subtitleColor),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Bank Type Dropdown
                Text(
                  "Bank Account Type",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedBankType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                    hint: Text(
                      "Select account type",
                      style: TextStyle(color: subtitleColor),
                    ),
                    items: _bankTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(color: textColor),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBankType = newValue;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Account Number Field
                Text(
                  "Account Number",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter your account number",
                    hintStyle: TextStyle(color: subtitleColor),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Error message
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 30),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateAccountDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_outlined, size: 20),
                              SizedBox(width: 10),
                              Text(
                                "Update Account Details",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}