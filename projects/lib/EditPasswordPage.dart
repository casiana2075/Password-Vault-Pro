import 'package:flutter/material.dart';
import 'package:projects/Model/password_fields.dart';
import 'package:projects/PasswordField.dart';

class EditPasswordPage extends StatefulWidget {
  final passwords password;

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
    websiteController = TextEditingController(text: widget.password.websiteName);
    emailController = TextEditingController(text: widget.password.email);
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
              const SizedBox(height: 30),
              SizedBox(
                height: screenHeight * 0.055,
                width: screenWidth * 0.5,
                child: ElevatedButton(
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
                      widget.password.websiteName = websiteController.text.trim();
                      widget.password.email = emailController.text.trim();
                      widget.password.password = passwordController.text.trim();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              )
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
