import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lostandfound/pages/SearchByImagePage.dart';
import 'package:lostandfound/pages/matchespage.dart';
import 'package:lostandfound/services/local_notification_service.dart';

import 'firebase_options.dart';
import 'package:lostandfound/pages/dashboard_screen.dart';
import 'package:lostandfound/pages/auth/login.dart';
import 'package:lostandfound/pages/my_posts_screen.dart';
import 'package:lostandfound/pages/post_item_screen.dart';
import 'package:lostandfound/pages/auth/signup.dart';

// ✅ Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("🔔 Background message: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Initialize local notifications
  await NotificationService.init();

  // ✅ FCM setup
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions (important for Android 13+ & iOS)
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Get FCM token
  String? token = await messaging.getToken();
  debugPrint("📲 FCM Token: $token");

  // Foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("🔔 Foreground message: ${message.notification?.title}");
  });

  // Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrainTrack Lost & Found',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // ✅ important
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        textTheme: GoogleFonts.ralewayTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF7F6FB),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple).copyWith(
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
      onGenerateRoute: (settings) {
        // ✅ Safe navigation for notification payload
        if (settings.name == '/matches') {
          final args = settings.arguments;
          if (args != null && args is String && args.isNotEmpty) {
            return MaterialPageRoute(
              builder: (_) => MatchesPage(postId: args),
            );
          } else {
            // fallback to SearchByImagePage if payload is null/empty
            return MaterialPageRoute(
              builder: (_) => const SearchByImagePage(),
            );
          }
        }
        return null; // default null
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
