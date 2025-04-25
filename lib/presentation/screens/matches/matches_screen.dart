import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../screens/profile/view_profile_screen.dart';
import '../../../data/services/firebase_service.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _firebaseService = GetIt.instance<FirebaseService>();
  final List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      // Get current user's data
      final userDoc = await _firebaseService.getUserData(currentUser.uid);
      if (userDoc == null) {
        setState(() {
          _error = 'User profile not found';
          _isLoading = false;
        });
        return;
      }

      // Get current user's location
      final locationString = userDoc['location'] as String?;
      if (locationString == null || locationString.isEmpty) {
        setState(() {
          _error = 'Location not set in profile';
          _isLoading = false;
        });
        return;
      }

      // Parse location string (assuming format: "latitude,longitude")
      final locationParts = locationString.split(',');
      if (locationParts.length != 2) {
        setState(() {
          _error = 'Invalid location format';
          _isLoading = false;
        });
        return;
      }

      final latitude = double.tryParse(locationParts[0]);
      final longitude = double.tryParse(locationParts[1]);
      if (latitude == null || longitude == null) {
        setState(() {
          _error = 'Invalid location coordinates';
          _isLoading = false;
        });
        return;
      }

      // Get potential matches with the same logic as home screen
      final potentialMatches = await _firebaseService.getPotentialMatches(
        currentUserId: currentUser.uid,
        latitude: latitude,
        longitude: longitude,
        radiusInKm: 50.0, // 50km radius
      );

      // Get current user's matches
      final querySnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: currentUser.uid)
          .get();

      final List<Map<String, dynamic>> matches = [];
      
      // For each match document
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final users = List<String>.from(data['users'] ?? []);
        final otherUserId = users.firstWhere((id) => id != currentUser.uid);
        
        // Find this user in the potential matches (to get the same data format)
        final matchingUser = potentialMatches.firstWhere(
          (match) => match['id'] == otherUserId,
          orElse: () => <String, dynamic>{},
        );
        
        // If user found in potential matches, use that data
        if (matchingUser.isNotEmpty) {
          // Calculate distance if location available
          double? calculatedDistance;
          if (matchingUser['location'] != null) {
            final otherLocationStr = matchingUser['location'].toString();
            final otherLocationParts = otherLocationStr.split(',');
            if (otherLocationParts.length == 2) {
              final otherLat = double.tryParse(otherLocationParts[0]);
              final otherLng = double.tryParse(otherLocationParts[1]);
              if (otherLat != null && otherLng != null) {
                calculatedDistance = await _firebaseService.calculateDistance(
                  latitude, longitude, otherLat, otherLng);
              }
            }
          }
          
          matches.add({
            'id': doc.id, // Match document ID
            'matchId': doc.id,
            'otherUserId': otherUserId,
            ...matchingUser,
            'matched': true,
            'calculatedDistance': calculatedDistance,
          });
        } else {
          // Otherwise get data directly (fallback)
          final otherUserData = await _firebaseService.getUserData(otherUserId);
          if (otherUserData != null) {
            final firstName = otherUserData['firstName'] ?? '';
            final lastName = otherUserData['lastName'] ?? '';
            final photoUrls = otherUserData['photoUrls'] as List<dynamic>? ?? [];
            final images = otherUserData['images'] as List<dynamic>? ?? [];
            final validImages = [...images, ...photoUrls].where((url) => url != null && url.toString().isNotEmpty).toList();
            
            // Calculate age from birthdate
            int? age;
            if (otherUserData['birthdate'] != null) {
              final birthdate = (otherUserData['birthdate'] as Timestamp).toDate();
              age = DateTime.now().year - birthdate.year;
              
              // Adjust age if birthday hasn't occurred yet this year
              final today = DateTime.now();
              final birthdayThisYear = DateTime(today.year, birthdate.month, birthdate.day);
              if (birthdayThisYear.isAfter(today)) {
                age--;
              }
            }
            
            // Calculate distance if location available
            double? calculatedDistance;
            if (otherUserData['location'] != null) {
              final otherLocationStr = otherUserData['location'].toString();
              final otherLocationParts = otherLocationStr.split(',');
              if (otherLocationParts.length == 2) {
                final otherLat = double.tryParse(otherLocationParts[0]);
                final otherLng = double.tryParse(otherLocationParts[1]);
                if (otherLat != null && otherLng != null) {
                  calculatedDistance = await _firebaseService.calculateDistance(
                    latitude, longitude, otherLat, otherLng);
                }
              }
            }
            
            matches.add({
              'id': doc.id, // Match document ID
              'matchId': doc.id,
              'otherUserId': otherUserId,
              'name': '${firstName ?? ''} ${lastName ?? ''}'.trim(),
              'isVerified': otherUserData['isVerified'] ?? false,
              'age': age ?? otherUserData['age'] ?? 0,
              'location': otherUserData['location'] ?? '',
              'bio': otherUserData['bio'] ?? '',
              'images': validImages,
              'photoUrls': validImages,
              'interests': List<String>.from(otherUserData['interests'] ?? []),
              'hobbies': List<String>.from(otherUserData['hobbies'] ?? []),
              'personality': List<String>.from(otherUserData['personality'] ?? []),
              'matched': true,
              'calculatedDistance': calculatedDistance,
            });
          }
        }
      }

      setState(() {
        _matches.clear();
        _matches.addAll(matches);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load matches: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // Custom App Bar
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 8,
              left: 20,
              right: 16,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Matches',
                  style: TextStyles.headline4Dark.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  color: Colors.white,
                  iconSize: 26,
                  onPressed: () {
                    // TODO: Show filter options
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Matches Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _matches.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadMatches,
                            child: GridView.builder(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 16,
                                bottom: 70,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _matches.length,
                              itemBuilder: (context, index) {
                                final match = _matches[index];
                                return _buildMatchCard(context, match);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match) {
    // Get the first image from the images array or use a fallback
    final List<dynamic> images = match['images'] ?? [];
    final String imageUrl = images.isNotEmpty ? images.first.toString() : '';
    
    // Format distance using pre-calculated value
    String distance = '5 km away';
    if (match['calculatedDistance'] != null) {
      final double distanceValue = match['calculatedDistance'];
      distance = '${distanceValue.round()} km away';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewProfileScreen(
              profile: {
                'id': match['otherUserId'] ?? match['id'],
                'name': match['name'],
                'age': match['age'],
                'distance': distance,
                'bio': match['bio'] ?? '',
                'images': match['images'] ?? [imageUrl],
                'verified': match['isVerified'] ?? match['verified'] ?? false,
                'interests': match['interests'] ?? [],
                'hobbies': match['hobbies'] ?? [],
                'personality': match['personality'] ?? [],
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Profile Image
              imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[900],
                    child: const Icon(
                      Icons.person,
                      color: Colors.white30,
                      size: 64,
                    ),
                  ),

              // Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Match Info
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${match['name']}, ${match['age']}',
                            style: TextStyles.bodyText1Dark.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (match['isVerified'] == true || match['verified'] == true)
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.blue,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.9),
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              distance,
                              style: TextStyles.captionDark.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        if (match['matched'] == true)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyles.headline5Dark,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Failed to load matches',
              style: TextStyles.bodyText1Dark.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadMatches,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.primary,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Matches Yet',
            style: TextStyles.headline5Dark.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'When you match with someone, they will appear here',
              style: TextStyles.bodyText1Dark.copyWith(
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
} 