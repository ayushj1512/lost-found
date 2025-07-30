import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lostandfound/pages/chat/chat_list_page.dart';
import 'package:lostandfound/pages/found_screen.dart';
import 'package:lostandfound/pages/lost_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Stream<int> getUnreadChatCountStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Map<String, dynamic>? lastMessage = data['lastMessage'];
        if (lastMessage == null) continue;

        final String senderId = lastMessage['senderId'] ?? '';
        final Map readBy = lastMessage['readBy'] ?? {};

        final bool isUnread = readBy[currentUserId] == false;
        final bool isNotSender = senderId != currentUserId;

        if (isNotSender && isUnread) {
          count++;
        }
      }
      return count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<int>(
        stream: getUnreadChatCountStream(),
        builder: (context, snapshot) {
          int unreadCount = snapshot.data ?? 0;

          return Column(
            children: [
              Stack(
                children: [
                  ClipPath(
                    clipper: WaveClipper(),
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF26C6DA)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: const SafeArea(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Spacer(),
                              Text(
                                "Welcome To Mila kya?",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "What you lost, we will find.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 🔔 Chat icon with badge (no number)
                  Positioned(
                    top: 20,
                    right: 16,
                    child: SafeArea(
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: Colors.white, size: 28),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ChatListPage()),
                              );
                            },
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 🟥 Red message if there are unread chats
              
              const SizedBox(height: 20),

              // 🔘 Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LostScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Lost Items",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FoundScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Found Items",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    final firstControlPoint = Offset(size.width / 2, size.height);
    final firstEndPoint = Offset(size.width, size.height - 60);
    path.quadraticBezierTo(
        firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
