enum DietGoal { weightLoss, muscleGain, maintenance }

enum DietaryPreference { standard, vegetarian, vegan, keto, paleo }

enum Gender { male, female }

class UserProfile {
  final int age;
  final double weight; // in kg
  final double height; // in cm
  final Gender gender;
  final DietGoal goal;
  final DietaryPreference dietaryPreference;
  final List<String> allergies;
  final String language; // Added language field
  final int targetCalories;

  UserProfile({
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.goal,
    required this.dietaryPreference,
    this.allergies = const [],
    this.language = 'English', // Default to English
    this.targetCalories = 0,
  });
}
