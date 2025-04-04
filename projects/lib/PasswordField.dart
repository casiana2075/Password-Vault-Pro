import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class PasswordField extends StatefulWidget {
  final String hintText;
  final IconData icon;

  const PasswordField({Key? key, required this.hintText, required this.icon}) : super(key: key);

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true; // Toggles password visibility
  final LocalAuthentication auth = LocalAuthentication();
  Timer? _hidePasswordTimer;
  DateTime? _lastAuthTime;

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: "Authenticate to view password",
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/password fallback
        ),
      );
    } catch (e) {
      print("Authentication error: $e");
    }

    if (authenticated) {
      setState(() {
        _obscureText = false;
        _lastAuthTime = DateTime.now();
      });

      // timer to hide the password after 30 seconds
      _hidePasswordTimer?.cancel(); // Cancel any existing timer
      _hidePasswordTimer = Timer(const Duration(seconds: 30), () {
        setState(() {
          _obscureText = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _hidePasswordTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        obscureText: _obscureText,
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
            child: Icon(
              widget.icon,
              color: const Color.fromARGB(255, 82, 101, 120),
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: const Color.fromARGB(255, 82, 101, 120),
            ),
            onPressed: () async {
              if (_obscureText) {
                // if password is hidden, check if 30 seconds have passed
                if (_lastAuthTime != null &&
                    DateTime.now().difference(_lastAuthTime!).inSeconds < 30) {
                  setState(() {
                    _obscureText = false;
                  });
                } else {
                  await _authenticate();
                }
              } else {
                setState(() {
                  _obscureText = true;
                });
              }
            },
          ),
          filled: true,
          contentPadding: const EdgeInsets.all(16),
          hintText: widget.hintText,
          hintStyle: const TextStyle(
              color: Color.fromARGB(255, 82, 101, 120), fontWeight: FontWeight.w500),
          fillColor: const Color.fromARGB(247, 232, 235, 237),
          border: OutlineInputBorder(
            borderSide: const BorderSide(
              width: 0,
              style: BorderStyle.none,
            ),
            borderRadius: BorderRadius.circular(35),
          ),
        ),
      ),
    );
  }
}
