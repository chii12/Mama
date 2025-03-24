import 'package:flutter/material.dart';
import 'appointment.dart';
import 'reminder.dart';
import 'modules.dart';
import 'mainscreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    AppointmentsScreen(),
    NotificationScreen(),
    PregnancyModulesScreen(),
  ];

  void _navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex], // Display selected screen

          // Floating Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavButton(Icons.home, "Home", 0),
                  _buildNavButton(Icons.event, "Appointments", 1),
                  _buildNavButton(Icons.notifications, "Reminders", 2),
                  _buildNavButton(Icons.book, "Modules", 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation Button
  Widget _buildNavButton(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () => _navigateTo(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _selectedIndex == index ? Colors.pinkAccent : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: _selectedIndex == index ? Colors.pinkAccent : Colors.grey)),
        ],
      ),
    );
  }
}
