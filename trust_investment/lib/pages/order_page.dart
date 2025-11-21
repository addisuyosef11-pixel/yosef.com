import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pushable_button/pushable_button.dart';
import 'api_service.dart';

class OrderPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> vipData;

  const OrderPage({super.key, required this.token, required this.vipData});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class RadialSpinner extends StatefulWidget {
  final double size;
  final int lines;
  final double lineLength;
  final double lineWidth;
  final Color color;

  const RadialSpinner({
    super.key,
    this.size = 28,
    this.lines = 12,
    this.lineLength = 8,
    this.lineWidth = 3,
    this.color = Colors.grey,
  });

  @override
  State<RadialSpinner> createState() => _RadialSpinnerState();
}

class _RadialSpinnerState extends State<RadialSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.rotate(
            angle: 2 * pi * _ctrl.value,
            child: CustomPaint(
              painter: _RadialPainter(
                lines: widget.lines,
                lineLength: widget.lineLength,
                lineWidth: widget.lineWidth,
                color: widget.color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadialPainter extends CustomPainter {
  final int lines;
  final double lineLength;
  final double lineWidth;
  final Color color;

  _RadialPainter({
    required this.lines,
    required this.lineLength,
    required this.lineWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < lines; i++) {
      final angle = 2 * pi * i / lines;
      final start = center + Offset(cos(angle), sin(angle)) * (size.width / 4);
      final end =
          center + Offset(cos(angle), sin(angle)) * (size.width / 4 + lineLength);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _OrderPageState extends State<OrderPage> {
  double _balance = 0.0;
  bool _isProcessing = false;
  DateTime? _lastClaimTime;

  int _currentStep = -1;
  List<String> _steps = [
    "Checking network",
    "Checking balance",
    "Calculating income",
    "Processing claim"
  ];
  List<String> _results = ["pending", "pending", "pending", "pending"];

  int _selectedTab = 0; // 0 = Valid, 1 = Expired
  List<Map<String, dynamic>> _boughtVIPs = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _loadBoughtVIPs();
    _lastClaimTime = widget.vipData['last_claim_time'] != null
        ? DateTime.tryParse(widget.vipData['last_claim_time'])
        : null;
  }

  double parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  int parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await ApiService.getProfile(widget.token);
      if (!mounted) return;
      if (profile != null) {
        setState(() {
          _balance = parseDouble(profile['balance']);
        });
      }
    } catch (e) {}
  }

  Future<void> _loadBoughtVIPs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList("bought_vips");
    if (jsonList != null) {
      setState(() {
        _boughtVIPs =
            jsonList.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      });
    }
  }

  Future<void> _saveBoughtVIPs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonList =
        _boughtVIPs.map((e) => jsonEncode(e)).toList(growable: false);
    await prefs.setStringList("bought_vips", jsonList);
  }

  bool _canClaim() {
    if (_lastClaimTime == null) return true;
    return DateTime.now().difference(_lastClaimTime!).inHours >= 24;
  }

  Future<void> _runStep(int index, {required bool successful}) async {
    if (!mounted) return;
    setState(() => _currentStep = index);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _results[index] = successful ? "success" : "fail";
    });
  }

  Future<void> _claimIncome() async {
    if (_isProcessing) return;
    if (!_canClaim()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can claim once every 24 hours")));
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStep = 0;
      _results = ["pending", "pending", "pending", "pending"];
    });

    await _runStep(0, successful: true);
    await _runStep(1, successful: true);
    await _runStep(2, successful: true);

    try {
      final res = await ApiService.claimVipIncome(widget.token);
      bool ok = res != null && res['success'] == true;
      await _runStep(3, successful: ok);

      if (ok) {
        final dailyIncome = parseDouble(
            widget.vipData['daily_income'] ?? widget.vipData['dailyEarnings']);
        if (!mounted) return;
        setState(() {
          _balance += dailyIncome;
          _lastClaimTime = DateTime.now();
          _boughtVIPs.add(widget.vipData); // Add purchased VIP
        });
        await _saveBoughtVIPs();
      }
    } catch (e) {
      await _runStep(3, successful: false);
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);
  }

  Widget _buildStep(int index) {
    String label = _steps[index];
    String status = _results[index];

    Widget icon;
    if (_currentStep == index && _isProcessing && status == "pending") {
      icon = const RadialSpinner();
    } else if (status == "success") {
      icon = const Icon(Icons.check_circle, color: Colors.green, size: 28);
    } else if (status == "fail") {
      icon = const Icon(Icons.cancel, color: Colors.red, size: 28);
    } else {
      icon = const Icon(Icons.circle_outlined, color: Colors.grey, size: 24);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            icon,
            if (index < _steps.length - 1)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              )
          ],
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 15,
              color: status == "success"
                  ? Colors.green
                  : status == "fail"
                      ? Colors.red
                      : Colors.black87),
        )
      ],
    );
  }

  Widget _tabButton(String title, int index) {
    bool selected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        setState(() {
          _selectedTab = index;
        });
      },
      child: Column(
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.purple : Colors.black87)),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: selected ? 80 : 0,
            color: Colors.purple,
          )
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _validVIPs {
    return _boughtVIPs.where((vip) {
      final lastClaim = vip['last_claim_time'] != null
          ? DateTime.tryParse(vip['last_claim_time'])
          : null;
      if (lastClaim == null) return true;
      final days = parseInt(vip['income_days'] ?? vip['validityDays']);
      return DateTime.now().difference(lastClaim).inDays < days;
    }).toList();
  }

  List<Map<String, dynamic>> get _expiredVIPs {
    return _boughtVIPs.where((vip) {
      final lastClaim = vip['last_claim_time'] != null
          ? DateTime.tryParse(vip['last_claim_time'])
          : null;
      if (lastClaim == null) return false;
      final days = parseInt(vip['income_days'] ?? vip['validityDays']);
      return DateTime.now().difference(lastClaim).inDays >= days;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vip = widget.vipData;
    final name = vip['title'] ?? "VIP Product";
    final dailyIncome = parseDouble(vip['daily_income'] ?? vip['dailyEarnings']);
    final totalIncome = parseDouble(vip['total_earning'] ?? vip['totalIncome']);
    final validityDays = parseInt(vip['income_days'] ?? vip['validityDays']);
    final imageUrl = vip['image_url'] ?? "";

    final ordersToShow =
        _selectedTab == 0 ? _validVIPs : _expiredVIPs;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.purple,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _tabButton("Valid Orders", 0),
                const SizedBox(width: 20),
                _tabButton("Expired Orders", 1),
              ],
            ),
            const SizedBox(height: 16),

            // VIP card (styled like VipProductsPage)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Image.network(
                        imageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // VIP badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              name,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFD700)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text("Daily Income: Br${dailyIncome.toStringAsFixed(2)}",
                              style: GoogleFonts.poppins(fontSize: 15)),
                          Text("Total Earnings: Br${totalIncome.toStringAsFixed(2)}",
                              style: GoogleFonts.poppins(fontSize: 15)),
                          Text("Earning Days: $validityDays days",
                              style: GoogleFonts.poppins(fontSize: 15)),
                        ]),
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Balance
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Balance", style: GoogleFonts.poppins(fontSize: 16)),
                  Text("Br${_balance.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Step progress only visible after claim
            if (_isProcessing)
              Expanded(
                child: ListView.builder(
                  itemCount: _steps.length,
                  itemBuilder: (c, i) => _buildStep(i),
                ),
              ),

            const SizedBox(height: 12),

            // Claim button (3D Pushable style)
            SizedBox(
              width: 140,
              height: 45,
              child: PushableButton(
                height: 45,
                elevation: 6,
                hslColor: HSLColor.fromAHSL(1.0, 270, 0.6, 0.4),
                shadow: BoxShadow(
                  color: Colors.purple.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
                onPressed: _claimIncome,
                child: Center(
                  child: Text(
                    _isProcessing ? "Processing..." : "Claim",
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bought VIPs list (valid or expired)
            Expanded(
              child: ListView.builder(
                itemCount: ordersToShow.length,
                itemBuilder: (c, i) {
                  final v = ordersToShow[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(v['title'] ?? "VIP Product"),
                      subtitle: Text(
                          "Daily: Br${v['daily_income'] ?? v['dailyEarnings']}, Total: Br${v['total_earning'] ?? v['totalIncome']}"),
                    ),
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
