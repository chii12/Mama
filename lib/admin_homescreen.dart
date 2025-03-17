import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'admindoc_rec.dart';
import 'admin_nutrition.dart';
import 'admin_newborn.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 0;
  bool _isSidebarOpen = false; // Sidebar visibility state

  final List<Widget> _screens = [
    AdminOverviewScreen(),
    AdminDoctorRecommendation(),
    AdminNutritionScreen(),
    AdminNewbornScreen(),
    AdminScheduleScreen(),
    AdminResourcesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      return;
    }

    try {
      final response = await supabase.from('users').select('role').eq('id', user.id).maybeSingle();
      if (response == null || response['role'] != 'admin') {
        await supabase.auth.signOut();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    } catch (e) {
      await supabase.auth.signOut();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _screens[_selectedIndex]),
            ],
          ),
          if (_isSidebarOpen)
            GestureDetector(
              onTap: _toggleSidebar, // Close sidebar when tapping outside
              child: Container(
                color: Colors.black.withOpacity(0.5),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
          _buildSidebar(), // Sidebar component
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.pinkAccent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: _toggleSidebar,
          ),
          Text("Admin Dashboard", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Row(
            children: [
              IconButton(icon: Icon(Icons.search, color: Colors.white), onPressed: () {}),
              IconButton(icon: Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await supabase.auth.signOut();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 250),
      left: _isSidebarOpen ? 0 : -250, // Show or hide sidebar
      top: 0,
      bottom: 0,
      child: Material(
        elevation: 8,
        child: Container(
          width: 250,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              ListTile(
                leading: Icon(Icons.dashboard),
                title: Text('Dashboard'),
                onTap: () => _selectPage(0),
              ),
              ListTile(
                leading: Icon(Icons.local_hospital),
                title: Text('Doctor Recommendations'),
                onTap: () => _selectPage(1),
              ),
              ListTile(
                leading: Icon(Icons.restaurant),
                title: Text('Nutrition'),
                onTap: () => _selectPage(2),
              ),
              ListTile(
                leading: Icon(Icons.child_care),
                title: Text('Newborn Care'),
                onTap: () => _selectPage(3),
              ),
              ListTile(
                leading: Icon(Icons.schedule),
                title: Text('Schedule'),
                onTap: () => _selectPage(4),
              ),
              ListTile(
                leading: Icon(Icons.folder),
                title: Text('Resources'),
                onTap: () => _selectPage(5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
      _isSidebarOpen = false;
    });
  }
}

// ============================== OVERVIEW PANEL WITH USER MANAGEMENT ==============================
class AdminOverviewScreen extends StatefulWidget {
  @override
  _AdminOverviewScreenState createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final response = await supabase.from('users').select('id, name, email');

    return response.map((user) => {
      'id': user['id'],
      'name': user['name'] ?? 'Unknown',
      'email': user['email'] ?? 'No email',
    }).toList();
  }

  void _viewUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("User Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${user['name']}"),
              Text("Email: ${user['email']}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return Center(child: Text("No users found."));

          return ListView(
            padding: EdgeInsets.all(16),
            children: snapshot.data!.map((user) {
              return ListTile(
                title: Text(user['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user['email']),
                onTap: () => _viewUser(user),
                trailing: IconButton(
                  icon: Icon(Icons.edit, color: Colors.pinkAccent),
                  onPressed: () {}, // Edit function here
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// Dummy placeholders for other sections
class AdminScheduleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Text("Schedule Panel"));
}

class AdminResourcesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Text("Resources Panel"));
}
