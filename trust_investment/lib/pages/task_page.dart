import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class TaskPage extends StatefulWidget {
  final String token; // Token received after login
  const TaskPage({Key? key, required this.token}) : super(key: key);

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  bool _isClaiming = false;
  bool _adWatched = false;
  bool _joinedTelegram = false;
  bool _rechargeClaimed = false;
  double _balance = 0.0;

  final String baseUrl = "https://your-django-api.com/api"; // 🔹 change to your backend base URL

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// Fetch user balance and task status
  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/tasks/status/"),
        headers: {
          "Authorization": "Token ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _balance = (data['balance'] ?? 0).toDouble();
          _adWatched = data['ad_watched'] ?? false;
          _joinedTelegram = data['joined_telegram'] ?? false;
          _rechargeClaimed = data['recharge_claimed'] ?? false;
        });
      } else {
        debugPrint("Error fetching data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  /// Watch Ad task
  Future<void> _watchAd() async {
    setState(() => _isClaiming = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/tasks/watch-ad/"),
        headers: {
          "Authorization": "Token ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _adWatched = true;
          _balance += 5;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ad watched successfully! +5 ETB")),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to update ad task")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isClaiming = false);
    }
  }

  /// Join Telegram task
  Future<void> _joinTelegram() async {
    const telegramUrl = 'https://t.me/your_channel_here';
    if (await canLaunch(telegramUrl)) {
      await launch(telegramUrl);
      try {
        final response = await http.post(
          Uri.parse("$baseUrl/tasks/join-telegram/"),
          headers: {
            "Authorization": "Token ${widget.token}",
            "Content-Type": "application/json",
          },
        );
        if (response.statusCode == 200) {
          setState(() => _joinedTelegram = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Joined Telegram — reward granted!")),
          );
        }
      } catch (e) {
        debugPrint("Error updating join telegram: $e");
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Could not open Telegram link.")));
    }
  }

  /// Claim first recharge bonus
  Future<void> _claimRecharge() async {
    if (_rechargeClaimed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Already claimed.")));
      return;
    }
    setState(() => _isClaiming = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/tasks/claim-recharge/"),
        headers: {
          "Authorization": "Token ${widget.token}",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _rechargeClaimed = true;
          _balance += 10;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recharge bonus claimed successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isClaiming = false);
    }
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required String assetImage,
    required Widget action,
  }) {
    return Card(
      color: const Color(0xFF1E2329),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                assetImage,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey.shade800,
                  child: const Icon(Icons.image_not_supported, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white54)),
                ],
              ),
            ),
            action,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Tasks'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D47A1),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Complete tasks to earn rewards',
                          style: TextStyle(fontSize: 14, color: Colors.white70)),
                      SizedBox(height: 4),
                      Text('First trial recharge available',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _fetchUserData,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Refresh tasks',
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildTaskCard(
                  title: 'Watch Ads',
                  subtitle: _adWatched ? 'Completed' : 'Watch ads to earn ETB 5',
                  assetImage: 'assets/images/watch_ads.jpg',
                  action: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _adWatched ? null : _watchAd,
                    child: Text(_adWatched ? 'Done' : 'Watch'),
                  ),
                ),
                _buildTaskCard(
                  title: 'Join Telegram Channel',
                  subtitle: _joinedTelegram ? 'Joined — thank you!' : 'Join and earn ETB 3',
                  assetImage: 'assets/images/join_telegram.jpg',
                  action: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _joinedTelegram ? null : _joinTelegram,
                    child: Text(_joinedTelegram ? 'Joined' : 'Join'),
                  ),
                ),
                _buildTaskCard(
                  title: 'First Trial Recharge',
                  subtitle: _rechargeClaimed ? 'Claimed' : 'Claim your first recharge bonus',
                  assetImage: 'assets/images/deposit_1.jpg',
                  action: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isClaiming || _rechargeClaimed ? null : _claimRecharge,
                    child: _isClaiming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_rechargeClaimed ? 'Claimed' : 'Claim'),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFF1E2329),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                const Text('Balance:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(8)),
                  child: Text('ETB ${_balance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Redirect to Recharge Page soon...")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Top Up'),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}



