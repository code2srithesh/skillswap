import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../messaging/screens/chat_screen.dart';
import '../../messaging/services/messaging_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/premium_background.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/animations.dart';

class SwapsScreen extends StatefulWidget {
  const SwapsScreen({super.key});

  @override
  State<SwapsScreen> createState() => _SwapsScreenState();
}

class _SwapsScreenState extends State<SwapsScreen> {
  final _db = FirebaseFirestore.instance;
  final _messaging = MessagingService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _incomingPending() {
    return _db
        .collection('requests')
        .where('receiverUid', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _myActiveAndHistory() {
    return _db
        .collection('requests')
        .where('participants', arrayContains: _uid)
        .snapshots()
        .map((s) {
          final docs = s.docs.toList();
          docs.sort((a, b) {
            final aTs =
                (a.data()['updatedAt'] as dynamic)?.toDate() ??
                (a.data()['createdAt'] as dynamic)?.toDate() ??
                DateTime(1970);
            final bTs =
                (b.data()['updatedAt'] as dynamic)?.toDate() ??
                (b.data()['createdAt'] as dynamic)?.toDate() ??
                DateTime(1970);
            return bTs.compareTo(aTs);
          });
          return docs;
        });
  }

  Future<void> _acceptRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final senderUid = (data['senderUid'] ?? data['requesterId'] ?? '')
        .toString();
    final receiverUid = (data['receiverUid'] ?? data['postOwnerId'] ?? '')
        .toString();
    final requesterName =
        (data['requesterName'] ?? data['senderName'] ?? 'Student').toString();
    final postOwnerName = (data['postOwnerName'] ?? 'Student').toString();
    final postId = (data['postId'] as String?);

    await doc.reference.update({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
      'participants': [senderUid, receiverUid],
      'requesterId': senderUid,
      'postOwnerId': receiverUid,
      'requesterName': requesterName,
      'postOwnerName': postOwnerName,
    });

    final conversationId = await _messaging.ensureConversationForRequest(
      requestId: doc.id,
      requesterId: senderUid,
      requesterName: requesterName,
      postOwnerId: receiverUid,
      postOwnerName: postOwnerName,
      postId: postId,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          fallbackOtherUserId: senderUid == _uid ? receiverUid : senderUid,
          fallbackOtherUserName: senderUid == _uid
              ? postOwnerName
              : requesterName,
        ),
      ),
    );
  }

  Future<void> _rejectRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await doc.reference.update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _openChat(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final senderUid = (data['senderUid'] ?? data['requesterId'] ?? '')
        .toString();
    final receiverUid = (data['receiverUid'] ?? data['postOwnerId'] ?? '')
        .toString();

    final requesterName =
        (data['requesterName'] ?? data['senderName'] ?? 'Student').toString();
    final postOwnerName = (data['postOwnerName'] ?? 'Student').toString();
    final postId = (data['postId'] as String?);

    final conversationId = await _messaging.ensureConversationForRequest(
      requestId: doc.id,
      requesterId: senderUid,
      requesterName: requesterName,
      postOwnerId: receiverUid,
      postOwnerName: postOwnerName,
      postId: postId,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          fallbackOtherUserId: senderUid == _uid ? receiverUid : senderUid,
          fallbackOtherUserName: senderUid == _uid
              ? postOwnerName
              : requesterName,
        ),
      ),
    );
  }

  Future<void> _markCompleted(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await doc.reference.update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('conversations').doc(doc.id).set({
      'swapStatus': 'completed',
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: PremiumBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              'My Swaps',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: TabBar(
              dividerColor: Colors.transparent,
              indicatorColor: AppTheme.primaryColor,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade400,
              tabs: const [
                Tab(text: 'Incoming'),
                Tab(text: 'Active & History'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // Incoming
              StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                stream: _incomingPending(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Unable to load requests', style: GoogleFonts.inter(color: Colors.white)));
                  }

                  final docs = snapshot.data ?? [];
                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No pending requests',
                        style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 15),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final requesterName =
                          (data['requesterName'] ??
                                  data['senderName'] ??
                                  'Student')
                              .toString();
                      final message = (data['message'] ?? '').toString();

                      return StaggeredItem(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                PremiumAvatar(name: requesterName, size: 44),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        requesterName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message.isEmpty ? 'No message' : message,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BouncyTap(
                                      onTap: () => _rejectRequest(doc),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    BouncyTap(
                                      onTap: () => _acceptRequest(doc),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
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

              // Active & History
              StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                stream: _myActiveAndHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Unable to load swaps', style: GoogleFonts.inter(color: Colors.white)));
                  }

                  final all = snapshot.data ?? [];
                  final docs = all.where((d) {
                    final s = (d.data()['status'] ?? 'pending').toString();
                    return s == 'accepted' || s == 'completed' || s == 'rejected';
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No active swaps yet',
                        style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 15),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final status = (data['status'] ?? 'pending').toString();

                      final senderUid =
                          (data['senderUid'] ?? data['requesterId'] ?? '')
                              .toString();

                      final requesterName =
                          (data['requesterName'] ??
                                  data['senderName'] ??
                                  'Student')
                              .toString();
                      final postOwnerName = (data['postOwnerName'] ?? 'Student')
                          .toString();

                      final otherName = senderUid == _uid
                          ? postOwnerName
                          : requesterName;
                      final message = (data['message'] ?? '').toString();

                      Color chipBg;
                      Color chipFg;
                      if (status == 'accepted') {
                        chipBg = Colors.green.withOpacity(0.15);
                        chipFg = Colors.green.shade400;
                      } else if (status == 'completed') {
                        chipBg = Colors.blue.withOpacity(0.15);
                        chipFg = Colors.blue.shade400;
                      } else {
                        chipBg = Colors.red.withOpacity(0.15);
                        chipFg = Colors.red.shade400;
                      }

                      return StaggeredItem(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                PremiumAvatar(name: otherName, size: 44),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              otherName,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: chipBg,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: chipFg.withOpacity(0.2)),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: chipFg,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message.isEmpty ? '—' : message,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BouncyTap(
                                      onTap: () => _openChat(doc),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chat_bubble_rounded,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    if (status == 'accepted') ...[
                                      const SizedBox(width: 10),
                                      BouncyTap(
                                        onTap: () => _markCompleted(doc),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.verified_rounded,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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
            ],
          ),
        ),
      ),
    );
  }
}
