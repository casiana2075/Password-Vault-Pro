import 'dart:convert';
import 'dart:io'; // For HttpClient
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // for IOClient
import '../Model/password.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static const String baseUrl = 'https://10.0.2.2:3000'; // HTTPS for emulator

  // Create a custom HTTP client that allows self-signed certificates
  static final http.Client _client = () {
    final httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true; // Accept self-signed certificates
    return IOClient(httpClient); // Use IOClient to wrap HttpClient
  }();

  static Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  static Future<List<Password>> fetchPasswords() async {
    final token = await _getIdToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/passwords'),
      headers: {'Authorization': token ?? ''},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Password.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load passwords: ${response.statusCode}');
    }
  }

  static Future<bool> deletePassword(int id) async {
    final token = await _getIdToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/passwords/$id'),
      headers: {'Authorization': token ?? ''},
    );

    return response.statusCode == 200;
  }

  static Future<Password?> addPassword(String site, String username, String rawPassword, [String? logoUrl]) async {
    final token = await _getIdToken();

    final response = await _client.post(
      Uri.parse('$baseUrl/passwords'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
      body: jsonEncode({
        'site': site,
        'username': username,
        'password': rawPassword,
        'logoUrl': logoUrl,
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
      int id, String site, String username, String newRawPassword, String logoUrl) async {
    final token = await _getIdToken();

    final response = await _client.put(
      Uri.parse('$baseUrl/passwords/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
      body: jsonEncode({
        'site': site,
        'username': username,
        'password': newRawPassword,
        'logoUrl': logoUrl,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> createOrFetchUser() async {
    final token = await _getIdToken();
    final url = Uri.parse('$baseUrl/users');

    final response = await _client.get(
      url,
      headers: {
        'Authorization': token ?? '',
      },
    );

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
    final response = await _client.get(
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