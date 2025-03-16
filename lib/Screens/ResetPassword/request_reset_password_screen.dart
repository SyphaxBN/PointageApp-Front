import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:authpage/services/api_service.dart';

class RequestResetPasswordScreen extends StatefulWidget {
  const RequestResetPasswordScreen({super.key});

  @override
  _RequestResetPasswordScreenState createState() =>
      _RequestResetPasswordScreenState();
}

class _RequestResetPasswordScreenState
    extends State<RequestResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> _requestReset() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer un email valide."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await apiService.post("/auth/request-reset-password", {
        "email": emailController.text,
      });

      String message = response.data["message"] ?? "";
      bool errorFlag = response.data["error"] == true;

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          !errorFlag) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty
                ? message
                : "Email envoyé ! Vérifiez votre boîte de réception."),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/reset-password");
      } else {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de l'envoi de la demande."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FA), // Bleu très clair
      body: Stack(
        children: [
          Positioned(
            top: -10,
            left: -85,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFB3DAF1), // Bleu clair
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
                color: Color(0xFF80C7E8), // Bleu plus foncé
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
                  SvgPicture.asset(
                    'assets/images/forgotpass.svg',
                    height: 180,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Entrer votre email pour recevoir un token de réinitialisation",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Email",
                      prefixIcon: const Icon(Icons.email,
                          color: Color(0xFF3498DB)), // Icône email ajoutée
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                          ? const CircularProgressIndicator(color: Colors.white)
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
    );
  }
}
