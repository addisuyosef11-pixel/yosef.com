import 'package:flutter/material.dart';
import 'dart:async';
import 'order_page.dart';
import 'api_service.dart';
import 'recharge_page.dart';
import 'withdraw_page.dart';
import 'task_page.dart';
import 'lucky_wheel_page.dart';
import 'settings_page.dart';
import 'gift_redeem_page.dart'; // Gift redemption page
import 'chat_page.dart'; // Customer support chat page

class HomePage extends StatefulWidget {
  final String token;
  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollSpeed = 1.0;
  bool _showBalance = false;
  double _balance = 0.0;
  String _accountNumber = "";
  String _username = "";
  bool _loading = true;

  int _bannerIndex = 0;
  late PageController _pageController;

  List<String> commissions = [];

  List<Map<String, String>> banners = [
    {"img": "assets/images/vip_4.jpg", "discount": "25% OFF"},
    {"img": "assets/images/vip_1.jpg", "discount": "10% OFF"},
    {"img": "assets/images/vip_3.jpg", "discount": "15% OFF"},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInfiniteScroll();
      _fetchData();
    });
    _startBannerAutoScroll();
  }

  void _startInfiniteScroll() async {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.offset + _scrollSpeed;
        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(currentScroll);
        }
      }
    }
  }

  void _startBannerAutoScroll() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _bannerIndex = (_bannerIndex + 1) % banners.length;
        _pageController.animateToPage(
          _bannerIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchData() async {
    try {
      final profile = await ApiService.getProfile(widget.token);
      setState(() {
        _username = profile?['username'] ?? "";
        _balance = (profile?['balance'] ?? 0).toDouble();
        _accountNumber = profile?['account_number'] ?? "";
      });

      final commissionData = await ApiService.getCommissions(widget.token);
      setState(() {
        commissions =
            commissionData.map<String>((e) => e['description'] ?? "").toList();
      });
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        title: const Text("Daily Cash 💰",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              accountName: Text(_username),
              accountEmail: Text(_accountNumber),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.purple),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.purple),
              title: const Text("Profile"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.purple),
              title: const Text("Settings"),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(token: widget.token),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                _banner(),
                const SizedBox(height: 8),
                _dotIndicator(),
                const SizedBox(height: 20),
                _balanceCard(),
                const SizedBox(height: 20),
                _giftBoxSection(), // <-- Gift box replaces countdown
                const SizedBox(height: 25),
                _recentCommissions(),
                const SizedBox(height: 30),
                const Text(
                  "Financial Services",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                _buttonGrid(),
                const SizedBox(height: 35),
                _faqSection(),
                const SizedBox(height: 30),
                _customerServiceSection(), // <-- round bigger button
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _banner() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: banners.length,
        onPageChanged: (index) => setState(() => _bannerIndex = index),
        itemBuilder: (context, index) {
          final banner = banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(banner['img']!),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      banner['discount']!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderPage(token: widget.token, vipData: {})),
                      );
                    },
                    child: const Text("Order Now"),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(banners.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _bannerIndex == index ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _bannerIndex == index ? Colors.purple : Colors.grey,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _balanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text("Welcome, $_username", style: const TextStyle(color: Colors.black87, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showBalance ? "${_balance.toStringAsFixed(2)} ETB" : "**** ETB",
                style: const TextStyle(color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(_showBalance ? Icons.visibility : Icons.visibility_off, color: Colors.green),
                onPressed: () => setState(() => _showBalance = !_showBalance),
              ),
            ],
          ),
          Text("Account: $_accountNumber", style: const TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _recentCommissions() {
    return Column(
      children: [
        const Text("Recent Commissions",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Container(
          height: 80,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: ListView.builder(
            controller: _scrollController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: commissions.length * 2,
            itemBuilder: (context, index) {
              final commission = commissions[index % commissions.length];
              return Text(commission, style: const TextStyle(color: Colors.black87, fontSize: 14));
            },
          ),
        ),
      ],
    );
  }

  Widget _buttonGrid() {
    final List<Map<String, dynamic>> buttons = [
      {
        "title": "Deposit",
        "icon": Icons.account_balance,
        "action": () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => RechargePage(token: widget.token)));
        }
      },
      {
        "title": "Withdraw",
        "icon": Icons.attach_money,
        "action": () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => WithdrawPage(token: widget.token)));
        }
      },
      {
        "title": "Order",
        "icon": Icons.shopping_cart,
        "action": () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => OrderPage(token: widget.token, vipData: {})));
        }
      },
      {
        "title": "Task Hall",
        "icon": Icons.task_alt,
        "action": () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TaskPage(token: widget.token)));
        }
      },
      {
        "title": "Lucky Wheel",
        "icon": Icons.casino,
        "action": () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LuckyWheelPage(token: widget.token, currentBalance: _balance)),
          );
        }
      },
    ];

    return Wrap(
      spacing: 25,
      runSpacing: 25,
      children: buttons.map((b) {
        return Column(
          children: [
            InkWell(
              onTap: b["action"] as void Function(),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                child: Center(
                  child: Icon(b["icon"] as IconData, color: Colors.white, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(b["title"] as String, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ],
        );
      }).toList(),
    );
  }

  Widget _faqSection() {
    final faqs = [
      {"q": "How can I deposit money?", "a": "Go to Deposit, choose payment method, confirm."},
      {"q": "How do I withdraw my earnings?", "a": "Tap Withdraw, enter amount and confirm."},
      {"q": "How do I complete daily tasks?", "a": "Go to Task Hall, complete tasks to earn."},
      {"q": "What is the Lucky Wheel?", "a": "Spin daily to win random rewards."},
      {"q": "How can I contact support?", "a": "Use Help in Settings or official channels."},
    ];

    return Column(
      children: [
        const Text("Frequently Asked Questions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 10),
        ...faqs.map((item) {
          return ExpansionTile(
            leading: const Icon(Icons.help_outline, color: Colors.green),
            title: Text(item['q']!, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(item['a']!, style: const TextStyle(color: Colors.black54, fontSize: 14)),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _giftBoxSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => GiftRedeemPage(token: widget.token)));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.card_giftcard, color: Colors.orange, size: 36),
              SizedBox(width: 10),
              Text("Daily Gift", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customerServiceSection() {
    return Center(
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(token: widget.token)));
        },
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            color: Colors.purple,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.support_agent, color: Colors.white, size: 48),
              SizedBox(height: 8),
              Text("Customer Service", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
