import 'package:flutter/material.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  // Dummy user-posted items with personal details
  final List<Map<String, dynamic>> myItems = const [
    {
      'title': 'Lost Headphones',
      'type': 'Lost',
      'train': '12951 / Rajdhani Express',
      'date': '20 July 2025',
      'status': 'Open',
      'category': 'Electronics',
      'name': 'Person XYZ',
      'email': 'xyz@example.com',
      'phone': '+91 9876543210',
    },
    {
      'title': 'Found Wallet',
      'type': 'Found',
      'train': '12234 / Duronto',
      'date': '18 July 2025',
      'status': 'Claimed',
      'category': 'Wallet',
      'name': 'Person XYZ',
      'email': 'xyz@example.com',
      'phone': '+91 9876543210',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: myItems.isEmpty
          ? const Center(child: Text("You haven’t posted any items yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myItems.length,
              itemBuilder: (context, index) {
                final item = myItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Type: ${item['type']}'),
                        Text('Train: ${item['train']}'),
                        Text('Date: ${item['date']}'),
                        Text('Category: ${item['category']}'),
                        const Divider(height: 20),
                        Text('Posted By: ${item['name']}'),
                        Text('Email: ${item['email']}'),
                        Text('Phone: ${item['phone']}'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(item['status']),
                              backgroundColor: item['status'] == 'Open'
                                  ? Colors.orange[200]
                                  : Colors.green[300],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    // TODO: Add edit logic
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    // TODO: Add delete logic
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO: Add logout logic
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      // Example: Navigate to login screen
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
