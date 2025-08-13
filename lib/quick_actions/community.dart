import 'package:flutter/material.dart';

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
    // Updated length to 3 for Feed, Forums, Events
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0D6), // Matches your app's background color
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: const Color(0xFF61972E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the logo
          children: [
            Image.asset(
              'assets/furever2.png', // Your app logo from home_page
              height: 40,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
            onPressed: () {
              print('Notification icon tapped on Community page!');
            },
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0), // Height for the TabBar
          child: Container(
            color: const Color(0xFF61972E), // AppBar color
            child: TabBar(
              controller: _tabController,
              isScrollable: true, // Allow scrolling if many tabs
              indicatorColor: Colors.white, // White indicator line
              labelColor: Colors.white, // Selected tab text color
              unselectedLabelColor: Colors.white.withOpacity(0.7), // Unselected tab text color
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
              tabs: const [
                Tab(text: 'Feed'),
                Tab(text: 'Forums'),
                Tab(text: 'Events'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Feed Tab Content
          SingleChildScrollView(
            child: Column(
              children: [
                _buildPostCard(
                  context: context,
                  userName: 'Pet Owner',
                  timeAgo: '2 days ago',
                  postText: 'Adopted a new puppy!! Her name is Toppy!',
                  imageAsset: 'assets/puppy.jpeg', // You'll need to add this image
                  tags: ['#dog', '#puppy', '#beagle'],
                ),
                _buildPostCard(
                  context: context,
                  userName: 'Cat_Lover_123',
                  timeAgo: '5 hours ago',
                  postText: 'My cat, Whiskers, just turned 5! Happy birthday little one! 🎉',
                  imageAsset: null, // No image for this post example
                  tags: ['#cat', '#birthday', '#whiskers', '#feline'],
                ),
                _buildPostCard(
                  context: context,
                  userName: 'DoggoFan',
                  timeAgo: '1 day ago',
                  postText: 'Morning walkies with Max! He loves the park. 🐶🌳',
                  imageAsset: 'assets/dog_walking.jpeg', // Add this image or use a placeholder
                  tags: ['#dog', '#walkies', '#park', '#goldenretriever'],
                ),
                // --- Add more feed posts here ---
              ],
            ),
          ),
          // Forums Tab Content
          _buildForumsTab(),
          // Events Tab Content
          _buildEventsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('Add Post button tapped!');
          // Implement logic to add a new post/forum/event based on current tab
        },
        backgroundColor: const Color(0xFF61972E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Helper method to build a forum post card
  Widget _buildForumPostCard({
    required String title,
    required String author,
    required String replies,
    required String lastActivity,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
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
                style: const TextStyle(color: Color(0xFF61972E), fontWeight: FontWeight.w500),
              ),
              Text(
                'Last activity: $lastActivity',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build an event card
  Widget _buildEventCard({
    required String title,
    required String date,
    required String time,
    required String location,
    String? imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imageUrl,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                '$date at $time',
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                location,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: () {
                print('View event details for $title');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF61972E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('View Details'),
            ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
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
                backgroundColor: Color(0xFFE8F0D6),
                child: Icon(Icons.person, color: Color(0xFF61972E)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    timeAgo,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.grey),
                onPressed: () {
                  print('Share post tapped!');
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            postText,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          if (imageAsset != null) ...[
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imageAsset,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                    ),
                  );
                },
              ),
            ),
          ],
          if (tags != null && tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: tags.map((tag) => Text(
                tag,
                style: const TextStyle(color: Color(0xFF61972E), fontSize: 13, fontWeight: FontWeight.w500),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // --- Forums Tab Content ---
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
          _buildForumPostCard(
            title: 'Share your funniest pet stories!',
            author: 'LaughingPetOwner',
            replies: '120',
            lastActivity: 'yesterday',
          ),
          // Add more forum posts here
          const SizedBox(height: 80), // Space for floating action button
        ],
      ),
    );
  }

  // --- Events Tab Content ---
  Widget _buildEventsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildEventCard(
            title: 'Local Pet Adoption Drive',
            date: 'August 15, 2025',
            time: '10:00 AM - 3:00 PM',
            location: 'Community Park, Malvar',
            imageUrl: 'assets/adoption_event.jpeg', // Add this image
          ),
          _buildEventCard(
            title: 'Free Pet Grooming Workshop',
            date: 'September 5, 2025',
            time: '2:00 PM - 4:00 PM',
            location: 'Pet Salon & Spa',
            imageUrl: null, // No image for this event
          ),
          _buildEventCard(
            title: 'Annual Dog Walk for Charity',
            date: 'October 2, 2025',
            time: '8:00 AM',
            location: 'Riverfront Trail',
            imageUrl: 'assets/dog_walk.jpeg', // Add this image
          ),
          // Add more event cards here
          const SizedBox(height: 80), // Space for floating action button
        ],
      ),
    );
  }
}