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
        title: const Text('Chat Bubbles'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            onPressed: () => _showNewChatDialog(context, currentUserId),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var conversations = snapshot.data!.docs;

          if (conversations.isEmpty) {
            return const Center(child: Text('Belum ada chat yang tersedia'));
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              var conversation = conversations[index];
              var participants =
                  List<String>.from(conversation['participants']);
              var otherUserId =
                  participants.firstWhere((id) => id != currentUserId);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  var user = User(
                    uid: userSnapshot.data!.id,
                    fullName: userSnapshot.data!['fullName'],
                    profilePicUrl: userSnapshot.data!['photoProfile'] ??
                        'https://example.com/default_profile_pic.png',
                    roomCode: userSnapshot.data!['roomCode'],
                  );

                  var lastMessage =
                      conversation['lastMessage'] ?? 'Belum ada pesan';
                  var timestamp =
                      conversation['lastMessageTimestamp'] as Timestamp?;
                  var formattedTimestamp = timestamp != null
                      ? DateFormat('hh:mm a').format(timestamp.toDate())
                      : '';

                  var unreadCount =
                      conversation['unreadCount'][currentUserId] ?? 0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.profilePicUrl),
                      radius: 25,
                    ),
                    title: Text(
                      user.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    subtitle: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('conversations')
                          .doc(conversation.id)
                          .get(),
                      builder: (context, conversationSnapshot) {
                        if (!conversationSnapshot.hasData) {
                          return const Text('Loading...');
                        }

                        var isTyping = conversationSnapshot
                                .data!['typingStatus'][otherUserId] ??
                            false;
                        var lastMessage = isTyping
                            ? 'Sedang mengetik...'
                            : conversation['lastMessage'] ?? 'Belum ada pesan';

                        return Text(
                          lastMessage,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
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
                    onTap: () {
                      _navigateToChatPage(
                        context,
                        user,
                        currentUserId!,
                        conversation.id,
                      );
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

  void _showNewChatDialog(BuildContext context, String? currentUserId) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Mulai Percakapan Dengan",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .where('roomCode', isEqualTo: currentUserRoomCode)
                      .get(),
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

                    return users.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: Text(
                              "Tidak ada teman untuk di chat",
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              var user = users[index];
                              return Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(user.profilePicUrl),
                                      radius: 30,
                                    ),
                                    title: Text(user.fullName),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _startNewChat(
                                          context, user, currentUserId!);
                                    },
                                  ),
                                  if (index < users.length - 1) const Divider(),
                                ],
                              );
                            },
                          );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startNewChat(
      BuildContext context, User user, String currentUserId) async {
    var conversationRef =
        FirebaseFirestore.instance.collection('conversations').doc();

    await conversationRef.set({
      'participants': [currentUserId, user.uid],
      'lastMessage': '',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadCount': {currentUserId: 0, user.uid: 0},
    });

    _navigateToChatPage(context, user, currentUserId, conversationRef.id);
  }

  void _navigateToChatPage(
      BuildContext context, User user, String currentUserId, String chatId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatPage(user: user, currentUserId: currentUserId, chatId: chatId),
      ),
    );
  }
}
