import 'package:flutter/material.dart';
import 'api_service.dart';

class GiftRedeemPage extends StatefulWidget {
  final String token;
  const GiftRedeemPage({super.key, required this.token});

  @override
  State<GiftRedeemPage> createState() => _GiftRedeemPageState();
}

class _GiftRedeemPageState extends State<GiftRedeemPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _message = "Please enter a gift code.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final result = await ApiService.redeemGiftCode(
        token: widget.token,
        code: code,
      );

      setState(() {
        if (result['success'] == true) {
          _message = "Code redeemed successfully! Amount: ${result['amount'] ?? 0}";
        } else {
          _message = "Failed: ${result['message'] ?? 'Invalid code'}";
        }
      });
    } catch (e) {
      setState(() {
        _message = "Error: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Redeem Gift Code"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Paste your gift code below and tap Redeem",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Gift Code",
                hintText: "Enter your gift code",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _codeController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _redeemCode,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.purple,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Redeem", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: _message!.startsWith("Failed") || _message!.startsWith("Error")
                      ? Colors.red
                      : Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
