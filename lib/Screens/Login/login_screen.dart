import 'package:authpage/Screens/ResetPassword/request_reset_password_screen.dart';
import 'package:authpage/Screens/Signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:authpage/services/api_service.dart';
import 'package:authpage/services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérification de la syntaxe de l'email
    bool isValidEmail =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
            .hasMatch(email);

    if (!isValidEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez saisir une adresse email valide"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Votre mot de passe doit contenir au moins 8 caractères"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await apiService.post("/auth/login", {
        "email": email,
        "password": password,
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

        await StorageService.saveToken(response.data["access_token"]);

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/home');
          // Navigator.pushNamedAndRemoveUntil(
          // context,
          // '/home',
          // (Route<dynamic> route) =>
          // false, // Supprime toutes les routes précédentes ( Attention aux crashs sur l'émulateur Android Studio )
          // );
        });
      } else {
        String errorMessage = response.data["message"] ?? "Erreur de connexion";

        if (errorMessage.toLowerCase().contains("email")) {
          errorMessage = "Adresse email incorrecte";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateWithAnimation(String route) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _getScreenFromRoute(route),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _getScreenFromRoute(String route) {
    switch (route) {
      case '/register':
        return const SignUpScreen();
      case '/reset-password-request':
        return const RequestResetPasswordScreen();
      default:
        return const LoginScreen();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/images/login.svg",
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Connexion",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Adresse e-mail",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.email, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Mot de passe",
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          _navigateWithAnimation('/reset-password-request'),
                      child: const Text(
                        "Mot de passe oublié ?",
                        style: TextStyle(
                          color: Color(0xFF007BFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Se connecter",
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Pas encore de compte ? "),
                      GestureDetector(
                        onTap: () => _navigateWithAnimation('/register'),
                        child: const Text("S'inscrire",
                            style: TextStyle(
                                color: Color(0xFF007BFF),
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
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
