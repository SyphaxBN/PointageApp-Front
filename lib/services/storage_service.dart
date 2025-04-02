import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion du stockage local de l'application.
/// Permet de sauvegarder et récupérer des données persistantes
/// telles que le token d'authentification, les informations utilisateur, etc.
/// Utilise SharedPreferences pour stocker les données de manière sécurisée.
class StorageService {
  /// Sauvegarde le token d'authentification dans le stockage local.
  /// @param token Le token JWT à sauvegarder
  static Future<void> saveToken(String token) async {
    if (token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    }
  }

  /// Récupère le token d'authentification depuis le stockage local.
  /// @return Le token JWT stocké ou null si non trouvé/invalide
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    return token?.isNotEmpty == true ? token : null;
  }

  /// Supprime le token d'authentification du stockage local.
  /// Utile lors de la déconnexion de l'utilisateur.
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// Efface toutes les données stockées localement.
  /// Utilisé lors de la déconnexion complète ou réinitialisation de l'application.
  static Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Efface toutes les données stockées
  }

  /// Sauvegarde l'identifiant de l'utilisateur dans le stockage local.
  /// @param userId L'identifiant unique de l'utilisateur
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  /// Récupère l'identifiant de l'utilisateur depuis le stockage local.
  /// @return L'identifiant utilisateur ou null si non trouvé
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  /// Supprime l'identifiant de l'utilisateur du stockage local.
  static Future<void> removeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  /// Efface les données spécifiques aux pointages de l'utilisateur.
  /// Utilisé pour réinitialiser l'état de pointage sans effacer
  /// les informations d'identification de l'utilisateur.
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs
        .remove('lastAttendance'); // Supprime les données du dernier pointage
  }

  /// Sauvegarde le nom de l'utilisateur dans le stockage local.
  /// @param name Le nom de l'utilisateur
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  /// Récupère le nom de l'utilisateur depuis le stockage local.
  /// @return Le nom de l'utilisateur ou null si non trouvé
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  /// Supprime le nom de l'utilisateur du stockage local.
  static Future<void> removeUserName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
  }

  /// Sauvegarde le rôle de l'utilisateur dans le stockage local.
  /// @param role Le rôle de l'utilisateur (ex: "admin", "user")
  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
  }

  /// Récupère le rôle de l'utilisateur depuis le stockage local.
  /// @return Le rôle de l'utilisateur ou null si non trouvé
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole');
  }

  /// Sauvegarde l'email de l'utilisateur dans le stockage local.
  /// @param email L'adresse email de l'utilisateur
  static Future<void> saveUserEmail(String email) async {
    if (email.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
    }
  }

  /// Récupère l'email de l'utilisateur depuis le stockage local.
  /// @return L'email de l'utilisateur ou null si non trouvé
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  /// Supprime l'email de l'utilisateur du stockage local.
  static Future<void> removeUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
  }

  /// Sauvegarde l'URL de la photo de profil de l'utilisateur.
  /// @param imageUrl L'URL de l'image de profil
  static Future<void> saveUserPhoto(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_photo', imageUrl);
  }

  /// Récupère l'URL de la photo de profil de l'utilisateur.
  /// @return L'URL de l'image ou null si non trouvée
  static Future<String?> getUserPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_photo');
  }
}

final storageService = StorageService();
