import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_app/api/model/user_model.dart';
import 'package:couple_app/module/chat/chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatelessWidget {
  final String currentUserRoomCode;

  ChatListPage({required this.currentUserRoomCode});

  @override
  Widget build(BuildContext context) {
    // Get the current user's ID
    final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Chats'),
       centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('roomCode', isEqualTo: currentUserRoomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs
              .where((doc) => doc.id != currentUserId)
              .map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return User(
              uid: doc.id,
              fullName: data['fullName'],
              profilePicUrl: data['photoProfile'] ??
                  'https://example.com/default_profile_pic.png',
              roomCode: data['roomCode'],
            );
          }).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, messageSnapshot) {
                  if (!messageSnapshot.hasData ||
                      messageSnapshot.data!.docs.isEmpty) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user.profilePicUrl),
                        radius: 25,
                      ),
                      title: Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'No messages yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        _navigateToChatPage(context, user, currentUserId);
                      },
                    );
                  }

                  var lastMessageDoc = messageSnapshot.data!.docs.first;
                  var lastMessage = lastMessageDoc['message'];
                  var timestamp = lastMessageDoc['timestamp'] as Timestamp;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.profilePicUrl),
                      radius: 25,
                    ),
                    title: Text(
                      user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      lastMessage,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('hh:mm a').format(timestamp.toDate()),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '1', // Placeholder for unread message count
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _navigateToChatPage(context, user, currentUserId);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToChatPage(
      BuildContext context, User user, String? currentUserId) {
    if (currentUserId != null && currentUserId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            user: user,
            currentUserId: currentUserId,
          ),
        ),
      );
    } else {
      // Handle case when currentUserId is null or empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to open chat. User not logged in."),
        ),
      );
    }
  }
}
