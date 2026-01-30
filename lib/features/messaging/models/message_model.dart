class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      receiverId: json['receiverId'] ?? '',
      message: json['message'] ?? '',
      timestamp: (json['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? swapId;
  final String? postId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unread;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.swapId,
    this.postId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unread = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'swapId': swapId,
      'postId': postId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unread': unread,
    };
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final participantsRaw = json['participants'];
    final participants = participantsRaw is List
        ? participantsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final participantNamesRaw = json['participantNames'];
    final participantNames = participantNamesRaw is Map
        ? participantNamesRaw.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          )
        : <String, String>{};

    // Backward compatibility for old schema (user1Id/user2Id)
    final user1Id = (json['user1Id'] ?? '').toString();
    final user2Id = (json['user2Id'] ?? '').toString();
    if (participants.isEmpty && user1Id.isNotEmpty && user2Id.isNotEmpty) {
      participants.addAll([user1Id, user2Id]);
    }
    if (participantNames.isEmpty) {
      final user1Name = (json['user1Name'] ?? '').toString();
      final user2Name = (json['user2Name'] ?? '').toString();
      if (user1Id.isNotEmpty && user1Name.isNotEmpty) {
        participantNames[user1Id] = user1Name;
      }
      if (user2Id.isNotEmpty && user2Name.isNotEmpty) {
        participantNames[user2Id] = user2Name;
      }
    }

    final unreadRaw = json['unread'];
    final unread = unreadRaw is Map
        ? unreadRaw.map(
            (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
          )
        : <String, int>{};

    return ConversationModel(
      id: json['id'] ?? '',
      participants: participants,
      participantNames: participantNames,
      swapId: json['swapId']?.toString(),
      postId: json['postId']?.toString(),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime:
          (json['lastMessageTime'] as dynamic)?.toDate() ?? DateTime.now(),
      unread: unread,
    );
  }

  String otherUserId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String otherUserName(String currentUserId) {
    final otherId = otherUserId(currentUserId);
    return participantNames[otherId] ?? 'User';
  }

  int unreadCountFor(String currentUserId) {
    // unread map stores *unread messages for that user*
    return unread[currentUserId] ?? 0;
  }
}
