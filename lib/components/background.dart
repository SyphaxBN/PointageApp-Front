import 'package:flutter/material.dart';

/// Composant d'arrière-plan réutilisable pour les écrans de l'application.
/// Fournit un design cohérent avec des images en haut et en bas de l'écran.
class Background extends StatelessWidget {
  final Widget child; // Le contenu principal à afficher
  const Background({
    super.key,
    required this.child,
    this.topImage = "assets/images/main_top.png", // Image en haut (par défaut)
    this.bottomImage =
        "assets/images/login_bottom.png", // Image en bas (par défaut)
  });

  final String topImage, bottomImage; // Chemins des images d'arrière-plan

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Empêche le redimensionnement quand le clavier apparaît
      body: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Image en haut à gauche
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                topImage,
                width: 120,
              ),
            ),
            // Image en bas à droite (actuellement désactivée)
            // Positioned(
            //   bottom: 0,
            //   right: 0,
            //   child: Image.asset(bottomImage, width: 120),
            // ),
            // Contenu principal
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}
