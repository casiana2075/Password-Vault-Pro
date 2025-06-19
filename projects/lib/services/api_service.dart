import 'dart:convert';
import 'dart:io'; // For HttpClient
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // for IOClient
import '../Model/password.dart';
import '../Model/credit_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';

class ApiService {
  static const String baseUrl = 'https://10.0.2.2:3001'; // HTTPS for emulator
  //static const String baseUrl = 'https://192.168.0.108:3001'; // HTTPS for device


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

  static Future<int> checkPasswordForBreach(String password) async {
    if (password.isEmpty) return 0;

    // 1. Hash the password using SHA-1
    final bytes = utf8.encode(password); // data being hashed
    final digest = sha1.convert(bytes); // SHA-1 hash

    // Convert hash to uppercase hex string
    final String sha1Hash = digest.toString().toUpperCase();

    // 2. Take the first 5 characters as the prefix
    final String prefix = sha1Hash.substring(0, 5);
    final String suffix = sha1Hash.substring(5);

    final String apiUrl = 'https://api.pwnedpasswords.com/range/$prefix';

    try {
      // Use the default http client for HIBP, not your custom _client
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // 3. The API returns a list of suffixes and their counts, one per line
        final String responseBody = response.body;
        final List<String> lines = responseBody.split('\r\n');

        // 4. Search locally for the full hash's suffix
        for (String line in lines) {
          final parts = line.split(':');
          if (parts.length == 2) {
            final String retrievedSuffix = parts[0];
            final int count = int.tryParse(parts[1]) ?? 0;

            if (retrievedSuffix == suffix) {
              // 5. Found a match! This password has been pwned.
              return count; // Return the number of times it was found
            }
          }
        }
        // If loop completes, suffix not found for this prefix
        return 0;
      } else if (response.statusCode == 400) {
        print('HIBP API Bad Request (likely invalid prefix): $prefix');
        return 0; // Or throw an error if you want to handle it specifically
      } else {
        print('HIBP API error: ${response.statusCode} - ${response.body}');
        return 0; // Treat as not found if API error
      }
    } catch (e) {
      print('Error checking password with HIBP: $e');
      return 0; // Treat as not found on network/other error
    }
  }

  // method to check a list of passwords
  static Future<List<Password>> checkPasswordsForBreaches(List<Password> passwords) async {
    // Create a deep copy to avoid modifying the original list directly while iterating
    List<Password> passwordsToCheck = passwords.map((p) => p.copyWith(
      id: p.id,
      site: p.site,
      username: p.username,
      password: p.password, // This will be the plain-text password
      logoUrl: p.logoUrl,
      isPwned: p.isPwned,
      pwnCount: p.pwnCount,
    )).toList();


    for (var p in passwordsToCheck) {
      if (p.password.isNotEmpty) { // Only check non-empty passwords
        // Introduce a small delay to avoid hitting HIBP rate limits too quickly
        await Future.delayed(Duration(milliseconds: 50));
        final pwnCount = await checkPasswordForBreach(p.password);
        if (pwnCount > 0) {
          p.isPwned = true;
          p.pwnCount = pwnCount;
        } else {
          p.isPwned = false;
          p.pwnCount = 0;
        }
      } else {
        p.isPwned = false;
        p.pwnCount = 0;
      }
    }
    return passwordsToCheck; // Return the list with updated pwned statuses
  }

  static Future<bool> deleteUser(String uid) async {
    final token = await _getIdToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/users/$uid'),
      headers: {'Authorization': token ?? ''},
    );

    return response.statusCode == 200;
  }

  //  Methods for Credit Cards -------------
  static Future<List<CreditCard>> fetchCreditCards() async {
    final token = await _getIdToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/credit_cards'),
      headers: {'Authorization': token ?? ''},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => CreditCard.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load credit cards: ${response.statusCode} ${response.body}');
    }
  }

  static Future<bool> addCreditCard({
    required String cardHolderName,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    String? notes,
    String? type,
  }) async {
    final token = await _getIdToken();
    final response = await _client.post(
      Uri.parse('$baseUrl/credit_cards'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
      body: jsonEncode({
        'card_holder_name': cardHolderName,
        'card_number': cardNumber,
        'expiry_date': expiryDate,
        'cvv': cvv,
        'notes': notes,
        'type': type,
      }),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print('Failed to add credit card: ${response.statusCode} ${response.body}');
      return false;
    }
  }

  static Future<CreditCard?> updateCreditCard({
    required int id,
    required String cardHolderName,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    String? notes,
    String? type,
  }) async {
    final token = await _getIdToken();
    final response = await _client.put(
      Uri.parse('$baseUrl/credit_cards/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
      body: jsonEncode({
        'card_holder_name': cardHolderName,
        'card_number': cardNumber,
        'expiry_date': expiryDate,
        'cvv': cvv,
        'notes': notes,
        'type': type,
      }),
    );

    if (response.statusCode == 200) {
      return CreditCard.fromJson(jsonDecode(response.body));
    } else {
      print('Failed to update credit card: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  static Future<bool> deleteCreditCard(int id) async {
    final token = await _getIdToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/credit_cards/$id'),
      headers: {'Authorization': token ?? ''},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to delete credit card: ${response.statusCode} ${response.body}');
      return false;
    }
  }
}