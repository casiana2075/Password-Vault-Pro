import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/password.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000'; // use 10.0.2.2 for emulator

  static Future<List<Password>> fetchPasswords() async {
    final response = await http.get(Uri.parse('$baseUrl/passwords'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Password.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load passwords');
    }
  }

  static Future<bool> deletePassword(int id) async {
    final url = Uri.parse('$baseUrl/passwords/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to delete: ${response.statusCode}');
      return false;
    }
  }

  static Future<Password?> addPassword(String site, String username, String password, [String? logoUrl]) async {
    final url = Uri.parse('$baseUrl/passwords');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "site": site,
        "username": username,
        "password": password,
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

  static Future<bool> updatePassword(int id, String site, String username, String password) async {
    final url = Uri.parse('$baseUrl/passwords/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'site': site,
        'username': username,
        'password': password,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, String>> fetchWebsiteLogos() async {
    final url = Uri.parse('$baseUrl/logos');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> logos = json.decode(response.body);

      //filter only entries where name and url are not null
      return {
        for (var logo in logos)
          if (logo['site_name'] != null && logo['logo_url'] != null)
            logo['site_name'].toString().toLowerCase(): logo['logo_url'].toString()
      };
    } else {
      throw Exception('Failed to fetch logos');
    }
  }

}
