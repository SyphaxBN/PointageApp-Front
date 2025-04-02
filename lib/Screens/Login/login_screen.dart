import 'package:authpage/Screens/ResetPassword/request_reset_password_screen.dart';
import 'package:authpage/Screens/Signup/signup_screen.dart';
import 'package:authpage/services/attendance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:authpage/services/api_service.dart';
import 'package:authpage/services/storage_service.dart';

/// Écran de connexion de l'application.
/// Permet à l'utilisateur de se connecter avec son email et mot de passe.
/// Offre également des liens vers l'inscription et la réinitialisation de mot de passe.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  // Contrôleurs pour les champs de saisie
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false; // Indicateur d'état de chargement

  /// Gère le processus de connexion.
  /// Valide les entrées, envoie les identifiants au serveur et traite la réponse.
  void _login() async {
    // Récupération et nettoyage des données saisies
    String email = emailController.text.trim();
    String password = passwordController.text;

    // Validation des champs obligatoires
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validation de la syntaxe de l'email
    bool isValidEmail =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
            .hasMatch(email);

    if (!isValidEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez saisir une adresse email valide"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation de la longueur du mot de passe
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Votre mot de passe doit contenir au moins 8 caractères"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Activation de l'indicateur de chargement
    setState(() {
      isLoading = true;
    });

    try {
      // Envoi des identifiants au serveur
      final response = await apiService.post("/auth/login", {
        "email": email,
        "password": password,
      });

      // Vérification du statut d'erreur de la réponse
      bool isError = response.data["error"] is bool
          ? response.data["error"]
          : response.data["error"].toString() == "true";

      // Traitement de la réponse du serveur
      if ((response.data["status"] == 200 || response.statusCode == 200) &&
          !isError) {
        // Notification de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connexion réussie !"),
            backgroundColor: Colors.green,
          ),
        );

        // Sauvegarde du token d'authentification
        await StorageService.saveToken(response.data["access_token"]);

        // Récupération du dernier pointage après connexion
        try {
          final lastAttendance = await AttendanceService.getLastAttendance();
          print("📌 Dernier pointage récupéré : $lastAttendance");
        } catch (e) {
          print("⚠️ Erreur lors de la récupération du dernier pointage : $e");
        }

        // Redirection vers l'accueil après un court délai
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        // Gestion des erreurs de connexion
        String errorMessage = response.data["message"] ?? "Erreur de connexion";

        // Amélioration du message d'erreur pour l'email
        if (errorMessage.toLowerCase().contains("email")) {
          errorMessage = "Adresse email incorrecte";
        }

        // Affichage du message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Gestion des erreurs de requête
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la connexion"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Désactivation de l'indicateur de chargement
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Gère la navigation vers d'autres écrans avec une animation de transition.
  /// @param route La route cible ('/register' ou '/reset-password-request')
  void _navigateWithAnimation(String route) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _getScreenFromRoute(route),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Configuration de l'animation
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          // Animation combinant glissement et fondu
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Retourne l'écran correspondant à la route spécifiée.
  /// @param route La route cible
  /// @return Le widget correspondant à la route
  Widget _getScreenFromRoute(String route) {
    switch (route) {
      case '/register':
        return const SignUpScreen();
      case '/reset-password-request':
        return const RequestResetPasswordScreen();
      default:
        return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FA),
      body: Stack(
        children: [
          // Éléments de design - cercles bleus
          Positioned(
            top: -10,
            left: -85,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFB3DAF1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -8,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFF80C7E8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Illustration SVG
                  SvgPicture.asset(
                    "assets/images/login.svg",
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  // Titre
                  const Text(
                    "Connexion",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Champ de saisie pour l'email
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Adresse e-mail",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.email, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Champ de saisie pour le mot de passe
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Mot de passe",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Lien pour mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          _navigateWithAnimation('/reset-password-request'),
                      child: const Text(
                        "Mot de passe oublié ?",
                        style: TextStyle(
                          color: Color(0xFF007BFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Bouton de connexion
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Se connecter",
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                  const SizedBox(height: 12),
                  // Lien vers la page d'inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Pas encore de compte ? "),
                      GestureDetector(
                        onTap: () => _navigateWithAnimation('/register'),
                        child: const Text("S'inscrire",
                            style: TextStyle(
                                color: Color(0xFF007BFF),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
