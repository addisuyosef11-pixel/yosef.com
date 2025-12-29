
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'api_service.dart';

class TeamPage extends StatefulWidget {
  final String token;
  const TeamPage({Key? key, required this.token}) : super(key: key);

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  List<dynamic> _teamMembers = [];
  Map<String, dynamic> _teamStats = {};
  String _inviteCode = '';
  bool _isLoading = true;
  final TextEditingController _phoneController = TextEditingController();

  // Helper method to parse amount from dynamic value
  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove currency symbols and parse
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    if (value is num) return value.toDouble();
    
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getTeamMembers(widget.token);
      
      if (ApiService.isSuccess(response)) {
        setState(() {
          _teamMembers = response['team_members'] ?? response['members'] ?? [];
          _teamStats = response['team_stats'] ?? response['stats'] ?? {};
          _inviteCode = _teamStats['invite_code'] ?? response['invite_code'] ?? '';
          _isLoading = false;
        });
      } else {
        _showError(ApiService.getErrorMessage(response));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error loading team data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendInvitation() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    try {
      final response = await ApiService.sendInvitation(
        token: widget.token,
        phone: phone,
      );
      
      if (ApiService.isSuccess(response)) {
        _showSuccess(response['message'] ?? 'Invitation sent successfully!');
        _phoneController.clear();
        _loadTeamData(); // Refresh data
      } else {
        _showError(ApiService.getErrorMessage(response));
      }
    } catch (e) {
      _showError('Error sending invitation: $e');
    }
  }

  Future<void> _shareReferral() async {
    final shareText = 'Join me on this amazing platform!\nUse my invite code: $_inviteCode';
    
    // You can also use the API to get share content if available
    try {
      final response = await ApiService.shareReferralLink(widget.token);
      if (ApiService.isSuccess(response)) {
        await Share.share(response['share_text'] ?? response['message'] ?? shareText);
      } else {
        await Share.share(shareText);
      }
    } catch (e) {
      // Fallback to basic sharing
      await Share.share(shareText);
    }
  }

  // Share via Telegram
  Future<void> _shareViaTelegram() async {
    final shareText = 'Join me on this amazing platform!\nUse my invite code: $_inviteCode';
    final encodedText = Uri.encodeComponent(shareText);
    final telegramUrl = 'https://t.me/share/url?url=&text=$encodedText';
    
    try {
      if (await canLaunchUrl(Uri.parse(telegramUrl))) {
        await launchUrl(Uri.parse(telegramUrl));
      } else {
        await Share.share(shareText);
      }
    } catch (e) {
      _showError('Failed to open Telegram: $e');
    }
  }

