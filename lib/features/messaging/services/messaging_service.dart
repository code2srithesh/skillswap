import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class MessagingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _messagesCollection = 'messages';
  final String _conversationsCollection = 'conversations';

  /// Create or get conversation ID from two user IDs
  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  /// Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String receiverName,
    required String message,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw "User not logged in";

    final conversationId = _getConversationId(currentUser.uid, receiverId);
    final messageId = _db.collection(_messagesCollection).doc().id;
    final timestamp = DateTime.now();

    // Get sender name
    final senderDoc = await _db.collection('users').doc(currentUser.uid).get();
    final senderName = senderDoc['name'] ?? 'Unknown';

    // Add message
    await _db.collection(_messagesCollection).doc(messageId).set({
      'id': messageId,
      'conversationId': conversationId,
      'senderId': currentUser.uid,
      'senderName': senderName,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Update conversation
    final userIds = [currentUser.uid, receiverId]..sort();
    await _db.collection(_conversationsCollection).doc(conversationId).set({
      'id': conversationId,
      'participants': [currentUser.uid, receiverId],
      'user1Id': userIds[0],
      'user2Id': userIds[1],
      'user1Name': currentUser.uid == userIds[0] ? senderName : receiverName,
      'user2Name': receiverId == userIds[1] ? receiverName : senderName,
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUser.uid,
    }, SetOptions(merge: true));
  }

  /// Get messages for a conversation (Real-time)
  Stream<List<MessageModel>> getMessages(String otherUserId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final conversationId = _getConversationId(currentUserId, otherUserId);

    return _db
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Get all conversations for current user (Real-time)
  Stream<List<ConversationModel>> getConversations() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return _db
        .collection(_conversationsCollection)
        .where(
          Filter.or(
            Filter('user1Id', isEqualTo: currentUserId),
            Filter('user2Id', isEqualTo: currentUserId),
          ),
        )
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ConversationModel.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    await _db.collection(_messagesCollection).doc(messageId).update({
      'isRead': true,
    });
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    // Delete all messages in conversation
    final messages = await _db
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .get();

    for (var msg in messages.docs) {
      await msg.reference.delete();
    }

    // Delete conversation
    await _db.collection(_conversationsCollection).doc(conversationId).delete();
  }

  /// Get or create conversation after swap
  Future<void> initiateConversation({
    required String otherUserId,
    required String otherUserName,
    required String initialMessage,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw "User not logged in";

    final conversationId = _getConversationId(currentUser.uid, otherUserId);

    // Get current user name
    final userDoc = await _db.collection('users').doc(currentUser.uid).get();
    final currentUserName = userDoc['name'] ?? 'Unknown';

    // Create conversation record
    await _db.collection(_conversationsCollection).doc(conversationId).set({
      'id': conversationId,
      'participants': [currentUser.uid, otherUserId],
      'user1Id': currentUser.uid,
      'user2Id': otherUserId,
      'user1Name': currentUserName,
      'user2Name': otherUserName,
      'lastMessage': initialMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUser.uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Send initial message
    if (initialMessage.isNotEmpty) {
      await sendMessage(
        receiverId: otherUserId,
        receiverName: otherUserName,
        message: initialMessage,
      );
    }
  }
}
