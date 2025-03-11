import 'package:flutter/material.dart';
import 'package:authpage/services/api_service.dart';

class SignUpForm extends StatefulWidget {
  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _register() async {
    try {
      final response = await apiService.post("/auth/register", {
        "name": nameController.text,
        "email": emailController.text,
        "password": passwordController.text,
      });

      if (response.statusCode == 201) {
        await apiService.saveToken(response.data["access_token"]);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Inscription réussie !"),
              backgroundColor: Colors.green),
        );

        Navigator.pushReplacementNamed(context, "/login");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Un compte existe deja avec cette adresse email.'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Nom")),
        TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: "Email")),
        TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: "Mot de passe"),
            obscureText: true),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _register, child: const Text("S'inscrire")),
      ],
    );
  }
}
