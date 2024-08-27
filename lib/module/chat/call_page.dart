import 'package:couple_app/agora_manager.dart';
import 'package:couple_app/api/model/user_model.dart';
import 'package:flutter/material.dart';

class CallPage extends StatefulWidget {
  final bool isVideoCall;
  final User user;

  CallPage({
    required this.isVideoCall,
    required this.user,
  });

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final AgoraManager _agoraManager = AgoraManager();
  bool isMuted = false;
  bool isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _agoraManager.initialize().then((_) {
      _agoraManager.joinChannel(isVideo: widget.isVideoCall);
    });
  }

  @override
  void dispose() {
    _agoraManager.leaveChannel();
    _agoraManager.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      isMuted = !isMuted;
    });
    _agoraManager.muteMicrophone(isMuted);
  }

  void _toggleSpeaker() {
    setState(() {
      isSpeakerOn = !isSpeakerOn;
    });
    _agoraManager.toggleSpeaker(isSpeakerOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.isVideoCall ? 'Video Call' : 'Voice Call'),
        actions: [
          IconButton(
            icon: Icon(isSpeakerOn ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleSpeaker,
          ),
          IconButton(
            icon: Icon(isMuted ? Icons.mic_off : Icons.mic),
            onPressed: _toggleMute,
          ),
          if (widget.isVideoCall)
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () {
                // Implement video toggle logic if necessary
              },
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(widget.user.profilePicUrl),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.user.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.isVideoCall ? 'Video Call' : 'Voice Call',
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "angkat",
                  onPressed: () {
                    // Implement answer logic here
                    print('Call answered');
                  },
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.call, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: "telpon",
                  onPressed: () {
                    // Implement hang up logic here
                    _agoraManager.leaveChannel();
                    Navigator.of(context).pop();
                  },
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
