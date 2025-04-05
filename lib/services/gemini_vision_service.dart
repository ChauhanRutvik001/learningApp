import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';

class GeminiVisionService {
  static const String apiKey = 'AIzaSyCuiM_7fsybhrBSE6DHYCsRsro2qStGabU';
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent';

  static Future<FoodItem> analyzeFoodImage(File imageFile) async {
    try {
      developer.log('🔍 ANALYZING FOOD IMAGE: ${imageFile.path}',
          name: 'GeminiVisionAPI');

      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      developer.log(
          '📸 IMAGE CONVERTED TO BASE64 (${(base64Image.length / 1024).toStringAsFixed(2)}KB)',
          name: 'GeminiVisionAPI');

      // Create prompt based on user profile
      final prompt =
          "Identify this food and provide its nutritional information: calories, protein (g), carbs (g), and fat (g).";

      developer.log('🔹 VISION PROMPT: $prompt', name: 'GeminiVisionAPI');

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
      developer.log('📤 SENDING REQUEST TO GEMINI VISION API',
          name: 'GeminiVisionAPI');
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      developer.log('📥 VISION API RESPONSE STATUS: ${response.statusCode}',
          name: 'GeminiVisionAPI');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Log the full response for debugging
        final prettyJson =
            const JsonEncoder.withIndent('  ').convert(jsonResponse);
        developer.log('📦 COMPLETE VISION RESPONSE:\n$prettyJson',
            name: 'GeminiVisionAPI');

        final textResponse =
            jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        developer.log('📝 FOOD ANALYSIS TEXT:\n$textResponse',
            name: 'GeminiVisionAPI');

        // Parse response into FoodItem object
        final foodItem = _parseFoodResponse(textResponse);

        // Log the parsed food item
        developer.log(
            '🍽️ PARSED FOOD ITEM: ${foodItem.name} - '
            '${foodItem.calories}kcal, '
            '${foodItem.protein}g protein, '
            '${foodItem.carbs}g carbs, '
            '${foodItem.fat}g fat',
            name: 'GeminiVisionAPI');

        return foodItem;
      } else {
        developer.log(
            '❌ VISION API ERROR: ${response.statusCode}\n${response.body}',
            name: 'GeminiVisionAPI',
            error: response.body);
        throw Exception(
            'Failed to analyze food: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      developer.log('❌ EXCEPTION ANALYZING FOOD: $e',
          name: 'GeminiVisionAPI', error: e);
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
