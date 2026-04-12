import 'package:flutter/material.dart';
import '../widgets/menu_item.dart';
import '../widgets/history_item.dart';
import '../services/location_service.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription? _locationSub;
  bool isSOSActive = false;

  
  void startSOS() {
    setState(() => isSOSActive = true);

    _locationSub =
        LocationService.getLocationStream().listen((position) {
      print("REALTIME: ${position.latitude}, ${position.longitude}");

    
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SOS Aktif 🚨")),
    );
  }

  
  void stopSOS() {
    _locationSub?.cancel();
    setState(() => isSOSActive = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SOS Dihentikan")),
    );
  }

  
  Future<void> sendLocationOnce() async {
    final position = await LocationService.getCurrentLocation();

    if (position != null) {
      print("LAT: ${position.latitude}");
      print("LONG: ${position.longitude}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Lokasi: ${position.latitude}, ${position.longitude}"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal ambil lokasi")),
      );
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello 👋", style: TextStyle(color: Colors.grey)),
                      Text("David",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white),
                  )
                ],
              ),

              const SizedBox(height: 25),

              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1749FC), Color(0xFF3D7BFF)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning,
                        color: Colors.white, size: 40),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text("Emergency? Tap SOS!",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isSOSActive ? Colors.red : Colors.white,
                        foregroundColor:
                            isSOSActive ? Colors.white : Colors.blue,
                      ),
                      onPressed: () {
                        if (isSOSActive) {
                          stopSOS();
                        } else {
                          startSOS();
                        }
                      },
                      child: Text(isSOSActive ? "STOP" : "SOS"),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text("Services",
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 15),

              GridView.count(
  crossAxisCount: 2,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisSpacing: 15,
  mainAxisSpacing: 15,
  children: [
    MenuItem(
      icon: Icons.local_hospital,
      title: "Ambulans",
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Panggil Ambulans 🚑")),
        );
      },
    ),
    MenuItem(
      icon: Icons.local_fire_department,
      title: "Kebakaran",
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Laporan Kebakaran 🔥")),
        );
      },
    ),
    MenuItem(
      icon: Icons.local_police,
      title: "Kriminal",
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Laporan Kriminal 👮")),
        );
      },
    ),
    MenuItem(
      icon: Icons.map,
      title: "Rumah Sakit",
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cari Rumah Sakit 🏥")),
        );
      },
    ),
  ],
),
              const SizedBox(height: 25),

              const Text("Recent Activity",
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 10),

              const HistoryItem(title: "Laporan SOS", time: "10 menit lalu"),
              const HistoryItem(title: "Panggil Ambulans", time: "Kemarin"),
            ],
          ),
        ),
      ),
    );
  }
}