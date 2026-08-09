import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

enum urlType {web, mail}

class DeveloperTile extends StatelessWidget {
  final urlType type;
  final IconData kicon;
  final String ktitle;
  final String ksubtitle;
  final Uri kURL;
  final bool isDarkMode;
  const DeveloperTile({
    Key? key,
    required this.kicon,
    required this.ktitle,
    required this.ksubtitle,
    required this.kURL,
    required this.isDarkMode,
    required this.type,
  }) : super(key: key);

  void _launchURL(Uri _url) async {
    if(type == urlType.mail){
      await launchUrl(
        _url,

      );
    }else{
      if (await canLaunchUrl(_url)) {
        await launchUrl(
          _url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $_url';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _launchURL(kURL);
      },
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Icon(
                kicon,
                size: 30,
                color: Colors.white,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ktitle,
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w300),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  ksubtitle,
                  style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}