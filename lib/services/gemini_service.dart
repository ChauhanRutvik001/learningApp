import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/meal_plan.dart';
import '../models/food_item.dart';

class GeminiService {
  // Updated API key and endpoint for Gemini 2.0 Flash
  static const String apiKey = 'AIzaSyBwUnN3aDHbySQIApPli86kKwZWVSOuJ_0';
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<MealPlan> generateMealPlan(UserProfile profile,
      {String? sessionId}) async {
    try {
      // Create prompt based on user profile
      final prompt = _createDietPlanPrompt(profile, sessionId: sessionId);

      // Add randomization to ensure varied responses
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.8, // Increase temperature for more variation
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
          'stopSequences': [],
          'candidateCount': 1,
        }
      };

      // Log the prompt being sent
      developer.log('🔹 GEMINI PROMPT:\n$prompt', name: 'GeminiAPI');

      // Make API request
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      developer.log('📥 GEMINI RESPONSE STATUS: ${response.statusCode}',
          name: 'GeminiAPI');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Pretty-print the complete response for debugging
        final prettyJson =
            const JsonEncoder.withIndent('  ').convert(jsonResponse);
        developer.log('📦 COMPLETE GEMINI RESPONSE:\n$prettyJson',
            name: 'GeminiAPI');

        // Extract and log the text response
        final textResponse =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        developer.log('📝 MEAL PLAN TEXT:\n$textResponse', name: 'GeminiAPI');

        // Parse response into MealPlan object
        final mealPlan = _parseMealPlanResponse(textResponse, profile);

        // Log the structured meal plan for debugging
        _logMealPlan(mealPlan);

