import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../messaging/screens/chat_screen.dart';
import '../../messaging/services/messaging_service.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/premium_background.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;
  final _messaging = MessagingService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _getPendingRequests() {
    return _db
        .collection('requests')
        .where('receiverUid', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs);
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getMatches() {
    return _db
        .collection('requests')
        .where('participants', arrayContains: _uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.toList();
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request accepted! You can now chat with $requesterName'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Chat',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: conversationId,
                  fallbackOtherUserId: senderUid,
                  fallbackOtherUserName: requesterName,
                ),
              ),
            );
          },
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

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Request rejected'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Premium Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: AppTheme.accentGradientBrush,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.inbox_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Requests'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.handshake_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Matches'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: [_buildRequestsTab(isDark), _buildMatchesTab(isDark)],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab(bool isDark) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _getPendingRequests(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 2,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState('Unable to load requests');
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return _buildEmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'All Caught Up!',
                subtitle: 'No pending requests',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final requestDoc = requests[index];
                final data = requestDoc.data();
                return StaggeredItem(
                  index: index,
                  child: _buildRequestCard(requestDoc, data, isDark),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> data,
    bool isDark,
  ) {
    final requesterName =
        data['requesterName'] ?? data['senderName'] ?? 'Student';
    final teachSkill = data['teachSkill'] ?? 'Skill';
    final learnSkill = data['learnSkill'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: PremiumCard(
        hasGlow: true,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PremiumAvatar(name: requesterName, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requesterName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber.shade400,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Wants to swap skills',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Skills info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    const Color(0xFF8B5CF6).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildSkillRow(
                    Icons.school_rounded,
                    'They teach',
                    teachSkill,
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 10),
                  _buildSkillRow(
                    Icons.lightbulb_rounded,
                    'You teach',
                    learnSkill,
                    Colors.amber.shade600,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: BouncyTap(
                    onTap: () => _acceptRequest(doc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Accept',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BouncyTap(
                    onTap: () => _rejectRequest(doc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Decline',
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillRow(
    IconData icon,
    String label,
    String skill,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
        ),
        Expanded(
          child: Text(
            skill,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesTab(bool isDark) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
          stream: _getMatches(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: 2,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState('Unable to load matches');
            }

            final matches = snapshot.data ?? [];

            if (matches.isEmpty) {
              return _buildEmptyState(
                icon: Icons.handshake_outlined,
                title: 'No Matches Yet',
                subtitle: 'Accept requests to start swapping!',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final matchDoc = matches[index];
                final data = matchDoc.data();
                return StaggeredItem(
                  index: index,
                  child: _buildMatchCard(matchDoc.id, data, isDark),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatchCard(
    String matchId,
    Map<String, dynamic> data,
    bool isDark,
  ) {
    final senderUid = data['senderUid'] ?? data['requesterId'] ?? '';
    final senderName = data['requesterName'] ?? data['senderName'] ?? 'Student';
    final receiverName = data['postOwnerName'] ?? 'Student';
    final teachSkill = data['teachSkill'] ?? 'Skill';
    final learnSkill = data['learnSkill'] ?? 'Skill';

    final otherPersonName = senderUid == _uid ? receiverName : senderName;
    final otherUserId = senderUid == _uid
        ? (data['receiverUid'] ?? data['postOwnerId'] ?? '')
        : senderUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: BouncyTap(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: data['conversationId'] ?? matchId,
                fallbackOtherUserId: otherUserId,
                fallbackOtherUserName: otherPersonName.toString(),
              ),
            ),
          );
        },
        child: PremiumCard(
          hasGlow: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PremiumAvatar(name: otherPersonName.toString(), size: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherPersonName.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Match accepted',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradientBrush,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Skill swap info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.1),
                      const Color(0xFF059669).withOpacity(isDark ? 0.1 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$teachSkill ↔ $learnSkill',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.accentGradientBrush,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.1),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
