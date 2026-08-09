import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:passwordzzz_v2/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'auth/auth_service.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'theming/themes.dart';
import 'providers/search_state_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseAuthMethods>(
          create: (_) => FirebaseAuthMethods(FirebaseAuth.instance), // Provide FirebaseAuthMethods
        ),
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => SearchStateProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.getThemeMode(),
            theme: MyThemes.lightTheme,
            darkTheme: MyThemes.darkTheme,
            home: LoginScreen(),
          );
        },
      ),
    );
  }
}
