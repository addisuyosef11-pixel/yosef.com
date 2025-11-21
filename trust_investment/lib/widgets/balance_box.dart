import 'package:flutter/material.dart';
import '../models/balance_model.dart';
import '../services/api_service.dart';

class BalanceBox extends StatefulWidget {
  final int userId;
  const BalanceBox({super.key, required this.userId});

  @override
  State<BalanceBox> createState() => _BalanceBoxState();
}

class _BalanceBoxState extends State<BalanceBox> {
  BalanceModel? balance;
  bool isHidden = false;

  @override
  void initState() {
    super.initState();
    fetchBalance();
  }

  Future<void> fetchBalance() async {
    try {
      final data = await ApiService.fetchBalance(widget.userId);
      setState(() => balance = data);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF002D62), Color(0xFF005EB8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
          Row(
            children: [
              Text(
                isHidden
                    ? '**** ETB'
                    : '${balance?.amount.toStringAsFixed(2) ?? "--"} ETB',
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility, color: Colors.white),
                onPressed: () => setState(() => isHidden = !isHidden),
              ),
            ],
          ),
          Text(
            'Account: 1000150744672',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
