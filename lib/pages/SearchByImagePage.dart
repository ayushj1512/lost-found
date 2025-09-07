import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'matchespage.dart';
import 'item_details_screen.dart';

class SearchByImagePage extends StatefulWidget {
  const SearchByImagePage({super.key});

  @override
  State<SearchByImagePage> createState() => _SearchByImagePageState();
}

class _SearchByImagePageState extends State<SearchByImagePage> {
  File? _selectedImage;
  bool _loading = false;
  List<Map<String, dynamic>> _matches = [];
  String? _error;

  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  /// Search matches based on uploaded image labels
  Future<void> _searchMatches() async {
    if (_selectedImage == null) return;
    setState(() {
      _loading = true;
      _matches = [];
      _error = null;
    });

    try {
      final inputImage = InputImage.fromFile(_selectedImage!);

      // ML Kit Image Labeler (On-device)
      final options = ImageLabelerOptions(confidenceThreshold: 0.3);
      final labeler = ImageLabeler(options: options);
      final labels = await labeler.processImage(inputImage);

      final extractedLabels = labels.map((l) => l.label.toLowerCase()).toList();
      if (extractedLabels.isEmpty) {
        setState(() {
          _error = "No labels detected in the image.";
          _loading = false;
        });
        return;
      }

      // Fetch all items from Firestore
      final snapshot = await FirebaseFirestore.instance.collection('items').get();

      // Filter posts that share at least one label
      List<Map<String, dynamic>> found = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final postLabels = List<String>.from(data['labels'] ?? []).map((e) => e.toLowerCase()).toList();
        final common = extractedLabels.where(postLabels.contains).length;
        if (common > 0) {
          found.add({...data, 'docId': doc.id, 'score': common / extractedLabels.length});
        }
      }

      found.sort((a, b) => (b['score']).compareTo(a['score']));

      setState(() {
        _matches = found;
        _loading = false;
        if (_matches.isEmpty) _error = "No matches found.";
      });

    } catch (e) {
      setState(() {
        _error = "Failed to process image.";
        _loading = false;
      });
      debugPrint("SearchByImage error: $e");
    }
  }

  /// Select a post from user's own posts
  Future<void> _selectOwnPost() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('uid', isEqualTo: uid)
        .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You haven’t posted any items yet.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: snapshot.docs.map((doc) {
          final data = doc.data();
          final photoUrl = data['photoUrl'];
          return ListTile(
            leading: photoUrl != null
                ? Image.network(photoUrl, width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.image),
            title: Text(data['title'] ?? 'No title'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchesPage(postId: doc.id),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search by Image")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 200)
                : Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Text("No image selected")),
                  ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _pickImage, child: const Text("Upload Image")),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _searchMatches, child: const Text("Search")),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _selectOwnPost, child: const Text("Select from My Posts")),
            const SizedBox(height: 10),
            _loading
                ? const CircularProgressIndicator()
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(fontSize: 16)))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _matches.length,
                          itemBuilder: (_, i) {
                            final m = _matches[i];
                            return Card(
                              child: ListTile(
                                leading: m['photoUrl'] != null
                                    ? Image.network(m['photoUrl'], width: 50, height: 50, fit: BoxFit.cover)
                                    : const Icon(Icons.image),
                                title: Text(m['title'] ?? 'No title'),
                                subtitle: Text(m['description'] ?? ''),
                                trailing: Text(
                                  "${(m['score'] * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(color: Colors.green),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ItemDetailsScreen(itemData: m, docId: m['docId']),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
