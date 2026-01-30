import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../messaging/screens/chat_screen.dart';
import '../../messaging/services/messaging_service.dart';
import '../../../core/theme.dart';

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
    // Avoid OR queries: query by participants and filter client-side.
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
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        appBar: AppBar(
          title: Text(
            'My Swaps',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Unable to load requests'));
                }

                final docs = snapshot.data ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No pending requests',
                      style: GoogleFonts.inter(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
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

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        title: Text(
                          requesterName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          message.isEmpty ? 'No message' : message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.red,
                              ),
                              onPressed: () => _rejectRequest(doc),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.check_rounded,
                                color: Colors.green,
                              ),
                              onPressed: () => _acceptRequest(doc),
                            ),
                          ],
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Unable to load swaps'));
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
                      style: GoogleFonts.inter(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
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
                      chipBg = Colors.green.shade100;
                      chipFg = Colors.green.shade800;
                    } else if (status == 'completed') {
                      chipBg = Colors.blue.shade100;
                      chipFg = Colors.blue.shade800;
                    } else {
                      chipBg = Colors.red.shade100;
                      chipFg = Colors.red.shade800;
                    }

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                otherName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: chipFg,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          message.isEmpty ? '—' : message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_rounded),
                              onPressed: () => _openChat(doc),
                            ),
                            if (status == 'accepted')
                              IconButton(
                                icon: const Icon(Icons.verified_rounded),
                                onPressed: () => _markCompleted(doc),
                                tooltip: 'Mark completed',
                              ),
                          ],
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
    );
  }
}
