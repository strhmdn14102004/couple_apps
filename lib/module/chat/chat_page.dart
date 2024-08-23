import 'package:couple_app/api/model/user_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final User user;
  final String currentUserId;

  ChatPage({required this.user, required this.currentUserId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('messages')
          .add({
        'senderId': widget.currentUserId,
        'receiverId': widget.user.uid,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId)
          .collection('messages')
          .add({
        'senderId': widget.currentUserId,
        'receiverId': widget.user.uid,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': true,
      });

      _messageController.clear();
    }
  }

  void _showMessageOptions(BuildContext context, DocumentSnapshot messageDoc) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(messageDoc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editMessage(messageDoc);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteMessage(DocumentSnapshot messageDoc) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('messages')
        .doc(messageDoc.id)
        .delete();
  }

  void _editMessage(DocumentSnapshot messageDoc) {
    var messageData = messageDoc.data() as Map<String, dynamic>;
    _messageController.text = messageData['message'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Pesan'),
          content: TextField(
            controller: _messageController,
            decoration: const InputDecoration(hintText: 'Edit your message'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.currentUserId)
                    .collection('messages')
                    .doc(messageDoc.id)
                    .update({'message': _messageController.text});
                _messageController.clear();
                Navigator.pop(context);
              },
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _chatMessagesStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.user.profilePicUrl),
            ),
            const SizedBox(width: 10),
            Text(widget.user.fullName),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatMessagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index].data() as Map<String, dynamic>;
                    bool isSentByCurrentUser =
                        message['senderId'] == widget.currentUserId;

                    return GestureDetector(
                      onLongPress: () {
                        // Show options only for messages sent by the current user
                        if (isSentByCurrentUser) {
                          _showMessageOptions(context, messages[index]);
                        }
                      },
                      child: Align(
                        alignment: isSentByCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4.0,
                            horizontal: 8.0,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 14.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSentByCurrentUser
                                ? Colors.teal[500]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(8),
                              topRight: const Radius.circular(8),
                              bottomLeft: isSentByCurrentUser
                                  ? const Radius.circular(8)
                                  : const Radius.circular(0),
                              bottomRight: isSentByCurrentUser
                                  ? const Radius.circular(0)
                                  : const Radius.circular(8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['message'],
                                style: TextStyle(
                                  color: isSentByCurrentUser
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                DateFormat('hh:mm a').format(
                                  (message['timestamp'] as Timestamp?)
                                          ?.toDate() ??
                                      DateTime.now(),
                                ),
                                style: TextStyle(
                                  color: isSentByCurrentUser
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
