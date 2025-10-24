import 'package:flutter/material.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_mint, _mintDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with logo and icons
              Padding(
                padding: EdgeInsets.only(top: statusBarHeight + 4, left: 8, right: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        Image.asset('assets/furever.png', height: 28),
                        const SizedBox(width: 6),
                        const Text(
                          'Furever Healthy',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.white, size: 26),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Community header card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/pawscomm.png', height: 35),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Connect with others, share your stories, and grow together in one friendly space.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tabs (Feed, Forums, Events)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 2.5,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Feed'),
                    Tab(text: 'Forums'),
                    Tab(text: 'Events'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // White rounded container for tab content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFeedTab(context),
                      _buildForumsTab(),
                      _buildEventsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Add Post button tapped!');
        },
        backgroundColor: _mint,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- FEED TAB ---
  Widget _buildFeedTab(BuildContext context) {
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
            imageAsset: null,
            tags: ['#cat', '#birthday', '#whiskers'],
          ),
        ],
      ),
    );
  }

  // --- FORUMS TAB ---
  Widget _buildForumsTab() {
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

  // --- EVENTS TAB ---
  Widget _buildEventsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildEventCard(
            title: 'Local Pet Adoption Drive',
            date: 'August 15, 2025',
            time: '10:00 AM - 3:00 PM',
            location: 'Community Park, Malvar',
            imageUrl: 'assets/adoption_event.jpeg',
          ),
          _buildEventCard(
            title: 'Free Pet Grooming Workshop',
            date: 'September 5, 2025',
            time: '2:00 PM - 4:00 PM',
            location: 'Pet Salon & Spa',
          ),
        ],
      ),
    );
  }

  // --- Reusable Cards ---
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

  Widget _buildEventCard({
    required String title,
    required String date,
    required String time,
    required String location,
    String? imageUrl,
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
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(imageUrl, fit: BoxFit.cover),
            ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text('$date at $time', style: const TextStyle(color: Colors.black54, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(location, style: const TextStyle(color: Colors.black54, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _mint,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }
}
