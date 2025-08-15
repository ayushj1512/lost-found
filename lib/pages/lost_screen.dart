import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lostandfound/pages/item_details_screen.dart';
import 'package:lostandfound/pages/post_item_screen.dart';

class LostScreen extends StatelessWidget {
  const LostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lostItemsQuery = FirebaseFirestore.instance
        .collection('items')
        .where('type', isEqualTo: 'Lost');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(179, 168, 250, 1),
        elevation: 1,
        title: const Text(
          'Lost Items',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: lostItemsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No lost items found.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final items = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              // Make the card a bit taller so image can dominate visually
              childAspectRatio: 0.68,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>? ?? {};

              return Padding(
                // OUTER padding around the entire card (top/bottom/left/right)
                padding: const EdgeInsets.all(8.0),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  clipBehavior: Clip.hardEdge,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailsScreen(
                            itemData: item,
                            docId: items[index].id,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image area (takes majority of the card)
                        Expanded(
                          flex: 6,
                          child: Container(
                            // INNER padding so image doesn't touch rounded corners
                            padding: const EdgeInsets.all(8),
                            color: Colors.white,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: item['photoUrl'] != null &&
                                      item['photoUrl'].toString().isNotEmpty
                                  ? Image.network(
                                      item['photoUrl'],
                                      fit: BoxFit.contain, // show full image
                                      width: double.infinity,
                                      height: double.infinity,
                                      alignment: Alignment.center,
                                      // Gracefully handle load errors
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(Icons.broken_image,
                                              size: 36, color: Colors.grey),
                                        );
                                      },
                                    )
                                  : const Center(
                                      child: Icon(Icons.image_not_supported,
                                          size: 36, color: Colors.grey),
                                    ),
                            ),
                          ),
                        ),

                        // Text / meta area (smaller)
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (item['title'] ?? 'Unknown').toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (item['color'] != null &&
                                    item['color'].toString().isNotEmpty)
                                  Text(
                                    "Color: ${item['color']}",
                                    style: const TextStyle(
                                        color: Color.fromARGB(255, 229, 222, 249), fontSize: 13),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  (item['description'] ?? 'No description provided.')
                                      .toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        (item['date'] ?? 'Unknown').toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                ),
                              ],
                            ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PostItemScreen()),
          );
        },
        backgroundColor: const Color.fromARGB(255, 126, 97, 255),
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 5,
      ),
    );
  }
}
