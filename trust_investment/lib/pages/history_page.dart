// lib/pages/history_page.dart
import 'package:flutter/material.dart';
import 'api_service.dart';

class HistoryPage extends StatefulWidget {
  final String token;

  const HistoryPage({Key? key, required this.token}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  String? _errorMessage;
  List<dynamic> _withdrawHistory = [];
  List<dynamic> _aviatorHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final withdrawals = await ApiService.getWithdrawHistory(widget.token);
      final aviator = await ApiService.aviatorHistory(widget.token);

      setState(() {
        _withdrawHistory = withdrawals;
        _aviatorHistory = aviator;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch history: $e";
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildHistoryList(String title, List<dynamic> history) {
    if (history.isEmpty) {
      return Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("No records yet")
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            final amount = item['amount'] ?? item['balance'] ?? 0;
            final timestamp = item['timestamp'] ?? item['date'] ?? 'Unknown';
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text("Amount: $amount"),
              subtitle: Text("Date: $timestamp"),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHistoryList("Withdrawals", _withdrawHistory),
                      _buildHistoryList("Aviator History", _aviatorHistory),
                    ],
                  ),
                ),
    );
  }
}
