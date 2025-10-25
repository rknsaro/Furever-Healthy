// lib/quick_actions/community/community_forums.dart
import 'package:flutter/material.dart';

const _mint = Color(0xFF6F994A);

class CommunityForumsTab extends StatelessWidget {
  const CommunityForumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Started by $author', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$replies Replies', style: const TextStyle(color: _mint, fontWeight: FontWeight.w500)),
              Text('Last activity: $lastActivity', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
