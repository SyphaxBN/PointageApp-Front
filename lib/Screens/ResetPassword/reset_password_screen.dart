import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:authpage/services/api_service.dart';

/// Écran de réinitialisation de mot de passe.
/// Permet à l'utilisateur d'entrer un nouveau mot de passe après avoir reçu un token
/// de réinitialisation par email.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Contrôleurs pour les champs de saisie
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  /// Gère le processus de réinitialisation du mot de passe.
  /// Valide les entrées, envoie les données au serveur et traite la réponse.
  void _resetPassword() async {
    // Vérification de la correspondance des mots de passe
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Les mots de passe ne correspondent pas."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Envoi de la requête de réinitialisation au serveur
      final response = await apiService.post("/auth/reset-password", {
        "token": tokenController.text,
        "password": passwordController.text,
      });

      // Vérification du succès de la requête
      bool isError = response.data["error"] is bool
          ? response.data["error"]
          : response.data["error"].toString() == "true";

      if (!isError &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        // Notification de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mot de passe réinitialisé avec succès !"),
            backgroundColor: Colors.green,
          ),
        );

        // Redirection vers l'écran de connexion après un court délai
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushNamed(context, '/login');
        });
      } else {
        // Affichage du message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response.data["message"] ?? "Erreur de réinitialisation"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Gestion des erreurs de requête
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la réinitialisation du mot de passe"),
          backgroundColor: Colors.red,
        ),
      );
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration SVG
                  SvgPicture.asset(
                    'assets/images/notifpass.svg',
                    height: 180,
                  ),
                  const SizedBox(height: 20),
                  // Champ pour entrer le token reçu par email
                  _buildTextField(tokenController, "Token",
                      icon: Icons.vpn_key),
                  const SizedBox(height: 10),
                  // Champ pour entrer le nouveau mot de passe
                  _buildTextField(passwordController, "Nouveau mot de passe",
                      isPassword: true, icon: Icons.lock),
                  const SizedBox(height: 10),
                  // Champ pour confirmer le nouveau mot de passe
                  _buildTextField(confirmPasswordController,
                      "Confirmer le nouveau mot de passe",
                      isPassword: true, icon: Icons.lock_outline),
                  const SizedBox(height: 20),
                  // Bouton de réinitialisation
                  ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A90E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 40),
                    ),
                    child: const Text(
                      "Réinitialiser le mot de passe",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
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
  /// @param isPassword Indique si le champ doit masquer le texte (pour les mots de passe)
  /// @param icon L'icône optionnelle à afficher à gauche du champ
  /// @return Un widget TextField configuré
  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool isPassword = false, IconData? icon}) {
    return TextField(
      controller: controller,
      obscureText: isPassword, // Masque le texte si c'est un mot de passe
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        prefixIcon: icon != null
            ? Icon(
                icon,
                color: const Color(0xFF3498DB),
              )
            : null,
      ),
    );
  }
}
