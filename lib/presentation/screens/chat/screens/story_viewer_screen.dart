import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/services/firebase_service.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final VoidCallback onStoriesSeen;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.onStoriesSeen,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late int _currentPersonIndex;
  late int _currentStoryIndex;
  bool _isPaused = false;
  bool _storiesSeen = false;
  final _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _currentPersonIndex = widget.initialIndex;
    _currentStoryIndex = 0;
    _pageController = PageController(initialPage: _currentStoryIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });

    // Defer marking the first story as seen until after build
    Future.microtask(() {
      _markCurrentStoryAsSeen();
    });
    _startProgress();
  }

  void _markCurrentStoryAsSeen() async {
    final currentPerson = widget.stories[_currentPersonIndex];
    final stories = (currentPerson['stories'] as List?) ?? [];
    if (_currentStoryIndex < stories.length) {
      final story = stories[_currentStoryIndex];
      final storyId = story['id'] as String?;
      final userId = currentPerson['userId'] as String?;
      
      if (storyId != null && userId != null) {
        print("Marking story as seen: $storyId for user $userId");
        
        // Check if the current user ID is already in the seenBy list
        final List<String> seenBy = List<String>.from(story['seenBy'] as List<dynamic>? ?? []);
        final currentUserId = _firebaseService.currentUser?.uid;
        
        if (currentUserId != null && !seenBy.contains(currentUserId)) {
          await _firebaseService.markStoryAsSeen(userId, storyId);
          
          // Update local state
          setState(() {
            seenBy.add(currentUserId);
            stories[_currentStoryIndex] = {
              ...Map<String, dynamic>.from(stories[_currentStoryIndex]),
              'seenBy': seenBy,
              'isSeen': true  // This sets it as seen for the current user in the UI
            };
          });
          
          widget.onStoriesSeen();
        }
      } else {
        print("Cannot mark story as seen - Missing ID ($storyId) or user ID ($userId)");
      }
    }
  }

  void _startProgress() {
    if (!_isPaused) {
      _progressController.forward(from: 0.0);
    }
  }

  void _nextStory() {
    final currentPerson = widget.stories[_currentPersonIndex];
    final stories = (currentPerson['stories'] as List?) ?? [];
    
    if (_currentStoryIndex < stories.length - 1) {
      // Move to next story of current person
      setState(() {
        _currentStoryIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      Future.microtask(() {
        _markCurrentStoryAsSeen();
      });
      _startProgress();
    } else {
      // Move to next person's first story
      if (_currentPersonIndex < widget.stories.length - 1) {
        setState(() {
          _currentPersonIndex++;
          _currentStoryIndex = 0;
        });
        _pageController.jumpToPage(0);
        Future.microtask(() {
          _markCurrentStoryAsSeen();
        });
        _startProgress();
      } else {
        _markStoriesAsSeen();
        Navigator.pop(context);
      }
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      // Move to previous story of current person
      setState(() {
        _currentStoryIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      Future.microtask(() {
        _markCurrentStoryAsSeen();
      });
      _startProgress();
    } else {
      // Move to previous person's last story
      if (_currentPersonIndex > 0) {
        final previousPerson = widget.stories[_currentPersonIndex - 1];
        final previousStories = (previousPerson['stories'] as List?) ?? [];
        setState(() {
          _currentPersonIndex--;
          _currentStoryIndex = previousStories.length - 1;
        });
        _pageController.jumpToPage(_currentStoryIndex);
        Future.microtask(() {
          _markCurrentStoryAsSeen();
        });
        _startProgress();
      } else {
        _markStoriesAsSeen();
        Navigator.pop(context);
      }
    }
  }

  void _markStoriesAsSeen() {
    if (!_storiesSeen) {
      _storiesSeen = true;
      widget.onStoriesSeen();
    }
  }

  @override
  void dispose() {
    _markStoriesAsSeen();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPerson = widget.stories[_currentPersonIndex];
    final stories = (currentPerson['stories'] as List?) ?? [];
    
    if (stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No stories available',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > 2 * screenWidth / 3) {
            _nextStory();
          }
        },
        onLongPressStart: (_) {
          setState(() {
            _isPaused = true;
            _progressController.stop();
          });
        },
        onLongPressEnd: (_) {
          setState(() {
            _isPaused = false;
            _progressController.forward();
          });
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: stories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentStoryIndex = index;
                });
                Future.microtask(() {
                  _markCurrentStoryAsSeen();
                });
                if (!_isPaused) {
                  _startProgress();
                }
              },
              itemBuilder: (context, index) {
                final story = stories[index];
                final currentUserId = _firebaseService.currentUser?.uid;
                final List<String> seenBy = List<String>.from(story['seenBy'] as List<dynamic>? ?? []);
                final isSeen = currentUserId != null && seenBy.contains(currentUserId);
                
                return Stack(
                  children: [
                    Hero(
                      tag: 'story_${currentPerson['name']}_$index',
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSeen ? Colors.grey : AppColors.primary,
                            width: 2,
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: story['imageUrl'] as String? ?? '',
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            print('Error loading story image: $error');
                            print('Story data: $story');
                            return Container(
                              color: Colors.grey[900],
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.white38,
                                size: 32,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Text(
                        story['createdAt'] != null 
                            ? _formatCreationTime((story['createdAt'] as Timestamp).toDate()) 
                            : 'Just now',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: List.generate(
                    stories.length,
                    (index) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              final currentUserId = _firebaseService.currentUser?.uid;
                              final List<String> seenBy = List<String>.from(stories[index]['seenBy'] as List<dynamic>? ?? []);
                              final isSeen = currentUserId != null && seenBy.contains(currentUserId);
                              
                              return LinearProgressIndicator(
                                value: index == _currentStoryIndex
                                    ? _progressController.value
                                    : index < _currentStoryIndex
                                        ? 1.0
                                        : 0.0,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isSeen ? Colors.grey : Colors.white,
                                ),
                                minHeight: 2,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white24,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: currentPerson['image'] as String? ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white38,
                            size: 16,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white38,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentPerson['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCreationTime(DateTime creationTime) {
    final now = DateTime.now();
    final difference = now.difference(creationTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${creationTime.day}/${creationTime.month}';
    }
  }
} 