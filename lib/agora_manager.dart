import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

class AgoraManager {
  static const String appId = '1056fc6df2e9430784220439c5674eab'; // Replace with your Agora App ID
  static const String token = '007eJxTYHg3KytXR8451/Dur5nyFb2VD2rfZtcufGQemRG37dmXm9MUGAwNTM3Sks1S0oxSLU2MDcwtTIyMDEyMLZNNzcxNUhOTwk3OpjUEMjK0m+xhYIRCEJ+NITm/tCAnlYEBAP28IYE='; // Replace with your Agora Token
  static const String channelName = 'couple'; // Replace with your channel name

  late RtcEngine _engine;

  Future<void> initialize() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

   // Add an event handler
_engine.registerEventHandler(
    RtcEngineEventHandler(
    // Occurs when the local user joins the channel successfully
    onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint("local user ${connection.localUid} joined");
     
    },
    // Occurs when a remote user join the channel
    onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint("remote user $remoteUid joined");
   
      
    },
    // Occurs when a remote user leaves the channel
    onUserOffline: (RtcConnection connection, int remoteUid,
        UserOfflineReasonType reason) {
        debugPrint("remote user $remoteUid left channel");
      
    },
    ),
);

  }

  Future<void> joinChannel({required bool isVideo}) async {
    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: isVideo, // Set this to control video
        publishMicrophoneTrack: true, // Enable audio by default
      ),
      uid: 0,
    );
  }

  Future<void> leaveChannel() async {
    await _engine.leaveChannel();
  }

  void dispose() {
    _engine.release();
  }

  void muteMicrophone(bool isMuted) {}

  void toggleSpeaker(bool isSpeakerOn) {}
}
