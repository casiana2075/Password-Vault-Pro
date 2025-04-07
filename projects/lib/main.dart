import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projects/AddModal.dart';
import 'package:projects/Model/password_fields.dart';
import 'package:projects/Model/password.dart';
import 'package:projects/constants.dart';
import 'package:projects/SecurityRecomPage.dart';
import 'package:projects/EditPasswordPage.dart';
import 'package:projects/services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // root of the application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<int, bool> selectedPasswords = {};
  static bool isInDeleteMode = false;

  List<Password> _passwords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPasswords();
  }

  void loadPasswords() async {
    try {
      _passwords = await ApiService.fetchPasswords();
    } catch (e) {
      print('Error loading: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String plusAsset = 'assets/plus.svg'; // #757575
    final String deleteAsset = 'assets/delete.svg';
    final String lockAsset = 'assets/lock.svg';
    final String copyAsset = 'assets/copy.svg';
    final String editAsset = 'assets/edit.svg';
    final String cancelAsset = 'assets/cancel.svg';

    double screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children : [
              profilePicAddDeleteIcons(plusAsset, deleteAsset,cancelAsset, screenHeight, context),
              searchBar("Search Password"),
              securityRecommendations(lockAsset, 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 25, 0, 5),
                child: Row(
                  children: [
                    Text(
                      "Passwords",
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: Constants.passwordData.length,
                  itemBuilder: (context, index) {
                    final password = Constants.passwordData[index];
                    return passwordSection(password, context, index);
                  }),
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

  Widget circleAvatarRound(){
    return CircleAvatar(
        radius: 30,
        backgroundColor: Color(0xFFBABABA),
        child: CircleAvatar(
            radius: 27.5,
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(3),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/profile.jpg'),
                radius: 28,
              ),
            )
        )
    );
  }

  Widget profilePicAddDeleteIcons(String plusAsset, String deleteAsset, String cancelAsset, double screenHeight, BuildContext context){
    String getGreeting() {
      int hour = DateTime.now().hour;
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
          Row( // Profile row
            children: [
              circleAvatarRound(),
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Hello Cass",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      getGreeting(),
                      style: const TextStyle(
                        color: Color(0xFFBABABA),
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              _hoverButton(plusAsset, screenHeight, () => bottomModal(context)),
              if (isInDeleteMode)
                _hoverButton(cancelAsset, screenHeight, () => deletePasswordsState() )
              else
                _hoverButton(deleteAsset, screenHeight, ()=> deletePasswordsState())
            ],
          ),
        ],
      ),
    );
  }

  Widget _hoverButton(String asset, double screenHeight, VoidCallback onTap, [String? password]) {
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (details) {},
          child: InkWell(
            borderRadius: BorderRadius.circular(35),
            splashColor: Colors.blue[200],
            onTap: () {
              if (asset.contains('plus')){
                bottomModal(context);
              }
              else if (asset.contains('delete') || asset.contains('cancel'))
                { deletePasswordsState(); }
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
                    colorFilter: const ColorFilter.mode(Colors.black45, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget searchBar(String hintText){
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: TextFormField(
        decoration: InputDecoration(
            filled: true,
            contentPadding: EdgeInsets.all(13),
            hintText: hintText,
            hintStyle:TextStyle(
                color: Color.fromARGB(255, 154, 153, 153),
                fontWeight: FontWeight.w500
            ),
            fillColor: Color.fromARGB(63, 186, 186, 186),
            prefixIcon: Padding(
                padding: EdgeInsets.fromLTRB(25, 0, 3, 0),
                child: Icon(Icons.search)
            ),
            border: OutlineInputBorder(
                borderSide:  BorderSide(
                  width: 0,
                  style: BorderStyle.none,
                ),
                borderRadius: BorderRadius.circular(35)
            )
        ),
        style: TextStyle(),
      ),
    );
  }

  Widget securityRecommendations(String icon, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: GestureDetector(
        onTapDown: (details) {}, // for additional actions
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          splashColor: Colors.black12,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SecurityRecomPage()),
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
                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
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
                      count == 0 ? "No security risks found" : "Security risks found",
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
                  "$count", //var number of recommendations
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

  Widget passwordSection(passwords password, BuildContext context, int index) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.fromLTRB(25.0, 10, 25.0, 10),
      child: InkWell(
        onTap: () async {
          // Navigate to EditPasswordPage
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(        //give reference to password item
              builder: (context) => EditPasswordPage(password: password),
            ),
          );

          if (updated == true) {
            setState(() {}); // rebuild to reflect changes
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
              Row(
                children: [
                  if (isInDeleteMode)
                    Checkbox(
                      value: selectedPasswords[index] ?? false,
                      shape: const CircleBorder(),
                      onChanged: (bool? value) {
                        setState(() {
                          selectedPasswords[index] = value ?? false;
                        });
                      },
                    ),
                  logoBox(password),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15.0, 0, 8, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          password.websiteName,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 22, 22, 22),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          password.email,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 39, 39, 39),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _hoverButton('assets/copy.svg', screenHeight, () {}, password.password),
            ],
          ),
        ),
      ),
    );
  }

  Widget logoBox(passwords password) {
    return Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 239, 239, 239),
            borderRadius: BorderRadius.circular(30)),
        child: FractionallySizedBox(
            heightFactor: 0.5,
            widthFactor: 0.5,
            child: Image.network(password.logoUrl)));
  }

  void deleteSelectedPasswords() {
    setState(() {
      // Get list of selected indexes
      List<int> indexesToRemove = selectedPasswords.entries
          .where((entry) => entry.value) // Filter selected ones
          .map((entry) => entry.key) // Get their indexes
          .toList();

      // Sort in descending order to avoid index shift issues
      indexesToRemove.sort((a, b) => b.compareTo(a));

      // Remove items from Constants.passwordData
      for (int index in indexesToRemove) {
        Constants.passwordData.removeAt(index);
      }

      // Clear selection map
      selectedPasswords.clear();
    });
  }

  Future<dynamic> bottomModal(BuildContext context) {
    return showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        isScrollControlled: true,
        context: context,
        builder: (BuildContext bc) {
          return Wrap(children: <Widget>[
            Container(
              child: Container(
                decoration: BoxDecoration(
                    color: Colors
                        .white, //forDialog ? Color(0xFF737373) : Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(25.0),
                        topRight: const Radius.circular(25.0))),
                child: AddModal(),
              ),
            )
          ]);
        });
  }

  void deletePasswordsState() {
    setState(() {
      isInDeleteMode = !isInDeleteMode;
    });
  }

  void copyPassword(BuildContext context, String password) {
    if (password.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password is empty, nothing to copy."),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Clipboard.setData(ClipboardData(text: password)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password copied to clipboard ✅"),
          duration: Duration(seconds: 2),
        ),
      );
    });
}
}