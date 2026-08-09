import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/shared_prefs_handler.dart';

class SettingsTile extends StatefulWidget {
  final String text;
  final String prefsTag;
  SettingsTile({Key? key, required this.text, required this.prefsTag})
      : super(key: key);

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool switchState = true;
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      switchState = prefs.getBool(widget.prefsTag) ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            const Color(0xff0ba99b).withOpacity(0.5),
            const Color(0xff0ba99b).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      height: 75,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text(
                widget.text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Transform.scale(
              scale: 1.2,
              child: Switch(
                value: switchState,
                onChanged: (bool value) {
                  setState(() {
                    switchState = value;
                    SharedPrefsHandler.saveData(
                        tag: widget.prefsTag, data: value);
                  });
                },
                activeTrackColor: const Color(0xff0ed9a0).withOpacity(0.8),
                activeColor: Colors.white,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.transparent.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}