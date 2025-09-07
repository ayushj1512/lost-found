import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lostandfound/main.dart';
import 'package:lostandfound/pages/matchespage.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        // Navigate to MatchesPage only if payload is valid
        if (payload != null && payload.isNotEmpty) {
          try {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => MatchesPage(postId: payload),
              ),
            );
          } catch (e) {
            debugPrint("Notification navigation error: $e");
          }
        } else {
          debugPrint("Notification tapped with empty payload, no navigation.");
        }
      },
    );
  }

  static Future<void> showNotification(String? postId) async {
    if (postId == null || postId.isEmpty) return;

    const android = AndroidNotificationDetails(
      'matches_channel',
      'Matches',
      channelDescription: 'Notifications for item matches',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: android);

    await _notifications.show(
      0,
      'New Match Found 🎉',
      'We found a possible match for your item!',
      details,
      payload: postId,
    );
  }
}
