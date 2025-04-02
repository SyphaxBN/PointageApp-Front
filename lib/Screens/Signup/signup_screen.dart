import 'package:authpage/Screens/Login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:authpage/services/api_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Écran d'inscription permettant aux nouveaux utilisateurs de créer un compte.
/// Collecte le nom, l'email et le mot de passe, effectue des validations,
/// puis envoie les données au serveur pour créer le compte.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Contrôleurs pour les champs de saisie
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false; // Indicateur d'état de chargement

  /// Gère le processus d'inscription d'un nouvel utilisateur.
  /// Valide les entrées, envoie les données au serveur et gère la réponse.
  void _register() async {
    if (isLoading)
      return; // Évite les soumissions multiples pendant le chargement

    // Récupération et nettoyage des données saisies
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;

    // Validation des champs obligatoires
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs."),
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
          content: Text("L'adresse email saisie est mal formatée."),
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
              Text("Votre mot de passe doit contenir au moins 8 caractères."),
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
      // Envoi des données au serveur
      final response = await apiService.post("/auth/register", {
        "name": name,
        "email": email,
        "password": password,
      });

      // Traitement de la réponse du serveur
      if (response.statusCode == 201) {
        await apiService.saveToken(response.data["access_token"]);

        // Notification de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Inscription réussie !"),
            backgroundColor: Colors.green,
          ),
        );

        // Redirection vers l'écran de connexion
        Navigator.pushReplacementNamed(context, "/login");
      }
    } catch (e) {
      // Gestion des erreurs d'inscription
      String errorMessage = "Un compte existe déjà avec cet email.";

      // Personnalisation du message d'erreur
      if (e.toString().toLowerCase().contains("email")) {
        errorMessage = "Adresse email incorrecte ou déjà enregistrée.";
      }

      // Affichage du message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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

  /// Navigation vers l'écran de connexion avec une animation de transition.
  void _navigateToLogin() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Configuration de l'animation
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          // Animation de glissement
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
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
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration SVG
                    SvgPicture.asset(
                      "assets/images/signup.svg",
                      height: 180,
                    ),
                    const SizedBox(height: 20),
                    // Titre de la page
                    const Text(
                      "Créer un compte",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Champ de saisie pour l'email
                    buildTextField(
                        emailController, "Adresse e-mail", Icons.email),
                    const SizedBox(height: 10),
                    // Champ de saisie pour le nom
                    buildTextField(nameController, "Nom", Icons.person),
                    const SizedBox(height: 10),
                    // Champ de saisie pour le mot de passe
                    buildTextField(
                        passwordController, "Mot de passe", Icons.lock,
                        isPassword: true),
                    const SizedBox(height: 20),
                    const SizedBox(height: 10),
                    // Bouton d'inscription
                    ElevatedButton(
                      onPressed: isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size(double.infinity, 55),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "S'inscrire",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                    ),
                    // Lien vers la page de connexion
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: RichText(
                        text: const TextSpan(
                          text: "Vous avez déjà un compte ? ",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.normal,
                          ),
                          children: [
                            TextSpan(
                              text: "Se connecter.",
                              style: TextStyle(
                                color: Color(0xFF007BFF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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

  /// Crée un champ de saisie stylisé avec un texte d'indication et une icône.
  /// 
  /// @param controller Le contrôleur pour gérer la valeur du champ
  /// @param hintText Le texte d'indication affiché lorsque le champ est vide
  /// @param icon L'icône à afficher à gauche du champ
  /// @param isPassword Indique si le champ doit masquer le texte (pour les mots de passe)
  /// @return Un widget TextField configuré
  Widget buildTextField(
      TextEditingController controller, String hintText, IconData icon,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword, // Masque le texte si c'est un mot de passe
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      ),
    );
  }
}
