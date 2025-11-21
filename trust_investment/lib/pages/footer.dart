import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        children: [
          const Text(
            "© 2025 Trust Investment. All rights reserved.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterLink("About Us"),
              _dot(),
              _buildFooterLink("Contact"),
              _dot(),
              _buildFooterLink("Privacy Policy"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: const TextStyle(color: Colors.blueAccent, fontSize: 14),
      ),
    );
  }

  Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text("•", style: TextStyle(color: Colors.black38)),
    );
  }
}
