import 'package:flutter/material.dart';
import 'package:authpage/services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  void _resetPassword() async {
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
      final response = await apiService.post("/auth/reset-password", {
        "token": tokenController.text,
        "password": passwordController.text,
      });
      bool isError = response.data["error"] is bool
          ? response.data["error"]
          : response.data["error"].toString() == "true";

      if (!isError &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mot de passe réinitialisé avec succès !"),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushNamed(context, '/login');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response.data["message"] ?? "Erreur de réinitialisation"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
      appBar: AppBar(title: const Text("Réinitialisation du mot de passe")),
      body: Center(
        // <-- Ajout de Center
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // <-- Centre verticalement
            crossAxisAlignment:
                CrossAxisAlignment.center, // <-- Centre horizontalement
            mainAxisSize: MainAxisSize
                .min, // <-- Ajuste la taille de la colonne au contenu
            children: [
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(labelText: "Token"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration:
                    const InputDecoration(labelText: "Nouveau mot de passe"),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                    labelText: "Confirmer le mot de passe"),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetPassword,
                child: const Text("Réinitialiser le mot de passe"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
