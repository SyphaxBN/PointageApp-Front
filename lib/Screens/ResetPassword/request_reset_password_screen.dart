import 'package:flutter/material.dart';
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
      // On récupère la valeur d'erreur en s'assurant qu'elle soit traitée comme booléen
      bool errorFlag;
      if (response.data["error"] is bool) {
        errorFlag = response.data["error"];
      } else {
        errorFlag = response.data["error"].toString().toLowerCase() != "false";
      }

      // Si tout est OK (status code 200/201 et pas d'erreur) OU si le message indique
      // qu'une demande est déjà en cours, on navigue vers l'écran de réinitialisation.
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
      } else if (message.contains("déjà en cours")) {
        // Même si errorFlag est true, on souhaite naviguer vers l'écran de réinitialisation.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
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
      appBar: AppBar(title: const Text("Mot de passe oublié")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
                "Entrez votre email pour recevoir un token de réinitialisation."),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _requestReset,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Envoyer un email"),
            ),
          ],
        ),
      ),
    );
  }
}
