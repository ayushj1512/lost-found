import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_details_screen.dart'; // ✅ import your details page

class MatchesPage extends StatefulWidget {
  final String postId; // Pass the Firestore document ID of the user's post

  const MatchesPage({super.key, required this.postId});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> matches = [];

  @override
  void initState() {
    super.initState();
    _findMatches();
  }

  /// Find items in Firestore with overlapping labels
  Future<void> _findMatches() async {
    final postDoc = await FirebaseFirestore.instance
        .collection('items')
        .doc(widget.postId)
        .get();

    if (!postDoc.exists) {
      setState(() => isLoading = false);
      return;
    }

    final postData = postDoc.data()!;
    final List<String> myLabels = List<String>.from(postData['labels'] ?? []);

    final snapshot = await FirebaseFirestore.instance.collection('items').get();

    List<Map<String, dynamic>> foundMatches = [];
    for (var doc in snapshot.docs) {
      if (doc.id == widget.postId) continue; // skip own post

      final data = doc.data();
      final itemLabels = List<String>.from(data['labels'] ?? []);

      int common = myLabels.where((l) => itemLabels.contains(l)).length;

      if (common > 0) {
        foundMatches.add({
          ...data,
          'docId': doc.id, // ✅ keep the Firestore document ID
          'matchScore': common / myLabels.length,
        });
      }
    }

    foundMatches.sort((a, b) => (b['matchScore']).compareTo(a['matchScore']));

    setState(() {
      matches = foundMatches;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Possible Matches"),
        backgroundColor: const Color.fromARGB(255, 101, 101, 196),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : matches.isEmpty
          ? const Center(child: Text("No matches found."))
          : ListView.builder(
              itemCount: matches.length,
              itemBuilder: (ctx, i) {
                final item = matches[i];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: item['photoUrl'] != null
                        ? Image.network(
                            item['photoUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image),
                    title: Text(item['title'] ?? 'No title'),
                    subtitle: Text(item['description'] ?? ''),
                    trailing: Text(
                      "Score: ${(item['matchScore'] * 100).toStringAsFixed(0)}%",
                      style: const TextStyle(color: Colors.green),
                    ),
                    onTap: () {
                      // ✅ Navigate to ItemDetailsScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailsScreen(
                            itemData: item,
                            docId: item['docId'], // pass Firestore doc ID
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
