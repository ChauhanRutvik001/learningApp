import 'food_item.dart';

class MealPlan {
  final List<FoodItem> breakfast;
  final List<FoodItem> lunch;
  final List<FoodItem> dinner;
  final List<FoodItem> snacks;
  final String? notes;
  final String? id; // Add an ID field for Firebase
  final DateTime?
      createdAt; // Add a timestamp for when the meal plan was created

  MealPlan({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
    this.notes,
    this.id,
    this.createdAt,
  });

  int get totalCalories {
    int total = 0;
    for (var food in [...breakfast, ...lunch, ...dinner, ...snacks]) {
      total += food.calories;
    }
    return total;
  }

  double get totalProtein {
    double total = 0;
    for (var food in [...breakfast, ...lunch, ...dinner, ...snacks]) {
      total += food.protein;
    }
    return total;
  }

  double get totalCarbs {
    double total = 0;
    for (var food in [...breakfast, ...lunch, ...dinner, ...snacks]) {
      total += food.carbs;
    }
    return total;
  }

  double get totalFat {
    double total = 0;
    for (var food in [...breakfast, ...lunch, ...dinner, ...snacks]) {
      total += food.fat;
    }
    return total;
  }

  // Convert MealPlan to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'breakfast': breakfast.map((item) => item.toMap()).toList(),
      'lunch': lunch.map((item) => item.toMap()).toList(),
      'dinner': dinner.map((item) => item.toMap()).toList(),
      'snacks': snacks.map((item) => item.toMap()).toList(),
      'notes': notes,
      'createdAt':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
    };
  }

  // Create a MealPlan from a Firebase Map
  factory MealPlan.fromMap(Map<String, dynamic> map, String documentId) {
    return MealPlan(
      id: documentId,
      breakfast: List<FoodItem>.from(
        (map['breakfast'] as List? ?? []).map(
          (item) => FoodItem.fromMap(item),
        ),
      ),
      lunch: List<FoodItem>.from(
        (map['lunch'] as List? ?? []).map(
          (item) => FoodItem.fromMap(item),
        ),
      ),
      dinner: List<FoodItem>.from(
        (map['dinner'] as List? ?? []).map(
          (item) => FoodItem.fromMap(item),
        ),
      ),
      snacks: List<FoodItem>.from(
        (map['snacks'] as List? ?? []).map(
          (item) => FoodItem.fromMap(item),
        ),
      ),
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
