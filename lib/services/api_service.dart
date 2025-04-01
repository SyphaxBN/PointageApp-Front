import 'package:authpage/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'dart:math';

class ApiService {
  // Configuration de Dio avec des options avancées pour la connexion
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "http://192.168.1.8:8000",
      // Augmenter les timeouts pour éviter les "Connection timed out"
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  ApiService() {
    _initializeInterceptors();

    // Ajouter un intercepteur de logging pour déboguer les connexions
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      request: true,
      requestHeader: true,
      responseHeader: true,
    ));
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
      print(
          "🔍 Tentative de connexion au serveur: ${dio.options.baseUrl}/auth");

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
      if (e is DioException) {
        print("🌐 Type d'erreur: ${e.type}");
        print("🔗 URL tentée: ${e.requestOptions.uri}");
        print("⏱️ Timeout? ${e.type == DioExceptionType.connectionTimeout}");

        // Conseils pour la résolution du problème
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          print(
              "⚠️ CONSEIL: Vérifiez que le serveur est en cours d'exécution et accessible");
          print(
              "⚠️ Essayez d'accéder à http://192.168.1.8:8000 dans un navigateur sur votre téléphone");
        }
      }
    }
    return null;
  }

  Future<String?> uploadProfilePhoto(String filePath) async {
    try {
      // Vérifier que le fichier existe
      final file = File(filePath);
      if (!await file.exists()) {
        print("❌ Le fichier n'existe pas: $filePath");
        return null;
      }

      // Vérifier le type MIME du fichier
      final extension = filePath.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        default:
          print("❌ Format de fichier non supporté: $extension");
          return null;
      }
      print("📄 Type MIME du fichier: $mimeType");

      // Obtenir le token pour l'authentification
      final token = await StorageService.getToken();
      if (token == null) {
        print("❌ Aucun token d'authentification trouvé!");
        return null;
      }
      print(
          "🔑 Token d'authentification: ${token.substring(0, min(10, token.length))}...");

      // Créer le FormData avec le fichier sous le nom 'file'
      // C'est crucial que le nom du champ soit 'file' comme attendu par le backend
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          filePath,
          filename: "profile.${extension}",
          contentType: MediaType.parse(mimeType),
        ),
      });

      print("🚀 Envoi de la requête à: /users/upload-photo");
      print(
          "📦 Contenu de FormData: champ 'file' avec le fichier ${file.path}");

      Response response = await dio.post(
        "/users/upload-photo",
        data: formData,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          contentType: "multipart/form-data",
          // Augmenter le timeout pour les uploads volumineux
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Photo uploadée avec succès: ${response.data}");
        return response.data["imageUrl"];
      } else {
        print("❌ Échec de l'upload: ${response.statusCode}, ${response.data}");
        return null;
      }
    } catch (e) {
      print("❌ Erreur lors de l'upload de la photo: $e");
      // Afficher les détails de l'erreur Dio si disponible
      if (e is DioException) {
        print("📝 Détails de l'erreur:");
        print("  - Status code: ${e.response?.statusCode}");
        print("  - Réponse du serveur: ${e.response?.data}");
        print("  - Message: ${e.message}");
      }
      return null;
    }
  }
}

final apiService = ApiService();
