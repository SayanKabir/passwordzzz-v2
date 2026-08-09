import 'dart:ui';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../db/local.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/data_model.dart';
import 'package:password_strength/password_strength.dart';
import '../utils/haptic_feedback.dart';
import '../components/my_snackbar.dart';
import '../utils/password_generators.dart';

enum PassGeneratorForm { CREATE, MODIFY }

class passGeneratorScreen extends StatefulWidget {
  final VoidCallback notifyParent;
  final PassGeneratorForm form;

  String prevSite;
  String prevUser;
  String prevPass;
  int prevID;
  passGeneratorScreen(
      {Key? key,
        required this.notifyParent,
        required this.form,
        this.prevSite = "",
        this.prevUser = "",
        this.prevPass = "",
        this.prevID = -1,
      }
      )
      : super(key: key);

  @override
  _passGeneratorScreenState createState() => _passGeneratorScreenState();
}

class _passGeneratorScreenState extends State<passGeneratorScreen> {

  final _siteController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  double _passwordStrength = 8;
  bool _containLowercase = true;
  bool _containUppercase = true;
  bool _containNumbers = true;
  bool _containSpecials = false;

  String newSite = "";
  String newUsername = "";
  String newPassword = "";

  bool _isSiteEmpty = false;
  bool _isUserEmpty = false;

  @override
  void initState() {
    super.initState();
    if(widget.form == PassGeneratorForm.MODIFY)
    {
      newSite = widget.prevSite;
      newUsername = widget.prevUser;
      newPassword = widget.prevPass;
    }
    else
      generatePassword(_passwordStrength, _containLowercase, _containUppercase,
          _containNumbers, _containSpecials);

    _siteController.text = newSite;
    _usernameController.text = newUsername;
    _passwordController.text = newPassword;
  }

