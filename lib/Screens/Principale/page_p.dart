import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:authpage/constants.dart';
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
  List<Map<String, dynamic>> attendanceHistory = [];

  @override
  void initState() {
    super.initState();
    fetchUserName();
    fetchAttendanceHistory();
  }

  Future<void> fetchUserName() async {
    String? name = await StorageService.getUserName();
    if (name == null) {
      final apiService = ApiService();
      final user = await apiService.getUser();
      if (user != null && user.containsKey("name")) {
        name = user["name"];
        await StorageService.saveUserName(name!);
      }
    }
    if (mounted) {
      setState(() {
        userName = name ?? "Utilisateur";
      });
    }
  }

  Future<void> fetchAttendanceHistory() async {
    final history = await AttendanceService.getAttendanceHistory();
    debugPrint("Historique récupéré: $history"); // Ajoute cette ligne

    if (mounted) {
      setState(() {
        attendanceHistory = history.map((record) {
          return {
            "type": record["type"] ?? "Inconnu",
            "time": record["time"] ?? "Heure inconnue",
            "location": record["location"] ?? "Localisation inconnue"
          };
        }).toList();
      });
    }
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
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> handleClockIn() async {
    await requestLocationPermission();
    Position? position = await getCurrentLocation();
    if (position == null) return;

    bool success =
        await AttendanceService.clockIn(position.latitude, position.longitude);
    if (success) {
      await fetchAttendanceHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pointage d'arrivée réussi!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du pointage.")),
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
      await fetchAttendanceHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pointage de départ réussi!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du pointage.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accueil"),
        backgroundColor: kPrimaryColor,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Employé",
                  style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bienvenue, $userName!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: handleClockIn,
                    child: const Text("Pointer mon arrivée"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: handleClockOut,
                    child: const Text("Pointer mon départ"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Historique des pointages",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: attendanceHistory.isEmpty
                  ? const Center(child: Text("Aucun pointage enregistré."))
                  : ListView.builder(
                      itemCount: attendanceHistory.length,
                      itemBuilder: (context, index) {
                        final record = attendanceHistory[index];
                        return ListTile(
                          title: Text(
                            "${record['type'] ?? 'Inconnu'} à ${record['time'] ?? 'Heure inconnue'}",
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(
                            "Localisation: ${record['location'] ?? 'Localisation inconnue'}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}