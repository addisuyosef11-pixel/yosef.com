import 'package:flutter/material.dart';

class IncomePage extends StatefulWidget {
  final String token;
  const IncomePage({Key? key, required this.token}) : super(key: key);

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  List<Map<String, dynamic>> _incomeHistory = [];
  bool _isLoading = true;
  double _totalIncome = 0.0;
  double _todayIncome = 0.0;

  @override
  void initState() {
    super.initState();
    _loadIncomeData();
  }

  Future<void> _loadIncomeData() async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data - replace with your API call
    setState(() {
      _incomeHistory = [
        {
          'date': '2024-01-15',
          'time': '14:30',
          'amount': 1250.0,
          'type': 'VIP Investment',
          'project': 'VIP Level 1',
          'status': 'completed'
        },
        {
          'date': '2024-01-14',
          'time': '10:15',
          'amount': 980.0,
          'type': 'Main Project',
          'project': 'Solar Farm A',
          'status': 'completed'
        },
        {
          'date': '2024-01-13',
          'time': '16:45',
          'amount': 750.0,
          'type': 'VIP Investment',
          'project': 'VIP Level 2',
          'status': 'completed'
        },
        {
          'date': '2024-01-12',
          'time': '09:20',
          'amount': 1200.0,
          'type': 'Referral Bonus',
          'project': 'Team Commission',
          'status': 'completed'
        },
      ];
      _totalIncome = 4180.0;
      _todayIncome = 850.0;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income History'),
        backgroundColor: const Color(0xFF8A2BE2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Income Summary
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8A2BE2), Color(0xFF9B4DCA)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Income',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              '${_totalIncome.toStringAsFixed(2)} Br',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          const Text(
                            'Today',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            '${_todayIncome.toStringAsFixed(2)} Br',
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Income History List
                Expanded(
                  child: ListView.builder(
                    itemCount: _incomeHistory.length,
                    itemBuilder: (context, index) {
                      final income = _incomeHistory[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8A2BE2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.attach_money, color: Color(0xFF8A2BE2)),
                          ),
                          title: Text(
                            income['type'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${income['date']} • ${income['project']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${income['amount']} Br',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                income['time'],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}