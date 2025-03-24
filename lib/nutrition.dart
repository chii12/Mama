import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  _NutritionScreenState createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final supabase = Supabase.instance.client;

  /// Fetch published nutrition files
  Future<List<Map<String, dynamic>>> _fetchFiles() async {
    final response = await supabase.from('nutrition').select().eq('status', 'published');
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nutrition Guide"), backgroundColor: Colors.pinkAccent),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchFiles(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return Center(child: Text("No published nutrition guides."));

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
