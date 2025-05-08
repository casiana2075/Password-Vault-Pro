import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projects/Model/password.dart';
import 'EditPasswordPage.dart';
import 'package:projects/services/api_service.dart'; // needed for refetch
import 'package:projects/utils/EncryptionHelper.dart';
import 'package:projects/utils/SecureKeyManager.dart';


class SecurityRecomPage extends StatefulWidget {
  final List<Password> passwords;
  final void Function(int)? onUpdated; // Update to accept an int parameter

  const SecurityRecomPage({
    super.key,
    required this.passwords,
    this.onUpdated,
  });

  @override
  State<SecurityRecomPage> createState() => _SecurityRecomPageState();
}

class _SecurityRecomPageState extends State<SecurityRecomPage> {
  late List<Password> _passwords;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _decryptPasswords();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Security Recommendations",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading..."),
            ],
          ),
        ),
      );
    }

    final repeatedMap = <String, List<Password>>{};
    final List<Password> weakPasswords = [];

    for (var p in _passwords) {
      repeatedMap.putIfAbsent(p.password, () => []).add(p);

      final pw = p.password;
      final hasMinLength = pw.length >= 8;
      final hasLetter = pw.contains(RegExp(r'[A-Za-z]'));
      final hasDigit = pw.contains(RegExp(r'\d'));
      final hasSpecial = pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      final isWeak = !(hasMinLength && hasLetter && hasDigit && hasSpecial);
      if (isWeak) weakPasswords.add(p);
    }

    final repeatedPasswords =
    repeatedMap.values.where((list) => list.length > 1).toList();

    final summaryCount = repeatedPasswords.length + weakPasswords.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Security Recommendations",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onUpdated != null) {
              widget.onUpdated!(summaryCount); // Pass summaryCount when navigating back
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshPasswords(summaryCount),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text("🔁 Reused Passwords",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (repeatedPasswords.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(50, 8, 8, 30),
                  child: Text("✅ No password was used twice."),
                ),
              for (var list in repeatedPasswords)
                Card(
                  child: ListTile(
                    title: Text("Used on ${list.length} sites"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: list.map((e) => Text("- ${e.site}")).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text("🛡 Weak Passwords",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text(
                "A strong password should contain at least 8 characters, "
                    "including letters, numbers, and special characters.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (weakPasswords.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(50, 8, 8, 30),
                  child: Text("✅ No weak passwords found."),
                ),
              for (var p in weakPasswords)
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditPasswordPage(password: p)),
                      );

                      if (updated == true) {
                        final newCount = await _refreshPasswords(summaryCount);
                        if (widget.onUpdated != null) {
                          widget.onUpdated!(newCount); // Pass updated summaryCount
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Password updated successfully"),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(bottom: 80.0, right: 20, left: 20),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: ListTile(
                      title: Text(p.site),
                      subtitle: Text("User: ${p.username}"),
                      trailing: const Icon(Icons.warning, color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> _refreshPasswords(int currentCount) async {
    setState(() {
      _isLoading = true; // set loading state during refresh
    });

    final updatedPasswords = await ApiService.fetchPasswords();
    final aesKey = await SecureKeyManager.getOrCreateUserKey();

    final decryptedPasswords = updatedPasswords.map((p) {
      final decryptedPw = EncryptionHelper.decryptText(p.password, aesKey);
      return p.copyWith(password: decryptedPw);
    }).toList();

    // Recalculate summaryCount
    final repeatedMap = <String, List<Password>>{};
    final List<Password> weakPasswords = [];

    for (var p in decryptedPasswords) {
      repeatedMap.putIfAbsent(p.password, () => []).add(p);
      final pw = p.password;
      final hasMinLength = pw.length >= 8;
      final hasLetter = pw.contains(RegExp(r'[A-Za-z]'));
      final hasDigit = pw.contains(RegExp(r'\d'));
      final hasSpecial = pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      final isWeak = !(hasMinLength && hasLetter && hasDigit && hasSpecial);
      if (isWeak) weakPasswords.add(p);
    }

    final repeatedPasswords =
    repeatedMap.values.where((list) => list.length > 1).toList();
    final newSummaryCount = repeatedPasswords.length + weakPasswords.length;

    setState(() {
      _passwords = decryptedPasswords;
      _isLoading = false; // clear loading state after decryption
    });

    return newSummaryCount; // Return the updated count
  }

  Future<void> _decryptPasswords() async {
    final aesKey = await SecureKeyManager.getOrCreateUserKey();

    final decryptedPasswords = widget.passwords.map((p) {
      final decryptedPw = EncryptionHelper.decryptText(p.password, aesKey);
      return p.copyWith(password: decryptedPw);
    }).toList();

    setState(() {
      _passwords = decryptedPasswords;
      _isLoading = false; // clear loading state after decryption
    });
  }
}