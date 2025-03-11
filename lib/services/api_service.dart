import 'package:authpage/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio dio = Dio(
      BaseOptions(baseUrl: "http://10.0.2.2:8000")); // Pour l'émulateur Android

  ApiService() {
    _initializeInterceptors();
  }

  void _initializeInterceptors() async {
    String? token = await StorageService.getToken(); // ✅ Récupération unifiée

    if (token != null) {
      dio.options.headers["Authorization"] = "Bearer $token";
      print("Token chargé dans ApiService : $token"); // 🔍 Debug
    } else {
      print("Aucun token trouvé dans StorageService !");
    }
  }

  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      return await dio.post(endpoint, data: data);
    } catch (e) {
      return Future.error("Erreur lors de la requête : $e");
    }
  }

  Future<Response> get(String endpoint) async {
    try {
      return await dio.get(endpoint);
    } catch (e) {
      return Future.error("Erreur lors de la requête : $e");
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final response = await dio.get("/auth");

      print("Réponse API getUser(): ${response.data}"); // 🔍 Debug

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("Erreur getUser() : $e");
    }
    return null;
  }
}

final apiService = ApiService();
