import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lostandfound/pages/item_details_screen.dart';
import 'package:lostandfound/pages/post_item_screen.dart';

class LostScreen extends StatefulWidget {
  const LostScreen({super.key});

  @override
  State<LostScreen> createState() => _LostScreenState();
}

class _LostScreenState extends State<LostScreen> {
  String searchQuery = "";
  String sortBy = "date"; // default sorting
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    Query lostItemsQuery = FirebaseFirestore.instance
        .collection('items')
        .where('type', isEqualTo: 'Lost');

    // 🔍 Sorting
    if (sortBy == "date") {
      lostItemsQuery = lostItemsQuery.orderBy('date', descending: true);
    } else if (sortBy == "title") {
      lostItemsQuery = lostItemsQuery.orderBy('title');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(179, 168, 250, 1),
        elevation: 0,
        centerTitle: true,
        title: const Text('Lost Items', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔍 Search + Sort + Calendar Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search items...",
                      prefixIcon: const Icon(Icons.search),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Sort Dropdown
                DropdownButton<String>(
                  value: sortBy,
                  items: const [
                    DropdownMenuItem(value: "date", child: Text("Sort by Date")),
                    DropdownMenuItem(value: "title", child: Text("Sort by Title")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      sortBy = value!;
                    });
                  },
                ),
                const SizedBox(width: 10),
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

          // 🔄 Items List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: lostItemsQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No lost items available."));
                }

                final now = DateTime.now();
                final sevenDaysAgo = now.subtract(const Duration(days: 7));

                final items = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? "").toString().toLowerCase();
                  final desc = (data['description'] ?? "").toString().toLowerCase();

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

                  final searchMatch = title.contains(searchQuery) || desc.contains(searchQuery);

                  return dateMatch && searchMatch;
                }).toList();

                if (items.isEmpty) {
                  return const Center(child: Text("No matching items found."));
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
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (item['photoUrl'] != null &&
                                  item['photoUrl'].toString().isNotEmpty)
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(item['photoUrl']),
                                  backgroundColor: Colors.grey[200],
                                  onBackgroundImageError: (_, __) {},
                                )
                              else
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported,
                                      size: 40, color: Colors.grey),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${item['title'] ?? 'Unknown'}",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
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
