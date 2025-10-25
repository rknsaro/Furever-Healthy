// lib/quick_actions/community/community_feed.dart
import 'package:flutter/material.dart';

const _mint = Color(0xFF6F994A);

class CommunityFeedTab extends StatelessWidget {
  const CommunityFeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPostCard(
            context: context,
            userName: 'Pet Owner',
            timeAgo: '2 days ago',
            postText: 'Adopted a new puppy!! Her name is Toppy!',
            imageAsset: 'assets/puppy.jpeg',
            tags: ['#dog', '#puppy', '#beagle'],
          ),
          _buildPostCard(
            context: context,
            userName: 'Cat_Lover_123',
            timeAgo: '5 hours ago',
            postText: 'My cat, Whiskers, just turned 5! 🎉',
            tags: ['#cat', '#birthday', '#whiskers'],
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard({
    required BuildContext context,
    required String userName,
    required String timeAgo,
    required String postText,
    String? imageAsset,
    List<String>? tags,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
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
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFA9C88C),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(postText, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          if (imageAsset != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(imageAsset, fit: BoxFit.cover),
            ),
          ],
          if (tags != null && tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: tags
                  .map((t) => Text(t, style: const TextStyle(color: _mint, fontWeight: FontWeight.w500)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
