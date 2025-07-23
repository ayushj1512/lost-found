import 'package:flutter/material.dart';
import 'package:lostandfound/pages/dashboard_screen.dart';
import 'package:lostandfound/pages/item_details_screen.dart'
    show ItemDetailsScreen;
import 'package:lostandfound/pages/login.dart';
import 'package:lostandfound/pages/my_posts_screen.dart' show MyPostsScreen;
import 'package:lostandfound/pages/post_item_screen.dart';
import 'package:lostandfound/pages/signup.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrainTrack Lost & Found',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/postItem': (context) => const PostItemScreen(),
        '/itemDetails': (context) => const ItemDetailsScreen(),
        '/myPosts': (context) => const MyPostsScreen(),
      },
    );
  }
}
