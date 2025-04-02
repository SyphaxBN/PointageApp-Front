import 'package:flutter/material.dart';

/// Classe utilitaire pour la gestion de l'interface responsive.
/// Permet d'adapter l'interface utilisateur en fonction de la taille de l'écran.
class Responsive extends StatelessWidget {
  final Widget mobile; // Interface pour les appareils mobiles
  final Widget? tablet; // Interface optionnelle pour les tablettes
  final Widget desktop; // Interface pour les ordinateurs de bureau

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Détermine si l'appareil actuel est considéré comme un mobile.
  /// @param context Le contexte de construction
  /// @return true si la largeur de l'écran est inférieure à 576px
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 576;

  /// Détermine si l'appareil actuel est considéré comme une tablette.
  /// @param context Le contexte de construction
  /// @return true si la largeur de l'écran est entre 576px et 992px
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 576 &&
      MediaQuery.of(context).size.width <= 992;

  /// Détermine si l'appareil actuel est considéré comme un ordinateur de bureau.
  /// @param context Le contexte de construction
  /// @return true si la largeur de l'écran est supérieure à 992px
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > 992;

  @override
  Widget build(BuildContext context) {
    // Récupération de la taille de l'écran actuel
    final Size size = MediaQuery.of(context).size;

    // Sélection de l'interface appropriée en fonction de la largeur de l'écran
    if (size.width > 992) {
      return desktop; // Interface pour ordinateur de bureau
    } else if (size.width >= 576 && tablet != null) {
      return tablet!; // Interface pour tablette (si disponible)
    } else {
      return mobile; // Interface mobile par défaut
    }
  }
}
