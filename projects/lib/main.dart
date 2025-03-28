import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:projects/AddModal.dart';
import 'package:projects/Model/password_model.dart';
import 'package:projects/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final String plusAsset = 'assets/plus.svg'; // #757575
    final String editAsset = 'assets/edit.svg';
    final String lockAsset = 'assets/lock.svg';
    final String copyAsset = 'assets/copy.svg';
    double screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children : [
              profilePicAddEditIcons(plusAsset, editAsset, screenHeight),
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
              Container(
                // height: 200,
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: Constants.passwordData.length,
                    itemBuilder: (context, index) {
                      final password = Constants.passwordData[index];
                      return passwordSection(password, context);
                    }),
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
  
  Widget profilePicAddEditIcons(String plusAsset, String editAsset, double screenHeight){
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
                      "Hello, Cass",
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
              _hoverButton(plusAsset, screenHeight, () {
              }),
              _hoverButton(editAsset, screenHeight, () {
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hoverButton(String asset, double screenHeight, VoidCallback onTap) {
    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (details) {},
          child: InkWell(
            borderRadius: BorderRadius.circular(35),
            splashColor: Colors.black12,
            onTap: () {
              // navigation or action here
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
            hintText: "Search Password",
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
            // navigation or action here
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

  Widget passwordSection(passwords password, BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.fromLTRB(25.0, 10, 25.0, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // profile row
          Row(
            children: [
              logoBox(password, context),
              Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 0, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      password.websiteName,
                      style: TextStyle(
                        color: Color.fromARGB(255, 22, 22, 22),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      password.email,
                      style: TextStyle(
                        color: Color.fromARGB(255, 39, 39, 39),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          _hoverButton('assets/copy.svg', screenHeight, (){})
        ],
      ),
    );
  }

  Widget logoBox(passwords password, BuildContext context) {
    return Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 239, 239, 239),
            borderRadius: BorderRadius.circular(20)),
        child: FractionallySizedBox(
            heightFactor: 0.5,
            widthFactor: 0.5,
            child: Image.network(password.logoUrl)));
  }

  // Future<dynamic> bottomModal(BuildContext context) {
  //   return showModalBottomSheet(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(20.0),
  //       ),
  //       isScrollControlled: true,
  //       context: context,
  //       builder: (BuildContext bc) {
  //         return Wrap(children: <Widget>[
  //           Container(
  //             child: Container(
  //               decoration: new BoxDecoration(
  //                   color: Colors
  //                       .white, //forDialog ? Color(0xFF737373) : Colors.white,
  //                   borderRadius: new BorderRadius.only(
  //                       topLeft: const Radius.circular(25.0),
  //                       topRight: const Radius.circular(25.0))),
  //               child: AddModal(),
  //             ),
  //           )
  //         ]);
  //       });
  // }

  // Widget bottomSheetWidgets(BuildContext context) {
  //   double screenHeight = MediaQuery.of(context).size.height;
  //   double screenWidth = MediaQuery.of(context).size.width;
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(10.0, 10, 10, 10),
  //     child: Column(
  //       children: [
  //         SizedBox(
  //           height: 10,
  //         ),
  //         Align(
  //           alignment: Alignment.topCenter,
  //           child: Container(
  //             width: screenWidth * 0.4,
  //             height: 5,
  //             decoration: BoxDecoration(
  //                 color: Color.fromARGB(255, 156, 156, 156),
  //                 borderRadius: BorderRadius.circular(20)),
  //           ),
  //         ),
  //         SizedBox(
  //           height: 20,
  //         ),
  //         searchBar("Search for a website or app"),
  //         SizedBox(
  //           height: 10,
  //         ),
  //         Row(
  //           children: [
  //             Container(
  //               height: 60,
  //               width: 130,
  //               decoration: BoxDecoration(
  //                   color:  Color.fromARGB(255, 239, 239, 239),
  //                   borderRadius: BorderRadius.circular(20)),
  //               child: FractionallySizedBox(
  //                 heightFactor: 0.5,
  //                 widthFactor: 0.5,
  //                 child: Container(
  //                   child: Row(
  //                     children: [
  //                       Icon(Icons.add),
  //                       SizedBox(
  //                         width: 4,
  //                       ),
  //                       Text(
  //                         "Add",
  //                         style: TextStyle(fontSize: 14),
  //                       )
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
//------------------33:27----------------