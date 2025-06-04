import 'package:flutter/material.dart';
import 'package:projects/services/api_service.dart';
import 'package:projects/utils/authenticateUserBiometrically.dart';
import 'package:projects/utils/password_strength_analyzer.dart';
import 'PasswordField.dart';
import 'package:projects/utils/password_generator.dart';


class AddModal extends StatefulWidget {
  final Function onAdded; // callback to reload list from parent

  const AddModal({super.key, required this.onAdded});

  @override
  State<AddModal> createState() => _AddModalState();
}

class _AddModalState extends State<AddModal> {
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();

  Map<String, String> _websiteLogos = {}; // all website logos available
  bool isLogosLoading = true;
  PasswordStrength _currentPasswordStrength = PasswordStrength.veryWeak;


  @override
  void initState() {
    super.initState();
    loadWebsiteLogos();
    _passwordController.addListener(_onPasswordChanged); // Add listener
    _onPasswordChanged(); // Initial check if password exists
  }

  @override void dispose() {
    _siteController.dispose();
    _usernameController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _logoUrlController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding (
      padding: const EdgeInsets.fromLTRB(10.0, 10, 10, 10),
      child: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: screenWidth * 0.4,
              height: 5,
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 156, 156, 156),
                  borderRadius: BorderRadius.circular(35)),
            ),
          ),
          SizedBox(
            height: 20,
          ),
        Align(
          alignment: Alignment.center,
            child: Text(
              "Add Password",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
            ),
          ),
          SizedBox( height: 20 ),
          Column(
            children: [
              formHeading("Website"),
              isLogosLoading
                  ? const Center(child: CircularProgressIndicator())
                  : searchTextWithSuggestions(),
              SizedBox(height: 10),
              formHeading("Username / E-mail"),
              formTextField("Enter Username or E-mail", Icons.alternate_email),
              formHeading("Password"),
              PasswordField(
                hintText: "Enter Password",
                icon: Icons.lock_outline,
                controller: _passwordController,
                onPasswordGenerated: (generatedPassword) {
                  setState(() {
                    _passwordController.text = generatedPassword;
                    _onPasswordChanged(); // Update strength after generation
                  });
                },
              ),
              // Password strength indicator
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 8.0, 30, 8.0),
                child: Row(
                  children: [
                    // Wrap Text in SizedBox for a fixed width
                    SizedBox(
                      width: 90,
                      child: Text(
                        '${PasswordStrengthAnalyzer.getStrengthText(_currentPasswordStrength)}',
                        style: TextStyle(
                          color: PasswordStrengthAnalyzer.getStrengthColor(_currentPasswordStrength),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _currentPasswordStrength.index / (PasswordStrength.values.length - 1),
                        backgroundColor: Colors.grey[300],
                        color: PasswordStrengthAnalyzer.getStrengthColor(_currentPasswordStrength),
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final generated = generateStrongPassword();
                  setState(() {
                    _passwordController.text = generated;
                    _onPasswordChanged();
                  });
                },
                icon: Icon(Icons.refresh, size: 16),
                label: Text("Generate strong password"),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  foregroundColor: Color.fromARGB(255, 55, 114, 255),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 50,
          ),
          SizedBox(
            height: screenHeight * 0.055,
            width: screenWidth * 0.5,
            child: ElevatedButton(
                style: ButtonStyle(
                    elevation: WidgetStatePropertyAll(5),
                    shadowColor:
                    WidgetStatePropertyAll(Color.fromARGB(255, 55, 114, 255)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35),
                            side:
                            BorderSide(color: Color.fromARGB(255, 55, 114, 255)))),
                    backgroundColor:
                    WidgetStatePropertyAll(Color.fromARGB(255, 55, 114, 255))),
                onPressed: () async {
                  final site = _siteController.text.trim();
                  final username = _usernameController.text.trim();
                  final password = _passwordController.text.trim();
                  final logoUrl = _logoUrlController.text.trim().isNotEmpty
                      ? _logoUrlController.text.trim()
                      : 'https://www.pngplay.com/wp-content/uploads/6/Mobile-Application-Blue-Icon-Transparent-PNG.png';

                  if (site.isEmpty || username.isEmpty || password.isEmpty) { // use case to complete all fields
                    showDialog(
                      context: context,
                      barrierDismissible: false, // prevent tapping outside to close immediately
                      builder: (BuildContext context) {
                        Future.delayed(Duration(seconds: 2), () {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
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
                          backgroundColor: Color.fromARGB(255, 50, 50, 50), // darker modern background
                          elevation: 8,
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    );
                    if (!mounted) return;
                  }

                  //check the user biometrics
                  final isAuthenticated = await authenticateUserBiometrically();

                  if (!isAuthenticated) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Biometric authentication failed")),
                    );
                    return;
                  }

                  final result = await ApiService.addPassword(site, username, password, logoUrl);

                  if (result != null && mounted) {
                    widget.onAdded();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Password added successfully")),
                    );
                  } else if (mounted){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to add password")),
                    );
                  }
                }
                ,
                child: Text(
                    "Done",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  )
                ),
           ),
          SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  Widget formTextField(String hintText, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        controller: _usernameController,
        maxLength: 30,
        decoration: InputDecoration(
          counterText: "",
          prefixIcon: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 5, 5, 5), // add padding to adjust icon
            child: Icon(
              icon,
              color: Color.fromARGB(255, 82, 101, 120),
            ),
          ),
          filled: true,
          contentPadding: EdgeInsets.all(16),
          hintText: hintText,
          hintStyle: TextStyle(
              color: Color.fromARGB(255, 82, 101, 120), fontWeight: FontWeight.w500),
          fillColor: Color.fromARGB(247, 232, 235, 237),
          border: OutlineInputBorder(
              borderSide: BorderSide(
                width: 0,
                style: BorderStyle.none,
              ),
              borderRadius: BorderRadius.circular(35))),
         style: TextStyle(),
      ),
    );
  }

  Widget formHeading(String text) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 10, 10, 10),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  Widget searchTextWithSuggestions() {
    final websites = _websiteLogos.keys.toList();
    List<String> filteredWebsites = websites
        .where((site) => site.toLowerCase().contains(_siteController.text.toLowerCase()))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          TextFormField(
            controller: _siteController,
            maxLength: 50,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.fromLTRB(20, 5, 5, 5),
                child: Icon(
                  Icons.search,
                  color: Color.fromARGB(255, 82, 101, 120),
                ),
              ),
              filled: true,
              contentPadding: EdgeInsets.all(16),
              hintText: "Search or type website",
              hintStyle: TextStyle(
                color: Color.fromARGB(255, 82, 101, 120),
                fontWeight: FontWeight.w500,
              ),
              fillColor: Color.fromARGB(247, 232, 235, 237),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(35),
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          if (_siteController.text.isNotEmpty && filteredWebsites.isNotEmpty)
            Container(
              constraints: BoxConstraints(maxHeight: 150),
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
                        _siteController.text = suggestion;
                        _siteController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _siteController.text.length),
                        );
                        _logoUrlController.text = _websiteLogos[suggestion] ?? '';
                      });
                      FocusScope.of(context).unfocus(); // hide keyboard
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
        isLogosLoading = false; // after logos are fetched
      });
    } catch (e) {
      print('Error loading logos: $e');
      setState(() {
        isLogosLoading = false; // even if error, allow UI to proceed
      });
    }
  }

  void _onPasswordChanged() {
    setState(() {
      _currentPasswordStrength = PasswordStrengthAnalyzer.analyze(_passwordController.text);
    });
  }
}