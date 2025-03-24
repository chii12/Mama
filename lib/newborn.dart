import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NewbornScreen extends StatefulWidget {
  const NewbornScreen({super.key});

@override
  _NewbornScreenState createState() => _NewbornScreenState();
}

class _NewbornScreenState extends State<NewbornScreen> {
  final supabase = Supabase.instance.client;


Future<List<Map<String, dynamic>>> _fetchFiles() async {
  final response = await supabase.from('newborn_care').select().eq('status', 'published');
  
  return response.map((doc) {
    return {
      'title': doc['title'] ?? 'Untitled', // Default title if null
      'description': doc['description'] ?? 'No description available', // Default description
      'url': doc['url'] ?? '', // Empty string instead of null
    };
  }).toList();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Newborn Guide"), backgroundColor: Colors.pinkAccent),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFiles(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return Center(child: Text("No published newborn care guides."));

          return ListView(
            children: snapshot.data!.map((doc) {
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(doc['title']),
                  subtitle: Text(doc['description']),
                  onTap: () => launchUrl(Uri.parse(doc['url'])),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
