import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'api_service.dart';
import 'history_page.dart';
import 'task_page.dart';
import 'recharge_page.dart';
import 'faq_page.dart';
import 'feedback_page.dart';
import 'settings_page.dart';
import 'telegram_page.dart';
import 'balance_page.dart';
import 'home_page.dart';
import 'income_page.dart';
import 'news_page.dart';
import 'support_chat_page.dart';
import 'team_page.dart';
import 'profile_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;
  const ProfilePage({super.key, required this.token});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> _profileData = {};
  bool isLoading = true;
  bool _isApiLoading = false;
  bool _balanceVisible = true;

  @override
  void initState() {
    super.initState();
    _loadDataWithDelay();
  }

  Future<void> _loadDataWithDelay() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      print("🔍 Loading profile data...");
      final profile = await ApiService.getProfile(widget.token);
      print("✅ Profile API Response: $profile");
      
      if (profile != null && profile.isNotEmpty) {
        setState(() {
          _profileData = profile;
        });
        print("✅ Profile loaded successfully");
      } else {
        print("⚠️ Profile is null or empty");
        setState(() {
          _profileData = {};
        });
      }
    } catch (e) {
      print("❌ Profile error: $e");
      _showToast("Failed to load profile", isError: true);
      setState(() {
        _profileData = {};
      });
    } finally {
      setState(() => isLoading = false);
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

  void _refreshData() {
    _showToast("Refreshing data...");
    _loadDataWithApiLoading();
  }

  Future<void> _loadDataWithApiLoading() async {
    setState(() => _isApiLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    await _loadData();
    setState(() => _isApiLoading = false);
  }

  Future<void> _handleMenuItemTap(Function action) async {
    setState(() => _isApiLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    action();
    setState(() => _isApiLoading = false);
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
                'Loading Profile...',
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
                _menuGrid(),
                const SizedBox(height: 20),
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

  Widget _heroBanner() {
    final username = _profileData['username']?.toString() ?? 'User';
    final userId = _getUserId();
    final inviteCode = _profileData['inviteCode']?.toString() ?? 'N/A';
    
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
          // Car background image (same as home page)
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'English',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $userId',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Invitation code: ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              inviteCode,
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _refreshData,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getUserId() {
    final possibleIdFields = [
      'id',
      'user_id',
      'userId',
      'uid',
      'user',
      'userid',
    ];
    
    for (var field in possibleIdFields) {
      if (_profileData.containsKey(field) && _profileData[field] != null) {
        return _profileData[field].toString();
      }
    }
    
    return '---';
  }

  Widget _balanceCard() {
    final balance = (_profileData['balance'] ?? 0).toDouble();
    final availableBalance = (_profileData['available_balance'] ?? balance).toDouble();
    final frozenBalance = (_profileData['frozen_balance'] ?? 0).toDouble();
    final accountNumber = _profileData['account_number']?.toString() ?? 'Not set';
    
    return Transform.translate(
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
            // User info with person icon (like home page)
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
                        'ID: ${_getUserId()}',
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
            
            // Balance section with eye icon (like home page)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BalancePage(token: widget.token),
                            ),
                          );
                        },
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
                            _balanceVisible ? balance.toStringAsFixed(0) : '*****',
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
                Column(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BalancePage(token: widget.token),
                          ),
                        );
                      },
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BalancePage(token: widget.token),
                          ),
                        );
                      },
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
            const SizedBox(height: 16),
            
            // Account number
            Text(
              'Account: $accountNumber',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            // Available and Frozen balance buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showToast('Available Balance: $availableBalance Br');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Available',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '$availableBalance Br',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showToast('Frozen Balance: $frozenBalance Br');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.lock, size: 18),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Frozen',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '$frozenBalance Br',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuGrid() {
    final menuItems = [
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'Wallet',
        'color': const Color(0xFFFF8C00),
        'onTap': () => _handleMenuItemTap(() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BalancePage(token: widget.token),
            ),
          );
        }),
      },
      {
        'icon': Icons.groups_outlined,
        'label': 'Team',
        'color': const Color(0xFF00BCD4),
        'onTap': () => _handleMenuItemTap(() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamPage(token: widget.token),
            ),
          );
        }),
      },
      {
        'icon': Icons.receipt_long_outlined,
        'label': 'History',
        'color': const Color(0xFF8B5CF6),
        'onTap': () => _handleMenuItemTap(() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BalancePage(token: widget.token),
            ),
          );
        }),
      },
      {
        'icon': Icons.headphones,
        'label': 'Support',
        'color': const Color(0xFF22C55E),
        'onTap': () => _handleMenuItemTap(() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SupportChatPage(
                token: widget.token,
                userName: _profileData['username']?.toString() ?? 'User',
              ),
            ),
          );
        }),
      },
      {
        'icon': Icons.help_outline,
        'label': 'FAQ',
        'color': const Color(0xFFE91E8C),
        'onTap': () => _handleMenuItemTap(() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FAQPage(token: widget.token),
            ),
          );
        }),
      },
      {
        'icon': Icons.lock_outline,
        'label': 'Settings',
        'color': const Color(0xFF9C27B0),
        'onTap': () => _handleMenuItemTap(() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsPage(token: widget.token),
            ),
          );
        }),
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Feedback',
        'color': const Color(0xFF3B82F6),
        'onTap': () => _handleMenuItemTap(() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FeedbackPage(token: widget.token),
            ),
          );
        }),
      },
      {
        'icon': Icons.logout,
        'label': 'Logout',
        'color': Colors.red,
        'onTap': () => _showLogoutDialog(context),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _buildMenuItem(
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            color: item['color'] as Color,
            onTap: item['onTap'] as VoidCallback,
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performLogout(context);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) {
    _showToast('Logged out successfully');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}