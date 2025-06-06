import 'package:flutter/material.dart';
import 'package:projects/Model/password.dart';
import 'EditPasswordPage.dart';
import 'package:projects/services/api_service.dart'; // needed for refetch
import 'dart:math';


// Helper function for Levenshtein Distance
int _levenshteinDistance(String s1, String s2) {
  s1 = s1.toLowerCase();
  s2 = s2.toLowerCase();

  final m = s1.length;
  final n = s2.length;
  final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));

  for (int i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (int j = 0; j <= n; j++) {
    dp[0][j] = j;
  }

  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      final cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
      dp[i][j] = min(
        dp[i - 1][j] + 1,      // Deletion
        min(
            dp[i][j - 1] + 1,    // Insertion
            dp[i - 1][j - 1] + cost // Substitution
        ),
      );
    }
  }
  return dp[m][n];
}

// Helper function to normalize domain names for comparison
String _normalizeDomain(String site) {
  try {
    Uri uri;
    // Attempt to prepend a scheme if missing, for reliable Uri parsing
    if (!site.startsWith('http://') && !site.startsWith('https://')) {
      uri = Uri.parse('https://$site'); // Use https as a default for parsing
    } else {
      uri = Uri.parse(site);
    }

    String host = uri.host;

    // Remove 'www.' prefix
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    // Convert to lowercase
    return host.toLowerCase();
  } catch (e) {
    // Fallback: if parsing fails (e.g., 'site' is not a valid URL-like string),
    // just return the lowercase version of the original string.
    // This is less robust but prevents crashes for malformed 'site' entries.
    print("Warning: Could not fully normalize site '$site'. Error: $e");
    return site.toLowerCase();
  }
}

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
  bool _isLoadingInitialFetch = true; // Indicates initial data fetch loading
  bool _isCheckingLeaks = false;      // Indicates HIBP check loading

  List<List<Password>> _confusableDomains = [];

  //Threshold for Levenshtein distance to consider domains confusable
  // A distance of 1 or 2 is generally a good starting point for typos.
  static const int _levenshteinThreshold = 2;

  @override
  void initState() {
    super.initState();
    // Initially, assign passwords from widget (pre-decrypted).
    // Start loading and checking process.
    _passwords = widget.passwords;
    _loadAndCheckPasswords();
  }

  // New method to handle both initial fetch and HIBP check sequentially
  Future<void> _loadAndCheckPasswords({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoadingInitialFetch = true; // Show full-page loading for initial fetch
      });
    }

    // Step 1: Fetch all passwords (this might be from your local DB or API)
    final fetchedPasswords = await ApiService.fetchPasswords();

    setState(() {
      _passwords = fetchedPasswords; // Update _passwords with newly fetched data
      _isLoadingInitialFetch = false; // Hide full-page loading once passwords are fetched
      _isCheckingLeaks = true;         // Start showing loading for leak check
      _confusableDomains = []; // Clear before recalculating
    });

    // Step 2: Check these passwords against the Have I Been Pwned API
    final updatedPasswordsWithPwnedStatus = await ApiService.checkPasswordsForBreaches(_passwords);
    // Step 3: Check for confusable domains
    final List<List<Password>> foundConfusableDomains = _findConfusableDomains(updatedPasswordsWithPwnedStatus);



    // After all checks are done, update the state and hide leak check loading
    setState(() {
      _passwords = updatedPasswordsWithPwnedStatus; // Update with pwned status
      _confusableDomains = foundConfusableDomains;   // Update with confusable domains
      _isCheckingLeaks = false;                       // Hide leak check loading
    });

    // Recalculate summary count after all updates
    _updateSummaryCount();
  }

  List<List<Password>> _findConfusableDomains(List<Password> passwords) {
    final List<List<Password>> confusableGroups = [];
    final Set<int> checkedPasswordIds = {}; // To avoid redundant checks and duplicate groups

    for (int i = 0; i < passwords.length; i++) {
      final p1 = passwords[i];
      if (checkedPasswordIds.contains(p1.id)) continue;

      final normalizedSite1 = _normalizeDomain(p1.site);

      final currentGroup = [p1];
      checkedPasswordIds.add(p1.id);

      for (int j = i + 1; j < passwords.length; j++) {
        final p2 = passwords[j];
        if (checkedPasswordIds.contains(p2.id)) continue;

        final normalizedSite2 = _normalizeDomain(p2.site);

        // Crucial: Only compare if normalized domains are actually different
        // to avoid comparing a site to itself if normalization yields identical string.
        if (normalizedSite1 == normalizedSite2) {
          continue; // These are effectively the same domain, not "confusable"
        }


        // Compare normalized site names
        final distance = _levenshteinDistance(normalizedSite1, normalizedSite2);

        if (distance > 0 && distance <= _levenshteinThreshold) {
          // If distance is 0, it's the exact same domain, which falls under "reused password"
          // We're interested in *similar* but *different* domains.
          currentGroup.add(p2);
          checkedPasswordIds.add(p2.id);
        }
      }

      if (currentGroup.length > 1) { // A group implies at least two confusable sites
        confusableGroups.add(currentGroup);
      }
    }
    return confusableGroups;
  }


  // Helper to update summary count and notify parent widget
  void _updateSummaryCount() {
    final repeatedMap = <String, List<Password>>{};
    final List<Password> weakPasswords = [];
    final List<Password> pwnedPasswords = [];

    for (var p in _passwords) {
      repeatedMap.putIfAbsent(p.password, () => []).add(p);
      final pw = p.password;
      final hasMinLength = pw.length >= 8;
      final hasLetter = pw.contains(RegExp(r'[A-Za-z]'));
      final hasDigit = pw.contains(RegExp(r'\d'));
      final hasSpecial = pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      final isWeak = !(hasMinLength && hasLetter && hasDigit && hasSpecial);
      if (isWeak) weakPasswords.add(p);
      if (p.isPwned) pwnedPasswords.add(p);
    }

    final repeatedPasswords = repeatedMap.values.where((list) => list.length > 1).toList();
    final newSummaryCount = repeatedPasswords.length + weakPasswords.length + pwnedPasswords.length;

    if (widget.onUpdated != null) {
      widget.onUpdated!(newSummaryCount);
    }
  }


  @override
  Widget build(BuildContext context) {
    // Show full page loading only during the initial data fetch
    if (_isLoadingInitialFetch) {
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
              Text("Loading passwords..."), // Specific text for initial load
            ],
          ),
        ),
      );
    }

    // Recalculate lists for display in build method
    final repeatedMap = <String, List<Password>>{};
    final List<Password> weakPasswords = [];
    final List<Password> pwnedPasswords = [];

    for (var p in _passwords) {
      // Reused Password check
      repeatedMap.putIfAbsent(p.password, () => []).add(p);

      // Weak Password check
      final pw = p.password;
      final hasMinLength = pw.length >= 8;
      final hasLetter = pw.contains(RegExp(r'[A-Za-z]'));
      final hasDigit = pw.contains(RegExp(r'\d'));
      final hasSpecial = pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      final isWeak = !(hasMinLength && hasLetter && hasDigit && hasSpecial);
      if (isWeak) weakPasswords.add(p);

      // Pwned Password check
      if (p.isPwned) {
        pwnedPasswords.add(p);
      }
    }

    final repeatedPasswords = repeatedMap.values.where((list) => list.length > 1).toList();
    final currentSummaryCount = repeatedPasswords.length + weakPasswords.length + pwnedPasswords.length + _confusableDomains.length;


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
              widget.onUpdated!(currentSummaryCount); // Pass current summary when navigating back
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAndCheckPasswords(isRefresh: true), // Call the combined load and check
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Pwned Passwords section
              const Text("🚨 Leaked Passwords",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text("HIGH PRIORITY RECOMMENDATIONS", style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500, color: Colors.red)),
              const Text(
                "These passwords have been found in known data breaches. "
                    "Change them immediately, even if they are strong.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),

              //Conditional loading for HIBP check
              if (_isCheckingLeaks) // Show specific loading indicator
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Checking for leaks..."),
                      ],
                    ),
                  ),
                )
              else if (pwnedPasswords.isEmpty) // Show 'no leaks' if not loading and empty
                const Padding(
                  padding: EdgeInsets.fromLTRB(50, 8, 8, 30),
                  child: Text("✅ No leaked passwords found."),
                )
              else // Display pwned passwords if not loading and not empty
                for (var p in pwnedPasswords)
                  Card(
                      shadowColor: Colors.red,
                      color: Colors.red.shade50,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditPasswordPage(password: p)),
                          );
                          if (updated == true) {
                            await _loadAndCheckPasswords(isRefresh: true); // Re-run all checks after update
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
                          subtitle: Text("User: ${p.username} (found ${p.pwnCount} times)"),
                          trailing: const Icon(Icons.security, color: Colors.red),
                        ),
                      )
                  ),
              const SizedBox(height: 20),

              // Reused Passwords section
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
                  shadowColor: Colors.yellow,
                  color: Colors.yellow.shade50,
                  child: ListTile(
                    title: Text("Used on ${list.length} sites"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: list.map((e) => Text("- ${e.site}")).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Weak Passwords section
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
                        await _loadAndCheckPasswords(isRefresh: true); // Re-run all checks after update
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
              const SizedBox(height: 20),

              // Confsable Domains Section
              const Text("⚠️ Confusable Domains",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text(
                "These sites have very similar addresses. This could indicate "
                    "a typo, or a potential phishing risk if you're not careful.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (_confusableDomains.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(50, 8, 8, 30),
                  child: Text("✅ No confusable domains found."),
                )
              else
                for (var group in _confusableDomains)
                  Card(
                    shadowColor: Colors.orange,
                    color: Colors.orange.shade50,
                    child: ListTile(
                      title: Text("Similar to: ${group.map((p) => p.site).join(', ')}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: group.map((p) => Text("- ${p.site} (User: ${p.username})")).toList(),
                      ),
                      trailing: const Icon(Icons.compare_arrows, color: Colors.orange),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }


}