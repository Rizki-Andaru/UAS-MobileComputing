import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'vehicle_management_screen.dart';
import 'service_history_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Key untuk masing-masing Navigator tab agar state navigasi terpisah
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Tab 0: Home
    GlobalKey<NavigatorState>(), // Tab 1: Tambah Kendaraan
    GlobalKey<NavigatorState>(), // Tab 2: Jadwal Servis
    GlobalKey<NavigatorState>(), // Tab 3: Profil
  ];

  // Callback untuk mengubah tab dari dalam halaman anak
  void setTabIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Mereset navigasi ke root jika tab yang sama diklik kembali
  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Pop semua halaman di atas root page
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E293B);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // TAB 0: HOME
          Navigator(
            key: _navigatorKeys[0],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => DashboardScreen(onTabChanged: setTabIndex),
              );
            },
          ),
          // TAB 1: TAMBAH KENDARAAN
          Navigator(
            key: _navigatorKeys[1],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const VehicleManagementScreen(),
              );
            },
          ),
          // TAB 2: JADWAL SERVIS (HISTORI)
          Navigator(
            key: _navigatorKeys[2],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const ServiceHistoryScreen(),
              );
            },
          ),
          // TAB 3: PROFIL
          Navigator(
            key: _navigatorKeys[3],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => ProfileScreen(onTabChanged: setTabIndex),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: primaryColor,
          selectedItemColor: Colors.amber,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home, color: Colors.amber),
              label: 'Homepage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car, color: Colors.amber),
              label: 'Tambah Kendaraan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month, color: Colors.amber),
              label: 'Jadwal Servis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, color: Colors.amber),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
