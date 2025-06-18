import 'package:flutter/material.dart';
import 'package:projects/Model/password.dart';
import 'package:projects/PasswordField.dart';
import 'package:projects/services/api_service.dart';
import 'package:projects/utils/password_generator.dart';
import 'package:url_launcher/url_launcher.dart';

class EditPasswordPage extends StatefulWidget {
  final Password password;

  const EditPasswordPage({super.key, required this.password});

  @override
  _EditPasswordPageState createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> with WidgetsBindingObserver {
  late TextEditingController websiteController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController logoUrlController;

  Map<String, String> _websiteLogos = {};
  bool isLoadingLogos = true;
  bool _isLoading = false;
  bool _justLaunchedUrl = false;

  // Store the original password to detect changes
  late String _originalPassword;
  bool _passwordChangedExternally = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    websiteController = TextEditingController(text: widget.password.site);
    emailController = TextEditingController(text: widget.password.username);
    logoUrlController = TextEditingController(text: widget.password.logoUrl);
    passwordController = TextEditingController(text: widget.password.password);

    // Store the original password for comparison
    _originalPassword = widget.password.password;

    loadWebsiteLogos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    websiteController.dispose();
    emailController.dispose();
    passwordController.dispose();
    logoUrlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app resumes after launching a URL, check if password needs updating
    if (state == AppLifecycleState.resumed && _justLaunchedUrl) {
      _justLaunchedUrl = false;
      _checkForPasswordChange();
    }
  }

