// Models for video call / meeting APIs

class MeetingInfo {
  final String meetingId;
  final String channelName;
  final String token;
  final int uid;
  final String appId;
  final String role;
  final String userName;

  MeetingInfo({
    required this.meetingId,
    required this.channelName,
    required this.token,
    required this.uid,
    required this.appId,
    required this.role,
    required this.userName,
  });

  factory MeetingInfo.fromJson(Map<String, dynamic> json) {
    final meetingId = json['meetingId'] ?? json['meeting_id'] ?? '';
    final channelName = json['channelName'] ?? json['channel_name'] ?? '';
    final token = json['token'] ?? '';
    final uidRaw = json['uid'];
    int uid = 0;
    if (uidRaw is int) {
      uid = uidRaw;
    } else if (uidRaw is String) {
      uid = int.tryParse(uidRaw) ?? 0;
    }
    final appId = json['appId'] ?? json['app_id'] ?? '';
    final role = json['role'] ?? '';
    final userName = json['user_name'] ?? json['userName'] ?? '';

    return MeetingInfo(
      meetingId: meetingId as String,
      channelName: channelName as String,
      token: token as String,
      uid: uid,
      appId: appId as String,
      role: role as String,
      userName: userName as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'meetingId': meetingId,
        'channelName': channelName,
        'token': token,
        'uid': uid,
        'appId': appId,
        'role': role,
        'user_name': userName,
      };
}

class RecordingInfo {
  final String resourceId;
  final String sid;

  RecordingInfo({required this.resourceId, required this.sid});

  factory RecordingInfo.fromJson(Map<String, dynamic> json) {
    final resourceId = json['resourceId'] ?? json['resource_id'] ?? '';
    final sid = json['sid'] ?? '';
    return RecordingInfo(
      resourceId: resourceId as String,
      sid: sid as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'resourceId': resourceId,
        'sid': sid,
      };
}

