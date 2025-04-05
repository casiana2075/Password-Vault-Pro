import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class PasswordField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final TextEditingController? controller;

  const PasswordField({
    super.key,
    required this.hintText,
    required this.icon,
    this.controller,
  });

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;
  final LocalAuthentication auth = LocalAuthentication();
  Timer? _hidePasswordTimer;
  DateTime? _lastAuthTime;
  late final TextEditingController _controller;
  bool _readOnly = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();

    // If password exists, start in protected mode
    if (_controller.text.trim().isNotEmpty) {
      _readOnly = true;
      _obscureText = true;
    } else {
      _readOnly = false;
      _obscureText = false;
    }
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: "Authenticate to view password",
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      print("Authentication error: $e");
    }

    if (authenticated) {
      setState(() {
        _obscureText = false;
        _readOnly = false;
        _lastAuthTime = DateTime.now();
      });

      _hidePasswordTimer?.cancel();
      _hidePasswordTimer = Timer(const Duration(seconds: 30), () {
        setState(() {
          _obscureText = true;
          _readOnly = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _hidePasswordTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose(); // only dispose internal controller
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        controller: _controller,
        obscureText: _obscureText,
        readOnly: _readOnly,
        onTap: () async {
          if (_readOnly && _obscureText) {
            await _authenticate();
          }
        },
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
                if (_lastAuthTime != null &&
                    DateTime.now().difference(_lastAuthTime!).inSeconds < 30) {
                  setState(() {
                    _obscureText = false;
                    _readOnly = false;
                  });
                } else {
                  await _authenticate();
                }
              } else {
                setState(() {
                  _obscureText = true;
                  _readOnly = true;
                });
              }
            },
          ),
          filled: true,
          contentPadding: const EdgeInsets.all(16),
          hintText: _controller.text.isEmpty ? widget.hintText : null,
          hintStyle: const TextStyle(
            color: Color.fromARGB(255, 82, 101, 120),
            fontWeight: FontWeight.w500,
          ),
          fillColor: const Color.fromARGB(247, 232, 235, 237),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(35),
          ),
        ),
      ),
    );
  }
}
