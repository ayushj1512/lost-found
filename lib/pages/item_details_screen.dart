import 'package:flutter/material.dart';

class ItemDetailsScreen extends StatelessWidget {
  const ItemDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Details'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: Icon(Icons.image, size: 80, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            Text('Lost Black Wallet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Category: Wallet'),
            Text('Type: Lost'),
            Text('Date: 22 July 2025'),
            Text('Train No: 12345'),
            Text('Station: New Delhi'),
            SizedBox(height: 16),
            Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Lost it while boarding the train. Black color with ID card inside.'),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.mail),
                label: Text('Contact Poster'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
