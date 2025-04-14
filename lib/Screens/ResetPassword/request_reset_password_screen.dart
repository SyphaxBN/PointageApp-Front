import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:authpage/services/api_service.dart';

/// Écran de demande de réinitialisation de mot de passe.
/// Permet à l'utilisateur d'entrer son email pour recevoir un token
/// de réinitialisation par email.
class RequestResetPasswordScreen extends StatefulWidget {
  const RequestResetPasswordScreen({super.key});

  @override
  _RequestResetPasswordScreenState createState() =>
      _RequestResetPasswordScreenState();
}

class _RequestResetPasswordScreenState
    extends State<RequestResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false; // Indicateur d'état de chargement

  /// Gère le processus de demande de réinitialisation du mot de passe.
  /// Valide l'email, envoie la demande au serveur et gère la réponse.
  Future<void> _requestReset() async {
    // Validation de l'email
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer un email valide."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Activation de l'indicateur de chargement
    setState(() => isLoading = true);

    try {
      // Envoi de la demande au serveur
      final response = await apiService.post("/auth/request-reset-password", {
        "email": emailController.text,
      });

      // Extraction du message et du statut d'erreur de la réponse
      String message = response.data["message"] ?? "";
      bool errorFlag = response.data["error"] == true;

      // Traitement de la réponse du serveur
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          !errorFlag) {
        // Notification de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty
                ? message
                : "Email envoyé ! Vérifiez votre boîte de réception."),
            backgroundColor: Colors.green,
          ),
        );

        // Redirection vers l'écran de réinitialisation de mot de passe
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/reset-password");
      } else {
        // Affichage du message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty
                ? message
                : "Erreur lors de l'envoi de l'email."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Gestion des erreurs de requête
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'envoi de la demande."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Désactivation de l'indicateur de chargement
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    // Libération des ressources
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Configuration responsive
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Ajustement des dimensions
    final double horizontalPadding = screenSize.width * 0.05;
    final double illustrationHeight =
        isLandscape ? screenSize.height * 0.3 : screenSize.height * 0.2;
    final double fieldWidth =
        isLandscape ? screenSize.width * 0.6 : double.infinity;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFE6F0FA),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration SVG avec hauteur adaptative
                        SvgPicture.asset(
                          'assets/images/forgotpass.svg',
                          height: illustrationHeight,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),

                        // Texte explicatif
                        Container(
                          width: fieldWidth,
                          child: const Text(
                            "Entrer votre email pour recevoir un token de réinitialisation",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Centralisation des champs en mode paysage
                        Center(
                          child: Container(
                            width: fieldWidth,
                            child: Column(
                              children: [
                                // Champ de saisie pour l'email
                                TextField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: "Email",
                                    prefixIcon: const Icon(Icons.email,
                                        color: Color(0xFF3498DB)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 20),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Bouton d'envoi d'email
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _requestReset,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3498DB),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white)
                                        : const Text(
                                            "Envoyer un Email",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
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
          );
        }),
      ),
    );
  }
}
