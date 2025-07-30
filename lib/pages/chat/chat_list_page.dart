import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lostandfound/pages/chat/chat_screen.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final Color? primaryColor = Colors.blue[700];
  final Color? accentColor = Colors.amber[400];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Messages',
          style: TextStyle(
            color: primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
       
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUserId)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final chatId = chats[index].id;

              final List users = chat['users'] ?? [];
              if (!users.contains(currentUserId)) return const SizedBox.shrink();

              final otherUserId = users.firstWhere(
                (id) => id != currentUserId,
                orElse: () => null,
              );

              if (otherUserId == null) return const SizedBox.shrink();

              final lastMessageData = chat['lastMessage'] ?? {};
              final lastText = lastMessageData['text'] ?? '';
              final timestamp =
                  (lastMessageData['timestamp'] as Timestamp?)?.toDate();
              final time = timestamp != null
                  ? TimeOfDay.fromDateTime(timestamp).format(context)
                  : '';

              final readBy = lastMessageData['readBy'] ?? {};
              final unread = readBy[currentUserId] == false;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData || !userSnap.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final userName = userData['name'] ?? 'User';

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              chatId: chatId,
                              otherUserId: otherUserId,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: Colors.white,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          child: Row(
                            children: [
                              const SizedBox(width: 0), // Reserved for avatar
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  unread
                                      ? CircleAvatar(
                                          radius: 10,
                                          backgroundColor: accentColor,
                                          child: const Text(
                                            '1',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white),
                                          ),
                                        )
                                      : Icon(Icons.check,
                                          size: 16, color: Colors.grey[400]),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
