import 'package:flutter/material.dart';
import 'package:fureverhealthy/book_appointment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fureverhealthy/utils/vet_services_parser.dart';
import 'package:flutter/foundation.dart';

const _mint = Color(0xFF6F994A);
const _mintDark = Color(0xFF112F15);
const _mintLight = Color(0xFFE8F0D6); // Light mint background
const _mintVeryLight = Color(0xFFF0F7E8); // Very light mint for subtle backgrounds

class VetProfilePage extends StatefulWidget {
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
  State<VetProfilePage> createState() => _VetProfilePageState();
}

class _VetProfilePageState extends State<VetProfilePage> {
  int? selectedRatingFilter; // null means "All", otherwise 1-5 for specific rating

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mintVeryLight,
      body: CustomScrollView(
        slivers: [
          // Header with profile picture - minimal design
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture floating above content
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('vets')
                      .doc(widget.vetId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String? profileImageUrl;
                    
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final vetData = snapshot.data!.data() as Map<String, dynamic>;
                      profileImageUrl = vetData['profileImageUrl'] as String?;
                    }
                    
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 20, bottom: 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 66,
                            backgroundColor: _mintLight,
                            child: ClipOval(
                              child: SizedBox(
                                width: 132,
                                height: 132,
                                child: profileImageUrl != null && profileImageUrl.isNotEmpty
                                    ? Image.network(
                                        profileImageUrl,
                                        width: 132,
                                        height: 132,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/vet_doctor.png',
                                            width: 132,
                                            height: 132,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        'assets/vet_doctor.png',
                                        width: 132,
                                        height: 132,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // White card with name, location, rating
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('vets')
                          .doc(widget.vetId)
                          .snapshots(),
                      builder: (context, vetSnapshot) {
                        String displayName = widget.vetName;
                        String displayLocation = widget.vetLocation;
                        String displaySpecialty = widget.vetSpecialty;
                        int displayRating = widget.vetRating;
                        String? profileImageUrl;
                        int reviewCount = 0;

                        if (vetSnapshot.hasData && vetSnapshot.data!.exists) {
                          final vetData =
                              vetSnapshot.data!.data() as Map<String, dynamic>;
                          // Get name - try multiple field names
                          final nameFromData = vetData['name'] as String? ??
                              vetData['displayName'] as String? ??
                              vetData['vetName'] as String? ??
                              vetData['fullName'] as String?;
                          displayName = nameFromData?.isNotEmpty == true ? nameFromData! : widget.vetName;
                          
                          displayLocation =
                              vetData['location'] as String? ?? widget.vetLocation;
                          displaySpecialty =
                              vetData['specialization'] as String? ??
                              vetData['specialty'] as String? ??
                              widget.vetSpecialty;
                          displayRating =
                              (vetData['rating'] as num?)?.toInt() ?? widget.vetRating;
                          profileImageUrl = vetData['profileImageUrl'] as String?;
                        }

                        // Get review count and average rating
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('feedback')
                              .where('vetName', isEqualTo: displayName)
                              .snapshots(),
                          builder: (context, reviewCountSnapshot) {
                            double averageRating = displayRating.toDouble();
                            
                            if (reviewCountSnapshot.hasData) {
                              final feedbackDocs = reviewCountSnapshot.data!.docs;
                              reviewCount = feedbackDocs.length;
                              
                              // Calculate average rating from feedback
                              if (reviewCount > 0) {
                                int totalRating = 0;
                                int ratingCount = 0;
                                
                                for (var doc in feedbackDocs) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final rating = data['rating'] as int?;
                                  if (rating != null && rating > 0) {
                                    totalRating += rating;
                                    ratingCount++;
                                  }
                                }
                                
                                if (ratingCount > 0) {
                                  averageRating = totalRating / ratingCount;
                                }
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Vet Name - displayed above specialization
                                // Always show the name if it exists
                                if (displayName.isNotEmpty)
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                if (displayName.isNotEmpty)
                                  const SizedBox(height: 12),
                                // Specialization
                                Text(
                                  displaySpecialty.isNotEmpty ? displaySpecialty : 'General',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
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
                                      '${averageRating.toStringAsFixed(1)} ($reviewCount)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Services Offered button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () => _showServicesOffered(context, widget.vetId, displayName),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _mint,
                                      side: const BorderSide(color: _mint),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Services Offered',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                                                vetId: widget.vetId,
                                                vetName: displayName,
                                                vetSpecialty: displaySpecialty,
                                                vetRating: displayRating,
                                                vetStatus: 'Available',
                                                profileImageUrl: profileImageUrl,
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
                const SizedBox(height: 8),
                // Portfolio section
                _buildPortfolioSection(),
                const SizedBox(height: 8),
                // Recent reviews section
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent reviews',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Rating filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildRatingFilterChip('All', null),
                            const SizedBox(width: 8),
                            _buildRatingFilterChip('5 Stars', 5),
                            const SizedBox(width: 8),
                            _buildRatingFilterChip('4 Stars', 4),
                            const SizedBox(width: 8),
                            _buildRatingFilterChip('3 Stars', 3),
                            const SizedBox(width: 8),
                            _buildRatingFilterChip('2 Stars', 2),
                            const SizedBox(width: 8),
                            _buildRatingFilterChip('1 Star', 1),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('vets')
                            .doc(widget.vetId)
                            .snapshots(),
                        builder: (context, vetSnapshot) {
                          String vetNameForQuery = widget.vetName;
                          if (vetSnapshot.hasData && vetSnapshot.data!.exists) {
                            final vetData =
                                vetSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            vetNameForQuery =
                                vetData['name'] as String? ??
                                vetData['displayName'] as String? ??
                                widget.vetName;
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

                              // Filter by rating if selected
                              List<QueryDocumentSnapshot> filteredReviews = reviews;
                              if (selectedRatingFilter != null) {
                                filteredReviews = reviews.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final rating = data['rating'] as int? ?? 0;
                                  return rating == selectedRatingFilter;
                                }).toList();
                              }

                              // Limit to 10 most recent
                              final limitedReviews = filteredReviews.take(10).toList();

                              if (limitedReviews.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      selectedRatingFilter != null
                                          ? 'No ${selectedRatingFilter}-star reviews yet.'
                                          : 'No reviews yet.',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }

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

  Widget _buildPortfolioSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vets')
          .doc(widget.vetId)
          .snapshots(),
      builder: (context, vetSnapshot) {
        if (!vetSnapshot.hasData || !vetSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final vetData = vetSnapshot.data!.data() as Map<String, dynamic>;
        
        // Get portfolio data - it's a Map with awards, bio, certifications
        final portfolioRaw = vetData['portfolio'];
        if (portfolioRaw == null || portfolioRaw is! Map) {
          return const SizedBox.shrink();
        }

        final portfolio = portfolioRaw as Map<String, dynamic>;
        
        // Extract portfolio fields
        final bio = portfolio['bio'] as String?;
        final awardsRaw = portfolio['awards'];
        final certificationsRaw = portfolio['certifications'];
        final educationRaw = portfolio['education'];
        final experienceRaw = portfolio['experience'];
        final languagesRaw = portfolio['languages'];
        final membershipsRaw = portfolio['memberships'];
        final publicationsRaw = portfolio['publications'];
        
        // Safely extract awards
        List<Map<String, dynamic>> awards = [];
        if (awardsRaw is List) {
          awards = awardsRaw.map((award) {
            if (award is Map) {
              return Map<String, dynamic>.from(award);
            }
            return <String, dynamic>{};
          }).toList();
        }
        
        // Safely extract certifications
        List<Map<String, dynamic>> certifications = [];
        if (certificationsRaw is List) {
          certifications = certificationsRaw.map((cert) {
            if (cert is Map) {
              return Map<String, dynamic>.from(cert);
            }
            return <String, dynamic>{};
          }).toList();
        }
        
        // Safely extract education
        List<Map<String, dynamic>> education = [];
        if (educationRaw is List) {
          education = educationRaw.map((edu) {
            if (edu is Map) {
              return Map<String, dynamic>.from(edu);
            }
            return <String, dynamic>{};
          }).toList();
        }
        
        // Safely extract experience
        List<Map<String, dynamic>> experience = [];
        if (experienceRaw is List) {
          experience = experienceRaw.map((exp) {
            if (exp is Map) {
              return Map<String, dynamic>.from(exp);
            }
            return <String, dynamic>{};
          }).toList();
        }
        
        // Safely extract languages
        List<String> languages = [];
        if (languagesRaw is List) {
          languages = languagesRaw.map((lang) {
            if (lang is String) {
              return lang;
            }
            return lang.toString();
          }).toList();
        }
        
        // Safely extract memberships
        List<Map<String, dynamic>> memberships = [];
        if (membershipsRaw is List) {
          memberships = membershipsRaw.map((mem) {
            if (mem is Map) {
              return Map<String, dynamic>.from(mem);
            }
            return <String, dynamic>{};
          }).toList();
        }
        
        // Safely extract publications
        List<Map<String, dynamic>> publications = [];
        if (publicationsRaw is List) {
          publications = publicationsRaw.map((pub) {
            if (pub is Map) {
              return Map<String, dynamic>.from(pub);
            }
            return <String, dynamic>{};
          }).toList();
        }
        
        // Only show portfolio section if there's any data
        if ((bio == null || bio.isEmpty) && 
            awards.isEmpty && 
            certifications.isEmpty &&
            education.isEmpty &&
            experience.isEmpty &&
            languages.isEmpty &&
            memberships.isEmpty &&
            publications.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bio Section
              if (bio != null && bio.isNotEmpty) ...[
                _buildPortfolioSectionTitle('About'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _mintVeryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    bio,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // Awards Section
              if (awards.isNotEmpty) ...[
                _buildPortfolioSectionTitle('Awards'),
                const SizedBox(height: 12),
                ...awards.map((award) => _buildAwardCard(award)),
                const SizedBox(height: 20),
              ],
              
              // Certifications Section
              if (certifications.isNotEmpty) ...[
                _buildPortfolioSectionTitle('Certifications'),
                const SizedBox(height: 12),
                ...certifications.map((cert) => _buildCertificationCard(cert)),
                const SizedBox(height: 20),
              ],
              
              // Education Section
              if (education.isNotEmpty) ...[
                _buildPortfolioSectionTitle('Education'),
                const SizedBox(height: 12),
                ...education.map((edu) => _buildEducationCard(edu)),
                const SizedBox(height: 20),
              ],
              
              // Experience Section
              if (experience.isNotEmpty) ...[
                _buildPortfolioSectionTitle('Experience'),
                const SizedBox(height: 12),
                ...experience.map((exp) => _buildExperienceCard(exp)),
                const SizedBox(height: 20),
              ],
              
              // Memberships Section
              if (memberships.isNotEmpty) ...[
                _buildPortfolioSectionTitle('Memberships'),
                const SizedBox(height: 12),
                ...memberships.map((mem) => _buildMembershipCard(mem)),
                const SizedBox(height: 20),
              ],
              
              // Publications Section
              if (publications.isNotEmpty) ...[
                _buildPortfolioSectionTitle('Publications'),
                const SizedBox(height: 12),
                ...publications.map((pub) => _buildPublicationCard(pub)),
                const SizedBox(height: 20),
              ],
              
              // Languages Section (moved to bottom)
              if (languages.isNotEmpty) ...[
                _buildPortfolioSectionTitle('Languages'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: languages.map((lang) => _buildLanguageChip(lang)).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortfolioSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _mintDark,
      ),
    );
  }

  Widget _buildAwardCard(Map<String, dynamic> award) {
    final title = award['title'] as String? ?? '';
    final organization = award['organization'] as String? ?? '';
    final year = award['year'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mintLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: _mint,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                if (organization.isNotEmpty) ...[
                  if (title.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    organization,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (year.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    year,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationCard(Map<String, dynamic> cert) {
    final name = cert['name'] as String? ?? '';
    final issuer = cert['issuer'] as String? ?? '';
    final year = cert['year'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mintLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified,
              color: _mint,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                if (issuer.isNotEmpty) ...[
                  if (name.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    issuer,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (year.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    year,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(Map<String, dynamic> edu) {
    final degree = edu['degree'] as String? ?? '';
    final institution = edu['institution'] as String? ?? '';
    final year = edu['year'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mintLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.school,
              color: _mint,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (degree.isNotEmpty)
                  Text(
                    degree,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                if (institution.isNotEmpty) ...[
                  if (degree.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    institution,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (year.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    year,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(Map<String, dynamic> exp) {
    final position = exp['position'] as String? ?? '';
    final organization = exp['organization'] as String? ?? '';
    final years = exp['years'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mintLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.work,
              color: _mint,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (position.isNotEmpty)
                  Text(
                    position,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                if (organization.isNotEmpty) ...[
                  if (position.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    organization,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (years.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    years,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(String language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _mintLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _mint.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.language,
            color: _mint,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            language,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _mintDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(Map<String, dynamic> mem) {
    final role = mem['role'] as String? ?? '';
    final organization = mem['organization'] as String? ?? '';
    final year = mem['year'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mintLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.group,
              color: _mint,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (role.isNotEmpty)
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                if (organization.isNotEmpty) ...[
                  if (role.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    organization,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (year.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    year,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicationCard(Map<String, dynamic> pub) {
    final title = pub['title'] as String? ?? '';
    final journal = pub['journal'] as String? ?? '';
    final year = pub['year'] as String? ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mintLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.article,
              color: _mint,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                if (journal.isNotEmpty) ...[
                  if (title.isNotEmpty) const SizedBox(height: 4),
                  Text(
                    journal,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (year.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    year,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fetch vet services with multiple fallback methods
  static Future<List<Map<String, dynamic>>> _fetchVetServicesWithFallback(String vetId) async {
    // Try the utility method first
    var services = await VetServicesParser.fetchVetServices(vetId);
    
    if (services.isNotEmpty) {
      return services;
    }
    
    // If not found, try direct document fetch with multiple formats
    try {
      // Try vet_rates_{vetId}
      var doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('vet_rates_$vetId')
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return VetServicesParser.parseVetRatesDocument(data);
      }
      
      // Try querying by vetId field
      final querySnapshot = await FirebaseFirestore.instance
          .collection('app_settings')
          .where('vetId', isEqualTo: vetId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return VetServicesParser.parseVetRatesDocument(data);
      }
      
      // Try just vetId as document ID
      doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc(vetId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return VetServicesParser.parseVetRatesDocument(data);
      }
    } catch (e) {
      debugPrint('Error fetching vet services: $e');
    }
    
    return [];
  }

  /// Show services offered dialog
  static void _showServicesOffered(BuildContext context, String vetId, String vetName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Services Offered',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchVetServicesWithFallback(vetId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: _mint),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Error loading services: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No services information available.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    final allServices = snapshot.data!;

                    if (allServices.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No services available.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: allServices.length,
                      itemBuilder: (context, index) {
                        final service = allServices[index];
                        final label = service['label'] as String? ?? 'Unknown Service';
                        final price = (service['price'] as num?)?.toInt() ?? 0;
                        final description = service['description'] as String? ?? 
                                          service['desc'] as String?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'PHP $price',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _mint,
                                    ),
                                  ),
                                ],
                              ),
                              if (description != null && description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildRatingFilterChip(String label, int? rating) {
    final isSelected = selectedRatingFilter == rating;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rating != null) ...[
            ...List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.amber,
                ),
              );
            }),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedRatingFilter = selected ? rating : null;
        });
      },
      selectedColor: _mint,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? _mint : Colors.grey.shade300,
          width: isSelected ? 1.5 : 1,
        ),
      ),
    );
  }
}
