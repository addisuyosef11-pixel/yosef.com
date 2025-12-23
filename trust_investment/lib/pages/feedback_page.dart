import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FeedbackPage extends HookWidget {
  final String token;
  const FeedbackPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final feedbackController = useTextEditingController();
    final rating = useState<int>(0);
    final category = useState<String>('General');
    final isLoading = useState<bool>(false);
    final isSubmitted = useState<bool>(false);

    final categories = [
      'General',
      'Technical Issue',
      'Payment Issue',
      'Suggestion',
      'Complaint',
      'Feature Request'
    ];

    Future<void> _submitFeedback() async {
      if (feedbackController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your feedback'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      isLoading.value = true;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      isLoading.value = false;
      isSubmitted.value = true;

      // Clear form
      feedbackController.clear();
      rating.value = 0;
      category.value = 'General';

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }

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
                  'Feedback',
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Share Your Thoughts',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Help us improve TESLAX with your valuable feedback',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Category Selection
                    const Text(
                      'Category',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = category.value == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) => category.value = cat,
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(0xFF8A2BE2),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Rating
                    const Text(
                      'How would you rate your experience?',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return IconButton(
                          onPressed: () => rating.value = starIndex,
                          icon: Icon(
                            starIndex <= rating.value
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFFFA726),
                            size: 40,
                          ),
                        );
                      }),
                    ),
                    
                    if (rating.value > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            '${rating.value} star${rating.value == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: Color(0xFFFFA726),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Feedback Form
                    const Text(
                      'Your Feedback',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: feedbackController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          hintText: 'Tell us what you think...\n• What do you like?\n• What can be improved?\n• Any issues you faced?',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Please be specific and include details to help us understand your feedback better.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Submission Status
                    if (isSubmitted.value)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Thank you for your feedback! Our team will review it and work on improvements.',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (isSubmitted.value) const SizedBox(height: 20),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading.value ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A2BE2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF8A2BE2).withOpacity(0.4),
                        ),
                        child: isLoading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Feedback',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Additional Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFF8A2BE2), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'What happens next?',
                                style: TextStyle(
                                  color: Color(0xFF333333),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Our team reviews all feedback daily\n'
                            '• We prioritize issues based on user impact\n'
                            '• You may receive follow-up questions\n'
                            '• Major updates are announced in-app',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                              height: 1.6,
                            ),
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