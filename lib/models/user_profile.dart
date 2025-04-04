enum DietGoal { weightLoss, muscleGain, maintenance }

enum DietaryPreference { standard, vegetarian, vegan, keto, paleo }

class UserProfile {
  final int age;
  final double weight; // in kg
  final double height; // in cm
  final DietGoal goal;
  final DietaryPreference dietaryPreference;
  final List<String> allergies;
  final int targetCalories;

  UserProfile({
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
    required this.dietaryPreference,
    this.allergies = const [],
    this.targetCalories = 0,
  });
}
