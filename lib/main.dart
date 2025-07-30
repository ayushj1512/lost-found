import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- added
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'package:lostandfound/pages/dashboard_screen.dart';
import 'package:lostandfound/pages/login.dart';
import 'package:lostandfound/pages/my_posts_screen.dart';
import 'package:lostandfound/pages/post_item_screen.dart';
import 'package:lostandfound/pages/auth/signup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrainTrack Lost & Found',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF7F6FB),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)
            .copyWith(
              primary: Colors.deepPurple,
              secondary: Colors.deepPurpleAccent,
            ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/postItem': (context) => const PostItemScreen(),
        '/myPosts': (context) => const MyPostsScreen(),
      },
    );
  }
}

/// Handles user authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
          );
        }

        if (snapshot.hasData) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
