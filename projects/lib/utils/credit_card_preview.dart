import 'package:flutter/material.dart';

class CreditCardPreview extends StatelessWidget {
  final String cardNumber;
  final String cardHolderName;
  final String expiryDate;
  final String cardType;

  const CreditCardPreview({
    super.key,
    this.cardNumber = '•••• •••• •••• ••••', // Default masked number
    this.cardHolderName = 'CARD HOLDER',
    this.expiryDate = 'MM/YY',
    this.cardType = '', // Default empty type
  });

  // Helper to mask card number for display on the preview
  String _formatCardNumber(String number) {
    if (number.isEmpty) return '•••• •••• •••• ••••';
    // Remove all non-digit characters
    String cleanNumber = number.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += cleanNumber[i];
    }
    // Pad with dots if less than 16 characters for visual consistency
    if (formatted.length < 19) { // 16 digits + 3 spaces = 19 chars
      int remainingDots = (19 - formatted.length).clamp(0, 19);
      formatted += '•' * remainingDots;
    }
    return formatted;
  }

  // Helper to return an icon based on card type for the preview
  Widget _getCardTypeIcon(String type) {
    String lowerType = type.toLowerCase();
    IconData iconData;
    Color iconColor;

    if (lowerType.contains('visa')) {
      iconData = Icons.payments; // A more specific payment icon
      iconColor = Colors.white; // For contrast on dark card
    } else if (lowerType.contains('mastercard')) {
      iconData = Icons.credit_score;
      iconColor = Colors.white;
    } else if (lowerType.contains('amex') || lowerType.contains('american express')) {
      iconData = Icons.wallet;
      iconColor = Colors.white;
    } else if (lowerType.contains('discover')) {
      iconData = Icons.money;
      iconColor = Colors.white;
    } else if (lowerType.contains('jcb')) {
      iconData = Icons.card_membership;
      iconColor = Colors.white;
    } else if (lowerType.contains('diners club')) {
      iconData = Icons.credit_card;
      iconColor = Colors.white;
    } else if (lowerType.contains('unionpay')) {
      iconData = Icons.account_balance_wallet;
      iconColor = Colors.white;
    }
    else {
      iconData = Icons.credit_card; // Default icon
      iconColor = Colors.white;
    }
    return Icon(iconData, color: iconColor, size: 30);
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200, // Fixed height for a consistent card size
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent, // A nice vibrant color
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        // You could add a subtle gradient here for more realism
        gradient: const LinearGradient(
          colors: [
            Colors.deepPurple,
            Colors.purpleAccent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Card chip
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber[300],
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.nfc, color: Colors.black87), // NFC icon for chip
            ),
          ),
          // Card type icon
          Positioned(
            top: 20,
            right: 20,
            child: _getCardTypeIcon(cardType),
          ),
          // Card Number
          Positioned(
            top: 90,
            left: 20,
            right: 20,
            child: Text(
              _formatCardNumber(cardNumber),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                fontFamily: 'monospace', // A monospaced font looks good for numbers
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Card Holder Name
          Positioned(
            bottom: 30,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CARD HOLDER',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cardHolderName.toUpperCase().isEmpty ? 'CARD HOLDER' : cardHolderName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Expiry Date
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXPIRES',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expiryDate.isEmpty ? 'MM/YY' : expiryDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}