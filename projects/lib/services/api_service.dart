import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/password.dart';
import '../utils/EncryptionHelper.dart';
import '../utils/SecureKeyManager.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // for emulator(10.0.2.2:3000)

  static Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  static Future<List<Password>> fetchPasswords() async {
    final token = await _getIdToken();
    final response = await http.get(
      Uri.parse('$baseUrl/passwords'),
      headers: {'Authorization': token ?? ''},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Password.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load passwords');
    }
  }

  static Future<bool> deletePassword(int id) async {
    final token = await _getIdToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/passwords/$id'),
      headers: {'Authorization': token ?? ''},
    );

    return response.statusCode == 200;
  }

  static Future<Password?> addPassword(String site, String username, String rawPassword, [String? logoUrl]) async {
    final token = await _getIdToken();

    final aesKey = await SecureKeyManager.getOrCreateUserKey();
    final encryptedPassword = EncryptionHelper.encryptText(rawPassword, aesKey);

    final response = await http.post(
      Uri.parse('$baseUrl/passwords'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
      body: jsonEncode({
        "site": site,
        "username": username,
        "password": encryptedPassword,
        "logoUrl": logoUrl,
      }),
    );

    if (response.statusCode == 201) {
      return Password.fromJson(jsonDecode(response.body));
    } else {
      print('Add failed: ${response.body}');
      return null;
    }
  }


  static Future<bool> updatePassword(
      int id,
      String site,
      String username,
      String newRawPassword,
      String logoUrl
      ) async {
    final token = await _getIdToken();
    final aesKey = await SecureKeyManager.getOrCreateUserKey();
    final encryptedPassword = EncryptionHelper.encryptText(newRawPassword, aesKey);

    final response = await http.put(
      Uri.parse('$baseUrl/passwords/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
      body: jsonEncode({
        'site': site,
        'username': username,
        'password': encryptedPassword,
        'logoUrl': logoUrl,
      }),
    );

    return response.statusCode == 200;
  }


  static Future<Map<String, dynamic>?> createOrFetchUser() async {
    final token = await _getIdToken();
    final url = Uri.parse('$baseUrl/users');

    final response = await http.get(url, headers: {
      'Authorization': token ?? '',
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('User creation/fetch failed: ${response.body}');
      return null;
    }
  }


  static Future<Map<String, String>> fetchWebsiteLogos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      throw Exception('Failed to retrieve ID token');
    }
    final url = Uri.parse('$baseUrl/logos');
    final response = await http.get(
      url,
      headers: {
        'Authorization': idToken,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> logos = json.decode(response.body);
      return {
        for (var logo in logos)
          if (logo['site_name'] != null && logo['logo_url'] != null)
            logo['site_name'].toString().toLowerCase(): logo['logo_url'].toString()
      };
    } else {
      throw Exception('Failed to fetch logos: ${response.statusCode}');
    }
  }
}

