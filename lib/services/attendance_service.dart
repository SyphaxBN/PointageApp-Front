import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:authpage/services/storage_service.dart';

/// Service de gestion des pointages des utilisateurs.
/// Gère les interactions avec l'API backend pour enregistrer les entrées/sorties,
/// récupérer l'historique des pointages et le dernier pointage.
class AttendanceService {
  /// URL de base pour les appels API liés aux pointages
  static const String baseUrl = 'http://192.168.1.7:8000/attendance';

  /// Enregistre un pointage d'entrée (arrivée) pour l'utilisateur.
  /// @param latitude La latitude de la position de l'utilisateur lors du pointage
  /// @param longitude La longitude de la position de l'utilisateur lors du pointage
  /// @return Un message d'erreur ou null si le pointage est réussi
  static Future<String?> clockIn(double latitude, double longitude) async {
    return await _recordAttendance("clock-in", latitude, longitude);
  }

  /// Enregistre un pointage de sortie (départ) pour l'utilisateur.
  /// @param latitude La latitude de la position de l'utilisateur lors du pointage
  /// @param longitude La longitude de la position de l'utilisateur lors du pointage
  /// @return Un message d'erreur ou null si le pointage est réussi
  static Future<String?> clockOut(double latitude, double longitude) async {
    return await _recordAttendance("clock-out", latitude, longitude);
  }

  /// Fonction interne qui gère l'enregistrement des pointages.
  /// Mutualise le code pour les pointages d'entrée et de sortie.
  /// 
  /// @param type Le type de pointage ("clock-in" ou "clock-out")
  /// @param latitude La latitude de la position de l'utilisateur
  /// @param longitude La longitude de la position de l'utilisateur
  /// @return Un message d'erreur ou null si le pointage est réussi
  static Future<String?> _recordAttendance(
      String type, double latitude, double longitude) async {
    try {
      // Récupération du token d'authentification
      String? token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return "Token non disponible";
      }

      // Envoi de la requête au serveur
      final response = await http.post(
        Uri.parse('$baseUrl/$type'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      // Traitement de la réponse
      if (response.statusCode == 201) {
        return null; // ✅ Succès
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData['message'] ??
            "Erreur inconnue"; // Retourne le message d'erreur du backend
      }
    } catch (e) {
      return "Une erreur est survenue : $e";
    }
  }

  /// Récupère l'historique complet des pointages de l'utilisateur.
  /// Convertit les données du backend dans un format adapté à l'interface utilisateur.
  /// 
  /// @return Une liste de pointages formatée pour l'affichage
  static Future<List<Map<String, dynamic>>> getAttendanceHistory() async {
    try {
      // Récupération du token d'authentification
      String? token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Token non disponible");
      }

      // Appel au backend pour récupérer l'historique
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Transformation des données pour l'affichage
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        List<Map<String, dynamic>> parsedResponse = [];

        // Traitement de chaque enregistrement
        for (var record in jsonResponse) {
          String? clockIn = record['clockIn'];
          String? clockOut = record['clockOut'];
          String location = record['location'] ?? 'Localisation inconnue';

          // Ajouter le pointage d'entrée s'il existe
          if (clockIn != null) {
            parsedResponse.add({
              'type': "Entrée",
              'time': clockIn,
              'location': location,
            });
          }

          // Ajouter le pointage de sortie s'il existe
          if (clockOut != null) {
            parsedResponse.add({
              'type': "Sortie",
              'time': clockOut,
              'location': location,
            });
          }
        }

        // 🔍 Affichage des données après traitement pour debugging
        // ignore: unused_local_variable
        for (var record in parsedResponse) {}

        return parsedResponse;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Récupère le dernier pointage de l'utilisateur connecté.
  /// Utilisé pour afficher le statut actuel de pointage sur l'écran d'accueil.
  /// 
  /// @return Les informations du dernier pointage ou null si aucun pointage n'existe
  static Future<Map<String, dynamic>?> getLastAttendance() async {
    try {
      // Récupération du token d'authentification
      String? token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      // Appel au backend pour récupérer le dernier pointage
      final response = await http.get(
        Uri.parse('$baseUrl/last'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse;
      } else if (response.statusCode == 404) {
        return null; // Aucun pointage trouvé
      } else {
        return null; // Erreur de serveur ou autre
      }
    } catch (e) {
      return null; // Erreur lors de la requête
    }
  }
}
