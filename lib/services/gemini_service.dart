import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/meal_plan.dart';
import '../models/food_item.dart';

class GeminiService {
  // API key already correctly set
  static const String apiKey = 'AIzaSyBwUnN3aDHbySQIApPli86kKwZWVSOuJ_0';

  // Update to use the Gemini 2.0 Flash model
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<MealPlan> generateMealPlan(UserProfile profile) async {
    try {
      // Create prompt based on user profile
      final prompt = _createDietPlanPrompt(profile);

      // Create request body - use more specific instruction parameters
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature':
              0.3, // Lower temperature for more consistent formatting
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      // Make API request with timeout
      final response = await http
          .post(
            Uri.parse('$apiUrl?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out'),
          );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final textResponse =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        // Parse response into MealPlan object
        return _parseMealPlanResponse(textResponse);
      } else {
        throw Exception(
            'Failed to generate meal plan: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating meal plan: $e');
    }
  }

  static String _createDietPlanPrompt(UserProfile profile) {
    String dietGoalText = '';
    switch (profile.goal) {
      case DietGoal.weightLoss:
        dietGoalText = 'weight loss';
        break;
      case DietGoal.muscleGain:
        dietGoalText = 'muscle gain';
        break;
      case DietGoal.maintenance:
        dietGoalText = 'weight maintenance';
        break;
    }

    String dietTypeText = '';
    switch (profile.dietaryPreference) {
      case DietaryPreference.standard:
        dietTypeText = 'standard diet with no specific restrictions';
        break;
      case DietaryPreference.vegetarian:
        dietTypeText = 'vegetarian diet (no meat, but includes dairy and eggs)';
        break;
      case DietaryPreference.vegan:
        dietTypeText = 'vegan diet (no animal products)';
        break;
      case DietaryPreference.keto:
        dietTypeText = 'ketogenic diet (low carb, high fat)';
        break;
      case DietaryPreference.paleo:
        dietTypeText =
            'paleo diet (based on foods available in paleolithic era)';
        break;
    }

    String allergiesText = profile.allergies.isNotEmpty
        ? 'Allergies: ${profile.allergies.join(", ")}'
        : 'No specific food allergies.';

    // Calculate BMR and caloric needs
    double bmr = 0;
    if (profile.gender == Gender.male) {
      bmr = 88.362 +
          (13.397 * profile.weight) +
          (4.799 * profile.height) -
          (5.677 * profile.age);
    } else {
      bmr = 447.593 +
          (9.247 * profile.weight) +
          (3.098 * profile.height) -
          (4.330 * profile.age);
    }

    // Adjust based on activity level (assuming moderate activity)
    double calorieTarget = bmr * 1.55;

    // Adjust based on goal
    if (profile.goal == DietGoal.weightLoss) {
      calorieTarget -= 500; // Deficit for weight loss
    } else if (profile.goal == DietGoal.muscleGain) {
      calorieTarget += 500; // Surplus for muscle gain
    }

    // Add language specific instructions
    String languageInstructions = '';
    if (profile.language == 'हिंदी') {
      languageInstructions =
          'Please provide the entire meal plan in Hindi language.';
    } else if (profile.language == 'ગુજરાતી') {
      languageInstructions =
          'Please provide the entire meal plan in Gujarati language.';
    } else {
      languageInstructions = 'Please provide the meal plan in English.';
    }

    return '''
    Create a personalized daily meal plan for a ${profile.age} year old individual with the following characteristics:
    - Height: ${profile.height} cm
    - Weight: ${profile.weight} kg
    - Target daily calories: ${calorieTarget.toInt()} kcal
    - Dietary goal: $dietGoalText
    - Dietary preference: $dietTypeText
    - $allergiesText

    $languageInstructions

    Please provide a detailed meal plan with specific portion sizes including breakfast, lunch, dinner, and snacks with the following information for each food item:
    1. Name of the dish/food with exact portion size (e.g., "1 cup oatmeal" or "85g chicken breast")
    2. Calories (kcal)
    3. Protein (g)
    4. Carbs (g)
    5. Fat (g)

    Format your response STRICTLY as follows:
    BREAKFAST:
    - [Food name with portion], [calories] kcal, [protein]g protein, [carbs]g carbs, [fat]g fat
    - [Food name with portion], [calories] kcal, [protein]g protein, [carbs]g carbs, [fat]g fat

    LUNCH:
    - [Food name with portion], [calories] kcal, [protein]g protein, [carbs]g carbs, [fat]g fat

    DINNER:
    - [Food name with portion], [calories] kcal, [protein]g protein, [carbs]g carbs, [fat]g fat

    SNACKS:
    - [Food name with portion], [calories] kcal, [protein]g protein, [carbs]g carbs, [fat]g fat

    NOTES:
    [Any additional notes about the meal plan, hydration recommendations, or meal timing]
    ''';
  }

  static MealPlan _parseMealPlanResponse(String response) {
    try {
      List<FoodItem> breakfast = [];
      List<FoodItem> lunch = [];
      List<FoodItem> dinner = [];
      List<FoodItem> snacks = [];
      String notes = '';

      // Split response by sections
      final sections = response.split(
          RegExp(r'BREAKFAST:|LUNCH:|DINNER:|SNACKS:|NOTES:', multiLine: true));

      if (sections.length >= 5) {
        // Parse each section
        breakfast = _parseFoodItems(sections[1]);
        lunch = _parseFoodItems(sections[2]);
        dinner = _parseFoodItems(sections[3]);
        snacks = _parseFoodItems(sections[4]);

        // Get notes if available
        if (sections.length > 5) {
          notes = sections[5].trim();
        }
      }

      return MealPlan(
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
        snacks: snacks,
        notes: notes,
      );
    } catch (e) {
      print('Error parsing meal plan response: $e');

      // Return a fallback meal plan if parsing fails
      return MealPlan(
        breakfast: [
          FoodItem(
              name: "Oatmeal with berries",
              calories: 320,
              protein: 12,
              carbs: 58,
              fat: 6),
          FoodItem(
              name: "Greek yogurt",
              calories: 150,
              protein: 15,
              carbs: 7,
              fat: 8),
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
        notes:
            "This is a fallback meal plan because we couldn't parse the AI response correctly.",
      );
    }
  }

  static List<FoodItem> _parseFoodItems(String section) {
    final items = <FoodItem>[];
    final lines = section.trim().split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty || !line.contains(',')) continue;

      try {
        // Extract food name
        final match = RegExp(r'- (.*?),').firstMatch(line);
        if (match == null) continue;

        final name = match.group(1)?.trim() ?? 'Unknown food';

        // Extract nutritional values
        final caloriesMatch = RegExp(r'(\d+)\s*kcal').firstMatch(line);
        final proteinMatch =
            RegExp(r'(\d+\.?\d*)\s*g\s*protein').firstMatch(line);
        final carbsMatch = RegExp(r'(\d+\.?\d*)\s*g\s*carbs').firstMatch(line);
        final fatMatch = RegExp(r'(\d+\.?\d*)\s*g\s*fat').firstMatch(line);

        final calories =
            caloriesMatch != null ? int.parse(caloriesMatch.group(1)!) : 0;
        final protein =
            proteinMatch != null ? double.parse(proteinMatch.group(1)!) : 0.0;
        final carbs =
            carbsMatch != null ? double.parse(carbsMatch.group(1)!) : 0.0;
        final fat = fatMatch != null ? double.parse(fatMatch.group(1)!) : 0.0;

        items.add(FoodItem(
          name: name,
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
        ));
      } catch (e) {
        print('Error parsing food item: $line, error: $e');
        continue;
      }
    }

    return items;
  }
}
