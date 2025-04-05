import 'package:flutter/material.dart';

class SecurityRecomPage extends StatelessWidget {
  const SecurityRecomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Security Recommendations",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Text(
          "Here are your security recommendations!",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
