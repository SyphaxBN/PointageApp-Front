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

    if (name == null) {
      final apiService = ApiService();
      final user = await apiService.getUser();
      if (user != null && user.containsKey("name")) {
        name = user["name"];
        await StorageService.saveUserName(name!);
      }
    }

    // 🔵 Appel API pour récupérer le dernier pointage
    final lastAttendance = await AttendanceService.getLastAttendance();

    print(
        "🔵 Réponse API getLastAttendance: $lastAttendance"); // 🔥 Vérification des données reçues

    // ✅ Vérifie si les données sont bien mises à jour
    setState(() {
      userName = name ?? "Utilisateur";
      todayDate = formatDate(DateTime.now());

      if (lastAttendance != null) {
        clockInTime = lastAttendance["clockIn"] ?? "--:--";
        clockOutTime = lastAttendance["clockOut"] ?? "Not yet";
        lastLocation = lastAttendance["location"] ?? "Localisation inconnue";

        print(
            "🟢 Mise à jour UI - clockIn: $clockInTime, clockOut: $clockOutTime, location: $lastLocation"); // ✅ Debug UI
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
              Text("Veuillez activer la localisation dans les paramètres."),
        ),
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
      desiredAccuracy: LocationAccuracy.high, // Assure une meilleure précision
    );
  }

  Future<void> handleClockIn() async {
    await requestLocationPermission();
    Position? position = await getCurrentLocation();
    if (position == null) return;

    print(
        "📍 Tentative de pointage avec : Latitude: ${position.latitude}, Longitude: ${position.longitude}");

    bool success =
        await AttendanceService.clockIn(position.latitude, position.longitude);
    if (success) {
      await Future.delayed(const Duration(
          seconds:
              2)); // ⚡ Donne un petit délai avant de récupérer les nouvelles données
      await fetchUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pointage d'arrivée réussi!")),
      );
    }
  }

  Future<void> handleClockOut() async {
    await requestLocationPermission();
    Position? position = await getCurrentLocation();
    if (position == null) return;

    bool success =
        await AttendanceService.clockOut(position.latitude, position.longitude);
    if (success) {
      await fetchUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pointage de départ réussi!")),
      );
    }
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
                          Text(userName,
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
                    "Bienvenue chez Beko, $userName!",
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
                            const Text("Today's status",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
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
                                const Text("Clock in",
                                    style: TextStyle(fontSize: 14)),
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
                                const Text("Clock Out",
                                    style: TextStyle(fontSize: 14)),
                                Text(clockOutTime,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                              ],
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
                          child: const Text("Clock In"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: handleClockOut,
                          child: const Text("Clock Out"),
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
