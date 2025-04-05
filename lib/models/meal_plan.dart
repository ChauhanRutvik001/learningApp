import 'food_item.dart';

class MealPlan {
  final List<FoodItem> breakfast;
  final List<FoodItem> lunch;
  final List<FoodItem> dinner;
  final List<FoodItem> snacks;
  final String? notes; // Mark as nullable with ?

  MealPlan({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
    this.notes,
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
}
