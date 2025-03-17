import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              "assets/images/pusot.png", // Logo
              width: 30,
              height: 30,
            ),
            SizedBox(width: 10),
            Text("Profile", style: TextStyle(color: Colors.pink)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implement logout with Supabase Auth
            },
            child: Text("Logout", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture (Fixed)
            ClipOval(
              child: Image.asset(
                "assets/images/profile_pic.png", // Ensure this image exists in assets
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "User Name", // TODO: Fetch name from Supabase Auth or Database
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink),
            ),
            SizedBox(height: 5),
            TextButton(
              onPressed: () {
                // TODO: Implement Edit Profile functionality
              },
              child: Text("Edit", style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 20),

            // User Details Section (Replace Firebase Data with Supabase Data)
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pink),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildDetailTile("Email", "user@example.com"), // TODO: Fetch from Supabase
                  _buildDetailTile("Phone", "+1234567890"), // TODO: Fetch from Supabase
                  _buildDetailTile("Joined", "01 Jan 2024"), // TODO: Fetch from Supabase
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(String title, String value) {
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
      subtitle: Text(value, style: TextStyle(fontSize: 16)),
    );
  }
}
