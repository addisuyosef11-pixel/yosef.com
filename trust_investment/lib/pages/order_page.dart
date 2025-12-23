import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'api_service.dart';

class OrderPage extends StatefulWidget {
  final String token;

  const OrderPage({super.key, required this.token});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  double _balance = 0.0;
  double _todaysTotalIncome = 0.0; // Total claimed today
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isApiLoading = false;
  bool _balanceVisible = true;
  
  int _selectedTab = 0; // 0 = All, 1 = Active, 2 = Completed
  List<Map<String, dynamic>> _userInvestments = [];
  List<Map<String, dynamic>> _activeInvestments = [];
  List<Map<String, dynamic>> _completedInvestments = [];
  
  // Timer for countdown
  late Timer _timer;
  Map<int, Duration> _claimTimers = {}; // investment_id -> time remaining
  Map<int, double> _todaysClaims = {}; // investment_id -> amount claimed today
  
  // Track today's date to reset daily income
  String _todayDate = "";
  
  // For showing in-line messages
  String _message = "";
  Color _messageColor = Colors.green;
  bool _showMessage = false;

  @override
  void initState() {
    super.initState();
    _todayDate = DateTime.now().toIso8601String().split('T')[0]; // Get YYYY-MM-DD
    _loadData();
    // Start timer for countdown updates
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateClaimTimers();
          _checkAndResetDailyIncome();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _checkAndResetDailyIncome() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (today != _todayDate) {
      // New day, reset today's income
      setState(() {
        _todaysTotalIncome = 0.0;
        _todaysClaims.clear();
        _todayDate = today;
      });
    }
  }

