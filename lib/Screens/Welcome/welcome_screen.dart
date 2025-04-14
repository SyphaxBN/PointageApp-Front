import 'package:authpage/Screens/Login/login_screen.dart';
import 'package:flutter/material.dart';

/// Écran d'accueil de l'application.
/// Premier écran que voit l'utilisateur au lancement de l'application.
/// Présente une introduction à l'application et un bouton pour commencer.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération des dimensions de l'écran pour le responsive design
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Ajuster la taille du logo et des marges en fonction de l'orientation
    final double logoHeight =
        isLandscape ? screenSize.height * 0.4 : screenSize.height * 0.3;
    final double horizontalPadding = screenSize.width * 0.05;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFE6F0FA), // Bleu très clair pour le fond
      body: SafeArea(
        // SafeArea garantit que le contenu est visible même avec des encoches
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              // Création d'éléments de design - cercles bleus en haut à gauche
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

              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo de l'application avec hauteur adaptative
                        Image.asset(
                          "assets/images/beko.png",
                          height: logoHeight,
                          fit: BoxFit.contain,
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

                        // Description du service
                        const Text(
                          "La solution de suivi intelligent de Beko garantit une gestion du temps précise et efficace, aidant les équipes à rester productives et organisées.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(255, 102, 102, 102),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bouton "Commencer" avec animation de transition
                        ElevatedButton(
                          onPressed: () {
                            // Navigation vers l'écran de connexion avec animation
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const LoginScreen(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  // Configuration de l'animation de transition
                                  const begin =
                                      Offset(1.0, 0.0); // Départ de la droite
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));

                                  // Combinaison d'une animation de glissement et de fondu
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

                          // Style du bouton
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
          );
        }),
      ),
    );
  }
}
