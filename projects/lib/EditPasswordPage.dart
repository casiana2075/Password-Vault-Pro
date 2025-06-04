import 'package:flutter/material.dart';
import 'package:projects/Model/password.dart';
import 'package:projects/PasswordField.dart';
import 'package:projects/services/api_service.dart';
import 'package:projects/utils/password_generator.dart';

class EditPasswordPage extends StatefulWidget {
  final Password password;

  const EditPasswordPage({super.key, required this.password});

  @override
  _EditPasswordPageState createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  late TextEditingController websiteController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController logoUrlController;

  Map<String, String> _websiteLogos = {};
  bool isLoadingLogos = true;

  @override
  void initState() {
    super.initState();
    websiteController = TextEditingController(text: widget.password.site);
    emailController = TextEditingController(text: widget.password.username);
    logoUrlController = TextEditingController(text: widget.password.logoUrl);
    passwordController = TextEditingController(text: widget.password.password);

    loadWebsiteLogos();
  }

  @override
  void dispose() {
    websiteController.dispose();
    emailController.dispose();
    passwordController.dispose();
    logoUrlController.dispose();
    super.dispose();
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
        iconTheme: IconThemeData(color: Colors.black87),
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
              PasswordField(
                hintText: "Enter password",
                icon: Icons.lock_outline,
                controller: passwordController,
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  final generated = generateStrongPassword();
                  setState(() {
                    passwordController.text = generated;
                  });
                },
                icon: Icon(Icons.refresh, size: 16),
                label: Text("Generate strong password"),
                style: TextButton.styleFrom(
                  foregroundColor: Color.fromARGB(255, 55, 114, 255),
                ),
              ),
              SizedBox(
                height: 30,
              ),
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
                onPressed: () async { // edit password data
                  final site = websiteController.text.trim();
                  final username = emailController.text.trim();
                  final password = passwordController.text.trim();
                  final logoUrl = logoUrlController.text.trim();

                  //no empty fields
                  if (site.isEmpty || username.isEmpty || password.isEmpty) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        Future.delayed(Duration(seconds: 2), () {
                          if (mounted) Navigator.of(context).pop();
                        });
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          content: Container(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
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
                          backgroundColor: Color.fromARGB(255, 50, 50, 50),
                          elevation: 8,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    );
                    return;
                  }

                  final updated = await ApiService.updatePassword(
                    widget.password.id,
                    site,
                    username,
                    password,
                    logoUrl,
                  );

                  if (updated) {
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to update password")),
                    );
                  }
                },
                child: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              SizedBox(
                height: 10,
              ),
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
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Deletion'),
                        content: const Text('Are you sure you want to delete this password?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false), // Cancel
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(true), // Confirm
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    final success = await ApiService.deletePassword(widget.password.id);

                    if (success) {
                      Navigator.pop(context, true); // remove the password here
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to delete password")),
                      );
                    }
                  }

                },
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
              prefixIcon: Padding(
                padding: const EdgeInsets.fromLTRB(20, 5, 5, 5),
                child: Icon(
                  Icons.language,
                  color: const Color.fromARGB(255, 82, 101, 120),
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
