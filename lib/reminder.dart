import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchUserNotifications();
    _listenForNotifications(); // ✅ Enable real-time updates
  }

  // ✅ Fetch notifications from Supabase
  Future<void> _fetchUserNotifications() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final response = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', user.id)
      .eq('role', 'user')  // Fetch only user notifications
      .order('created_at', ascending: false);

  setState(() {
    _notifications = response;
  });
}


  // ✅ Listen for real-time notifications
void _listenForNotifications() {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.id!)
      .listen((List<Map<String, dynamic>> newNotifications) {
    print("📩 New Notifications: $newNotifications"); // ✅ Debugging
    setState(() {
      _notifications = newNotifications;
    });
  });
}



  // ✅ Mark a single notification as read
  Future<void> _markAsRead(String id) async {
    await supabase.from('notifications').update({'is_read': true}).eq('id', id);
    _fetchUserNotifications();
  }

  // ✅ Mark all notifications as read
  Future<void> _markAllAsRead() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', user.id);

    _fetchUserNotifications();
  }

  // ✅ Delete a notification
  Future<void> _deleteNotification(String id) async {
    await supabase.from('notifications').delete().eq('id', id);
    _fetchUserNotifications();
  }

  // ✅ Delete all notifications
  Future<void> _deleteAllNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('notifications').delete().eq('user_id', user.id);
    _fetchUserNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        backgroundColor: Colors.pinkAccent,
        actions: [
          if (_notifications.isNotEmpty) // Show button only if there are notifications
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
                        if (!notif['is_read']) // Show mark read only if unread
                          IconButton(
                            icon: Icon(Icons.mark_email_read, color: Colors.blue),
                            onPressed: () => _markAsRead(notif['id']),
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



