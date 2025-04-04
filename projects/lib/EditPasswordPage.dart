import 'package:flutter/material.dart';
import 'package:projects/Model/password_fields.dart';

class EditPasswordPage extends StatefulWidget {
  final passwords password;

  const EditPasswordPage({Key? key, required this.password}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Password",
          style:TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: websiteController,
              decoration: const InputDecoration(labelText: "Website Name"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle update logic here (save changes)
                Navigator.pop(context); // Go back to the previous page
              },
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}
