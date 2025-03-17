import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return FutureBuilder(
      future: supabase.from('users').select('name').eq('id', user?.id ?? '').maybeSingle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text("Error loading profile"));
        }

        final userName = snapshot.data?['name'] ?? "Guest User";

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
                onPressed: () async {
                  await supabase.auth.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
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
                // Profile Picture (Fixed for now)
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
                  userName, // Fetch user name from Supabase
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

                // User Details Section
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.pink),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                     
                      _buildDetailTile("Email", user?.email ?? "Not Available"),
                      _buildDetailTile("User ID", user?.id ?? "Unknown"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(String title, String value) {
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
      subtitle: Text(value, style: TextStyle(fontSize: 16)),
    );
  }
}
