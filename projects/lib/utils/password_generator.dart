//enforces at least one upper, lower, digit, and special character
import 'dart:math';

String generateStrongPassword({int length = 16}) {
  const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const lower = 'abcdefghijklmnopqrstuvwxyz';
  const digits = '0123456789';
  const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  const all = '$upper$lower$digits$symbols';

  final secureRandom = Random.secure(); // backed by system-level cryptography
  String getRandom(String chars) => chars[secureRandom.nextInt(chars.length)];

  // ensure at least one character from each group
  final passwordChars = <String>[
    getRandom(upper),
    getRandom(lower),
    getRandom(digits),
    getRandom(symbols),
  ];

  // fill the rest of the password length with random characters from all groups
  for (int i = passwordChars.length; i < length; i++) {
    passwordChars.add(getRandom(all));
  }

  // shuffle the result for randomness
  passwordChars.shuffle(secureRandom);

  return passwordChars.join();
}
