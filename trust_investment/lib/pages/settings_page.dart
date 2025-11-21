import 'package:flutter/material.dart';
import 'set_withdraw_password_page.dart';
import 'change_withdraw_password_page.dart';
import 'account_number_page.dart';

class SettingsPage extends StatefulWidget {
  final String token; // required token
  const SettingsPage({super.key, required this.token});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F3F),
      body: Stack(
        children: [
          // Header
          Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF001F3F), Color(0xFF004AAD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "⚙️ Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Body
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.82,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ===== ACCOUNT SECURITY =====
                  _buildSectionTitle("Account Security"),
                  _buildSettingsTile(
                    icon: Icons.password,
                    title: "Set Withdraw Password",
                    subtitle: "Create or update your withdrawal PIN",
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
                    icon: Icons.vpn_key,
                    title: "Change Withdraw Password",
                    subtitle: "Modify your existing withdrawal password",
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
                    icon: Icons.account_balance,
                    title: "Change Account Number",
                    subtitle: "Update your linked bank account",
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
                    icon: Icons.notifications_active,
                    title: "Notifications",
                    value: _notificationsEnabled,
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                    },
                  ),
                  _buildSwitchTile(
                    icon: Icons.dark_mode,
                    title: "Dark Mode",
                    value: _darkModeEnabled,
                    onChanged: (val) {
                      setState(() => _darkModeEnabled = val);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF004AAD),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Normal settings tile
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF004AAD)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(color: Colors.black54))
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black45, size: 18),
        onTap: onTap,
      ),
    );
  }

  // Switch setting tile
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF004AAD)),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF004AAD),
        ),
      ),
    );
  }
}

