import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final supabase = Supabase.instance.client;
  String? _selectedPlace;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<dynamic> _appointments = [];
  final List<String> _places = ["Our Lady of Fatima Medical Center", "Lying In Gen. T De Leon"];
  final List<String> _cancelReasons = [
    "Scheduling conflict",
    "Health condition improved",
    "Found another provider",
    "Personal reasons",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }
Future<void> _fetchAppointments() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final response = await supabase
      .from('appointments')
      .select()
      .eq('user_id', user.id);

  setState(() {
    _appointments = response;
  });
}


 Future<void> _bookAppointment() async {
  if (_selectedPlace == null || _selectedDate == null || _selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please select all fields before booking!"), backgroundColor: Colors.red),
    );
    return;
  }

  // ✅ Insert appointment into Supabase
  final response = await supabase.from('appointments').insert({
    'user_id': supabase.auth.currentUser?.id,
    'place': _selectedPlace,
    'date': _selectedDate!.toIso8601String(),
    'time': _selectedTime!.format(context),
    'status': 'pending',
  }).select().single();

  // ✅ Notify Admins
  if (response != null) {
    _sendNotificationToAdmins(
      "New Appointment Request",
      "A user booked an appointment at $_selectedPlace on ${_selectedDate!.toLocal()} at ${_selectedTime!.format(context)}.",
    );
  }

  _resetSelection();
  _fetchAppointments();
}

// ✅ Function to notify all admins
Future<void> _sendNotificationToAdmins(String title, String message) async {
  final adminResponse = await supabase.from('users').select('id').eq('role', 'admin');
  List<String> adminIds = adminResponse.map<String>((admin) => admin['id']).toList();

  for (String adminId in adminIds) {
    await supabase.from('notifications').insert({
      'user_id': adminId, // ✅ Only notify admins
      'title': title,
      'message': message,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

  Future<void> _cancelAppointment(String id) async {
    String? selectedReason;
    TextEditingController otherReasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Cancel Appointment"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Select Reason"),
                    items: _cancelReasons.map((reason) {
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
                      decoration: InputDecoration(labelText: "Enter your reason"),
                    ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final reason = selectedReason == "Other" ? otherReasonController.text : selectedReason;
                if (reason == null || reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please select a reason"), backgroundColor: Colors.red),
                  );
                  return;
                }
                await supabase.from('appointments').update({'status': 'canceled', 'cancel_reason': reason}).eq('id', id);
                Navigator.pop(context);
                _fetchAppointments();
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void _resetSelection() {
    setState(() {
      _selectedPlace = null;
      _selectedDate = null;
      _selectedTime = null;
    });


  }


  Future<void> _updateAppointment(int index) async {
  final appointment = _appointments[index];

  if (_selectedPlace == null || _selectedDate == null || _selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please select all fields before updating!"), backgroundColor: Colors.red),
    );
    return;
  }

  await supabase.from('appointments').update({
    'place': _selectedPlace,
    'date': _selectedDate!.toIso8601String(),
    'time': _selectedTime!.format(context),
  }).eq('id', appointment['id']);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Appointment updated successfully!"), backgroundColor: Colors.green),
  );

  _fetchAppointments(); // Refresh the list
}

void _showBookingDialog({bool isEditing = false, int? index}) {
  if (isEditing && index != null) {
    final appointment = _appointments[index];
    _selectedPlace = appointment['place'];
    _selectedDate = DateTime.parse(appointment['date']);
    _selectedTime = TimeOfDay(
      hour: int.parse(appointment['time'].split(":")[0]),
      minute: int.parse(appointment['time'].split(":")[1]),
    );
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(isEditing ? "Edit Appointment" : "Book Appointment", style: TextStyle(color: Colors.pink)),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Select Place"),
                  value: _selectedPlace,
                  items: _places.map((place) {
                    return DropdownMenuItem(value: place, child: Text(place));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedPlace = value;
                    });
                  },
                ),
                SizedBox(height: 10),
                TextButton.icon(
                  icon: Icon(Icons.calendar_today, color: Colors.pink),
                  label: Text(
                    _selectedDate == null ? "Select Date" : DateFormat.yMMMd().format(_selectedDate!),
                  ),
                  onPressed: () => _pickDate().then((_) => setDialogState(() {})),
                ),
                SizedBox(height: 10),
                TextButton.icon(
                  icon: Icon(Icons.access_time, color: Colors.pink),
                  label: Text(
                    _selectedTime == null ? "Select Time" : _selectedTime!.format(context),
                  ),
                  onPressed: () => _pickTime().then((_) => setDialogState(() {})),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (isEditing && index != null) {
                _updateAppointment(index); // ✅ Now it works!
              } else {
                _bookAppointment();
              }
              Navigator.pop(context);
            },
            child: Text(isEditing ? "Update" : "Book"),
          ),
        ],
      );
    },
  );
}


  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );


    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

@override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 3, // Updated from 2 to 3 to include "Approved" tab
    child: Scaffold(
      appBar: AppBar(
        title: const Text("Appointments"),
        backgroundColor: Colors.pinkAccent,
        bottom: const TabBar(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: "Booking"),
            Tab(text: "Past"),
            Tab(text: "Upcoming Appointmet"), // New tab added
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            children: [
              _buildAppointmentsList("pending"),   // Upcoming (Pending) appointments
              _buildAppointmentsList("canceled"),  // Canceled appointments
              _buildAppointmentsList("approved"),  // Approved appointments (New)
            ],
          ),

          // ✅ Show image when there are no appointments
          if (_appointments.isEmpty) 
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/booking.jpg', // Make sure the image is in assets folder
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),

      // ✅ Replace FloatingActionButton with a Text Button
      floatingActionButton: _appointments.where((appt) => appt['status'] == 'pending').isEmpty
        ? Padding(
            padding: const EdgeInsets.only(bottom: 103.0),
            child: ElevatedButton(
              onPressed: _showBookingDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                "Book Appointment",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          )
        : null, // Only hides if there are still pending appointments

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ),
  );
}


  Widget _buildAppointmentsList(String status) {
  final filteredAppointments = _appointments.where((appt) => appt['status'] == status).toList();

  return filteredAppointments.isEmpty
      ?   Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/booking.jpg', // Make sure the image is in assets folder
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 20),
                  Text(
                    "",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                ],
              ),
            )

      : ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            final appointment = filteredAppointments[index];

            return Card(
              elevation: 3,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: Icon(Icons.event, color: Colors.pink),
                title: Text("Appointment at ${appointment['place']}", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  "${DateFormat.yMMMd().format(DateTime.parse(appointment['date']))} at ${appointment['time']}",
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "edit") {
                      _showBookingDialog(isEditing: true, index: index);
                    } else if (value == "cancel") {
                      _cancelAppointment(appointment['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: "edit", child: Text("Edit")),
                    PopupMenuItem(value: "cancel", child: Text("Cancel")),
                  ],
                ),
              ),
            );
          },
        );
  }}