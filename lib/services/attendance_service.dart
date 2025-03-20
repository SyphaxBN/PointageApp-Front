import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:authpage/services/storage_service.dart';

class AttendanceService {
  static const String baseUrl = 'http://10.0.2.2:8000/attendance';

  /// Enregistre un pointage d'arrivée
  static Future<bool> clockIn(double latitude, double longitude) async {
    return await _recordAttendance("clock-in", latitude, longitude);
  }

  /// Enregistre un pointage de départ
  static Future<bool> clockOut(double latitude, double longitude) async {
    return await _recordAttendance("clock-out", latitude, longitude);
  }

  /// Fonction interne pour enregistrer un pointage
  static Future<bool> _recordAttendance(
      String type, double latitude, double longitude) async {
    try {
      String? token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

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

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Récupère l'historique des pointages
  static Future<List<Map<String, dynamic>>> getAttendanceHistory() async {
    try {
      String? token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Token non disponible");
      }

      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        List<Map<String, dynamic>> parsedResponse = [];

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

        // 🔍 Affichage des données après traitement
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

  /// 📌 Récupère le dernier pointage de l'utilisateur connecté
  static Future<Map<String, dynamic>?> getLastAttendance() async {
    try {
      String? token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

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
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
