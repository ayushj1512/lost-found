import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lostandfound/pages/chat/chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

final primaryColor = Colors.blue[700];
final accentColor = Colors.amber[400];

void showContactOptionsBottomSheet(
  BuildContext context,
  String finderEmail,
  String finderUid,
  String itemId,
) async {
  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser == null) {
    _showTopNotification(context, "You need to be logged in to chat.");
    return;
  }

  List<String> ids = [currentUser.uid, finderUid];
  ids.sort();
  final chatId = ids.join('_');

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contact_mail, size: 40, color: primaryColor),
            const SizedBox(height: 10),
            const Text(
              'Contact Finder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ListTile(
              leading: Icon(Icons.email, color: primaryColor),
              title: const Text('Email the Finder'),
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: finderEmail,
                );

                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                } else {
                  await Clipboard.setData(ClipboardData(text: finderEmail));
                  _showTopNotification(
                    context,
                    "Couldn't open email app. Finder's email copied.",
                  );
                }
              },
            ),

            ListTile(
              leading: Icon(Icons.chat, color: primaryColor),
              title: const Text('Chat on App'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      chatId: chatId,
                      otherUserId: finderUid,
                      itemId: itemId, docId: '', // ✅ pass itemId only
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      );
    },
  );
}

void _showTopNotification(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 60,
      left: MediaQuery.of(context).size.width * 0.1,
      right: MediaQuery.of(context).size.width * 0.1,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  Future.delayed(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}
