import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:couple_app/api/model/user_model.dart';
import 'package:couple_app/module/chat/call_page.dart';
import 'package:couple_app/module/chat/user_details_page.dart';
import 'package:couple_app/overlay/overlays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Import Slidable
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final User user;
  final String chatId;
  final String currentUserId;

  ChatPage({
    required this.user,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final messageData = {
        'senderId': widget.currentUserId,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      final chatDocRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.chatId);

      // Add new message to the 'messages' subcollection
      await chatDocRef.collection('messages').add(messageData);

      // Update lastMessage and lastMessageTimestamp
      await chatDocRef.update({
        'lastMessage': _messageController.text,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'unreadCount.${widget.user.uid}': FieldValue.increment(1),
      });

      _messageController.clear();
      _updateTypingStatus(false);
    }
  }

  void _onMessageChanged(String value) {
    if (!_isTyping && value.isNotEmpty) {
      setState(() {
        _isTyping = true;
      });
      _updateTypingStatus(true);
    } else if (_isTyping && value.isEmpty) {
      setState(() {
        _isTyping = false;
      });
      _updateTypingStatus(false);
    }
  }

  void _onMessageSubmitted(String value) {
    setState(() {
      _isTyping = false;
    });
    _updateTypingStatus(false);
    _sendMessage();
  }

  void _updateTypingStatus(bool isTyping) async {
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.chatId)
        .update({
      'typingStatus.${widget.currentUserId}': isTyping,
    });
  }

  Stream<QuerySnapshot> _chatMessagesStream() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void _markMessageAsRead(String messageId) async {
    final chatDocRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId);

    // Update the isRead field to true
    await chatDocRef.update({'isRead': true});

    // Mengurangi unreadCount setelah pesan dibaca
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.chatId)
        .update({
      'unreadCount.${widget.currentUserId}':
          FieldValue.increment(-1), // Kurangi count
    });
  }

  void _editMessage(String messageId, String currentMessage) {
    TextEditingController editController =
        TextEditingController(text: currentMessage);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pesan'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            hintText: 'Masukan Pesan',
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              String updatedMessage = editController.text.trim();
              if (updatedMessage.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('conversations')
                    .doc(widget.chatId)
                    .collection('messages')
                    .doc(messageId)
                    .update({'message': updatedMessage, 'edited': true});

                // Optionally update 'lastMessage' if this is the last message
                final chatDocRef = FirebaseFirestore.instance
                    .collection('conversations')
                    .doc(widget.chatId);
                final lastMessageSnapshot = await chatDocRef
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get();
                if (lastMessageSnapshot.docs.isNotEmpty &&
                    lastMessageSnapshot.docs.first.id == messageId) {
                  await chatDocRef.update({
                    'lastMessage': updatedMessage,
                    'lastMessageTimestamp': FieldValue.serverTimestamp(),
                  });
                }

                Navigator.of(context).pop(); // Close the dialog
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(String messageId) async {
    // Optional: Show a confirmation dialog
    bool confirm = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pesan'),
        content: const Text('Apakah kamu yakin akan menghapus pesan ini?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              confirm = true;
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Optionally update 'lastMessage' if this was the last message
      final chatDocRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(widget.chatId);
      final lastMessageSnapshot = await chatDocRef
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (lastMessageSnapshot.docs.isNotEmpty) {
        final lastMessage = lastMessageSnapshot.docs.first.data();
        await chatDocRef.update({
          'lastMessage': lastMessage['message'],
          'lastMessageTimestamp': lastMessage['timestamp'],
        });
      } else {
        // If no messages left, clear lastMessage fields
        await chatDocRef.update({
          'lastMessage': null,
          'lastMessageTimestamp': null,
          'unreadCount.${widget.user.uid}': 0,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UserDetailsPage(userId: widget.user.uid),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.user.profilePicUrl),
              ),
            ),
            const SizedBox(width: 10),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(widget.chatId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  var typingStatus = data['typingStatus'] ?? {};
                  bool isUserTyping = typingStatus.entries.any((entry) =>
                      entry.key != widget.currentUserId && entry.value == true);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.fullName),
                      if (isUserTyping)
                        const Text(
                          'sedang mengetik...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  );
                }
                return Text(widget.user.fullName);
              },
            ),
            const Spacer(),
           IconButton(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CallPage(
          isVideoCall: false,
          user: widget.user,
        ),
      ),
    );
  },
  icon: const Icon(Icons.call),
),

            IconButton(
              onPressed: () {
                Overlays.comming(
                  message:
                      "Sabar ya, featurenya lagi dibuat nih sama sasat dengan sepenuh rasa cinta hehe.",
                );
              },
              icon: const Icon(Icons.video_call),
            ),
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
                    var messageData =
                        messages[index].data() as Map<String, dynamic>;
                    String messageId = messages[index].id;
                    bool isSentByCurrentUser =
                        messageData['senderId'] == widget.currentUserId;
                    bool isRead = messageData['isRead'] ?? false;

                    if (!isSentByCurrentUser && !isRead) {
                      _markMessageAsRead(messageId);
                    }

                    return Slidable(
                      key: Key(messageId),
                      startActionPane: isSentByCurrentUser
                          ? ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    _deleteMessage(messageId);
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Delete',
                                ),
                              ],
                            )
                          : null,
                      endActionPane: isSentByCurrentUser
                          ? ActionPane(
                              motion: const ScrollMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    _editMessage(messageId,
                                        messageData['message'] ?? '');
                                  },
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: 'Edit',
                                ),
                              ],
                            )
                          : null,
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
                                messageData['message'],
                                style: TextStyle(
                                  color: isSentByCurrentUser
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    messageData['timestamp'] != null
                                        ? DateFormat('hh:mm a').format(
                                            (messageData['timestamp']
                                                    as Timestamp)
                                                .toDate(),
                                          )
                                        : DateFormat('hh:mm a').format(
                                            DateTime.now(),
                                          ),
                                    style: TextStyle(
                                      color: isSentByCurrentUser
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  if (isSentByCurrentUser)
                                    Text(
                                      messageData['edited'] == true
                                          ? '(Edited)'
                                          : '',
                                      style: TextStyle(
                                        color: isSentByCurrentUser
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              if (isSentByCurrentUser)
                                Text(
                                  isRead ? 'Dibaca' : 'Terkirim/Belum Dibaca',
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
                    onChanged: _onMessageChanged,
                    onSubmitted: _onMessageSubmitted,
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik Pesan',
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
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
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
