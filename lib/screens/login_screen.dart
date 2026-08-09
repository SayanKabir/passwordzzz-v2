import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:passwordzzz_v2/components/my_textfield.dart';
import 'package:passwordzzz_v2/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:passwordzzz_v2/components/my_button.dart';
import '../auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Method to handle login with email and password
  Future<void> _loginWithEmail(BuildContext context) async {
    final authMethods = Provider.of<FirebaseAuthMethods>(context, listen: false);
    await authMethods.loginWithEmail(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      context: context,
    );
  }

  // Method to handle Google Sign-In
  Future<void> _loginWithGoogle(BuildContext context) async {
    final authMethods = Provider.of<FirebaseAuthMethods>(context, listen: false);
    await authMethods.signInWithGoogle(context);
  }

  // Method to handle Apple Sign-In
  Future<void> _loginWithApple(BuildContext context) async {
    final authMethods = Provider.of<FirebaseAuthMethods>(context, listen: false);
    await authMethods.signInWithApple(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),

                // Heading etc
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Image.asset(
                        'assets/logo-small.png',
                        scale: 5,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    Text(
                      'Login to Passwordzzz',
                      textAlign: TextAlign.start,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        color: context.read<ThemeProvider>().isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    Text(
                      'No more forgetting passwords',
                      textAlign: TextAlign.start,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: context.read<ThemeProvider>().isDarkMode
                            ? Colors.white60
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // TextFormFields
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                ),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),

                const SizedBox(height: 10),

                // Login Button
                MyButton(
                  onPressed: () async {
                    await _loginWithEmail(context); // Login with email and password
                  },
                  width: double.infinity,
                  child: Text(
                    'Log In',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Or authorize with
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: context.read<ThemeProvider>().isDarkMode
                            ? Colors.white60
                            : Colors.black54,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Or authorize with',
                        style: GoogleFonts.roboto(
                          color: context.read<ThemeProvider>().isDarkMode
                              ? Colors.white60
                              : Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: context.read<ThemeProvider>().isDarkMode
                            ? Colors.white60
                            : Colors.black54,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Google and Apple sign-in buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyButton(
                      onPressed: () async {
                        await _loginWithGoogle(context); // Google sign-in
                      },
                      width: MediaQuery.of(context).size.width * 0.2,
                      backgroundColor: context.read<ThemeProvider>().isDarkMode
                          ? Colors.white
                          : Colors.black,
                      child: Image.asset(
                        'assets/google-logo.png',
                        scale: 18,
                      ),
                    ),
                    const SizedBox(width: 20), // Add some space between buttons
                    MyButton(
                      onPressed: () async {
                        await _loginWithApple(context); // Apple sign-in
                      },
                      width: MediaQuery.of(context).size.width * 0.2,
                      backgroundColor: context.read<ThemeProvider>().isDarkMode
                          ? Colors.white
                          : Colors.black,
                      child: Image.asset(
                        'assets/apple-logo.png',
                        scale: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
