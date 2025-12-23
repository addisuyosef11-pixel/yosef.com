import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class RechargePage extends StatefulWidget {
  final String token;
  final double currentBalance;

  const RechargePage({
    Key? key,
    required this.token,
    this.currentBalance = 50.0,
  }) : super(key: key);

  @override
  _RechargePageState createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  int _step = 0;

  // Colors matching HomePage
  static const Color primaryColor = Color(0xFF8B5CF6);
  static const Color secondaryColor = Color(0xFF7C3AED);
  static const Color gradientStart = Color(0xFF8B5CF6);
  static const Color gradientEnd = Color(0xFF6D28D9);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color greenColor = Color(0xFF22C55E);
  static const Color redColor = Color(0xFFEF5350);
  
  static const int _countdownMinutes = 15;
  static const double _minDeposit = 10;

  // Deposit controls
  final TextEditingController _amountController = TextEditingController();
  final List<int> _quickAmounts = [10, 50, 100, 500, 1000, 2000, 5000, 10000];
  String? _amountError;

  // Payment methods
  bool _loadingMethods = true;
  List<Map<String, dynamic>> _methods = [];
  Map<String, dynamic>? _selectedMethod;

  // Upload proof
  File? _pickedImage;
  XFile? _pickedXFile;
  bool _submitting = false;
  final TextEditingController _senderNameCtrl = TextEditingController();
  final TextEditingController _transactionCtrl = TextEditingController();

  // Countdown
  Timer? _countdownTimer;
  Duration _expiresIn = Duration.zero;

  // Spinner overlay
  bool _showTransitionSpinner = false;

  // Balance from API
  double _balance = 0.0;
  bool _loadingBalance = true;

  @override
  void initState() {
    super.initState();
    _balance = widget.currentBalance;
    _fetchBalanceAndMethods();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amountController.dispose();
    _senderNameCtrl.dispose();
    _transactionCtrl.dispose();
    super.dispose();
  }

  // ---------- API calls ----------
  Future<void> _fetchBalanceAndMethods() async {
    setState(() {
      _loadingBalance = true;
      _loadingMethods = true;
    });

    try {
      final results = await Future.wait([
        () async {
          try {
            final profile = await ApiService.getProfile(widget.token);
            if (profile != null && profile['balance'] != null) {
              final b = profile['balance'];
              return double.tryParse(b.toString()) ?? widget.currentBalance;
            }
          } catch (_) {}
          return widget.currentBalance;
        }(),
        () async {
          try {
            final methods = await ApiService.getPaymentMethods(widget.token);
            return methods;
          } catch (_) {
            return <Map<String, dynamic>>[];
          }
        }(),
      ]);

      setState(() {
        _balance = results[0] as double;
        _methods = List<Map<String, dynamic>>.from(results[1] as List<dynamic>);
        if (_methods.isNotEmpty && _selectedMethod == null) _selectedMethod = _methods[0];
      });
    } catch (e) {
      debugPrint('Error fetching balance/methods: $e');
    } finally {
      setState(() {
        _loadingBalance = false;
        _loadingMethods = false;
      });
    }
  }

  Future<void> _fetchPaymentMethods() async {
    setState(() {
      _loadingMethods = true;
    });
    try {
      final methods = await ApiService.getPaymentMethods(widget.token);
      setState(() {
        _methods = List<Map<String, dynamic>>.from(methods);
        if (_methods.isNotEmpty && _selectedMethod == null) _selectedMethod = _methods[0];
      });
    } catch (e) {
      debugPrint('Error fetching methods: $e');
      setState(() {
        _amountError = "Error fetching payment methods";
      });
    } finally {
      setState(() => _loadingMethods = false);
    }
  }

  // ---------- Helpers ----------
  String? _bankLogoForMethod(Map<String, dynamic> method) {
    final name = (method['name'] ?? '').toString().toLowerCase();
    final code = (method['code'] ?? '').toString().toLowerCase();
    if (name.contains('cbe') || code == 'cbe' || name.contains('commercial bank')) {
      return 'assets/images/cbe.jpg';
    }
    if (name.contains('awash') || code == 'awash') {
      return 'assets/images/awash_bank.jpg';
    }
    if (name.contains('abyssinia') || name.contains('abyssin') || code.contains('abyssinia')) {
      return 'assets/images/abyssinia_bank.jpg';
    }
    if (name.contains('tele') || name.contains('telebirr') || code.contains('tele')) {
      return 'assets/images/tele_birr.jpg';
    }
    return null;
  }

  bool _methodIsAvailable(Map<String, dynamic> method) {
    if (method.containsKey('status')) {
      final s = method['status']?.toString().toLowerCase();
      return s == 'available' || s == 'active' || s == 'enabled';
    }
    if (method.containsKey('active')) {
      return method['active'] == true;
    }
    if (method.containsKey('available')) {
      return method['available'] == true;
    }
    return true;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _expiresIn = Duration(minutes: _countdownMinutes);
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expiresIn.inSeconds <= 1) {
        timer.cancel();
        setState(() => _expiresIn = Duration.zero);
      } else {
        setState(() => _expiresIn = _expiresIn - const Duration(seconds: 1));
      }
    });
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _pickQuickAmount(int amount) {
    _amountController.text = amount.toString();
    setState(() => _amountError = null);
  }

  bool _validateDeposit() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() => _amountError = "Enter an amount to deposit");
      return false;
    }
    final n = double.tryParse(text);
    if (n == null || n <= 0) {
      setState(() => _amountError = "Enter a valid amount");
      return false;
    }
    if (n < _minDeposit) {
      setState(() => _amountError = "Minimum deposit is ${_minDeposit.toInt()} Br");
      return false;
    }
    setState(() => _amountError = null);
    return true;
  }

  void _copyToClipboard(String text, [String? label]) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${label ?? "Copied"} to clipboard'),
        backgroundColor: primaryColor,
      ),
    );
  }

  // ---------- Step transitions ----------
  Future<void> _toPaymentSelection() async {
    if (!_validateDeposit()) return;

    setState(() => _showTransitionSpinner = true);

    await Future.wait([
      _fetchPaymentMethods(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;
    setState(() {
      _showTransitionSpinner = false;
      _step = 1;
    });
  }

  Future<void> _toPaymentProcess() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_methodIsAvailable(_selectedMethod!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected bank is unavailable'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _showTransitionSpinner = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    _startCountdown();
    setState(() {
      _showTransitionSpinner = false;
      _step = 2;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) {
      setState(() {
        _pickedXFile = file;
        if (!kIsWeb) {
          _pickedImage = File(file.path);
        } else {
          _pickedImage = null;
        }
      });
    }
  }

  Future<void> _submitRecharge() async {
    if (_pickedXFile == null && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload proof of transfer"), backgroundColor: Colors.red),
      );
      return;
    }
    if (_senderNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter sender account name"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _showTransitionSpinner = true;
    });

    try {
      dynamic proofFile;
      if (kIsWeb) {
        proofFile = _pickedXFile;
      } else {
        proofFile = _pickedImage;
      }

      final result = await ApiService.recharge(
        token: widget.token,
        amount: _amountController.text.trim(),
        paymentMethod: _selectedMethod?['id']?.toString(),
        proof: proofFile,
      );

      if (result != null && (result['success'] == true || (result['message'] != null))) {
        try {
          final profile = await ApiService.getProfile(widget.token);
          if (profile != null && profile['balance'] != null) {
            setState(() => _balance = double.tryParse(profile['balance'].toString()) ?? _balance);
          }
        } catch (_) {}
        if (mounted) setState(() => _step = 3);
      } else {
        final msg = result?['message'] ?? 'Recharge failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString()), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error submitting recharge: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting recharge'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _showTransitionSpinner = false;
        });
      }
    }
  }

  // ---------- UI Components ----------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [gradientStart, gradientEnd],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  _step == 0 ? 'Deposit Funds' : 
                  _step == 1 ? 'Select Bank' : 
                  _step == 2 ? 'Complete Payment' : 'Success',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // For balance alignment
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                _loadingBalance
                    ? const Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : Text(
                        '${_balance.toStringAsFixed(0)} Br',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // Step 0: Deposit page
  Widget _depositPage() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildWhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Amount (Br)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF7F9FA),
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              if (_amountError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _amountError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showTransitionSpinner ? null : _toPaymentSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _showTransitionSpinner
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Select',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickAmounts.map((amt) {
                  final bool selected = _amountController.text.trim() == amt.toString();
                  return GestureDetector(
                    onTap: () => _pickQuickAmount(amt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected ? orangeColor.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? orangeColor : Colors.grey[300]!,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        '$amt Br',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? orangeColor : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Deposit Information',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Minimum deposit: 10 Br\n'
                      '• Processing: 5-30 minutes\n'
                      '• Contact support if not received within 1 hour',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 1: Payment selection
  Widget _paymentSelectionPage() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildWhiteCard(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Amount: ${_amountController.text.trim()} Br',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select payment method',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _loadingMethods
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: SpinKitCircle(color: primaryColor, size: 40),
                      ),
                    )
                  : Column(
                      children: [
                        ..._methods.map((method) {
                          final logo = _bankLogoForMethod(method);
                          final available = _methodIsAvailable(method);
                          final isSelected = _selectedMethod != null && _selectedMethod!['id'] == method['id'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? orangeColor : Colors.transparent,
                                width: isSelected ? 2 : 0,
                              ),
                            ),
                            child: ListTile(
                              leading: logo != null
                                  ? Image.asset(
                                      logo,
                                      width: 40,
                                      height: 40,
                                      errorBuilder: (c, e, s) {
                                        return CircleAvatar(
                                          backgroundColor: primaryColor.withOpacity(0.1),
                                          child: const Icon(Icons.account_balance, color: primaryColor, size: 20),
                                        );
                                      },
                                    )
                                  : CircleAvatar(
                                      backgroundColor: primaryColor.withOpacity(0.1),
                                      child: const Icon(Icons.account_balance, color: primaryColor, size: 20),
                                    ),
                              title: Text(
                                method['name'] ?? 'Payment Method',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? orangeColor : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                available ? 'Available' : 'Unavailable',
                                style: TextStyle(
                                  color: available ? greenColor : redColor,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: orangeColor)
                                  : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              onTap: () {
                                setState(() {
                                  _selectedMethod = method;
                                });
                              },
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _showTransitionSpinner ? null : () => setState(() => _step = 0),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.grey),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Back',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showTransitionSpinner ? null : _toPaymentProcess,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orangeColor,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _showTransitionSpinner
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white),
                                      )
                                    : const Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ],
    );
  }

  // Step 2: Payment process
  Widget _paymentProcessPage() {
    final bank = _selectedMethod ?? <String, dynamic>{};
    final bankName = bank['name'] ?? 'Bank';
    final accountName = bank['account_name'] ?? bank['account'] ?? 'Account Name';
    final accountNumber = bank['account'] ?? bank['number'] ?? '0000000000';
    final orderNumber = 'TRX${DateTime.now().millisecondsSinceEpoch % 1000000}';

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        // Timer Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _expiresIn.inMinutes < 5 ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _expiresIn.inMinutes < 5 ? Colors.orange : Colors.blue,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer,
                color: _expiresIn.inMinutes < 5 ? Colors.orange : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatDuration(_expiresIn),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _expiresIn.inMinutes < 5 ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Complete within 15 min',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildWhiteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              // Bank details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildDetailItem('Bank Name', bankName, icon: Icons.account_balance),
                    const SizedBox(height: 12),
                    _buildDetailItem('Account Name', accountName, icon: Icons.person),
                    const SizedBox(height: 12),
                    _buildDetailItem('Account Number', accountNumber, icon: Icons.numbers),
                    const SizedBox(height: 12),
                    _buildDetailItem('Amount', '${_amountController.text} Br', icon: Icons.money),
                    const SizedBox(height: 12),
                    _buildDetailItem('Reference', orderNumber, icon: Icons.receipt),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.yellow.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠️ IMPORTANT: Use the reference number above when making payment',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sender Account Name',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _senderNameCtrl,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Transaction/FT Number',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _transactionCtrl,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Upload Proof (JPG, PNG)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: (_pickedImage == null && _pickedXFile == null)
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload payment proof',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? _pickedXFile != null
                                  ? Image.network(
                                      _pickedXFile!.path,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : const Center(child: Text('Image not available'))
                              : _pickedImage != null
                                  ? Image.file(
                                      _pickedImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : const Center(child: Text('Image not available')),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _submitting
                  ? Center(
                      child: SpinKitCircle(color: orangeColor, size: 40),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitRecharge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _step = 1),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.green, size: 16),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () => _copyToClipboard(value, label),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3: success page
  Widget _successPage() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 40),
        _buildWhiteCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: greenColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Submitted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your deposit request has been received and is being processed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[400],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verification usually takes 5-15 minutes during business hours.',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _step = 0;
                    _amountController.clear();
                    _pickedImage = null;
                    _pickedXFile = null;
                    _senderNameCtrl.clear();
                    _transactionCtrl.clear();
                    _countdownTimer?.cancel();
                    _expiresIn = Duration.zero;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Make Another Deposit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_step) {
      case 0:
        body = _depositPage();
        break;
      case 1:
        body = _paymentSelectionPage();
        break;
      case 2:
        body = _paymentProcessPage();
        break;
      case 3:
        body = _successPage();
        break;
      default:
        body = _depositPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: body,
          ),
          if (_showTransitionSpinner)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SpinKitCircle(color: orangeColor, size: 40),
                      const SizedBox(height: 16),
                      const Text(
                        'Processing...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}