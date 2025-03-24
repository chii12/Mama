import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

class AdminNewbornScreen extends StatefulWidget {
  const AdminNewbornScreen({super.key});

  @override
  _AdminNewbornScreenState createState() => _AdminNewbornScreenState();
}

class _AdminNewbornScreenState extends State<AdminNewbornScreen> {
  final supabase = Supabase.instance.client;
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileExtension;

  /// Picks a file and stores in memory
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null) return;

    setState(() {
      _fileBytes = result.files.first.bytes!;
      _fileName = result.files.first.name;
      _fileExtension = result.files.first.extension ?? '';
    });
  }

  /// Upload file and insert metadata into Supabase
  Future<void> _uploadFile({required bool publish}) async {
    if (_fileBytes == null || _fileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a file first!"))
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please log in first!"))
      );
      return;
    }

    try {
      // Fetch user role safely
      final response = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle(); // Use maybeSingle() to avoid exceptions

      if (response == null || response['role'] != 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Only admins can upload files!"))
        );
        return;
      }

      // Proceed with file upload
      String filePath = '${DateTime.now().millisecondsSinceEpoch}_$_fileName';
    await supabase.storage.from('newborn_care').uploadBinary(filePath, _fileBytes!);
String fileUrl = supabase.storage.from('newborn_care').getPublicUrl(filePath);


      await supabase.from('newborn_care').insert({
     
        'user_id': user.id,
        'url': fileUrl,
        'file_name': _fileName,
        'file_type': _fileExtension,
        'title': _titleController.text.isNotEmpty ? _titleController.text : "No Title",
        'description': _descriptionController.text,
        'status': publish ? 'published' : 'draft',
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(publish ? "File uploaded!" : "File saved as draft."))
      );
      _clearInputs();
      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e"))
      );
    }
  }

  /// Clear input fields after uploading
  void _clearInputs() {
    _titleController.clear();
    _descriptionController.clear();
    _fileBytes = null;
    _fileName = null;
    _fileExtension = null;
  }

  /// Fetches uploaded files
  Future<List<Map<String, dynamic>>> _fetchFiles() async {
    final response = await supabase.from('newborn_care').select();

    return response.map((doc) {
      return {
        'id': doc['id']?.toString() ?? '',
        'title': doc['title'] ?? 'No Title',
        'description': doc['description'] ?? 'No description available',
        'url': doc['url'] ?? '',
        'file_name': doc['file_name'] ?? 'Unknown',
        'file_type': doc['file_type'] ?? 'unknown',
        'status': doc['status'] ?? 'draft',
      };
    }).toList();
  }

  /// Deletes a file
Future<void> _deleteFile(String fileName, String docId) async {
  try {
    // Remove file from Supabase Storage
    await supabase.storage.from('newborn_care').remove([fileName]);

    // Delete file metadata from the database
    await supabase.from('newborn_care').delete().eq('id', docId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("File deleted successfully!")),
    );
    setState(() {}); // Refresh the list
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to delete file: $e")),
    );
  }
}

  Future<void> _uploadDraft(String docId) async {
    try {
      await supabase.from('newborn_care').update({
        'status': 'published',
      }).eq('id', docId);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Draft uploaded successfully!"))
      );
      setState(() {});  // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload draft: $e"))
      );
    }
  }

  bool isImage(String fileType) {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Newborn"), backgroundColor: Colors.pinkAccent),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(controller: _titleController, decoration: InputDecoration(labelText: "Title")),
                TextField(controller: _descriptionController, decoration: InputDecoration(labelText: "Description")),
                SizedBox(height: 10),
                _fileName == null ? Text("No file selected") : Text("Selected: $_fileName"),
                ElevatedButton(
                  onPressed: _pickFile,
                  child: Text("Choose File"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _uploadFile(publish: true),
                      child: Text("Upload Now"),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _uploadFile(publish: false),
                      child: Text("Save as Draft"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFiles(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) return Center(child: Text("No newborn files uploaded yet."));

                return ListView(
                  children: snapshot.data!.map((doc) {
                  return Card(
  margin: EdgeInsets.all(10),
  child: ListTile(
    leading: isImage(doc['file_type'])
        ? Image.network(doc['url'], width: 50, height: 50, fit: BoxFit.cover)
        : Icon(Icons.insert_drive_file, size: 40, color: Colors.blue),
    title: Text(doc['title'], style: TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(doc['description']),
        Text("Status: ${doc['status']}", 
            style: TextStyle(
              color: doc['status'] == 'published' ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            )),
      ],
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (doc['status'] == 'draft') // Show Upload button only for drafts
          IconButton(
            icon: Icon(Icons.upload, color: Colors.green),
            onPressed: () => _uploadDraft(doc['id']),
          ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteFile(doc['file_name'], doc['id']),
        ),
      ],
    ),
    onTap: () => launchUrl(Uri.parse(doc['url'])),
  ),
);

                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
