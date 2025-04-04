// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class passwords {
  String websiteName;
  String email;
  String logoUrl;
  String password;

  passwords(
      this.websiteName,
      this.email,
      this.logoUrl,
      this.password
      );

  passwords copyWith({
    String? websiteName,
    String? email,
    String? logoUrl,
  }) {
    return passwords(
      websiteName ?? this.websiteName,
      email ?? this.email,
      logoUrl ?? this.logoUrl,
      password ?? this.password
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'websiteName': websiteName,
      'email': email,
      'logoUrl': logoUrl,
    };
  }

  factory passwords.fromMap(Map<String, dynamic> map) {
    return passwords(
      map['websiteName'] as String,
      map['email'] as String,
      map['logoUrl'] as String,
      map['password'] as String
    );
  }

  String toJson() => json.encode(toMap());

  factory passwords.fromJson(String source) => passwords.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'passwords(websiteName: $websiteName, email: $email, logoUrl: $logoUrl)';

  @override
  bool operator ==(covariant passwords other) {
    if (identical(this, other)) return true;

    return
      other.websiteName == websiteName &&
          other.email == email &&
          other.logoUrl == logoUrl;
  }

  @override
  int get hashCode => websiteName.hashCode ^ email.hashCode ^ logoUrl.hashCode;
}