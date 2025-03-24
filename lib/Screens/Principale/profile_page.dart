import 'package:flutter/material.dart';
import 'package:authpage/services/api_service.dart';
import 'package:authpage/services/storage_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Décorations en arrière-plan
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: userPhoto.isNotEmpty
                          ? NetworkImage("http://10.0.2.2:8000$userPhoto")
                              as ImageProvider
                          : null,
                      child: userPhoto.isEmpty
                          ? Icon(Icons.person,
                              size: 50, color: Colors.grey[600])
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(userName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(userEmail,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(userRole,
                        style: const TextStyle(
                            fontSize: 16, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 20),
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
