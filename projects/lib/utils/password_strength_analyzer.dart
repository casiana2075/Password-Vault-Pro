import 'dart:ui';

import 'package:flutter/material.dart';

enum PasswordStrength {
  veryWeak,
  weak,
  fair,
  good,
  strong,
  veryStrong,
}

class PasswordStrengthAnalyzer {
  static PasswordStrength analyze(String password) {
    if (password.isEmpty) return PasswordStrength.veryWeak;

    int score = 0;

    // Length
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;

    // Character diversity
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasLowercase) score += 1;
    if (hasUppercase) score += 1;
    if (hasDigits) score += 1;
    if (hasSpecial) score += 1;

    // Combinations of character types
    int charTypeCount = 0;
    if (hasLowercase) charTypeCount++;
    if (hasUppercase) charTypeCount++;
    if (hasDigits) charTypeCount++;
    if (hasSpecial) charTypeCount++;
    if (charTypeCount >= 3) score += 1;
    if (charTypeCount >= 4) score += 1;

    // Penalties for common patterns (simplified)
    // You might add more sophisticated checks like common passwords, sequential chars, etc.
    if (password.contains(RegExp(r'123')) || password.contains(RegExp(r'abc'))) score -= 1;
    if (password.toLowerCase().contains(password.toLowerCase().substring(0,2) * 2) && password.length > 3) score -=1; // penalize 'aaaa'


    // Map score to strength enum
    if (score <= 1) return PasswordStrength.veryWeak;
    if (score == 2) return PasswordStrength.weak;
    if (score == 3) return PasswordStrength.fair;
    if (score == 4) return PasswordStrength.good;
    if (score >= 5 && score < 7) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  // You can also add a method to get a human-readable text for the strength
  static String getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak: return "Very Weak";
      case PasswordStrength.weak: return "Weak";
      case PasswordStrength.fair: return "Fair";
      case PasswordStrength.good: return "Good";
      case PasswordStrength.strong: return "Strong";
      case PasswordStrength.veryStrong: return "Very Strong";
    }
  }

  static Color getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.veryWeak: return Colors.red;
      case PasswordStrength.weak: return Colors.orange;
      case PasswordStrength.fair: return Colors.yellow;
      case PasswordStrength.good: return Colors.lightGreen;
      case PasswordStrength.strong: return Colors.green;
      case PasswordStrength.veryStrong: return Colors.blue; // Or dark green
    }
  }
}