import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/services/firebase_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firebaseService = GetIt.instance<FirebaseService>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _jobController = TextEditingController();
  final _educationController = TextEditingController();
  final _heightController = TextEditingController();

  // Profile Pictures
  List<String> _profilePictures = [];
  String? _profilePicture; // Separate field for main profile picture
  int _mainProfilePictureIndex = 0;

  // Selected values
  String _selectedRelationshipStatus = 'Single';
  String _selectedZodiacSign = 'Leo';
  List<String> _selectedLanguages = [];
  List<String> _selectedInterests = [];
  List<String> _selectedHobbies = [];
  List<String> _selectedPersonality = [];
  List<String> _selectedLookingFor = [];
  String _selectedPreferredGender = 'All';
  DateTime? _birthdate;
  String _selectedGender = 'Male';

  // Available options
  final List<String> _relationshipOptions = ['Single', 'In a relationship', 'Married', 'Divorced', 'Complicated'];
  final List<String> _zodiacSigns = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];
  final List<String> _languageOptions = ['English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese', 'Russian', 'Japanese', 'Korean', 'Chinese', 'Arabic', 'Hindi'];
  final List<String> _interestOptions = ['Photography', 'Travel', 'Coffee', 'Technology', 'Music', 'Hiking', 'Cooking', 'Reading', 'Sports', 'Art', 'Dancing', 'Writing', 'Gaming', 'Fitness', 'Yoga', 'Meditation', 'Movies', 'Theater', 'Fashion', 'Beauty'];
  final List<String> _hobbyOptions = ['Photography', 'Guitar', 'Cooking', 'Hiking', 'Reading', 'Painting', 'Singing', 'Dancing', 'Writing', 'Gaming', 'Fitness', 'Yoga', 'Meditation', 'Movies', 'Theater', 'Fashion', 'Beauty'];
  final List<String> _personalityOptions = ['Adventurous', 'Creative', 'Ambitious', 'Friendly', 'Funny', 'Intelligent', 'Kind', 'Loyal', 'Passionate', 'Patient', 'Romantic', 'Spontaneous', 'Thoughtful', 'Witty'];
  final List<String> _lookingForOptions = ['Long-term relationship', 'Friendship', 'Travel buddies', 'Casual dating', 'Marriage', 'Networking'];
  final List<String> _preferredGenderOptions = ['Male', 'Female', 'Non-binary', 'All'];
  final List<String> _genderOptions = ['Male', 'Female', 'Non-binary', 'Other'];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        setState(() {
          _error = 'User profile not found';
          _isLoading = false;
        });
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>;
      
      // Helper function to safely convert to list
      List<dynamic> safeList(dynamic value) {
        if (value == null) return [];
        if (value is List) return value;
        if (value is String) return [value];
        return [];
      }

      // Helper function to safely get string value
      String safeString(dynamic value) {
        if (value == null) return '';
        return value.toString();
      }

      // Helper function to validate dropdown value
      String validateDropdownValue(String value, List<String> options) {
        if (value.isEmpty || !options.contains(value)) {
          return options.first;
        }
        return value;
      }

      setState(() {
        _nameController.text = '${safeString(data['firstName'])} ${safeString(data['lastName'])}';
        _usernameController.text = safeString(data['username']);
        _bioController.text = safeString(data['bio']);
        _locationController.text = safeString(data['location']);
        _jobController.text = safeString(data['job']);
        _educationController.text = safeString(data['education']);
        _heightController.text = safeString(data['height']);
        
        // Load gender if it exists
        _selectedGender = validateDropdownValue(
          safeString(data['gender']),
          _genderOptions
        );
        
        // Load profile picture and additional photos separately
        _profilePicture = safeString(data['profilePicture']);
        _profilePictures = safeList(data['photoUrls']).map((e) => e.toString()).toList();
        
        // If profile picture is not set but we have additional photos, use the first one
        if (_profilePicture == null || _profilePicture!.isEmpty) {
          if (_profilePictures.isNotEmpty) {
            _profilePicture = _profilePictures[0];
          }
        }
        
        _selectedRelationshipStatus = validateDropdownValue(
          safeString(data['relationshipStatus']),
          _relationshipOptions,
        );
        _selectedZodiacSign = validateDropdownValue(
          safeString(data['zodiacSign']),
          _zodiacSigns,
        );
        _selectedPreferredGender = validateDropdownValue(
          safeString(data['preferredGender']),
          _preferredGenderOptions,
        );
        
        // Load birthdate if it exists
        if (data['birthdate'] != null) {
          try {
            if (data['birthdate'] is Timestamp) {
              _birthdate = (data['birthdate'] as Timestamp).toDate();
            } else if (data['birthdate'] is String) {
              _birthdate = DateTime.parse(data['birthdate'] as String);
            }
          } catch (e) {
            print('Error parsing birthdate: $e');
          }
        }
        
        _selectedLanguages = safeList(data['languages'])
            .map((e) => e.toString())
            .where((lang) => _languageOptions.contains(lang))
            .toList();
        _selectedInterests = safeList(data['interests'])
            .map((e) => e.toString())
            .where((interest) => _interestOptions.contains(interest))
            .toList();
        _selectedHobbies = safeList(data['hobbies'])
            .map((e) => e.toString())
            .where((hobby) => _hobbyOptions.contains(hobby))
            .toList();
        _selectedPersonality = safeList(data['personality'])
            .map((e) => e.toString())
            .where((trait) => _personalityOptions.contains(trait))
            .toList();
        _selectedLookingFor = safeList(data['lookingFor'])
            .map((e) => e.toString())
            .where((option) => _lookingForOptions.contains(option))
            .toList();
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _jobController.dispose();
    _educationController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: AppColors.backgroundDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Header background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.4),
                          AppColors.backgroundDark.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                  // Profile picture
                  Center(
                    child: _buildProfileHeader(),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                color: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _saveProfile,
                ),
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: bottomPadding + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Photo gallery
                    _buildPhotoGallery(),
                    
                    const SizedBox(height: 24),
                    _buildEditSections(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveProfile,
        backgroundColor: AppColors.primary,
        label: const Text('SAVE PROFILE'),
        icon: const Icon(Icons.save),
      ),
    );
  }
  
  Widget _buildProfileHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: _profilePicture != null
                ? CachedNetworkImage(
                    imageUrl: _profilePicture!,
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
                        size: 48,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[900],
                    child: const Icon(
                      Icons.person,
                      color: Colors.white38,
                      size: 48,
                    ),
                  ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.backgroundDark,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 20),
              color: Colors.white,
              onPressed: _pickAndUploadProfilePicture,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPhotoGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Photo Gallery',
              style: TextStyles.subtitle1Dark.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${_profilePictures.length}/6',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Add multiple photos to increase your chances of matching',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _profilePictures.length + 1,
            itemBuilder: (context, index) {
              if (index == _profilePictures.length) {
                // Add new picture button
                return Padding(
                  key: const ValueKey('add_button'),
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: _profilePictures.length < 6 ? _pickAndUploadAdditionalPhoto : null,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _profilePictures.length < 6 
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            color: _profilePictures.length < 6 ? AppColors.primary : Colors.white30,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              color: _profilePictures.length < 6 ? Colors.white70 : Colors.white30,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              return Padding(
                key: ValueKey(_profilePictures[index]),
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: _profilePictures[index],
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
                    // Delete Button 
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () => _deleteAdditionalPhoto(index),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditSections() {
    return Column(
      children: [
        // Here we'll build each section one by one
        _buildBasicInfoSection(),
        const SizedBox(height: 24),
        _buildPersonalInfoSection(),
        const SizedBox(height: 24),
        _buildPersonalitySection(),
        const SizedBox(height: 24),
        _buildInterestsSection(),
        const SizedBox(height: 24),
        _buildLanguagesSection(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Info',
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Name',
          icon: Icons.person_outline,
        ),
        _buildTextField(
          controller: _usernameController,
          label: 'Username',
          icon: Icons.alternate_email,
        ),
        _buildBirthdatePicker(),
        _buildTextField(
          controller: _bioController,
          label: 'Bio',
          icon: Icons.edit_note,
          maxLines: 3,
        ),
        _buildLocationField(),
      ],
    );
  }

  Widget _buildBirthdatePicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.cake_outlined, color: AppColors.primary, size: 14),
                const SizedBox(width: 8),
                Text(
                  'Birthdate',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _pickBirthdate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                color: Colors.white.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _birthdate != null
                          ? '${_birthdate!.day}/${_birthdate!.month}/${_birthdate!.year} (${_calculateAge(_birthdate!)} years old)'
                          : 'Select your birthdate',
                      style: TextStyle(
                        color: _birthdate != null ? Colors.white : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Personal Info',
      children: [
        _buildTextField(
          controller: _locationController,
          label: 'Location',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedGender,
          label: 'Gender',
          icon: Icons.person_outline,
          items: _genderOptions,
          onChanged: (value) {
            setState(() {
              _selectedGender = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _jobController,
          label: 'Work',
          icon: Icons.work_outline,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _educationController,
          label: 'Education',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _heightController,
          label: 'Height',
          icon: Icons.height,
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedRelationshipStatus,
          label: 'Relationship Status',
          icon: Icons.favorite_outline,
          items: _relationshipOptions,
          onChanged: (value) {
            setState(() {
              _selectedRelationshipStatus = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedZodiacSign,
          label: 'Zodiac Sign',
          icon: Icons.star_outline,
          items: _zodiacSigns,
          onChanged: (value) {
            setState(() {
              _selectedZodiacSign = value!;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          value: _selectedPreferredGender,
          label: 'Preferred Gender',
          icon: Icons.people_outline,
          items: _preferredGenderOptions,
          onChanged: (value) {
            setState(() {
              _selectedPreferredGender = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPersonalitySection() {
    return _buildSection(
      title: 'Personality & Goals',
      children: [
        _buildChipSelector(
          title: 'Personality',
          selectedItems: _selectedPersonality,
          options: _personalityOptions,
          onChanged: (items) {
            setState(() {
              _selectedPersonality = items;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildChipSelector(
          title: 'Looking For',
          selectedItems: _selectedLookingFor,
          options: _lookingForOptions,
          onChanged: (items) {
            setState(() {
              _selectedLookingFor = items;
            });
          },
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return _buildSection(
      title: 'Interests & Hobbies',
      children: [
        _buildChipSelector(
          title: 'Interests',
          selectedItems: _selectedInterests,
          options: _interestOptions,
          onChanged: (items) {
            setState(() {
              _selectedInterests = items;
            });
          },
        ),
        const SizedBox(height: 16),
        _buildChipSelector(
          title: 'Hobbies',
          selectedItems: _selectedHobbies,
          options: _hobbyOptions,
          onChanged: (items) {
            setState(() {
              _selectedHobbies = items;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return _buildSection(
      title: 'Languages',
      children: [
        _buildChipSelector(
          title: 'Languages',
          selectedItems: _selectedLanguages,
          options: _languageOptions,
          onChanged: (items) {
            setState(() {
              _selectedLanguages = items;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppColors.primary, size: 14),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: _locationController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your location',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location, color: AppColors.primary),
                onPressed: () {
                  // TODO: Implement location picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Current location detection coming soon!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getSectionIcon(title),
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyles.subtitle1Dark.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Basic Info':
        return Icons.person_outline;
      case 'Personal Info':
        return Icons.info_outline;
      case 'Personality & Goals':
        return Icons.psychology_outlined;
      case 'Interests & Hobbies':
        return Icons.interests_outlined;
      case 'Languages':
        return Icons.language_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 14),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 14),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          DropdownButtonFormField<String>(
            value: value,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
            ),
            dropdownColor: AppColors.backgroundDark,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildChipSelector({
    required String title,
    required List<String> selectedItems,
    required List<String> options,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              children: [
                Icon(_getChipSelectorIcon(title), color: AppColors.primary, size: 14),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${selectedItems.length} selected',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options.map((option) => GestureDetector(
                onTap: () {
                  final newItems = List<String>.from(selectedItems);
                  if (selectedItems.contains(option)) {
                    newItems.remove(option);
                  } else {
                    newItems.add(option);
                  }
                  onChanged(newItems);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedItems.contains(option) 
                        ? AppColors.primary.withOpacity(0.2) 
                        : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedItems.contains(option) 
                          ? AppColors.primary 
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selectedItems.contains(option))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ),
                      Text(
                        option,
                        style: TextStyle(
                          color: selectedItems.contains(option) 
                              ? Colors.white 
                              : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getChipSelectorIcon(String title) {
    switch (title) {
      case 'Personality':
        return Icons.psychology_outlined;
      case 'Looking For':
        return Icons.favorite_outline;
      case 'Interests':
        return Icons.interests_outlined;
      case 'Hobbies':
        return Icons.sports_esports_outlined;
      case 'Languages':
        return Icons.translate_outlined;
      default:
        return Icons.label_outline;
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // Show confirmation dialog
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.backgroundDark,
          title: const Text(
            'Save Changes?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to save these changes to your profile?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Save',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );

      // If user confirmed, proceed with saving
      if (shouldSave == true) {
        try {
          final userId = _auth.currentUser?.uid;
          if (userId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('User not logged in'),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }

          // Split name into first and last name
          final nameParts = _nameController.text.split(' ');
          final firstName = nameParts.first;
          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

          // Create a map of all the updated data
          final updatedData = {
            'firstName': firstName,
            'lastName': lastName,
            'username': _usernameController.text,
            'bio': _bioController.text,
            'location': _locationController.text,
            'job': _jobController.text,
            'education': _educationController.text,
            'height': _heightController.text,
            'birthdate': _birthdate != null ? Timestamp.fromDate(_birthdate!) : null,
            'age': _birthdate != null ? _calculateAge(_birthdate!) : null,
            'gender': _selectedGender,
            'relationshipStatus': _selectedRelationshipStatus,
            'zodiacSign': _selectedZodiacSign,
            'languages': _selectedLanguages,
            'interests': _selectedInterests,
            'hobbies': _selectedHobbies,
            'personality': _selectedPersonality,
            'lookingFor': _selectedLookingFor,
            'preferredGender': _selectedPreferredGender,
            'profilePicture': _profilePicture,
            'photoUrls': _profilePictures,
            'updatedAt': FieldValue.serverTimestamp(),
          };

          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          // Update the user's profile in Firestore
          await _firestore.collection('users').doc(userId).update(updatedData);
          
          // Get current user stats
          final userStatsDoc = await _firestore.collection('user_stats').doc(userId).get();
          
          if (userStatsDoc.exists) {
            // Update existing stats document
            await _firestore.collection('user_stats').doc(userId).update({
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          } else {
            // Create new stats document if it doesn't exist
            await _firestore.collection('user_stats').doc(userId).set({
              'posts': 0,
              'started': 0,
              'passed': 0,
              'matches': 0,
              'likes': 0,
              'superLikes': 0,
              'lastUpdated': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });
          }

          // Close loading indicator
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
          }

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          }

          // Create a complete user data map with all fields
          final completeUserData = {
            ...updatedData,
            'id': userId,
            'email': _auth.currentUser?.email,
            'createdAt': FieldValue.serverTimestamp(),
          };

          // Fetch latest stats to return with userData
          final updatedStatsDoc = await _firestore.collection('user_stats').doc(userId).get();
          final statsData = updatedStatsDoc.data() as Map<String, dynamic>? ?? {};
          
          // Add stats to the data returned to the profile screen
          final returnData = {
            ...completeUserData,
            'stats': statsData,
          };

          // Pass the complete updated data back to the profile screen
          if (mounted) {
            Navigator.pop(context, returnData);
          }
        } catch (e) {
          // Close loading indicator if it's still showing
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save profile: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _pickAndUploadProfilePicture() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        // Upload the image to Firebase Storage
        final file = File(pickedFile.path);
        final fileName = 'profile_pictures/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child(fileName);
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();

        // Update the profile picture
        setState(() {
          _profilePicture = downloadUrl;
        });

        // Close loading indicator
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Close loading indicator if it's still showing
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile picture: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadAdditionalPhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        // Upload the image to Firebase Storage
        final file = File(pickedFile.path);
        final fileName = 'additional_photos/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child(fileName);
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();

        // Add the new photo to the list
        setState(() {
          _profilePictures.add(downloadUrl);
        });

        // Close loading indicator
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Close loading indicator if it's still showing
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAdditionalPhoto(int index) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Get the photo URL
      final photoUrl = _profilePictures[index];

      // Delete from Firebase Storage
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();

      // Remove from the list
      setState(() {
        _profilePictures.removeAt(index);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickBirthdate() async {
    final initialDate = _birthdate ?? DateTime.now().subtract(const Duration(days: 365 * 25));
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Must be at least 18
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.backgroundDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _birthdate) {
      setState(() {
        _birthdate = pickedDate;
      });
    }
  }

  int _calculateAge(DateTime birthdate) {
    final today = DateTime.now();
    var age = today.year - birthdate.year;
    final monthDifference = today.month - birthdate.month;
    final dayDifference = today.day - birthdate.day;

    if (monthDifference < 0 || (monthDifference == 0 && dayDifference < 0)) {
      age--;
    }

    return age;
  }
} 