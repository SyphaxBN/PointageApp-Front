import 'package:authpage/Screens/Login/login_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FA), // Bleu très clair
      body: Stack(
        children: [
          // Cercles bleus en haut à gauche
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
                color: Color(0xFF80C7E8), // Bleu un peu plus foncé
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
                    // Image principale
                    Image.asset(
                      "assets/images/beko.png",
                      height: 310,
                    ),
                    const SizedBox(height: 20),

                    // Titre sur deux lignes
                    const Text(
                      "Suivi intelligent pour un travail",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "précis et efficace",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    const Text(
                      "La solution de suivi intelligent de Beko garantit une gestion du temps précise et efficace, aidant les équipes à rester productives et organisées.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 102, 102, 102),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bouton "Commencer"
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const LoginScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin =
                                  Offset(1.0, 0.0); // Départ de la droite
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));

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
                      },
          
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Commencer",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
}