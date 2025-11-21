


import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'api_service.dart';

class LuckyWheelPage extends StatefulWidget {
  final String token;
  final double currentBalance;

  const LuckyWheelPage({
    Key? key,
    required this.token,
    required this.currentBalance,
  }) : super(key: key);

  @override
  State<LuckyWheelPage> createState() => _LuckyWheelPageState();
}

class _LuckyWheelPageState extends State<LuckyWheelPage> {
  final StreamController<int> _controller = StreamController<int>();
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 3));
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<int> values = [10, 30, 50, 100, 200, 250, 300];
  final List<Color> colors = [
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.purple,
    Colors.yellow,
    Colors.pink
  ];

  bool _spinning = false;
  List<Map<String, dynamic>> recentWinnings = [];

  @override
  void initState() {
    super.initState();
    _fetchRecentWinnings();
  }

  @override
  void dispose() {
    _controller.close();
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchRecentWinnings() async {
    try {
      final data = await ApiService.getRecentWinnings(widget.token);
      setState(() {
        recentWinnings = data.reversed
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (e) {
      print("Error fetching recent winnings: $e");
    }
  }

  void spinWheel() async {
    if (_spinning) return;
    setState(() => _spinning = true);

    final random = Random();
    int selectedIndex = random.nextInt(values.length);
    double selectedAmount = values[selectedIndex].toDouble();

    _audioPlayer.play(AssetSource("sounds/spin.mp3"));
    _controller.add(selectedIndex);

    Future.delayed(const Duration(seconds: 4), () async {
      _confettiController.play();
      _showCongratulationsOverlay(selectedAmount);

      try {
        await ApiService.recordWinning(widget.token, selectedAmount);
        recentWinnings.insert(0, {
          'amount': selectedAmount,
          'timestamp': DateTime.now().toString()
        });
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to record winning: $e")),
        );
      }

      setState(() => _spinning = false);
    });
  }

  void _showCongratulationsOverlay(double value) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        children: [
          AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "🎉 Congratulations! 🎉",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  "You won $value ETB",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () {
                    double newBalance = widget.currentBalance + value;
                    Navigator.of(context).pop(); // close dialog
                    Navigator.of(context).pop(newBalance); // return updated balance
                  },
                  child: const Text("Back to Home"),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: colors,
              gravity: 0.3,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Lucky Wheel", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Balance: ${widget.currentBalance.toStringAsFixed(2)} ETB",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: FortuneWheel(
                selected: _controller.stream,
                animateFirst: false,
                physics: CircularPanPhysics(
                    duration: const Duration(seconds: 4),
                    curve: Curves.easeOutCubic),
                items: [
                  for (int i = 0; i < values.length; i++)
                    FortuneItem(
                      child: Text(
                        values[i].toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      style: FortuneItemStyle(color: colors[i], borderWidth: 0),
                    ),
                ],
                indicators: const [
                  FortuneIndicator(
                      alignment: Alignment.topCenter,
                      child: TriangleIndicator(color: Colors.black)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _spinning ? null : spinWheel,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 14)),
              child: const Text("SPIN",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 30),
            const Text("Recent Winnings",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: recentWinnings.isEmpty
                  ? const Center(child: Text("No recent winnings yet"))
                  : ListView.builder(
                      itemCount: recentWinnings.length,
                      itemBuilder: (context, index) {
                        final win = recentWinnings[index];
                        return ListTile(
                          leading: const Icon(Icons.emoji_events,
                              color: Colors.orange),
                          title: Text("${win['amount']} ETB",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(win['timestamp'].toString()),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
