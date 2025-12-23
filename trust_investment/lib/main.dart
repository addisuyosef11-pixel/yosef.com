import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/vip_products_page.dart';
import 'pages/signup_page.dart';
import 'pages/api_service.dart';
import 'pages/invite_page.dart';
import 'pages/login_page.dart';
import 'pages/income_page.dart';
import 'pages/news_page.dart';
import 'pages/team_page.dart';
import 'pages/support_chat_page.dart';
import 'pages/order_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trust Investment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF8A2BE2),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF8A2BE2),
          secondary: const Color(0xFF9B4DCA),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8A2BE2),
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: LoginPage(),
      routes: {
        '/main': (context) {
          final token = ModalRoute.of(context)!.settings.arguments as String;
          return MainNavigation(token: token);
        },
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  final String token;
  const MainNavigation({super.key, required this.token});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Get the current page based on selected index
  Widget _getPage() {
    switch (_selectedIndex) {
      case 0:
        return HomePage(token: widget.token);
      case 1:
        return OrderPage(token: widget.token); // FIXED: Removed vipData parameter
      case 2:
        return NewsPage(token: widget.token);
      case 3:
        return SupportChatPage(
          token: widget.token,
          userName: 'User',
        );
      case 4:
        return TeamPage(token: widget.token);
      case 5:
        return ProfilePage(token: widget.token);
      default:
        return HomePage(token: widget.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.trending_up, 'label': 'Income'}, // Changed from 'Orders' to 'Income'
      {'icon': Icons.article, 'label': 'News'},
      {'icon': Icons.chat, 'label': 'Chat'},
      {'icon': Icons.people, 'label': 'Team'},
      {'icon': Icons.person, 'label': 'Me'},
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
                onTap: () {
                  setState(() => _selectedIndex = index);
                },
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