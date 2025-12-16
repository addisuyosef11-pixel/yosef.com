import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'balance_page.dart';
import 'gift_redeem_page.dart';
import 'support_chat_page.dart'; // Add this import

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
  int _selectedIndex = 0;
  
  late PageController _pageController;
  final PageController _mainProjectPageController = PageController();
  int _currentPage = 0;
  int _currentMainProjectPage = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;
 
  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _loadData();
    _startAutoScroll();
    loadChatHistory();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _mainProjectPageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isUserInteracting && _vipProducts.isNotEmpty && _pageController.hasClients) {
        if (_currentPage < _vipProducts.length - 1) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.animateToPage(
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

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      
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
      final chatHistory = await ApiService.fetchChatHistory(token: widget.token);
      print("✅ Chat History loaded: ${chatHistory.length} messages");
      
      setState(() {
        _chatHistory = chatHistory;
      });
    } catch (e) {
      print("❌ Chat history error: $e");
      setState(() {
        _chatHistory = [];
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
    const url = 'https://t.me/teslax_official';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showToast('Cannot open Telegram');
      }
    } catch (e) {
      _showToast('Error opening Telegram: $e', isError: true);
    }
  }

  void _refreshData() {
    _showToast("Refreshing data...");
    _loadData();
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

  // NEW: Handle chat navigation
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8A2BE2)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildBalanceCard(),
                  _buildQuickActions(),
                  _buildCashChallengeBanner(),
                  _buildWelfareProducts(),
                  _buildMainProject(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            _buildFloatingChatButton(), // Add floating chat button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // NEW: Floating Chat Button with WhatsApp style
  Widget _buildFloatingChatButton() {
    return Positioned(
      right: 20,
      bottom: 120,
      child: GestureDetector(
        onTap: _handleChat,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF25D366), const Color(0xFF128C7E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Animated ring
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
              
              // Chat icon
              const Center(
                child: Icon(
                  Icons.chat_bubble,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              
              // Support badge with animation
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.headset_mic,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ),
              
              // Unread message indicator
              if (_chatHistory.isNotEmpty && 
                  _chatHistory.any((msg) => 
                    msg['sender'] != 'user' && 
                    (msg['read'] != true) &&
                    DateTime.now().difference(DateTime.parse(msg['timestamp'])).inHours < 24))
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Modified Quick Actions to use new chat handler
  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.monetization_on, 
        'label': 'Free Cash', 
        'color': const Color(0xFFFFB800), 
        'bg': const Color(0xFFFFF3CD), 
        'onTap': _navigateToGiftRedeem
      },
      {
        'icon': Icons.send, 
        'label': 'Telegram', 
        'color': const Color(0xFF8A2BE2), 
        'bg': const Color(0xFFE8D4F8), 
        'onTap': _openTelegram
      },
      {
        'icon': Icons.headphones, 
        'label': 'Support', 
        'color': const Color(0xFF25D366), // WhatsApp green
        'bg': const Color(0xFFDCF8C6), // WhatsApp light green
        'badge': _chatHistory.isEmpty ? '0' : '${_chatHistory.length}', 
        'onTap': _handleChat // Updated to use new chat handler
      },
      {
        'icon': Icons.assignment, 
        'label': 'Task', 
        'color': const Color(0xFF8A2BE2), 
        'bg': const Color(0xFFE8D4F8), 
        'onTap': () => _showToast('Loading tasks...')
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((action) {
          return GestureDetector(
            onTap: action['onTap'] as VoidCallback,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: action['bg'] as Color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 28,
                      ),
                    ),
                    if (action['badge'] != null && action['badge'] != '0')
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Text(
                            action['badge'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    final username = _profileData['username']?.toString() ?? 'User';
    final userId = _profileData['id']?.toString() ?? '---';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8A2BE2), Color(0xFF9B4DCA)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1620288627223-53302f4e8c74?w=100',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.electric_car, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ID: $userId',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshData,
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => _showToast("Notifications"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Invest in TeslaX solar cells to earn daily income, achieve sustainable energy development, and alleviate the difficulties faced by Africans in using electricity.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Available Balance',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[400]),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _balance.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        'Br',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
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
              _buildActionButton('Withdraw', const Color(0xFFFF6B35), false, () {
                _navigateToBalancePage();
              }),
              const SizedBox(height: 8),
              _buildActionButton('Deposit', const Color(0xFFFF6B35), true, () {
                _navigateToBalancePage();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, bool isFilled, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isFilled ? color : Colors.transparent,
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isFilled ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCashChallengeBanner() {
    return GestureDetector(
      onTap: () => _showToast("Joining Cash Challenge..."),
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cash Challenge',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Free win cash, products',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Join now.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 0,
              child: Image.network(
                'https://images.unsplash.com/photo-1522542550221-31fd8575f5a5?w=120',
                height: 100,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVipProductCard(Map<String, dynamic> product) {
    final vipLevels = [
      {
        'name': 'Basic',
        'color': [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
        'image': 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=400',
      },
      {
        'name': 'Premium',
        'color': [const Color(0xFF2196F3), const Color(0xFF0D47A1)],
        'image': 'https://images.unsplash.com/photo-1620288627223-53302f4e8c74?w=400',
      },
      {
        'name': 'VIP',
        'color': [const Color(0xFF9C27B0), const Color(0xFF6A1B9A)],
        'image': 'https://images.unsplash.com/photo-1593941707882-a5bba14938c7?w=400',
      },
    ];

    final index = _vipProducts.indexOf(product);
    final level = vipLevels[index % vipLevels.length];
    final gradient = level['color'] as List<Color>;
    
    final id = product['id'] ?? 0;
    final name = product['title'] ?? level['name'] as String;
    final price = product['price'] ?? 0;
    final dailyEarnings = product['daily_earnings'] ?? 0;
    final validityDays = product['validity_days'] ?? 0;
    final totalIncome = product['total_income'] ?? 0;
    
    final priceNum = price is num ? price : double.tryParse(price.toString()) ?? 0;
    final dailyNum = dailyEarnings is num ? dailyEarnings : double.tryParse(dailyEarnings.toString()) ?? 0;
    final daysNum = validityDays is num ? validityDays : int.tryParse(validityDays.toString()) ?? 0;
    final totalNum = totalIncome is num ? totalIncome : double.tryParse(totalIncome.toString()) ?? (dailyNum * daysNum);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gradient[1],
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (index + 1).toString(),
                        style: TextStyle(
                          color: gradient[1],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatItem(daysNum.toString(), 'Days', 12),
                    _buildStatItem(dailyNum.toStringAsFixed(0), 'Daily', 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: gradient[1],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          Text(
                            totalNum.toStringAsFixed(0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: priceNum > 0 ? () => _showInvestDialog(id, name, priceNum.toInt()) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      priceNum > 0 ? '$priceNum Br  Invest' : 'FREE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, double fontSize) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelfareProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Welfare Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        if (_vipProducts.isEmpty)
          Container(
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
                Icon(Icons.inventory_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                const Text(
                  'No investment products available',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _refreshData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A2BE2),
                  ),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 240,
            child: GestureDetector(
              onPanStart: (_) => _handleUserInteraction(),
              onTapDown: (_) => _handleUserInteraction(),
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                onPageChanged: (index) {
                  final page = index % _vipProducts.length;
                  setState(() {
                    _currentPage = page;
                  });
                  _handleUserInteraction();
                },
                itemCount: _vipProducts.length,
                itemBuilder: (context, index) {
                  final product = _vipProducts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildVipProductCard(product),
                  );
                },
              ),
            ),
          ),
        
        const SizedBox(height: 12),
        
        if (_vipProducts.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_vipProducts.length, (index) {
              return GestureDetector(
                onTap: () {
                  _handleUserInteraction();
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: _currentPage == index ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: _currentPage == index
                        ? const Color(0xFF8A2BE2)
                        : Colors.grey[300]!,
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildMainProject() {
    if (_isMainLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_mainProjects.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Main Projects',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
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
                    'No main projects available',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refreshData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A2BE2),
                    ),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Main Projects',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        Column(
          children: _mainProjects.map((project) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildMainProjectCardVertical(project),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMainProjectCardVertical(Map<String, dynamic> project) {
    final int id = (project['id'] is int) ? project['id'] : int.tryParse(project['id']?.toString() ?? '0') ?? 0;
    final String title = project['title']?.toString() ?? 'Main Project';
    final String description = project['description']?.toString() ?? project['short_description']?.toString() ?? '';
    
    final double price = (project['price'] is num) ? (project['price'] as num).toDouble() : 
                        double.tryParse(project['price']?.toString() ?? '0') ?? 0.0;
    
    final double dailyIncome = (project['daily_income'] is num) ? (project['daily_income'] as num).toDouble() : 
                              double.tryParse(project['daily_income']?.toString() ?? '0') ?? 0.0;
    
    final int cycleDays = (project['cycle_days'] is int) ? project['cycle_days'] : 
                         int.tryParse(project['cycle_days']?.toString() ?? '30') ?? 30;
    
    double totalIncome = (project['total_income'] is num) ? (project['total_income'] as num).toDouble() : 
                        double.tryParse(project['total_income']?.toString() ?? '0') ?? 0.0;
    
    if (totalIncome == 0) {
      totalIncome = dailyIncome * cycleDays;
    }
    
    final int availableUnits = (project['available_units'] is int) ? project['available_units'] : 
                             int.tryParse(project['available_units']?.toString() ?? '0') ?? 0;
    
    final int totalUnits = (project['total_units'] is int) ? project['total_units'] : 
                          int.tryParse(project['total_units']?.toString() ?? '0') ?? 0;
    
    final bool isAvailable = availableUnits > 0 && 
                            (project['is_active'] ?? true) && 
                            (project['status']?.toString() != 'sold_out');

    final List<Color> gradientColors = [
      const Color(0xFFFF6B35),
      const Color(0xFFFF8E53),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF6B35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
            ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.solar_power,
                        color: gradientColors[1],
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'MAIN PROJECT',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Text(
                      '$availableUnits/$totalUnits',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildVerticalStatItem('$cycleDays', 'Days', Icons.calendar_today),
                      _buildVerticalStatItem('${dailyIncome.toStringAsFixed(0)}', 'Daily', Icons.trending_up),
                      _buildVerticalStatItem('${totalIncome.toStringAsFixed(0)}', 'Total', Icons.attach_money),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unit Price',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                          ),
                          ),
                          Text(
                            '${price.toStringAsFixed(0)} Br',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ],
                      ),
                      
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isAvailable 
                              ? gradientColors 
                              : [Colors.grey, Colors.grey],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton(
                          onPressed: isAvailable ? () => _showMainProjectInvestDialog(id, title, price, availableUnits) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            isAvailable ? 'INVEST NOW' : 'SOLD OUT',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFF6B35)),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      {
        'icon': Icons.home, 
        'label': 'Home', 
        'onTap': () => setState(() => _selectedIndex = 0)
      },
      {
        'icon': Icons.trending_up, 
        'label': 'Income', 
        'onTap': () {
          setState(() => _selectedIndex = 1);
          _showToast("Loading income details...");
        }
      },
      {
        'icon': Icons.article, 
        'label': 'News', 
        'onTap': () {
          setState(() => _selectedIndex = 2);
          _showToast("Loading news...");
        }
      },
      {
        'icon': Icons.chat, 
        'label': 'Chat', 
        'onTap': () {
          setState(() => _selectedIndex = 3);
          _handleChat(); // Updated to use new chat handler
        }
      },
      {
        'icon': Icons.people, 
        'label': 'Team', 
        'onTap': () {
          setState(() => _selectedIndex = 4);
          _showToast("Loading team data...");
        }
      },
      {
        'icon': Icons.person, 
        'label': 'Me', 
        'onTap': () {
          setState(() => _selectedIndex = 5);
          _showToast("Opening profile...");
        }
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = _selectedIndex == index;
              return GestureDetector(
                onTap: item['onTap'] as VoidCallback,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? const Color(0xFF8A2BE2) : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? const Color(0xFF8A2BE2) : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TeslaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDC143C)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.15);
    path.lineTo(size.width * 0.3, size.height * 0.85);
    path.lineTo(size.width * 0.45, size.height * 0.85);
    path.lineTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.55, size.height * 0.85);
    path.lineTo(size.width * 0.7, size.height * 0.85);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}