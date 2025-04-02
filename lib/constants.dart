import 'package:flutter/material.dart';

/// URL de base du backend pour les appels API.
/// Configurée pour l'émulateur Android qui utilise 10.0.2.2 pour accéder à localhost.
const String backendUrl = "http://10.0.2.2:8000";

/// Couleur primaire de l'application.
/// Utilisée pour les boutons, les liens et les éléments principaux.
const kPrimaryColor = Color.fromARGB(255, 0, 93, 199);

/// Couleur primaire claire de l'application.
/// Utilisée pour les arrière-plans de champs de formulaire et les zones secondaires.
const kPrimaryLightColor = Color(0xFFF1E6FF);

/// Valeur de padding par défaut utilisée dans toute l'application.
/// Permet de maintenir une cohérence dans les espacements.
const double defaultPadding = 16.0;
