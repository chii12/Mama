import 'package:flutter/material.dart';
import 'profile.dart';
import 'doctor_rec.dart';
import 'nutrition.dart';
import 'newborn.dart';

import 'tipoftheday.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showButtons = true; // Controls button visibility
  double _lastOffset = 0; // Tracks last scroll position

  void _handleScroll(UserScrollNotification notification) {
    if (notification.metrics.pixels > _lastOffset) {
      // Scrolling down
      setState(() => _showButtons = false);
    } else if (notification.metrics.pixels < _lastOffset || 
               notification.metrics.pixels == notification.metrics.maxScrollExtent) {
      // Scrolling up or reached bottom
      setState(() => _showButtons = true);
    }
    _lastOffset = notification.metrics.pixels; // Update last position
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home"), backgroundColor: Colors.pinkAccent),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          _handleScroll(notification);
          return true;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildBestPractices(context),
              const SizedBox(height: 20),
              _buildTipOfTheDay(context),
              const SizedBox(height: 20),
              _buildResources(),
              const SizedBox(height: 80), // Space for floating buttons
            ],
          ),
        ),
      ),
    
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset("assets/images/pusot.png", width: 40, height: 40),
            const SizedBox(width: 10),
            const Text("MamEase", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink)),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
          },
          child: Row(
            children: const [
              Text("Profile", style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(width: 10),
              Icon(Icons.account_circle, size: 32, color: Colors.pink),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBestPractices(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Best Practices", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCategoryButton(context, "Doctor", "assets/images/doctor.png", DoctorScreen()),
            _buildCategoryButton(context, "Nutrition", "assets/images/nutrition.png", NutritionScreen()),
            _buildCategoryButton(context, "Newborn", "assets/images/newborn.png", NewbornScreen()),
          ],
        ),
      ],
    );
  }

  Widget _buildTipOfTheDay(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tip of the day", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => TipDetailsScreen()));
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.pink[100], borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset("assets/images/tips.png", width: double.infinity, height: 180, fit: BoxFit.cover),
                ),
                const SizedBox(height: 10),
                const Text("Baby's Development Updates", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Resources", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink)),
        const SizedBox(height: 10),
        _buildResourceItem(Icons.book, "Pregnancy Nutrition"),
        _buildResourceItem(Icons.spa, "Yoga"),
        _buildResourceItem(Icons.menu_book, "Guide to Baby’s First"),
      ],
    );
  }

  Widget _buildCategoryButton(BuildContext context, String title, String imagePath, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
      },
      child: Column(
        children: [
          Image.asset(imagePath, width: 80, height: 80, fit: BoxFit.cover),
          const SizedBox(height: 5),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildResourceItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {},
    );
  }

}
