import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/custom_slide_transition.dart';
import 'settings_page.dart';
import 'package:provider/provider.dart';
import '../components/password_unit.dart';
import '../components/search_overlay.dart';
import '../utils/haptic_feedback.dart';
import '../providers/search_state_provider.dart';
import '../providers/theme_provider.dart';
import 'pass_generator_screen.dart';
import '../db/local.dart';
import '../components/animated_search_bar.dart';
import '../utils/passwords_data_handler.dart';

class Manager extends StatefulWidget {
  const Manager({Key? key}) : super(key: key);

  @override
  _ManagerState createState() => _ManagerState();
}

class _ManagerState extends State<Manager> {
  @override
  void initState() {
    super.initState();
    getAllDataFromDB();
  }

  void refreshPage() {
    setState(() {});
  }

  getData() async {
    final List datas = await sqliteDB.dataBase.getData();
    return datas;
  }

  @override
  Widget build(BuildContext context) {
    var __isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    TextEditingController textController = TextEditingController();
    return ChangeNotifierProvider(
      create: (_) => SearchStateProvider(),
      builder: (context, _) => Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size(
            double.infinity,
            75.0,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaY: 15, sigmaX: 15),
              child: AppBar(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
                ),
                centerTitle: false,
                leadingWidth: 0,
                actions: [
                  //SEARCH BUTTON
                  AnimatedSearchBar(
                    textController: textController,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5, right: 15, top: 5),
                    child: IconButton(
                      onPressed: () async {
                        hapticFeedback(context, HapticType.Selection);
                        final provider = context.read<ThemeProvider>();
                        provider.toggleTheme();
                      },
                      icon: Icon(
                        __isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        size: 28,
                        color: __isDarkMode
                            ? const Color(0xffddfffa)
                            : const Color(0xff0ba99b).withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
                elevation: 0,
                backgroundColor: Colors.transparent.withOpacity(0.03),
                toolbarHeight: 75,
                title: Padding(
                  padding: const EdgeInsets.only(left: 0, right: 35),
                  child: GestureDetector(
                    onTap: () {
                      Feedback.forTap(context);
                      hapticFeedback(context, HapticType.Selection);
                      Navigator.of(context).push(
                        SlideAnimationRoute(
                          page: const SettingsPage(),
                        ),
                      );
                    },
                    child: Image.asset(
                      "assets/logo-full.png",
                      color: __isDarkMode
                          ? const Color(0xffddfffa)
                          : const Color(0xff0ba99b).withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: FutureBuilder<dynamic>(
                future: getData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: Text(
                          "You have no saved password",
                          style: GoogleFonts.montserrat(
                            color: __isDarkMode ? Colors.white38 : Colors.black38,
                            fontSize: 20,
                          ),
                        ),
                      );
                    } else if (snapshot.data.length != null) {
                      return RefreshIndicator(
                        edgeOffset: 100,
                        strokeWidth: 2.5,
                        backgroundColor: __isDarkMode ? Colors.black : Colors.white,
                        color: const Color(0xff0ba99b),
                        onRefresh: () async {
                          await Future.delayed(const Duration(milliseconds: 800));
                          refreshPage();
                        },
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 100),
                          itemCount: snapshot.data.length + 1,
                          itemBuilder: (context, index) {
                            if (index < snapshot.data.length) {
                              return PasswordUnit(
                                id: snapshot.data[index]['id'],
                                kSite: snapshot.data[index]['site'],
                                kUsername: snapshot.data[index]['user'],
                                notifyParent: refreshPage,
                                form: ListViewForm.MANAGER,
                              );
                            } else {
                              return const SizedBox(
                                height: 0,
                              );
                            }
                          },
                        ),
                      );
                    }
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff0ba99b),
                      ),
                    );
                  }
                  throw 'TODO';
                },
              ),
            ),
            Consumer<SearchStateProvider>(
              builder: (context, searchState, _) {
                return getSearchOverlay(
                  searchState.isSearchShowing,
                  searchState.getSearchResLen,
                );
              },
            ),
          ],
        ),
        floatingActionButton: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaY: 4, sigmaX: 4),
            child: SizedBox(
              height: 55,
              child: FloatingActionButton.extended(
                //extendedPadding: const EdgeInsetsDirectional.symmetric(vertical: 0, horizontal: 20),
                elevation: 0,
                backgroundColor: const Color(0xff0ba99b).withOpacity(0.8),
                label: Text(
                  "Create new password",
                  style: GoogleFonts.poppins(
                    letterSpacing: 1,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                icon: const Icon(
                  Icons.add,
                  size: 26,
                  color: Colors.white,
                ),
                onPressed: () {
                  hapticFeedback(context, HapticType.Selection);
                  showModalBottomSheet<void>(
                    clipBehavior: Clip.antiAlias,
                    barrierColor: Colors.transparent,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (BuildContext context) {
                      return passGeneratorScreen(
                        notifyParent: refreshPage,
                        form: PassGeneratorForm.CREATE,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
