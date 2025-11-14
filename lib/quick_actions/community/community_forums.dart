// lib/quick_actions/community/community_forums.dart
import 'package:flutter/material.dart';

const _mint = Color(0xFF6F994A);

class CommunityForumsTab extends StatelessWidget {
  const CommunityForumsTab({super.key});

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
        children: [
          _buildForumPostCard(
            title: 'Best food for picky eaters?',
            author: 'DoggoMom',
            replies: '25',
            lastActivity: '1 hour ago',
          ),
          _buildForumPostCard(
            title: 'Training tips for new puppies',
            author: 'TrainerPro',
            replies: '80',
            lastActivity: '3 hours ago',
          ),
        ],
      ),
    );
  }

  Widget _buildForumPostCard({
    required String title,
    required String author,
    required String replies,
    required String lastActivity,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2F2F2F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Started by $author',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$replies Replies',
                  style: const TextStyle(
                    color: _mint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Last activity: $lastActivity',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
