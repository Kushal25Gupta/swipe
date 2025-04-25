import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../config/firebase_config.dart';
import 'dart:io';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import 'dart:math';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseConfig.auth;
  final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  final FirebaseStorage _storage = FirebaseConfig.storage;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Auth methods
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  // Firestore methods
  Future<void> createUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      print('Attempting to create user profile in Firestore...');
      print('User ID: $userId');
      print('Profile data: $profileData');
      
      // Check if Firestore is initialized
      if (_firestore == null) {
        print('Firestore is not initialized!');
        throw Exception('Firestore is not initialized');
      }
      
      // Verify Firestore connection with retry
      bool connected = false;
      int retryCount = 0;
      const maxRetries = 3;
      
      while (!connected && retryCount < maxRetries) {
        try {
          print('Testing Firestore connection (attempt ${retryCount + 1})...');
          // Try to get the collection reference instead of a document
          await _firestore!.collection('users').limit(1).get();
          connected = true;
          print('Firestore connection test successful');
        } catch (e) {
          print('Firestore connection test failed: $e');
          retryCount++;
          if (retryCount < maxRetries) {
            print('Retrying in 2 seconds...');
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
      
      if (!connected) {
        throw Exception('Could not connect to Firestore after $maxRetries attempts');
      }
      
      // Create document reference
      final docRef = _firestore!.collection('users').doc(userId);
      print('Document reference created: ${docRef.path}');
      
      // Set the data
      print('Setting document data...');
      await docRef.set(profileData);
      print('Document data set successfully');
      
      // Verify the document was created
      print('Verifying document creation...');
      final doc = await docRef.get();
      if (doc.exists) {
        print('✅ Verified: Document exists in Firestore');
        print('Document data: ${doc.data()}');
      } else {
        print('❌ Error: Document was not created in Firestore');
        throw Exception('Document was not created in Firestore');
      }
    } on FirebaseException catch (e) {
      print('🔥 Firebase error creating user profile:');
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
      print('Plugin: ${e.plugin}');
      print('Stack trace: ${e.stackTrace}');
      
      // Handle specific Firestore errors
      if (e.code == 'unavailable') {
        throw Exception('Firestore service is currently unavailable. Please try again later.');
      } else if (e.code == 'not-found') {
        throw Exception('Firestore database not found. Please check your Firebase configuration.');
      }
      
      rethrow;
    } catch (e) {
      print('❌ Error creating user profile: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final userId = currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    await _firestore.collection('users').doc(userId).update(updates);
  }

  // Storage methods
  Future<String> uploadProfileImage(File file) async {
    final userId = currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    final ref = _storage.ref().child('profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Real-time listeners
  Stream<QuerySnapshot> getPotentialMatchesStream() {
    return _firestore
        .collection('users')
        .where('isProfileComplete', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getMatches() {
    final userId = currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    return _firestore
        .collection('matches')
        .where('users', arrayContains: userId)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getPotentialMatches({
    required String currentUserId,
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) async {
    try {
      final currentUserDoc = await getUserData(currentUserId);
      if (currentUserDoc == null) {
        throw Exception('Current user not found');
      }

      final currentUserGender = currentUserDoc['gender'] as String?;
      final currentUserPreferredGender = currentUserDoc['preferredGender'] as String?;

      print('DEBUG GENDER MATCHING: Current user gender: $currentUserGender');
      print('DEBUG GENDER MATCHING: Current user preferred gender: $currentUserPreferredGender');

      if (currentUserGender == null || currentUserPreferredGender == null) {
        throw Exception('Current user gender or gender preference not set');
      }

      // Get all users first
      final querySnapshot = await _firestore
          .collection('users')
          .where('isProfileComplete', isEqualTo: true)
          .get();

      print('DEBUG GENDER MATCHING: Found ${querySnapshot.docs.length} potential users with complete profiles');
      
      // Filter users in memory
      final matches = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final userId = doc.id;
        final userGender = data['gender'] as String?;
        final userPreferredGender = data['preferredGender'] as String?;
        final userLocation = data['location'] as String?;
        final userName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();

        // Skip if any required field is missing
        if (userGender == null || userPreferredGender == null || userLocation == null) {
          print('DEBUG GENDER MATCHING: Skipping user $userName ($userId) - missing required field');
          return false;
        }

        // Skip current user
        if (userId == currentUserId) {
          return false;
        }

        // Check gender compatibility
        final isGenderCompatible = (currentUserPreferredGender == 'All' || currentUserPreferredGender == userGender) &&
                                 (userPreferredGender == 'All' || userPreferredGender == currentUserGender);

        print('DEBUG GENDER MATCHING: User $userName ($userId) - Gender: $userGender, Preferred: $userPreferredGender, Compatible: $isGenderCompatible');

        if (!isGenderCompatible) {
          return false;
        }

        // Check location
        try {
          final locationParts = userLocation.split(',');
          if (locationParts.length != 2) return false;

          final userLat = double.tryParse(locationParts[0]);
          final userLng = double.tryParse(locationParts[1]);

          if (userLat == null || userLng == null) return false;

          final distance = calculateDistance(latitude, longitude, userLat, userLng);
          final withinRange = distance <= radiusInKm;
          
          print('DEBUG GENDER MATCHING: User $userName - Distance: ${distance.toStringAsFixed(2)}km, Within range: $withinRange');
          
          return withinRange;
        } catch (e) {
          return false;
        }
      }).map((doc) {
        final data = doc.data();
        final images = data['images'] as List<dynamic>? ?? [];
        final photoUrls = data['photoUrls'] as List<dynamic>? ?? [];
        final validImages = [...images, ...photoUrls].where((url) => url != null && url.toString().isNotEmpty).toList();
        
        return {
          'id': doc.id,
          ...data,
          'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim(),
          'isVerified': data['isVerified'] ?? false,
          'age': data['age'] ?? 0,
          'location': data['location'] ?? '',
          'images': validImages,
          'photoUrls': validImages,
        };
      }).toList();

      return matches;
    } catch (e) {
      print('Error getting potential matches: $e');
      rethrow;
    }
  }

  int _calculateMatchScore(
    List<String> currentUserInterests,
    List<String> currentUserHobbies,
    List<String> currentUserPersonality,
    List<String> otherUserInterests,
    List<String> otherUserHobbies,
    List<String> otherUserPersonality,
  ) {
    int score = 0;

    // Calculate common interests
    final commonInterests = currentUserInterests
        .where((interest) => otherUserInterests.contains(interest))
        .length;
    score += commonInterests * 3; // Weight for interests

    // Calculate common hobbies
    final commonHobbies = currentUserHobbies
        .where((hobby) => otherUserHobbies.contains(hobby))
        .length;
    score += commonHobbies * 2; // Weight for hobbies

    // Calculate common personality traits
    final commonPersonality = currentUserPersonality
        .where((trait) => otherUserPersonality.contains(trait))
        .length;
    score += commonPersonality * 1; // Weight for personality

    return score;
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Story methods
  Future<String> uploadStory(File file) async {
    final userId = currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    final ref = _storage.ref().child('stories/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> createStory(String imageUrl) async {
    final userId = currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    print("Creating story for user: $userId");
    print("Image URL: $imageUrl");

    final now = DateTime.now();
    final storyId = const Uuid().v4(); // Generate unique ID for story
    
    final storyItem = {
      'id': storyId,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(now),
      'seenBy': <String>[], // Track which users have seen this story
    };
    
    print("Story item to be created: $storyItem");
    
    final storyData = {
      'userId': userId,
      'stories': [storyItem],
      'timestamp': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 1))),
      'viewers': <String>[],
    };

    print("Story data to be created: $storyData");

    // Check if user already has a story document
    final existingStories = await _firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .get();

    print("Found ${existingStories.docs.length} existing story documents");

    // Filter expired stories in memory
    final validStories = existingStories.docs.where((doc) {
      final expiresAt = doc.get('expiresAt') as Timestamp?;
      if (expiresAt == null) {
        print("Story document has no expiresAt: ${doc.data()}");
        return false;
      }
      final isValid = expiresAt.toDate().isAfter(now);
      print("Story expiresAt: ${expiresAt.toDate()}, isValid: $isValid");
      return isValid;
    }).toList();

    print("Found ${validStories.length} valid story documents");

    if (validStories.isNotEmpty) {
      // Update existing story document
      final storyDoc = validStories.first;
      print("Updating existing story document: ${storyDoc.id}");
      await storyDoc.reference.update({
        'stories': FieldValue.arrayUnion([storyItem]),
        'expiresAt': Timestamp.fromDate(now.add(const Duration(days: 1))),
      });
      print("Story document updated successfully");
    } else {
      // Create new story document
      print("Creating new story document");
      final docRef = await _firestore.collection('stories').add(storyData);
      print("New story document created with ID: ${docRef.id}");
    }
  }

  Future<void> deleteExpiredStories() async {
    final now = DateTime.now();
    final expiredStories = await _firestore
        .collection('stories')
        .where('expiresAt', isLessThan: now.toIso8601String())
        .get();

    for (var doc in expiredStories.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> markStoryAsSeen(String storyOwnerId, String storyId) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) throw Exception('User not authenticated');
      
      print("Marking story as seen - Owner ID: $storyOwnerId, Story ID: $storyId, Current User: $currentUserId");
      
      // Get all story documents for this user
      final querySnapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: storyOwnerId)
          .get();
      
      print("Found ${querySnapshot.docs.length} story documents for user");
      
      if (querySnapshot.docs.isEmpty) return;
      
      // Find the document containing this story
      for (final doc in querySnapshot.docs) {
        final stories = doc.get('stories') as List<dynamic>;
        print("Document ${doc.id} has ${stories.length} stories");
        
        bool storyFound = false;
        final updatedStories = stories.map((story) {
          final currentId = story['id'] as String?;
          print("Checking story ID: $currentId against $storyId");
          
          if (currentId == storyId) {
            storyFound = true;
            print("Story found! Marking as seen");
            
            // Get current seenBy list or create a new one
            List<String> seenBy = [];
            if (story.containsKey('seenBy')) {
              seenBy = List<String>.from(story['seenBy'] as List<dynamic>? ?? []);
            }
            
            // Add current user to seenBy if not already there
            if (!seenBy.contains(currentUserId)) {
              seenBy.add(currentUserId);
              print("Added user $currentUserId to seenBy list");
            }
            
            return {...Map<String, dynamic>.from(story), 'seenBy': seenBy};
          }
          return story;
        }).toList();
        
        if (storyFound) {
          print("Updating document ${doc.id} with seen status");
          await doc.reference.update({
            'stories': updatedStories
          });
          
          print("Story marked as seen successfully");
          break;
        }
      }
    } catch (e) {
      print('Error marking story as seen: $e');
    }
  }

  Stream<QuerySnapshot> getStories() {
    return _firestore
        .collection('stories')
        .snapshots();
  }

  Stream<QuerySnapshot> getMyStories() {
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .snapshots();
  }

  Future<Map<String, List<String>>> getAppConfiguration() async {
    try {
      final configDoc = await _firestore.collection('app_configuration').doc('options').get();
      if (!configDoc.exists) {
        return {};
      }
      
      final data = configDoc.data() as Map<String, dynamic>;
      return {
        'relationshipOptions': List<String>.from(data['relationshipOptions'] ?? []),
        'zodiacSigns': List<String>.from(data['zodiacSigns'] ?? []),
        'languageOptions': List<String>.from(data['languageOptions'] ?? []),
        'interestOptions': List<String>.from(data['interestOptions'] ?? []),
        'hobbyOptions': List<String>.from(data['hobbyOptions'] ?? []),
        'personalityOptions': List<String>.from(data['personalityOptions'] ?? []),
        'lookingForOptions': List<String>.from(data['lookingForOptions'] ?? []),
        'genderOptions': List<String>.from(data['genderOptions'] ?? []),
        'preferredGenderOptions': List<String>.from(data['preferredGenderOptions'] ?? []),
        'preferredAgeRanges': List<String>.from(data['preferredAgeRanges'] ?? []),
        'preferredHeightRanges': List<String>.from(data['preferredHeightRanges'] ?? []),
      };
    } catch (e) {
      print('Error fetching app configuration: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getMenuItems() async {
    try {
      final menuDoc = await _firestore.collection('app_configuration').doc('menu_items').get();
      if (!menuDoc.exists) {
        return {};
      }
      
      return menuDoc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching menu items: $e');
      return {};
    }
  }

  // Add missing methods
  Future<void> sendNotification(String userId, String title, String body, {String type = 'like'}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Current user is null, cannot send notification');
        return;
      }

      // Get current user's data
      final userDoc = await getUserData(currentUser.uid);
      if (userDoc == null) {
        print('User document not found for current user');
        return;
      }

      // Get user's photo URL with fallback
      final photoUrls = userDoc['photoUrls'] as List<dynamic>?;
      final imageUrl = (photoUrls?.isNotEmpty ?? false) 
          ? photoUrls!.first.toString() 
          : 'https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y';

      print('Sending notification to user: $userId');
      print('Notification type: $type');
      print('From user ID: ${currentUser.uid}');

      final notificationData = {
        'userId': userId,
        'title': title,
        'message': body,
        'image': imageUrl,
        'type': type,
        'fromUserId': currentUser.uid,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('Notification data: $notificationData');

      final docRef = await _firestore.collection('notifications').add(notificationData);
      print('Notification saved with ID: ${docRef.id}');

      // Verify the notification was saved
      final savedDoc = await docRef.get();
      if (savedDoc.exists) {
        print('Verified notification saved successfully');
        print('Saved data: ${savedDoc.data()}');
      } else {
        print('Error: Notification was not saved');
      }
    } catch (e) {
      print('Error sending notification: $e');
      rethrow;
    }
  }

  Future<String> createMatch(String userId1, String userId2) async {
    try {
      // Check if a match already exists between these users
      final existingMatches = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId1)
          .get();
      
      for (var doc in existingMatches.docs) {
        final users = List<String>.from(doc.data()['users'] ?? []);
        if (users.contains(userId2)) {
          print('Match already exists between $userId1 and $userId2, returning existing match ID: ${doc.id}');
          return doc.id;
        }
      }
      
      // No existing match found, create a new one
      final matchId = const Uuid().v4();
      final batch = _firestore.batch();

      // Create match document
      final matchRef = _firestore.collection('matches').doc(matchId);
      batch.set(matchRef, {
        'users': [userId1, userId2],
        'matchedAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'unread': {
          userId1: 0,
          userId2: 0,
        },
      });

      // Update users' matches
      final user1Ref = _firestore.collection('users').doc(userId1);
      final user2Ref = _firestore.collection('users').doc(userId2);

      batch.update(user1Ref, {
        'matches': FieldValue.arrayUnion([matchId]),
      });

      batch.update(user2Ref, {
        'matches': FieldValue.arrayUnion([matchId]),
      });

      // Increment matches count for both users
      await incrementUserStats(userId1, 'matches');
      await incrementUserStats(userId2, 'matches');

      await batch.commit();
      print('Created new match with ID: $matchId between users $userId1 and $userId2');
      return matchId;
    } catch (e) {
      print('Error creating match: $e');
      rethrow;
    }
  }

  Future<QuerySnapshot> getNotifications() async {
    final userId = currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    
    return await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
  }

  Future<void> updateNotificationStatus(String notificationId, bool isRead, {String? status}) async {
    try {
      final updateData = <String, dynamic>{
        'isRead': isRead,
      };
      
      if (status != null) {
        updateData['status'] = status;
      }
      
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update(updateData);
    } catch (e) {
      print('Error updating notification status: $e');
      rethrow;
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of the earth in km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  // Chat methods using Realtime Database
  Stream<List<Map<String, dynamic>>> getMessages(String matchId) {
    print("Listening for messages in match: $matchId");
    
    return _database
        .ref()
        .child('matches')
        .child(matchId)
        .child('messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          print("Received message snapshot: ${event.snapshot.value}");
          
          if (event.snapshot.value == null) {
            print("No messages found for match: $matchId");
            return [];
          }
          
          final Map<dynamic, dynamic> messages = event.snapshot.value as Map;
          print("Number of messages found: ${messages.length}");
          
          return messages.entries.map((entry) {
            final message = entry.value as Map<dynamic, dynamic>;
            print("Processing message: ${message['text']}");
            
            // Convert dynamic metadata to Map<String, dynamic>
            Map<String, dynamic> metadata = {};
            if (message['metadata'] != null) {
              final rawMetadata = message['metadata'] as Map<dynamic, dynamic>;
              rawMetadata.forEach((key, value) {
                metadata[key.toString()] = value;
              });
            }
            
            return {
              'id': entry.key,
              'text': message['text'] ?? '',
              'senderId': message['senderId'],
              'timestamp': message['timestamp'],
              'isRead': message['isRead'] ?? false,
              'type': message['type'] ?? 'text',
              'metadata': metadata,
            };
          }).toList()
            ..sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
        });
  }

  Future<void> sendMessage(
    String matchId,
    String message,
    String senderId,
  ) async {
    final messageId = const Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    print("Sending message to match: $matchId");
    print("Message content: $message");
    print("Sender ID: $senderId");
    print("Message ID: $messageId");

    final messageData = {
      'text': message,
      'senderId': senderId,
      'timestamp': timestamp,
      'isRead': false,
    };
    
    print("Message data: $messageData");

    try {
      // Save message to Realtime Database
      await _database
          .ref()
          .child('matches')
          .child(matchId)
          .child('messages')
          .child(messageId)
          .set(messageData);
      
      print("Message saved to Realtime Database successfully");

      // Also update the match's last message in Firestore
      await _firestore.collection('matches').doc(matchId).update({
        'lastMessage': message,
        'lastMessageTimestamp': timestamp,
      });
      
      print("Match document updated in Firestore");
    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }

  Future<void> sendCustomMessage(
    String matchId,
    Map<String, dynamic> messageData,
  ) async {
    final messageId = const Uuid().v4();
    
    print("Sending custom message to match: $matchId");
    print("Message type: ${messageData['type']}");
    print("Message ID: $messageId");
    
    // Extract data needed for Realtime Database
    final message = {
      'text': messageData['text'] ?? '',
      'senderId': messageData['senderId'],
      'timestamp': messageData['timestamp'],
      'isRead': false,
      'type': messageData['type'],
      'metadata': messageData['metadata'] ?? {},
    };
    
    print("Custom message data: $message");
    
    try {
      // Save message to Realtime Database
      await _database
          .ref()
          .child('matches')
          .child(matchId)
          .child('messages')
          .child(messageId)
          .set(message);
      
      print("Custom message saved to Realtime Database successfully");

      // Update the match's last message in Firestore
      String displayText = messageData['text'] ?? 'Sent a message';
      if (messageData['type'] == 'image') {
        displayText = 'Sent an image';
      } else if (messageData['type'] == 'audio') {
        displayText = 'Sent an audio';
      } else if (messageData['type'] == 'voice') {
        displayText = 'Sent a voice message';
      } else if (messageData['type'] == 'location') {
        displayText = 'Shared location';
      } else if (messageData['type'] == 'contact') {
        displayText = 'Shared a contact';
      } else if (messageData['type'] == 'document') {
        displayText = 'Sent a document';
      }

      await _firestore.collection('matches').doc(matchId).update({
        'lastMessage': displayText,
        'lastMessageTimestamp': messageData['timestamp'],
        'lastMessageType': messageData['type'],
      });
      
      print("Match document updated in Firestore for custom message");
    } catch (e) {
      print("Error sending custom message: $e");
      rethrow;
    }
  }

  Future<void> markMessageAsRead(String matchId, String messageId) async {
    try {
      await _database
          .ref()
          .child('matches')
          .child(matchId)
          .child('messages')
          .child(messageId)
          .update({
            'isRead': true,
          });
    } catch (e) {
      print('Error marking message as read: $e');
      rethrow;
    }
  }

  Future<bool> hasUnreadNotifications() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return false;
      
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking unread notifications: $e');
      return false;
    }
  }

  // Method to increment user statistics
  Future<void> incrementUserStats(String userId, String statType) async {
    try {
      final statsRef = _firestore.collection('user_stats').doc(userId);
      final statsDoc = await statsRef.get();
      
      if (statsDoc.exists) {
        // Increment the specific stat
        await statsRef.update({
          statType: FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Create a new stats document if it doesn't exist
        await statsRef.set({
          'posts': statType == 'posts' ? 1 : 0,
          'started': statType == 'started' ? 1 : 0,
          'passed': statType == 'passed' ? 1 : 0,
          'matches': statType == 'matches' ? 1 : 0,
          'likes': statType == 'likes' ? 1 : 0,
          'superLikes': statType == 'superLikes' ? 1 : 0,
          'lastUpdated': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      print('Updated $statType stat for user $userId');
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }
} 