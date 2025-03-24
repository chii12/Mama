import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminSchedScreen extends StatefulWidget {
  @override
  _AdminSchedScreenState createState() => _AdminSchedScreenState();
}

class _AdminSchedScreenState extends State<AdminSchedScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> approvedAppointments = [];
  List<dynamic> pendingAppointments = [];
  List<dynamic> rejectedAppointments = [];

  final List<String> _rejectReasons = [
    "Doctor unavailable",
    "Patient requested reschedule",
    "Incomplete patient details",
    "Duplicate booking",
    "Emergency case took priority",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final response = await supabase.from('appointments').select();
      print("🟢 Fetched Appointments: $response");

      if (mounted) {
        setState(() {
          approvedAppointments = response.where((a) => a['status'] == 'approved').toList();
          pendingAppointments = response.where((a) => a['status'] == 'pending').toList();
          rejectedAppointments = response.where((a) => a['status'] == 'rejected').toList();
        });
      }
    } catch (e) {
      print("❌ Error fetching appointments: $e");
    }
  }

 Future<void> _updateAppointmentStatus(String id, String status, {String? reason}) async {
  try {
    final updateData = {'status': status};
    if (reason != null) {
      updateData['reject_reason'] = reason;
    }

    await supabase.from('appointments').update(updateData).eq('id', id);

    // ✅ Fetch the user's ID from the appointment
    final appointment = await supabase.from('appointments').select().eq('id', id).maybeSingle();
    if (appointment == null || appointment['user_id'] == null) {
      print("⚠️ No user found for this appointment.");
      return;
    }
    String userId = appointment['user_id'];

    // ✅ Insert a notification for the user
    await supabase.from('notifications').insert({
      'user_id': userId,
      'title': status == 'approved' ? "Appointment Approved" : "Appointment Rejected",
      'message': status == 'approved'
          ? "Your appointment on ${appointment['date']} at ${appointment['time']} has been approved!"
          : "Your appointment on ${appointment['date']} at ${appointment['time']} was rejected. Reason: ${reason ?? 'No reason provided.'}",
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    // ✅ Refresh the UI
    _fetchAppointments();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Appointment $status successfully!"), backgroundColor: Colors.green),
    );
  } catch (e) {
    print("❌ Error updating appointment status: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to update appointment."), backgroundColor: Colors.red),
    );
  }
}


  Future<void> _deleteAppointment(String id) async {
    try {
      await supabase.from('appointments').delete().eq('id', id);
      _fetchAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Appointment deleted successfully!"), backgroundColor: Colors.red),
      );
    } catch (e) {
      print("❌ Error deleting appointment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete appointment."), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectReasonDialog(String id) {
    String? selectedReason;
    TextEditingController otherReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Reject Appointment"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Select a reason"),
                    items: _rejectReasons.map((reason) {
                      return DropdownMenuItem(value: reason, child: Text(reason));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedReason = value;
                      });
                    },
                  ),
                  if (selectedReason == "Other")
                    TextField(
                      controller: otherReasonController,
                      decoration: InputDecoration(labelText: "Enter other reason"),
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final reason = selectedReason == "Other"
                    ? otherReasonController.text.trim()
                    : selectedReason;

                if (reason == null || reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please select or enter a reason"), backgroundColor: Colors.red),
                  );
                  return;
                }
                _updateAppointmentStatus(id, 'rejected', reason: reason);
                Navigator.pop(context);
              },
              child: Text("Reject"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Schedule Appointments"),
          backgroundColor: Colors.pinkAccent,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Schedules"),
              Tab(text: "Pending"),
              Tab(text: "Rejected"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppointmentList(approvedAppointments, showActions: false),
            _buildAppointmentList(pendingAppointments, showActions: true),
            _buildAppointmentList(rejectedAppointments, showActions: false, showDelete: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(List<dynamic> appointments, {bool showActions = false, bool showDelete = false}) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          "No appointments found.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 3,
          child: ListTile(
            title: Text(
              "Appointment at ${appointment['place']}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${DateFormat.yMMMd().format(DateTime.parse(appointment['date']))} at ${appointment['time']}"),
                if (appointment['status'] == 'rejected' && appointment['reject_reason'] != null)
                  Text("Reason: ${appointment['reject_reason']}", style: TextStyle(color: Colors.red)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showActions) ...[
                  IconButton(
                    icon: Icon(Icons.check_circle, color: const Color.fromARGB(255, 137, 153, 138)),
                    onPressed: () => _updateAppointmentStatus(appointment['id'], 'approved'),
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _showRejectReasonDialog(appointment['id']),
                  ),
                ],
                if (showDelete) ...[
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.black),
                    onPressed: () => _deleteAppointment(appointment['id']),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
