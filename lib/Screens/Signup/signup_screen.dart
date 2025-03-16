import 'package:authpage/Screens/Login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:authpage/services/api_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void _register() async {
    if (isLoading) return;

    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

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
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacementNamed(context, "/login");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un compte existe déjà avec cet email.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

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
                    SvgPicture.asset(
                      "assets/images/signup.svg",
                      height: 180,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Créer un compte",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                        emailController, "Adresse e-mail", Icons.email),
                    const SizedBox(height: 10),
                    buildTextField(nameController, "Nom", Icons.person),
                    const SizedBox(height: 10),
                    buildTextField(
                        passwordController, "Mot de passe", Icons.lock,
                        isPassword: true),
                    const SizedBox(height: 20),
                    const SizedBox(height: 10),
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

  Widget buildTextField(
      TextEditingController controller, String hintText, IconData icon,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
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