        return mealPlan;
      } else {
        developer.log(
            '❌ GEMINI API ERROR: ${response.statusCode}\n${response.body}',
            name: 'GeminiAPI',
            error: response.body);
        throw Exception(
            'Failed to generate meal plan: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      developer.log('❌ EXCEPTION GENERATING MEAL PLAN: $e',
          name: 'GeminiAPI', error: e);
      throw Exception('Error generating meal plan: $e');
    }
  }

  // Log the structured meal plan
  static void _logMealPlan(MealPlan mealPlan) {
    final buffer = StringBuffer();
    buffer.writeln('🍽️ PARSED MEAL PLAN:');

    buffer.writeln('\n🍳 BREAKFAST:');
    for (var food in mealPlan.breakfast) {
      buffer.writeln(
          '  • ${food.name}: ${food.calories}kcal, ${food.protein}g protein, ${food.carbs}g carbs, ${food.fat}g fat');
    }

    buffer.writeln('\n🥗 LUNCH:');
    for (var food in mealPlan.lunch) {
      buffer.writeln(
          '  • ${food.name}: ${food.calories}kcal, ${food.protein}g protein, ${food.carbs}g carbs, ${food.fat}g fat');
    }

    buffer.writeln('\n🍲 DINNER:');
    for (var food in mealPlan.dinner) {
      buffer.writeln(
          '  • ${food.name}: ${food.calories}kcal, ${food.protein}g protein, ${food.carbs}g carbs, ${food.fat}g fat');
    }

    buffer.writeln('\n🍎 SNACKS:');
    for (var food in mealPlan.snacks) {
      buffer.writeln(
          '  • ${food.name}: ${food.calories}kcal, ${food.protein}g protein, ${food.carbs}g carbs, ${food.fat}g fat');
    }

    if (mealPlan.notes?.isNotEmpty == true) {
      buffer.writeln('\n📝 NOTES:');
      buffer.writeln('  ${mealPlan.notes}');
    }

    developer.log(buffer.toString(), name: 'GeminiAPI');
  }

  static String _createDietPlanPrompt(UserProfile profile,
      {String? sessionId}) {
    final allergiesText = profile.allergies.isEmpty
        ? 'No allergies.'
        : 'Allergies: ${profile.allergies.join(', ')}.';

    // Add randomization cue and uniqueness request
    final randomSeed =
        sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

    return '''
You are a creative nutritionist creating a personalized meal plan. Generate a UNIQUE and DIFFERENT meal plan (Seed: $randomSeed) with specific food items.

USER PROFILE:
- Age: ${profile.age} years
- Weight: ${profile.weight} kg
- Height: ${profile.height} cm
- Goal: ${_formatGoal(profile.goal)}
- Dietary Preference: ${_formatDietaryPreference(profile.dietaryPreference)}
- $allergiesText

IMPORTANT INSTRUCTIONS:
1. BE CREATIVE - Suggest interesting and varied food combinations
2. DON'T use generic names like "Breakfast" or "Lunch" for food items
3. BE SPECIFIC with food names (e.g., "Spinach and feta omelet" not just "Omelet")
4. INCLUDE precise measurements for every item (e.g., "85g quinoa" or "1 medium apple")
5. VARY the suggested foods each time this prompt is run
6. FOLLOW the user's dietary preferences strictly
7. BE REALISTIC with portion sizes and nutrition values based on user's profile

OUTPUT FORMAT:
Format your response in the following structure exactly, with one line per food item:
BREAKFAST:
- [Specific food name] ([precise measurement]): [calories]kcal, [protein]g protein, [carbs]g carbs, [fat]g fat

LUNCH:
- [Specific food name] ([precise measurement]): [calories]kcal, [protein]g protein, [carbs]g carbs, [fat]g fat

DINNER:
- [Specific food name] ([precise measurement]): [calories]kcal, [protein]g protein, [carbs]g carbs, [fat]g fat

SNACKS:
- [Specific food name] ([precise measurement]): [calories]kcal, [protein]g protein, [carbs]g carbs, [fat]g fat

NOTES:
[Practical advice specific to this meal plan]
''';
  }

  static String _formatGoal(DietGoal goal) {
    switch (goal) {
      case DietGoal.weightLoss:
        return 'Weight loss (caloric deficit)';
      case DietGoal.muscleGain:
        return 'Muscle gain (caloric surplus with higher protein)';
      case DietGoal.maintenance:
        return 'Weight maintenance (balanced calories)';
    }
  }

  static String _formatDietaryPreference(DietaryPreference preference) {
    switch (preference) {
      case DietaryPreference.standard:
        return 'Standard (no restrictions)';
      case DietaryPreference.vegetarian:
        return 'Vegetarian (no meat, allows dairy and eggs)';
      case DietaryPreference.vegan:
        return 'Vegan (no animal products)';
      case DietaryPreference.keto:
        return 'Keto (high fat, very low carb)';
      case DietaryPreference.paleo:
        return 'Paleo (no processed foods, grains, or dairy)';
    }
  }

  static String _getNutritionTargets(UserProfile profile) {
    final bmr = _calculateBMR(profile);

    switch (profile.goal) {
      case DietGoal.weightLoss:
        final targetCalories = (bmr * 0.8).round(); // 20% deficit
        return '''
        - Total calories: ${targetCalories}kcal (caloric deficit)
        - Protein: ${(profile.weight * 2.0).round()}g (higher protein to preserve muscle)
        - Fat: ${(targetCalories * 0.3 / 9).round()}g (moderate fat)
        - Carbs: remaining calories from carbohydrates''';

      case DietGoal.muscleGain:
        final targetCalories = (bmr * 1.15).round(); // 15% surplus
        return '''
        - Total calories: ${targetCalories}kcal (caloric surplus)
        - Protein: ${(profile.weight * 2.2).round()}g (high protein for muscle building)
        - Fat: ${(targetCalories * 0.25 / 9).round()}g (moderate fat)
        - Carbs: higher carbs to support training and recovery''';

      case DietGoal.maintenance:
        return '''
        - Total calories: ${bmr.round()}kcal (maintenance)
        - Protein: ${(profile.weight * 1.8).round()}g
        - Fat: ${(bmr * 0.3 / 9).round()}g
        - Carbs: balanced to complete caloric needs''';
    }
  }

  static int _calculateBMR(UserProfile profile) {
    // Mifflin-St Jeor Equation
    if (profile.weight <= 0 || profile.height <= 0 || profile.age <= 0) {
      return 2000; // Default if invalid inputs
    }

    // Assume male for simplicity (if needed, add gender to UserProfile)
    return (10 * profile.weight + 6.25 * profile.height - 5 * profile.age + 5)
        .round();
  }

  static MealPlan _parseMealPlanResponse(String response, UserProfile profile) {
    try {
      List<FoodItem> breakfast = [];
      List<FoodItem> lunch = [];
      List<FoodItem> dinner = [];
      List<FoodItem> snacks = [];
      String notes = '';

      // Split response into sections
      final sections =
          response.split(RegExp(r'(BREAKFAST|LUNCH|DINNER|SNACKS|NOTES):'));

      // Improved regex to capture food items with better name and portion handling
      final foodItemPattern = RegExp(
        r'- ([^:]+)(?:\s*\(([^)]+)\))?\s*:\s*(\d+)kcal,\s*([\d\.]+)g protein,\s*([\d\.]+)g carbs,\s*([\d\.]+)g fat',
        multiLine: true,
      );

      String currentSection = '';
      for (int i = 0; i < sections.length; i++) {
        final section = sections[i].trim();

        // Identify section type
        if (section == 'BREAKFAST' ||
            section == 'LUNCH' ||
            section == 'DINNER' ||
            section == 'SNACKS' ||
            section == 'NOTES') {
          currentSection = section;
          continue;
        }

        // Process items in each section
        if (currentSection == 'BREAKFAST' ||
            currentSection == 'LUNCH' ||
            currentSection == 'DINNER' ||
            currentSection == 'SNACKS') {
          final matches = foodItemPattern.allMatches(section);
          for (var match in matches) {
            final foodName = match.group(1)!.trim();
            final portion =
                match.group(2) != null ? match.group(2)!.trim() : "";
            final calories = int.parse(match.group(3)!);
            final protein = double.parse(match.group(4)!);
            final carbs = double.parse(match.group(5)!);
            final fat = double.parse(match.group(6)!);

            // Create name with portion if available
            final fullName =
                portion.isNotEmpty ? "$foodName ($portion)" : foodName;

            final foodItem = FoodItem(
              name: fullName,
              calories: calories,
              protein: protein,
              carbs: carbs,
              fat: fat,
            );

            if (currentSection == 'BREAKFAST') {
              breakfast.add(foodItem);
            } else if (currentSection == 'LUNCH') {
              lunch.add(foodItem);
            } else if (currentSection == 'DINNER') {
              dinner.add(foodItem);
            } else if (currentSection == 'SNACKS') {
              snacks.add(foodItem);
            }
          }
        } else if (currentSection == 'NOTES') {
          notes = section.trim();
        }
      }

      // Use more specific default foods for fallback
      if (breakfast.isEmpty) {
        breakfast = [
          FoodItem(
              name: "Greek yogurt with berries (200g)",
              calories: 180,
              protein: 15,
              carbs: 20,
              fat: 5),
          FoodItem(
              name: "Whole grain toast with avocado (2 slices)",
              calories: 240,
              protein: 8,
              carbs: 30,
              fat: 12),
        ];
      }

      if (lunch.isEmpty) {
        lunch = [
          FoodItem(
              name: "Chickpea salad with quinoa (300g)",
              calories: 350,
              protein: 15,
              carbs: 45,
              fat: 10),
          FoodItem(
              name: "Mixed vegetables with hummus (150g)",
              calories: 200,
              protein: 7,
              carbs: 20,
              fat: 10),
        ];
      }

      if (dinner.isEmpty) {
        dinner = [
          FoodItem(
              name: "Lentil curry with brown rice (350g)",
              calories: 420,
              protein: 20,
              carbs: 60,
              fat: 10),
          FoodItem(
              name: "Steamed broccoli with olive oil (150g)",
              calories: 120,
              protein: 5,
              carbs: 10,
              fat: 7),
        ];
      }

      if (snacks.isEmpty) {
        snacks = [
          FoodItem(
              name: "Apple with almond butter (1 medium + 2 tbsp)",
              calories: 200,
              protein: 5,
              carbs: 25,
              fat: 10),
          FoodItem(
              name: "Mixed nuts (30g)",
              calories: 180,
              protein: 6,
              carbs: 6,
              fat: 15),
        ];
      }

      // Add validation to ensure we're getting varied results
      if (breakfast.isEmpty ||
          breakfast.length < 2 ||
          lunch.isEmpty ||
          dinner.isEmpty ||
          snacks.isEmpty) {
        print(
            "WARNING: Gemini returned insufficient meal items, enriching response...");
        // Add supplemental items if Gemini didn't return enough
        if (breakfast.isEmpty || breakfast.length < 2) {
          breakfast.add(FoodItem(
            name: "Multi-grain toast with almond butter (2 slices)",
            calories: 290,
            protein: 12,
            carbs: 30,
            fat: 15,
          ));
        }
        // Add more supplemental items as needed...
      }

      return MealPlan(
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
        snacks: snacks,
        notes: notes,
      );
    } catch (e) {
      print('Error parsing meal plan: $e');
      // Return dynamically generated default meal plan instead of static one
      return _createDefaultMealPlan(profile);
    }
  }

  static MealPlan _createDefaultVegetarianMealPlan() {
    return MealPlan(
      breakfast: [
        FoodItem(
            name: "Greek yogurt with honey and berries (200g)",
            calories: 180,
            protein: 15,
            carbs: 20,
            fat: 5),
        FoodItem(
            name: "Whole grain toast with avocado (2 slices)",
            calories: 240,
            protein: 8,
            carbs: 30,
            fat: 12),
      ],
      lunch: [
        FoodItem(
            name: "Quinoa bowl with roasted vegetables (350g)",
            calories: 380,
            protein: 12,
            carbs: 50,
            fat: 14),
        FoodItem(
            name: "Spinach salad with walnuts and apple (150g)",
            calories: 180,
            protein: 5,
            carbs: 15,
            fat: 12),
      ],
      dinner: [
        FoodItem(
            name: "Vegetable stir-fry with tofu (350g)",
            calories: 320,
            protein: 20,
            carbs: 30,
            fat: 12),
        FoodItem(
            name: "Brown rice (150g cooked)",
            calories: 160,
            protein: 3,
            carbs: 32,
            fat: 1),
      ],
      snacks: [
        FoodItem(
            name: "Apple with almond butter (1 medium + 2 tbsp)",
            calories: 200,
            protein: 5,
            carbs: 25,
            fat: 10),
        FoodItem(
            name: "Carrot sticks with hummus (100g)",
            calories: 130,
            protein: 4,
            carbs: 15,
            fat: 6),
      ],
      notes:
          "This is a balanced vegetarian meal plan focused on weight loss while maintaining good protein intake. Try to prepare meals in advance for convenience.",
    );
  }

  static MealPlan _createDefaultMealPlan(UserProfile profile) {
    // Create dynamic default based on user profile
    final isVegetarian =
        profile.dietaryPreference == DietaryPreference.vegetarian ||
            profile.dietaryPreference == DietaryPreference.vegan;
    final isLowCarb = profile.dietaryPreference == DietaryPreference.keto;
    final isWeightLoss = profile.goal == DietGoal.weightLoss;

    // Calculate approximate calorie needs
    final bmr = _calculateBMR(profile);
    final targetCalories =
        isWeightLoss ? (bmr * 0.8).round() : (bmr * 1.1).round();

    // Generate breakfast options based on preferences
    final breakfastOptions = isVegetarian
        ? [
            FoodItem(
                name: "Greek yogurt with berries (200g)",
                calories: 180,
                protein: 15,
                carbs: 20,
                fat: 5),
            FoodItem(
                name: "Avocado toast on whole grain bread (2 slices)",
                calories: 320,
                protein: 10,
                carbs: 30,
                fat: 18),
            FoodItem(
                name: "Spinach and mushroom omelette (3 eggs)",
                calories: 300,
                protein: 21,
                carbs: 4,
                fat: 22),
          ]
        : [
            FoodItem(
                name: "Scrambled eggs with bacon (3 eggs, 2 strips)",
                calories: 350,
                protein: 24,
                carbs: 2,
                fat: 26),
            FoodItem(
                name: "Turkey sausage with toast (2 links, 1 slice)",
                calories: 250,
                protein: 18,
                carbs: 15,
                fat: 14),
          ];

    // Use timestamp to select different options each time
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSelector = timestamp % 100;

    return MealPlan(
      breakfast: [breakfastOptions[randomSelector % breakfastOptions.length]],
      lunch: isVegetarian
          ? [
              FoodItem(
                  name: "Quinoa bowl with roasted vegetables (350g)",
                  calories: 380,
                  protein: 12,
                  carbs: 50,
                  fat: 14)
            ]
          : [
              FoodItem(
                  name: "Grilled chicken salad (300g)",
                  calories: 320,
                  protein: 35,
                  carbs: 10,
                  fat: 16)
            ],
      dinner: isVegetarian
          ? [
              FoodItem(
                  name: "Lentil curry with brown rice (300g)",
                  calories: 450,
                  protein: 18,
                  carbs: 65,
                  fat: 12)
            ]
          : [
              FoodItem(
                  name: "Baked salmon with asparagus (200g)",
                  calories: 380,
                  protein: 40,
                  carbs: 8,
                  fat: 20)
            ],
      snacks: isLowCarb
          ? [
              FoodItem(
                  name: "Mixed nuts (30g)",
                  calories: 180,
                  protein: 6,
                  carbs: 6,
                  fat: 15)
            ]
          : [
              FoodItem(
                  name: "Apple with peanut butter (1 medium + 2 tbsp)",
                  calories: 230,
                  protein: 7,
                  carbs: 30,
                  fat: 12)
            ],
      notes:
          "Personalized meal plan for ${profile.goal.toString().split('.').last} goal. "
          "Adjust portions as needed to meet your daily calorie target of approximately $targetCalories kcal.",
    );
  }
}
