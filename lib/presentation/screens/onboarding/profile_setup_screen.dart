import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/signup_credentials.dart';
import '../../widgets/common/loading_overlay.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _firebaseService = GetIt.instance<FirebaseService>();
  final _firestore = FirebaseFirestore.instance;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _usernameController = TextEditingController();
  final _jobController = TextEditingController();
  final _educationController = TextEditingController();
  final _heightController = TextEditingController();
  final List<String> _genders = ['Male', 'Female', 'Non-binary', 'Other'];
  final List<File> _selectedPhotos = [];
  
  String? _selectedGender;
  DateTime? _birthdate;
  bool _isLoading = false;
  int _currentStep = 0;
  
  // Additional profile fields
  String? _selectedRelationshipStatus;
  String? _selectedZodiacSign;
  List<String> _selectedLanguages = [];
  List<String> _selectedHobbies = [];
  List<String> _selectedPersonality = [];
  String? _preferredGender;
  String? _preferredAgeRange;
  String? _preferredHeightRange;

  // Available options
  final List<String> _relationshipOptions = ['Single', 'In a relationship', 'Married', 'Divorced', 'Complicated'];
  final List<String> _zodiacSigns = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];
  final List<String> _languageOptions = ['English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese', 'Russian', 'Japanese', 'Korean', 'Chinese', 'Arabic', 'Hindi'];
  final List<String> _hobbyOptions = ['Photography', 'Guitar', 'Cooking', 'Hiking', 'Reading', 'Painting', 'Singing', 'Dancing', 'Writing', 'Gaming', 'Fitness', 'Yoga', 'Meditation', 'Movies', 'Theater', 'Fashion', 'Beauty'];
  final List<String> _personalityOptions = ['Adventurous', 'Creative', 'Ambitious', 'Friendly', 'Funny', 'Intelligent', 'Kind', 'Loyal', 'Passionate', 'Patient', 'Romantic', 'Spontaneous', 'Thoughtful', 'Witty'];
  final List<String> _preferredGenderOptions = ['Male', 'Female', 'Non-binary', 'All'];
  final List<String> _preferredAgeRanges = ['18-25', '25-30', '30-35', '35-40', '40+'];
  final List<String> _preferredHeightRanges = ['5\'0\"-5\'5\"', '5\'5\"-5\'10\"', '5\'10\"-6\'0\"', '6\'0\"-6\'5\"', '6\'5\"+'];

  // Interests and Preferences
  final List<String> _availableInterests = [
    'Travel ✈️', 'Music 🎵', 'Sports 🏃‍♂️', 'Art 🎨', 
    'Food 🍕', 'Movies 🎬', 'Reading 📚', 'Gaming 🎮',
    'Photography 📸', 'Cooking 👨‍🍳', 'Dancing 💃', 'Fitness 💪',
    'Nature 🌿', 'Technology 💻', 'Fashion 👗', 'Pets 🐾',
    'Yoga 🧘‍♀️', 'Writing ✍️', 'Hiking 🏔️', 'Coffee ☕',
    'Wine 🍷', 'Meditation 🧘‍♂️', 'Shopping 🛍️', 'Gardening 🌱',
    'Music Production 🎹', 'Languages 🗣️', 'Board Games 🎲', 'Volunteering 🤝',
    'Astronomy 🔭', 'Politics 🗳️', 'History 📚', 'Science 🔬'
  ];
  
  Set<String> _selectedInterests = {};
  double _preferredDistance = 50;
  String? _lookingFor;
  
  // Lifestyle choices
  Map<String, bool> _lifestyle = {
    'Smoke': false,
    'Drink': false,
    'Exercise': false,
    'Religion Important': false,
  };

  final List<String> _relationshipGoals = [
    'Casual dating 🎭',
    'Serious relationship 💝',
    'Short-term relationship 💫',
    'Long-term commitment 💍',
    'Marriage minded 👰',
    'Still figuring it out 🤔',
    'Friendship first 🤝',
    'Adventure partner 🌎'
  ];

  SignupCredentials? _signupCredentials;
  String? _coordinates;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get credentials from route arguments
      final route = ModalRoute.of(context);
      if (route != null) {
        final args = route.settings.arguments;
        print('Route arguments in initState: $args');
        
        if (args is SignupCredentials) {
          print('Setting signup credentials: ${args.email}');
          setState(() {
            _signupCredentials = args;
          });
        } else {
          print('Invalid arguments type: ${args?.runtimeType}');
        }
      }
    });
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (_selectedPhotos.length < 6) { // Maximum 6 photos
          _selectedPhotos.add(File(pickedFile.path));
        }
      });
    }
  }

  bool _canProceedFromBasicInfo() {
    return _firstNameController.text.isNotEmpty &&
           _lastNameController.text.isNotEmpty &&
           _selectedGender != null;
  }

  bool _canProceedFromBirthdate() {
    return _birthdate != null;
  }

  bool _canProceedFromLocation() {
    return _locationController.text.isNotEmpty;
  }

  bool _canProceedFromPhotos() {
    return _selectedPhotos.length >= 3;
  }

  bool _canProceedFromInterests() {
    return _selectedInterests.length >= 3;
  }

  bool _canProceedFromLifestyle() {
    return true; // Optional section
  }

  bool _canProceedFromRelationshipGoals() {
    return _lookingFor != null;
  }

  bool _canProceedFromPersonalInfo() {
    return _jobController.text.isNotEmpty &&
           _educationController.text.isNotEmpty &&
           _heightController.text.isNotEmpty &&
           _selectedRelationshipStatus != null;
  }

  bool _canProceedFromLanguages() {
    return _selectedLanguages.isNotEmpty;
  }

  bool _canProceedFromHobbies() {
    return _selectedHobbies.isNotEmpty;
  }

  bool _canProceedFromPersonality() {
    return _selectedPersonality.isNotEmpty;
  }

  bool _canProceedFromPreferences() {
    return _preferredGender != null &&
           _preferredAgeRange != null &&
           _preferredHeightRange != null;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _proceedToNextStep() {
    bool canProceed = false;
    String errorMessage = '';

    switch (_currentStep) {
      case 0: // Basic Info
        canProceed = _canProceedFromBasicInfo();
        errorMessage = 'Please fill in all required fields (First Name, Last Name, and Gender)';
        break;
      case 1: // Birthdate
        canProceed = _canProceedFromBirthdate();
        errorMessage = 'Please select your birthdate';
        break;
      case 2: // Personal Info
        canProceed = _canProceedFromPersonalInfo();
        errorMessage = 'Please fill in all required fields (Job/Profession, Education, and Height)';
        break;
      case 3: // Location
        canProceed = _canProceedFromLocation();
        errorMessage = 'Please enter your location';
        break;
      case 4: // Photos
        canProceed = _canProceedFromPhotos();
        errorMessage = 'Please upload at least 3 photos';
        break;
      case 5: // Languages
        canProceed = _canProceedFromLanguages();
        errorMessage = 'Please select at least one language';
        break;
      case 6: // Interests
        canProceed = _canProceedFromInterests();
        errorMessage = 'Please select at least 3 interests';
        break;
      case 7: // Hobbies
        canProceed = _canProceedFromHobbies();
        errorMessage = 'Please select at least one hobby';
        break;
      case 8: // Personality
        canProceed = _canProceedFromPersonality();
        errorMessage = 'Please select at least one personality trait';
        break;
      case 9: // Lifestyle
        canProceed = _canProceedFromLifestyle();
        break;
      case 10: // Preferences
        canProceed = _canProceedFromPreferences();
        errorMessage = 'Please set your preferences';
        break;
      case 11: // Relationship Goals
        canProceed = _canProceedFromRelationshipGoals();
        errorMessage = 'Please select what you\'re looking for';
        break;
    }

    if (canProceed) {
      setState(() {
        _currentStep++;
      });
    } else {
      _showValidationError(errorMessage);
    }
  }

  Future<void> _submitProfile() async {
    if (!_canProceedFromRelationshipGoals()) {
      _showValidationError('Please select what you\'re looking for');
      return;
    }

    // Get credentials from route arguments again in case they were lost
    if (_signupCredentials == null) {
      final route = ModalRoute.of(context);
      if (route != null) {
        final args = route.settings.arguments;
        print('Getting credentials from route in submit: $args');
        if (args is SignupCredentials) {
          _signupCredentials = args;
        }
      }
    }

    if (_signupCredentials == null) {
      print('Signup credentials are null');
      print('Current route: ${ModalRoute.of(context)?.settings.name}');
      print('Route arguments: ${ModalRoute.of(context)?.settings.arguments}');
      _showValidationError('Signup credentials not found. Please try signing up again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting authentication process with email: ${_signupCredentials!.email}');
      
      // First, authenticate with Firebase
      final auth = FirebaseAuth.instance;
      
      // Create user with email and password
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _signupCredentials!.email,
        password: _signupCredentials!.password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Failed to create user account');
      }
      
      final userId = userCredential.user!.uid;
      print('User account created successfully with ID: $userId');

      // Upload photos
      print('Starting photo upload...');
      List<String> photoUrls = [];
      for (var photo in _selectedPhotos) {
        String url = await _firebaseService.uploadProfileImage(photo);
        photoUrls.add(url);
      }
      print('Photo upload completed');

      // Create user profile in Firestore
      print('Creating user profile...');
      await _firebaseService.createUserProfile(userId, {
        'userId': userId,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'username': _usernameController.text,
        'birthdate': _birthdate != null ? Timestamp.fromDate(_birthdate!) : null,
        'gender': _selectedGender,
        'location': _coordinates ?? '',
        'locationText': _locationController.text,
        'bio': _bioController.text.isEmpty ? null : _bioController.text,
        'job': _jobController.text,
        'education': _educationController.text,
        'height': _heightController.text,
        'relationshipStatus': _selectedRelationshipStatus,
        'zodiacSign': _selectedZodiacSign,
        'languages': _selectedLanguages,
        'photoUrls': photoUrls,
        'profilePicture': photoUrls.isNotEmpty ? photoUrls[0] : null,
        'interests': _selectedInterests.toList(),
        'hobbies': _selectedHobbies,
        'personality': _selectedPersonality,
        'lookingFor': _lookingFor,
        'preferredDistance': _preferredDistance,
        'preferredGender': _preferredGender,
        'preferredAgeRange': _preferredAgeRange,
        'preferredHeightRange': _preferredHeightRange,
        'lifestyle': {
          'smokes': _lifestyle['Smoke'] ?? false,
          'drinks': _lifestyle['Drink'] ?? false,
          'exercises': _lifestyle['Exercise'] ?? false,
          'religionImportant': _lifestyle['Religion Important'] ?? false,
        },
        'favoriteMusic': [],
        'favoriteMovies': [],
        'favoriteBooks': [],
        'favoriteFood': [],
        'favoriteSports': [],
        'favoriteTravel': [],
        'isVerified': false,
        'premium': false,
        'isActive': true,
        'isProfileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'isOnline': true,
        'userName': _usernameController.text,
        'userImage': photoUrls.isNotEmpty ? photoUrls[0] : null,
        'filters': {
          'ageRange': {
            'min': 18,
            'max': 35,
          },
          'distanceRange': {
            'min': 0,
            'max': _preferredDistance.round(),
          },
          'gender': _preferredGender ?? 'Everyone',
          'interests': _selectedInterests.toList(),
        },
        'stats': {
          'posts': 0,
          'started': 0,
          'passed': 0,
          'matches': 0,
          'likes': 0,
          'superLikes': 0,
        },
        'settings': {
          'notifications': true,
          'location': true,
          'showAge': true,
          'showDistance': true,
          'showOnlineStatus': true,
        },
      });
      print('User profile created successfully');

      // Create user stats document
      await _firestore.collection('user_stats').doc(userId).set({
        'posts': 0,
        'started': 0,
        'passed': 0,
        'matches': 0,
        'likes': 0,
        'superLikes': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Initialize matches collection
      await _firestore.collection('matches').doc(userId).set({
        'users': [],
        'matchedAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'unread': {},
      });

      // Initialize stories collection
      await _firestore.collection('stories').doc(userId).set({
        'userName': _usernameController.text,
        'userImage': photoUrls.isNotEmpty ? photoUrls[0] : null,
        'isOnline': true,
        'viewers': [],
        'expiresAt': FieldValue.serverTimestamp(),
        'stories': [],
      });

      // Sign in the user
      await auth.signInWithEmailAndPassword(
        email: _signupCredentials!.email,
        password: _signupCredentials!.password,
      );
      print('User signed in successfully');

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to create account';
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered. Please try logging in.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/Password accounts are not enabled.';
          break;
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error during profile setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Request location permission first
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to get your location'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Check if location service is enabled
      final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final address = '${place.locality ?? ''}, ${place.country ?? ''}';
        
        setState(() {
          _locationController.text = address;
          // Store coordinates in the format "latitude,longitude"
          _coordinates = '${position.latitude},${position.longitude}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildBasicInfoStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us a bit about yourself',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help other users know the real you, keep it fun and genuine.',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _genders.map((String gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(gender),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedGender = newValue;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add more details about yourself to help others get to know you better.',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _jobController,
            decoration: InputDecoration(
              labelText: 'Job/Profession',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _educationController,
            decoration: InputDecoration(
              labelText: 'Education',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _heightController,
            decoration: InputDecoration(
              labelText: 'Height',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRelationshipStatus,
            decoration: InputDecoration(
              labelText: 'Relationship Status',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _relationshipOptions.map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedRelationshipStatus = newValue;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdateStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your date of birth?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your profile does not display your birthdate, only your age.',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _birthdate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Birthdate',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _birthdate != null
                    ? DateFormat('MMMM d, yyyy').format(_birthdate!)
                    : 'Select your birthdate',
              ),
            ),
          ),
          if (_birthdate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cake_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'You\'re ${DateTime.now().year - _birthdate!.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where are you located?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us find people near you',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _locationController,
            readOnly: true, // Make it read-only since we'll use the location button
            decoration: InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _getCurrentLocation,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload your favourite pictures',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload at least 3 photos to show a bit of your life, personality, and what you\'re about',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              if (index < _selectedPhotos.length) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedPhotos[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPhotos.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Languages',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the languages you speak',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languageOptions.map((language) {
              final isSelected = _selectedLanguages.contains(language);
              return FilterChip(
                label: Text(language),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLanguages.add(language);
                    } else {
                      _selectedLanguages.remove(language);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are your interests?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your interests to help us find better matches for you',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey[100],
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHobbiesStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hobbies',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your hobbies and activities you enjoy',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hobbyOptions.map((hobby) {
              final isSelected = _selectedHobbies.contains(hobby);
              return FilterChip(
                label: Text(hobby),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedHobbies.add(hobby);
                    } else {
                      _selectedHobbies.remove(hobby);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personality',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select traits that describe your personality',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _personalityOptions.map((trait) {
              final isSelected = _selectedPersonality.contains(trait);
              return FilterChip(
                label: Text(trait),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPersonality.add(trait);
                    } else {
                      _selectedPersonality.remove(trait);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about your lifestyle',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help others know more about your lifestyle choices',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ..._lifestyle.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  title: Text(entry.key),
                  value: entry.value,
                  onChanged: (bool? value) {
                    setState(() {
                      _lifestyle[entry.key] = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferences',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your preferences for potential matches',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            value: _preferredGender,
            decoration: InputDecoration(
              labelText: 'Preferred Gender',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _preferredGenderOptions.map((String gender) {
              return DropdownMenuItem<String>(
                value: gender,
                child: Text(gender),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _preferredGender = newValue;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _preferredAgeRange,
            decoration: InputDecoration(
              labelText: 'Preferred Age Range',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _preferredAgeRanges.map((String range) {
              return DropdownMenuItem<String>(
                value: range,
                child: Text(range),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _preferredAgeRange = newValue;
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _preferredHeightRange,
            decoration: InputDecoration(
              labelText: 'Preferred Height Range',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _preferredHeightRanges.map((String range) {
              return DropdownMenuItem<String>(
                value: range,
                child: Text(range),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _preferredHeightRange = newValue;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipGoalsStep() {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are you looking for?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the type of relationship you\'re hoping to find',
            style: TextStyles.bodyText1Light.copyWith(
              color: AppColors.textLightSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(
            _relationshipGoals.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _lookingFor = _relationshipGoals[index];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _lookingFor == _relationshipGoals[index]
                          ? AppColors.primary
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _relationshipGoals[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _lookingFor == _relationshipGoals[index]
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (_lookingFor == _relationshipGoals[index])
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> steps = [
      _buildBasicInfoStep(),
      _buildBirthdateStep(),
      _buildPersonalInfoStep(),
      _buildLocationStep(),
      _buildPhotosStep(),
      _buildLanguagesStep(),
      _buildInterestsStep(),
      _buildHobbiesStep(),
      _buildPersonalityStep(),
      _buildLifestyleStep(),
      _buildPreferencesStep(),
      _buildRelationshipGoalsStep(),
    ];

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / steps.length,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: steps[_currentStep],
                  ),
                ),
              ),
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _currentStep--;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0)
                      const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_currentStep < steps.length - 1) {
                                  _proceedToNextStep();
                                } else {
                                  _submitProfile();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                            _currentStep < steps.length - 1 ? 'Next' : 'Complete',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                        ),
                      ),
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _usernameController.dispose();
    _jobController.dispose();
    _educationController.dispose();
    _heightController.dispose();
    super.dispose();
  }
} 