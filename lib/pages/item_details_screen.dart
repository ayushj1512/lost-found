import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lostandfound/components/showContactOptionsBottomSheet.dart'
    show showContactOptionsBottomSheet;

class ItemDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final String docId; // <-- Firestore Document ID

  const ItemDetailsScreen({
    super.key,
    required this.itemData,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue[700];
    final accentColor = Colors.amber[400];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview
            Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: itemData['photoUrl'] != null &&
                          itemData['photoUrl'].toString().isNotEmpty
                      ? Image.network(itemData['photoUrl'], fit: BoxFit.cover)
                      : const Center(
                          child: Icon(
                            Icons.image,
                            size: 90,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Card(
              elevation: 6,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemData['title'] ?? 'Unknown Item',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    infoRow('Status', itemData['status'] ?? '-'),
                    infoRow('Date', itemData['date'] ?? '-'),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      itemData['description'] ?? 'No description provided.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Contact Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final String? finderUid = itemData['uid'];

                  print('item id: $docId');
                  print('user id: $finderUid');

                  if (finderUid == null || finderUid.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact details unavailable.'),
                      ),
                    );
                    return;
                  }

                  final userData = await fetchUserDetails(finderUid);

                  if (userData != null) {
                    final email = userData['email'] ?? '';

                    if (email.isNotEmpty) {
                      showContactOptionsBottomSheet(
                        context,
                        email,
                        finderUid,
                        docId, // use docId
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No contact info found.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to fetch contact info.')),
                    );
                  }
                },
                icon: const Icon(Icons.mail_outline),
                label: const Text('Contact Poster'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                  shadowColor: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fetches user details from Firestore using UID
  Future<Map<String, dynamic>?> fetchUserDetails(String uid) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (snapshot.exists) {
        return snapshot.data();
      } else {
        print('User document does not exist.');
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
    return null;
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
