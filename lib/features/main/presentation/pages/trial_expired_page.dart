
import 'package:flutter/material.dart';

class TrialExpiredPage extends StatelessWidget {
  const TrialExpiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_rounded, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                "TRIAL EXPIRED",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                "Your 30-day trial for Svenska Industrial Suite has ended. Please contact your service provider to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8B949E), height: 1.5),
              ),
              const SizedBox(height: 32),
              const Divider(color: Color(0xFF30363D)),
              const SizedBox(height: 20),
              const Text(
                "CONTACT FOR ACTIVATION:",
                style: TextStyle(color: Color(0xFF00FFFF), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("support@svenska.com", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}