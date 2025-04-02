import 'package:authpage/services/storage_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'dart:math';

/// Service de gestion des appels API vers le backend.
/// Centralise toutes les communications HTTP entre l'application mobile
/// et le serveur backend, gère l'authentification et les erreurs réseau.
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

  /// Constructeur du service API.
  /// Initialise les intercepteurs et configure le client HTTP.
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

  /// Initialise les intercepteurs pour ajouter automatiquement le token d'authentification
  /// à toutes les requêtes sortantes.
  void _initializeInterceptors() async {
    String? token = await StorageService.getToken(); // ✅ Récupération unifiée

    if (token != null) {
      dio.options.headers["Authorization"] = "Bearer $token";
    } else {}
  }

  /// Effectue une requête HTTP POST vers l'endpoint spécifié.
  /// 
  /// @param endpoint L'URL de l'endpoint à appeler, relative à l'URL de base
  /// @param data Les données à envoyer dans le corps de la requête
  /// @return L'objet Response contenant la réponse du serveur
  /// @throws Future.error en cas d'erreur de communication
  Future<Response> post(String endpoint, Map<String, dynamic> data) async {
    try {
      return await dio.post(endpoint, data: data);
    } catch (e) {
      return Future.error("Erreur lors de la requête : $e");
    }
  }

  /// Effectue une requête HTTP GET vers l'endpoint spécifié.
  /// 
  /// @param endpoint L'URL de l'endpoint à appeler, relative à l'URL de base
  /// @return L'objet Response contenant la réponse du serveur
  /// @throws Future.error en cas d'erreur de communication
  Future<Response> get(String endpoint) async {
    try {
      return await dio.get(endpoint);
    } catch (e) {
      return Future.error("Erreur lors de la requête : $e");
    }
  }

  /// Sauvegarde le token d'authentification dans le stockage local.
  /// 
  /// @param token Le token JWT à sauvegarder
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  /// Récupère les informations de l'utilisateur connecté depuis le backend.
  /// 
  /// @return Un objet Map contenant les données de l'utilisateur ou null en cas d'échec
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

  /// Télécharge une photo de profil utilisateur vers le serveur.
  /// Gère la validation du fichier, la détermination du type MIME et la gestion des erreurs.
  /// 
  /// @param filePath Le chemin local vers le fichier image à télécharger
  /// @return L'URL de l'image téléchargée sur le serveur, ou null en cas d'échec
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

      // Envoi de la requête au serveur
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

      // Traitement de la réponse
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

// Instance singleton du service API, utilisable dans toute l'application
final apiService = ApiService();
