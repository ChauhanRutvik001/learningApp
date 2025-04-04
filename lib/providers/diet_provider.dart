import 'package:flutter/foundation.dart';
import '../models/meal_plan.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';

class DietProvider with ChangeNotifier {
  UserProfile? _userProfile;
  MealPlan? _currentMealPlan;
  List<FoodItem> _scannedFoodHistory = [];
  bool _isGenerating = false;

  UserProfile? get userProfile => _userProfile;
  MealPlan? get currentMealPlan => _currentMealPlan;
  List<FoodItem> get scannedFoodHistory => _scannedFoodHistory;
  bool get isGenerating => _isGenerating;

  // Update user profile
  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  // Generate meal plan using Gemini API
  Future<void> generateMealPlan() async {
    if (_userProfile == null) {
      throw Exception('User profile not set');
    }

    _isGenerating = true;
    notifyListeners();

    try {
      // Use the Gemini service to generate a meal plan based on user profile
      _currentMealPlan = await GeminiService.generateMealPlan(_userProfile!);
      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _isGenerating = false;
      notifyListeners();
      rethrow; // Let the UI handle the error
    }
  }

  // Add scanned food to history
  void addScannedFood(FoodItem food) {
    _scannedFoodHistory.add(food);
    notifyListeners();
  }
}
