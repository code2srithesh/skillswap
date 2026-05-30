import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../home/models/post_model.dart';
import '../../skill_details/screens/skill_detail_screen.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../../core/theme.dart';
import '../../../core/animations.dart';
import '../../../core/time_formatter.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/premium_background.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required List allPosts});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _keyword = "";
  Set<String> _acceptedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadAcceptedUsers();
  }

  // Load all users with whom current user has accepted requests
  Future<void> _loadAcceptedUsers() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('requests')
        .where('participants', arrayContains: currentUserId)
        .where('status', isEqualTo: 'accepted')
        .get();

    final Set<String> acceptedIds = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participants'] ?? []);
      for (var userId in participants) {
        if (userId != currentUserId) {
          acceptedIds.add(userId);
        }
      }
    }

    if (mounted) {
      setState(() {
        _acceptedUserIds = acceptedIds;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Discover Skills',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: TextField(
                autofocus: false,
                onChanged: (val) => setState(() => _keyword = val),
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Search skills (e.g. Flutter, Python)...",
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                  suffixIcon: _keyword.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white),
                          onPressed: () => setState(() => _keyword = ""),
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ),
            
            // Search Results
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return Center(
                      child: Text(
                        'No posts available',
                        style: GoogleFonts.inter(color: Colors.grey.shade400),
                      ),
                    );
                  }

                  final allDocs = snapshot.data!.docs;
                  final currentUserId =
                      FirebaseAuth.instance.currentUser?.uid ?? '';

                  final filteredDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final teach = (data['teachSkill'] ?? '')
                        .toString()
                        .toLowerCase();
                    final learn = (data['learnSkill'] ?? '')
                        .toString()
                        .toLowerCase();
                    final search = _keyword.toLowerCase();
                    final postUserId = data['uid'] ?? '';
                    final isSwapped = data['isSwapped'] ?? false;
                    final isDiscoverable = data['isDiscoverable'] ?? true;

                    final matchesSearch =
                        _keyword.isEmpty ||
                        teach.contains(search) ||
                        learn.contains(search);
                    final isNotOwnPost = postUserId != currentUserId;
                    final notSwapped = !isSwapped;
                    final noAcceptedRequest = !_acceptedUserIds.contains(
                      postUserId,
                    );

                    return matchesSearch &&
                        isNotOwnPost &&
                        notSwapped &&
                        isDiscoverable &&
                        noAcceptedRequest;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleInAnimation(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 50,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No matching skills found',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords',
                            style: GoogleFonts.inter(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final post = PostModel(
                        id: doc.id,
                        uid: data['uid'] ?? '',
                        userName: data['userName'] ?? 'Student',
                        role: data['role'] ?? 'VIT Student',
                        teachSkill: data['teachSkill'] ?? '',
                        learnSkill: data['learnSkill'] ?? '',
                        description: data['description'] ?? '',
                        timePosted: data['timePosted'] ?? 'Recently',
                        createdAt:
                            (data['createdAt'] as dynamic)?.toDate() ??
                            DateTime.now(),
                        updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
                        expiryDays: data['expiryDays'] ?? 0,
                      );

                      return StaggeredItem(
                        index: index,
                        child: _buildSearchCard(post, context, isDark),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard(PostModel post, BuildContext context, bool isDark) {
    final isExpired = post.checkIfExpired();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SkillDetailScreen(post: post),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Row
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(
                            userId: post.uid,
                            userName: post.userName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        child: Text(
                          post.userName.isNotEmpty ? post.userName[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UserProfileScreen(
                              userId: post.uid,
                              userName: post.userName,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            post.role,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Expired',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Swap Skills Info Box
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TEACHES',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                          ),
                          child: Text(
                            post.teachSkill,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'LEARNS',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
                          ),
                          child: Text(
                            post.learnSkill,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (post.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  post.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade300,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),

              // Expiry Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TimeFormatter.formatTime(post.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    TimeFormatter.getTimeRemaining(
                      post.createdAt,
                      post.expiryDays,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isExpired
                          ? Colors.red.shade400
                          : Colors.orange.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
