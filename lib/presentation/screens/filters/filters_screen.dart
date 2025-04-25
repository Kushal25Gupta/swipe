import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/common/loading_overlay.dart';

enum Gender { Male, Female, Everyone }

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({Key? key}) : super(key: key);

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  // Filter options
  RangeValues _ageRange = const RangeValues(18, 35);
  RangeValues _distanceRange = const RangeValues(1, 100);
  Gender _selectedGender = Gender.Everyone;
  final Set<String> _selectedInterests = {};
  
  // Advanced filters
  bool _onlyVerified = false;
  bool _onlyWithBio = false;
  bool _hideAlreadyMatched = true;
  bool _sortByActivity = false;
  
  // Premium filters
  RangeValues _heightRange = const RangeValues(150, 190);
  bool _heightFilterEnabled = false;
  
  // Status flags
  bool _isPremium = false; // Set to true for premium users
  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }
      
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!docSnapshot.exists || !docSnapshot.data()!.containsKey('filters')) {
        // If no filters exist yet, keep the defaults
        return;
      }
      
      final filters = docSnapshot.data()!['filters'] as Map<String, dynamic>;
      
      // Load premium status
      final userData = docSnapshot.data()!;
      _isPremium = userData['isPremium'] == true;
      
      // Load age range
      if (filters.containsKey('ageRange')) {
        final ageRange = filters['ageRange'] as Map<String, dynamic>;
        _ageRange = RangeValues(
          (ageRange['min'] as num).toDouble(),
          (ageRange['max'] as num).toDouble(),
        );
      }
      
      // Load distance range
      if (filters.containsKey('distanceRange')) {
        final distanceRange = filters['distanceRange'] as Map<String, dynamic>;
        _distanceRange = RangeValues(
          (distanceRange['min'] as num).toDouble(),
          (distanceRange['max'] as num).toDouble(),
        );
      }
      
      // Load gender preference
      if (filters.containsKey('gender')) {
        final genderString = filters['gender'] as String;
        _selectedGender = Gender.values.firstWhere(
          (g) => g.toString().split('.').last == genderString,
          orElse: () => Gender.Everyone,
        );
      }
      
      // Load interests
      if (filters.containsKey('interests')) {
        final interests = filters['interests'] as List<dynamic>;
        _selectedInterests.clear();
        _selectedInterests.addAll(interests.map((i) => i.toString()));
      }
      
      // Load advanced filters
      if (filters.containsKey('advancedFilters')) {
        final advFilters = filters['advancedFilters'] as Map<String, dynamic>;
        _onlyVerified = advFilters['onlyVerified'] as bool? ?? false;
        _onlyWithBio = advFilters['onlyWithBio'] as bool? ?? false;
        _hideAlreadyMatched = advFilters['hideAlreadyMatched'] as bool? ?? false;
        _sortByActivity = advFilters['sortByActivity'] as bool? ?? false;
      }
      
      // Load premium filters if user is premium
      if (_isPremium && filters.containsKey('premiumFilters')) {
        final premiumFilters = filters['premiumFilters'] as Map<String, dynamic>;
        _heightFilterEnabled = premiumFilters['heightFilterEnabled'] as bool? ?? false;
        
        if (premiumFilters.containsKey('heightRange')) {
          final heightRange = premiumFilters['heightRange'] as Map<String, dynamic>;
          _heightRange = RangeValues(
            (heightRange['min'] as num).toDouble(),
            (heightRange['max'] as num).toDouble(),
          );
        }
      }
    } catch (e) {
      print('Error loading filters: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper widget for section headers
  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper widget for range sliders
  Widget _buildRangeSliderSection({
    required String title,
    required String valueLabel,
    required RangeValues values,
    required RangeValues min,
    required RangeValues max,
    required Function(RangeValues) onChanged,
  }) {
    // Ensure values are within the min/max bounds
    final safeValues = RangeValues(
      values.start.clamp(min.start, max.end),
      values.end.clamp(min.start, max.end),
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: safeValues,
          min: min.start,
          max: max.end,
          divisions: (max.end - min.start).toInt(),
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ],
    );
  }

  // Helper widget for section headers
  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: trailing ??
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of sample interests - would be loaded from database in real app
    final interests = [
      'Travel', 'Music', 'Sports', 'Art', 'Food',
      'Movies', 'Fitness', 'Reading', 'Photography',
      'Dancing', 'Cooking', 'Gaming', 'Nature',
    ];

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Filter Preferences'),
          actions: [
            // Always show Save button; disable while saving
            TextButton(
              onPressed: _isSaving ? null : _saveFilters,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Filters Section
            _buildSectionHeader('Basic Filters'),
            const SizedBox(height: 16),
            
            // Age Range
            _buildRangeSliderSection(
              title: 'Age',
              valueLabel: '${_ageRange.start.toInt()} - ${_ageRange.end.toInt()} years',
              values: _ageRange,
              min: const RangeValues(18, 18),
              max: const RangeValues(65, 65),
              onChanged: (values) {
                setState(() {
                  _ageRange = values;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Distance Range
            _buildRangeSliderSection(
              title: 'Maximum Distance',
              valueLabel: '${_distanceRange.end.toInt()} km',
              values: _distanceRange,
              min: const RangeValues(1, 1),
              max: const RangeValues(150, 150),
              onChanged: (values) {
                setState(() {
                  _distanceRange = RangeValues(_distanceRange.start, values.end);
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Gender Preference
            Text(
              'Show me',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: Gender.values.map((gender) {
                return ChoiceChip(
                  label: Text(gender.name),
                  selected: _selectedGender == gender,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedGender = gender;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Interests
            Text(
              'Interests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Match with people who share your interests',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                return FilterChip(
                  label: Text(interest),
                  selected: _selectedInterests.contains(interest),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            
            // Advanced Filters
            _buildSectionHeader('Advanced Filters'),
            _buildSwitchOption(
              title: 'Only verified profiles',
              subtitle: 'Show only profiles that are verified',
              value: _onlyVerified,
              onChanged: (value) {
                setState(() {
                  _onlyVerified = value;
                });
              },
            ),
            _buildSwitchOption(
              title: 'Only profiles with bio',
              subtitle: 'Show only profiles that have a bio',
              value: _onlyWithBio,
              onChanged: (value) {
                setState(() {
                  _onlyWithBio = value;
                });
              },
            ),
            _buildSwitchOption(
              title: 'Hide already matched',
              subtitle: 'Hide profiles you already matched with',
              value: _hideAlreadyMatched,
              onChanged: (value) {
                setState(() {
                  _hideAlreadyMatched = value;
                });
              },
            ),
            _buildSwitchOption(
              title: 'Sort by recent activity',
              subtitle: 'Show recently active profiles first',
              value: _sortByActivity,
              onChanged: (value) {
                setState(() {
                  _sortByActivity = value;
                });
              },
            ),
            
            const SizedBox(height: 32),
            
            // Premium Filters
            _buildSectionHeader('Premium Filters'),
            if (!_isPremium)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Unlock additional filters with Premium',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            
            // Height Filter (Premium feature)
            Opacity(
              opacity: _isPremium ? 1.0 : 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSwitchOption(
                    title: 'Height filter',
                    subtitle: 'Filter profiles by height',
                    value: _heightFilterEnabled && _isPremium,
                    onChanged: _isPremium 
                        ? (value) {
                            setState(() {
                              _heightFilterEnabled = value;
                            });
                          }
                        : null,
                  ),
                  if (_heightFilterEnabled && _isPremium)
                    _buildRangeSliderSection(
                      title: 'Height range',
                      valueLabel: '${_heightRange.start.toInt()} - ${_heightRange.end.toInt()} cm',
                      values: _heightRange,
                      min: const RangeValues(140, 140),
                      max: const RangeValues(220, 220),
                      onChanged: (values) {
                        setState(() {
                          _heightRange = values;
                        });
                      },
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save button at bottom
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveFilters,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFilters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to save filters'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create a map of filter values
      final filters = {
        'ageRange': {
          'min': _ageRange.start.round(),
          'max': _ageRange.end.round(),
        },
        'distanceRange': {
          'min': _distanceRange.start.round(),
          'max': _distanceRange.end.round(),
        },
        'gender': _selectedGender.toString().split('.').last,
        'interests': _selectedInterests.toList(),
        'advancedFilters': {
          'onlyVerified': _onlyVerified,
          'onlyWithBio': _onlyWithBio,
          'hideAlreadyMatched': _hideAlreadyMatched,
          'sortByActivity': _sortByActivity,
        },
        'premiumFilters': {
          'heightFilterEnabled': _heightFilterEnabled,
          'heightRange': {
            'min': _heightRange.start.round(),
            'max': _heightRange.end.round(),
          },
        },
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'filters': filters});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Filters saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Pop the screen after successful save
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save filters: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyles.subtitle1Dark.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyles.bodyText2Dark.copyWith(
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      // Reset basic filters to defaults
      _ageRange = const RangeValues(18, 35);
      _distanceRange = const RangeValues(1, 50);
      _selectedGender = Gender.Everyone;
      _selectedInterests.clear();
      
      // Reset advanced filters
      _onlyVerified = false;
      _onlyWithBio = false;
      _hideAlreadyMatched = false;
      _sortByActivity = false;
      
      // Reset premium filters
      _heightFilterEnabled = false;
      _heightRange = const RangeValues(150, 200);
    });
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All filters have been reset to default values'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 