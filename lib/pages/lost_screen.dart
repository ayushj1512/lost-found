import 'package:flutter/material.dart';
import 'item_details_screen.dart';

class LostScreen extends StatelessWidget {
  const LostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage('assets/placeholder.jpg'),
            ),
            title: Text('Lost Item ${index + 1}'),
            subtitle: const Text('Train No: 12345\nStation: NDLS'),
            isThreeLine: true,
            trailing: TextButton(
              child: const Text('Details'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ItemDetailsScreen()),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
