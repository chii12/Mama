import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart'; // To open/download files

class AdminNewbornScreen extends StatefulWidget {
  const AdminNewbornScreen({super.key});

  @override
  _AdminNewbornScreenState createState() => _AdminNewbornScreenState();
}

class _AdminNewbornScreenState extends State<AdminNewbornScreen> {
  final supabase = Supabase.instance.client;

  /// Picks a file and uploads it to Supabase Storage
  Future<void> _pickAndUploadFile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please log in first!")));
      return;
    }

    // Fetch user role from the Supabase 'users' table
    final response = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    final String userRole = response['role'] ?? 'user'; // Default role is 'user'

    if (userRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Only admins can upload files!")));
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null) return;

      Uint8List fileBytes = result.files.first.bytes!;
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${result.files.first.name}';
      String fileExtension = result.files.first.extension ?? '';

      // Upload file to Supabase Storage
      await supabase.storage.from('newborn_care').uploadBinary(fileName, fileBytes);

      // Get the public URL
      String fileUrl = supabase.storage.from('newborn_care').getPublicUrl(fileName);

      // Insert file details into Supabase Database
      await supabase.from('newborn_care').insert({
        'user_id': user.id,
        'url': fileUrl,
        'file_name': result.files.first.name,
        'file_type': fileExtension, // Store file type
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File uploaded successfully!")));
      setState(() {}); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  /// Fetches uploaded files from Supabase
  Future<List<Map<String, dynamic>>> _fetchFiles() async {
    final response = await supabase.from('newborn_care').select();
    return response;
  }

  /// Deletes a file from Supabase Storage & Database
  Future<void> _deleteFile(String fileName, String docId) async {
    try {
      await supabase.storage.from('newborn_care').remove([fileName]);
      await supabase.from('newborn_care').delete().eq('id', docId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File deleted successfully!")));
      setState(() {}); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete file: $e")));
    }
  }

  /// Determines if a file is an image
  bool isImage(String fileType) {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileType.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Newborn"), backgroundColor: Colors.pinkAccent),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFiles(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return Center(child: Text("No newborn recommendations uploaded yet."));

          return ListView(
            children: snapshot.data!.map((doc) {
              String fileUrl = doc['url'];
              String fileName = doc['file_name'];
              String fileType = doc['file_type'] ?? '';
              String docId = doc['id'].toString();

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: isImage(fileType)
                      ? Image.network(fileUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.insert_drive_file, size: 40, color: Colors.blue),
                  title: Text(fileName),
                  subtitle: Text(fileType.toUpperCase()),
                  onTap: () => launchUrl(Uri.parse(fileUrl)), // Open/download file
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFile(fileName, docId),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndUploadFile,
        backgroundColor: Colors.pink,
        child: Icon(Icons.add),
      ),
    );
  }
}
