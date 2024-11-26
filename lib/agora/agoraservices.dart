import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctor_doom/agora/apiwork.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static RtcEngine? _engine;
  static const String appId = "2f3131394cc6417b91aa93cfde567a37";
  static int? _remoteUid;
  static String roomName = "";

  static Future<bool> checkPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    return cameraStatus.isGranted && micStatus.isGranted;
  }

  static Future<void> initializeAgora() async {
    try {
      _engine = await createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      await _engine!.enableVideo();
      await _engine!.startPreview();

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print("Local user ${connection.localUid} joined channel");
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print("Remote user $remoteUid joined channel");
            _remoteUid = remoteUid;
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            print("Remote user $remoteUid left channel");
            _remoteUid = null;
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            print("Left channel with stats: $stats");
          },
        ),
      );
    } catch (e) {
      print("Error initializing Agora: $e");
      rethrow;
    }
  }

  static Future<void> joinChannel(String roomName, String username) async {
    if (_engine == null) {
      print("Error: _engine is not initialized.");
      throw Exception("Engine not initialized");
    }

    try {
      await createMember(username, 0, roomName);
      Map<String, dynamic>? tokendata = await fetchAgoraToken(roomName);

      if (tokendata == null) {
        throw Exception("Token generation failed");
      }

      await _engine!.joinChannel(
        token: tokendata['token'],
        channelId: roomName,
        uid: tokendata['uid'],
        options: ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );
    } catch (e) {
      print("Error joining channel: $e");
    }
  }

  static Future<void> leaveChannel(String roomName, String username) async {
    if (_engine == null) {
      print("Error: _engine is not initialized.");
      throw Exception("Engine not initialized");
    }

    try {
      await leaveMeeting(username, 0, roomName);
      await _engine!.leaveChannel();
    } catch (e) {
      print("Error leaving channel: $e");
    }
  }

  static Future<void> muteLocalAudio(bool mute) async {
    if (_engine == null) {
      print("Error: _engine is not initialized.");
      return;
    }
    try {
      await _engine!.muteLocalAudioStream(mute);
    } catch (e) {
      print("Error muting audio: $e");
    }
  }

  static Future<void> muteLocalVideo(bool mute) async {
    if (_engine != null) {
      await _engine!.muteLocalVideoStream(mute);
      if (!mute) {
        await _engine!
            .startPreview(); // Ensure preview restarts when video is unmuted
      }
    }
  }

  static Widget localVideo() {
    if (_engine != null) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }

  static Widget remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: roomName),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }

  static Future<void> dispose() async {
    if (_engine == null) {
      print("Error: _engine is not initialized.");
      return;
    }

    try {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    } catch (e) {
      print("Error during dispose: $e");
    }
  }
}
