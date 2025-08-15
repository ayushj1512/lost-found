import 'package:flutter/material.dart';
import 'package:lostandfound/pages/my_posts_screen.dart';
import 'home_screen.dart';
import 'post_item_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    MyPostsScreen(),
  ];

  void _openPostItemScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostItemScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        color: Colors.white,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.home,
                      color: _selectedIndex == 0
                          ? const Color.fromARGB(255, 63, 56, 152)
                          : Colors.grey.shade500,
                      size: 28,
                    ),
                    Text(
                      'Home',
                      style: TextStyle(
                        color: _selectedIndex == 0
                            ? const Color.fromARGB(255, 63, 56, 152)
                            : Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48), // Space for FAB
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: _selectedIndex == 1
                          ? const Color.fromARGB(255, 63, 56, 152)
                          : Colors.grey.shade500,
                      size: 28,
                    ),
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: _selectedIndex == 1
                            ? const Color.fromARGB(255, 63, 56, 152)
                            : Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 224, 212, 255),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: _openPostItemScreen,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
