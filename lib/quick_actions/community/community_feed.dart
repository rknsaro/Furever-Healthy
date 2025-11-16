// lib/quick_actions/community/community_feed.dart
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

const _headerGreen = Color(0xFF6F994A);
const _textMuted = Color(0xFF8C8C8C);

class CommunityFeedTab extends StatefulWidget {
  const CommunityFeedTab({super.key});

  @override
  State<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends State<CommunityFeedTab> {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<_CommunityPost> _posts = [];
  late final List<bool> _isLiked = [];
  String? _profileImageUrl;
  final Map<String, String> _userProfileImages = {};

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadProfileImage();
  }

  Future<void> _showCommentsSheet(_CommunityPost post) async {
    final TextEditingController commentController = TextEditingController();
    final currentUser = _auth.currentUser;
    String? replyingToCommentId;
    String? replyingToUserName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.8,
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
                // Header with live count
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('community_posts')
                      .doc(post.postId)
                      .collection('comments')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Column(
                      children: [
                        Text(
                          count > 0 ? 'Comments ($count)' : 'Comments',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.black12, height: 1),
                      ],
                    );
                  },
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection('community_posts')
                        .doc(post.postId)
                        .collection('comments')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _headerGreen),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Failed to load comments.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        );
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Be the first to comment.',
                            style: TextStyle(color: Colors.black45),
                          ),
                        );
                      }

                      // Separate top-level comments and replies
                      final topLevel =
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                      final byParent =
                          <
                            String,
                            List<QueryDocumentSnapshot<Map<String, dynamic>>>
                          >{};
                      for (final d in docs) {
                        final parentId = d.data()['parentId'] as String?;
                        if (parentId == null) {
                          topLevel.add(d);
                        } else {
                          byParent.putIfAbsent(parentId, () => []).add(d);
                        }
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: topLevel.length,
                        itemBuilder: (context, index) {
                          final c = topLevel[index];
                          return _buildCommentTile(
                            context: context,
                            postId: post.postId,
                            doc: c,
                            replies: byParent[c.id] ?? const [],
                            byParent: byParent,
                            onReplyTap: (commentId, userName) {
                              replyingToCommentId = commentId;
                              replyingToUserName = userName;
                              // focus input
                              FocusScope.of(context).unfocus();
                              Future.delayed(
                                const Duration(milliseconds: 50),
                                () {
                                  FocusScope.of(ctx).requestFocus(FocusNode());
                                },
                              );
                              // refresh banner
                              (ctx as Element).markNeedsBuild();
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                if (replyingToUserName != null) ...[
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFF1F3F5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Replying to $replyingToUserName',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            replyingToCommentId = null;
                            replyingToUserName = null;
                            (ctx as Element).markNeedsBuild();
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(color: Colors.black87),
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
                        onTap: () async {
                          final text = commentController.text.trim();
                          if (text.isEmpty) return;
                          if (currentUser == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please sign in to comment'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                            return;
                          }
                          try {
                            // Prepare profile info
                            String userName =
                                currentUser.displayName ?? 'Anonymous';
                            String? avatarUrl = currentUser.photoURL;
                            try {
                              final userDoc = await _firestore
                                  .collection('users')
                                  .doc(currentUser.uid)
                                  .get();
                              final data = userDoc.data();
                              if (data != null) {
                                if ((data['name'] as String?)
                                        ?.trim()
                                        .isNotEmpty ==
                                    true) {
                                  userName = (data['name'] as String).trim();
                                }
                                final fsAvatar =
                                    data['profileImageUrl'] as String?;
                                if (fsAvatar != null &&
                                    fsAvatar.trim().isNotEmpty) {
                                  avatarUrl = fsAvatar.trim();
                                }
                              }
                            } catch (_) {}

                            final commentRef = _firestore
                                .collection('community_posts')
                                .doc(post.postId)
                                .collection('comments')
                                .doc();

                            final payload = {
                              'commentId': commentRef.id,
                              'postId': post.postId,
                              'userId': currentUser.uid,
                              'userName': userName,
                              'userAvatar': avatarUrl,
                              'text': text,
                              'parentId': replyingToCommentId,
                              'createdAt': FieldValue.serverTimestamp(),
                            };

                            final batch = _firestore.batch();
                            batch.set(commentRef, payload);
                            batch.update(
                              _firestore
                                  .collection('community_posts')
                                  .doc(post.postId),
                              {'comments': FieldValue.increment(1)},
                            );
                            await batch.commit();

                            commentController.clear();
                            replyingToCommentId = null;
                            replyingToUserName = null;
                            (ctx as Element).markNeedsBuild();

                            // Create notifications
                            try {
                              // Notify post owner on any new comment
                              if (currentUser.uid != post.userId) {
                                await _firestore
                                    .collection('notifications')
                                    .add({
                                      'userId': post.userId,
                                      'type': 'comment',
                                      'postId': post.postId,
                                      'actorId': currentUser.uid,
                                      'actorName': userName,
                                      'message':
                                          '$userName commented on your post',
                                      'createdAt': FieldValue.serverTimestamp(),
                                      'isRead': false,
                                    });
                              }
                              // If this is a reply, also notify parent comment author (if different)
                              final parentId = payload['parentId'] as String?;
                              if (parentId != null) {
                                final parentSnap = await _firestore
                                    .collection('community_posts')
                                    .doc(post.postId)
                                    .collection('comments')
                                    .doc(parentId)
                                    .get();
                                final parentUserId =
                                    (parentSnap.data()?['userId'] as String?) ??
                                    '';
                                if (parentUserId.isNotEmpty &&
                                    parentUserId != currentUser.uid &&
                                    parentUserId != post.userId) {
                                  await _firestore
                                      .collection('notifications')
                                      .add({
                                        'userId': parentUserId,
                                        'type': 'reply',
                                        'postId': post.postId,
                                        'actorId': currentUser.uid,
                                        'actorName': userName,
                                        'message':
                                            '$userName replied to your comment',
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                        'isRead': false,
                                      });
                                }
                              }
                            } catch (_) {}
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to comment: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _headerGreen,
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
  }

  Widget _buildCommentTile({
    required BuildContext context,
    required String postId,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> replies,
    required Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    byParent,
    required void Function(String commentId, String userName) onReplyTap,
  }) {
    final data = doc.data();
    final userName = (data['userName'] as String?) ?? 'Anonymous';
    final text = (data['text'] as String?) ?? '';
    final avatar = (data['userAvatar'] as String?) ?? '';
    final ts = (data['createdAt'] as Timestamp?)?.toDate();
    final authorId = (data['userId'] as String?) ?? '';
    final currentUserId = _auth.currentUser?.uid;

    Widget avatarWidget;
    if (avatar.startsWith('http')) {
      avatarWidget = ClipOval(
        child: Image.network(
          avatar,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        ),
      );
    } else if (avatar.isNotEmpty) {
      avatarWidget = ClipOval(
        child: Image.asset(
          avatar,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(),
        ),
      );
    } else {
      avatarWidget = _defaultAvatar();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatarWidget,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (ts != null)
                          Text(
                            _timeAgo(ts),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (currentUserId != null && currentUserId == authorId)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            onSelected: (value) async {
                              if (value == 'delete') {
                                await _deleteCommentWithReplies(
                                  postId: postId,
                                  commentId: doc.id,
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            icon: const Icon(
                              Icons.more_horiz,
                              size: 18,
                              color: Colors.black45,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => onReplyTap(doc.id, userName),
                      child: const Text(
                        'Reply',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.favorite_border,
                color: Colors.black26,
                size: 18,
              ),
            ],
          ),
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Column(
                children: replies.map((r) {
                  return _buildCommentTile(
                    context: context,
                    postId: postId,
                    doc: r,
                    replies: byParent[r.id] ?? const [],
                    byParent: byParent,
                    onReplyTap: onReplyTap,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return ClipOval(
      child: Image.asset(
        'assets/pet_images/luna.png',
        width: 36,
        height: 36,
        fit: BoxFit.cover,
      ),
    );
  }

  Future<void> _deleteCommentWithReplies({
    required String postId,
    required String commentId,
  }) async {
    try {
      final commentsCol = _firestore
          .collection('community_posts')
          .doc(postId)
          .collection('comments');
      final repliesSnap = await commentsCol
          .where('parentId', isEqualTo: commentId)
          .get();
      final batch = _firestore.batch();
      int deleteCount = 1;
      // delete parent
      batch.delete(commentsCol.doc(commentId));
      // delete replies
      for (final r in repliesSnap.docs) {
        batch.delete(r.reference);
        deleteCount += 1;
      }
      // decrement comments count on post
      batch.update(_firestore.collection('community_posts').doc(postId), {
        'comments': FieldValue.increment(-deleteCount),
      });
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            backgroundColor: _headerGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comment: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final profileImageRef = _storage
            .ref()
            .child('profile_images')
            .child(user.uid)
            .child('profile.jpg');
        final url = await profileImageRef.getDownloadURL();
        setState(() {
          _profileImageUrl = url;
        });
      } catch (e) {
        // If profile.jpg doesn't exist, try any image in the user's profile_images folder
        try {
          final folderRef = _storage
              .ref()
              .child('profile_images')
              .child(user.uid);
          final listResult = await folderRef.listAll();
          if (listResult.items.isNotEmpty) {
            final anyUrl = await listResult.items.first.getDownloadURL();
            setState(() {
              _profileImageUrl = anyUrl;
            });
            return;
          }
        } catch (_) {}

        // Then try Firestore profileImageUrl, then fallback to Auth photoURL
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          final data = doc.data();
          final fromFirestore = data != null
              ? data['profileImageUrl'] as String?
              : null;
          setState(() {
            _profileImageUrl = fromFirestore ?? user.photoURL;
          });
        } catch (_) {
          setState(() {
            _profileImageUrl = user.photoURL;
          });
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    _CommunityPost post,
    int index,
  ) async {
    // Only allow owners to delete; guard against mis-taps
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != post.userId) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Post'),
          content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deletePost(post, index);
    }
  }

  Future<void> _deletePost(_CommunityPost post, int index) async {
    try {
      // Delete the image from Firebase Storage if it exists
      if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
        try {
          final imageUrl = post.imageUrl!;
          final uri = Uri.parse(imageUrl);

          // Firebase Storage URLs have the format:
          // https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token={token}
          // Extract the path between /o/ and ?
          if (uri.path.contains('/o/')) {
            final pathMatch = RegExp(r'/o/([^?]+)').firstMatch(uri.path);
            if (pathMatch != null) {
              final encodedPath = pathMatch.group(1)!;
              final decodedPath = Uri.decodeComponent(encodedPath);
              final imageRef = _storage.ref(decodedPath);
              await imageRef.delete();
            }
          }
        } catch (e) {
          print('Error deleting image from storage: $e');
          // Continue with post deletion even if image deletion fails
        }
      }

      // Delete the post from Firestore
      await _firestore.collection('community_posts').doc(post.postId).delete();

      // Update the local list
      setState(() {
        _posts.removeAt(index);
        if (_isLiked.length > index) {
          _isLiked.removeAt(index);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: _headerGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleLike(_CommunityPost post, int index) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final postRef = _firestore.collection('community_posts').doc(post.postId);
    final likeRef = postRef.collection('likes').doc(currentUser.uid);

    try {
      final likeSnap = await likeRef.get();
      final isCurrentlyLiked = likeSnap.exists || _isLiked[index];
      if (isCurrentlyLiked) {
        // Unlike
        final batch = _firestore.batch();
        batch.delete(likeRef);
        batch.update(postRef, {'reactions': FieldValue.increment(-1)});
        await batch.commit();

        // Best-effort: remove existing like notification
        try {
          final notifQuery = await _firestore
              .collection('notifications')
              .where('type', isEqualTo: 'like')
              .where('postId', isEqualTo: post.postId)
              .where('actorId', isEqualTo: currentUser.uid)
              .where('userId', isEqualTo: post.userId)
              .limit(1)
              .get();
          if (notifQuery.docs.isNotEmpty) {
            await notifQuery.docs.first.reference.delete();
          }
        } catch (_) {}

        setState(() {
          _isLiked[index] = false;
        });
      } else {
        // Like
        final batch = _firestore.batch();
        batch.set(likeRef, {
          'userId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.update(postRef, {'reactions': FieldValue.increment(1)});
        await batch.commit();

        // Create notification for post owner (avoid self-like notifications)
        if (currentUser.uid != post.userId) {
          String actorName = currentUser.displayName ?? 'Someone';
          try {
            final actorDoc = await _firestore
                .collection('users')
                .doc(currentUser.uid)
                .get();
            final data = actorDoc.data();
            if (data != null &&
                (data['name'] as String?)?.trim().isNotEmpty == true) {
              actorName = (data['name'] as String).trim();
            }
          } catch (_) {}

          await _firestore.collection('notifications').add({
            'userId': post.userId, // recipient (post owner)
            'type': 'like',
            'postId': post.postId,
            'actorId': currentUser.uid,
            'actorName': actorName,
            'message': '$actorName liked your post',
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }

        setState(() {
          _isLiked[index] = true;
        });
      }
    } on FirebaseException catch (e) {
      final code = e.code;
      final msg = e.message ?? e.toString();
      debugPrint('Like error [$code]: $msg');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating like: $msg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Like error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating like: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditPostDialog(_CommunityPost post, int index) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != post.userId) return;

    final TextEditingController textController = TextEditingController(
      text: post.message,
    );
    XFile? pickedImage;
    Uint8List? imageBytes;
    bool isUploading = false;
    bool removeImage = false;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Update your post...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        try {
                          final image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            if (kIsWeb) {
                              final bytes = await image.readAsBytes();
                              setDialogState(() {
                                pickedImage = image;
                                imageBytes = bytes;
                                removeImage = false;
                              });
                            } else {
                              setDialogState(() {
                                pickedImage = image;
                                removeImage = false;
                              });
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error picking image: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          color: Colors.grey[50],
                        ),
                        child: Builder(
                          builder: (context) {
                            final hasExisting =
                                post.imageUrl != null &&
                                post.imageUrl!.isNotEmpty;
                            if (pickedImage != null || imageBytes != null) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: kIsWeb
                                    ? Image.memory(
                                        imageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(pickedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                              );
                            } else if (hasExisting && !removeImage) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  post.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add or replace image',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: removeImage,
                          onChanged: (v) {
                            setDialogState(() {
                              removeImage = v ?? false;
                              if (removeImage) {
                                pickedImage = null;
                                imageBytes = null;
                              }
                            });
                          },
                        ),
                        const Text('Remove image'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isUploading
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final newText = textController.text.trim();
                                  if (newText.isEmpty &&
                                      !(pickedImage != null ||
                                          imageBytes != null) &&
                                      !(removeImage)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please add text or keep an image',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setDialogState(() => isUploading = true);
                                  try {
                                    final postRef = _firestore
                                        .collection('community_posts')
                                        .doc(post.postId);
                                    String? newImageUrl = post.imageUrl;

                                    // Handle image removal or replacement
                                    if (removeImage) {
                                      // delete old image if exists
                                      if (post.imageUrl != null &&
                                          post.imageUrl!.isNotEmpty) {
                                        try {
                                          final uri = Uri.parse(post.imageUrl!);
                                          if (uri.path.contains('/o/')) {
                                            final pathMatch = RegExp(
                                              r'/o/([^?]+)',
                                            ).firstMatch(uri.path);
                                            if (pathMatch != null) {
                                              final encodedPath = pathMatch
                                                  .group(1)!;
                                              final decodedPath =
                                                  Uri.decodeComponent(
                                                    encodedPath,
                                                  );
                                              final imageRef = _storage.ref(
                                                decodedPath,
                                              );
                                              await imageRef.delete();
                                            }
                                          }
                                        } catch (_) {}
                                      }
                                      newImageUrl = null;
                                    } else if (pickedImage != null ||
                                        imageBytes != null) {
                                      // upload new image and delete old
                                      if (post.imageUrl != null &&
                                          post.imageUrl!.isNotEmpty) {
                                        try {
                                          final uri = Uri.parse(post.imageUrl!);
                                          if (uri.path.contains('/o/')) {
                                            final pathMatch = RegExp(
                                              r'/o/([^?]+)',
                                            ).firstMatch(uri.path);
                                            if (pathMatch != null) {
                                              final encodedPath = pathMatch
                                                  .group(1)!;
                                              final decodedPath =
                                                  Uri.decodeComponent(
                                                    encodedPath,
                                                  );
                                              final imageRef = _storage.ref(
                                                decodedPath,
                                              );
                                              await imageRef.delete();
                                            }
                                          }
                                        } catch (_) {}
                                      }
                                      final timestamp =
                                          DateTime.now().millisecondsSinceEpoch;
                                      final storagePath =
                                          'community_posts/${post.userId}/$timestamp.jpg';
                                      final storageRef = _storage.ref(
                                        storagePath,
                                      );
                                      UploadTask uploadTask;
                                      if (imageBytes != null) {
                                        uploadTask = storageRef.putData(
                                          imageBytes!,
                                          SettableMetadata(
                                            contentType: 'image/jpeg',
                                          ),
                                        );
                                      } else {
                                        uploadTask = storageRef.putFile(
                                          File(pickedImage!.path),
                                          SettableMetadata(
                                            contentType: 'image/jpeg',
                                          ),
                                        );
                                      }
                                      final snapshot = await uploadTask
                                          .whenComplete(() {});
                                      newImageUrl = await snapshot.ref
                                          .getDownloadURL();
                                    }

                                    await postRef.update({
                                      'message': newText,
                                      'imageUrl': newImageUrl,
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    });

                                    // Update local list to reflect changes immediately
                                    setState(() {
                                      _posts[index] = _CommunityPost(
                                        postId: post.postId,
                                        userId: post.userId,
                                        userName: post.userName,
                                        userAvatar: post.userAvatar,
                                        message: newText,
                                        timestamp: post.timestamp,
                                        reactions: post.reactions,
                                        comments: post.comments,
                                        shares: post.shares,
                                        imageUrl: newImageUrl,
                                      );
                                    });

                                    if (mounted) {
                                      Navigator.of(dialogContext).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Post updated successfully',
                                          ),
                                          backgroundColor: _headerGreen,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => isUploading = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error updating post: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _headerGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadPosts() async {
    try {
      final postsSnapshot = await _firestore
          .collection('community_posts')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      final loadedPosts = postsSnapshot.docs.map((doc) {
        final data = doc.data();
        return _CommunityPost.fromFirestore(data, doc.id);
      }).toList();

      // Set posts first so they display immediately
      setState(() {
        _posts = loadedPosts;
        _isLiked.clear();
        _isLiked.addAll(List<bool>.filled(_posts.length, false));
      });

      // Load like state for current user so hearts persist across sessions
      await _loadLikeStatesForCurrentUser();

      // Load profile images for all unique users in the background
      final userIds = loadedPosts.map((post) => post.userId).toSet();
      for (final userId in userIds) {
        _loadUserProfileImage(userId); // Load asynchronously without waiting
      }
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  Future<void> _loadLikeStatesForCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _posts.isEmpty) return;

    // Build quick lookup for indices by postId to avoid race conditions
    final Map<String, int> postIdToIndex = {};
    for (var i = 0; i < _posts.length; i++) {
      postIdToIndex[_posts[i].postId] = i;
    }

    try {
      final futures = _posts.map((post) async {
        try {
          final likeDoc = await _firestore
              .collection('community_posts')
              .doc(post.postId)
              .collection('likes')
              .doc(currentUser.uid)
              .get();
          final index = postIdToIndex[post.postId];
          if (!mounted || index == null) return;
          if (likeDoc.exists) {
            setState(() {
              // Guard against length changes
              if (index < _isLiked.length) {
                _isLiked[index] = true;
              }
            });
          }
        } catch (_) {
          // Ignore per-post errors to keep UI responsive
        }
      }).toList();
      await Future.wait(futures);
    } catch (e) {
      // Non-fatal
      debugPrint('Error loading like states: $e');
    }
  }

  Future<void> _loadUserProfileImage(String userId) async {
    if (_userProfileImages.containsKey(userId)) {
      return; // Already loaded or attempted
    }

    try {
      // Mark as loading to prevent multiple requests
      _userProfileImages[userId] = '';

      final profileImageRef = _storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child('profile.jpg');
      final url = await profileImageRef.getDownloadURL();

      if (mounted) {
        setState(() {
          _userProfileImages[userId] = url;
          print('✅ Profile image loaded for user $userId');
        });
      }
    } catch (e) {
      // Try any file in the folder as a fallback
      try {
        final folderRef = _storage.ref().child('profile_images').child(userId);
        final listResult = await folderRef.listAll();
        if (listResult.items.isNotEmpty) {
          final anyUrl = await listResult.items.first.getDownloadURL();
          if (mounted) {
            setState(() {
              _userProfileImages[userId] = anyUrl;
            });
          }
          return;
        }
      } catch (_) {}

      // Mark as not found; UI will fallback to default/avatar URL
      if (mounted) {
        setState(() {
          _userProfileImages[userId] = '';
        });
      }
    }
  }

  String _getUserAvatarUrl(_CommunityPost post) {
    // First check if we have a profile image from storage (and it's not empty)
    if (_userProfileImages.containsKey(post.userId) &&
        _userProfileImages[post.userId]!.isNotEmpty) {
      return _userProfileImages[post.userId]!;
    }
    // Then check if userAvatar is already a URL (from Firestore)
    if (post.userAvatar.startsWith('http')) {
      return post.userAvatar;
    }
    // Fallback to default asset
    return 'assets/pet_images/luna.png';
  }

  Future<void> _showCreatePostDialog() async {
    final TextEditingController textController = TextEditingController();
    XFile? pickedImage;
    Uint8List? imageBytes;
    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    const Text(
                      'Create Post',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Text input
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Image selection area
                    GestureDetector(
                      onTap: () async {
                        try {
                          final image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                          );
                          if (image != null) {
                            if (kIsWeb) {
                              final bytes = await image.readAsBytes();
                              setDialogState(() {
                                pickedImage = image;
                                imageBytes = bytes;
                              });
                            } else {
                              setDialogState(() {
                                pickedImage = image;
                              });
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error picking image: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          color: Colors.grey[50],
                        ),
                        child: pickedImage != null || imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    kIsWeb
                                        ? Image.memory(
                                            imageBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(pickedImage!.path),
                                            fit: BoxFit.cover,
                                          ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                        ),
                                        onPressed: () {
                                          setDialogState(() {
                                            pickedImage = null;
                                            imageBytes = null;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No image selected. Tap to add an image',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isUploading
                              ? null
                              : () {
                                  Navigator.of(dialogContext).pop();
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final text = textController.text.trim();
                                  if (text.isEmpty && pickedImage == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter text or add an image',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    isUploading = true;
                                  });

                                  try {
                                    final user = _auth.currentUser;
                                    if (user == null) {
                                      throw Exception('User not logged in');
                                    }

                                    // Fetch user profile from Firestore for accurate name/avatar
                                    String displayName =
                                        user.displayName ?? 'Anonymous';
                                    String? avatarUrl = user.photoURL;
                                    try {
                                      final userDoc = await _firestore
                                          .collection('users')
                                          .doc(user.uid)
                                          .get();
                                      final data = userDoc.data();
                                      if (data != null) {
                                        if ((data['name'] as String?)
                                                ?.trim()
                                                .isNotEmpty ==
                                            true) {
                                          displayName = (data['name'] as String)
                                              .trim();
                                        }
                                        final fsProfileUrl =
                                            data['profileImageUrl'] as String?;
                                        if (fsProfileUrl != null &&
                                            fsProfileUrl.trim().isNotEmpty) {
                                          avatarUrl = fsProfileUrl.trim();
                                        }
                                      }
                                    } catch (_) {
                                      // ignore and use auth fallback
                                    }

                                    String? imageUrl;
                                    if (pickedImage != null ||
                                        imageBytes != null) {
                                      final timestamp =
                                          DateTime.now().millisecondsSinceEpoch;
                                      final storagePath =
                                          'community_posts/${user.uid}/$timestamp.jpg';
                                      final storageRef = FirebaseStorage
                                          .instance
                                          .ref(storagePath);

                                      UploadTask uploadTask;
                                      if (imageBytes != null) {
                                        uploadTask = storageRef.putData(
                                          imageBytes!,
                                          SettableMetadata(
                                            contentType: 'image/jpeg',
                                          ),
                                        );
                                      } else {
                                        uploadTask = storageRef.putFile(
                                          File(pickedImage!.path),
                                          SettableMetadata(
                                            contentType: 'image/jpeg',
                                          ),
                                        );
                                      }

                                      final snapshot = await uploadTask
                                          .whenComplete(() {});
                                      imageUrl = await snapshot.ref
                                          .getDownloadURL();
                                    }

                                    await _firestore
                                        .collection('community_posts')
                                        .add({
                                          'userId': user.uid,
                                          'userName': displayName,
                                          // Save a best-effort avatar URL; UI still prefers Storage image if present
                                          'userAvatar':
                                              avatarUrl ??
                                              'assets/pet_images/luna.png',
                                          'message': text,
                                          'imageUrl': imageUrl,
                                          'timestamp':
                                              FieldValue.serverTimestamp(),
                                          'reactions': 0,
                                          'comments': 0,
                                          'shares': 0,
                                        });

                                    if (mounted) {
                                      Navigator.of(dialogContext).pop();
                                      _loadPosts();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Post created successfully!',
                                          ),
                                          backgroundColor: _headerGreen,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() {
                                      isUploading = false;
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error creating post: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _headerGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Post'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

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
          _buildHeader(context, user),
          const SizedBox(height: 16),
          if (_posts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(
                child: Text(
                  'No posts yet. Be the first to share!',
                  style: TextStyle(color: _textMuted),
                ),
              ),
            ),
          for (var i = 0; i < _posts.length; i++) ...[
            _buildPostCard(context, _posts[i], i),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile picture with green border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _headerGreen, width: 2),
            ),
            child: ClipOval(
              child: (_profileImageUrl != null || user?.photoURL != null)
                  ? Image.network(
                      _profileImageUrl ?? user!.photoURL!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/pet_images/luna.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/pet_images/luna.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Text input field
          Expanded(
            child: GestureDetector(
              onTap: _showCreatePostDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "What's on your mind?",
                  style: TextStyle(color: _headerGreen, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Image upload icon
          GestureDetector(
            onTap: _showCreatePostDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/add_post.png',
                width: 24,
                height: 24,
                color: _headerGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, _CommunityPost post, int index) {
    if (index >= _isLiked.length) {
      _isLiked.add(false);
    }
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
                  // Profile picture with border
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _headerGreen, width: 2),
                    ),
                    child: ClipOval(
                      child: Builder(
                        builder: (context) {
                          final avatarUrl = _getUserAvatarUrl(post);

                          if (avatarUrl.startsWith('http')) {
                            return Image.network(
                              avatarUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 44,
                                      height: 44,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                _headerGreen,
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/pet_images/luna.png',
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                );
                              },
                            );
                          } else {
                            return Image.asset(
                              avatarUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ),
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: _textMuted),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirmation(context, post, index);
                      } else if (value == 'edit') {
                        _showEditPostDialog(post, index);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      final user = _auth.currentUser;
                      // Only show delete option if user is the post owner
                      if (user != null && post.userId == user.uid) {
                        return [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: _headerGreen),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ];
                      }
                      return [];
                    },
                  ),
                ],
              ),
            ),
            if (post.message.isNotEmpty) ...[
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
            ],
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 280,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 280,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _headerGreen,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 280,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ],
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
                    onTap: () => _toggleLike(post, index),
                  ),
                  _PostActionButton(
                    asset: 'assets/comment.png',
                    label: post.comments.toString(),
                    onTap: () => _showCommentsSheet(post),
                  ),
                  _PostActionButton(
                    asset: 'assets/share_button.png',
                    label: post.shares.toString(),
                    onTap: () {},
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
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
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.message,
    required this.timestamp,
    required this.reactions,
    required this.comments,
    required this.shares,
    this.imageUrl,
  });

  final String postId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String message;
  final DateTime timestamp;
  final int reactions;
  final int comments;
  final int shares;
  final String? imageUrl;

  factory _CommunityPost.fromFirestore(Map<String, dynamic> data, String id) {
    return _CommunityPost(
      postId: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userAvatar: data['userAvatar'] ?? 'assets/pet_images/luna.png',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: data['reactions'] ?? 0,
      comments: data['comments'] ?? 0,
      shares: data['shares'] ?? 0,
      imageUrl: data['imageUrl'],
    );
  }
}
