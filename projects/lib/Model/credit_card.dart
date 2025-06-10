class CreditCard {
  final int id;
  final String cardHolderName;
  final String cardNumber;
  final String expiryDate;
  final String cvv;
  final String? notes; // Nullable
  final String? type; // Nullable (e.g., Visa, Mastercard)

  CreditCard({
    required this.id,
    required this.cardHolderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    this.notes,
    this.type,
  });

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'],
      cardHolderName: json['card_holder_name'],
      cardNumber: json['card_number'],
      expiryDate: json['expiry_date'],
      cvv: json['cvv'],
      notes: json['notes'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_holder_name': cardHolderName,
      'card_number': cardNumber,
      'expiry_date': expiryDate,
      'cvv': cvv,
      'notes': notes,
      'type': type,
    };
  }

  CreditCard copyWith({
    int? id,
    String? cardHolderName,
    String? cardNumber,
    String? expiryDate,
    String? cvv,
    String? notes,
    String? type,
  }) {
    return CreditCard(
      id: id ?? this.id,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      notes: notes ?? this.notes,
      type: type ?? this.type,
    );
  }
}