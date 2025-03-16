import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      backgroundColor: const Color(0xFFE6F0FA),
      body: Stack(
        children: [
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
                  SvgPicture.asset(
                    'assets/images/notifpass.svg',
                    height: 180,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(tokenController, "Token",
                      icon: Icons.vpn_key),
                  const SizedBox(height: 10),
                  _buildTextField(passwordController, "Nouveau mot de passe",
                      isPassword: true, icon: Icons.lock),
                  const SizedBox(height: 10),
                  _buildTextField(confirmPasswordController,
                      "Confirmer le nouveau mot de passe",
                      isPassword: true, icon: Icons.lock_outline),
                  const SizedBox(height: 20),
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

  Widget _buildTextField(TextEditingController controller, String hintText,
      {bool isPassword = false, IconData? icon}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
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
