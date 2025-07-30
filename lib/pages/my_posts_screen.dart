import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lostandfound/components/PostedItemsList.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "My Posts",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 4,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text("User not logged in."))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Personal Details",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text("Name: ${user.displayName ?? 'N/A'}"),
                                Text("Email: ${user.email ?? 'N/A'}"),
                                Text("UID: ${user.uid}"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "My Posted Items",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: PostedItemsList(uid: user.uid),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton.icon(
          onPressed: () {
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
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
