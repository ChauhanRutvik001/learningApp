import 'package:flutter/foundation.dart';
import '../models/meal_plan.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';

class DietProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  UserProfile? _userProfile;
  MealPlan? _currentMealPlan;
  List<FoodItem> _scannedFoodHistory = [];
  bool _isGenerating = false;
  bool _isSaving = false;

  UserProfile? get userProfile => _userProfile;
  MealPlan? get currentMealPlan => _currentMealPlan;
  List<FoodItem> get scannedFoodHistory => _scannedFoodHistory;
  bool get isGenerating => _isGenerating;
  bool get isSaving => _isSaving;

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
  
  // Save current meal plan to Firebase
  Future<String?> saveMealPlan() async {
    if (_currentMealPlan == null) {
      throw Exception('No meal plan to save');
    }
    
    _isSaving = true;
    notifyListeners();
    
    try {
      // Add current timestamp if not already set
      final mealPlanToSave = MealPlan(
        breakfast: _currentMealPlan!.breakfast,
        lunch: _currentMealPlan!.lunch,
        dinner: _currentMealPlan!.dinner,
        snacks: _currentMealPlan!.snacks,
        notes: _currentMealPlan!.notes,
        createdAt: DateTime.now(),
      );
      
      // Save to Firebase
      String? id = await _firebaseService.saveMealPlan(mealPlanToSave);
      
      _isSaving = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isSaving = false;
      notifyListeners();
      rethrow; // Let the UI handle the error
    }
  }
  
  // Load saved meal plans from Firebase
  Future<List<MealPlan>> getSavedMealPlans() async {
    try {
      return await _firebaseService.getUserMealPlans();
    } catch (e) {
      print('Error loading saved meal plans: $e');
      rethrow;
    }
  }
  
  // Delete a saved meal plan
  Future<bool> deleteMealPlan(String id) async {
    try {
      return await _firebaseService.deleteMealPlan(id);
    } catch (e) {
      print('Error deleting meal plan: $e');
      rethrow;
    }
  }
}
