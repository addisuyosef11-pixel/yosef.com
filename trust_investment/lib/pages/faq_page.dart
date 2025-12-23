import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FAQPage extends HookWidget {
  final String token;
  const FAQPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final expandedIndex = useState<int?>(null);
    
    final faqs = [
      {
        'question': 'How do I start earning daily income?',
        'answer': 'Purchase either a Main Project or Welfare Product package. After payment confirmation, you can claim daily income every 24 hours from your Profile page.'
      },
      {
        'question': 'What is the difference between Main Project and Welfare Product?',
        'answer': 'Main Project offers higher daily income rates (1.5% daily) while Welfare Product offers slightly lower rates (0.8% daily). Both provide daily income for 365 days.'
      },
      {
        'question': 'When can I withdraw my earnings?',
        'answer': 'You can withdraw your available balance anytime. Frozen balance becomes available after 24 hours. Minimum withdrawal is 50 Birr.'
      },
      {
        'question': 'How do I recharge my account?',
        'answer': 'Go to Recharge page, select amount, choose payment method (Bank Transfer or TeleBirr), complete payment, and wait for confirmation.'
      },
      {
        'question': 'What is the 24-hour claim interval?',
        'answer': 'You can claim daily income once every 24 hours. The timer resets after each claim. Missed days cannot be claimed later.'
      },
      {
        'question': 'How do I invite friends and earn referral bonuses?',
        'answer': 'Share your unique invitation code from your Profile. When friends register using your code and make purchases, you earn referral bonuses.'
      },
      {
        'question': 'What happens if I miss a daily claim?',
        'answer': 'The income for that day is forfeited. You can only claim income for the current day during the 24-hour window.'
      },
      {
        'question': 'How long does withdrawal processing take?',
        'answer': 'Withdrawals are processed within 24 hours during business days. Weekends and holidays may cause slight delays.'
      },
      {
        'question': 'Can I purchase multiple packages?',
        'answer': 'Yes, you can purchase multiple Main Project and Welfare Product packages. Each package generates separate daily income.'
      },
      {
        'question': 'How do I contact customer support?',
        'answer': 'Use the Customer Service option in your Profile to connect with our Telegram support team for immediate assistance.'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF8A2BE2),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 16,
              16,
              20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF8A2BE2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search FAQs...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // FAQ List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: faqs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final faq = faqs[index];
                        final isExpanded = expandedIndex.value == index;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: Colors.white,
                            collapsedBackgroundColor: Colors.white,
                            initiallyExpanded: index == 0,
                            onExpansionChanged: (expanded) {
                              expandedIndex.value = expanded ? index : null;
                            },
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8A2BE2).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF8A2BE2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              faq['question']!,
                              style: const TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Icon(
                              isExpanded ? Icons.remove : Icons.add,
                              color: const Color(0xFF8A2BE2),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                                child: Text(
                                  faq['answer']!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Need Help Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8A2BE2).withOpacity(0.1),
                            const Color(0xFF9C27B0).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8A2BE2).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.help_outline,
                            color: Color(0xFF8A2BE2),
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Still need help?',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Contact our customer support team for personalized assistance.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // You can navigate to Telegram page directly if needed
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8A2BE2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text('Contact Support'),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}