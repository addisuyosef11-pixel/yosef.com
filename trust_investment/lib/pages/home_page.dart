import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'api_service.dart';
import 'balance_page.dart';
import 'gift_redeem_page.dart';
import 'support_chat_page.dart';
import 'income_page.dart';
import 'news_page.dart';
import 'team_page.dart';
import 'profile_page.dart';
import 'lucky_wheel_page.dart';
import 'recharge_page.dart';

class HomePage extends StatefulWidget {
  final String token;
  const HomePage({Key? key, required this.token}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> _profileData = {};
  List<Map<String, dynamic>> _vipProducts = [];
  List<Map<String, dynamic>> _chatHistory = [];
  List<Map<String, dynamic>> _mainProjects = [];
  double _balance = 0.0;
  
  bool isLoading = true;
  bool _isMainLoading = false;
  bool _isApiLoading = false;
  bool _balanceVisible = true;
  
  late PageController _vipCtrl;
  final PageController _mainProjectPageController = PageController();
  int _vipIndex = 0;
  int _currentMainProjectPage = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;
 
  @override
  void initState() {
    super.initState();
    _vipCtrl = PageController(viewportFraction: 0.88);
    _loadDataWithDelay();
    _startAutoScroll();
    loadChatHistory();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _vipCtrl.dispose();
    _mainProjectPageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isUserInteracting && _vipProducts.isNotEmpty && _vipCtrl.hasClients) {
        if (_vipIndex < _vipProducts.length - 1) {
          _vipCtrl.nextPage(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        } else {
          _vipCtrl.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _handleUserInteraction() {
    if (!_isUserInteracting) {
      setState(() => _isUserInteracting = true);
    }
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _isUserInteracting = false);
        _startAutoScroll();
      }
    });
  }

