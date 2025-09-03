import 'package:cloud_firestore/cloud_firestore.dart';
import 'image_label_service.dart';

class PostService {
  static Future<void> savePost(String imageUrl, String userId) async {
    final labels = await ImageLabelService.getLabelsFromUrl(imageUrl);

    await FirebaseFirestore.instance.collection("posts").add({
      "imageUrl": imageUrl,
      "userId": userId,
      "labels": labels,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> findMatches(List<String> newLabels) async {
    final snapshot = await FirebaseFirestore.instance.collection("posts").get();

    List<Map<String, dynamic>> matches = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final existingLabels = List<String>.from(data["labels"] ?? []);
      final overlap = existingLabels.where((l) => newLabels.contains(l)).toList();

      if (overlap.isNotEmpty) {
        matches.add({...data, "overlap": overlap});
      }
    }
    return matches;
  }
}
