import 'package:flutter/material.dart';
import 'package:projects/services/api_service.dart';
import 'PasswordField.dart';

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

  @override
  void initState() {
    super.initState();
    loadWebsiteLogos();
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
          SizedBox( height: 30 ),
          isLogosLoading
              ? const Center(child: CircularProgressIndicator())
              : searchTextWithSuggestions(),
          SizedBox( height: 10 ),
          Column(
            children: [
              formHeading("Username / E-mail"),
              formTextField("Enter Username or E-mail", Icons.alternate_email),
              formHeading("Password"),
              PasswordField(
                  hintText: "Enter Password",
                  icon: Icons.lock_outline,
                  controller: _passwordController,
              )
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

                  if (site.isEmpty || username.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please fill in all fields")),
                    );
                    return;
                  }

                  final result = await ApiService.addPassword(site, username, password, logoUrl);

                  if (result != null) {
                    widget.onAdded();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Password added successfully")),
                    );
                  } else {
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
        decoration: InputDecoration(
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

}