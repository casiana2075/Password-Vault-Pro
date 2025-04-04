import 'package:flutter/material.dart';
import 'PasswordField.dart';

class AddModal extends StatelessWidget {
  const AddModal({super.key});

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
          SizedBox(
            height: 30,
          ),
          searchText("Search for a website or app"),
          SizedBox(
            height: 10,
          ),
          Column(
            children: [
              formHeading("Username"),
              formTextField("Enter Username", Icons.person),
              formHeading("E-mail"),
              formTextField("Enter Email", Icons.email),
              formHeading("Password"),
              PasswordField(hintText: "Enter Password", icon: Icons.lock_outline)
            ],
          ),
          SizedBox(
            height: 50,
          ),
          Container(
            height: screenHeight * 0.055,
            width: screenWidth * 0.5,
            child: ElevatedButton(
                style: ButtonStyle(
                    elevation: MaterialStatePropertyAll(5),
                    shadowColor:
                    MaterialStatePropertyAll(Color.fromARGB(255, 55, 114, 255)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35),
                            side:
                            BorderSide(color: Color.fromARGB(255, 55, 114, 255)))),
                    backgroundColor:
                    MaterialStatePropertyAll(Color.fromARGB(255, 55, 114, 255))),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Done",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                )),
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

  Widget searchText(String hintText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        decoration: InputDecoration(
            prefixIcon: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 5, 5, 5), // add padding to adjust icon
              child: Icon(
                Icons.search,
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
}