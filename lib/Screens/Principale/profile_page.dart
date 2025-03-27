import 'package:flutter/material.dart';
import 'package:authpage/services/api_service.dart';
import 'package:authpage/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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

  Future<void> pickImage() async {
    var status = await Permission.photos
        .request(); // Demande la permission d'accès aux photos

    if (status.isGranted) {
      try {
        final pickedFile =
            await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          print("Image sélectionnée : ${pickedFile.path}");
        } else {
          print("Aucune image sélectionnée.");
        }
      } catch (e) {
        print("Erreur lors de la sélection de l'image : $e");
      }
    } else {
      print("Permission refusée.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Décorations en arrière-plan (cercles)
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

            // Bouton retour au premier plan
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar avec bouton d'édition
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundImage: userPhoto.isNotEmpty
                              ? NetworkImage("http://10.0.2.2:8000$userPhoto")
                                  as ImageProvider
                              : null,
                          child: userPhoto.isEmpty
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
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              onPressed: () async {
                                final ImagePicker picker = ImagePicker();
                                final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery);

                                if (image != null) {
                                  String? uploadedPhotoUrl = await apiService
                                      .uploadProfilePhoto(image.path);

                                  if (uploadedPhotoUrl != null) {
                                    await StorageService.saveUserPhoto(
                                        uploadedPhotoUrl);

                                    setState(() {
                                      userPhoto = uploadedPhotoUrl;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Photo de profil mise à jour !")),
                                    );
                                  }
                                }
                              },
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

                    // Carte avec infos utilisateur
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5, // Ombre ajoutée
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

                    const SizedBox(height: 20), // Espacement augmenté

                    // Bouton de déconnexion
                    ElevatedButton(
                      onPressed: () async {
                        // Effacer toutes les données stockées
                        await StorageService.removeToken(); // Supprime le token
                        await StorageService
                            .clearUserData(); // Supprime les infos de l'utilisateur
                        await StorageService.clearStorage();

                        // Rediriger vers la page de connexion et supprimer l'historique de navigation
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
    );
  }
}
