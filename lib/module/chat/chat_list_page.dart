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
    final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Chats  (BETA)'),
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
                        'tidak ada pesan tersedia',
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

                  var messages = messageSnapshot.data!.docs;

                  // Ensure isRead field exists or default to false
                  var unreadCount = messages
                      .where((doc) =>
                          (doc.data() as Map<String, dynamic>)['isRead'] ??
                          false == false && doc['receiverId'] == currentUserId)
                      .length;

                  var lastMessageDoc = messages.first;
                  var lastMessage = lastMessageDoc['message'];

                  // Check for null timestamp
                  var timestamp = lastMessageDoc['timestamp'];
                  var formattedTimestamp =
                      timestamp != null && timestamp is Timestamp
                          ? DateFormat('hh:mm a').format(timestamp.toDate())
                          : 'No time'; // Default or handle null timestamp

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
                          formattedTimestamp,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (unreadCount > 0)
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.red,
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      await _markMessagesAsRead(user.uid, currentUserId!);
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

  Future<void> _markMessagesAsRead(String userId, String currentUserId) async {
    final messageCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('messages');

    final unreadMessages = await messageCollection
        .where('isRead', isEqualTo: false)
        .where('receiverId', isEqualTo: currentUserId)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  void _navigateToChatPage(
      BuildContext context, User user, String? currentUserId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatPage(user: user, currentUserId: currentUserId!),
      ),
    );
  }
}