  void _updateClaimTimers() {
    final now = DateTime.now();
    _claimTimers.clear();
    
    for (var investment in _activeInvestments) {
      final lastClaimTime = investment['last_claim_time']?.toString();
      if (lastClaimTime != null && lastClaimTime.isNotEmpty) {
        try {
          final lastClaim = DateTime.parse(lastClaimTime);
          final nextClaimTime = lastClaim.add(Duration(hours: 24));
          final timeRemaining = nextClaimTime.difference(now);
          
          if (timeRemaining.inSeconds > 0) {
            _claimTimers[investment['id']] = timeRemaining;
          }
        } catch (e) {
          print("Error parsing claim time: $e");
        }
      }
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // Fetch balance
      final balanceData = await ApiService.getBalance(widget.token);
      if (balanceData['success'] == true && mounted) {
        setState(() {
          _balance = (balanceData['total'] ?? 0).toDouble();
        });
      }
      
      // Fetch user's investments
      await _loadUserInvestments();
      
    } catch (e) {
      print("Error loading data: $e");
      _showMessageText("Failed to load investments", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserInvestments() async {
    try {
      setState(() => _isApiLoading = true);
      
      // Use the API method
      final List<Map<String, dynamic>> investments = await ApiService.getUserInvestments(widget.token);
      
      print('📊 Loaded ${investments.length} investments from API');
      
      // Update the main list
      setState(() {
        _userInvestments = investments;
      });
      
      // Categorize investments after loading
      _categorizeInvestments();
      
    } catch (e) {
      print("Error loading user investments: $e");
      _showMessageText("Failed to load investments", isError: true);
    } finally {
      setState(() => _isApiLoading = false);
    }
  }

  void _categorizeInvestments() {
    print('🔍 Categorizing ${_userInvestments.length} investments...');
    
    // Reset categories
    List<Map<String, dynamic>> active = [];
    List<Map<String, dynamic>> completed = [];
    
    final now = DateTime.now();
    
    for (var investment in _userInvestments) {
      final isActive = _isInvestmentActive(investment, now);
      
      print('  - ${investment['title']}: active = $isActive');
      
      if (isActive) {
        active.add(investment);
      } else {
        completed.add(investment);
      }
    }
    
    setState(() {
      _activeInvestments = active;
      _completedInvestments = completed;
    });
    
    // Update claim timers
    _updateClaimTimers();
    
    print('📊 Categorized: ${_activeInvestments.length} active, ${_completedInvestments.length} completed');
  }

  bool _isInvestmentActive(Map<String, dynamic> investment, DateTime currentDate) {
    final purchaseDateStr = investment['purchase_date']?.toString();
    if (purchaseDateStr == null || purchaseDateStr.isEmpty) {
      return true; // Default to active if no purchase date
    }
    
    try {
      final purchaseDate = DateTime.parse(purchaseDateStr);
      final type = investment['type'] ?? 'vip';
      
      if (type == 'vip') {
        // VIP products: Check validity days
        final validityDays = _parseInt(investment['validityDays'] ?? investment['validity_days'] ?? 0);
        if (validityDays <= 0) return true; // No expiration if no validity days
        
        final expiryDate = purchaseDate.add(Duration(days: validityDays));
        return currentDate.isBefore(expiryDate);
      } else {
        // Main projects: Check cycle days
        final cycleDays = _parseInt(investment['cycle_days'] ?? 0);
        if (cycleDays <= 0) return true; // No expiration if no cycle days
        
        final expiryDate = purchaseDate.add(Duration(days: cycleDays));
        return currentDate.isBefore(expiryDate);
      }
    } catch (e) {
      print("Error checking investment activity: $e");
      return true; // Default to active on error
    }
  }

  bool _canClaimIncome(Map<String, dynamic> investment) {
    // First check if investment is still active
    if (!_isInvestmentActive(investment, DateTime.now())) {
      return false;
    }
    
    final lastClaimTime = investment['last_claim_time']?.toString();
    if (lastClaimTime == null || lastClaimTime.isEmpty) return true;
    
    try {
      final lastClaim = DateTime.parse(lastClaimTime);
      final now = DateTime.now();
      final hoursSinceLastClaim = now.difference(lastClaim).inHours;
      return hoursSinceLastClaim >= 24;
    } catch (e) {
      return true;
    }
  }

  String _formatCountdown(Duration duration) {
    if (duration.inSeconds <= 0) return "Ready to claim!";
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Widget _buildClaimButton(Map<String, dynamic> investment) {
    final investmentId = investment['id'];
    final type = investment['type'];
    final isActive = _isInvestmentActive(investment, DateTime.now());
    final canClaim = _canClaimIncome(investment);
    final timer = _claimTimers[investmentId];
    final isVip = type == 'vip';
    
    // If investment is not active, show completed state
    if (!isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'COMPLETED',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '-- Br',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }
    
    // Calculate claim amount
    double claimAmount = 0;
    if (isVip) {
      claimAmount = _parseDouble(investment['dailyEarnings'] ?? investment['daily_earnings'] ?? 0);
    } else {
      claimAmount = _parseDouble(investment['daily_income'] ?? 0);
      final units = _parseInt(investment['units'] ?? 1);
      claimAmount = claimAmount * units;
    }
    
    if (canClaim) {
      // Claim button - enabled
      return ElevatedButton(
        onPressed: () => _claimSingleIncome(investment),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          elevation: 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CLAIM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${claimAmount.toStringAsFixed(0)} Br',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else if (timer != null) {
      // Countdown timer - disabled with timer
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatCountdown(timer),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${claimAmount.toStringAsFixed(0)} Br',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else {
      // Claimed button - disabled
      final isClaimedToday = _todaysClaims.containsKey(investmentId);
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isClaimedToday ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isClaimedToday ? Colors.green : Colors.grey,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isClaimedToday ? 'CLAIMED TODAY' : 'CLAIMED',
              style: TextStyle(
                color: isClaimedToday ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${claimAmount.toStringAsFixed(0)} Br',
              style: TextStyle(
                color: isClaimedToday ? Colors.green : Colors.grey,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInvestmentItem(Map<String, dynamic> investment) {
    final type = investment['type'] ?? 'vip';
    final isVip = type == 'vip';
    
    // Check if investment is active based on date
    final isActive = _isInvestmentActive(investment, DateTime.now());
    
    // Get data
    final name = investment['title'] ?? 'Investment';
    final price = _parseDouble(investment['price']);
    final purchaseDate = investment['purchase_date']?.toString() ?? '';
    final lastClaimTime = investment['last_claim_time']?.toString();
    
    // Type-specific fields
    final dailyAmount = isVip 
      ? _parseDouble(investment['dailyEarnings'] ?? 0)
      : _parseDouble(investment['daily_income'] ?? 0);
    
    final days = isVip
      ? _parseInt(investment['validityDays'] ?? 0)
      : _parseInt(investment['cycle_days'] ?? 0);
    
    final totalIncome = isVip
      ? _parseDouble(investment['totalIncome'] ?? 0)
      : _parseDouble(investment['total_income'] ?? 0);
    
    final units = isVip ? 1 : _parseInt(investment['units'] ?? 1);
    final availableUnits = isVip ? 0 : _parseInt(investment['available_units'] ?? 0);
    final image = investment['image']?.toString() ?? '';
    
    // Calculate expiry date
    DateTime? expiryDate;
    try {
      final purchaseDateTime = DateTime.parse(purchaseDate);
      expiryDate = purchaseDateTime.add(Duration(days: days));
    } catch (e) {
      expiryDate = null;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isVip 
                ? const Color(0xFF8B5CF6).withOpacity(0.1)
                : const Color(0xFFFF8C00).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVip ? const Color(0xFF8B5CF6) : const Color(0xFFFF8C00),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isVip ? 'VIP PRODUCT' : 'MAIN PROJECT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF22C55E).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? const Color(0xFF22C55E) : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'COMPLETED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? const Color(0xFF22C55E) : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildInvestmentImage(image, type),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              children: [
                                const TextSpan(text: 'Invested: '),
                                TextSpan(
                                  text: '${price.toStringAsFixed(0)} Br',
                                  style: const TextStyle(
                                    color: Color(0xFFFF8C00),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isVip && availableUnits > 0)
                            Text(
                              'Available: $availableUnits units',
                              style: TextStyle(
                                fontSize: 12,
                                color: availableUnits > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          if (!isVip)
                            Text(
                              'Your Units: $units',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Stats container
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn((dailyAmount * units).toStringAsFixed(0), 'Daily', false),
                      _buildStatColumn(days.toString(), 'Days', false),
                      _buildStatColumn(totalIncome.toStringAsFixed(0), 'Total', true),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Purchase date, expiry date and claim button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchased: ${_formatDate(purchaseDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (expiryDate != null)
                            Text(
                              'Expires: ${_formatDate(expiryDate.toIso8601String())}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive ? Colors.orange : Colors.grey,
                              ),
                            ),
                          if (lastClaimTime != null && lastClaimTime.isNotEmpty)
                            Text(
                              'Last claim: ${_formatDate(lastClaimTime)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          // Show next claim time if applicable
                          if (isActive && lastClaimTime != null && lastClaimTime.isNotEmpty)
                            _buildNextClaimInfo(investment),
                        ],
                      ),
                    ),
                    
                    // CLAIM BUTTON HERE
                    _buildClaimButton(investment),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextClaimInfo(Map<String, dynamic> investment) {
    final lastClaimTime = investment['last_claim_time']?.toString();
    if (lastClaimTime == null || lastClaimTime.isEmpty) {
      return Container();
    }
    
    try {
      final lastClaim = DateTime.parse(lastClaimTime);
      final nextClaimTime = lastClaim.add(const Duration(hours: 24));
      final now = DateTime.now();
      final timeRemaining = nextClaimTime.difference(now);
      
      if (timeRemaining.inSeconds <= 0) {
        return Container();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'Next claim: ${_formatDateTime(nextClaimTime)}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.orange,
            ),
          ),
        ],
      );
    } catch (e) {
      return Container();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildInvestmentImage(String imagePath, String type) {
    // Remove double "assets/" prefix if present
    if (imagePath.startsWith('assets/assets/')) {
      imagePath = imagePath.replaceFirst('assets/assets/', 'assets/');
    }
    
    Widget placeholder = Container(
      decoration: BoxDecoration(
        color: type == 'main_project' ? const Color(0xFFFF8C00).withOpacity(0.2) : const Color(0xFF8B5CF6).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          type == 'main_project' ? Icons.ev_station : Icons.star,
          size: 30,
          color: type == 'main_project' ? const Color(0xFFFF8C00) : const Color(0xFF8B5CF6),
        ),
      ),
    );

    if (imagePath.isEmpty) return placeholder;

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else {
      return Image.asset(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }
  }

  Widget _buildStatColumn(String value, String label, bool highlight) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: highlight
        ? BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          )
        : null,
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: highlight ? const Color(0xFF22C55E) : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: highlight ? const Color(0xFF22C55E) : Colors.grey,
          ),
        ),
      ],
    ),
  );

  Future<void> _claimSingleIncome(Map<String, dynamic> investment) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _isApiLoading = true;
    });
    
    try {
      final investmentId = investment['id'];
      final type = investment['type'];
      final isVip = type == 'vip';
      
      // Calculate claim amount
      double claimAmount = 0;
      if (isVip) {
        claimAmount = _parseDouble(investment['dailyEarnings'] ?? investment['daily_earnings'] ?? 0);
      } else {
        claimAmount = _parseDouble(investment['daily_income'] ?? 0);
        final units = _parseInt(investment['units'] ?? 1);
        claimAmount = claimAmount * units;
      }
      
      final result = await ApiService.claimInvestmentIncome(widget.token, investmentId, type);
      
      if (result['success'] == true) {
        // Update investment with new claim time
        final now = DateTime.now();
        investment['last_claim_time'] = now.toIso8601String();
        
        // Update balance
        final claimedAmount = _parseDouble(result['amount']);
        setState(() {
          _balance += claimedAmount;
          // Add to today's total income
          _todaysTotalIncome += claimedAmount;
          // Track this investment as claimed today
          _todaysClaims[investmentId] = claimedAmount;
        });
        
        // Update claim timers
        _updateClaimTimers();
        
        _showMessageText("Successfully claimed ${claimedAmount.toStringAsFixed(2)} Br today!");
        
        // Refresh the list
        _categorizeInvestments();
      } else {
        _showMessageText(result['error'] ?? result['message'] ?? "Failed to claim income", isError: true);
      }
      
    } catch (e) {
      _showMessageText("Failed to claim income: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isApiLoading = false;
        });
      }
    }
  }

  Future<void> _claimAllIncome() async {
    if (_isProcessing || _activeInvestments.isEmpty) return;
    
    setState(() {
      _isProcessing = true;
      _isApiLoading = true;
    });
    
    try {
      double totalClaimed = 0;
      int successfulClaims = 0;
      
      // Find investments that can be claimed
      final investmentsToClaim = _activeInvestments.where((inv) => _canClaimIncome(inv)).toList();
      
      if (investmentsToClaim.isEmpty) {
        _showMessageText("No income available to claim today", isError: true);
        return;
      }
      
      for (var investment in investmentsToClaim) {
        try {
          final investmentId = investment['id'];
          final type = investment['type'];
          final result = await ApiService.claimInvestmentIncome(widget.token, investmentId, type);
          
          if (result['success'] == true) {
            final now = DateTime.now();
            investment['last_claim_time'] = now.toIso8601String();
            final claimedAmount = _parseDouble(result['amount']);
            totalClaimed += claimedAmount;
            successfulClaims++;
            
            // Track this investment as claimed today
            _todaysClaims[investmentId] = claimedAmount;
          }
        } catch (e) {
          print("Error claiming investment ${investment['id']}: $e");
        }
      }
      
      // Update balance
      setState(() {
        _balance += totalClaimed;
        _todaysTotalIncome += totalClaimed;
      });
      
      // Update claim timers
      _updateClaimTimers();
      
      if (successfulClaims > 0) {
        _showMessageText("Successfully claimed ${totalClaimed.toStringAsFixed(2)} Br today from $successfulClaims investments!");
        _categorizeInvestments();
      } else {
        _showMessageText("Failed to claim income", isError: true);
      }
      
    } catch (e) {
      _showMessageText("Failed to claim all income: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isApiLoading = false;
        });
      }
    }
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    if (v is num) return v.toDouble();
    return 0.0;
  }

  int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is num) return v.toInt();
    return 0;
  }

  void _showMessageText(String message, {bool isError = false}) {
    if (!mounted) return;
    
    setState(() {
      _message = message;
      _messageColor = isError ? Colors.red : const Color(0xFF22C55E);
      _showMessage = true;
    });
    
    // Hide message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> get _currentInvestments {
    switch (_selectedTab) {
      case 0: return _userInvestments;
      case 1: return _activeInvestments;
      case 2: return _completedInvestments;
      default: return _userInvestments;
    }
  }

  double get _totalDailyEarnings {
    return _activeInvestments.fold(0.0, (sum, inv) {
      final type = inv['type'];
      double dailyAmount = 0;
      
      if (type == 'vip') {
        dailyAmount = _parseDouble(inv['dailyEarnings'] ?? inv['daily_earnings'] ?? 0);
      } else if (type == 'main_project') {
        dailyAmount = _parseDouble(inv['daily_income'] ?? 0);
        final units = _parseInt(inv['units'] ?? 1);
        dailyAmount = dailyAmount * units;
      }
      
      return sum + dailyAmount;
    });
  }

  double _calculateTotalInvested() {
    return _userInvestments.fold(0.0, (sum, inv) {
      final price = _parseDouble(inv['price']);
      final units = inv['type'] == 'main_project' ? _parseInt(inv['units'] ?? 1) : 1;
      return sum + (price * units);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitCircle(
                color: const Color(0xFFFF8C00),
                size: 50.0,
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading Investments...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentInvestments = _currentInvestments;
    final totalInvested = _calculateTotalInvested();
    final canClaimAny = _activeInvestments.any((inv) => _canClaimIncome(inv));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFF7C3AED),
                        Color(0xFF6D28D9),
                      ],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'My Investments',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                ),

                // Message Banner
                if (_showMessage)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: _messageColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          _messageColor == Colors.red ? Icons.error : Icons.check_circle,
                          color: _messageColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _message,
                            style: TextStyle(
                              color: _messageColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: _messageColor, size: 18),
                          onPressed: () {
                            setState(() {
                              _showMessage = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                // Today's Income Card
                Transform.translate(
                  offset:  Offset(0, _showMessage ? -8 : -16),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF8C00),
                          Color(0xFFFFA726),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Income",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _todaysTotalIncome.toStringAsFixed(0),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4, left: 4),
                                  child: Text(
                                    'Br',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Claimed today • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Balance Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset:  Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Available Balance',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _balanceVisible = !_balanceVisible;
                                        });
                                      },
                                      child: Icon(
                                        _balanceVisible ? Icons.visibility : Icons.visibility_off,
                                        color: Colors.grey[600],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _balanceVisible ? _balance.toStringAsFixed(0) : '*****',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 4, left: 4),
                                      child: Text(
                                        'Br',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFFF8C00),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Claim All Button
                      if (_activeInvestments.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: ElevatedButton(
                            onPressed: canClaimAny && !_isProcessing ? _claimAllIncome : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canClaimAny ? const Color(0xFF22C55E) : Colors.grey,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.bolt, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'CLAIM ALL (${_totalDailyEarnings.toStringAsFixed(0)} Br)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Quick Stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statItem(Icons.trending_up, 'Daily', '${_totalDailyEarnings.toStringAsFixed(0)} Br'),
                      _statItem(Icons.assignment_turned_in, 'Active', '${_activeInvestments.length}'),
                      _statItem(Icons.check_circle, 'Completed', '${_completedInvestments.length}'),
                      _statItem(Icons.attach_money, 'Invested', '${totalInvested.toStringAsFixed(0)} Br'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? const Color(0xFF8B5CF6) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 0 ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'All (${_userInvestments.length})',
                                style: TextStyle(
                                  color: _selectedTab == 0 ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? const Color(0xFF8B5CF6) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 1 ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Active (${_activeInvestments.length})',
                                style: TextStyle(
                                  color: _selectedTab == 1 ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 2 ? const Color(0xFF8B5CF6) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 2 ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Completed (${_completedInvestments.length})',
                                style: TextStyle(
                                  color: _selectedTab == 2 ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Investments List
                if (currentInvestments.isEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _selectedTab == 1 ? Icons.shopping_bag_outlined : 
                          _selectedTab == 2 ? Icons.check_circle_outlined : Icons.inventory_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedTab == 0 ? 'No investments yet' :
                          _selectedTab == 1 ? 'No active investments' : 'No completed investments',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                          ),
                          child: const Text('Browse Investments'),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: currentInvestments.map(_buildInvestmentItem).toList(),
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
          
          // API Loading Overlay
          if (_isApiLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitCircle(
                      color: const Color(0xFFFF8C00),
                      size: 50.0,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Processing...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) => Column(
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFE8D4F8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: const Color(0xFF8B5CF6),
          size: 26,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF333333),
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}