import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lostandfound/pages/matchespage.dart' show MatchesPage;


class PostedItemsList extends StatelessWidget {
  final String uid;

  const PostedItemsList({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final postsRef = FirebaseFirestore.instance
        .collection('items')
        .where('uid', isEqualTo: uid);

    return StreamBuilder<QuerySnapshot>(
      stream: postsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "You haven’t posted any items yet.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemBuilder: (context, index) {
            final doc = posts[index];
            final item = doc.data() as Map<String, dynamic>;
            final photoUrl = item['photoUrl'];

            return InkWell(
              onTap: () {
                // ✅ Navigate to MatchesPage when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchesPage(postId: doc.id),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: photoUrl != null && photoUrl.toString().isNotEmpty
                            ? Image.network(
                                photoUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 40),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image,
                                    size: 30, color: Colors.white70),
                              ),
                      ),

                      const SizedBox(width: 10),

                      /// Item Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Title
                            Text(
                              item['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 4),

                            /// Type + Train
                            Text(
                              "${item['type']} • ${item['train'] ?? ''}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),

                            /// Date & Category
                            Text(
                              "📅 ${item['date'] ?? ''} • 🧾 ${item['category'] ?? ''}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
