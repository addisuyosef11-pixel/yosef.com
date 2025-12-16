import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'recharge_page.dart';

class BalancePage extends StatefulWidget {
  final String token;
  const BalancePage({Key? key, required this.token}) : super(key: key);

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  double balance = 0;
  double availableBalance = 0;
  double frozenBalance = 0;
  List<Map<String, dynamic>> withdrawals = [];
  List<Map<String, dynamic>> deposits = [];
  String? bankAccountNumber;
  bool isLoading = true;
  
  List<dynamic> paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchPaymentMethods();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    try {
      // Get profile data which includes balances - FIXED VERSION
      final profileData = await _getBalanceFromApi();
      
      // Get history data
      final withdrawData = await ApiService.getWithdrawals(widget.token);
      final depositData = await ApiService.getRechargeHistory(widget.token);

      setState(() {
        balance = profileData['total'] ?? 0;
        availableBalance = profileData['available'] ?? 0;
        frozenBalance = profileData['frozen'] ?? 0;
        withdrawals = withdrawData;
        deposits = depositData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Failed to load wallet data: $e", isError: true);
    }
  }

  // FIXED: Direct API call for balance
  Future<Map<String, double>> _getBalanceFromApi() async {
    try {
      // Try the profile endpoint first
      final profileUrl = Uri.parse('${ApiService.baseUrl}/profile/');
      final balanceUrl = Uri.parse('${ApiService.baseUrl}/balance/');
      
      final profileResponse = await http.get(
        profileUrl,
        headers: {
          'Authorization': 'Token ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('Profile API Response Status: ${profileResponse.statusCode}');
      print('Profile API Response Body: ${profileResponse.body}');

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        
        // Check if balance is in profile response
        if (profileData.containsKey('balance') || 
            profileData.containsKey('available_balance') ||
            profileData.containsKey('total_balance')) {
          
          return {
            'total': _extractDouble(profileData, ['balance', 'total_balance', 'total']),
            'available': _extractDouble(profileData, ['available_balance', 'available', 'avail_balance']),
            'frozen': _extractDouble(profileData, ['frozen_balance', 'frozen', 'locked_balance']),
          };
        }
      }

      // If profile doesn't have balance, try balance endpoint
      final balanceResponse = await http.get(
        balanceUrl,
        headers: {
          'Authorization': 'Token ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('Balance API Response Status: ${balanceResponse.statusCode}');
      print('Balance API Response Body: ${balanceResponse.body}');

      if (balanceResponse.statusCode == 200) {
        final balanceData = jsonDecode(balanceResponse.body);
        
        return {
          'total': _extractDouble(balanceData, ['balance', 'total_balance', 'total']),
          'available': _extractDouble(balanceData, ['available_balance', 'available', 'avail_balance']),
          'frozen': _extractDouble(balanceData, ['frozen_balance', 'frozen', 'locked_balance']),
        };
      }

      // If both fail, return zeros
      return {'total': 0, 'available': 0, 'frozen': 0};

    } catch (e) {
      print('Error fetching balance: $e');
      return {'total': 0, 'available': 0, 'frozen': 0};
    }
  }

  double _extractDouble(Map<String, dynamic> data, List<String> possibleKeys) {
    for (var key in possibleKeys) {
      if (data.containsKey(key) && data[key] != null) {
        try {
          final value = data[key];
          if (value is double) return value;
          if (value is int) return value.toDouble();
          if (value is String) {
            // Remove any currency symbols and parse
            final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
            return double.tryParse(cleaned) ?? 0.0;
          }
          if (value is num) return value.toDouble();
        } catch (e) {
          print('Error extracting $key: $e');
        }
      }
    }
    return 0.0;
  }

  // Fetch payment methods - FIXED to handle different response structures
  Future<void> _fetchPaymentMethods() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/payment-methods/');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      print('Payment Methods Response Status: ${response.statusCode}');
      print('Payment Methods Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different response structures
        if (data is Map) {
          if (data.containsKey('payment_methods')) {
            setState(() {
              paymentMethods = List<dynamic>.from(data['payment_methods'] ?? []);
            });
          } else if (data.containsKey('methods')) {
            setState(() {
              paymentMethods = List<dynamic>.from(data['methods'] ?? []);
            });
          } else if (data.containsKey('data')) {
            setState(() {
              paymentMethods = List<dynamic>.from(data['data'] ?? []);
            });
          }
        } else if (data is List) {
          setState(() {
            paymentMethods = List<dynamic>.from(data);
          });
        }
        
        print('Loaded ${paymentMethods.length} payment methods');
      } else {
        print('Payment methods API failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch payment methods: $e');
    }
  }

  // Process withdrawal - FIXED with better error handling
  Future<String> _processWithdrawal(String token, double amount) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/withdraw/');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'amount': amount}),
      );

      print('Withdrawal Response Status: ${response.statusCode}');
      print('Withdrawal Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status']?.toString() ?? 'success';
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        final errorMsg = data['error']?.toString() ?? data['message']?.toString() ?? data['detail']?.toString() ?? '';
        
        print('400 Error Message: $errorMsg');
        
        if (errorMsg.toLowerCase().contains('insufficient')) {
          return 'insufficient';
        }
        if (errorMsg.toLowerCase().contains('password') || errorMsg.toLowerCase().contains('withdraw_password')) {
          return 'withdraw_password_not_set';
        }
        if (errorMsg.toLowerCase().contains('minimum')) {
          return 'minimum_amount_not_met';
        }
        return 'withdrawal_failed: $errorMsg';
      } else if (response.statusCode == 401) {
        return 'unauthorized';
      } else if (response.statusCode == 403) {
        return 'forbidden';
      } else {
        return 'withdrawal_failed: ${response.statusCode}';
      }
    } catch (e) {
      print('Withdrawal error: $e');
      return 'error: $e';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ... REST OF THE CODE REMAINS EXACTLY THE SAME ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wallet',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildBalanceDetails(),
                    const SizedBox(height: 24),
                    _buildLinkAccountSection(),
                    const SizedBox(height: 24),
                    _buildActionCards(),
                    const SizedBox(height: 24),
                    _buildRecentTransactions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.wallet, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'My Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _showWithdrawDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Total Balance',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${balance.toStringAsFixed(0)} Br',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _navigateToRechargePage(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                  ),
                  child: const Text('Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NEW: Navigate to Recharge Page
  void _navigateToRechargePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RechargePage(token: widget.token),
      ),
    ).then((_) {
      // Refresh data when returning from recharge page
      _fetchData();
    });
  }

  Widget _buildBalanceDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Balance Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _balanceDetailItem(
                  'Available',
                  '${availableBalance.toStringAsFixed(0)} Br',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _balanceDetailItem(
                  'Frozen',
                  '${frozenBalance.toStringAsFixed(0)} Br',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceDetailItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Link Account',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showLinkAccountDialog(),
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: CustomPaint(
                      size: const Size(double.infinity, 60),
                      painter: WavePainter(),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.orange, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bankAccountNumber != null ? 'Update Account' : 'Bank Account',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (bankAccountNumber != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '****${bankAccountNumber!.substring(bankAccountNumber!.length - 4)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
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
      ],
    );
  }

  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            'Deposit\nRecord',
            Icons.receipt_long,
            const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1976D2)]),
            () => _showHistoryDialog('deposits'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            'Withdrawal\nRecord',
            Icons.description,
            const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFE64A19)]),
            () => _showHistoryDialog('withdrawals'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            'Set\nPassword',
            Icons.lock,
            const LinearGradient(colors: [Color(0xFFEF5350), Color(0xFFD32F2F)]),
            () => _showSetPasswordDialog(),
          ),
        ),
      ],
    );
  }

  Widget _actionCard(String title, IconData icon, LinearGradient gradient, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final allTransactions = [...deposits, ...withdrawals]
      ..sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
    
    final recentTransactions = allTransactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Column(
            children: recentTransactions.map((tx) => _buildTransactionCard(tx)).toList(),
          ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final isDeposit = deposits.contains(tx);
    final amount = tx['amount'] ?? 0;
    final date = tx['created_at']?.toString().split('T').first ?? '';
    final status = tx['status'] ?? 'pending';
    final isSuccess = status.toLowerCase() == 'success' || 
                     status.toLowerCase() == 'completed' || 
                     status.toLowerCase() == 'approved';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDeposit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isDeposit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isDeposit ? 'Deposit' : 'Withdrawal'} - $amount Br',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDeposit ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          _buildStatusChip(status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'success':
      case 'approved':
      case 'completed':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pending':
      case 'processing':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.access_time;
        break;
      default:
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.substring(0, 1).toUpperCase() + status.substring(1),
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ========== DIALOGS ==========

  void _showWithdrawDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.arrow_upward, color: Colors.red[400]),
            const SizedBox(width: 8),
            const Text('Withdraw Funds'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available Balance', style: TextStyle(color: Colors.grey)),
                  Text('${availableBalance.toStringAsFixed(0)} Br', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (Br)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixText: 'Br ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0 || amount > availableBalance) {
                _showSnackBar('Invalid amount', isError: true);
                return;
              }
              Navigator.pop(ctx);
              
              setState(() => isLoading = true);
              final result = await _processWithdrawal(widget.token, amount);
              setState(() => isLoading = false);
              
              if (result == 'success') {
                _showSnackBar('Withdrawal of $amount Br initiated');
                await _fetchData();
              } else if (result == 'insufficient') {
                _showSnackBar('Insufficient balance', isError: true);
              } else if (result == 'withdraw_password_not_set') {
                _showSnackBar('Please set withdrawal password first', isError: true);
              } else if (result == 'minimum_amount_not_met') {
                _showSnackBar('Amount is below minimum withdrawal limit', isError: true);
              } else if (result == 'unauthorized') {
                _showSnackBar('Session expired. Please login again.', isError: true);
              } else if (result == 'forbidden') {
                _showSnackBar('You do not have permission to withdraw', isError: true);
              } else {
                _showSnackBar('Withdrawal failed: $result', isError: true);
              }
            },
            child: const Text('Withdraw', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLinkAccountDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.credit_card, color: Colors.purple[400]),
            const SizedBox(width: 8),
            const Text('Link Bank Account'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: 'Account Number',
            hintText: 'Enter 20-digit account number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (controller.text.length < 20) {
                _showSnackBar('Enter valid account number', isError: true);
                return;
              }
              Navigator.pop(ctx);
              
              setState(() => isLoading = true);
              // Update this function according to your API
              // final result = await accountNumberUpdate(controller.text);
              setState(() => isLoading = false);
              
              // if (result == 'success') {
              //   _showSnackBar('Bank account linked successfully');
              // } else {
              //   _showSnackBar('Failed: $result', isError: true);
              // }
              _showSnackBar('Account linking not implemented in this example');
            },
            child: const Text('Link Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSetPasswordDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.blue[400]),
            const SizedBox(width: 8),
            const Text('Set Withdrawal Password'),
          ],
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter withdrawal password',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final password = controller.text.trim();
              if (password.length < 4) {
                _showSnackBar('Password must be at least 4 characters', isError: true);
                return;
              }
              Navigator.pop(ctx);
              
              setState(() => isLoading = true);
              // Update this according to your API
              // final success = await ApiService.setWithdrawPassword(
              //   token: widget.token,
              //   withdrawPassword: password,
              // );
              setState(() => isLoading = false);
              
              // if (success) {
              //   _showSnackBar('Withdrawal password set successfully');
              // } else {
              //   _showSnackBar('Failed to set password', isError: true);
              // }
              _showSnackBar('Password setting not implemented in this example');
            },
            child: const Text('Set Password', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(String type) {
    List<Map<String, dynamic>> data;
    String title;
    Color color;

    switch (type) {
      case 'deposits':
        data = deposits;
        title = 'Deposit History';
        color = Colors.blue;
        break;
      case 'withdrawals':
        data = withdrawals;
        title = 'Withdrawal History';
        color = Colors.orange;
        break;
      default:
        data = [...deposits, ...withdrawals];
        data.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
        title = 'All Transactions';
        color = Colors.purple;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.history, color: color),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: data.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No transactions yet', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: data.length,
                      itemBuilder: (_, i) {
                        final tx = data[i];
                        final isDeposit = deposits.contains(tx);
                        return _buildTransactionCard(tx);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.3, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.7, size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}