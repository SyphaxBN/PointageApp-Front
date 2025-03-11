import 'package:authpage/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:authpage/services/api_service.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login() async {
    try {
      final response = await apiService.post("/auth/login", {
        "email": emailController.text,
        "password": passwordController.text,
      });

      bool isError = response.data["error"] is bool
          ? response.data["error"]
          : response.data["error"].toString() == "true";

      if ((response.data["status"] == 200 || response.statusCode == 200) &&
          !isError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Connexion réussie !"),
            backgroundColor: Colors.green,
          ),
        );

        await StorageService.saveToken(
            response.data["access_token"]); // ✅ Unifié

        print("Token sauvegardé : ${response.data["access_token"]}");

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushNamed(context, '/home');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data["message"] ?? "Erreur de connexion"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la connexion"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: "Email"),
        ),
        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: "Mot de passe"),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _login,
          child: const Text("Se connecter"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/reset-password-request');
          },
          child: const Text("Mot de passe oublié ?"),
        ),
      ],
    );
  }
}
