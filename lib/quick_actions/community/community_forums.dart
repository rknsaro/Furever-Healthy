// lib/quick_actions/community/community_forums.dart
import 'package:flutter/material.dart';

const _mint = Color(0xFF6F994A);

class CommunityForumsTab extends StatefulWidget {
  const CommunityForumsTab({super.key});

  @override
  State<CommunityForumsTab> createState() => _CommunityForumsTabState();
}

class _CommunityForumsTabState extends State<CommunityForumsTab> {
  String _selectedCategoryKey = 'all';
  final Set<String> _likedKeys = {};
  final Map<String, int> _heartCounts = {};
  final Map<String, int> _commentCounts = {};
  final Map<String, List<ForumComment>> _commentsByPost = {};

  late final List<ForumCommunity> _communities = _buildCommunities();

  @override
  void initState() {
    super.initState();
    _seedComments();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPad = MediaQuery.of(context).padding.bottom + 16;

    // Compute posts based on selected category
    final List<({ForumPostSample post, Color accent})> visiblePosts;
    String? subTitle;
    if (_selectedCategoryKey == 'all') {
      visiblePosts = [
        for (final c in _communities)
          for (final p in c.posts) (post: p, accent: c.color),
      ];
      subTitle = null;
    } else {
      final c = _communities.firstWhere(
        (c) => c.key == _selectedCategoryKey,
        orElse: () => _communities.first,
      );
      visiblePosts = [for (final p in c.posts) (post: p, accent: c.color)];
      subTitle = c.subtitle;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: bottomPad,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              // child: Text(
              //   'FH Community',
              //   style: const TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.w800,
              //     color: Color(0xFF1F2937),
              //   ),
              // ),
            ),
            const SizedBox(height: 8),
            if (subTitle != null)
              Text(
                subTitle,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: _selectedCategoryKey == 'all',
                    onTap: () => setState(() => _selectedCategoryKey = 'all'),
                  ),
                  const SizedBox(width: 8),
                  for (final c in _communities) ...[
                    _CategoryChip(
                      label: c.displayName,
                      selected: _selectedCategoryKey == c.key,
                      onTap: () => setState(() => _selectedCategoryKey = c.key),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final pair in visiblePosts) ...[
              _ForumPostCard(
                sample: pair.post,
                accent: pair.accent,
                isLiked: _likedKeys.contains(_sampleKey(pair.post)),
                hearts: _heartCounts[_sampleKey(pair.post)] ?? pair.post.hearts,
                comments:
                    _commentCounts[_sampleKey(pair.post)] ?? pair.post.comments,
                onToggleLike: () {
                  setState(() {
                    final key = _sampleKey(pair.post);
                    if (_likedKeys.contains(key)) {
                      _likedKeys.remove(key);
                      _heartCounts[key] =
                          (_heartCounts[key] ?? pair.post.hearts) - 1;
                    } else {
                      _likedKeys.add(key);
                      _heartCounts[key] =
                          (_heartCounts[key] ?? pair.post.hearts) + 1;
                    }
                  });
                },
                onComment: () async {
                  final added = await _showLocalCommentSheet(
                    context,
                    pair.post,
                  );
                  if (added > 0) {
                    setState(() {
                      final key = _sampleKey(pair.post);
                      _commentCounts[key] =
                          (_commentCounts[key] ?? pair.post.comments) + added;
                    });
                  }
                },
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share coming soon'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (visiblePosts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12.withOpacity(0.08)),
                ),
                child: const Text(
                  'No posts yet for this flair. Be the first to start a discussion!',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<ForumCommunity> _buildCommunities() {
    return [
      ForumCommunity(
        key: 'health',
        displayName: 'Pet Health & Wellness',
        subtitle:
            'Your go-to space for pet wellness discussions — symptoms, feeding, grooming, supplements, and real vet visit experiences.',
        color: const Color(0xFF6F994A),
        flairs: const [
          'Advice Needed',
          'Diet',
          'Medical Concern',
          'Grooming',
          'Success Story',
        ],
        posts: const [
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Pet Health & Wellness',
            username: 'pawcare101',
            timeAgo: '3h',
            flair: 'Advice Needed',
            title: 'How often should I bathe a Shih Tzu?',
            preview:
                'I keep getting conflicting answers. Weekly or every 2–3 weeks? What works best for your Shih Tzu? Any shampoo suggestions?',
            hearts: 128,
            comments: 42,
          ),
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Pet Health & Wellness',
            username: 'catmom',
            timeAgo: '5h',
            flair: 'Medical Concern',
            title: "My cat hasn't eaten for a day — should I worry?",
            preview:
                'She’s usually a heavy eater. Still moving around normally but not eating. Has this happened to your cat before?',
            hearts: 76,
            comments: 33,
          ),
        ],
      ),
      ForumCommunity(
        key: 'breeds',
        displayName: 'Breed Discussions',
        subtitle:
            'Talk about your pet’s breed — health, grooming needs, behavior, and quirks. Perfect for new owners and curious pawrents.',
        color: const Color(0xFF3B82F6),
        flairs: const [
          'Dog Breed',
          'Cat Breed',
          'Behavior',
          'First-Time Owner',
        ],
        posts: const [
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Breed Discussions',
            username: 'adoptlocal',
            timeAgo: '2h',
            flair: 'Dog Breed',
            title: 'Aspin owners: what’s their personality like at home?',
            preview:
                'Thinking of adopting an Aspin. How easy are they to train and socialize?',
            hearts: 90,
            comments: 27,
          ),
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Breed Discussions',
            username: 'persianparent',
            timeAgo: '7h',
            flair: 'Cat Breed',
            title: 'Persian cat owners: how do you deal with matting?',
            preview:
                'My cat’s fur tangles so fast. Any tips for keeping it smooth?',
            hearts: 61,
            comments: 19,
          ),
        ],
      ),
      ForumCommunity(
        key: 'training',
        displayName: 'Training & Behavior',
        subtitle:
            'Share training problems, behavior questions, and techniques that worked for your dogs or cats.',
        color: const Color(0xFFF59E0B),
        flairs: const [
          'Help',
          'Puppy Training',
          'Cat Behavior',
          'Success Story',
          'Question',
        ],
        posts: const [
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Training & Behavior',
            username: 'newpuppy',
            timeAgo: '1h',
            flair: 'Help',
            title: 'Puppy keeps biting everything, including hands',
            preview:
                'He’s teething, but it’s getting a bit too much. What strategies worked for you?',
            hearts: 112,
            comments: 58,
          ),
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Training & Behavior',
            username: 'kittyguru',
            timeAgo: '9h',
            flair: 'Success Story',
            title: 'My cat learned the litter box in just 3 days!',
            preview: 'Here’s what I did — hope it helps other cat parents too!',
            hearts: 140,
            comments: 65,
          ),
        ],
      ),
      ForumCommunity(
        key: 'stories',
        displayName: 'Pet Stories & Moments',
        subtitle:
            'A place to celebrate your pets — funny moments, milestones, glow-ups, and adoption journeys.',
        color: const Color(0xFF8B5CF6),
        flairs: const ['Showoff', 'Before/After', 'Funny', 'Adoption Story'],
        posts: const [
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Pet Stories & Moments',
            username: 'chaosdog',
            timeAgo: '4h',
            flair: 'Funny',
            title: 'Show the most chaotic photo of your pet 🤣',
            preview: 'Here’s my dog crashing head-first into a laundry basket.',
            hearts: 320,
            comments: 104,
          ),
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Pet Stories & Moments',
            username: 'newcatdad',
            timeAgo: '11h',
            flair: 'Adoption Story',
            title: 'Adopted my first kitten — meet Miso!',
            preview: 'She’s tiny but already acting like the boss.',
            hearts: 210,
            comments: 77,
          ),
        ],
      ),
      ForumCommunity(
        key: 'products',
        displayName: 'Product Reviews & Recommendations',
        subtitle:
            'Share and discover trusted pet products — food, toys, grooming, and more.',
        color: const Color(0xFF10B981),
        flairs: const ['Food', 'Toys', 'Grooming', 'Accessories', 'Question'],
        posts: const [
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Product Reviews & Recommendations',
            username: 'gearhound',
            timeAgo: '6h',
            flair: 'Toys',
            title: 'Most durable chew toy for heavy chewers?',
            preview:
                'My lab destroys everything in minutes. Any toy that actually lasts?',
            hearts: 58,
            comments: 21,
          ),
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Product Reviews & Recommendations',
            username: 'catcare',
            timeAgo: '1d',
            flair: 'Food',
            title: 'Best wet food for picky cats (PH-available)?',
            preview:
                'Looking for recommendations that are easy to find locally.',
            hearts: 34,
            comments: 12,
          ),
        ],
      ),
      ForumCommunity(
        key: 'lostfound',
        displayName: 'Lost & Found Pets',
        subtitle:
            'Post lost pets, found animals, or tips for helping pets reunite with their owners.',
        color: const Color(0xFF92400E),
        flairs: const ['Lost', 'Found', 'Urgent', 'Tip'],
        posts: const [
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Lost & Found',
            username: 'mandaluyongwatch',
            timeAgo: '1d',
            flair: 'Lost',
            title: 'Missing orange cat in Mandaluyong',
            preview:
                'Last seen near the barangay hall. Please message if spotted!',
            hearts: 15,
            comments: 9,
          ),
        ],
      ),
      ForumCommunity(
        key: 'adoption',
        displayName: 'Adoption & Rescue',
        subtitle:
            'A safe space for adoption posts, fostering advice, and pet rescue stories.',
        color: const Color(0xFFF59E0B),
        flairs: const [
          'For Adoption',
          'Seeking Adopter',
          'Rescue Story',
          'Foster Tips',
        ],
        posts: const [
          ForumPostSample(
            communityIcon: Icons.pets,
            communityName: 'Adoption & Rescue (PH)',
            username: 'rescueph',
            timeAgo: '3d',
            flair: 'For Adoption',
            title: '4 rescued puppies looking for new homes',
            preview: 'Location: Cavite • DM for details if interested.',
            hearts: 45,
            comments: 18,
          ),
        ],
      ),
    ];
  }

  String _sampleKey(ForumPostSample s) =>
      '${s.communityName}-${s.title}-${s.username}';

  Future<int> _showLocalCommentSheet(
    BuildContext context,
    ForumPostSample post,
  ) async {
    final controller = TextEditingController();
    int added = 0;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final inset = MediaQuery.of(ctx).viewInsets.bottom;
        return StatefulBuilder(
          builder: (localCtx, localSetState) {
            final String key = _sampleKey(post);
            _commentsByPost.putIfAbsent(key, () => <ForumComment>[]);
            final comments = _commentsByPost[key]!;
            return Padding(
              padding: EdgeInsets.only(bottom: inset),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Comments • ${(_commentCounts[key] ?? post.comments) + added + _extraLocalCountForRenderedReplies(comments)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 16),
                    Expanded(
                      child: comments.isEmpty
                          ? const Center(
                              child: Text(
                                'Be the first to comment!',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: comments.length,
                              itemBuilder: (_, i) {
                                final c = comments[i];
                                return _CommentTile(
                                  comment: c,
                                  onReplySubmit: (text) {
                                    if (text.trim().isEmpty) return;
                                    final reply = ForumComment(
                                      author: 'you',
                                      message: text.trim(),
                                      timeAgo: 'now',
                                    );
                                    localSetState(() {
                                      c.replies.add(reply);
                                      added += 1;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F3F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  hintText: 'Write a comment...',
                                  hintStyle: TextStyle(color: Colors.black38),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;
                              final newComment = ForumComment(
                                author: 'you',
                                message: text,
                                timeAgo: 'now',
                              );
                              localSetState(() {
                                comments.add(newComment);
                                added += 1;
                              });
                              controller.clear();
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: _mint,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return added;
  }

  void _seedComments() {
    // Seed comments related to each post's title/preview
    for (final community in _communities) {
      for (final post in community.posts) {
        final key = _sampleKey(post);
        if (_commentsByPost.containsKey(key)) continue;
        final seed = _buildSeedForPost(community, post);
        _commentsByPost[key] = seed;
        _commentCounts[key] =
            (_commentCounts[key] ?? post.comments) +
            seed.length +
            seed.fold<int>(0, (n, c) => n + c.replies.length);
      }
    }
  }

  List<ForumComment> _buildSeedForPost(
    ForumCommunity community,
    ForumPostSample post,
  ) {
    final t = post.title.toLowerCase();
    final preview = post.preview.toLowerCase();
    switch (community.key) {
      case 'health':
        if (t.contains('shih tzu') || t.contains('bathe')) {
          return [
            ForumComment(
              author: 'groomGuru',
              message:
                  'For Shih Tzu, every 2–3 weeks is ideal. Weekly can dry skin unless you moisturize.',
              timeAgo: '2h',
              replies: [
                ForumComment(
                  author: 'oatmealFan',
                  message:
                      'Aloe/oatmeal shampoos helped our itch-prone shih tzu.',
                  timeAgo: '1h',
                ),
              ],
            ),
            ForumComment(
              author: 'coatCare',
              message:
                  'Brush before bath to avoid matting. Conditioner helps a lot.',
              timeAgo: '45m',
            ),
          ];
        }
        if (t.contains("hasn't eaten") || preview.contains('not eating')) {
          return [
            ForumComment(
              author: 'catRN',
              message:
                  'Warm the wet food a bit and try tuna water. If >24h no eating, call a vet.',
              timeAgo: '3h',
              replies: [
                ForumComment(
                  author: 'hydrationTips',
                  message: 'Check hydration (gum moisture, skin tent).',
                  timeAgo: '2h',
                ),
              ],
            ),
            ForumComment(
              author: 'quietFeeder',
              message:
                  'Feed in a calm spot; stress and new smells can reduce appetite.',
              timeAgo: '1h',
            ),
          ];
        }
        break;
      case 'breeds':
        if (t.contains('aspin')) {
          return [
            ForumComment(
              author: 'aspinOwner',
              message:
                  'Super loyal and smart. Socialize early and provide puzzle games.',
              timeAgo: '5h',
              replies: [
                ForumComment(
                  author: 'parkBuddy',
                  message: 'Daily walks + basic cues kept mine well-behaved.',
                  timeAgo: '4h',
                ),
              ],
            ),
            ForumComment(
              author: 'trainerPH',
              message: 'Short, frequent sessions work best with Aspins.',
              timeAgo: '2h',
            ),
          ];
        }
        if (t.contains('persian') || preview.contains('matting')) {
          return [
            ForumComment(
              author: 'combCollector',
              message:
                  'Steel comb + detangling spray. Work slowly from tips to roots.',
              timeAgo: '7h',
            ),
            ForumComment(
              author: 'groomSchedule',
              message:
                  'Daily quick combing behind ears/underarms prevents painful mats.',
              timeAgo: '5h',
              replies: [
                ForumComment(
                  author: 'vetTech',
                  message:
                      'If mats are tight, see a groomer — avoid scissors near skin.',
                  timeAgo: '5h',
                ),
              ],
            ),
          ];
        }
        break;
      case 'training':
        if (t.contains('biting') || preview.contains('teething')) {
          return [
            ForumComment(
              author: 'puppyCoach',
              message:
                  'Redirect to chew toy; pause play if biting repeats. Consistency matters.',
              timeAgo: '1h',
              replies: [
                ForumComment(
                  author: 'freezeToy',
                  message: 'Frozen washcloths soothed my pup’s gums.',
                  timeAgo: '55m',
                ),
              ],
            ),
            ForumComment(
              author: 'calmSignals',
              message: 'Mark calm behavior with a reward; teach “leave it”.',
              timeAgo: '50m',
            ),
          ];
        }
        if (t.contains('litter box') || preview.contains('litter')) {
          return [
            ForumComment(
              author: 'catCoach',
              message:
                  'Great! Keep the box spotless and use fine-grain litter to maintain habits.',
              timeAgo: '9h',
            ),
            ForumComment(
              author: 'kittenTips',
              message:
                  'Offer one extra litter box in a quiet spot to prevent accidents.',
              timeAgo: '8h',
            ),
          ];
        }
        break;
      case 'stories':
        if (t.contains('chaotic photo') || preview.contains('photo')) {
          return [
            ForumComment(
              author: 'laughTrack',
              message: 'Peak chaos. Pets vs physics is my favorite genre 😂',
              timeAgo: '4h',
            ),
            ForumComment(
              author: 'cameraRoll',
              message: 'I have a mid-air fail too — instant classic.',
              timeAgo: '3h',
            ),
          ];
        }
        if (t.contains('adopted') || preview.contains('first kitten')) {
          return [
            ForumComment(
              author: 'welcomeHome',
              message: 'Congrats on Miso! Expect zoomies and cuddle naps.',
              timeAgo: '11h',
              replies: [
                ForumComment(
                  author: 'kittenCare',
                  message: 'Add vertical spaces and scratchers to burn energy.',
                  timeAgo: '10h',
                ),
              ],
            ),
            ForumComment(
              author: 'safeSpace',
              message:
                  'A quiet safe room helps with the first-week adjustment.',
              timeAgo: '10h',
            ),
          ];
        }
        break;
      case 'products':
        if (t.contains('chew toy') || preview.contains('chewer')) {
          return [
            ForumComment(
              author: 'durabilityTester',
              message: 'Kong Extreme and GoughNuts survived my power chewer.',
              timeAgo: '6h',
            ),
            ForumComment(
              author: 'sizeMatters',
              message: 'Size up one step — reduces tearing for strong jaws.',
              timeAgo: '5h',
            ),
          ];
        }
        if (t.contains('wet food') || preview.contains('picky cats')) {
          return [
            ForumComment(
              author: 'catCuisine',
              message:
                  'Warm slightly or add broth. Transition brands gradually.',
              timeAgo: '1d',
            ),
            ForumComment(
              author: 'storeWatch',
              message: 'Monge and Sheba are easy to find locally.',
              timeAgo: '22h',
            ),
          ];
        }
        break;
      case 'lostfound':
        if (t.contains('orange cat') || preview.contains('barangay')) {
          return [
            ForumComment(
              author: 'localEyes',
              message:
                  'Search late evening — streets are quieter and cats emerge.',
              timeAgo: '1d',
            ),
            ForumComment(
              author: 'posterPro',
              message: 'Posters at sari‑sari stores spread fast in the area.',
              timeAgo: '23h',
            ),
          ];
        }
        break;
      case 'adoption':
        if (t.contains('rescued puppies') || preview.contains('cavite')) {
          return [
            ForumComment(
              author: 'adoptShare',
              message:
                  'Sharing! Please add age, deworm/vax status, and temperament notes.',
              timeAgo: '3d',
            ),
            ForumComment(
              author: 'fosterCare',
              message: 'Vet check + clear photos boost adoption chances.',
              timeAgo: '2d',
            ),
          ];
        }
        break;
    }
    return [
      ForumComment(
        author: 'communityMember',
        message: 'Great topic — following for more insights!',
        timeAgo: '2h',
      ),
      ForumComment(
        author: 'helpfulPaw',
        message: 'Thanks for posting. This will help many of us.',
        timeAgo: '1h',
      ),
    ];
  }

  int _extraLocalCountForRenderedReplies(List<ForumComment> comments) {
    // We count replies in display count while the sheet is open
    return comments.fold<int>(0, (n, c) => n + c.replies.length);
  }
}

class ForumPostSample {
  final IconData communityIcon;
  final String communityName;
  final String username;
  final String timeAgo;
  final String flair;
  final String title;
  final String preview;
  final int hearts;
  final int comments;

  const ForumPostSample({
    required this.communityIcon,
    required this.communityName,
    required this.username,
    required this.timeAgo,
    required this.flair,
    required this.title,
    required this.preview,
    required this.hearts,
    required this.comments,
  });
}

class ForumCommunity {
  final String key;
  final String displayName;
  final String subtitle;
  final Color color;
  final List<String> flairs;
  final List<ForumPostSample> posts;
  const ForumCommunity({
    required this.key,
    required this.displayName,
    required this.subtitle,
    required this.color,
    required this.flairs,
    required this.posts,
  });
}

class ForumComment {
  final String author;
  final String message;
  final String timeAgo;
  final List<ForumComment> replies;

  ForumComment({
    required this.author,
    required this.message,
    required this.timeAgo,
    List<ForumComment>? replies,
  }) : replies = replies ?? <ForumComment>[];
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = _mint;
    final bg = selected ? color.withOpacity(0.14) : color.withOpacity(0.06);
    final border = selected ? color.withOpacity(0.6) : color.withOpacity(0.25);
    final weight = selected ? FontWeight.w800 : FontWeight.w700;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: weight, fontSize: 12),
        ),
      ),
    );
  }
}

class _ForumPostCard extends StatelessWidget {
  const _ForumPostCard({
    required this.sample,
    required this.accent,
    required this.isLiked,
    required this.hearts,
    required this.comments,
    required this.onToggleLike,
    required this.onComment,
    required this.onShare,
  });

  final ForumPostSample sample;
  final Color accent;
  final bool isLiked;
  final int hearts;
  final int comments;
  final VoidCallback onToggleLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black12.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(sample.communityIcon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${sample.communityName} • Posted by @${sample.username} • ${sample.timeAgo} ago',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
            ],
          ),
          const SizedBox(height: 10),
          // Flair + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Text(
                  '[${sample.flair}]',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sample.title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sample.preview,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          // Actions row (match community_feed)
          Row(
            children: [
              GestureDetector(
                onTap: onToggleLike,
                child: Row(
                  children: [
                    Image.asset(
                      isLiked
                          ? 'assets/pawheart_filled.png'
                          : 'assets/pawheart.png',
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$hearts',
                      style: const TextStyle(
                        color: _mint,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: onComment,
                child: Row(
                  children: [
                    Image.asset('assets/comment.png', width: 22, height: 22),
                    const SizedBox(width: 6),
                    Text(
                      '$comments',
                      style: const TextStyle(
                        color: _mint,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: onShare,
                child: Row(
                  children: [
                    Image.asset(
                      'assets/share_button.png',
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Share',
                      style: TextStyle(
                        color: _mint,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // no-op helper removed
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({required this.comment, required this.onReplySubmit});
  final ForumComment comment;
  final ValueChanged<String> onReplySubmit;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _isReplying = false;
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _mint.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, size: 18, color: _mint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${widget.comment.author} • ${widget.comment.timeAgo}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.comment.message,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => setState(() => _isReplying = !_isReplying),
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          color: _mint,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (_isReplying) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F3F5),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: TextField(
                                controller: _replyController,
                                decoration: const InputDecoration(
                                  hintText: 'Write a reply...',
                                  hintStyle: TextStyle(color: Colors.black38),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              final text = _replyController.text.trim();
                              if (text.isEmpty) return;
                              widget.onReplySubmit(text);
                              _replyController.clear();
                              setState(() => _isReplying = false);
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: _mint,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.send,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.comment.replies.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      for (final r in widget.comment.replies)
                        Padding(
                          padding: const EdgeInsets.only(left: 38, bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _mint.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.pets,
                                  size: 14,
                                  color: _mint,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '@${r.author} • ${r.timeAgo}',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.message,
                                      style: const TextStyle(
                                        color: Color(0xFF111827),
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