  // Share via WhatsApp
  Future<void> _shareViaWhatsApp() async {
    final shareText = 'Join me on this amazing platform!\nUse my invite code: $_inviteCode';
    final encodedText = Uri.encodeComponent(shareText);
    final whatsappUrl = 'https://wa.me/?text=$encodedText';
    
    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        await Share.share(shareText);
      }
    } catch (e) {
      _showError('Failed to open WhatsApp: $e');
    }
  }

  // Share via Facebook
  Future<void> _shareViaFacebook() async {
    final shareText = 'Join me on this amazing platform!\nUse my invite code: $_inviteCode';
    
    // Facebook doesn't have a direct share URL that works well
    // So we'll use the generic share with a hint
    try {
      await Share.share(shareText, subject: 'Share on Facebook');
    } catch (e) {
      _showError('Failed to share: $e');
    }
  }

  // Share via Instagram
  Future<void> _shareViaInstagram() async {
    final shareText = 'Join me on this amazing platform!\nUse my invite code: $_inviteCode';
    
    // Instagram doesn't have a direct share URL for text
    // So we'll copy to clipboard and show instructions
    _copyToClipboard(shareText);
    _showInfo('Invitation copied! Open Instagram and paste in your story or post.');
    
    // Optionally try to open Instagram
    try {
      if (await canLaunchUrl(Uri.parse('instagram://'))) {
        await launchUrl(Uri.parse('instagram://'));
      }
    } catch (e) {
      // Instagram not installed, that's okay
    }
  }

  // Share via Email
  Future<void> _shareViaEmail() async {
    final subject = 'Join me on this amazing platform!';
    final body = 'Use my invite code: $_inviteCode\n\nJoin now and start earning!';
    final emailUrl = 'mailto:?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
      } else {
        _showError('No email app found');
      }
    } catch (e) {
      _showError('Failed to open email: $e');
    }
  }

  // Share via SMS
  Future<void> _shareViaSMS() async {
    final body = 'Join me on this amazing platform! Use my invite code: $_inviteCode';
    final smsUrl = 'sms:?body=${Uri.encodeComponent(body)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
      } else {
        _showError('No SMS app found');
      }
    } catch (e) {
      _showError('Failed to open SMS: $e');
    }
  }

  Future<void> _loadCommissionHistory() async {
    try {
      final response = await ApiService.getCommissionHistory(widget.token);
      if (ApiService.isSuccess(response)) {
        // You can navigate to commission history page or show a dialog
        final List<dynamic> commissions = response['commissions'] ?? [];
        if (commissions.isNotEmpty) {
          _showCommissionDialog(commissions);
        } else {
          _showInfo('No commission history yet');
        }
      } else {
        _showError('Failed to load commission history');
      }
    } catch (e) {
      _showError('Error loading commission history: $e');
    }
  }

  Future<void> _loadTeamStats() async {
    try {
      final response = await ApiService.getTeamStats(widget.token);
      if (ApiService.isSuccess(response)) {
        // Update stats if needed
        setState(() {
          _teamStats = {
            ..._teamStats,
            ...response,
          };
        });
      }
    } catch (e) {
      // Silently fail, stats might already be loaded from getTeamMembers
    }
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    
    Clipboard.setData(ClipboardData(text: text));
    _showSuccess('Copied to clipboard!');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showCommissionDialog(List<dynamic> commissions) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Commission History',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Container(
                height: 300,
                child: ListView.builder(
                  itemCount: commissions.length,
                  itemBuilder: (context, index) {
                    final commission = commissions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF8A2BE2).withOpacity(0.1),
                        child: Icon(Icons.monetization_on, color: Color(0xFF8A2BE2), size: 20),
                      ),
                      title: Text(
                        commission['from_user']?.toString() ?? 'Unknown',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Level: ${commission['level'] ?? 'Direct'}',
                        style: GoogleFonts.poppins(),
                      ),
                      trailing: Text(
                        '${_parseAmount(commission['amount']).toStringAsFixed(2)} Br',
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF8A2BE2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, dynamic value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: Color(0xFF8A2BE2), size: 24),
          SizedBox(height: 8),
          Text(
            value?.toString() ?? '0',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Invite Code',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.history, color: Color(0xFF8A2BE2)),
                  onPressed: _loadCommissionHistory,
                  tooltip: 'Commission History',
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _inviteCode,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.content_copy),
                    onPressed: () => _copyToClipboard(_inviteCode),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Original Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _shareReferral,
                icon: Icon(Icons.share, color: Colors.white),
                label: Text(
                  'Share Invite Code',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8A2BE2),
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Social Media Share Options
            Text(
              'Share via Social Media:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            // Responsive social buttons
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 400;
                return Container(
                  height: isWide ? 120 : 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      SizedBox(width: 8),
                      _buildSocialChip(
                        icon: Icons.telegram,
                        color: Color(0xFF0088cc), // Telegram blue
                        label: 'Telegram',
                        onPressed: _shareViaTelegram,
                        isWide: isWide,
                      ),
                      SizedBox(width: isWide ? 16 : 12),
                      _buildSocialChip(
                        icon: Icons.facebook,
                        color: Color(0xFF4267B2), // Facebook blue
                        label: 'Facebook',
                        onPressed: _shareViaFacebook,
                        isWide: isWide,
                      ),
                      SizedBox(width: isWide ? 16 : 12),
                      _buildSocialChip(
                        icon: Icons.camera_alt,
                        color: Color(0xFFE4405F), // Instagram pink
                        label: 'Instagram',
                        onPressed: _shareViaInstagram,
                        isWide: isWide,
                      ),
                      SizedBox(width: isWide ? 16 : 12),
                      _buildSocialChip(
                        icon: Icons.chat,
                        color: Color(0xFF25D366), // WhatsApp green
                        label: 'WhatsApp',
                        onPressed: _shareViaWhatsApp,
                        isWide: isWide,
                      ),
                      SizedBox(width: isWide ? 16 : 12),
                      _buildSocialChip(
                        icon: Icons.email,
                        color: Colors.grey[700]!,
                        label: 'Email',
                        onPressed: _shareViaEmail,
                        isWide: isWide,
                      ),
                      SizedBox(width: isWide ? 16 : 12),
                      _buildSocialChip(
                        icon: Icons.sms,
                        color: Colors.blueGrey,
                        label: 'SMS',
                        onPressed: _shareViaSMS,
                        isWide: isWide,
                      ),
                      SizedBox(width: 8),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialChip({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
    required bool isWide,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isWide ? 80 : 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isWide ? 64 : 56,
              height: isWide ? 64 : 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isWide ? 32 : 28,
              ),
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isWide ? 12 : 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite New Member',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: GoogleFonts.poppins(),
                hintText: 'Enter phone number with country code',
                hintStyle: GoogleFonts.poppins(),
                prefixIcon: Icon(Icons.phone, color: Color(0xFF8A2BE2)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF8A2BE2), width: 2),
                ),
              ),
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendInvitation,
                icon: Icon(Icons.send, color: Colors.white),
                label: Text(
                  'Send Invitation',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8A2BE2),
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFF8A2BE2).withOpacity(0.1),
          child: Icon(Icons.person, color: Color(0xFF8A2BE2)),
        ),
        title: Text(
          member['name']?.toString() ?? 
          member['username']?.toString() ?? 
          member['phone']?.toString() ?? 
          'Unknown User',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Level: ${member['level'] ?? member['vip_level'] ?? 'No VIP'}',
              style: GoogleFonts.poppins(),
            ),
            if (member['joined_at'] != null || member['created_at'] != null)
              Text(
                'Joined: ${member['joined_at'] ?? member['created_at']}',
                style: GoogleFonts.poppins(),
              ),
            if (member['investment'] != null)
              Text(
                'Investment: ${_parseAmount(member['investment']).toStringAsFixed(2)} Br',
                style: GoogleFonts.poppins(),
              ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: ((member['status'] == 'active' || member['is_active'] == true) 
                ? Colors.green 
                : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            (member['status'] == 'active' || member['is_active'] == true) ? 'Active' : 'Inactive',
            style: GoogleFonts.poppins(
              color: (member['status'] == 'active' || member['is_active'] == true) 
                  ? Colors.green 
                  : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Team',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFF8A2BE2),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTeamData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8A2BE2),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 768;
                
                return SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 800 : double.infinity,
                      ),
                      child: Column(
                        children: [
                          // Stats Section
                          Container(
                            padding: EdgeInsets.all(16),
                            color: Color(0xFFF5F5F5),
                            child: isDesktop
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildStatCard('Members', _teamStats['total_members'] ?? _teamStats['members'] ?? _teamMembers.length, Icons.people),
                                      _buildStatCard('Active', _teamStats['active_members'] ?? _teamStats['active'] ?? 0, Icons.check_circle),
                                      _buildStatCard('Investment', '${_parseAmount(_teamStats['total_investment'] ?? _teamStats['investment'] ?? 0).toStringAsFixed(0)}', Icons.attach_money),
                                      _buildStatCard('Commission', '${_parseAmount(_teamStats['commission_earned'] ?? _teamStats['commission'] ?? 0).toStringAsFixed(0)}', Icons.monetization_on),
                                    ],
                                  )
                                : Wrap(
                                    alignment: WrapAlignment.spaceAround,
                                    spacing: 20,
                                    runSpacing: 16,
                                    children: [
                                      _buildStatCard('Members', _teamStats['total_members'] ?? _teamStats['members'] ?? _teamMembers.length, Icons.people),
                                      _buildStatCard('Active', _teamStats['active_members'] ?? _teamStats['active'] ?? 0, Icons.check_circle),
                                      _buildStatCard('Investment', '${_parseAmount(_teamStats['total_investment'] ?? _teamStats['investment'] ?? 0).toStringAsFixed(0)}', Icons.attach_money),
                                      _buildStatCard('Commission', '${_parseAmount(_teamStats['commission_earned'] ?? _teamStats['commission'] ?? 0).toStringAsFixed(0)}', Icons.monetization_on),
                                    ],
                                  ),
                          ),

                          // Referral Card with social media options
                          _buildReferralCard(),

                          // Invitation Card
                          _buildInvitationCard(),

                          // Team Members List
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Team Members (${_teamMembers.length})',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _loadTeamStats,
                                  icon: Icon(Icons.analytics, size: 18, color: Color(0xFF8A2BE2)),
                                  label: Text(
                                    'Stats',
                                    style: GoogleFonts.poppins(
                                      color: Color(0xFF8A2BE2),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Team Members List
                          _teamMembers.isEmpty
                              ? Container(
                                  constraints: BoxConstraints(maxWidth: 600),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.people_outline, size: 80, color: Colors.grey),
                                        SizedBox(height: 20),
                                        Text(
                                          'No team members yet',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Invite friends to join your team and earn commissions!',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 30),
                                        // Social invite buttons
                                        Column(
                                          children: [
                                            // Telegram button with blue color and white text
                                            Container(
                                              width: double.infinity,
                                              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                              child: ElevatedButton.icon(
                                                onPressed: _shareViaTelegram,
                                                icon: Icon(Icons.telegram, color: Colors.white),
                                                label: Text(
                                                  'Invite via Telegram',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(0xFF0088cc), // Telegram blue
                                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                              child: ElevatedButton.icon(
                                                onPressed: _shareViaFacebook,
                                                icon: Icon(Icons.facebook, color: Colors.white),
                                                label: Text(
                                                  'Invite via Facebook',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(0xFF4267B2), // Facebook blue
                                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                              child: ElevatedButton.icon(
                                                onPressed: _shareViaInstagram,
                                                icon: Icon(Icons.camera_alt, color: Colors.white),
                                                label: Text(
                                                  'Invite via Instagram',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(0xFFE4405F), // Instagram pink
                                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                              child: ElevatedButton.icon(
                                                onPressed: _shareViaWhatsApp,
                                                icon: Icon(Icons.chat, color: Colors.white),
                                                label: Text(
                                                  'Invite via WhatsApp',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Color(0xFF25D366), // WhatsApp green
                                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(25),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 20),
                                            Text(
                                              'Or share your invite code:',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey,
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Container(
                                              margin: EdgeInsets.symmetric(horizontal: 20),
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Color(0xFF8A2BE2)),
                                                borderRadius: BorderRadius.circular(8),
                                                color: Color(0xFF8A2BE2).withOpacity(0.1),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    _inviteCode,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF8A2BE2),
                                                      letterSpacing: 2,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  IconButton(
                                                    icon: Icon(Icons.content_copy, color: Color(0xFF8A2BE2)),
                                                    onPressed: () => _copyToClipboard(_inviteCode),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 40),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(
                                  constraints: BoxConstraints(maxWidth: 600),
                                  child: Column(
                                    children: [
                                      for (var i = 0; i < _teamMembers.length; i++)
                                        _buildTeamMemberCard(
                                          Map<String, dynamic>.from(_teamMembers[i]),
                                        ),
                                    ],
                                  ),
                                ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}