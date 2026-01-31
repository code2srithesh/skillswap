import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../services/messaging_service.dart';
import 'chat_screen.dart';
import '../../../core/theme.dart';
import '../../../core/animations.dart';
import '../../../core/time_formatter.dart';
import '../../../core/widgets/premium_background.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _messagingService = MessagingService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<ConversationModel>>(
      stream: _messagingService.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: ShimmerAnimation(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final otherUserId = conversation.otherUserId(currentUserId);
            final otherUserName = conversation.otherUserName(currentUserId);
            final hasUnread = conversation.unreadCountFor(currentUserId) > 0;

            return StaggeredItem(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BouncyTap(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: conversation.id,
                          fallbackOtherUserId: otherUserId,
                          fallbackOtherUserName: otherUserName,
                        ),
                      ),
                    );
                  },
                  child: PremiumCard(
                    padding: const EdgeInsets.all(16),
                    hasGlow: hasUnread,
                    child: Row(
                      children: [
                        // Premium Avatar
                        PremiumAvatar(name: otherUserName, size: 52),
                        const SizedBox(width: 16),

                        // Message info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      otherUserName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: hasUnread
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    TimeFormatter.formatTime(
                                      conversation.lastMessageTime,
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: hasUnread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: hasUnread
                                          ? AppTheme.primaryColor
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      conversation.lastMessage.isEmpty
                                          ? "Start a conversation..."
                                          : conversation.lastMessage,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: hasUnread
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                        color: hasUnread
                                            ? (isDark
                                                  ? Colors.white70
                                                  : Colors.black87)
                                            : Colors.grey.shade500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (hasUnread) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.accentGradientBrush,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '${conversation.unreadCountFor(currentUserId)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No messages yet',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect with other students to start\nexchanging skills and messages',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber.shade100,
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: Colors.amber.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load messages',
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
}
