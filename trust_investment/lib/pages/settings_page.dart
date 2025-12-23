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
  bool _biometricEnabled = false;
  bool _autoUpdateEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 70, bottom: 16),
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepPurple,
                      Colors.purple,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.only(left: 24, bottom: 24),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Customize your experience',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
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
            ),
          ),

          // Settings List
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Security Section
                    _buildSectionHeader('Account Security'),
                    const SizedBox(height: 12),
                    _buildModernCard(
                      children: [
                        _buildModernTile(
                          icon: Icons.lock_outline,
                          title: 'Set Withdraw Password',
                          subtitle: 'Create a secure withdrawal password',
                          iconColor: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SetWithdrawPasswordPage(token: widget.token),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildModernTile(
                          icon: Icons.vpn_key_outlined,
                          title: 'Change Withdraw Password',
                          subtitle: 'Update your existing password',
                          iconColor: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChangeWithdrawPasswordPage(token: widget.token),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildModernTile(
                          icon: Icons.account_balance_outlined,
                          title: 'Bank Account',
                          subtitle: 'Manage your linked bank account',
                          iconColor: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AccountNumberPage(token: widget.token),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildModernSwitchTile(
                          icon: Icons.fingerprint_outlined,
                          title: 'Biometric Login',
                          subtitle: 'Use fingerprint or face ID',
                          iconColor: Colors.purple,
                          value: _biometricEnabled,
                          onChanged: (val) {
                            setState(() => _biometricEnabled = val);
                          },
                        ),
                      ],
                    ),

                    // Preferences Section
                    const SizedBox(height: 24),
                    _buildSectionHeader('Preferences'),
                    const SizedBox(height: 12),
                    _buildModernCard(
                      children: [
                        _buildModernSwitchTile(
                          icon: Icons.notifications_active_outlined,
                          title: 'Push Notifications',
                          subtitle: 'Receive important updates',
                          iconColor: Colors.amber,
                          value: _notificationsEnabled,
                          onChanged: (val) {
                            setState(() => _notificationsEnabled = val);
                          },
                        ),
                        _buildDivider(),
                        _buildModernSwitchTile(
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark Mode',
                          subtitle: 'Switch to dark theme',
                          iconColor: Colors.indigo,
                          value: _darkModeEnabled,
                          onChanged: (val) {
                            setState(() => _darkModeEnabled = val);
                          },
                        ),
                        _buildDivider(),
                        _buildModernSwitchTile(
                          icon: Icons.update_outlined,
                          title: 'Auto Update',
                          subtitle: 'Automatically update app',
                          iconColor: Colors.teal,
                          value: _autoUpdateEnabled,
                          onChanged: (val) {
                            setState(() => _autoUpdateEnabled = val);
                          },
                        ),
                      ],
                    ),

                    // Support Section
                    const SizedBox(height: 24),
                    _buildSectionHeader('Support'),
                    const SizedBox(height: 12),
                    _buildModernCard(
                      children: [
                        _buildModernTile(
                          icon: Icons.help_outline,
                          title: 'Help Center',
                          subtitle: 'Get answers to your questions',
                          iconColor: Colors.blueGrey,
                          onTap: () {
                            // TODO: Navigate to help center
                          },
                        ),
                        _buildDivider(),
                        _buildModernTile(
                          icon: Icons.security_outlined,
                          title: 'Privacy Policy',
                          subtitle: 'View our privacy terms',
                          iconColor: Colors.deepPurple,
                          onTap: () {
                            // TODO: Show privacy policy
                          },
                        ),
                        _buildDivider(),
                        _buildModernTile(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          subtitle: 'Read our terms and conditions',
                          iconColor: Colors.brown,
                          onTap: () {
                            // TODO: Show terms of service
                          },
                        ),
                        _buildDivider(),
                        _buildModernTile(
                          icon: Icons.info_outline,
                          title: 'About',
                          subtitle: 'App version 1.0.0',
                          iconColor: Colors.pink,
                          onTap: () {
                            // TODO: Show about dialog
                          },
                        ),
                      ],
                    ),

                    // Account Actions
                    const SizedBox(height: 24),
                    _buildSectionHeader('Account'),
                    const SizedBox(height: 12),
                    _buildModernCard(
                      children: [
                        _buildModernTile(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          subtitle: 'Update your personal information',
                          iconColor: Colors.cyan,
                          onTap: () {
                            // TODO: Navigate to edit profile
                          },
                        ),
                        _buildDivider(),
                        _buildModernTile(
                          icon: Icons.history_outlined,
                          title: 'Activity Log',
                          subtitle: 'View your account activity',
                          iconColor: Colors.deepOrange,
                          onTap: () {
                            // TODO: Show activity log
                          },
                        ),
                        _buildDivider(),
                        _buildModernTile(
                          icon: Icons.delete_outline,
                          title: 'Delete Account',
                          subtitle: 'Permanently delete your account',
                          iconColor: Colors.red,
                          textColor: Colors.red,
                          onTap: () {
                            // TODO: Show delete account confirmation
                          },
                        ),
                      ],
                    ),

                    // Logout Button
                    const SizedBox(height: 32),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showLogoutConfirmation(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
                          ),
                          elevation: 2,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildModernCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[200],
      ),
    );
  }

  Widget _buildModernTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            )
          : null,
      trailing: onTap != null
          ? Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[600],
                size: 16,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildModernSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            )
          : null,
      trailing: Transform.scale(
        scale: 0.9,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.deepPurple,
          activeTrackColor: Colors.deepPurple.withOpacity(0.3),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey.withOpacity(0.3),
        ),
      ),
      onTap: () => onChanged(!value),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout from your account?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
              // TODO: Implement logout logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}