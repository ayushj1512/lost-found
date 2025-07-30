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
        backgroundColor: const Color(0xFF2196F3),
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 500 + index * 100),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item['photoUrl'] != null &&
                            item['photoUrl'].toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item['photoUrl'],
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(height: 12),

                        Text(
                          "Name: ${item['title'] ?? 'Unknown'}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),

                        if (item['color'] != null)
                          Text(
                            "Color: ${item['color']}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 8),

                        Text(
                          item['description'] ?? 'No description provided.',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Date: ${item['date'] ?? 'Unknown'}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (item['status'] != null &&
                                item['status'].toString().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.shade100,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  item['status'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ItemDetailsScreen(
  itemData: item,
  docId: items[index].id, // 👈 pass document ID from snapshot
),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                elevation: 3,
                              ),
                            ),
                          ],
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
          Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=> PostItemScreen()));
        },
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 5,
      ),
    );
  }
}
