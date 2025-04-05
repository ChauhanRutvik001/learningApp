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

  // Form fields
  final _ageController = TextEditingController(text: '30');
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController(text: '170');
  DietGoal _selectedGoal = DietGoal.weightLoss;
  DietaryPreference _selectedDietType = DietaryPreference.standard;
  final List<String> _allergies = [];
  bool _isLoading = false;
  Gender _selectedGender = Gender.male;
  String _selectedLanguage = 'English';
  List<String> _availableLanguages = ['English', 'हिंदी', 'ગુજરાતી'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Diet Plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Personal Information',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Age field
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Weight field
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your weight';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid weight';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Height field
                TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your height';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid height';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Gender selection
                Text(
                  'Gender',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<Gender>(
                        value: Gender.male,
                        groupValue: _selectedGender,
                        title: Text('Male'),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<Gender>(
                        value: Gender.female,
                        groupValue: _selectedGender,
                        title: Text('Female'),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Diet goal selection
                Text(
                  'Diet Goal',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDietGoalSelector(),
                const SizedBox(height: 24),

                // Dietary preference selection
                Text(
                  'Dietary Preference',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDietaryPreferenceSelector(),
                const SizedBox(height: 32),

                Text(
                  'Language / भाषा / ભાષા',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedLanguage,
                      items: _availableLanguages.map((String language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(language),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLanguage = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Generate plan button
                ElevatedButton(
                  onPressed: _isLoading ? null : _generateDietPlan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Generate Diet Plan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDietGoalSelector() {
    return Column(
      children: [
        _buildGoalOption(
          DietGoal.weightLoss,
          'Weight Loss',
          'Reduce caloric intake with balanced nutrition',
        ),
        _buildGoalOption(
          DietGoal.muscleGain,
          'Muscle Gain',
          'Increase protein and calories for muscle building',
        ),
        _buildGoalOption(
          DietGoal.maintenance,
          'Maintenance',
          'Balanced diet to maintain current weight',
        ),
      ],
    );
  }

  Widget _buildGoalOption(DietGoal goal, String title, String description) {
    return RadioListTile<DietGoal>(
      value: goal,
      groupValue: _selectedGoal,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.poppins(
          fontSize: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _selectedGoal = value!;
        });
      },
      activeColor: Theme.of(context).primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildDietaryPreferenceSelector() {
    return Column(
      children: [
        _buildDietaryOption(
          DietaryPreference.standard,
          'Standard',
          'No specific restrictions',
        ),
        _buildDietaryOption(
          DietaryPreference.vegetarian,
          'Vegetarian',
          'No meat, includes dairy and eggs',
        ),
        _buildDietaryOption(
          DietaryPreference.vegan,
          'Vegan',
          'No animal products',
        ),
        _buildDietaryOption(
          DietaryPreference.keto,
          'Keto',
          'Low carb, high fat',
        ),
        _buildDietaryOption(
          DietaryPreference.paleo,
          'Paleo',
          'Based on foods available in paleolithic era',
        ),
      ],
    );
  }

  Widget _buildDietaryOption(
      DietaryPreference preference, String title, String description) {
    return RadioListTile<DietaryPreference>(
      value: preference,
      groupValue: _selectedDietType,
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        description,
        style: GoogleFonts.poppins(
          fontSize: 12,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _selectedDietType = value!;
        });
      },
      activeColor: Theme.of(context).primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Future<void> _generateDietPlan() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Create user profile from form data
        final userProfile = UserProfile(
          age: int.parse(_ageController.text),
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          gender: _selectedGender,
          goal: _selectedGoal,
          dietaryPreference: _selectedDietType,
          allergies: _allergies,
          language: _selectedLanguage, // Add the selected language
        );

        // Update profile in provider
        final dietProvider = Provider.of<DietProvider>(context, listen: false);
        dietProvider.updateUserProfile(userProfile);

        // Generate the meal plan
        await dietProvider.generateMealPlan();

        if (mounted) {
          // Navigate to meal plan screen - this line was incomplete
          Navigator.pushNamed(context, '/meal-plan');
        }
      } catch (e) {
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
