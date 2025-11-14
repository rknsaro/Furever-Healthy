import 'package:flutter/material.dart';
import 'package:fureverhealthy/book_appointment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);

class VetProfilePage extends StatelessWidget {
  final String vetId;
  final String vetName;
  final String vetSpecialty;
  final int vetRating;
  final String vetLocation;

  const VetProfilePage({
    super.key,
    required this.vetId,
    required this.vetName,
    required this.vetSpecialty,
    required this.vetRating,
    required this.vetLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with profile picture
          SliverAppBar(
            expandedHeight: 300,
            pinned: false,
            backgroundColor: _mintDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(color: _mintDark),
                child: Center(
                  child: Image.asset(
                    'assets/vet_doctor.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // White card with name, location, rating - using Transform to overlap
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('vets')
                          .doc(vetId)
                          .snapshots(),
                      builder: (context, vetSnapshot) {
                        String displayName = vetName;
                        String displayLocation = vetLocation;
                        int displayRating = vetRating;
                        int reviewCount = 0;

                        if (vetSnapshot.hasData && vetSnapshot.data!.exists) {
                          final vetData =
                              vetSnapshot.data!.data() as Map<String, dynamic>;
                          displayName =
                              vetData['name'] as String? ??
                              vetData['displayName'] as String? ??
                              vetName;
                          displayLocation =
                              vetData['location'] as String? ?? vetLocation;
                          displayRating =
                              (vetData['rating'] as num?)?.toInt() ?? vetRating;
                        }

                        // Get review count
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('feedback')
                              .where('vetName', isEqualTo: displayName)
                              .snapshots(),
                          builder: (context, reviewCountSnapshot) {
                            if (reviewCountSnapshot.hasData) {
                              reviewCount =
                                  reviewCountSnapshot.data!.docs.length;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      displayLocation,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$displayRating ($reviewCount)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Action button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BookAppointmentPage(
                                                vetId: vetId,
                                                vetName: displayName,
                                                vetSpecialty: vetSpecialty,
                                                vetRating: displayRating,
                                                vetStatus: 'Available',
                                              ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _mint,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Book Appointment',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Recent reviews section
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent reviews',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('vets')
                            .doc(vetId)
                            .snapshots(),
                        builder: (context, vetSnapshot) {
                          String vetNameForQuery = vetName;
                          if (vetSnapshot.hasData && vetSnapshot.data!.exists) {
                            final vetData =
                                vetSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            vetNameForQuery =
                                vetData['name'] as String? ??
                                vetData['displayName'] as String? ??
                                vetName;
                          }

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('feedback')
                                .where('vetName', isEqualTo: vetNameForQuery)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Text(
                                      'No reviews yet.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final reviews = snapshot.data!.docs.toList()
                                ..sort((a, b) {
                                  final aDate =
                                      (a.data() as Map<String, dynamic>)['date']
                                          as Timestamp?;
                                  final bDate =
                                      (b.data() as Map<String, dynamic>)['date']
                                          as Timestamp?;
                                  if (aDate == null && bDate == null) return 0;
                                  if (aDate == null) return 1;
                                  if (bDate == null) return -1;
                                  return bDate.compareTo(
                                    aDate,
                                  ); // Descending order
                                });

                              // Limit to 10 most recent
                              final limitedReviews = reviews.take(10).toList();

                              return Column(
                                children: limitedReviews.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final name =
                                      data['Name'] as String? ?? 'Anonymous';
                                  final feedback =
                                      data['Feedback'] as String? ?? '';
                                  final rating = data['rating'] as int? ?? 0;
                                  final date = data['date'] as Timestamp?;

                                  int daysAgo = 0;
                                  if (date != null) {
                                    final now = DateTime.now();
                                    final reviewDate = date.toDate();
                                    daysAgo = now.difference(reviewDate).inDays;
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _buildReview(
                                      name: name,
                                      avatar: 'assets/user_prof.png',
                                      review: feedback,
                                      daysAgo: daysAgo,
                                      rating: rating,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview({
    required String name,
    required String avatar,
    required String review,
    required int daysAgo,
    int rating = 5,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            avatar,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 50,
                height: 50,
                color: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.grey),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '$daysAgo Days ago',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                review,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
