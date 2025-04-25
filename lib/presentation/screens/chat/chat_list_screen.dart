import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import 'chat_screen.dart';
import 'screens/story_viewer_screen.dart';
import 'screens/story_creation_screen.dart';
import '../../../data/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swipe/presentation/widgets/story_circle.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  final _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();
  final List<Map<String, dynamic>> _stories = [];
  final List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  bool _isChatsLoading = true;
  bool _isStoriesLoading = true;
  final _firestore = FirebaseFirestore.instance;
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _needsRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStoriesAndChats();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came to foreground
      _refreshData();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_needsRefresh) {
      _needsRefresh = false;
      _refreshData();
    }
  }
  
  void _refreshData() {
    print("Refreshing chat list data...");
    if (mounted) {
      _loadStoriesAndChats();
    }
  }

  Future<void> _loadStoriesAndChats() async {
    if (_firebaseService.currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isChatsLoading = false;
          _isStoriesLoading = false;
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _isChatsLoading = true;
          _isStoriesLoading = true;
        });
      }

      // Load chats first
      _firebaseService.getMatches().listen((snapshot) async {
        if (!mounted) return;
        
        final chats = <Map<String, dynamic>>[];
        
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final users = List<String>.from(data['users'] ?? []);
            final otherUserId = users.firstWhere((id) => id != _firebaseService.currentUser!.uid);
            
            // Get other user's data
            final otherUserData = await _firebaseService.getUserData(otherUserId);
            if (otherUserData != null) {
              // Get last message from Realtime Database
              final messages = await _firebaseService.getMessages(doc.id).first;
              final lastMessage = messages.isNotEmpty ? messages.last : null;

              // Add to chats
              chats.add({
                'id': doc.id,
                'otherUserId': otherUserId,
                'otherUserName': '${otherUserData['firstName'] ?? ''} ${otherUserData['lastName'] ?? ''}'.trim(),
                'otherUserPhoto': otherUserData['photoUrls']?.first ?? otherUserData['profilePicture'] ?? '',
                'lastMessage': lastMessage?['text'] ?? 'No messages yet',
                'lastMessageTime': lastMessage != null 
                    ? DateTime.fromMillisecondsSinceEpoch(lastMessage['timestamp'] as int)
                    : (data['lastMessageAt'] as Timestamp).toDate(),
                'unreadCount': (data['unread']?[_firebaseService.currentUser!.uid] ?? 0),
                'isActive': data['isActive'] ?? true,
              });
            }
          } catch (e) {
            print('Error processing chat: $e');
          }
        }

        if (mounted) {
          setState(() {
            _chats.clear();
            _chats.addAll(chats);
            _isChatsLoading = false;
            _isLoading = _isChatsLoading || _isStoriesLoading;
          });
        }
      });

      // Load stories
      _firebaseService.getStories().listen((stories) async {
        if (!mounted) return;
        
        final storiesList = <Map<String, dynamic>>[];
        
        // Get current user's profile data
        final currentUserData = await _firebaseService.getUserData(_firebaseService.currentUser!.uid);
        
        // Add "Your Story" at the beginning
        QueryDocumentSnapshot? currentUserStory;
        bool hasUserStory = false;
        List<dynamic> userStories = [];
        
        try {
          if (stories.docs.isNotEmpty) {
            print("Found stories docs: ${stories.docs.length}");
            currentUserStory = stories.docs.firstWhere(
              (doc) => doc.get('userId') == _firebaseService.currentUser!.uid,
            );
            print("Found current user's story document");
            hasUserStory = true;
            userStories = currentUserStory.get('stories') ?? [];
            print("User stories before filtering: ${userStories.length}");
            
            // Filter out expired stories
            final now = DateTime.now();
            userStories = userStories.where((story) {
              final createdAt = story['createdAt'] as Timestamp?;
              if (createdAt == null) {
                print("Story has no createdAt: $story");
                return false;
              }
              final isValid = now.difference(createdAt.toDate()).inHours < 24;
              print("Story createdAt: ${createdAt.toDate()}, isValid: $isValid");
              return isValid;
            }).toList();
            
            print("User stories after filtering: ${userStories.length}");
            hasUserStory = userStories.isNotEmpty;
            print("Has valid stories: $hasUserStory");
          } else {
            print("No stories found in collection");
          }
        } catch (e) {
          print("Error processing user story: $e");
          hasUserStory = false;
          userStories = [];
        }

        final currentUserId = _firebaseService.currentUser!.uid;
        
        // Check if all user stories are seen by the current user
        final bool allUserStoriesSeen = userStories.isNotEmpty && 
                                        userStories.every((story) {
                                          List<String> seenBy = List<String>.from(story['seenBy'] as List<dynamic>? ?? []);
                                          return seenBy.contains(currentUserId);
                                        });
        print("All user stories seen: $allUserStoriesSeen");

        print("Creating Your Story entry with hasStory: $hasUserStory");
        storiesList.add({
          'name': 'Your Story',
          'image': currentUserData?['photoUrls']?.first ?? currentUserData?['profilePicture'] ?? _firebaseService.currentUser!.photoURL ?? '',
          'isActive': true,
          'hasStory': hasUserStory,
          'isSeen': allUserStoriesSeen,
          'stories': userStories.map((story) => {
            'imageUrl': story['imageUrl'],
            'createdAt': story['createdAt'],
            'seenBy': story['seenBy'] ?? <String>[],
            'isSeen': (story['seenBy'] as List<dynamic>?)?.contains(currentUserId) ?? false,
            'id': story['id'] ?? '',
          }).toList(),
          'userId': _firebaseService.currentUser!.uid,
        });
        
        for (var story in stories.docs) {
          try {
            final storyData = story.data() as Map<String, dynamic>;
            final userId = storyData['userId'] as String?;
            if (userId == null || userId == _firebaseService.currentUser!.uid) continue;

            // Get other user's data
            final userData = await _firebaseService.getUserData(userId);
            if (userData == null) continue;

            // Get their stories
            final storyList = storyData['stories'] as List<dynamic>? ?? [];
            print("User ${userData['firstName'] ?? 'Unknown'} (ID: $userId) has ${storyList.length} stories");
            
            if (storyList.isEmpty) {
              print("Skipping user because they have no stories");
              continue;
            }
            
            // Filter out expired stories
            final now = DateTime.now();
            final validStories = storyList.where((story) {
              final createdAt = story['createdAt'] as Timestamp?;
              if (createdAt == null) {
                print("Story has no createdAt timestamp");
                return false;
              }
              final isValid = now.difference(createdAt.toDate()).inHours < 24;
              print("Story for ${userData['firstName']}: created ${createdAt.toDate()}, isValid: $isValid");
              return isValid;
            }).toList();

            print("User ${userData['firstName']} has ${validStories.length} valid stories");
            if (validStories.isEmpty) {
              print("Skipping user because they have no valid stories");
              continue; // Skip if no valid stories
            }

            // Check if we can chat with this user (they should be in our matches)
            final canChat = _chats.any((chat) => chat['otherUserId'] == userId);
            print("Can chat with ${userData['firstName']}: $canChat");
            
            // Only show stories from users we've matched with
            if (!canChat) {
              print("Skipping user's stories because we can't chat with them");
              continue;
            }

            // Check if the current user has seen all of this user's stories
            final hasUnseenStories = validStories.any((story) {
              List<String> seenBy = List<String>.from(story['seenBy'] as List<dynamic>? ?? []);
              return !seenBy.contains(currentUserId);
            });
            
            final allStoriesSeen = validStories.every((story) {
              List<String> seenBy = List<String>.from(story['seenBy'] as List<dynamic>? ?? []);
              return seenBy.contains(currentUserId);
            });
            
            print("User ${userData['firstName']}: has unseen stories: $hasUnseenStories, all seen: $allStoriesSeen");

            storiesList.add({
              'name': '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
              'image': userData['photoUrls']?.first ?? userData['profilePicture'] ?? '',
              'isActive': userData['isOnline'] ?? false,
              'hasStory': true,
              'isSeen': allStoriesSeen,
              'stories': validStories.map((story) => {
                'imageUrl': story['imageUrl'],
                'createdAt': story['createdAt'],
                'seenBy': story['seenBy'] ?? <String>[],
                'isSeen': (story['seenBy'] as List<dynamic>?)?.contains(currentUserId) ?? false,
                'id': story['id'] ?? '',
              }).toList(),
              'userId': userId,
            });
          } catch (e) {
            print('Error processing story: $e');
          }
        }

        // Also filter "Your Story" for expired stories
        if (storiesList.isNotEmpty && storiesList[0]['name'] == 'Your Story') {
          final yourStories = storiesList[0]['stories'] as List<dynamic>;
          final now = DateTime.now();
          final validStories = yourStories.where((story) {
            final createdAt = story['createdAt'] as Timestamp?;
            if (createdAt == null) return false;
            return now.difference(createdAt.toDate()).inHours < 24;
          }).toList();

          if (validStories.isEmpty) {
            storiesList[0]['hasStory'] = false;
            storiesList[0]['stories'] = [];
          } else {
            storiesList[0]['stories'] = validStories;
          }
        }

        // Sort stories: unseen first, then seen
        storiesList.sort((a, b) {
          if (a['name'] == 'Your Story') return -1; // Your story always first
          if (b['name'] == 'Your Story') return 1;
          
          final aSeen = a['isSeen'] as bool;
          final bSeen = b['isSeen'] as bool;
          
          if (aSeen == bSeen) return 0;
          return aSeen ? 1 : -1; // Unseen stories come first
        });

        if (mounted) {
          setState(() {
            _stories.clear();
            _stories.addAll(storiesList);
            _isStoriesLoading = false;
            _isLoading = _isChatsLoading || _isStoriesLoading;
          });
        }
      });
    } catch (e) {
      print('Error loading stories and chats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isChatsLoading = false;
          _isStoriesLoading = false;
        });
      }
    }
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime messageTime;
    if (timestamp is Timestamp) {
      messageTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      messageTime = timestamp;
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }
  }

  void _markStoriesAsSeen(String userId) {
    if (!mounted) return;
    
    print("Marking stories as seen for user: $userId");
    
    // Use Future.microtask to ensure we're not in a frame
    Future.microtask(() async {
      if (!mounted) return;
      
      final currentUserId = _firebaseService.currentUser!.uid;
      
      // First find all stories for this user
      final storyIndex = _stories.indexWhere((s) => s['userId'] == userId);
      if (storyIndex != -1) {
        print("Found user in stories at index $storyIndex");
        final userStories = _stories[storyIndex]['stories'] as List;
        print("User has ${userStories.length} stories");
        
        // Mark each story as seen in Firebase
        for (var story in userStories) {
          final storyId = story['id'] as String?;
          if (storyId != null && storyId.isNotEmpty) {
            // We need to check the current seenBy status
            final List<String> seenBy = List<String>.from(story['seenBy'] as List<dynamic>? ?? []);
            
            if (!seenBy.contains(currentUserId)) {
              print("Marking story $storyId as seen in Firebase");
              try {
                await _firebaseService.markStoryAsSeen(userId, storyId);
                // Update local story status
                seenBy.add(currentUserId);
                story['seenBy'] = seenBy;
                story['isSeen'] = true; // For the current user
                print("Story marked as seen in Firebase");
              } catch (e) {
                print("Error marking story as seen: $e");
              }
            } else {
              print("Story $storyId already seen by current user");
            }
          }
        }
        
        // Update local state
        if (mounted) {
          setState(() {
            // Set overall user story status to seen
            _stories[storyIndex]['isSeen'] = true;
            
            // Ensure all stories are marked as seen locally for the current user
            for (var story in _stories[storyIndex]['stories']) {
              List<String> seenBy = List<String>.from(story['seenBy'] as List<dynamic>? ?? []);
              if (!seenBy.contains(currentUserId)) {
                seenBy.add(currentUserId);
                story['seenBy'] = seenBy;
              }
              story['isSeen'] = true; // For the current user
            }

            // Reorder stories
            final story = _stories.removeAt(storyIndex);
            final firstSeenIndex = _stories.indexWhere((s) => s['isSeen'] == true);
            if (firstSeenIndex != -1) {
              _stories.insert(firstSeenIndex, story);
            } else {
              _stories.add(story);
            }
            
            print("Local story state updated, refreshing UI");
          });
        }
      } else {
        print("User $userId not found in stories list");
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredStories() {
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));

    return _stories.map((person) {
      if (!person['hasStory']) return person;

      final stories = (person['stories'] as List).where((story) {
        final createdAt = story['createdAt'] as Timestamp?;
        return createdAt != null && createdAt.toDate().isAfter(oneDayAgo);
      }).toList();

      return {
        ...person,
        'hasStory': stories.isNotEmpty,
        'stories': stories,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getOrderedStories(List<Map<String, dynamic>> stories) {
    if (stories.isEmpty) return [];

    final unvisitedStories = stories.where((s) => 
      s['hasStory'] as bool && 
      !(s['isSeen'] as bool) && 
      s['name'] != 'Your Story'
    ).toList();

    final visitedStories = stories.where((s) => 
      s['hasStory'] as bool && 
      (s['isSeen'] as bool) && 
      s['name'] != 'Your Story'
    ).toList();

    final yourStory = stories.firstWhere(
      (s) => s['name'] == 'Your Story',
      orElse: () => stories.first,
    );

    return [yourStory, ...unvisitedStories, ...visitedStories];
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final filteredStories = _getFilteredStories();
    final orderedStories = _getOrderedStories(filteredStories);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding + 60),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StoryCreationScreen(),
              ),
            );

            if (result != null && result is List<File>) {
              _createNewStory(result);
            }
          },
          backgroundColor: AppColors.primary,
          child: const Icon(
            Icons.camera_alt,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          // Custom App Bar
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 12,
              left: 20,
              right: 16,
              bottom: 12,
            ),
            color: AppColors.backgroundDark,
            child: Row(
              children: [
                Text(
                  'Chats',
                  style: TextStyles.headline4Dark.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Stories
          Container(
            height: 100,
            margin: const EdgeInsets.only(top: 4),
            child: _buildStories(),
          ),

          // Chat List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isChatsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _chats.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 4),
                            itemCount: _chats.length,
                            itemBuilder: (context, index) {
                              final chat = _chats[index];
                              return _buildChatItem(context, chat);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStories() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final story = _stories[index];
        return _buildStoryItem(story, index == 0);
      },
    );
  }

  Widget _buildStoryItem(Map<String, dynamic> story, bool isFirst) {
    final bool hasStory = story['hasStory'] as bool;
    final bool isSeen = story['isSeen'] as bool;
    final bool isActive = story['isActive'] as bool;
    final List<dynamic> userStories = story['stories'] as List<dynamic>? ?? [];

    print("Building story item: ${story['name']}");
    print("Has story: $hasStory");
    print("Is seen: $isSeen");
    print("Stories count: ${userStories.length}");

    return GestureDetector(
      onTap: () async {
        if (isFirst) {
          if (hasStory && userStories.isNotEmpty) {
            final filteredStories = _getFilteredStories().where((s) {
              final hasStory = s['hasStory'] as bool;
              final storiesList = s['stories'] as List?;
              return hasStory && storiesList != null && storiesList.isNotEmpty;
            }).toList();
            
            final index = filteredStories.indexWhere((s) => s['name'] == 'Your Story');
            if (index != -1) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryViewerScreen(
                    stories: filteredStories,
                    initialIndex: index,
                    onStoriesSeen: () => _markStoriesAsSeen(story['userId']),
                  ),
                ),
              );
              
              // Refresh data when returning from story viewer
              _needsRefresh = true;
              _refreshData();
            }
          } else {
            // Show story creation screen when no stories exist
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const StoryCreationScreen(),
              ),
            );

            if (result != null && result is List<File>) {
              await _createNewStory(result);
              // Refresh after story creation
              _needsRefresh = true;
              _refreshData();
            }
          }
          return;
        }
        
        if (!hasStory || userStories.isEmpty) return;
        
        final filteredStories = _getFilteredStories().where((s) {
          final hasStory = s['hasStory'] as bool;
          final storiesList = s['stories'] as List?;
          return hasStory && storiesList != null && storiesList.isNotEmpty;
        }).toList();
        
        final index = filteredStories.indexWhere((s) => s['userId'] == story['userId']);
        if (index != -1) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StoryViewerScreen(
                stories: filteredStories,
                initialIndex: index,
                onStoriesSeen: () => _markStoriesAsSeen(story['userId']),
              ),
            ),
          );
          
          // Refresh data when returning from story viewer
          _needsRefresh = true;
          _refreshData();
        }
      },
      child: Container(
        width: 72,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasStory && !isSeen
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.7),
                          AppColors.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: Border.all(
                  color: hasStory 
                      ? (isSeen ? Colors.grey.shade900 : AppColors.primary)
                      : Colors.white24,
                  width: hasStory ? 2 : 1,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    Hero(
                      tag: 'story_${story['userId']}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: CachedNetworkImage(
                          imageUrl: story['image'],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[900],
                            child: const Icon(
                              Icons.person,
                              color: Colors.white38,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isFirst)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: hasStory ? Colors.green : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.backgroundDark,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              hasStory ? Icons.check : Icons.add,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (isActive && !isFirst)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.backgroundDark,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story['name'],
              style: TextStyle(
                color: hasStory && !isSeen ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: hasStory && !isSeen ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Map<String, dynamic> chat) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              matchId: chat['id'],
              otherUserId: chat['otherUserId'],
            ),
          ),
        );
        
        // Refresh data when returning from chat screen
        _needsRefresh = true;
        _refreshData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        child: Row(
          children: [
            // Profile Picture
            Hero(
              tag: 'chat_${chat['id']}_${chat['otherUserId']}',
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[900],
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: chat['otherUserPhoto'],
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white38,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (chat['unreadCount'] > 0)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.backgroundDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Chat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat['otherUserName'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat['lastMessage'],
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Time
            Text(
              _getTimeAgo(chat['lastMessageTime']),
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewStory(List<File> files) async {
    try {
      print("Uploading ${files.length} story files...");
      setState(() {
        _isLoading = true;
      });

      final storyUrls = await Future.wait(
        files.map((file) => _firebaseService.uploadStory(file)),
      );
      print("Successfully uploaded ${storyUrls.length} stories");

      // Create story entries
      for (var url in storyUrls) {
        await _firebaseService.createStory(url);
        print("Created story with URL: $url");
      }

      // Refresh data after story creation
      await _loadStoriesAndChats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating story: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create story'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Chats Yet',
            style: TextStyles.headline5Dark.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'When you match with someone, you can start chatting here',
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