import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_details_screen.dart';

class MatchesPage extends StatefulWidget {
  final String? postId; // Nullable
  const MatchesPage({super.key, this.postId});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  bool loading = true;
  List<Map<String, dynamic>> matches = [];
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.postId != null && widget.postId!.isNotEmpty) {
      _findMatches();
    } else {
      setState(() {
        loading = false;
        error = "Invalid post ID.";
      });
    }
  }

  Future<void> _findMatches() async {
    try {
      final postSnap = await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.postId)
          .get();

      if (!postSnap.exists) {
        setState(() {
          loading = false;
          error = "Post not found.";
        });
        return;
      }

      final myLabels = List<String>.from(postSnap['labels'] ?? []);
      if (myLabels.isEmpty) {
        setState(() {
          loading = false;
          error = "No labels found for this post.";
        });
        return;
      }

      final itemsSnap = await FirebaseFirestore.instance.collection('items').get();

      final foundMatches = itemsSnap.docs
          .where((d) => d.id != widget.postId)
          .map((d) {
            final data = d.data();
            final labels = List<String>.from(data['labels'] ?? []);
            final common = myLabels.where(labels.contains).length;
            return common > 0
                ? {...data, 'docId': d.id, 'score': common / myLabels.length}
                : null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      foundMatches.sort((a, b) => (b['score']).compareTo(a['score']));

      setState(() {
        matches = foundMatches;
        loading = false;
        if (matches.isEmpty) error = "No matches found.";
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = "No matches found.";
      });
      debugPrint("MatchesPage error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Possible Matches"),
        backgroundColor: const Color.fromARGB(255, 101, 101, 196),
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(fontSize: 16)))
              : ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (_, i) {
                    final m = matches[i]; 
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: m['photoUrl'] != null
                            ? Image.network(
                                m['photoUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image),
                        title: Text(m['title'] ?? 'No title'),
                        subtitle: Text(m['description'] ?? ''),
                        trailing: Text(
                          "${(m['score'] * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(color: Colors.green),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailsScreen(
                              itemData: m,
                              docId: m['docId'],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
