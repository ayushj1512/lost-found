import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String? itemId; // Optional: only needed when initiating
  final String? docId; // optional field

  const ChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    this.itemId,  
     this.docId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  DocumentSnapshot<Map<String, dynamic>>? _itemSnapshot;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _loadOrFetchItem(); // handles both new and stored itemId
  }

  void _loadOrFetchItem() async {
    final chatDoc =
        await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();

    final existingItemId = chatDoc.data()?['itemId'];

    if (existingItemId != null) {
      _fetchItemDetails(existingItemId);
    } else if (widget.itemId != null) {
      // Store itemId during first message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .set({'itemId': widget.itemId}, SetOptions(merge: true));
      _fetchItemDetails(widget.itemId!);
    }
  }

  Future<void> _fetchItemDetails(String itemId) async {
    final doc = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
    if (doc.exists) {
      setState(() {
        _itemSnapshot = doc;
      });
    }
  }

  void _markMessagesAsRead() async {
    final unreadMessages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('readBy.$currentUserId', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'readBy.$currentUserId': true});
    }
  }

  void sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final newMessage = {
      'text': messageText,
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'readBy': {
        currentUserId: true,
        widget.otherUserId: false,
      }
    };

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    final messageRef = chatRef.collection('messages').doc();

    await messageRef.set(newMessage);

    await chatRef.set({
      'lastMessage': newMessage,
      'updatedAt': FieldValue.serverTimestamp(),
      'users': [currentUserId, widget.otherUserId],
    }, SetOptions(merge: true));

    _messageController.clear();
  }

  Widget _buildItemBanner() {
    if (_itemSnapshot == null || !_itemSnapshot!.exists) return const SizedBox();

    final data = _itemSnapshot!.data()!;
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      child: ListTile(
        leading: data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty
            ? Image.network(data['photoUrl'], width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.image, size: 40, color: Colors.grey),
        title: Text(data['title'] ?? 'Item'),
        subtitle: const Text('You are chatting about this item'),
      ),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getOtherUserStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 1,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: getOtherUserStream(),
          builder: (context, snapshot) {
            final userData = snapshot.data?.data();
            final name = userData?['name'] ?? 'User';
            return Text(name);
          },
        ),
      ),
      body: Column(
        children: [
          if (_itemSnapshot != null) _buildItemBanner(), // ✅ Always show if loaded
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUserId;
                    final readBy = data['readBy'] ?? {};
                    final isSeen = readBy[widget.otherUserId] == true;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: Radius.circular(isMe ? 12 : 0),
                                bottomRight: Radius.circular(isMe ? 0 : 12),
                              ),
                            ),
                            child: Text(
                              data['text'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (isMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Icon(
                                isSeen ? Icons.done_all : Icons.check,
                                size: 16,
                                color: isSeen ? Colors.blue : Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
