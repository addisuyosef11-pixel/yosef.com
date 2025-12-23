import 'package:flutter/material.dart';

class TeamPage extends StatefulWidget {
  final String token;
  const TeamPage({Key? key, required this.token}) : super(key: key);

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = true;
  Map<String, dynamic> _teamStats = {};

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _teamMembers = [
        {
          'name': 'John Doe',
          'level': 'Level 1',
          'joined': '2024-01-10',
          'status': 'active',
          'investment': 5000.0,
          'avatar': 'https://randomuser.me/api/portraits/men/1.jpg'
        },
        {
          'name': 'Sarah Smith',
          'level': 'Level 2',
          'joined': '2024-01-08',
          'status': 'active',
          'investment': 7500.0,
          'avatar': 'https://randomuser.me/api/portraits/women/2.jpg'
        },
        {
          'name': 'Mike Johnson',
          'level': 'Level 1',
          'joined': '2024-01-05',
          'status': 'active',
          'investment': 3000.0,
          'avatar': 'https://randomuser.me/api/portraits/men/3.jpg'
        },
        {
          'name': 'Emma Wilson',
          'level': 'Level 3',
          'joined': '2024-01-02',
          'status': 'active',
          'investment': 12000.0,
          'avatar': 'https://randomuser.me/api/portraits/women/4.jpg'
        },
        {
          'name': 'David Brown',
          'level': 'Level 1',
          'joined': '2023-12-28',
          'status': 'inactive',
          'investment': 2000.0,
          'avatar': 'https://randomuser.me/api/portraits/men/5.jpg'
        },
      ];
      
      _teamStats = {
        'totalMembers': 5,
        'activeMembers': 4,
        'totalInvestment': 29500.0,
        'commissionEarned': 885.0,
      };
      
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team'),
        backgroundColor: const Color(0xFF8A2BE2),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeamData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Team Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFF5F5F5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('Total', '${_teamStats['totalMembers']}', Icons.people),
                      _buildStatCard('Active', '${_teamStats['activeMembers']}', Icons.check_circle),
                      _buildStatCard('Investment', '${_teamStats['totalInvestment']}', Icons.attach_money),
                      _buildStatCard('Commission', '${_teamStats['commissionEarned']}', Icons.monetization_on),
                    ],
                  ),
                ),

                // Team List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Team Members',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('Invite'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A2BE2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Team Members List
                Expanded(
                  child: ListView.builder(
                    itemCount: _teamMembers.length,
                    itemBuilder: (context, index) {
                      final member = _teamMembers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(member['avatar']),
                            radius: 24,
                          ),
                          title: Text(
                            member['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Level: ${member['level']}'),
                              Text('Joined: ${member['joined']}'),
                              Text('Investment: ${member['investment']} Br'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: member['status'] == 'active' 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              member['status'] == 'active' ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: member['status'] == 'active' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8A2BE2), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}