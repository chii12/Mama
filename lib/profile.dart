import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final response = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .single(); // Fetch user details

      setState(() {
        userData = response;
        isLoading = false;
      });

    } catch (e) {
      print("❌ Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

// ✅ Function to update the user's name in Supabase
  Future<void> _updateUserName(String newName) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('users')
          .update({'name': newName})
          .eq('id', user.id)
          .select(); // Fetch updated data

      if (response.isEmpty) {
        print("❌ Supabase Update Failed: No data returned.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: Name update failed"), backgroundColor: Colors.red),
        );
        return;
      }

      // ✅ Update the UI with the new name
      setState(() {
        userData = response.first;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Name updated successfully!"), backgroundColor: Colors.green),
      );
    } catch (e) {
      print("❌ Exception Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update name"), backgroundColor: Colors.red),
      );
    }
  }

  // ✅ Function to show the edit name dialog
  void _showEditNameDialog() {
    TextEditingController nameController = TextEditingController(text: userData!['name']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Name"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: "Enter new name"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  _updateUserName(nameController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

Future<void> _updateHealthData(String bloodPressure, String weight, String glucose) async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // ✅ Update and fetch the latest data in one query
    final response = await supabase
        .from('users')
        .update({
          'blood_pressure': bloodPressure,
          'bp_status': '✏️ User-Reported',
          'weight': int.tryParse(weight) ?? 0,
          'weight_status': '✏️ User-Reported',
          'glucose': int.tryParse(glucose) ?? 0,
          'glucose_status': '✏️ User-Reported',
        })
        .eq('id', user.id)
        .select(); // ✅ Fetch updated data immediately

    // ✅ Ensure we got updated data
    if (response.isEmpty) {
      print("❌ Supabase Update Failed: No data returned.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Update failed, no data returned"), backgroundColor: Colors.red),
      );
      return;
    }

    // ✅ Refresh userData with the updated response
    setState(() {
      userData = response.first; // Use the first record in the returned list
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Health Data updated successfully!"), backgroundColor: Colors.green),
    );
  } catch (e) {
    print("❌ Exception Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to update health data"), backgroundColor: Colors.red),
    );
  }
}



  void _showEditHealthDataDialog() {
    TextEditingController bpController = TextEditingController(text: userData!['blood_pressure']);
    TextEditingController weightController = TextEditingController(text: userData!['weight']?.toString());
    TextEditingController glucoseController = TextEditingController(text: userData!['glucose']?.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Health Data"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bpController,
                decoration: InputDecoration(labelText: "Blood Pressure (e.g., 120/80 mmHg)"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Weight (kg)"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: glucoseController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Glucose (mg/dL)"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (bpController.text.trim().isNotEmpty &&
                    weightController.text.trim().isNotEmpty &&
                    glucoseController.text.trim().isNotEmpty) {
                  _updateHealthData(bpController.text.trim(), weightController.text.trim(), glucoseController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
  

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return Scaffold(
        body: Center(child: Text("User not found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          TextButton(
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: Text("Logout", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundImage: userData!['profile_picture'] != null
                  ? NetworkImage(userData!['profile_picture'])
                  : AssetImage('assets/default_profile.png') as ImageProvider,
            ),
            SizedBox(height: 10),

            // ✅ Editable Name
           Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      userData!['name'] ?? "No Name",
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
    IconButton(
      icon: Icon(Icons.edit, color: Colors.pinkAccent),
      onPressed: _showEditNameDialog, // ✅ This should call _showEditNameDialog()
    ),
  ],
),

            SizedBox(height: 20),

            // ✅ User Info Cards
            ProfileInfoCard(
              title: "Email",
              content: userData!['email'] ?? "No Email",
              icon: Icons.email,
            ),
            ProfileInfoCard(
              title: "User ID",
              content: userData!['id'],
              icon: Icons.perm_identity,
            ),

            Divider(height: 30, thickness: 1),
            Text("Health Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            // ✅ Health Data Cards
            HealthDataCard(
              title: "Blood Pressure",
              value: userData!['blood_pressure'] ?? "Unknown",
              status: userData!['bp_status'] ?? "✏️ User-Reported",
            ),
            HealthDataCard(
              title: "Weight",
              value: userData!['weight']?.toString() ?? "Unknown",
              status: userData!['weight_status'] ?? "✏️ User-Reported",
            ),
            HealthDataCard(
              title: "Glucose",
              value: userData!['glucose']?.toString() ?? "Unknown",
              status: userData!['glucose_status'] ?? "⚠️ Pending Review",
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showEditHealthDataDialog,
              child: Text("Edit Health Data"),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  ProfileInfoCard({required this.title, required this.content, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.pinkAccent),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                SizedBox(height: 5),
                Text(content, style: TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
class HealthDataCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;

  HealthDataCard({required this.title, required this.value, required this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: TextStyle(fontSize: 14, color: Colors.black87)),
                Text(status, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

