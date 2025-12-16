import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';

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

  // Colors from first style
  static const Color primaryColor = Color(0xFF9C27B0);
  static const Color secondaryColor = Color(0xFF7B1FA2);
  static const Color orangeColor = Color(0xFFFF9800);
  static const Color greenColor = Color(0xFF4CAF50);
  static const Color blueColor = Color(0xFF42A5F5);
  static const Color redColor = Color(0xFFEF5350);
  static const Color gradientStart = Color(0xFF9C27B0);
  static const Color gradientEnd = Color(0xFF7B1FA2);
  
  static const double _cardWidth = 620;
  static const int _countdownMinutes = 15;
  static const double _minDeposit = 10;

  // deposit controls
  final TextEditingController _amountController = TextEditingController();
  final List<int> _quickAmounts = [
    10,
    50,
    100,
    500,
    894,
    1235,
    1798,
    2500,
    4789,
    5734,
    6300,
    8000,
    12700
  ];
  String? _amountError;

  // payment methods
  bool _loadingMethods = true;
  List<Map<String, dynamic>> _methods = [];
  Map<String, dynamic>? _selectedMethod;

  // upload proof
  File? _pickedImage;
  bool _submitting = false;
  final TextEditingController _senderNameCtrl = TextEditingController();
  final TextEditingController _transactionCtrl = TextEditingController();

  // countdown
  Timer? _countdownTimer;
  Duration _expiresIn = Duration.zero;

  // spinner overlay for step-transitions
  bool _showTransitionSpinner = false;
  final Color _spinnerColor = primaryColor;

  // balance from API
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

  // ---------- helpers ----------

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${label ?? "Copied"} to clipboard')));
  }

  // ---------- step transitions ----------

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a bank')));
      return;
    }

    if (!_methodIsAvailable(_selectedMethod!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected bank is unavailable')),
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
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<void> _submitRecharge() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload proof of transfer")));
      return;
    }
    if (_senderNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter sender account name")));
      return;
    }

    setState(() {
      _submitting = true;
      _showTransitionSpinner = true;
    });

    try {
      final apiFuture = ApiService.recharge(
        token: widget.token,
        amount: _amountController.text.trim(),
        paymentMethod: _selectedMethod?['id']?.toString(),
        proof: _pickedImage,
      );

      final results = await Future.wait([
        apiFuture,
        Future.delayed(const Duration(seconds: 3)),
      ]);

      final result = results[0] as Map<String, dynamic>?;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg.toString())));
      }
    } catch (e) {
      debugPrint('Error submitting recharge: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error submitting recharge')));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _showTransitionSpinner = false;
        });
      }
    }
  }

  // ---------- UI building with first style colors ----------

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
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
                        child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _step == 0 ? 'Deposit Funds' : 
                        _step == 1 ? 'Select Method' : 
                        _step == 2 ? 'Complete Payment' : 'Success',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Current Balance',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 4),
              _loadingBalance
                  ? const SizedBox(
                      height: 40,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  : Text(
                      '${_balance.toStringAsFixed(0)} Br',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveCard({required Widget child, Color? gradientColor1, Color? gradientColor2}) {
    return Container(
      width: double.infinity,
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColor1 ?? const Color(0xFFFFD54F),
            gradientColor2 ?? const Color(0xFFFF9800),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradientColor1 ?? Colors.orange).withOpacity(0.3),
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
          Center(child: child),
        ],
      ),
    );
  }

  Widget _roundedWhiteCard({required Widget child, EdgeInsets? padding}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          color: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(padding: padding ?? const EdgeInsets.all(24.0), child: child),
        ),
      );

  // Step 0: Deposit page
  Widget _depositPage() {
    return Stack(
      children: [
        Column(children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _roundedWhiteCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Enter Amount (Br):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  child: Text(_amountError!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showTransitionSpinner ? null : _toPaymentSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Proceed to Deposit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Quick Select:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickAmounts.map((amt) {
                  final bool selected = _amountController.text.trim() == amt.toString();
                  return InkWell(
                    onTap: () => _pickQuickAmount(amt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected ? greenColor : const Color(0xFF8FD9C7),
                          width: selected ? 2.5 : 1.2,
                        ),
                      ),
                      child: Text(
                        '$amt Br',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selected ? greenColor : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Deposit Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Minimum deposit: 10 Br\n'
                      '• Deposits are processed within 5-30 minutes\n'
                      '• Contact support if deposit not received within 1 hour\n'
                      '• Always keep your transaction reference',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ]),
        if (_showTransitionSpinner) _buildOverlaySpinner(),
      ],
    );
  }

  // Step 1: Payment selection
  Widget _paymentSelectionPage() {
    return Stack(
      children: [
        Column(children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _roundedWhiteCard(
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Text(
                    'Amount to Deposit: ${_amountController.text.trim()} Br',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Select a Bank:', style: TextStyle(color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 20),
              _loadingMethods
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: SpinKitCircle(color: _spinnerColor, size: 40)),
                    )
                  : Column(
                      children: [
                        Column(
                          children: _methods.map((method) {
                            final logo = _bankLogoForMethod(method);
                            final available = _methodIsAvailable(method);
                            final isSelected = _selectedMethod != null && _selectedMethod!['id'] == method['id'];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? primaryColor : Colors.transparent,
                                  width: isSelected ? 2 : 0,
                                ),
                              ),
                              child: ListTile(
                                leading: logo != null
                                    ? Image.asset(
                                        logo,
                                        width: 44,
                                        height: 44,
                                        errorBuilder: (c, e, s) {
                                          return CircleAvatar(
                                            backgroundColor: primaryColor.withOpacity(0.1),
                                            child: const Icon(Icons.account_balance, color: primaryColor),
                                          );
                                        },
                                      )
                                    : CircleAvatar(
                                        backgroundColor: primaryColor.withOpacity(0.1),
                                        child: const Icon(Icons.account_balance, color: primaryColor),
                                      ),
                                title: Text(
                                  method['name'] ?? 'Payment Method',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? primaryColor : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  available ? 'Available' : 'Unavailable',
                                  style: TextStyle(
                                    color: available ? greenColor : redColor,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: primaryColor)
                                    : const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  setState(() {
                                    _selectedMethod = method;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showTransitionSpinner ? null : () => setState(() => _step = 0),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Back'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showTransitionSpinner ? null : _toPaymentProcess,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'Proceed to Payment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
            ]),
          ),
        ]),
        if (_showTransitionSpinner) _buildOverlaySpinner(),
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

    return Stack(
      children: [
        Column(children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          
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
                  'Complete within 15 minutes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          _roundedWhiteCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Payment Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Bank details in the first style format
              Container(
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
              
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
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
              
              const SizedBox(height: 24),
              const Text('Sender Account Name:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _senderNameCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Transaction/FT Number:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _transactionCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Upload Proof (JPG, PNG):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: _pickedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Tap to upload payment proof',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '(Screenshot or receipt)',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _pickedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _submitting
                  ? Center(child: SpinKitCircle(color: _spinnerColor, size: 40))
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitRecharge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Submit Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _step = 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Methods'),
                ),
              ),
            ]),
          ),
        ]),
        if (_showTransitionSpinner) _buildOverlaySpinner(),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
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
                    fontSize: 16,
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
    return Column(children: [
      _buildHeaderCard(),
      const SizedBox(height: 40),
      Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: greenColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '🎉 Payment Submitted Successfully!',
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
            const SizedBox(height: 8),
            const Text(
              'You will receive a notification once your payment is verified.',
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
                  _senderNameCtrl.clear();
                  _transactionCtrl.clear();
                  _countdownTimer?.cancel();
                  _expiresIn = Duration.zero;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Make Another Deposit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildOverlaySpinner() {
    return Positioned.fill(
      child: Container(
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
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing...'),
              ],
            ),
          ),
        ),
      ),
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _step == 0 ? 'Deposit Funds' : 
          _step == 1 ? 'Select Method' : 
          _step == 2 ? 'Complete Payment' : 'Success',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Stack(
          children: [
            body,
            if (_showTransitionSpinner) _buildOverlaySpinner(),
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