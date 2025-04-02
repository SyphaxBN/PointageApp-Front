import 'package:flutter/material.dart';
import 'package:authpage/constants.dart';

/// Composant réutilisable pour basculer entre les écrans de connexion et d'inscription.
/// Affiche un texte et un lien en fonction du contexte (login ou inscription).
class AlreadyHaveAnAccountCheck extends StatelessWidget {
  final bool login; // Indique si on est sur l'écran de connexion
  final Function? press; // Fonction à exécuter lors du clic sur le lien

  const AlreadyHaveAnAccountCheck({
    super.key,
    this.login = true, // Par défaut, on est sur l'écran de connexion
    required this.press, // La fonction de navigation est obligatoire
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Texte qui change selon qu'on est sur l'écran de connexion ou d'inscription
        Text(
          login ? "Don't have an Account ? " : "Already have an Account ? ",
          style: const TextStyle(color: kPrimaryColor),
        ),
        // Lien cliquable pour naviguer vers l'autre écran
        GestureDetector(
          onTap: press as void Function()?,
          child: Text(
            login ? "Sign Up" : "Sign In",
            style: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}
