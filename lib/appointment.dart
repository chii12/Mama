import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String? _selectedPlace;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<Map<String, String>> _appointments = [];

  final List<String> _places = ["Maysan", "Luzon", "Visayas"];

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

  void _bookAppointment() {
    if (_selectedPlace == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select all fields before booking!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _appointments.add({
        "place": _selectedPlace!,
        "date": DateFormat.yMMMd().format(_selectedDate!),
        "time": _selectedTime!.format(context),
      });

      _resetSelection();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Appointment Booked Successfully!"), backgroundColor: Colors.green),
    );
  }

  void _editAppointment(int index) {
    Map<String, String> appointment = _appointments[index];

    setState(() {
      _selectedPlace = appointment["place"];
      _selectedDate = DateFormat.yMMMd().parse(appointment["date"]!);
      _selectedTime = TimeOfDay.fromDateTime(DateFormat.jm().parse(appointment["time"]!));
    });

    _showBookingDialog(isEditing: true, index: index);
  }

  void _updateAppointment(int index) {
    if (_selectedPlace == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select all fields before updating!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _appointments[index] = {
        "place": _selectedPlace!,
        "date": DateFormat.yMMMd().format(_selectedDate!),
        "time": _selectedTime!.format(context),
      };

      _resetSelection();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Appointment Updated Successfully!"), backgroundColor: Colors.green),
    );
  }

  void _deleteAppointment(int index) {
    setState(() {
      _appointments.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Appointment Deleted"), backgroundColor: Colors.red),
    );
  }

  void _resetSelection() {
    _selectedPlace = null;
    _selectedDate = null;
    _selectedTime = null;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Activity", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.pinkAccent,
          bottom: const TabBar(
            indicatorColor: Colors.pink,
            labelColor: Color.fromARGB(255, 248, 246, 247),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Past"),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildUpcomingAppointments(),
                Center(child: Text("No past appointments yet")),
              ],
            ),
            Positioned(
              bottom: 105,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showBookingDialog(),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text("Book an Appointment", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return _appointments.isEmpty
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/no_appointments.png", width: 200),
              SizedBox(height: 20),
              Text("No upcoming appointments yet",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 10),
              Text("Schedule your healthcare appointments at your convenience",
                  textAlign: TextAlign.center),
            ],
          )
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _appointments.length,
            itemBuilder: (context, index) {
              final appointment = _appointments[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: Icon(Icons.event, color: Colors.pink),
                  title: Text("Appointment in ${appointment['place']}", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${appointment['date']} at ${appointment['time']}"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "Edit") {
                        _editAppointment(index);
                      } else if (value == "Delete") {
                        _deleteAppointment(index);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: "Edit", child: Text("Edit")),
                      PopupMenuItem(value: "Delete", child: Text("Delete")),
                    ],
                  ),
                ),
              );
            },
          );
  }

  void _showBookingDialog({bool isEditing = false, int? index}) {
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
                      _selectedDate == null
                          ? "Select Date"
                          : DateFormat.yMMMd().format(_selectedDate!),
                    ),
                    onPressed: () => _pickDate().then((_) => setDialogState(() {})),
                  ),
                  SizedBox(height: 10),
                  TextButton.icon(
                    icon: Icon(Icons.access_time, color: Colors.pink),
                    label: Text(
                      _selectedTime == null
                          ? "Select Time"
                          : _selectedTime!.format(context),
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
                if (isEditing && index != null) _updateAppointment(index);
                else _bookAppointment();
                Navigator.pop(context);
              },
              child: Text(isEditing ? "Update" : "Book"),
            ),
          ],
        );
      },
    );
  }
}
