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
  final String user1Id;
  final String user2Id;
  final String user1Name;
  final String user2Name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.user1Name,
    required this.user2Name,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'user1Name': user1Name,
      'user2Name': user2Name,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
    };
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? '',
      user1Id: json['user1Id'] ?? '',
      user2Id: json['user2Id'] ?? '',
      user1Name: json['user1Name'] ?? '',
      user2Name: json['user2Name'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime:
          (json['lastMessageTime'] as dynamic)?.toDate() ?? DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
