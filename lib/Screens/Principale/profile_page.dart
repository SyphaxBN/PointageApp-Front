import 'package:flutter/material.dart';
import 'package:authpage/services/api_service.dart';
import 'package:authpage/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  String userName = "Chargement...";
  String userEmail = "Chargement...";
  String userRole = "Chargement...";
  String userPhoto = "default.png";
  bool isUploading = false;
  bool photoUpdated =
      false; // Variable pour suivre si la photo a été mise à jour

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    String? name = await StorageService.getUserName();
    String? email = await StorageService.getUserEmail();
    String? role = await StorageService.getUserRole();
    String? photo = await StorageService.getUserPhoto();

    if (name == null || email == null || role == null) {
      final apiService = ApiService();
      final user = await apiService.getUser();
      if (user != null) {
        name = user["name"] ?? "Utilisateur";
        email = user["email"] ?? "Email inconnu";
        role = user["role"] ?? "Rôle inconnu";
        photo = user["photo"] ?? "default.png";

        await StorageService.saveUserName(name!);
        await StorageService.saveUserEmail(email!);
        await StorageService.saveUserRole(role!);
        await StorageService.saveUserPhoto(photo!);
      }
    }

    setState(() {
      userName = name ?? "Utilisateur";
      userEmail = email ?? "Email inconnu";
      userRole = role ?? "Rôle inconnu";
      userPhoto = photo ?? "default.png";
    });
  }

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

  Future<void> _pickImage(ImageSource source) async {
    bool permissionGranted = false;

    try {
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

      if (!permissionGranted) {
        print(
            "❌ Permission refusée: Camera=${source == ImageSource.camera}, Gallery=${source == ImageSource.gallery}");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  "Permission refusée pour accéder aux photos ou à la caméra")));

          // Proposer d'ouvrir les paramètres
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

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          isUploading = true;
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

        String? uploadedPhotoUrl =
            await apiService.uploadProfilePhoto(image.path);

        setState(() {
          isUploading = false;
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
    // Correction de l'URL pour ajouter le slash manquant entre le port et le chemin
    String imageUrl = userPhoto.isNotEmpty
        ? (userPhoto.startsWith('/')
            ? "http://192.168.1.8:8000$userPhoto" // Le slash est déjà dans userPhoto
            : "http://192.168.1.8:8000/$userPhoto") // Ajout du slash ici
        : "";

    // Debugging de l'URL construite
    print("🖼️ URL de l'image construite: $imageUrl");

    return WillPopScope(
      // Intercepter le retour arrière pour retourner l'état de mise à jour
      onWillPop: () async {
        Navigator.pop(context, photoUpdated);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE6F0FA),
        body: SafeArea(
          child: Stack(
            children: [
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          isUploading
                              ? CircleAvatar(
                                  radius: 80,
                                  backgroundColor: Colors.grey[200],
                                  child: const CircularProgressIndicator(),
                                )
                              : CircleAvatar(
                                  radius: 80,
                                  backgroundImage: imageUrl.isNotEmpty
                                      ? NetworkImage(imageUrl) as ImageProvider
                                      : null,
                                  child: imageUrl.isEmpty
                                      ? Icon(Icons.person,
                                          size: 80, color: Colors.grey[600])
                                      : null,
                                ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
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
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.blue),
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
                              Row(
                                children: [
                                  const Icon(Icons.email, color: Colors.blue),
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
                              Row(
                                children: [
                                  const Icon(Icons.work, color: Colors.blue),
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
                      ElevatedButton(
                        onPressed: () async {
                          await StorageService.removeToken();
                          await StorageService.clearUserData();
                          await StorageService.clearStorage();

                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (route) => false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                        ),
                        child: const Text(
                          "Déconnexion",
                          style: TextStyle(color: Colors.white),
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
    );
  }
}
