import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:projects/AddModal.dart';
import 'package:projects/Model/password.dart';
import 'package:projects/SecurityRecomPage.dart';
import 'package:projects/EditPasswordPage.dart';
import 'package:projects/LoginPage.dart';
import 'package:projects/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<int, bool> selectedPasswords = {};

  List<Password> _allPasswords = [];
  List<Password> _filteredPasswords = []; // visible list
  final TextEditingController _searchController = TextEditingController();

  static bool isInDeleteMode = false;
  bool isLoading = true;
  int summaryCount = 0; // store the summary count


  @override
  void initState() {
    super.initState();
    loadPasswords();
  }

  @override
  Widget build(BuildContext context) {
    final String plusAsset = 'assets/plus.svg'; // #757575
    final String deleteAsset = 'assets/delete.svg';
    final String lockAsset = 'assets/lock.svg';
    final String copyAsset = 'assets/copy.svg';
    final String editAsset = 'assets/edit.svg';
    final String cancelAsset = 'assets/cancel.svg';


    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              profilePicAddDeleteIcons(
                  plusAsset, deleteAsset, cancelAsset, screenHeight, context),
              searchBar("Search Password", _searchController, _filterPasswords),
              securityRecommendations(lockAsset, summaryCount),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 25, 0, 5),
                child: Row(
                  children: [
                    Text(
                      "Passwords",
                      style: TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _filteredPasswords.isEmpty ? Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    _allPasswords.isEmpty
                        ? "🔐 No passwords stored yet!"
                        : "🤔 No matches found.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // optional
                itemCount: _filteredPasswords.length,
                itemBuilder: (context, index) {
                  final password = _filteredPasswords[index];
                  return passwordSection(password, context, index);
                },
              ),
              if (selectedPasswords.containsValue(true) && isInDeleteMode)
                ElevatedButton(
                  onPressed: () => deleteSelectedPasswords(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Delete Selected"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget circleAvatarRound() {
    final User? user = FirebaseAuth.instance.currentUser;
    String? photoUrl;

    if (user != null) {
      photoUrl = user.photoURL;
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: const Color(0xFFBABABA),
      child: CircleAvatar(
        radius: 27.5,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: user != null && photoUrl != null
              ? CircleAvatar(
            backgroundImage: NetworkImage(photoUrl),
            radius: 28,
            onBackgroundImageError: (exception, stackTrace) {
            },
          )
              : const CircleAvatar(
            backgroundImage: AssetImage('assets/profile.jpg'),
            radius: 28,
          ),
        ),
      ),
    );
  }

  Widget profilePicAddDeleteIcons(String plusAsset, String deleteAsset,
      String cancelAsset, double screenHeight, BuildContext context) {
    String getGreeting() {
      int hour = DateTime
          .now()
          .hour;
      if (hour >= 3 && hour < 11) {
        return "Good morning";
      } else if (hour >= 11 && hour < 17) {
        return "Good afternoon";
      } else {
        return "Good evening";
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 25, 10, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded( // Wrap the profile row in Expanded
            child: Row( // Profile row
              children: [
                GestureDetector(
                  onTap: () {
                    _showProfileMenu(context);
                  },
                  child: circleAvatarRound(),
                ),
              Expanded( // Add Expanded here to allow text to shrink
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello ${_getUserName()}",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis, // Add overflow handling
                        maxLines: 1, // Limit to one line
                      ),
                      Text(
                        getGreeting(),
                        style: const TextStyle(
                          color: Color(0xFFBABABA),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],),
          ),
          Row(
            children: [
              _hoverButton(plusAsset, screenHeight, () => bottomModal(context)),
              if (isInDeleteMode)
                _hoverButton(cancelAsset, screenHeight, () => deletePasswordsState())
              else
                _hoverButton(deleteAsset, screenHeight, () => deletePasswordsState()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hoverButton(String asset, double screenHeight, VoidCallback onTap,
      [String? password]) {
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (details) {},
          child: InkWell(
            borderRadius: BorderRadius.circular(35),
            splashColor: Colors.blue[200],
            onTap: () {
              if (asset.contains('plus')) {
                bottomModal(context);
              }
              else if (asset.contains('delete') || asset.contains('cancel')) {
                deletePasswordsState();
              }
              else if (asset.contains('copy') && password != null) {
                copyPassword(context, password);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(0, 186, 186, 186),
                borderRadius: BorderRadius.circular(35),
              ),
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  SvgPicture.asset(
                    asset,
                    height: 25,
                    width: 25,
                    colorFilter: const ColorFilter.mode(
                        Colors.black45, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget searchBar(String hintText, TextEditingController controller,
      Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          contentPadding: EdgeInsets.all(13),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Color.fromARGB(255, 154, 153, 153),
            fontWeight: FontWeight.w500,
          ),
          fillColor: Color.fromARGB(63, 186, 186, 186),
          prefixIcon: Padding(
            padding: EdgeInsets.fromLTRB(25, 0, 3, 0),
            child: Icon(Icons.search),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(35),
          ),
        ),
        style: TextStyle(),
      ),
    );
  }

  Widget securityRecommendations(String icon, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: GestureDetector(
        onTapDown: (details) {},
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          splashColor: Colors.black12,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SecurityRecomPage(
                  passwords: _allPasswords,
                  onUpdated: (int newCount) async {
                    await loadPasswords(); // Re-fetch passwords
                    setState(() {
                      summaryCount = newCount; // Update summaryCount
                    });
                  },
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(63, 186, 186, 186),
              borderRadius: BorderRadius.circular(35),
            ),
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
            child: Row(
              children: [
                SvgPicture.asset(
                  icon,
                  height: 22,
                  width: 22,
                  colorFilter: const ColorFilter.mode(
                      Colors.black, BlendMode.srcIn),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Security Recommendations",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      count == 0
                          ? "No security risks found"
                          : "Security risks found",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Color.fromARGB(255, 120, 120, 120),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  "$count",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.black),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget passwordSection(Password password, BuildContext context, int index) {
    double screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Padding(
      padding: const EdgeInsets.fromLTRB(25.0, 10, 25.0, 10),
      child: InkWell(
        onTap: () async {
          // navigate to EditPasswordPage
          final updated = await Navigator.push(
            context,
            MaterialPageRoute( //give reference to password item
              builder: (context) => EditPasswordPage(password: password),
            ),
          );

          if (updated == true) {
            await loadPasswords(); // re-fetch from the database
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Password updated or deleted")),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(123, 220, 220, 220),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Profile row
              Expanded(
                child: Row(
                  children: [
                    if (isInDeleteMode)
                      Checkbox(
                        value: selectedPasswords[password.id] ?? false,
                        shape: const CircleBorder(),
                        onChanged: (value) {
                          setState(() {
                            selectedPasswords[password.id] = value ?? false;
                          });
                        },
                      ),
                    logoBox(password),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15.0, 0, 8, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _highlight(
                              password.site,
                              const TextStyle(
                                color: Color.fromARGB(255, 22, 22, 22),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.ellipsis, // Add overflow handling
                              ),
                              context,
                            ),
                            const SizedBox(height: 4),
                            _highlight(
                                password.username,
                                const TextStyle(
                                  color: Color.fromARGB(255, 39, 39, 39),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                context
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _hoverButton(
                  'assets/copy.svg', screenHeight, () {}, password.password),
            ],
          ),
        ),
      ),
    );
  }

  Widget logoBox(Password password) {
    return Container(
      height: 55,
      width: 55,
      decoration: BoxDecoration(
        color: Color.fromARGB(0, 239, 239, 239),
        borderRadius: BorderRadius.circular(50),
      ),
      child: FractionallySizedBox(
        heightFactor: 0.8,
        widthFactor: 0.8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.network(
            password.logoUrl,
            fit: BoxFit.cover, // make sure image fits within clipped bounds
          ),
        ),
      ),
    );
  }

  Widget _highlight(String source, TextStyle baseStyle, BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return Text(source, style: baseStyle);
    }

    final matches = source.toLowerCase().indexOf(query);
    if (matches < 0) {
      return Text(source, style: baseStyle);
    }

    return RichText(
      textHeightBehavior: TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
      strutStyle: StrutStyle(
        forceStrutHeight: true,
        height: 1.0, // force consistent line height
      ),
      text: TextSpan(
        style: baseStyle, // main style
        children: [
          TextSpan(text: source.substring(0, matches)),
          TextSpan(
            text: source.substring(matches, matches + query.length),
            style: baseStyle.copyWith(
              backgroundColor: const Color.fromARGB(150, 118, 191, 255),
            ),
          ),
          TextSpan(text: source.substring(matches + query.length)),
        ],
      ), textScaler: TextScaler.linear(MediaQuery
          .of(context)
          .textScaleFactor),
    );
  }

  void deleteSelectedPasswords() async {
    List<int> idsToDelete = selectedPasswords.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    // confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete ${idsToDelete
              .length} selected password(s)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Delete from DB
    for (int id in idsToDelete) {
      final success = await ApiService.deletePassword(id);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete item with id: $id")),
        );
      }
    }

    // refresh homepage
    setState(() {
      loadPasswords();
      selectedPasswords.clear();
      isInDeleteMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Deleted ${idsToDelete.length} password(s)")),
    );
  }

  void deletePasswordsState() {
    setState(() {
      isInDeleteMode = !isInDeleteMode;
    });
  }

  void copyPassword(BuildContext context, String decryptedPassword) async {
    try {
      if (decryptedPassword.trim().isEmpty) { // Using decryptedPassword directly
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password is empty, nothing to copy."),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // No decryption needed here, use the already decrypted password
      await Clipboard.setData(ClipboardData(text: decryptedPassword));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password copied to clipboard"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(seconds: 30), () async {
        final currentClipboard = await Clipboard.getData('text/plain');
        if (currentClipboard?.text == decryptedPassword) {
          await Clipboard.setData(const ClipboardData(text: ""));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to copy password: $e"), // Renamed print message
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _filterPasswords(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredPasswords = _allPasswords.where((p) =>
      p.site.toLowerCase().contains(lowerQuery) ||
          p.username.toLowerCase().contains(lowerQuery)).toList();
    });
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.logout, color: Colors.blue),
                title: Text('Logout', style: TextStyle(color: Colors.blue)),
                onTap: () {
                  Navigator.pop(context);
                  logout();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text('Delete Account', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteAccount(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Account"),
          content: Text(
            "This will permanently delete your account and all your saved passwords. This action cannot be undone. Are you sure?",
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount(context);
              },
            ),
          ],
        );
      },
    );
  }

  String _getUserName() {
    // Get the currently logged-in user
    final User? user = FirebaseAuth.instance.currentUser;

    // Check if a user is logged in and has an email
    if (user != null && user.email != null) {
      final String email = user.email!;

      // Split the email address at the "@" symbol
      final List<String> parts = email.split('@');

      // Check if the email was split into parts
      if (parts.isNotEmpty) {
        // Return the first part (the user's name/identifier)
        return parts[0];
      }
    }

    // Return nothing if the user is not logged in or has no email
    return "";
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Deleting account..."),
            ],
          ),
        ),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        navigator.pop();
        throw Exception("No user signed in");
      }

      final String uid = user.uid;

      // Delete from backend first (this will delete passwords + user in DB)
      final backendDeleted = await ApiService.deleteUser(uid);
      if (!backendDeleted) {
        navigator.pop();
        throw Exception("Failed to delete user from server");
      }

      // Delete Firebase account
      await user.delete();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Sign out/disconnect from Google if needed
      try {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      } catch (e) {
        print("Google sign out error: $e");
      }

      navigator.pop(); // Close loading dialog

      // Navigate to login
      if (context.mounted) {
        navigator.pop(); // Close the loading dialog

        // Add a short delay to allow dialog closing to complete
        await Future.delayed(Duration(milliseconds: 100));

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
                (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      navigator.pop();
      // Handle re-authentication required etc.
      print("Firebase error: $e");
    } catch (e) {
      navigator.pop();
      print("Error deleting account: $e");
    }
  }


  Future<dynamic> bottomModal(BuildContext context) {
    return showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25.0),
                  topRight: Radius.circular(25.0),
                ),
              ),
              child: AddModal(
                onAdded: () async {
                  await loadPasswords(); //re-fetch data from the DB
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> loadPasswords() async {
    try {
      final fetched = await ApiService.fetchPasswords(); // Fetches decrypted passwords
      // Calculate initial summaryCount
      final repeatedMap = <String, List<Password>>{};
      final List<Password> weakPasswords = [];

      // Passwords are already decrypted from the API call
      for (var p in fetched) { // Use 'fetched' directly
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

      if (mounted) {
        setState(() {
          _allPasswords = fetched; // Store decrypted passwords
          _filteredPasswords = fetched;
          summaryCount = newSummaryCount;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load passwords: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> logout() async {
    try {
      // firebase logout
      await FirebaseAuth.instance.signOut();

      // google SignOut
      await GoogleSignIn().signOut();

      // clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // navigate to login page
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginPage()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Logout error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: ${e.toString()}")),
      );
    }
  }

}