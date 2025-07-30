import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lostandfound/pages/item_details_screen.dart';
import 'package:lostandfound/pages/post_item_screen.dart';

class FoundScreen extends StatelessWidget {
  const FoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final foundItemsQuery = FirebaseFirestore.instance
        .collection('items')
        .where('type', isEqualTo: 'Found');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        centerTitle: true,
        title: const Text('Found Items', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: foundItemsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No found items available.'));
          }

          final items = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final doc = items[index];
              final item = doc.data() as Map<String, dynamic>;

              // Injecting doc ID and uid into itemData
              item['id'] = doc.id;
              item['uid'] = item['uid'] ?? ''; // Ensure uid is present

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Title: ${item['title'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Category: ${item['category'] ?? '-'}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Train No: ${item['trainNumber'] ?? '-'}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Station: ${item['station'] ?? '-'}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Posted By: ${item['postedBy'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Date: ${item['date'] ?? '-'}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['description'] ?? 'No description provided.',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if ((item['status'] ?? '').toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['status'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Implement match logic here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Match Item'),
                          ),
                          ElevatedButton(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Details'),
                          ),
                        ],
                      ),
                    ],
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
            MaterialPageRoute(builder: (_) => const PostItemScreen()),
          );
        },
        backgroundColor: const Color(0xFFBBDEFB),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
