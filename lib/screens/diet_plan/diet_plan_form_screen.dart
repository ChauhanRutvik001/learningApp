import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/diet_provider.dart';

class DietPlanFormScreen extends StatefulWidget {
  const DietPlanFormScreen({super.key});

  @override
  State<DietPlanFormScreen> createState() => _DietPlanFormScreenState();
}

class _DietPlanFormScreenState extends State<DietPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController(text: '30');
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController(text: '170');
  DietGoal _selectedGoal = DietGoal.weightLoss;
  DietaryPreference _selectedDietType = DietaryPreference.standard;
  final List<String> _allergies = [];
  bool _isLoading = false;

  final List<String> _commonAllergies = [
    'Dairy',
    'Eggs',
    'Peanuts',
    'Tree nuts',
    'Soy',
    'Wheat',
    'Shellfish',
    'Fish',
    'Sesame'
  ];

  @override
  void initState() {
    super.initState();
    // Load existing profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dietProvider = Provider.of<DietProvider>(context, listen: false);
      if (dietProvider.userProfile != null) {
        _ageController.text = dietProvider.userProfile!.age.toString();
        _weightController.text = dietProvider.userProfile!.weight.toString();
        _heightController.text = dietProvider.userProfile!.height.toString();
        setState(() {
          _selectedGoal = dietProvider.userProfile!.goal;
          _selectedDietType = dietProvider.userProfile!.dietaryPreference;
          _allergies.clear();
          _allergies.addAll(dietProvider.userProfile!.allergies);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Personalize Your Diet',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator for form sections
                  LinearProgressIndicator(
                    value: 0.2, // Update this as user completes sections
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Basic Info Section
                  _buildSectionHeading(
                      'Your Information', Icons.person_outline),

                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormField(
                            controller: _ageController,
                            label: 'Age',
                            hint: 'Years',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your age';
                              }
                              final age = int.tryParse(value);
                              if (age == null || age < 12 || age > 120) {
                                return 'Please enter a valid age (12-120)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(
                            controller: _weightController,
                            label: 'Weight',
                            hint: 'kg',
                            icon: Icons.fitness_center,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your weight';
                              }
                              final weight = double.tryParse(value);
                              if (weight == null ||
                                  weight < 30 ||
                                  weight > 250) {
                                return 'Please enter a valid weight (30-250 kg)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildFormField(
                            controller: _heightController,
                            label: 'Height',
                            hint: 'cm',
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your height';
                              }
                              final height = double.tryParse(value);
                              if (height == null ||
                                  height < 100 ||
                                  height > 250) {
                                return 'Please enter a valid height (100-250 cm)';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Diet Goal Section
                  _buildSectionHeading('Your Goal', Icons.track_changes),

                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildDietGoalSelector(),
                    ),
                  ),

                  // Dietary Preference Section
                  _buildSectionHeading(
                      'Dietary Preference', Icons.restaurant_menu),

                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildDietaryPreferenceSelector(),
                    ),
                  ),

                  // Allergies Section
                  _buildSectionHeading(
                      'Allergies & Restrictions', Icons.warning_amber_rounded),

                  Card(
                    margin: const EdgeInsets.only(bottom: 32),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select any allergies or foods to avoid:',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8.0,
                            children: _commonAllergies.map((allergy) {
                              final isSelected = _allergies.contains(allergy);
                              return FilterChip(
                                label: Text(allergy),
                                selected: isSelected,
                                checkmarkColor: Colors.white,
                                selectedColor: Theme.of(context).primaryColor,
                                labelStyle: GoogleFonts.poppins(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _allergies.add(allergy);
                                    } else {
                                      _allergies.remove(allergy);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Generate Plan Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : _generateDietPlan,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.restaurant),
                                const SizedBox(width: 12),
                                Text(
                                  'Generate Meal Plan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeading(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDietGoalSelector() {
    return Column(
      children: [
        _buildGoalOption(
          DietGoal.weightLoss,
          'Weight Loss',
          'Reduce caloric intake with balanced nutrition',
          Icons.trending_down,
        ),
        _buildGoalOption(
          DietGoal.muscleGain,
          'Muscle Gain',
          'Increase protein and calories for muscle building',
          Icons.fitness_center,
        ),
        _buildGoalOption(
          DietGoal.maintenance,
          'Maintenance',
          'Balanced diet to maintain current weight',
          Icons.balance,
        ),
      ],
    );
  }

  Widget _buildGoalOption(
    DietGoal goal,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedGoal == goal;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGoal = goal;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDietaryPreferenceSelector() {
    return Column(
      children: [
        _buildDietaryOption(
          DietaryPreference.standard,
          'Standard',
          'No specific restrictions',
          Icons.restaurant,
        ),
        _buildDietaryOption(
          DietaryPreference.vegetarian,
          'Vegetarian',
          'No meat, includes dairy and eggs',
          Icons.egg_alt,
        ),
        _buildDietaryOption(
          DietaryPreference.vegan,
          'Vegan',
          'No animal products',
          Icons.spa,
        ),
        _buildDietaryOption(
          DietaryPreference.keto,
          'Keto',
          'Low carb, high fat',
          Icons.no_food,
        ),
        _buildDietaryOption(
          DietaryPreference.paleo,
          'Paleo',
          'Based on foods available in paleolithic era',
          Icons.eco,
        ),
      ],
    );
  }

  Widget _buildDietaryOption(
    DietaryPreference preference,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedDietType == preference;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDietType = preference;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateDietPlan() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        print('🔵 GENERATING DIET PLAN 🔵');
        print('---------------------------------------------');

        // Create user profile from form data
        final userProfile = UserProfile(
          age: int.parse(_ageController.text),
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          goal: _selectedGoal,
          dietaryPreference: _selectedDietType,
          allergies: _allergies,
        );

        // Print the user profile
        print('👤 USER PROFILE: ');
        print('  Age: ${userProfile.age} years');
        print('  Weight: ${userProfile.weight} kg');
        print('  Height: ${userProfile.height} cm');
        print('  Goal: ${userProfile.goal}');
        print('  Diet Type: ${userProfile.dietaryPreference}');
        print(
            '  Allergies: ${userProfile.allergies.isEmpty ? "None" : userProfile.allergies.join(", ")}');
        print('---------------------------------------------');

        // Update profile in provider
        final dietProvider = Provider.of<DietProvider>(context, listen: false);
        dietProvider.updateUserProfile(userProfile);

        print('📝 Sending request to generate meal plan...');

        // Generate the meal plan
        await dietProvider.generateMealPlan();

        print('✅ Meal plan generated successfully!');
        print('---------------------------------------------');

        if (mounted) {
          // Navigate to meal plan screen
          Navigator.pushNamed(context, '/meal-plan');
        }
      } catch (e) {
        print('❌ ERROR GENERATING MEAL PLAN: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error generating meal plan: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
}