  @override
  void dispose(){
    _siteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  TextSpan tellCorrectStrength(String _password) {
    double strength = estimatePasswordStrength(_password);
    // print(strength);
    if (strength < 0.3) {
      return const TextSpan(
        text: "Weak",
        style: TextStyle(color: Color(0xFFFE4A49)),
      );
    } else if (strength < 0.7) {
      return const TextSpan(
        text: "Medium",
        style: TextStyle(color: Colors.yellow),
      );
    } else if (strength < 0.9) {
      return const TextSpan(
        text: "Strong",
        style: TextStyle(
            color: Color(0xff7bf1a8),
            fontSize: 15,
            fontWeight: FontWeight.w500),
      );
    } else if (strength < 0.98) {
      return const TextSpan(
        text: "Very Strong",
        style: TextStyle(
            color: Color(0xff00ffff),
            fontSize: 15,
            fontWeight: FontWeight.w500),
      );
    } else {
      return TextSpan
        (
        text: "Ultimate ✨",
        style: TextStyle(
          color: const Color(0xffe9ff70),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              color: const Color(0xffeeeeee).withOpacity(1),
              // offset: Offset(1, -1),
              blurRadius: 50,
            ),
          ],
          letterSpacing: 1,
        ),
      );
    }
  }

  void generatePassword(double sizeD, bool uppercase, bool lowercase, bool digits, bool specials) {
    int size = sizeD.round();
    setState(() {
      newPassword = generateRandomPassword(size, uppercase, lowercase, digits, specials);
    });
  }

  @override
  Widget build(BuildContext context) {
    var __isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 20,
            width: MediaQuery.of(context).size.width * 0.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: __isDarkMode ? Colors.white60 : Colors.black12,
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: __isDarkMode
                        ? [
                      Colors.white.withOpacity(0.05),
                      Colors.white.withOpacity(0.1),
                    ]
                        : [
                      Colors.transparent.withOpacity(0.05),
                      Colors.transparent.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    //SITE TEXTFIELD
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8, right: 8, top: 20, bottom: 6),
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Image.network(
                              "https://www.google.com/s2/favicons?domain=$newSite&sz=64",
                              frameBuilder: (context, Widget _child, _, __) =>
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: _child,
                                  ),
                              errorBuilder: (context, _, __) => const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Icon(
                                  Icons.language_outlined,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: newSite,
                              autofocus: false,
                              cursorColor:
                              __isDarkMode ? Colors.white70 : Colors.black12,
                              cursorHeight: 25,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (String value) {
                                setState(
                                      () {
                                    newSite = value;
                                    if (newSite != "") _isSiteEmpty = false;
                                  },
                                );
                              },
                              style: TextStyle(
                                fontSize: 18,
                                color: __isDarkMode
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.8),
                              ),
                              decoration: InputDecoration(
                                suffixIcon: _isSiteEmpty
                                    ? const Icon(
                                  Icons.error_outline_outlined,
                                  color: Color(0xFFFE4A49),
                                )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white70,
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: __isDarkMode
                                        ? const Color(0xffddfffa).withAlpha(200)
                                        : const Color(0xff1d5c5c).withAlpha(200),
                                    width: 1.6,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: __isDarkMode
                                        ? const Color(0xffddfffa).withAlpha(100)
                                        : const Color(0xff1d5c5c).withAlpha(100),
                                    width: 1.2,
                                  ),
                                ),
                                hintText: "Website or app",
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: __isDarkMode
                                      ? Colors.white70
                                      : Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    //USERNAME TEXTFIELD
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8, right: 8, top: 4, bottom: 6),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 11),
                            child: Icon(
                              Icons.person_outline_outlined,
                              size: 30,
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: newUsername,
                              autofocus: false,
                              cursorColor:
                              __isDarkMode ? Colors.white70 : Colors.black54,
                              cursorHeight: 25,
                              enableInteractiveSelection: true,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (String value) {
                                setState(
                                      () {
                                    newUsername = value;
                                    if (newUsername != "") _isUserEmpty = false;
                                  },
                                );
                              },
                              style: TextStyle(
                                fontSize: 18,
                                color: __isDarkMode
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.black.withOpacity(0.8),
                              ),
                              decoration: InputDecoration(
                                suffixIcon: _isUserEmpty
                                    ? const Icon(
                                  Icons.error_outline_outlined,
                                  color: Color(0xFFFE4A49),
                                )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.white70,
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: __isDarkMode
                                        ? const Color(0xffddfffa).withAlpha(200)
                                        : const Color(0xff1d5c5c).withAlpha(200),
                                    width: 1.6,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: __isDarkMode
                                        ? const Color(0xffddfffa).withAlpha(100)
                                        : const Color(0xff1d5c5c).withAlpha(100),
                                    width: 1.2,
                                  ),
                                ),
                                hintText: "Username",
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: __isDarkMode
                                      ? Colors.white70
                                      : Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    //PASSWORD GENERATOR AND TEXTFIELD
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(18)),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaY: 5, sigmaX: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xff0ba99b).withOpacity(0.5),
                                  const Color(0xff0ba99b).withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            height: 120,
                            width: double.infinity,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextField(
                                      controller: TextEditingController(text: newPassword),
                                      enableInteractiveSelection: true,
                                      keyboardType: TextInputType.visiblePassword,
                                      cursorColor: Colors.white,
                                      decoration:
                                      const InputDecoration(border: InputBorder.none),
                                      textAlign: TextAlign.center,
                                      onChanged: (String value) {
                                        newPassword = value;
                                      },
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 27,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        text: "Password Strength:  ",
                                        children: [
                                          tellCorrectStrength(newPassword),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    //STRENGTH SLIDER
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xff0ed9a0).withOpacity(0.8),
                        inactiveTrackColor: const Color(0xff0ba99b).withOpacity(0.6),
                        showValueIndicator: ShowValueIndicator.always,
                        valueIndicatorColor: const Color(0xffffffff),
                        valueIndicatorTextStyle: const TextStyle
                          (
                            color: Colors.black87, fontWeight: FontWeight.bold),
                        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                      ),
                      child: Slider(
                        value: _passwordStrength,
                        label: _passwordStrength.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _passwordStrength = value;
                            generatePassword(
                                _passwordStrength,
                                _containLowercase,
                                _containUppercase,
                                _containNumbers,
                                _containSpecials);
                          });
                        },
                        thumbColor: Colors.white70.withOpacity(1),
                        max: 30,
                        min: 4,
                      ),
                    ),

                    //PASSWORD SPECIFICS
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(18)),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaY: 5, sigmaX: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xff0ba99b).withOpacity(0.5),
                                  const Color(0xff0ba99b).withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            height: 120,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  //UPPERCASE AND LOWERCASE SWITCHES COLUMN
                                  Column(
                                    children: [
                                      //UPPERCASE SWITCH
                                      Row(
                                        children: [
                                          Text(
                                            "Uppercase",
                                            style: GoogleFonts.poppins(
                                                color: Colors.white, fontSize: 18),
                                          ),
                                          Transform.scale(
                                            scale: 0.9,
                                            child: Switch(
                                              value: _containUppercase,
                                              onChanged: (bool value) {
                                                hapticFeedback(context, HapticType.Selection);
                                                setState(() {
                                                  _containUppercase = value;
                                                  generatePassword(
                                                      _passwordStrength,
                                                      _containLowercase,
                                                      _containUppercase,
                                                      _containNumbers,
                                                      _containSpecials);
                                                });
                                              },
                                              activeTrackColor: const Color(0xff0ed9a0)
                                                  .withOpacity(0.8),
                                              activeColor: Colors.white,
                                              inactiveThumbColor: Colors.white,
                                              inactiveTrackColor: Colors.transparent
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                        ],
                                      ),

                                      //LOWERCASE SWITCH
                                      Row(
                                        children: [
                                          Text(
                                            "Lowercase",
                                            style: GoogleFonts.poppins(
                                                color: Colors.white, fontSize: 18),
                                          ),
                                          Transform.scale(
                                            scale: 0.9,
                                            child: Switch(
                                              value: _containLowercase,
                                              onChanged: (bool value) {
                                                hapticFeedback(context, HapticType.Selection);
                                                setState(() {
                                                  _containLowercase = value;
                                                  generatePassword(
                                                      _passwordStrength,
                                                      _containLowercase,
                                                      _containUppercase,
                                                      _containNumbers,
                                                      _containSpecials);
                                                });
                                              },
                                              activeTrackColor: const Color(0xff0ed9a0)
                                                  .withOpacity(0.8),
                                              activeColor: Colors.white,
                                              inactiveThumbColor: Colors.white,
                                              inactiveTrackColor: Colors.transparent
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  //NUMBERS AND SPECIALS SWITCHES COLUMN
                                  Column(
                                    children: [
                                      //NUMBERS SWITCH
                                      Row(
                                        children: [
                                          Text(
                                            "Numbers",
                                            style: GoogleFonts.poppins(
                                                color: Colors.white, fontSize: 18),
                                          ),
                                          Transform.scale(
                                            scale: 0.9,
                                            child: Switch(
                                              value: _containNumbers,
                                              onChanged: (bool value) {
                                                hapticFeedback(context, HapticType.Selection);
                                                setState(() {
                                                  _containNumbers = value;
                                                  generatePassword(
                                                      _passwordStrength,
                                                      _containLowercase,
                                                      _containUppercase,
                                                      _containNumbers,
                                                      _containSpecials);
                                                });
                                              },
                                              activeTrackColor: const Color(0xff0ed9a0)
                                                  .withOpacity(0.8),
                                              activeColor: Colors.white,
                                              inactiveThumbColor: Colors.white,
                                              inactiveTrackColor: Colors.transparent
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                        ],
                                      ),

                                      //SPECIALS SWITCH
                                      Row(
                                        children: [
                                          Text(
                                            "Specials",
                                            style: GoogleFonts.poppins(
                                                color: Colors.white, fontSize: 18),
                                          ),
                                          Transform.scale(
                                            scale: 0.9,
                                            child: Switch(
                                              value: _containSpecials,
                                              onChanged: (bool value) {
                                                hapticFeedback(context, HapticType.Selection);
                                                setState(() {
                                                  _containSpecials = value;
                                                  generatePassword(
                                                      _passwordStrength,
                                                      _containLowercase,
                                                      _containUppercase,
                                                      _containNumbers,
                                                      _containSpecials);
                                                });
                                              },
                                              activeTrackColor: const Color(0xff0ed9a0)
                                                  .withOpacity(0.8),
                                              activeColor: Colors.white,
                                              inactiveThumbColor: Colors.white,
                                              inactiveTrackColor: Colors.transparent
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    //SAVE AND REFRESH BUTTONS
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //SAVE PASSWORD BUTTON
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0ed9a0).withOpacity(0.5),
                              foregroundColor: const Color(0xff0ed9a0),
                              shape: const CircleBorder(),
                              elevation: 0,
                              // shadowColor: Colors.white,
                            ),
                            onPressed: () {
                              if (newSite != "" &&
                                  newUsername != "" &&
                                  newPassword != "") {
                                if(widget.form == PassGeneratorForm.CREATE)
                                {
                                  Data newData = Data(
                                      Site: newSite,
                                      Username: newUsername,
                                      Password_secured: newPassword);
                                  sqliteDB.dataBase.addNewData(newData);
                                  widget.notifyParent();
                                  FlutterClipboard.copy(newPassword);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    mySnackbar(context,
                                        "Password saved and copied to clipboard"),
                                  );
                                  // Navigator.popUntil(context, ModalRoute.withName('/'));
                                  // Navigator.pop(context);
                                  Navigator.of(context).pop();
                                  hapticFeedback(context, HapticType.Selection);
                                }
                                else
                                {
                                  Data updatedData = Data(
                                      id: widget.prevID,
                                      Site: newSite,
                                      Username: newUsername,
                                      Password_secured: newPassword);
                                  sqliteDB.dataBase.updateData(updatedData.toMap());
                                  widget.notifyParent();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    mySnackbar(context,
                                        "Data modified"),
                                  );
                                  // Navigator.popUntil(context, ModalRoute.withName('/'));
                                  // Navigator.pop(context);
                                  Navigator.of(context).pop();
                                  hapticFeedback(context, HapticType.Selection);
                                }
                              } else {
                                if (newSite == "") {
                                  setState(() {
                                    _isSiteEmpty = true;
                                  });
                                }
                                if (newUsername == "") {
                                  setState(() {
                                    _isUserEmpty = true;
                                  });
                                }
                                hapticFeedback(context, HapticType.Action);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(18),
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),

                          //REFRESH BUTTON
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // primary: Color(0xff0ed9a0),
                              backgroundColor: const Color(0xff0ed9a0).withOpacity(0.5),
                              foregroundColor: const Color(0xff0ed9a0),
                              shape: const CircleBorder(),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() {
                                hapticFeedback(context, HapticType.Selection);
                                generatePassword(
                                    _passwordStrength,
                                    _containLowercase,
                                    _containUppercase,
                                    _containNumbers,
                                    _containSpecials);
                              });
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(18),
                              child: Icon(
                                Icons.autorenew_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
