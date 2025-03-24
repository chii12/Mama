import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

class AdminNutritionScreen extends StatefulWidget {
  const AdminNutritionScreen({super.key});

  @override
  _AdminNutritionScreenState createState() => _AdminNutritionScreenState();
}

class _AdminNutritionScreenState extends State<AdminNutritionScreen> {
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
    await supabase.storage.from('nutrition').uploadBinary(filePath, _fileBytes!);
    String fileUrl = supabase.storage.from('nutrition').getPublicUrl(filePath);

    await supabase.from('nutrition').insert({
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
  final response = await supabase.from('nutrition').select();

  return response.map((doc) {
    return {
      'id': doc['id']?.toString() ?? '',  // Ensure ID is a string
      'title': doc['title'] ?? 'No Title',
      'description': doc['description'] ?? 'No description available',
      'url': doc['url'] ?? '',  // Ensure URL is never null
      'file_name': doc['file_name'] ?? 'Unknown',
      'file_type': doc['file_type'] ?? 'unknown',
    //  'thumbnail': doc['thumbnail'] ?? 'https://via.placeholder.com/50',
      'status': doc['status'] ?? 'draft',
    };
  }).toList();
}

  /// Deletes a file
  Future<void> _deleteFile(String fileName, String docId) async {
    try {
      await supabase.storage.from('nutrition').remove([fileName]);
      await supabase.from('nutrition').delete().eq('id', docId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File deleted successfully!")));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete file: $e")));
    }
  }

  Future<void> _uploadDraft(String docId) async {
  try {
    await supabase.from('nutrition').update({
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
      appBar: AppBar(title: Text("Admin Nutrition"), backgroundColor: Colors.pinkAccent),
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
                if (snapshot.data!.isEmpty) return Center(child: Text("No nutrition files uploaded yet."));

                return ListView(
  children: snapshot.data!.map((doc) {
    String fileUrl = doc['url'];
    String fileName = doc['file_name'];
    String fileType = doc['file_type'] ?? '';
    String title = doc['title'] ?? 'No Title';
    String description = doc['description'] ?? 'No description';
    String docId = doc['id'].toString();
    String status = doc['status'] ?? 'draft';

    return Card(
      margin: EdgeInsets.all(10),
      child: ListTile(
        leading: isImage(fileType)
            ? Image.network(
                fileUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.broken_image, size: 50, color: Colors.grey),
              )
            : Icon(Icons.insert_drive_file, size: 40, color: Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            Text("File Type: ${fileType.toUpperCase()}", style: TextStyle(color: Colors.grey)),
          ],
        ),
        onTap: () => launchUrl(Uri.parse(fileUrl)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'draft')  // Show only for drafts
              ElevatedButton(
                onPressed: () => _uploadDraft(docId), 
                child: Text("Upload"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteFile(fileName, docId),
            ),
          ],
        ),
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
