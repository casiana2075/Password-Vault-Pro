class Password {
  final int id;
  final String site;
  final String username;
  final String password;
  final String createdAt;
  final String logoUrl;

  Password({
    required this.id,
    required this.site,
    required this.username,
    required this.password,
    required this.createdAt,
    required this.logoUrl,
  });

  factory Password.fromJson(Map<String, dynamic> json) {
    return Password(
      id: json['id'],
      site: json['site'],
      username: json['username'],
      password: json['password'],
      createdAt: json['created_at'],
      logoUrl: json['logoURL'],
    );
  }
}
