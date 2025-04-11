import 'package:flutter/material.dart';
import 'package:projects/Model/password.dart';
import 'package:projects/PasswordField.dart';
import 'package:projects/services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    websiteController = TextEditingController(text: widget.password.site);
    emailController = TextEditingController(text: widget.password.username);
    passwordController = TextEditingController(text: widget.password.password);
  }

  @override
  void dispose() {
    websiteController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

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
              _formTextField("Enter website name", Icons.language, websiteController),
              _formHeading("Email"),
              _formTextField("Enter email", Icons.email, emailController),
              _formHeading("Password"),
              PasswordField(
                hintText : "Enter password", icon: Icons.lock_outline, controller: passwordController),
              SizedBox(
                height: 50,
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
                onPressed: () {
                  setState(() { // save updated data
                    //save logic here!!!!!
                  });
                  Navigator.pop(context);
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
        decoration: InputDecoration(
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
}
