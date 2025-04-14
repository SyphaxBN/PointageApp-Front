import 'package:flutter/material.dart';
import 'package:authpage/services/api_service.dart';
import 'package:authpage/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

/// Écran de profil utilisateur.
/// Permet à l'utilisateur de visualiser et modifier ses informations personnelles,
/// notamment sa photo de profil, et de se déconnecter.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  // Variables pour stocker les informations utilisateur
  String userName = "Chargement...";
  String userEmail = "Chargement...";
  String userRole = "Chargement...";
  String userPhoto = "default.png";
  bool isUploading = false; // Indicateur de téléchargement d'image en cours
  bool photoUpdated = false; // Indicateur de mise à jour de la photo

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Chargement des données utilisateur au démarrage
  }

  /// Récupère les données de l'utilisateur depuis le stockage local
  /// ou depuis l'API si les données ne sont pas en cache.
  Future<void> fetchUserData() async {
    // Tentative de récupération depuis le stockage local
    String? name = await StorageService.getUserName();
    String? email = await StorageService.getUserEmail();
    String? role = await StorageService.getUserRole();
    String? photo = await StorageService.getUserPhoto();

    // Si les données ne sont pas en cache, on les récupère depuis l'API
    if (name == null || email == null || role == null) {
      final apiService = ApiService();
      final user = await apiService.getUser();
      if (user != null) {
        name = user["name"] ?? "Utilisateur";
        email = user["email"] ?? "Email inconnu";
        role = user["role"] ?? "Rôle inconnu";
        photo = user["photo"] ?? "default.png";

        // Mise en cache des nouvelles données
        await StorageService.saveUserName(name!);
        await StorageService.saveUserEmail(email!);
        await StorageService.saveUserRole(role!);
        await StorageService.saveUserPhoto(photo!);
      }
    }

    // Mise à jour de l'interface utilisateur
    setState(() {
      userName = name ?? "Utilisateur";
      userEmail = email ?? "Email inconnu";
      userRole = role ?? "Rôle inconnu";
      userPhoto = photo ?? "default.png";
    });
  }

  /// Affiche un modal permettant à l'utilisateur de choisir
  /// une source pour sa photo de profil (galerie ou caméra).
  Future<void> _showImageSourceOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Caméra'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Gère la sélection et le téléchargement d'une image
  /// depuis la galerie ou la caméra.
  ///
  /// @param source La source de l'image (galerie ou caméra)
  Future<void> _pickImage(ImageSource source) async {
    bool permissionGranted = false;

    try {
      // Demande de permissions selon la source choisie
      if (source == ImageSource.camera) {
        var cameraStatus = await Permission.camera.request();
        permissionGranted = cameraStatus.isGranted;
        print("📷 Status permission caméra: $cameraStatus");
      } else {
        // Sur Android 13+, nous utilisons storage ou photos selon la version
        if (Platform.isAndroid) {
          var storageStatus = await Permission.storage.request();
          var photosStatus = await Permission.photos.request();
          permissionGranted = storageStatus.isGranted || photosStatus.isGranted;
          print("📱 Status permission stockage: $storageStatus");
          print("📱 Status permission photos: $photosStatus");
        } else {
          var photoStatus = await Permission.photos.request();
          permissionGranted = photoStatus.isGranted;
          print("📱 Status permission photos: $photoStatus");
        }
      }

      // Si l'utilisateur a refusé les permissions
      if (!permissionGranted) {
        print(
            "❌ Permission refusée: Camera=${source == ImageSource.camera}, Gallery=${source == ImageSource.gallery}");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  "Permission refusée pour accéder aux photos ou à la caméra")));

          // Proposer d'ouvrir les paramètres de l'application
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text("Permissions requises"),
              content: const Text(
                  "Pour utiliser cette fonctionnalité, vous devez autoriser l'accès à la caméra et au stockage dans les paramètres de l'application."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Annuler"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  child: const Text("Ouvrir les paramètres"),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Sélection de l'image avec ImagePicker
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70, // Compression de l'image pour optimiser le transfert
      );

      if (image != null) {
        setState(() {
          isUploading = true; // Début du téléchargement
        });

        // Afficher des informations de debug sur le fichier
        File imageFile = File(image.path);
        int fileSize = await imageFile.length();
        print("📸 Image sélectionnée: ${image.path}");
        print(
            "📸 Taille du fichier: ${(fileSize / 1024).toStringAsFixed(2)} KB");

        // Vérifier si le fichier existe avant de l'envoyer
        if (!await imageFile.exists()) {
          setState(() {
            isUploading = false;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Le fichier image n'existe pas")));
          }
          return;
        }

        // Téléchargement de l'image sur le serveur
        String? uploadedPhotoUrl =
            await apiService.uploadProfilePhoto(image.path);

        setState(() {
          isUploading = false; // Fin du téléchargement
        });

        if (uploadedPhotoUrl != null) {
          await StorageService.saveUserPhoto(uploadedPhotoUrl);

          setState(() {
            userPhoto = uploadedPhotoUrl;
            photoUpdated = true; // Marquer que la photo a été mise à jour
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Photo de profil mise à jour !")));
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    "Échec de la mise à jour de la photo. Vérifiez le format et la taille de l'image.")));
          }
        }
      }
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
      print("Erreur lors de la sélection/upload de l'image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Modification de la gestion de l'URL de l'image de profil
    String imageUrl = "";
    if (userPhoto != "default.png" && userPhoto.isNotEmpty) {
      imageUrl = userPhoto.startsWith('/')
          ? "http://192.168.1.7:8000$userPhoto"
          : "http://192.168.1.7:8000/$userPhoto";
    }

    // Configuration responsive
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Ajustement des dimensions
    final double avatarRadius =
        isLandscape ? screenSize.height * 0.15 : screenSize.width * 0.15;

    return WillPopScope(
      // Intercepter le retour arrière pour retourner l'état de mise à jour
      onWillPop: () async {
        Navigator.pop(context, photoUpdated);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE6F0FA),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                // Éléments de design - cercles bleus
                Positioned(
                  top: -10,
                  left: -85,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      color: Color(0xFFB3DAF1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: -100,
                  left: -8,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      color: Color(0xFF80C7E8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Bouton de retour
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.pop(context, photoUpdated);
                    },
                  ),
                ),

                // Contenu principal avec défilement
                Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Photo de profil avec bouton d'édition
                          Stack(
                            children: [
                              isUploading
                                  ? CircleAvatar(
                                      radius: avatarRadius,
                                      backgroundColor: Colors.grey[200],
                                      child: const CircularProgressIndicator(),
                                    )
                                  : CircleAvatar(
                                      radius: avatarRadius,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: imageUrl.isNotEmpty
                                          ? NetworkImage(imageUrl)
                                              as ImageProvider
                                          : null,
                                      child: imageUrl.isEmpty
                                          ? Icon(Icons.person,
                                              size: avatarRadius * 0.7,
                                              color: Colors.grey[600])
                                          : null,
                                    ),
                              // Bouton d'édition de la photo
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: IconButton(
                                    onPressed: _showImageSourceOptions,
                                    icon: const Icon(Icons.edit,
                                        color: Colors.white, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Disposition adaptative pour les informations utilisateur
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  isLandscape ? screenSize.width * 0.1 : 0,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isLandscape
                                    ? screenSize.width * 0.6
                                    : screenSize.width * 0.9,
                              ),
                              child: Column(
                                children: [
                                  // Carte avec informations utilisateur
                                  Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 20, horizontal: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Nom utilisateur
                                          Row(
                                            children: [
                                              const Icon(Icons.person,
                                                  color: Colors.blue),
                                              const SizedBox(width: 10),
                                              Text(
                                                userName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 15),
                                          // Email utilisateur
                                          Row(
                                            children: [
                                              const Icon(Icons.email,
                                                  color: Colors.blue),
                                              const SizedBox(width: 10),
                                              Text(
                                                userEmail,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 15),
                                          // Rôle utilisateur
                                          Row(
                                            children: [
                                              const Icon(Icons.work,
                                                  color: Colors.blue),
                                              const SizedBox(width: 10),
                                              Text(
                                                userRole,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Bouton de déconnexion
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isLandscape
                                          ? screenSize.width * 0.4
                                          : screenSize.width * 0.6,
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        // Suppression des données utilisateur lors de la déconnexion
                                        await StorageService.removeToken();
                                        await StorageService.clearUserData();
                                        await StorageService.clearStorage();

                                        if (context.mounted) {
                                          // Redirection vers l'écran de connexion
                                          Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              '/login',
                                              (route) => false);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 24),
                                      ),
                                      child: const Text(
                                        "Déconnexion",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
