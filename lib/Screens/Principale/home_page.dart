import 'package:authpage/Screens/Principale/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:authpage/services/api_service.dart';
import 'package:authpage/services/storage_service.dart';
import 'package:authpage/services/attendance_service.dart';

/// Page d'accueil principale de l'application.
/// Affiche les informations de pointage de l'utilisateur connecté
/// et permet d'effectuer des pointages d'entrée et de sortie.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // Variables pour stocker les informations utilisateur et de pointage
  String userName = "Chargement...";
  String userRole = "Chargement...";
  String userPhoto = "default.png";
  String clockInTime = "--:--";
  String clockOutTime = "Not yet";
  String lastLocation = "Localisation inconnue";
  String todayDate = "Chargement...";

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Récupération des données utilisateur dès l'initialisation
  }

  /// Récupère les données de l'utilisateur et son dernier pointage.
  /// Les données sont chargées depuis le stockage local en priorité,
  /// puis depuis l'API si nécessaire.
  Future<void> fetchUserData() async {
    // Récupération des informations depuis le stockage local
    String? name = await StorageService.getUserName();
    String? role = await StorageService.getUserRole();
    String? photo = await StorageService.getUserPhoto();
    String? userId =
        await StorageService.getUserId(); // Récupération de l'ID utilisateur

    print("📌 Rôle récupéré du storage: $role");

    // Vérification si les données sont absentes ou incomplètes
    if (name == null ||
        name.isEmpty ||
        role == null ||
        role.isEmpty ||
        userId == null) {
      final apiService = ApiService();
      final user =
          await apiService.getUser(); // Récupération des données via API

      if (user != null) {
        // Stockage des données récupérées
        if (user.containsKey("name")) {
          name = user["name"];
          await StorageService.saveUserName(name!);
        }
        if (user.containsKey("role")) {
          role = user["role"];
          print("✅ Rôle final après API : $role");
          await StorageService.saveUserRole(role!);
        }
        if (user.containsKey("photo") && user["photo"] != null) {
          photo = user["photo"];
          await StorageService.saveUserPhoto(photo!);
        } else {
          photo = "default.png";
        }
        if (user.containsKey("id")) {
          userId = user["id"];
          await StorageService.saveUserId(userId!);
        }
      }
    }

    // Récupération du dernier pointage
    final lastAttendance = await AttendanceService.getLastAttendance();
    print("🔍 lastAttendance récupéré: $lastAttendance");

    // Mise à jour de l'état avec les nouvelles données après le rendu initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        userName = name ?? "Utilisateur";
        userRole = role ?? "Non défini";
        userPhoto = photo ?? "default.png";
        todayDate = formatDate(DateTime.now());

        if (lastAttendance != null && lastAttendance["userId"] == userId) {
          clockInTime = lastAttendance["clockInTime"] ?? "--:--";
          clockOutTime = lastAttendance["clockOutTime"] ?? "Pas encore";
          lastLocation = lastAttendance["location"] ?? "Localisation inconnue";
        } else {
          clockInTime = "--:--";
          clockOutTime = "Pas encore";
          lastLocation = "Aucune donnée disponible";
        }
      });
    });
  }

  /// Formate une date sous la forme "jour mois, année".
  /// @param date La date à formater
  /// @return La date formatée comme chaîne de caractères
  String formatDate(DateTime date) {
    return "${date.day} ${getMonthName(date.month)}, ${date.year}";
  }

  /// Convertit un numéro de mois en son nom en anglais.
  /// @param month Le numéro du mois (1-12)
  /// @return Le nom du mois correspondant
  String getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }

  /// Vérifie et demande la permission de localisation à l'utilisateur.
  /// Affiche des messages d'erreur appropriés en cas de refus.
  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Permission de localisation refusée.")));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("Veuillez activer la localisation dans les paramètres.")));
      return;
    }
  }

  /// Récupère la position actuelle de l'utilisateur.
  /// @return L'objet Position contenant latitude et longitude, ou null en cas d'échec
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Activez la localisation pour pointer.")));
      return null;
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Vérifie si le service de localisation est activé sur l'appareil.
  /// Ouvre les paramètres système si désactivé.
  Future<void> ensureLocationServiceEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
  }

  /// Gère le processus de pointage d'arrivée (entrée).
  /// Vérifie les permissions, récupère la position actuelle et envoie les données au backend.
  Future<void> handleClockIn() async {
    print("🚀 Début du pointage d'arrivée");
    await ensureLocationServiceEnabled();
    await requestLocationPermission();
    Position? position = await getCurrentLocation();
    if (position == null) return;

    print("📍 Position actuelle : ${position.latitude}, ${position.longitude}");
    String? errorMessage =
        await AttendanceService.clockIn(position.latitude, position.longitude);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    print("✅ Pointage d'arrivée réussi, mise à jour des données...");

    // Récupération immédiate du dernier pointage
    final lastAttendance = await AttendanceService.getLastAttendance();

    // 🔥 Mise à jour immédiate de l'UI
    setState(() {
      clockInTime = lastAttendance?["clockInTime"] ?? "--:--";
      clockOutTime = lastAttendance?["clockOutTime"] ?? "Pas encore";
      lastLocation = lastAttendance?["location"] ?? "Localisation inconnue";
    });

    print("✅ Données mises à jour avec succès !");
  }

  /// Gère le processus de pointage de départ (sortie).
  /// Similaire à handleClockIn mais pour la sortie.
  Future<void> handleClockOut() async {
    print("🚀 Début du pointage de départ");
    await ensureLocationServiceEnabled();
    await requestLocationPermission();
    Position? position = await getCurrentLocation();
    if (position == null) return;

    print("📍 Position actuelle : ${position.latitude}, ${position.longitude}");
    String? errorMessage =
        await AttendanceService.clockOut(position.latitude, position.longitude);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    print("✅ Pointage de départ réussi, mise à jour des données...");

    // Récupération immédiate du dernier pointage
    final lastAttendance = await AttendanceService.getLastAttendance();

    // 🔥 Mise à jour immédiate de l'UI
    setState(() {
      clockInTime = lastAttendance?["clockInTime"] ?? "--:--";
      clockOutTime = lastAttendance?["clockOutTime"] ?? "Pas encore";
      lastLocation = lastAttendance?["location"] ?? "Localisation inconnue";
    });

    print("✅ Données mises à jour avec succès !");
  }

  @override
  Widget build(BuildContext context) {
    // Configuration responsive
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bool isTablet = screenSize.shortestSide >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FA),
      body: SafeArea(
        child: Stack(
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
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec informations utilisateur et accès au profil
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                  fontSize: isTablet ? 22 : 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              userRole,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 75, 75, 75)),
                            ),
                          ],
                        ),
                        const Spacer(), // Pousse les éléments suivants à droite
                        TextButton(
                          onPressed: () async {
                            // Navigation vers la page de profil avec gestion du retour
                            final result = await Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const ProfilePage(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin =
                                      Offset(1.0, 0.0); // Départ de la droite
                                  const end = Offset.zero;
                                  const curve = Curves.easeInOut;

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));

                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );

                            // Si le résultat indique que des données ont été mises à jour, actualiser
                            if (result == true) {
                              await fetchUserData();
                            } else {
                              // Vérifier si la photo a été mise à jour
                              String? newPhoto =
                                  await StorageService.getUserPhoto();
                              if (newPhoto != null && newPhoto != userPhoto) {
                                setState(() {
                                  userPhoto = newPhoto;
                                });
                              }
                            }
                          },
                          child: const Text(
                            "Profile",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Avatar de l'utilisateur
                        CircleAvatar(
                          radius: isTablet ? 40 : 30,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: userPhoto != "default.png" &&
                                  userPhoto.isNotEmpty
                              ? NetworkImage(userPhoto.startsWith('/')
                                      ? "http://192.168.1.7:8000$userPhoto"
                                      : "http://192.168.1.7:8000/$userPhoto")
                                  as ImageProvider
                              : null,
                          child: userPhoto == "default.png" || userPhoto.isEmpty
                              ? Icon(Icons.person,
                                  size: isTablet ? 30 : 22,
                                  color: Colors.grey[600])
                              : null,
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 30 : 20),
                    // Message de bienvenue personnalisé
                    Text(
                      "Bienvenue chez Beko, $userName!",
                      style: TextStyle(
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: isTablet ? 30 : 20),
                    // Disposition adaptative selon l'orientation
                    isLandscape && !isTablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildAttendanceCard(isTablet),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: _buildActionButtons(),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildAttendanceCard(isTablet),
                              SizedBox(height: isTablet ? 30 : 20),
                              _buildActionButtons(),
                            ],
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

  // Widget pour la carte d'informations de pointage
  Widget _buildAttendanceCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isTablet
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte avec date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 5),
                  const Text("Status d'Aujourd'hui",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(todayDate,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          // Informations d'entrée et sortie
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.green),
                      const SizedBox(width: 5),
                      const Text("Arrivée", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  Text(clockInTime,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.orange),
                      const SizedBox(width: 5),
                      const Text("Départ", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  Text(clockOutTime,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10), // 🔹 Ajout d'un espacement
          // Information de localisation
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  lastLocation.isNotEmpty
                      ? lastLocation
                      : "Localisation inconnue",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget pour les boutons d'action
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: handleClockIn,
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text(
              "Arrivée",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50), // Vert
              foregroundColor: Colors.white,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: handleClockOut,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              "Départ",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935), // Rouge
              foregroundColor: Colors.white,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
