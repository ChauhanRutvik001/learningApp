import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class GeminiVisionService {
  // Update to the new API key
  static const String apiKey = 'AIzaSyCuiM_7fsybhrBSE6DHYCsRsro2qStGabU';
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent';

  static Future<FoodItem> analyzeFoodImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create prompt based on user profile
      final prompt =
          "Identify this food and provide its nutritional information: calories, protein (g), carbs (g), and fat (g).";

      // Create request body
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'topK': 32,
          'topP': 1,
          'maxOutputTokens': 512,
        }
      };

      // Make API request
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final textResponse =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        // Parse response into FoodItem object
        return _parseFoodResponse(textResponse);
      } else {
        throw Exception(
            'Failed to analyze food: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing food image: $e');
    }
  }

  static FoodItem _parseFoodResponse(String response) {
    try {
      String name = 'Unknown Food';
      int calories = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;

      // Extract food name - look for the first sentence or food name pattern
      final nameMatch =
          RegExp(r'^This (is|appears to be) (?:a )?(.*?)\.', multiLine: true)
                  .firstMatch(response) ??
              RegExp(r'^I can identify this as (?:a )?(.*?)\.', multiLine: true)
                  .firstMatch(response);

      if (nameMatch != null && nameMatch.groupCount >= 2) {
        name = nameMatch.group(2)!;
      } else {
        // Try to find the first sentence as the name
        final firstLineMatch = RegExp(r'^(.*?)\n').firstMatch(response);
        if (firstLineMatch != null) {
          name = firstLineMatch.group(1)!;
        }
      }

      // Extract nutritional values
      final caloriesMatch = RegExp(r'calories:?\s*(\d+)', caseSensitive: false)
          .firstMatch(response);
      final proteinMatch =
          RegExp(r'protein:?\s*(\d+\.?\d*)\s*g', caseSensitive: false)
              .firstMatch(response);
      final carbsMatch =
          RegExp(r'carbs:?\s*(\d+\.?\d*)\s*g', caseSensitive: false)
              .firstMatch(response);
      final fatMatch = RegExp(r'fat:?\s*(\d+\.?\d*)\s*g', caseSensitive: false)
          .firstMatch(response);

      if (caloriesMatch != null) {
        calories = int.parse(caloriesMatch.group(1)!);
      }

      if (proteinMatch != null) {
        protein = double.parse(proteinMatch.group(1)!);
      }

      if (carbsMatch != null) {
        carbs = double.parse(carbsMatch.group(1)!);
      }

      if (fatMatch != null) {
        fat = double.parse(fatMatch.group(1)!);
      }

      return FoodItem(
        name: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
    } catch (e) {
      print('Error parsing food response: $e');
      print('Original response: $response');

      // Return a default food item if parsing fails
      return FoodItem(
        name: "Unknown Food Item",
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
      );
    }
  }
}
