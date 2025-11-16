// lib/view_all_notes.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fureverhealthy/recent_notes.dart';
import 'package:intl/intl.dart';

const _mint = Color(0xFF6F994A);
const _screenBg = Color(0xFFF6F8FB);

class ViewAllNotesPage extends StatefulWidget {
  final String? petName;

  const ViewAllNotesPage({super.key, this.petName});

  @override
  State<ViewAllNotesPage> createState() => _ViewAllNotesPageState();
}

class _ViewAllNotesPageState extends State<ViewAllNotesPage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: _screenBg,
        appBar: AppBar(
          backgroundColor: _mint,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'All Notes',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
        body: const Center(child: Text('Please log in to view notes')),
      );
    }

    return Scaffold(
      backgroundColor: _screenBg,
      appBar: AppBar(
        backgroundColor: _mint,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Notes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RecentNotesPage(initialPetName: widget.petName),
                ),
              );
              if (result == true) {
                setState(() {}); // Refresh the list
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.petName != null
            ? FirebaseFirestore.instance
                  .collection('petNotes')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots()
            : FirebaseFirestore.instance
                  .collection('petNotes')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/recent_notes.png',
                    width: 80,
                    height: 80,
                    color: _mint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.petName != null
                        ? 'No notes for ${widget.petName} yet.'
                        : 'No notes yet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RecentNotesPage(initialPetName: widget.petName),
                        ),
                      );
                      if (result == true) {
                        setState(() {}); // Refresh the list
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mint,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Add Note',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter notes by pet name if specified
          final petNameTrimmed = widget.petName?.trim().toLowerCase();
          final allNotes = snapshot.data!.docs.where((doc) {
            if (petNameTrimmed == null || petNameTrimmed.isEmpty) {
              return true;
            }
            final data = doc.data() as Map<String, dynamic>;
            final notePetName = (data['petName'] as String?)?.trim() ?? '';
            return notePetName.toLowerCase() == petNameTrimmed;
          }).toList();

          // Sort by dateTime descending (or createdAt as fallback)
          allNotes.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            // Try dateTime first, then createdAt as fallback
            Timestamp? aTime = aData['dateTime'] as Timestamp?;
            Timestamp? bTime = bData['dateTime'] as Timestamp?;

            if (aTime == null) {
              aTime = aData['createdAt'] as Timestamp?;
            }
            if (bTime == null) {
              bTime = bData['createdAt'] as Timestamp?;
            }

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Descending order
          });

          if (allNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/recent_notes.png',
                    width: 80,
                    height: 80,
                    color: _mint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.petName != null
                        ? 'No notes for ${widget.petName} yet.'
                        : 'No notes yet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RecentNotesPage(initialPetName: widget.petName),
                        ),
                      );
                      if (result == true) {
                        setState(() {}); // Refresh the list
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mint,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Add Note',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allNotes.length,
            itemBuilder: (context, index) {
              final noteDoc = allNotes[index];
              final noteData = noteDoc.data() as Map<String, dynamic>;
              final noteId = noteDoc.id;
              final content = noteData['content'] as String? ?? '';
              final dateTime = noteData['dateTime'] as Timestamp?;
              final petName = noteData['petName'] as String? ?? '';
              final noteType = noteData['noteType'] as String? ?? 'General';
              final activityType = noteData['activityType'] as String?;

              return GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecentNotesPage(
                        initialPetName: petName,
                        noteId: noteId,
                      ),
                    ),
                  );
                  if (result == true) {
                    setState(() {}); // Refresh the list
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6F994A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.note,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (dateTime != null)
                              Text(
                                DateFormat(
                                  'd MMM, h:mm a',
                                ).format(dateTime.toDate()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            if (dateTime != null) const SizedBox(height: 4),
                            Text(
                              content.isNotEmpty ? content : 'No content',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (noteType.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _mint.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      noteType == 'Activity' &&
                                              activityType != null &&
                                              activityType.isNotEmpty
                                          ? 'Activity: $activityType'
                                          : noteType,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _mint,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (noteType.isNotEmpty && petName.isNotEmpty)
                                  const SizedBox(width: 8),
                                if (petName.isNotEmpty)
                                  Text(
                                    petName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecentNotesPage(initialPetName: widget.petName),
            ),
          );
          if (result == true) {
            setState(() {}); // Refresh the list
          }
        },
        backgroundColor: _mint,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
