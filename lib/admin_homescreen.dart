import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'admindoc_rec.dart';
import 'admin_nutrition.dart';
import 'admin_newborn.dart';
import 'admin_patient_list.dart';
import 'AdminSchedScreen.dart';
import 'admin_notif_screen.dart';
import 'dart:async';



class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}
StreamSubscription<List<Map<String, dynamic>>>? _appointmentSubscription;
class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 0;
  bool _isSidebarOpen = false; // Sidebar visibility state
  int _unreadNotificationCount = 0; // 🔴 Unread notifications count

   final List<Widget> _screens = [
    AdminDashboard(),
    AdminDoctorRecommendation(),
    AdminNutritionScreen(),
    AdminNewbornScreen(),
    AdminSchedScreen(),
    AdminResourcesScreen(),
    AdminPatientList(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _fetchUnreadNotificationCount(); // ✅ Fetch unread notification count
    _listenForAppointmentChanges(); // ✅ Listen for real-time appointment updates
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

  // ✅ Fetch unread notifications count
  Future<void> _fetchUnreadNotificationCount() async {
    final response = await supabase
        .from('notifications')
        .select('id')
        .eq('is_read', false);

    setState(() {
      _unreadNotificationCount = response.length;
    });
  }

  // ✅ Listen for real-time appointment updates
 void _listenForAppointmentChanges() async {
  // Prevent multiple listeners
  if (_appointmentSubscription != null) {
    print("⚠️ Listener already running. Skipping duplicate listener setup.");
    return;
  }

  // Fetch all admin users
  final adminResponse = await supabase.from('users').select('id').eq('role', 'admin');
  List<String> adminIds = adminResponse.map<String>((admin) => admin['id']).toList();

  _appointmentSubscription = supabase
      .from('appointments')
      .stream(primaryKey: ['id'])
      .listen((List<Map<String, dynamic>> updatedAppointments) {
    for (var appointment in updatedAppointments) {
      String userId = appointment['user_id']; // The user who booked the appointment

    if (appointment['status'] == 'canceled') {
        for (String adminId in adminIds) {
          _sendNotification(
            adminId,
            "Appointment Canceled",
            "A user has canceled their appointment at ${appointment['place']} on ${appointment['date']}.",
          );
        }
      }
    }
    setState(() {
      _unreadNotificationCount++;
    });
  });
}



  // ✅ Function to send notifications
 Future<void> _sendNotification(String userId, String title, String message) async {
  try {
    // Check if a similar notification already exists
    final existingNotif = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('title', title)
        .eq('message', message)
        .maybeSingle();

    // If the notification already exists, do not insert a duplicate
    if (existingNotif != null) {
      print("🔄 Notification already exists, skipping duplicate entry.");
      return;
    }

    // Otherwise, insert the new notification
    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
    print("📩 Notification sent to user $userId: $title");
  } catch (e) {
    print("❌ Error sending notification: $e");
  }
}


  // ✅ Function to update appointment status and notify users
  Future<void> _updateAppointmentStatus(String id, String status) async {
    try {
      await supabase.from('appointments').update({'status': status}).eq('id', id);

      // Fetch user_id of the appointment
      final response = await supabase.from('appointments').select('user_id, place, date, time').eq('id', id).maybeSingle();
      
      if (response != null) {
        String userId = response['user_id'];
        String place = response['place'];
        String date = response['date'];
        String time = response['time'];

        if (status == 'approved') {
          _sendNotification(
            userId,
            "Appointment Approved",
            "Your appointment at $place on $date at $time has been approved.",
          );
        } else if (status == 'rejected') {
          _sendNotification(
            userId,
            "Appointment Rejected",
            "Your appointment at $place on $date at $time has been rejected.",
          );
        }
      }
    } catch (e) {
      print("❌ Error updating appointment status: $e");
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
          Text("Doc Dashboard", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Row(
            children: [
              IconButton(icon: Icon(Icons.search, color: Colors.white), onPressed: () {}),

              // ✅ Notification Icon with Badge
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _unreadNotificationCount = 0;
                      });
                      Future.delayed(Duration(milliseconds: 100), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminNotificationScreen()),
      );
    });

                    },
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text(
                          '$_unreadNotificationCount',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),

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
              ListTile(
               leading: Icon(Icons.people),
               title: Text('Patients'),
                onTap: () => _selectPage(6), // Change index as needed
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
class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;
  int upcomingAppointments = 0;
  int activePatients = 0;
  int flaggedData = 0;
  List<dynamic> pendingAppointments = [];
  List<dynamic> flaggedEntries = [];
  String appointmentFilter = "all";

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

Future<void> _fetchDashboardData() async {
  try {
    final appointments = await supabase.from('appointments').select().eq('status', 'pending');
    final patients = await supabase.from('users').select().eq('role', 'patient');
    final flagged = await supabase.from('health_data').select().eq('status', 'flagged');

    print("🟢 Appointments: $appointments"); // Debugging
    print("🟢 Patients: $patients");
    print("🟢 Flagged Data: $flagged");

    if (mounted) {
      setState(() {
        upcomingAppointments = appointments.length;
        activePatients = patients.length;
        flaggedData = flagged.length;
        pendingAppointments = appointments; // Ensure this updates correctly
        flaggedEntries = flagged;
      });
    }
  } catch (e) {
    print("❌ Error fetching dashboard data: $e");
  }
}

  Future<void> _updateAppointmentStatus(String id, String status) async {
    await supabase.from('appointments').update({'status': status}).eq('id', id);
    _fetchDashboardData();
  }

  Future<void> _updateFlaggedDataStatus(String id, String status) async {
    await supabase.from('health_data').update({'status': status}).eq('id', id);
    _fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            SizedBox(height: 20),
            _buildFilters(),
            _buildActionableTasks(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _summaryCard("Pending Appointments", upcomingAppointments.toString(), Icons.event),
        _summaryCard("Active Patients", activePatients.toString(), Icons.people),
        _summaryCard("Flagged Data", flaggedData.toString(), Icons.warning),
      ],
    );
  }

  Widget _summaryCard(String title, String count, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.pinkAccent),
            SizedBox(height: 10),
            Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<String>(
          value: appointmentFilter,
          items: [
            DropdownMenuItem(value: "all", child: Text("All Appointments")),
            DropdownMenuItem(value: "pending", child: Text("Pending")),
            DropdownMenuItem(value: "approved", child: Text("Approved")),
            DropdownMenuItem(value: "rejected", child: Text("Rejected")),
          ],
          onChanged: (value) {
            setState(() {
              appointmentFilter = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionableTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Pending Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
        SizedBox(height: 10),
        _buildPendingAppointments(),
        _buildFlaggedData(),
      ],
    );
  }

Widget _buildPendingAppointments() {
  List<dynamic> filteredAppointments = pendingAppointments.where((appointment) {
    if (appointmentFilter == "all") return true;
    return appointment['status'] == appointmentFilter;
  }).toList();

  if (filteredAppointments.isEmpty) {
    return Center(child: Text("No pending appointments.", style: TextStyle(fontSize: 16, color: Colors.grey)));
  }

  return Column(
    children: filteredAppointments.map((appointment) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        child: ListTile(
          title: Text("Appointment at ${appointment['place']}", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${appointment['date']} at ${appointment['time']}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.check_circle, color: Colors.green),
                onPressed: () => _updateAppointmentStatus(appointment['id'], 'approved'),
              ),
              IconButton(
                icon: Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _updateAppointmentStatus(appointment['id'], 'rejected'),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}


  Widget _buildFlaggedData() {
    return Column(
      children: flaggedEntries.map((entry) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
          child: ListTile(
            title: Text("Flagged Data: ${entry['data_type']}", style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Value: ${entry['value']}, Reported by: ${entry['reported_by']}"),
            trailing: IconButton(
              icon: Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _updateFlaggedDataStatus(entry['id'], 'resolved'),
            ),
          ),
        );
      }).toList(),
    );
  }
}


class AdminResourcesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Text("Resources Panel"));
}



