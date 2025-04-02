import 'package:authpage/Screens/Principale/profile_page.dart';
import 'package:authpage/Screens/Signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:authpage/Screens/Welcome/welcome_screen.dart';
import 'package:authpage/Screens/Login/login_screen.dart';
import 'package:authpage/Screens/ResetPassword/request_reset_password_screen.dart';
import 'package:authpage/Screens/ResetPassword/reset_password_screen.dart';
import 'package:authpage/Screens/Principale/home_page.dart';
import 'package:authpage/constants.dart';

/// Point d'entrée principal de l'application.
/// Configure le thème, les routes et lance l'application.
void main() => runApp(const MyApp());

/// Widget racine de l'application.
/// Configure le thème global et définit les routes de navigation.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // Suppression de la bannière de débogage
      title: 'Flutter Auth',
      theme: ThemeData(
        // Configuration du thème principal
        primaryColor: const Color.fromARGB(255, 31, 125, 233),
        scaffoldBackgroundColor: Colors.white,

        // Style des boutons élevés
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            foregroundColor: Colors.white,
            backgroundColor: kPrimaryColor,
            shape: const StadiumBorder(),
            maximumSize: const Size(double.infinity, 56),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),

        // Style des champs de saisie
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: kPrimaryLightColor,
          iconColor: kPrimaryColor,
          prefixIconColor: kPrimaryColor,
          contentPadding: EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: defaultPadding,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      initialRoute: '/', // Route initiale au lancement de l'application

      // Définition des routes de navigation
      routes: {
        '/': (context) => const WelcomeScreen(), // Écran d'accueil
        '/login': (context) => const LoginScreen(), // Écran de connexion
        '/register': (context) => const SignUpScreen(), // Écran d'inscription
        '/reset-password-request':
            (context) => // Écran de demande de réinitialisation
                const RequestResetPasswordScreen(),
        '/reset-password': (context) =>
            const ResetPasswordScreen(), // Écran de réinitialisation
        '/home': (context) =>
            const HomePage(), // Écran d'accueil après connexion
        '/profile': (context) =>
            const ProfilePage(), // Écran de profil utilisateur
      },
    );
  }
}
