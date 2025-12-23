import 'package:flutter/material.dart';

class NewsPage extends StatefulWidget {
  final String token;
  const NewsPage({Key? key, required this.token}) : super(key: key);

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<Map<String, dynamic>> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _newsList = [
        {
          'title': 'New Solar Farm Project Launch',
          'date': 'Jan 15, 2024',
          'content': 'We are excited to announce the launch of our new solar farm project in Addis Ababa. This project will provide clean energy to over 10,000 households.',
          'image': 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=400',
          'category': 'Announcement'
        },
        {
          'title': 'System Maintenance Notice',
          'date': 'Jan 14, 2024',
          'content': 'There will be scheduled maintenance on January 20th from 2:00 AM to 4:00 AM. Some services may be temporarily unavailable.',
          'image': 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?w-400',
          'category': 'Notice'
        },
        {
          'title': 'Referral Program Update',
          'date': 'Jan 12, 2024',
          'content': 'Our referral program has been updated with better commission rates. Invite friends and earn more bonuses!',
          'image': 'https://images.unsplash.com/photo-1551434678-e076c223a692?w=400',
          'category': 'Update'
        },
        {
          'title': 'New Investment Packages',
          'date': 'Jan 10, 2024',
          'content': 'We have introduced new VIP investment packages with higher returns. Check them out in the investment section.',
          'image': 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400',
          'category': 'Investment'
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News & Updates'),
        backgroundColor: const Color(0xFF8A2BE2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _newsList.length,
              itemBuilder: (context, index) {
                final news = _newsList[index];
                return Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          news['image'],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 60, color: Colors.grey),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8A2BE2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    news['category'],
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  news['date'],
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              news['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              news['content'],
                              style: TextStyle( // REMOVED const keyword here
                                fontSize: 14,
                                color: Colors.grey[700], // This works now
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Read More'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}