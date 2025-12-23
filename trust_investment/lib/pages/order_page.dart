import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class OrderPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> vipData;

  const OrderPage({super.key, required this.token, required this.vipData});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with TickerProviderStateMixin {
  double _balance = 0.0;
  bool _isProcessing = false;
  DateTime? _lastClaimTime;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  int _selectedTab = 0; // 0 = Active, 1 = Completed
  List<Map<String, dynamic>> _boughtVIPs = [];
  Map<String, double> _dailyEarnings = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _animationController.forward();
    
    _lastClaimTime = widget.vipData['last_claim_time'] != null
        ? DateTime.tryParse(widget.vipData['last_claim_time'])
        : null;
    
    _fetchProfile();
    _loadBoughtVIPs();
    _calculateDailyEarnings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  Future<void> _loadBoughtVIPs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? jsonList = prefs.getStringList("bought_vips");
      if (jsonList != null) {
        setState(() {
          _boughtVIPs = jsonList
              .map((e) => jsonDecode(e) as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      print("Error loading bought VIPs: $e");
    }
  }

  Future<void> _saveBoughtVIPs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> jsonList =
          _boughtVIPs.map((e) => jsonEncode(e)).toList(growable: false);
      await prefs.setStringList("bought_vips", jsonList);
    } catch (e) {
      print("Error saving bought VIPs: $e");
    }
  }

  void _calculateDailyEarnings() {
    Map<String, double> earnings = {};
    for (var vip in _boughtVIPs) {
      final id = vip['id'].toString();
      final dailyIncome = parseDouble(vip['daily_income'] ?? vip['dailyEarnings']);
      earnings[id] = (earnings[id] ?? 0.0) + dailyIncome;
    }
    setState(() {
      _dailyEarnings = earnings;
    });
  }

  double get _totalDailyEarnings {
    return _dailyEarnings.values.fold(0.0, (sum, value) => sum + value);
  }

  List<Map<String, dynamic>> get _activeVIPs {
    return _boughtVIPs.where((vip) {
      final lastClaim = vip['last_claim_time'] != null
          ? DateTime.tryParse(vip['last_claim_time'])
          : null;
      if (lastClaim == null) return true;
      final days = parseInt(vip['income_days'] ?? vip['validityDays']);
      return DateTime.now().difference(lastClaim).inDays < days;
    }).toList();
  }

  List<Map<String, dynamic>> get _completedVIPs {
    return _boughtVIPs.where((vip) {
      final lastClaim = vip['last_claim_time'] != null
          ? DateTime.tryParse(vip['last_claim_time'])
          : null;
      if (lastClaim == null) return false;
      final days = parseInt(vip['income_days'] ?? vip['validityDays']);
      return DateTime.now().difference(lastClaim).inDays >= days;
    }).toList();
  }

  bool _canClaim() {
    if (_lastClaimTime == null) return true;
    return DateTime.now().difference(_lastClaimTime!).inHours >= 24;
  }

  Future<void> _claimIncome() async {
    if (_isProcessing || !_canClaim()) return;
    
    if (!_canClaim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Next claim available in ${24 - DateTime.now().difference(_lastClaimTime!).inHours} hours",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Show processing animation
      await Future.delayed(const Duration(seconds: 1));
      
      final res = await ApiService.claimVipIncome(widget.token);
      bool ok = res != null && res['success'] == true;

      if (ok && mounted) {
        final dailyIncome = parseDouble(
            widget.vipData['daily_income'] ?? widget.vipData['dailyEarnings']);
        
        // Animate balance update
        final targetBalance = _balance + dailyIncome;
        await _animateBalanceUpdate(targetBalance);
        
        setState(() {
          _lastClaimTime = DateTime.now();
        });

        // Show success animation
        _showSuccessAnimation(dailyIncome);
      } else {
        _showErrorSnackbar();
      }
    } catch (e) {
      _showErrorSnackbar();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _animateBalanceUpdate(double targetBalance) async {
    final duration = const Duration(milliseconds: 500);
    final steps = 20;
    final increment = (targetBalance - _balance) / steps;
    
    for (int i = 0; i <= steps; i++) {
      if (!mounted) break;
      await Future.delayed(duration ~/ steps);
      setState(() {
        _balance += increment;
      });
    }
  }

  void _showSuccessAnimation(double amount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              "Successfully claimed ${amount.toStringAsFixed(2)} Br",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              "Claim failed. Please try again",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> vip) {
    final name = vip['title'] ?? "VIP Product";
    final dailyIncome = parseDouble(vip['daily_income'] ?? vip['dailyEarnings']);
    final totalIncome = parseDouble(vip['total_earning'] ?? vip['totalIncome']);
    final validityDays = parseInt(vip['income_days'] ?? vip['validityDays']);
    final isActive = _selectedTab == 0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Icon(
              isActive ? Icons.rocket_launch : Icons.check_circle,
              color: isActive ? Colors.green : Colors.grey,
              size: 28,
            ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildInfoChip(
                  Icons.trending_up,
                  "${dailyIncome.toStringAsFixed(2)} Br/day",
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.calendar_today,
                  "$validityDays days",
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Total: ${totalIncome.toStringAsFixed(2)} Br",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isActive ? "ACTIVE" : "COMPLETED",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool selected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple : Colors.grey[50],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? Colors.deepPurple : Colors.grey[200]!,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vip = widget.vipData;
    final name = vip['title'] ?? "VIP Product";
    final dailyIncome = parseDouble(vip['daily_income'] ?? vip['dailyEarnings']);
    final ordersToShow = _selectedTab == 0 ? _activeVIPs : _completedVIPs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.shade700,
                        Colors.purple.shade600,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              "Income & Orders",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _fetchProfile,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                            "Total Daily",
                            "${_totalDailyEarnings.toStringAsFixed(2)} Br",
                            Icons.trending_up,
                            Colors.yellow,
                          ),
                          _buildStatItem(
                            "Active Orders",
                            "${_activeVIPs.length}",
                            Icons.shopping_bag,
                            Colors.green,
                          ),
                          _buildStatItem(
                            "Balance",
                            "${_balance.toStringAsFixed(2)} Br",
                            Icons.account_balance_wallet,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current VIP Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.purple.shade50,
                                Colors.blue.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "CURRENT PLAN",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber.shade400,
                                    size: 24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildDetailItem(
                                    "Daily Income",
                                    "${dailyIncome.toStringAsFixed(2)} Br",
                                    Icons.attach_money,
                                  ),
                                  const SizedBox(width: 20),
                                  _buildDetailItem(
                                    "Next Claim",
                                    _canClaim() ? "Available" : "In ${24 - DateTime.now().difference(_lastClaimTime!).inHours}h",
                                    Icons.access_time,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isProcessing ? null : _claimIncome,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _canClaim() ? Colors.deepPurple : Colors.grey,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                    shadowColor: Colors.deepPurple.withOpacity(0.3),
                                  ),
                                  child: _isProcessing
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              "Processing...",
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _canClaim() ? Icons.bolt : Icons.lock_clock,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _canClaim() ? "CLAIM INCOME" : "CLAIM LOCKED",
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tabs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTabButton("Active Orders", 0),
                            const SizedBox(width: 12),
                            _buildTabButton("Completed", 1),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Orders List
                        if (ordersToShow.isEmpty)
                          Column(
                            children: [
                              Icon(
                                _selectedTab == 0 
                                    ? Icons.shopping_bag_outlined 
                                    : Icons.check_circle_outline,
                                size: 60,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedTab == 0
                                    ? "No active orders"
                                    : "No completed orders",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          )
                        else
                          ...ordersToShow.map(_buildOrderItem).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}