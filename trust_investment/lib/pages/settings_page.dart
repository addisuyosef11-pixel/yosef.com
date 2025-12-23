import 'package:flutter/material.dart';
import 'set_withdraw_password_page.dart';
import 'change_withdraw_password_page.dart';
import 'account_number_page.dart';

class SettingsPage extends StatefulWidget {
  final String token;
  const SettingsPage({super.key, required this.token});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  static const Color primaryColor = Color(0xFF9C27B0);
  static const Color secondaryColor = Color(0xFF7B1FA2);
  static const Color gradientStart = Color(0xFF9C27B0);
  static const Color gradientEnd = Color(0xFF7B1FA2);
  static const Color cardColor = Colors.white;
  static const Color textColor = Colors.black87;
  static const Color subtitleColor = Colors.black54;
  static const Color backgroundColor = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Header with wave design
          _buildHeader(),
          
          // Back button - MOVED INSIDE SafeArea
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Main content
          Positioned.fill(
            top: 200, // Reduced from 180 to give more space
            child: Container(
              decoration: const BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // ===== ACCOUNT SECURITY =====
                    _buildSectionTitle("Account Security"),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: "Set Withdraw Password",
                      subtitle: "Create a secure withdrawal password",
                      color: const Color(0xFF42A5F5),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SetWithdrawPasswordPage(token: widget.token),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.vpn_key_outlined,
                      title: "Change Withdraw Password",
                      subtitle: "Update your existing password",
                      color: const Color(0xFFFF7043),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeWithdrawPasswordPage(token: widget.token),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.account_balance_outlined,
                      title: "Bank Account",
                      subtitle: "Manage your linked bank account",
                      color: const Color(0xFF66BB6A),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AccountNumberPage(token: widget.token),
                          ),
                        );
                      },
                    ),

                    // ===== PREFERENCES =====
                    const SizedBox(height: 24),
                    _buildSectionTitle("Preferences"),
                    _buildSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: "Push Notifications",
                      subtitle: "Receive important updates",
                      value: _notificationsEnabled,
                      color: const Color(0xFFFFB74D),
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                        // TODO: Save preference to backend
                      },
                    ),
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: "Dark Mode",
                      subtitle: "Switch to dark theme",
                      value: _darkModeEnabled,
                      color: const Color(0xFF78909C),
                      onChanged: (val) {
                        setState(() => _darkModeEnabled = val);
                        // TODO: Implement dark mode
                      },
                    ),

                    // ===== APP INFO =====
                    const SizedBox(height: 24),
                    _buildSectionTitle("About"),
                    _buildInfoTile(
                      icon: Icons.info_outline,
                      title: "App Version",
                      subtitle: "1.0.0",
                      color: const Color(0xFF9C27B0),
                    ),
                    _buildInfoTile(
                      icon: Icons.security_outlined,
                      title: "Privacy Policy",
                      subtitle: "View our privacy terms",
                      color: const Color(0xFF5C6BC0),
                      onTap: () {
                        // TODO: Show privacy policy
                      },
                    ),
                    _buildInfoTile(
                      icon: Icons.help_outline,
                      title: "Help & Support",
                      subtitle: "Contact our support team",
                      color: const Color(0xFF26A69A),
                      onTap: () {
                        // TODO: Show support page
                      },
                    ),

                    // Logout Button
                    const SizedBox(height: 32),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement logout
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 220, // Reduced height to show more content
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Wave design at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                child: SizedBox(
                  height: 60,
                  child: CustomPaint(
                    size: const Size(double.infinity, 60),
                    painter: WavePainter(),
                  ),
                ),
              ),
            ),
            
            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            
            // Header content
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
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
                        Icons.settings,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage your account preferences',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Header
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Settings tile with gradient background
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                  ),
                )
              : null,
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 14,
            ),
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Switch tile with gradient
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                  ),
                )
              : null,
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
            activeTrackColor: primaryColor.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Info tile (non-interactive)
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        color: Colors.grey[50],
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                  ),
                )
              : null,
          trailing: onTap != null
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 14,
                  ),
                )
              : null,
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.3, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.7, size.width, size.height * 0.4)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}