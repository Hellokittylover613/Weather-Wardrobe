import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/settings_panel.dart';
import 'home_screen.dart';
import 'weather_screen.dart';
import 'wardrobe_screen.dart';
import 'profile_screen.dart';

/// The "shell" that owns the single, persistent bottom navigation bar
/// and the slide-in settings panel (opened from Profile).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _tabs = [
    HomeScreen(),
    WeatherScreen(),
    WardrobeScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const SettingsPanel(),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.coral,
        unselectedItemColor: AppColors.plum.withOpacity(0.4),
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_cloudy_outlined),
            activeIcon: Icon(Icons.wb_cloudy),
            label: 'Weather',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom_outlined),
            activeIcon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