  /// Enhanced URL launching with better error handling and validation
  Future<void> _launchUrl() async {
    String url = websiteController.text.trim();

    // Validate that we have a website URL to launch
    if (url.isEmpty) {
      _showErrorSnackBar('Please enter a website URL first');
      return;
    }

    // Ensure the URL has a proper scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        _justLaunchedUrl = true;
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Try with www prefix as fallback
        final Uri fallbackUri = Uri.parse('https://www.${websiteController.text.trim()}');
        if (await canLaunchUrl(fallbackUri)) {
          _justLaunchedUrl = true;
          await launchUrl(
            fallbackUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw Exception('Unable to launch URL');
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
      _showErrorSnackBar('Could not open website. Please check the URL format.');
      _justLaunchedUrl = false;
    }
  }

  /// Check if the password might have been changed externally
  void _checkForPasswordChange() {
    // Show a more intelligent dialog that offers to detect password changes
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Password Update Check'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Did you update your password on the website?'),
              const SizedBox(height: 10),
              const Text(
                'If you changed your password, please update it here to keep your records synchronized.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No Changes'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _highlightPasswordField();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 55, 114, 255),
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Update Password'),
            ),
          ],
        );
      },
    );
  }

  /// Highlight the password field to draw user attention
  void _highlightPasswordField() {
    // Clear the current password to encourage user to enter the new one
    setState(() {
      passwordController.clear();
      _passwordChangedExternally = true;
    });

    // Show a helpful message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter your new password below'),
        backgroundColor: Color.fromARGB(255, 55, 114, 255),
      ),
    );
  }

  /// Helper method to show error messages consistently
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Password",
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _formHeading("Website"),
              isLoadingLogos
                  ? const Center(child: CircularProgressIndicator())
                  : searchWebsiteField(),

              _formHeading("Username / Email"),
              _formTextField("Enter username / email", Icons.email, emailController),

              _formHeading("Password"),
              // Add visual indicator if password was changed externally
              if (_passwordChangedExternally)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enter your updated password',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              PasswordField(
                hintText: "Enter password",
                icon: Icons.lock_outline,
                controller: passwordController,
              ),

              const SizedBox(height: 10),

              // Generate Password Button
              _actionButton(
                onPressed: () {
                  final generated = generateStrongPassword();
                  setState(() {
                    passwordController.text = generated;
                    _passwordChangedExternally = false; // Reset the flag
                  });
                },
                icon: Icons.refresh,
                label: "Generate strong password",
                color: const Color.fromARGB(255, 55, 114, 255),
              ),

              const SizedBox(height: 10),

              // Open Website Button
              _actionButton(
                onPressed: _launchUrl,
                icon: Icons.open_in_browser,
                label: "Open website",
                color: const Color.fromARGB(255, 76, 175, 80), // Green color for website action
              ),

              const SizedBox(height: 30),

              // Save Changes Button
              ElevatedButton(
                style: ButtonStyle(
                  elevation: const WidgetStatePropertyAll(5),
                  shadowColor: const WidgetStatePropertyAll(Color.fromARGB(255, 55, 114, 255)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                      side: const BorderSide(color: Color.fromARGB(255, 55, 114, 255)),
                    ),
                  ),
                  backgroundColor: const WidgetStatePropertyAll(Color.fromARGB(255, 55, 114, 255)),
                ),
                onPressed: _saveChanges,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),

              const SizedBox(height: 10),

              // Delete Password Button
              ElevatedButton(
                style: ButtonStyle(
                  elevation: const WidgetStatePropertyAll(5),
                  shadowColor: const WidgetStatePropertyAll(Color.fromARGB(255, 255, 55, 55)),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                      side: const BorderSide(color: Color.fromARGB(255, 255, 55, 55)),
                    ),
                  ),
                  backgroundColor: const WidgetStatePropertyAll(Color.fromARGB(255, 255, 55, 55)),
                ),
                onPressed: _deletePassword,
                child: const Text(
                  "Delete Password",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable action button widget for consistent styling
  Widget _actionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Handle saving password changes with validation
  Future<void> _saveChanges() async {
    final site = websiteController.text.trim();
    final username = emailController.text.trim();
    final password = passwordController.text.trim();
    final logoUrl = logoUrlController.text.trim();

    // Validate required fields
    if (site.isEmpty || username.isEmpty || password.isEmpty) {
      _showValidationDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updated = await ApiService.updatePassword(
        widget.password.id,
        site,
        username,
        password,
        logoUrl,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (updated) {
          // Update the original password reference for future comparisons
          _originalPassword = password;
          _passwordChangedExternally = false;
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar("Failed to update password");
        }
      }
    } catch (e) {
      print('Error updating password: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error updating password: $e');
      }
    }
  }

  /// Handle password deletion with confirmation
  Future<void> _deletePassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this password? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final success = await ApiService.deletePassword(widget.password.id);

      if (success) {
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar("Failed to delete password");
      }
    }
  }

  /// Show validation dialog for empty fields
  void _showValidationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: const Text(
              "⚠ Please fill in all fields ⚠",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 50, 50, 50),
          elevation: 8,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _formTextField(String hintText, IconData icon, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        controller: controller,
        maxLength: 30,
        decoration: InputDecoration(
          counterText: "",
          prefixIcon: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 82, 101, 120),
            ),
          ),
          filled: true,
          contentPadding: const EdgeInsets.all(16),
          hintText: hintText,
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
        style: const TextStyle(),
      ),
    );
  }

  Widget _formHeading(String text) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 15, 10, 5),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  Widget searchWebsiteField() {
    final websites = _websiteLogos.keys.toList();
    List<String> filteredWebsites = websites
        .where((site) => site.toLowerCase().contains(websiteController.text.toLowerCase()))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          TextFormField(
            controller: websiteController,
            maxLength: 50,
            decoration: InputDecoration(
              counterText: "",
              prefixIcon: const Padding(
                padding: EdgeInsets.fromLTRB(20, 5, 5, 5),
                child: Icon(
                  Icons.language,
                  color: Color.fromARGB(255, 82, 101, 120),
                ),
              ),
              filled: true,
              contentPadding: const EdgeInsets.all(16),
              hintText: "Search or type website",
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
            onChanged: (value) {
              setState(() {}); // Refresh suggestions
            },
          ),
          if (websiteController.text.isNotEmpty && filteredWebsites.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredWebsites.length,
                itemBuilder: (context, index) {
                  final suggestion = filteredWebsites[index];
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(_websiteLogos[suggestion]!),
                      backgroundColor: Colors.transparent,
                    ),
                    title: Text(suggestion),
                    onTap: () {
                      setState(() {
                        websiteController.text = suggestion;
                        websiteController.selection = TextSelection.fromPosition(
                          TextPosition(offset: websiteController.text.length),
                        );
                        logoUrlController.text = _websiteLogos[suggestion] ?? '';
                      });
                      FocusScope.of(context).unfocus(); // Close keyboard and dropdown
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> loadWebsiteLogos() async {
    try {
      final logos = await ApiService.fetchWebsiteLogos();
      setState(() {
        _websiteLogos = logos;
        isLoadingLogos = false;
      });
    } catch (e) {
      print('Failed to load logos: $e');
      setState(() {
        isLoadingLogos = false;
      });
    }
  }
}