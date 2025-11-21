import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';
import 'history_page.dart';
import 'task_page.dart';
import 'recharge_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;
  const ProfilePage({super.key, required this.token});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await ApiService.getProfile(widget.token);
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple, // Header background
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF0B90B)))
          : _error != null
              ? Center(
                  child: Text('Error: $_error',
                      style: GoogleFonts.poppins(color: Colors.white)),
                )
              : _profile == null
                  ? Center(
                      child: Text('Profile data is empty',
                          style: GoogleFonts.poppins(color: Colors.white)),
                    )
                  : Column(
                      children: [
                        // HEADER
                        Container(
                          padding: const EdgeInsets.only(
                              top: 60, left: 20, right: 20, bottom: 20),
                          width: double.infinity,
                          color: Colors.purple.withOpacity(0.85),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "My Profile",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _profile?['username'] ?? "No Name",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // MAIN CONTENT
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24)),
                            ),
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildBalanceCard(),
                                  const SizedBox(height: 20),
                                  _buildActionItem(
                                    icon: Icons.account_balance_wallet_outlined,
                                    label: "Withdrawal",
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              HistoryPage(token: widget.token)),
                                    ),
                                  ),
                                  _buildActionItem(
                                    icon: Icons.groups_outlined,
                                    label: "Team Report",
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              TaskPage(token: widget.token)),
                                    ),
                                  ),
                                  _buildActionItem(
                                    icon: Icons.receipt_long_outlined,
                                    label: "Recharge Record",
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              RechargePage(token: widget.token)),
                                    ),
                                  ),
                                  const SizedBox(height: 50),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _profile?['balance']?.toString() ?? '0.00';
    final available = _profile?['available_balance']?.toString() ?? balance;
    final frozen = _profile?['frozen_balance']?.toString() ?? '0.00';
    final accountNumber = _profile?['account_number'] ?? "N/A";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400.withOpacity(0.9),
            Colors.purple.shade700.withOpacity(0.9)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Balance",
            style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            "Birr $balance",
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const Divider(color: Colors.white30, height: 24, thickness: 1),
          Text(
            "Account: $accountNumber",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceItem(
                  "Available", "Birr $available", Colors.greenAccent.shade200),
              _buildBalanceItem(
                  "Frozen", "Birr $frozen", Colors.redAccent.shade200),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
              color: color, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF004AAD), size: 26),
        title: Text(label,
            style: GoogleFonts.poppins(
                color: const Color(0xFF001F3F),
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Color(0xFF004AAD), size: 16),
        onTap: onTap,
      ),
    );
  }
}