// lib/quick_actions/community/community_feed.dart
import 'package:flutter/material.dart';

const _headerGreen = Color(0xFF6F994A);
const _textMuted = Color(0xFF8C8C8C);

class CommunityFeedTab extends StatefulWidget {
  const CommunityFeedTab({super.key});

  @override
  State<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends State<CommunityFeedTab> {
  final List<_CommunityPost> _posts = [
    _CommunityPost(
      userName: 'Mark kikiam',
      userAvatar: 'assets/pet_images/luna.png',
      statusPrompt: 'What’s on your mind?',
      message: 'Adopted a new cat!! Her name is Luna!\n#cutecat',
      petImage: 'assets/pet_images/luna.png',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      reactions: 3,
      comments: 0,
      shares: 0,
    ),
  ];

  late final List<bool> _isLiked = List<bool>.filled(
    _posts.length,
    false,
    growable: false,
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          for (var i = 0; i < _posts.length; i++) ...[
            _buildPostCard(context, _posts[i], i),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            backgroundImage: const AssetImage('assets/pet_images/luna.png'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _posts.first.statusPrompt,
              style: const TextStyle(color: _textMuted, fontSize: 14),
            ),
          ),
          Image.asset('assets/add_post.png', width: 24, height: 24),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, _CommunityPost post, int index) {
    final isLiked = _isLiked[index];
    final reactionCount = post.reactions + (isLiked ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: AssetImage(post.userAvatar),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _timeAgo(post.timestamp),
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz, color: _textMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                post.message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Color(0xFF2F2F2F),
                ),
              ),
            ),
            if (post.petImage != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  post.petImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 220,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildReactionSummary(reactionCount, post.comments),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  _PostActionButton(
                    asset: isLiked
                        ? 'assets/pawheart_filled.png'
                        : 'assets/pawheart.png',
                    label: reactionCount.toString(),
                    onTap: () {
                      setState(() {
                        _isLiked[index] = !_isLiked[index];
                      });
                    },
                  ),
                  _PostActionButton(
                    asset: 'assets/comment.png',
                    label: post.comments.toString(),
                    onTap: () {},
                  ),
                  _PostActionButton(
                    asset: 'assets/share_button.png',
                    label: post.shares.toString(),
                    onTap: () {},
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: Image.asset(
                      'assets/save_post.png',
                      width: 26,
                      height: 26,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionSummary(int reactions, int comments) {
    return Row(
      children: [
        Image.asset('assets/pawheart.png', width: 18, height: 18),
        const SizedBox(width: 6),
        Text(
          '$reactions',
          style: const TextStyle(
            color: _headerGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        Image.asset('assets/comment.png', width: 18, height: 18),
        const SizedBox(width: 6),
        Text(
          '$comments',
          style: const TextStyle(
            color: _headerGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes <= 1 ? '1 minute ago' : '$minutes minutes ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return hours <= 1 ? '1 hour ago' : '$hours hours ago';
    }
    final days = difference.inDays;
    return days <= 1 ? '1 day ago' : '$days days ago';
  }
}

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    required this.asset,
    required this.label,
    required this.onTap,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            Image.asset(asset, width: 22, height: 22),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF4F4F4F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityPost {
  _CommunityPost({
    required this.userName,
    required this.userAvatar,
    required this.statusPrompt,
    required this.message,
    required this.timestamp,
    required this.reactions,
    required this.comments,
    required this.shares,
    this.petImage,
  });

  final String userName;
  final String userAvatar;
  final String statusPrompt;
  final String message;
  final DateTime timestamp;
  final int reactions;
  final int comments;
  final int shares;
  final String? petImage;
}