  Future<void> _loadDataWithDelay() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    await _loadData();
  }

  Future<void> _loadDataWithApiLoading() async {
    setState(() => _isApiLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    await _loadData();
    setState(() => _isApiLoading = false);
  }

  Future<void> _loadData() async {
    try {
      print("🔍 Starting data load...");
      
      try {
        print("🔍 Fetching profile...");
        final profile = await ApiService.getProfile(widget.token);
        print("✅ Profile API Response: $profile");
        
        if (profile != null && profile.isNotEmpty) {
          setState(() {
            _profileData = profile;
            _balance = (profile['balance'] ?? 
                       profile['available_balance'] ?? 
                       profile['total_balance'] ?? 0).toDouble();
          });
          print("✅ Balance loaded: $_balance Br");
        } else {
          print("⚠️ Profile is null or empty");
          setState(() {
            _profileData = {};
            _balance = 0.0;
          });
        }
      } catch (e) {
        print("❌ Profile error: $e");
        _showToast("Failed to load profile", isError: true);
        setState(() {
          _profileData = {};
          _balance = 0.0;
        });
      }
      
      try {
        print("🔍 Fetching main projects...");
        await _loadMainProjects();
      } catch (e) {
        print("❌ Main projects error: $e");
        _showToast("Failed to load main projects", isError: true);
      }
      
      try {
        print("🔍 Fetching VIP products...");
        final vipList = await ApiService.getVipProducts(widget.token);
        print("✅ VIP Products loaded: ${vipList.length} items");
        
        setState(() {
          _vipProducts = vipList;
        });
      } catch (e) {
        print("❌ VIP products error: $e");
        _showToast("Failed to load products", isError: true);
        setState(() {
          _vipProducts = [];
        });
      }
      
      setState(() => isLoading = false);
      
      if (_vipProducts.isNotEmpty || _balance > 0) {
        print("✅ Data loaded successfully");
      } else {
        print("⚠️ No data loaded");
      }
      
    } catch (e) {
      print("❌ General error in _loadData: $e");
      setState(() {
        isLoading = false;
        _profileData = {};
        _vipProducts = [];
        _balance = 0.0;
      });
      _showToast("Failed to load data", isError: true);
    }
  }

  Future<void> _loadMainProjects() async {
    try {
      setState(() => _isMainLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      
      print("🔍 Fetching main projects...");
      final mainProjectsList = await ApiService.getMainProjects(widget.token);
      print("✅ Main Projects loaded: ${mainProjectsList.length} items");
      
      setState(() {
        _mainProjects = mainProjectsList;
      });
      
      setState(() => _isMainLoading = false);
    } catch (e) {
      print("❌ Main projects error: $e");
      _showToast("Failed to load main projects", isError: true);
      setState(() {
        _mainProjects = [];
        _isMainLoading = false;
      });
    }
  }

  Future<void> loadChatHistory() async {
    try {
      setState(() => _isApiLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      
      final chatHistory = await ApiService.fetchChatHistory(token: widget.token);
      print("✅ Chat History loaded: ${chatHistory.length} messages");
      
      setState(() {
        _chatHistory = chatHistory;
        _isApiLoading = false;
      });
    } catch (e) {
      print("❌ Chat history error: $e");
      setState(() {
        _chatHistory = [];
        _isApiLoading = false;
      });
    }
  }
  
  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF8A2BE2),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _openTelegram() async {
    setState(() => _isApiLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    
    const url = 'https://t.me/teslax_official';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showToast('Cannot open Telegram');
      }
    } catch (e) {
      _showToast('Error opening Telegram: $e', isError: true);
    } finally {
      setState(() => _isApiLoading = false);
    }
  }

  void _refreshData() {
    _showToast("Refreshing data...");
    _loadDataWithApiLoading();
  }

  void _navigateToGiftRedeem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GiftRedeemPage(token: widget.token),
      ),
    );
  }

  void _navigateToBalancePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BalancePage(token: widget.token),
      ),
    );
  }

  void _handleChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportChatPage(
          token: widget.token,
          userName: _profileData['username']?.toString() ?? 'User',
        ),
      ),
    );
  }

  Future<void> _showInvestDialog(int vipId, String name, int price) async {
    bool confirmInvest = false;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Investment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Are you sure you want to invest in $name?",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Investment:", style: TextStyle(color: Colors.grey)),
                      Text("$price Br", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Your Balance:", style: TextStyle(color: Colors.grey)),
                      Text("${_balance.toStringAsFixed(2)} Br", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "You will earn daily income for the investment cycle.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              confirmInvest = true;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A2BE2),
            ),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmInvest) {
      await _handleInvest(vipId, name, price);
    }
  }

  Future<void> _handleInvest(int vipId, String name, int price) async {
    setState(() => _isApiLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    
    _showToast("Processing investment...");
    try {
      print("🔍 Investing in VIP ID: $vipId, Name: $name, Price: $price");
      final result = await ApiService.buyVipProduct(widget.token, vipId);
      print("✅ Investment result: $result");
      
      if (result == "success") {
        _showToast("Successfully invested in $name!");
        await _loadData();
      } else if (result == "insufficient") {
        _showToast("Insufficient balance. Need $price Br", isError: true);
      } else {
        _showToast("Investment failed: $result", isError: true);
      }
    } catch (e) {
      print("❌ Investment error: $e");
      _showToast("Network error: $e", isError: true);
    } finally {
      setState(() => _isApiLoading = false);
    }
  }

  Future<void> _showMainProjectInvestDialog(int projectId, String projectName, double price, int availableUnits) async {
    bool confirmInvest = false;
    int selectedUnits = 1;
    
    final maxAffordableUnits = _balance ~/ price;
    final maxUnits = maxAffordableUnits.clamp(1, availableUnits);
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final totalCost = price * selectedUnits;
          
          return AlertDialog(
            title: const Text("Invest in Project"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  projectName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Select Units to Invest",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: selectedUnits > 1 ? () {
                              setState(() => selectedUnits--);
                            } : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              selectedUnits.toString(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: selectedUnits < maxUnits ? () {
                              setState(() => selectedUnits++);
                            } : null,
                          ),
                        ],
                      ),
                      Text(
                        "Available: $availableUnits units",
                        style: TextStyle(
                          color: availableUnits > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildInvestmentRow("Unit Price:", "${price.toStringAsFixed(0)} Br"),
                      const SizedBox(height: 8),
                      _buildInvestmentRow("Units:", selectedUnits.toString()),
                      const SizedBox(height: 8),
                      _buildInvestmentRow("Total Cost:", "${totalCost.toStringAsFixed(0)} Br", isTotal: true),
                      const SizedBox(height: 8),
                      _buildInvestmentRow("Your Balance:", "${_balance.toStringAsFixed(0)} Br"),
                      const SizedBox(height: 8),
                      _buildInvestmentRow(
                        "Remaining:", 
                        "${(_balance - totalCost).toStringAsFixed(0)} Br",
                        color: (_balance - totalCost) < 0 ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                if (selectedUnits > maxAffordableUnits)
                  Text(
                    "⚠️ You need ${(totalCost - _balance).toStringAsFixed(0)} more Br",
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: (_balance >= totalCost && selectedUnits <= availableUnits) ? () {
                  confirmInvest = true;
                  Navigator.pop(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                ),
                child: const Text("Confirm Invest"),
              ),
            ],
          );
        },
      ),
    );
    
    if (confirmInvest) {
      await _getMainProject(projectId, price, selectedUnits, projectName);
    }
  }

  Widget _buildInvestmentRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: color ?? const Color(0xFF333333),
            fontSize: isTotal ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Future<void> _getMainProject(int projectId, double unitPrice, int units, String projectName) async {
    try {
      setState(() => _isApiLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      
      _showToast("Processing investment...");
      
      print("💰 Investing in Main Project:");
      print("  - Project ID: $projectId");
      print("  - Unit Price: $unitPrice Br");
      print("  - Units: $units");
      print("  - Total: ${unitPrice * units} Br");
      print("  - Balance: $_balance Br");
      
      final result = await ApiService.investInMainProject(
        token: widget.token,
        projectId: projectId,
        units: units,
      );
      
      print("✅ Investment API Response: $result");
      
      if (result['success'] == true) {
        _showToast("✅ Successfully invested in $projectName!");
        
        final totalCost = unitPrice * units;
        setState(() {
          _balance -= totalCost;
        });
        
        await _loadData();
        
      } else {
        _showToast("❌ ${result['message'] ?? 'Investment failed'}", isError: true);
      }
      
    } catch (e) {
      print("❌ Investment error: $e");
      _showToast("Network error: ${e.toString()}", isError: true);
    } finally {
      setState(() => _isApiLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
                'Loading TeslaX...',
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _heroBanner(),
                _balanceCard(),
                _quickActions(),
                _cashChallenge(),
                _welfareProducts(),
                _mainProject(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _floatingChat(),
          
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

  Widget _heroBanner() {
    return Container(
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
      child: Stack(
        children: [
          // Car background image
          Positioned.fill(
            child: ClipRRect(
              child: Image.asset(
                'assets/images/car.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(),
              ),
            ),
          ),
          
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.8),
                    const Color(0xFF7C3AED).withOpacity(0.8),
                    const Color(0xFF6D28D9).withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Invest in TeslaX solar cells to earn daily income, achieve sustainable energy development, and alleviate the difficulties faced by Africans in using electricity.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 90,
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.electric_car,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  Positioned(
                    top: -8,
                    right: -4,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBBF24),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '☀️',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceCard() => Transform.translate(
    offset: const Offset(0, -16),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info with person icon
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profileData['username']?.toString() ?? 'User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      'ID: ${_profileData['id']?.toString() ?? '---'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Balance section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _navigateToBalancePage,
                      child: Row(
                        children: [
                          Text(
                            'Available Balance',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Eye icon for show/hide balance
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
                            fontSize: 28, // Reduced font size
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4, left: 4),
                          child: Text(
                            'Br',
                            style: TextStyle(
                              fontSize: 18, // Reduced font size
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
              Column(
                children: [
                  OutlinedButton(
                    onPressed: _navigateToBalancePage,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFFF8C00),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Withdraw',
                      style: TextStyle(color: Color(0xFFFF8C00)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _navigateToBalancePage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Deposit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _quickActions() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _actionItem(Icons.monetization_on, 'Free Cash', const Color(0xFFFF8C00), onTap: _navigateToGiftRedeem),
        _actionItem(Icons.send, 'Telegram', const Color(0xFF00BCD4), onTap: _openTelegram),
        _actionItem(
          Icons.headphones, 
          'Message', 
          const Color(0xFF8B5CF6), 
          badge: _chatHistory.isEmpty ? null : '${_chatHistory.length}', 
          onTap: _handleChat,
        ),
        _actionItem(Icons.assignment, 'Task', const Color(0xFFE91E8C), onTap: () {
          setState(() => _isApiLoading = true);
          Future.delayed(const Duration(seconds: 2)).then((_) {
            setState(() => _isApiLoading = false);
            _showToast('Loading tasks...');
          });
        }),
      ],
    ),
  );

  Widget _actionItem(IconData icon, String label, Color color, {String? badge, VoidCallback? onTap}) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
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
                color: Colors.white,
                size: 26,
              ),
            ),
            if (badge != null && badge != '0')
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _cashChallenge() => GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LuckyWheelPage(
            token: widget.token,
            currentBalance: _balance,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9333EA),
            Color(0xFF7C3AED),
            Color(0xFFEC4899),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            bottom: 0,
            child: Text(
              '💵',
              style: TextStyle(fontSize: 40),
            ),
          ),
          Positioned(
            right: -20,
            bottom: -20,
            child: _spinWheel(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cash Challenge',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Free win cash, products',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LuckyWheelPage(
                          token: widget.token,
                          currentBalance: _balance,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  child: const Text(
                    'Join now.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _spinWheel() => SizedBox(
    width: 100,
    height: 100,
    child: CustomPaint(painter: _WheelPainter()),
  );

  Widget _welfareProducts() {
    if (_vipProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.inventory_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No investment products available',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'New',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Welfare Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: GestureDetector(
            onPanStart: (_) => _handleUserInteraction(),
            onTapDown: (_) => _handleUserInteraction(),
            child: PageView.builder(
              controller: _vipCtrl,
              onPageChanged: (index) {
                final page = index % _vipProducts.length;
                setState(() {
                  _vipIndex = page;
                });
                _handleUserInteraction();
              },
              itemCount: _vipProducts.length,
              itemBuilder: (context, index) {
                final product = _vipProducts[index];
                return _vipCard(product, index);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_vipProducts.length, (i) {
            return GestureDetector(
              onTap: () {
                _handleUserInteraction();
                _vipCtrl.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _vipIndex
                      ? const Color(0xFF8B5CF6)
                      : Colors.grey[300]!,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _vipCard(Map<String, dynamic> v, int index) {
    final id = v['id'] ?? 0;
    final name = v['title'] ?? 'TeslaX VIP';
    final price = v['price'] ?? 0;
    final dailyEarnings = v['dailyEarnings'] ?? v['daily_earnings'] ?? 0;
    final validityDays = v['validityDays'] ?? v['validity_days'] ?? 0;
    final totalIncome = v['totalIncome'] ?? v['total_income'] ?? 0;
    
    final priceNum = price is num ? price : double.tryParse(price.toString()) ?? 0;
    final dailyNum = dailyEarnings is num ? dailyEarnings : double.tryParse(dailyEarnings.toString()) ?? 0;
    final daysNum = validityDays is num ? validityDays : int.tryParse(validityDays.toString()) ?? 0;
    final totalNum = totalIncome is num ? totalIncome : double.tryParse(totalIncome.toString()) ?? (dailyNum * daysNum);
    
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF22C55E), width: 4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'T',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'TESLAX',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  name.toString(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(daysNum.toString(), 'Cycle(Days)', false),
                      _stat(dailyNum.toStringAsFixed(0), 'Daily income(Br)', false),
                      _stat(totalNum.toStringAsFixed(0), 'Total income(Br)', true),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: priceNum > 0 ? () => _showInvestDialog(id, name.toString(), priceNum.toInt()) : null,
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00BCD4),
                            Color(0xFF3B82F6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          priceNum > 0 ? '$priceNum Br  Invest' : 'FREE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
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

  Widget _stat(String val, String label, bool hl) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: hl
        ? BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          )
        : null,
    child: Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: hl ? const Color(0xFF22C55E) : Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: hl ? const Color(0xFF22C55E) : Colors.grey,
          ),
        ),
      ],
    )
  );

  Widget _mainProject() {
    if (_isMainLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitCircle(
              color: const Color(0xFF8B5CF6),
              size: 40.0,
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading Main Projects...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_mainProjects.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
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
            const Text(
              'Main Project',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Icon(Icons.inventory_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No projects available',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Main Project',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Display all main projects in a list
        Column(
          children: _mainProjects.asMap().entries.map((entry) {
            final index = entry.key;
            final project = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildMainProjectCard(project, index),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMainProjectCard(Map<String, dynamic> project, int index) {
    final int id = (project['id'] is int) ? project['id'] : int.tryParse(project['id']?.toString() ?? '0') ?? 0;
    final String title = project['title']?.toString() ?? 'Main Project';
    
    final double price = (project['price'] is num) ? (project['price'] as num).toDouble() : 
                        double.tryParse(project['price']?.toString() ?? '0') ?? 0.0;
    
    final double dailyIncome = (project['daily_income'] is num) ? (project['daily_income'] as num).toDouble() : 
                              double.tryParse(project['daily_income']?.toString() ?? '0') ?? 0.0;
    
    final int cycleDays = (project['cycle_days'] is int) ? project['cycle_days'] : 
                         int.tryParse(project['cycle_days']?.toString() ?? '30') ?? 30;
    
    final int availableUnits = (project['available_units'] is int) ? project['available_units'] : 
                             int.tryParse(project['available_units']?.toString() ?? '0') ?? 0;
    
    final double totalIncome = dailyIncome * cycleDays;

    // Use project image if available, otherwise use car images
    final String? projectImage = project['image']?.toString();
    
    // List of car images as fallback
    final List<String> carImages = [
      'images/car_1.jpg',
      'images/car_2.jpg',
      'images/car_3.jpg',
      'images/car_4.jpg',
      'images/car_5.jpg',
      'images/car_6.jpg',
      'images/car_7.jpg',
      'images/car_8.jpg',
    ];
    
    final String imagePath = projectImage != null && projectImage.isNotEmpty
        ? projectImage
        : carImages[index % carImages.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              // Image in rounded rectangle
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    imagePath,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.ev_station,
                            size: 40,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Project details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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
                          const TextSpan(text: 'Cycle(Days): '),
                          TextSpan(
                            text: '$cycleDays',
                            style: const TextStyle(
                              color: Color(0xFFFF8C00),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Available: $availableUnits/1',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
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
                _buildStatColumn(dailyIncome.toStringAsFixed(0), 'Daily Income(Br)', false),
                _buildStatColumn(totalIncome.toStringAsFixed(0), 'Total Income(Br)', false),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Price and Invest Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price section
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    const TextSpan(text: 'Price(Br) '),
                    TextSpan(
                      text: price.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Color(0xFFFF8C00),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Invest button
              ElevatedButton(
                onPressed: availableUnits > 0
                    ? () => _showMainProjectInvestDialog(id, title, price, availableUnits)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  elevation: 2,
                ),
                child: Text(
                  availableUnits > 0 ? 'INVEST' : 'SOLD OUT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method for stats columns
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
            fontSize: 18,
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

  Widget _floatingChat() => Positioned(
    bottom: 20,
    right: 16,
    child: FloatingActionButton(
      backgroundColor: const Color(0xFF22C55E),
      onPressed: _handleChat,
      child: const Icon(
        Icons.chat_bubble,
        color: Colors.white,
      ),
    ),
  );
}

// Simplified Wheel Painter
class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];
    
    // Draw colored segments
    for (int i = 0; i < 6; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        i * (2 * 3.14159 / 6),
        2 * 3.14159 / 6,
        true,
        paint,
      );
    }
    
    // Draw center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(c, r * 0.4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}