import 'package:flutter/foundation.dart';
import '../models/meal_plan.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';

class DietProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  MealPlan? _currentMealPlan;
  List<FoodItem> _scannedFoodHistory = [];
  bool _isGenerating = false;
  String _sessionId = DateTime.now().toIso8601String(); // Add session tracking

  UserProfile? get userProfile => _userProfile;
  MealPlan? get currentMealPlan => _currentMealPlan;
  List<FoodItem> get scannedFoodHistory => _scannedFoodHistory;
  bool get isGenerating => _isGenerating;
  String get sessionId => _sessionId; // Getter to force unique sessions

  // Update user profile
  void updateUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  // Reset session to force new content generation
  void resetSession() {
    _sessionId = DateTime.now().toIso8601String();
    _currentMealPlan = null;
    notifyListeners();
  }

  // Generate meal plan using Gemini API
  Future<void> generateMealPlan() async {
    if (_userProfile == null) {
      throw Exception('User profile not set');
    }

    try {
      // Pass session ID to ensure uniqueness
      final mealPlan = await GeminiService.generateMealPlan(_userProfile!,
          sessionId: _sessionId);
      _currentMealPlan = mealPlan;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Add scanned food to history
  void addScannedFood(FoodItem food) {
    _scannedFoodHistory.add(food);
    notifyListeners();
  }
}
