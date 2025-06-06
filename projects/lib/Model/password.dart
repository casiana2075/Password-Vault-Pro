class Password {
  final int id;
  final String site;
  final String username;
  String password;
  final String logoUrl;
  bool isPwned;
  int pwnCount;

  Password({
    required this.id,
    required this.site,
    required this.username,
    required this.password,
    required this.logoUrl,
    this.isPwned = false, // Default to false
    this.pwnCount = 0,
  });

  factory Password.fromJson(Map<String, dynamic> json) {
    return Password(
      id: json['id'],
      site: json['site'],
      username: json['username'],
      password: json['password'],
      logoUrl: json['logourl'],
      isPwned: json['isPwned'] ?? false, // Handle if not present in JSON
      pwnCount: json['pwnCount'] ?? 0,    // Handle if not present in JSON
    );
  }

  Password copyWith({
    int? id,
    String? site,
    String? username,
    String? password,
    String? logoUrl,
    bool? isPwned,
    int? pwnCount,
  }) {
    return Password(
      id: id ?? this.id,
      site: site ?? this.site,
      username: username ?? this.username,
      password: password ?? this.password,
      logoUrl: logoUrl ?? this.logoUrl,
      isPwned: isPwned ?? this.isPwned,
      pwnCount: pwnCount ?? this.pwnCount,
    );
  }
}
