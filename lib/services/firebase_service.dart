import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_plan.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Save a meal plan to Firestore
  Future<String?> saveMealPlan(MealPlan mealPlan) async {
    try {
      // Make sure user is logged in
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Reference to the user's meal plans collection
      final userMealPlansRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meal_plans');

      // Add the meal plan document
      final docRef = await userMealPlansRef.add(mealPlan.toMap());

      print('Meal plan saved with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving meal plan: $e');
      return null;
    }
  }

  // Get all meal plans for the current user
  Future<List<MealPlan>> getUserMealPlans() async {
    try {
      // Make sure user is logged in
      if (currentUserId == null) {
        return [];
      }

      // Get all meal plans for the user
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meal_plans')
          .orderBy('createdAt', descending: true)
          .get();

      // Convert snapshots to MealPlan objects
      return snapshot.docs.map((doc) {
        return MealPlan.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Error getting meal plans: $e');
      return [];
    }
  }

  // Delete a meal plan
  Future<bool> deleteMealPlan(String mealPlanId) async {
    try {
      // Make sure user is logged in
      if (currentUserId == null) {
        return false;
      }

      // Delete the meal plan document
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meal_plans')
          .doc(mealPlanId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting meal plan: $e');
      return false;
    }
  }
}
