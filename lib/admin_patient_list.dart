import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPatientList extends StatefulWidget {
  @override
  _AdminPatientListState createState() => _AdminPatientListState();
}

class _AdminPatientListState extends State<AdminPatientList> {
  final supabase = Supabase.instance.client;
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .neq('role', 'admin'); // Exclude admin users

      print("🚀 Raw Supabase Response: $response");

      setState(() {
        users = response.map((user) => {
              'id': user['id'] ?? '',
              'name': (user['name'] ?? 'Unknown').toString(),
              'email': (user['email'] ?? 'No Email').toString(),
              'phone': (user['phone'] ?? 'No Phone').toString(),
              'dob': (user['dob'] ?? 'N/A').toString(),
              'due_date': (user['due_date'] ?? 'N/A').toString(),
              'emergency_contact': (user['emergency_contact'] ?? 'N/A').toString(),
            }).toList();
      });

      print("✅ Processed Users: $users");

    } catch (error) {
      print("❌ Error fetching users: $error");
    }
  }

  void _showUserDialog(Map<String, dynamic> user) {
    TextEditingController nameController = TextEditingController(text: user['name']);
    TextEditingController emailController = TextEditingController(text: user['email']);
    TextEditingController phoneController = TextEditingController(text: user['phone']);
    TextEditingController dobController = TextEditingController(text: user['dob']);
    TextEditingController dueDateController = TextEditingController(text: user['due_date']);
    TextEditingController emergencyController = TextEditingController(text: user['emergency_contact']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit User Info"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: "Full Name")),
                TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
                TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone")),
                TextField(controller: dobController, decoration: InputDecoration(labelText: "Date of Birth (YYYY-MM-DD)")),
                TextField(controller: dueDateController, decoration: InputDecoration(labelText: "Gestational Age/Due Date")),
                TextField(controller: emergencyController, decoration: InputDecoration(labelText: "Emergency Contact")),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (user['id'] == null || user['id'].toString().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("User ID missing! Cannot update.")));
                  return;
                }

                final updateData = {
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'dob': dobController.text.trim(),
                  'due_date': dueDateController.text.trim(),
                  'emergency_contact': emergencyController.text.trim(),
                };

                try {
                  final response = await supabase
                      .from('users')
                      .update(updateData)
                      .eq('id', user['id'])
                      .select();

                  if (response.isNotEmpty) {
                    await _fetchUsers();
                    if (mounted) Navigator.pop(context);
                  }
                } catch (error) {
                  print("Error updating user: $error");
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

void _addNewUser() {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController dueDateController = TextEditingController();
  TextEditingController emergencyController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Add New User"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: "Full Name")),
              TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone")),
              TextField(controller: dobController, decoration: InputDecoration(labelText: "Date of Birth (YYYY-MM-DD)")),
              TextField(controller: dueDateController, decoration: InputDecoration(labelText: "Gestational Age/Due Date")),
              TextField(controller: emergencyController, decoration: InputDecoration(labelText: "Emergency Contact")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              String name = nameController.text.trim();
              String email = emailController.text.trim();
              String phone = phoneController.text.trim();
              String dob = dobController.text.trim();
              String dueDate = dueDateController.text.trim();
              String emergencyContact = emergencyController.text.trim();

              if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob)) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid DOB format. Use YYYY-MM-DD.")));
                return;
              }

              String defaultPassword = dob.replaceAll('-', ''); // Use DOB as password

              try {
                // ✅ Step 1: Register user in Supabase Auth
                final authResponse = await supabase.auth.signUp(
                  email: email,
                  password: defaultPassword, 
                );

                if (authResponse.user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("User registration failed.")),
                  );
                  return;
                }

                String userId = authResponse.user!.id; // Get the Supabase Auth ID

                // ✅ Step 2: Save User Info in `users` Table
                final userResponse = await supabase.from('users').insert({
                  'id': userId,  // Ensure the ID matches Supabase Auth
                  'name': name,
                  'email': email,
                  'phone': phone,
                  'dob': dob,
                  'due_date': dueDate,
                  'emergency_contact': emergencyContact,
                  'role': 'patient', // Default role is patient
                });

                print("User Inserted: $userResponse");

                // ✅ Step 3: Refresh UI & Close Dialog
                await _fetchUsers();
                if (mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("User added successfully!")),
                );

              } catch (error) {
                print("❌ Error adding user: $error");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: ${error.toString()}")),
                );
              }
            },
            child: Text("Add"),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Patient List"),
        backgroundColor: Colors.pinkAccent,
     actions: [
  IconButton(
    icon: Icon(Icons.add),
    onPressed: _addNewUser, // ✅ Show dialog instead of opening a new screen
  ),
],

      ),
      body: users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['name']), // ✅ FIXED (was 'full_name')
                  subtitle: Text(user['email']),
                  trailing: Icon(Icons.edit, color: Colors.pinkAccent),
                  onTap: () => _showUserDialog(user),
                );
              },
            ),
    );
  }
}
