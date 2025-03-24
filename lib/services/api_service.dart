import 'package:authpage/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio dio = Dio(
      BaseOptions(baseUrl: "http://10.0.2.2:8000")); // Pour l'émulateur Android
  // final Dio dio = Dio(BaseOptions(
  // baseUrl:
  // "http://192.168.1.7:8000") // Remplace par l'IP de ton PC ou par localhost
  // );

  ApiService() {
    _initializeInterceptors();
  }

  void _initializeInterceptors() async {
    String? token = await StorageService.getToken(); // ✅ Récupération unifiée

    if (token != null) {
      dio.options.headers["Authorization"] = "Bearer $token";
    } else {}
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
      final token = await StorageService.getToken();

      final response = await dio.get(
        "/auth",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final user = response.data;
        print("📌 Données utilisateur récupérées : $user"); // Debugging

        if (user.containsKey("role")) {
          await StorageService.saveUserRole(user["role"]); // 🔹 Stocke le rôle
          print("✅ Rôle stocké : ${user["role"]}"); // Debugging
        }

        return user;
      }
    } catch (e) {
      print("❌ Erreur dans getUser(): $e");
    }
    return null;
  }
}

final apiService = ApiService();
