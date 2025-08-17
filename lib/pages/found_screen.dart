import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lostandfound/pages/item_details_screen.dart';
import 'package:lostandfound/pages/post_item_screen.dart';

class FoundScreen extends StatefulWidget {
  const FoundScreen({super.key});

  @override
  State<FoundScreen> createState() => _FoundScreenState();
}

class _FoundScreenState extends State<FoundScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _sortBy = "Date"; // Default sort option
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final foundItemsQuery = FirebaseFirestore.instance
        .collection('items')
        .where('type', isEqualTo: 'Found');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(179, 168, 250, 1),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Found Items',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔍 Search Bar + 🔽 Sort By + 📅 Date Picker
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search items...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Sort Dropdown
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: "Date", child: Text("Date")),
                    DropdownMenuItem(value: "Title", child: Text("Title")),
                    DropdownMenuItem(value: "Category", child: Text("Category")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                ),
                const SizedBox(width: 12),
                // Calendar Button
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.black54),
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // 🔄 Firestore Data
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: foundItemsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No found items available.'));
                }

                final now = DateTime.now();
                final sevenDaysAgo = now.subtract(const Duration(days: 7));

                // Filter items
                List<QueryDocumentSnapshot> items = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final description =
                      (data['description'] ?? '').toString().toLowerCase();
                  final category =
                      (data['category'] ?? '').toString().toLowerCase();

                  // Check date
                  final itemDateString = data['date'] ?? '';
                  DateTime? itemDate;
                  try {
                    itemDate = DateFormat('yyyy-MM-dd').parse(itemDateString);
                  } catch (_) {
                    itemDate = null;
                  }

                  final dateMatch = _selectedDate != null
                      ? itemDate != null &&
                          itemDate.year == _selectedDate!.year &&
                          itemDate.month == _selectedDate!.month &&
                          itemDate.day == _selectedDate!.day
                      : itemDate != null && itemDate.isAfter(sevenDaysAgo);

                  final searchMatch =
                      title.contains(_searchQuery) ||
                      description.contains(_searchQuery) ||
                      category.contains(_searchQuery);

                  return dateMatch && searchMatch;
                }).toList();

                // Sort items
                items.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;

                  if (_sortBy == "Title") {
                    return (dataA['title'] ?? '')
                        .toString()
                        .compareTo((dataB['title'] ?? '').toString());
                  } else if (_sortBy == "Category") {
                    return (dataA['category'] ?? '')
                        .toString()
                        .compareTo((dataB['category'] ?? '').toString());
                  } else {
                    return (dataB['date'] ?? '')
                        .toString()
                        .compareTo((dataA['date'] ?? '').toString());
                  }
                });

                if (items.isEmpty) {
                  return const Center(
                      child: Text("No items match your search or date filter."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final item = doc.data() as Map<String, dynamic>;

                    item['id'] = doc.id;
                    item['uid'] = item['uid'] ?? '';

                    // Format date
                    String formattedDate = '-';
                    if (item['date'] != null && item['date'].toString().isNotEmpty) {
                      try {
                        final dt = DateFormat('yyyy-MM-dd').parse(item['date']);
                        formattedDate = DateFormat('dd MMM yyyy').format(dt);
                      } catch (_) {}
                    }

                    return InkWell(
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
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item['photoUrl'] != null &&
                                  item['photoUrl'].toString().isNotEmpty)
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(item['photoUrl']),
                                  backgroundColor: Colors.grey[200],
                                  onBackgroundImageError: (error, stackTrace) {},
                                )
                              else
                                const CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.image_not_supported,
                                      size: 40, color: Colors.white),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${item['title'] ?? 'Unknown'}",
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Category: ${item['category'] ?? '-'}",
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['description'] ??
                                          'No description provided.',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Date: $formattedDate",
                                      style: const TextStyle(fontSize: 13),
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
            ),
          ),
        ],
      ),
    );
  }
}
