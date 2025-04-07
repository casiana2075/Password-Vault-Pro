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
}
