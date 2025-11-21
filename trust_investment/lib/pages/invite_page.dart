import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

class InvitePage extends StatefulWidget {
  final String token;
  const InvitePage({super.key, required this.token});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  String _inviteCode = "";
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchInviteCode();
  }

  Future<void> _fetchInviteCode() async {
    try {
      final code = await ApiService.getInviteCode(token: widget.token);
      setState(() => _inviteCode = code);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch invite code: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _copyToClipboard() {
    if (_inviteCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invite"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Colors.green)
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Your Invite Code",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _inviteCode,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: _copyToClipboard,
                            icon:
                                const Icon(Icons.copy, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Copy this code and paste it in the system to redeem your gift.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
