import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/services/firebase_service.dart';
import 'package:get_it/get_it.dart';

class ProfileCard extends StatefulWidget {
  final Map<String, dynamic> profile;

  const ProfileCard({
    super.key,
    required this.profile,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  late PageController _pageController;
  int _currentPage = 0;
  final _firebaseService = GetIt.instance<FirebaseService>();
  String? _distance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _distance = 'N/A';
        });
        return;
      }

      // Get current user's location
      final currentUserDoc = await _firebaseService.getUserData(currentUser.uid);
      if (currentUserDoc == null || currentUserDoc['location'] == null) {
        setState(() {
          _isLoading = false;
          _distance = 'N/A';
        });
        return;
      }

      // Parse current user's location
      final currentLocationParts = (currentUserDoc['location'] as String).split(',');
      if (currentLocationParts.length != 2) {
        setState(() {
          _isLoading = false;
          _distance = 'N/A';
        });
        return;
      }

      final currentLat = double.tryParse(currentLocationParts[0]);
      final currentLng = double.tryParse(currentLocationParts[1]);

      // Parse matched user's location
      final matchedLocationParts = (widget.profile['location'] as String).split(',');
      if (matchedLocationParts.length != 2) {
        setState(() {
          _isLoading = false;
          _distance = 'N/A';
        });
        return;
      }

      final matchedLat = double.tryParse(matchedLocationParts[0]);
      final matchedLng = double.tryParse(matchedLocationParts[1]);

      if (currentLat == null || currentLng == null || matchedLat == null || matchedLng == null) {
        setState(() {
          _isLoading = false;
          _distance = 'N/A';
        });
        return;
      }

      // Calculate distance
      final distance = _firebaseService.calculateDistance(
        currentLat,
        currentLng,
        matchedLat,
        matchedLng,
      );

      setState(() {
        _isLoading = false;
        _distance = distance.toStringAsFixed(1);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _distance = 'N/A';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Robust images list fallback: use 'images', then 'photoUrls', or empty list
    final dynamic imagesData = widget.profile['images'] ?? widget.profile['photoUrls'] ?? [];
    final List<dynamic> images = (imagesData is List) ? List<dynamic>.from(imagesData) : <dynamic>[];
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image slider
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTapUp: (details) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    if (details.globalPosition.dx < screenWidth / 2) {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    } else {
                      if (_currentPage < images.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  },
                  child: CachedNetworkImage(
                    imageUrl: '${images[index]}?w=800',
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
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Image indicators at top
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    width: 60,
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),

            // Profile info with gradient overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.9],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${widget.profile['name']}, ${widget.profile['age']}',
                          style: TextStyles.headline5Dark.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 26,
                          ),
                        ),
                        if (widget.profile['isVerified'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyles.captionDark.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withOpacity(0.9),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isLoading 
                              ? 'Calculating distance...'
                              : '${_distance} km away',
                          style: TextStyles.bodyText2Dark.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 