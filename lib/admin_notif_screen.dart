import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';


class AdminNotificationScreen extends StatefulWidget {
  @override
  _AdminNotificationScreenState createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _deleteOldNotifications(); // ✅ Delete old notifications
    _fetchAdminNotifications();
    _listenForNotifications(); // ✅ Enable real-time updates
  }


  // ✅ Fetch the latest 20 notifications for the admin
Future<void> _fetchAdminNotifications() async {
  final admin = supabase.auth.currentUser;
  if (admin == null) return;

  final response = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', admin.id)
      .eq('role', 'admin')  // Fetch only admin notifications
      .order('created_at', ascending: false);

  setState(() {
    _notifications = response;
  });
}





  // ✅ Real-time notification listener (Only for new inserts)
StreamSubscription<List<Map<String, dynamic>>>? _notificationSubscription;
void _listenForNotifications() {
  final user = supabase.auth.currentUser;
  if (user == null || _notificationSubscription != null) return;

  print("👂 Listening for new notifications...");

  _notificationSubscription = supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .listen((List<Map<String, dynamic>> newNotifications) {
        print("📩 New Notification Received: $newNotifications");

        if (newNotifications.isNotEmpty) {
          setState(() {
            _notifications = newNotifications.toSet().toList();
          });
        }
      });
}




@override
void dispose() {
  _notificationSubscription?.cancel(); // ✅ Stop real-time listener when screen is closed
  super.dispose();
}


  // ✅ Mark a notification as read
  Future<void> markNotificationAsRead(int notifId) async {
  await supabase.from('notifications').update({'is_read': true}).eq('id', notifId);
}

  // ✅ Mark all notifications as read
  Future<void> _markAllAsRead() async {
    await supabase.from('notifications').update({'is_read': true});
    _fetchAdminNotifications();
  }

  // ✅ Delete a single notification
  Future<void> _deleteNotification(String id) async {
    await supabase.from('notifications').delete().eq('id', id);
    _fetchAdminNotifications();
  }

  // ✅ Delete all notifications
  Future<void> _deleteAllNotifications() async {
    await supabase.from('notifications').delete();
    _fetchAdminNotifications();
  }

  // ✅ Delete old notifications (Older than 7 days)
  Future<void> _deleteOldNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('notifications')
        .delete()
        .lt('created_at', DateTime.now().subtract(Duration(days: 7)).toIso8601String()); // ✅ Delete notifications older than 7 days
  }

 Future<void> updateAppointmentStatus(String appointmentId, String status) async {
  try {
    // ✅ Get the user_id from the appointment
    final response = await supabase
        .from('appointments')
        .select('user_id')
        .eq('id', appointmentId)
        .maybeSingle();

    if (response == null) {
      print("❌ No appointment found with ID: $appointmentId");
      return;
    }

    String userId = response['user_id'];

    // ✅ Update appointment status
    await supabase
        .from('appointments')
        .update({'status': status})
        .eq('id', appointmentId);

    // ✅ Send notification to the user
    await supabase.from('notifications').insert({
      'user_id': userId, // ✅ Send to the actual user, not a hardcoded ID
      'title': 'Appointment $status',
      'message': 'Your appointment has been $status by the admin.',
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
    });

    print("📩 Notification sent for appointment $status to user: $userId");
  } catch (e) {
    print("❌ Error updating appointment status: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Notifications"),
        backgroundColor: Colors.pinkAccent,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.check_circle, color: Colors.white),
              onPressed: _markAllAsRead,
              tooltip: "Mark all as read",
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteAllNotifications,
              tooltip: "Delete all notifications",
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(child: Text("No notifications yet!"))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(
                      notif['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: notif['is_read'] ? Colors.grey : Colors.black,
                      ),
                    ),
                    subtitle: Text(notif['message']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!notif['is_read'])
                          IconButton(
                            icon: Icon(Icons.mark_email_read, color: Colors.blue),
                            onPressed: () => markNotificationAsRead(notif['id']),
                          ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNotification(notif['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}


