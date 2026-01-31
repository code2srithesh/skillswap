import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../messaging/screens/chat_screen.dart';
import '../../../core/theme.dart';
import '../../../core/animations.dart';
import '../../../core/widgets/glass_card.dart';

class MySwapsScreen extends StatefulWidget {
  const MySwapsScreen({super.key});

  @override
  State<MySwapsScreen> createState() => _MySwapsScreenState();
}

class _MySwapsScreenState extends State<MySwapsScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  /// Fetch accepted swaps where current user is either sender or receiver
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _getAcceptedSwaps() {
    return _db
        .collection('requests')
        .where('participants', arrayContains: _uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.toList();
          // Sort by most recent first
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

  /// Get the name of the other person in the swap
  String _getOtherPersonName(Map<String, dynamic> swapData) {
    final senderUid = swapData['senderUid'] ?? swapData['requesterId'] ?? '';
    final senderName =
        swapData['requesterName'] ?? swapData['senderName'] ?? 'Student';
    final receiverName = swapData['postOwnerName'] ?? 'Student';

    if (senderUid == _uid) {
      return receiverName.toString();
    } else {
      return senderName.toString();
    }
  }

  /// Get the skill being taught in this swap
  String _getTeachSkill(Map<String, dynamic> swapData) {
    return swapData['teachSkill'] ?? 'Skill Exchange';
  }

  /// Get the skill being learned in this swap
  String _getLearnSkill(Map<String, dynamic> swapData) {
    return swapData['learnSkill'] ?? 'Unknown Skill';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "My Swaps",
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            stream: _getAcceptedSwaps(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: ShimmerAnimation(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade100,
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: 40,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load swaps',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection',
                        style: GoogleFonts.inter(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.handshake_outlined,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Swaps Yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by requesting a skill or waiting for\naccept requests',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final swaps = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: swaps.length,
                itemBuilder: (context, index) {
                  final swapDoc = swaps[index];
                  final swapData = swapDoc.data();

                  return FadeInUpAnimation(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    child: _buildSwapCard(
                      context,
                      swapDoc.id,
                      swapData,
                      isDark,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build individual swap card
  Widget _buildSwapCard(
    BuildContext context,
    String swapId,
    Map<String, dynamic> swapData,
    bool isDark,
  ) {
    final senderUid = swapData['senderUid'] ?? swapData['requesterId'] ?? '';
    final otherPersonName = _getOtherPersonName(swapData);
    final teachSkill = _getTeachSkill(swapData);
    final learnSkill = _getLearnSkill(swapData);

    // Determine if current user is teacher or learner
    final isCurrentUserTeacher = senderUid == _uid;
    final displayTeachSkill = isCurrentUserTeacher ? teachSkill : learnSkill;
    final displayLearnSkill = isCurrentUserTeacher ? learnSkill : teachSkill;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: () {
          // Navigate to chat screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: swapData['conversationId'] ?? swapId,
                fallbackOtherUserName: otherPersonName,
                fallbackOtherUserId: senderUid == _uid
                    ? swapData['receiverUid'] ?? swapData['postOwnerId'] ?? ''
                    : senderUid,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with other person's name
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.accentGradientBrush,
                    ),
                    child: Center(
                      child: Text(
                        otherPersonName.isNotEmpty
                            ? otherPersonName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherPersonName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Swap accepted',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.message_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Skills being exchanged
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You teach: $displayTeachSkill',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          size: 16,
                          color: Colors.amber.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You learn: $displayLearnSkill',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
