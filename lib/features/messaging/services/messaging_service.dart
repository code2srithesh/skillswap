import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class MessagingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _messagesCollection = 'messages';
  final String _conversationsCollection = 'conversations';

  Future<String> ensureConversationForRequest({
    required String requestId,
    required String requesterId,
    required String requesterName,
    required String postOwnerId,
    required String postOwnerName,
    String? postId,
  }) async {
    final conversationId = requestId;
    final conversationRef = _db
        .collection(_conversationsCollection)
        .doc(conversationId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(conversationRef);
      if (snap.exists) return;

      txn.set(conversationRef, {
        'id': conversationId,
        'swapId': requestId,
        'postId': postId,
        'participants': [requesterId, postOwnerId],
        'participantNames': {
          requesterId: requesterName,
          postOwnerId: postOwnerName,
        },
        'swapStatus': 'accepted',
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': null,
        'unread': {requesterId: 0, postOwnerId: 0},
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    return conversationId;
  }

  Stream<List<MessageModel>> getMessagesByConversationId(
    String conversationId,
  ) {
    return _db
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data()))
              .toList();
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages;
        });
  }

  Future<void> sendMessageToConversation({
    required String conversationId,
    required String message,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw "User not logged in";

    final conversationRef = _db
        .collection(_conversationsCollection)
        .doc(conversationId);
    final messageRef = _db.collection(_messagesCollection).doc();

    await _db.runTransaction((txn) async {
      final conversationSnap = await txn.get(conversationRef);
      if (!conversationSnap.exists) {
        throw 'Conversation not found';
      }

      final data = conversationSnap.data() as Map<String, dynamic>;
      final participantsRaw = data['participants'] as List?;
      final participants =
          participantsRaw?.map((e) => e.toString()).toList(growable: false) ??
          <String>[];

      if (!participants.contains(currentUser.uid)) {
        throw 'Not a participant';
      }

      final swapStatus = (data['swapStatus'] ?? 'accepted').toString();
      if (swapStatus != 'accepted' && swapStatus != 'completed') {
        throw 'Chat is not available for this swap yet';
      }

      // Once chat starts for an accepted swap, hide the related post from Discover.
      // This keeps the post visible only until someone actually starts messaging.
      String? postId;
      final postIdRaw = (data['postId'] ?? '').toString();
      if (postIdRaw.isNotEmpty) {
        postId = postIdRaw;
      } else {
        // Fallback for older conversation docs: infer from the request doc.
        final requestRef = _db.collection('requests').doc(conversationId);
        final requestSnap = await txn.get(requestRef);
        if (requestSnap.exists) {
          final requestData = requestSnap.data() as Map<String, dynamic>;
          final requestPostId = (requestData['postId'] ?? '').toString();
          if (requestPostId.isNotEmpty) postId = requestPostId;
        }
      }
      if (postId != null) {
        final postRef = _db.collection('posts').doc(postId);
        txn.set(postRef, {
          'isDiscoverable': false,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      final receiverId = participants.firstWhere(
        (id) => id != currentUser.uid,
        orElse: () => '',
      );
      if (receiverId.isEmpty) throw 'Invalid conversation participants';

      final participantNamesRaw = data['participantNames'] as Map?;
      final participantNames =
          participantNamesRaw?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          <String, String>{};

      final senderName = participantNames[currentUser.uid] ?? 'Unknown';

      final unreadRaw = data['unread'] as Map?;
      final unread =
          unreadRaw?.map(
            (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
          ) ??
          <String, int>{};
      unread[receiverId] = (unread[receiverId] ?? 0) + 1;

      txn.set(messageRef, {
        'id': messageRef.id,
        'conversationId': conversationId,
        'senderId': currentUser.uid,
        'senderName': senderName,
        'receiverId': receiverId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      txn.set(conversationRef, {
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unread': unread,
      }, SetOptions(merge: true));
    });
  }

  Future<void> markConversationRead(String conversationId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final ref = _db.collection(_conversationsCollection).doc(conversationId);
    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final unreadRaw = data['unread'] as Map?;
      final unread =
          unreadRaw?.map(
            (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
          ) ??
          <String, int>{};
      unread[currentUser.uid] = 0;
      txn.set(ref, {'unread': unread}, SetOptions(merge: true));
    });
  }

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
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data()))
              .toList();
          // Sort by timestamp descending (newest first)
          messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return messages;
        });
  }

  /// Get all conversations for current user (Real-time)
  Stream<List<ConversationModel>> getConversations() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return _db
        .collection(_conversationsCollection)
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs
              .map((doc) => ConversationModel.fromJson(doc.data()))
              .toList();
          // Sort by lastMessageTime descending
          conversations.sort((a, b) {
            return b.lastMessageTime.compareTo(a.lastMessageTime);
          });
          return conversations;
        });
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
