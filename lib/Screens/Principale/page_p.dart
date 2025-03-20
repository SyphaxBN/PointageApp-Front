import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:authpage/services/api_service.dart';
import 'package:authpage/services/storage_service.dart';
import 'package:authpage/services/attendance_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String userName = "Chargement...";
  String clockInTime = "--:--";
  String clockOutTime = "Not yet";
  String lastLocation = "Localisation inconnue";
  String todayDate = "Chargement...";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    String? name = await StorageService.getUserName();

    if (name == null || name.isEmpty) {
      // 🔹 Vérifie que le nom est bien récupéré
      final apiService = ApiService();
      final user = await apiService.getUser();
      if (user != null && user.containsKey("name")) {
        name = user["name"];
        await StorageService.saveUserName(name!);
      }
    }

    final lastAttendance = await AttendanceService.getLastAttendance();
    print("🔍 Vérification de lastAttendance : $lastAttendance");

    setState(() {
      userName = name ?? "Utilisateur";
      todayDate = formatDate(DateTime.now());

      if (lastAttendance != null) {
        clockInTime = lastAttendance["clockInTime"] ?? "--:--";
        clockOutTime = lastAttendance["clockOutTime"] ?? "Pas encore";
        lastLocation = lastAttendance["location"] ?? "Localisation inconnue";
      } else {
        clockInTime = "--:--";
        clockOutTime = "Pas encore";
        lastLocation = "Aucune donnée disponible";
      }
    });
  }

  String formatDate(DateTime date) {
    return "${date.day} ${getMonthName(date.month)}, ${date.year}";
  }

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

  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission de localisation refusée.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Veuillez activer la localisation dans les paramètres.")),
      );
      return;
    }
  }

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activez la localisation pour pointer.")),
      );
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> ensureLocationServiceEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
  }

  Future<void> handleClockIn() async {
    print("🚀 Début du pointage d'arrivée");
    await ensureLocationServiceEnabled();
    await requestLocationPermission();
    Position? position = await getCurrentLocation();
    if (position == null) {
      print("⚠️ Impossible d'obtenir la position");
      return;
    }

    print("📍 Position actuelle : ${position.latitude}, ${position.longitude}");

    bool success =
        await AttendanceService.clockIn(position.latitude, position.longitude);
    print(success
        ? "✅ Pointage d'arrivée réussi"
        : "❌ Pointage d'arrivée échoué");

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vous êtes trop loin du lieu de pointage !")),
      );
      return;
    }

    await fetchUserData();
    print("🔄 Données utilisateur mises à jour après pointage d'arrivée");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pointage d'arrivée réussi!")),
    );
  }

  Future<void> handleClockOut() async {
    print("🚀 Début du pointage de départ");
    await ensureLocationServiceEnabled();
    await requestLocationPermission();
    Position? position = await getCurrentLocation();
    if (position == null) {
      print("⚠️ Impossible d'obtenir la position");
      return;
    }

    print("📍 Position actuelle : ${position.latitude}, ${position.longitude}");

    bool success =
        await AttendanceService.clockOut(position.latitude, position.longitude);
    print(success
        ? "✅ Pointage de départ réussi"
        : "❌ Pointage de départ échoué");

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vous êtes trop loin du lieu de pointage !")),
      );
      return;
    }

    await fetchUserData();
    print("🔄 Données utilisateur mises à jour après pointage de départ");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pointage de départ réussi!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, // ✅ Nom correctement mis à jour
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text("employé",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blueAccent,
                        child:
                            Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Bienvenue chez Beko, $userName!", // ✅ Correction affichage du nom
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.blue),
                                const SizedBox(width: 5),
                                const Text("Status d'Aujourd'hui",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Text(todayDate,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        color: Colors.green),
                                    const SizedBox(width: 5),
                                    const Text("Arrivée",
                                        style: TextStyle(fontSize: 14)),
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
                                    const Icon(Icons.access_time,
                                        color: Colors.orange),
                                    const SizedBox(width: 5),
                                    const Text("Départ",
                                        style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                                Text(clockOutTime,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10), // 🔹 Ajout d'un espacement
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
                                overflow: TextOverflow
                                    .visible, // Permet d'afficher tout le texte
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: handleClockIn,
                          child: const Text("Arrivée"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: handleClockOut,
                          child: const Text("Départ"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
