import 'package:flutter/foundation.dart';
import '../models/meal_plan.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';

class DietProvider with ChangeNotifier {
  UserProfile? _userProfile;
  MealPlan? _currentMealPlan;
  List<FoodItem> _scannedFoodHistory = [];

  UserProfile? get userProfile => _userProfile;
  MealPlan? get currentMealPlan => _currentMealPlan;
  List<FoodItem> get scannedFoodHistory => _scannedFoodHistory;

  // Update user profile
  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  // Generate meal plan
  Future<void> generateMealPlan() async {
    // This would call the backend API with Gemini integration
    // For now, we'll mock it with a delay
    await Future.delayed(const Duration(seconds: 2));

    _currentMealPlan = MealPlan(
      breakfast: [
        FoodItem(
            name: "Oatmeal with berries",
            calories: 320,
            protein: 12,
            carbs: 58,
            fat: 6),
        FoodItem(
            name: "Greek yogurt", calories: 150, protein: 15, carbs: 7, fat: 8),
      ],
      lunch: [
        FoodItem(
            name: "Grilled chicken salad",
            calories: 450,
            protein: 35,
            carbs: 25,
            fat: 18),
      ],
      dinner: [
        FoodItem(
            name: "Salmon with vegetables",
            calories: 520,
            protein: 40,
            carbs: 30,
            fat: 22),
      ],
      snacks: [
        FoodItem(
            name: "Apple with almond butter",
            calories: 220,
            protein: 5,
            carbs: 25,
            fat: 12),
      ],
    );

    notifyListeners();
  }

  // Add scanned food to history
  void addScannedFood(FoodItem food) {
    _scannedFoodHistory.add(food);
    notifyListeners();
  }
}
