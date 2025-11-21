import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class RechargePage extends StatefulWidget {
  final String token;
  const RechargePage({super.key, required this.token});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  XFile? _pickedImage;
  bool _isSubmitting = false;

  static const String _apiUrl = "http://127.0.0.1:8000/api/recharge/";
  static const int _minDeposit = 645;

  final Map<String, String> _accounts = {
    "CBE": "1000311483076 (Yosef Addisu)",
    "TeleBirr": "0941815119 (Yosef Addisu)",
  };

  String? _selectedAccount;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(minutes: 15);
  bool _merchantExpired = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _remainingTime = const Duration(minutes: 15);
    _merchantExpired = false;
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        setState(() {
          _merchantExpired = true;
        });
        timer.cancel();
      } else {
        setState(() {
          _remainingTime -= const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _pickImage() async {
    if (_merchantExpired) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = picked);
    }
  }

  Future<void> _submitRecharge() async {
    if (_amountController.text.isEmpty ||
        int.tryParse(_amountController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid amount")),
      );
      return;
    }
    if (int.parse(_amountController.text) < _minDeposit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Minimum deposit is $_minDeposit birr")),
      );
      return;
    }

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload your payment screenshot")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.fields['bank'] = _selectedAccount ?? "Unknown";
      request.fields['amount'] = _amountController.text;
      request.headers['Authorization'] = 'Token ${widget.token}';
      request.files
          .add(await http.MultipartFile.fromPath('proof', _pickedImage!.path));

      var response = await request.send();
      var resBody = await response.stream.bytesToString();
      final data = json.decode(resBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _nextStep();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Deposit successful! Balance updated.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${data['error'] ?? 'Failed'}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exception: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      if (_currentStep == 2) _startCountdown(); // Start timer on upload step
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Deposit Funds",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),

          // STEP LINE
          _buildStepLine(_currentStep),

          Expanded(child: _buildStepContent()),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    const green = Color(0xFF00C853);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          bool isDone = index <= step;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isDone ? green : Colors.grey[300],
                  child: Icon(Icons.check,
                      size: 14, color: isDone ? Colors.white : Colors.transparent),
                ),
                if (index != 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < step ? green : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _chooseAccountStep();
      case 1:
        return _enterAmountStep();
      case 2:
        return _uploadScreenshotStep();
      case 3:
        return _successStep();
      default:
        return const SizedBox();
    }
  }

  Widget _chooseAccountStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Choose Payment Method",
              style: TextStyle(color: Colors.black87, fontSize: 18)),
          const SizedBox(height: 20),
          ..._accounts.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedAccount = entry.key);
                  _nextStep();
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: _selectedAccount == entry.key
                        ? Colors.green
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key,
                          style: TextStyle(
                              color: _selectedAccount == entry.key
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(entry.value,
                          style: TextStyle(
                              color: _selectedAccount == entry.key
                                  ? Colors.white70
                                  : Colors.black54,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _enterAmountStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              "Enter Deposit Amount (Min 645 ETB)",
              style: TextStyle(color: Colors.black87, fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: "e.g. 1000",
                hintStyle: const TextStyle(color: Colors.black38),
                filled: true,
                fillColor: Colors.grey[100],
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: const Text("Next",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadScreenshotStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Upload Screenshot",
              style: TextStyle(color: Colors.black87, fontSize: 18)),
          const SizedBox(height: 10),
          if (!_merchantExpired)
            Text(
              "Merchant ID valid for: ${_remainingTime.inMinutes.toString().padLeft(2,'0')}:${(_remainingTime.inSeconds % 60).toString().padLeft(2,'0')}",
              style: const TextStyle(color: Colors.red, fontSize: 16),
            )
          else
            const Text(
              "Merchant ID expired!",
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _merchantExpired ? null : _pickImage,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
                border: Border.all(color: Colors.green),
              ),
              child: _pickedImage == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload, color: Colors.black38, size: 40),
                          SizedBox(height: 8),
                          Text("Tap to upload screenshot",
                              style: TextStyle(color: Colors.black38)),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_pickedImage!.path),
                          fit: BoxFit.cover),
                    ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed:
                _merchantExpired || _isSubmitting ? null : _submitRecharge,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Submit",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _successStep() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 100),
          SizedBox(height: 20),
          Text("Deposit Successful!",
              style: TextStyle(color: Colors.black87, fontSize: 20)),
          SizedBox(height: 10),
          Text("Your balance has been updated.",
              style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
