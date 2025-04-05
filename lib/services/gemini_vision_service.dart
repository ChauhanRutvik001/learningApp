import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  // API key already correctly set
  static const String apiKey = 'AIzaSyBwUnN3aDHbySQIApPli86kKwZWVSOuJ_0';

  // Update to use the stable version of the API
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<Map<String, dynamic>> analyzeFood(Uint8List imageBytes) async {
    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // Create request body with improved prompt for better structure
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': '''
                Please analyze this food image and provide the following information in a clear, structured format:
                
                1. Food name/dish name: [Name the dish and its origin/cuisine]
                2. Main components: [List the visible components]
                3. Approximate calories per serving: [Number] calories
                4. Approximate protein content: [Number] grams
                5. Approximate carbohydrate content: [Number] grams
                6. Approximate fat content: [Number] grams
                7. Health assessment: [State if it's generally considered healthy, moderate, or unhealthy]
                8. Nutritional highlights: [Brief note about key nutrients]
                
                For traditional meals like Indian thalis, please identify the main components and their nutritional contributions.
                '''
              },
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}
              }
            ]
          }
        ]
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
        print("Text response: $textResponse");

        // Process and extract food data from the text response
        final result = _extractFoodData(textResponse);

        // Always include the raw response for display
        result['rawResponse'] = textResponse;

        return result;
      } else {
        print("API Error: ${response.statusCode}, ${response.body}");
        throw Exception(
            'Failed to analyze food: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print("Error in analyzeFood: $e");
      return {
        'foodName': 'Analysis Error',
        'error': e.toString(),
        'rawResponse': 'Error occurred: $e',
        'calories': 'N/A',
        'protein': 'N/A',
        'carbs': 'N/A',
        'fat': 'N/A',
        'isHealthy': false,
        'healthInfo': 'Could not analyze the image. Please try again.',
        'components': [],
      };
    }
  }

  static Map<String, dynamic> _extractFoodData(String text) {
    // Default values
    Map<String, dynamic> result = {
      'foodName': 'Unknown Food',
      'calories': 'N/A',
      'protein': 'N/A',
      'carbs': 'N/A',
      'fat': 'N/A',
      'isHealthy': null,
      'healthInfo': 'No health information available.',
      'components': [],
    };

    try {
      // Extract food name using better patterns based on the sample response
      final foodNameRegex = RegExp(
          r'Food Name/Dish Name:\s*\*?(.*?)(?:\*|\.|$)',
          caseSensitive: false,
          dotAll: true);
      final foodMatch = foodNameRegex.firstMatch(text);

      if (foodMatch != null && foodMatch.groupCount >= 1) {
        String foodName = foodMatch.group(1)?.trim() ?? 'Unknown Food';
        // Clean up markdown or formatting characters
        foodName = foodName.replaceAll(RegExp(r'\*'), '').trim();
        result['foodName'] = foodName;
      } else if (text.toLowerCase().contains("thali")) {
        if (text.toLowerCase().contains("gujarati")) {
          result['foodName'] = "Gujarati Thali";
        } else if (text.toLowerCase().contains("south indian")) {
          result['foodName'] = "South Indian Thali";
        } else {
          result['foodName'] = "Indian Thali";
        }
      }

      // Extract components from the thali
      final componentsRegex = RegExp(
          r'Main components:.*?(?:\n|$)(.*?)(?:\n\d\.|\n\*|\n$)',
          caseSensitive: false,
          dotAll: true);
      final componentsMatch = componentsRegex.firstMatch(text);

      if (componentsMatch != null && componentsMatch.groupCount >= 1) {
        String components = componentsMatch.group(1)?.trim() ?? '';
        List<String> componentList = components
            .split(RegExp(r'[,;•\n]'))
            .where((item) => item.trim().isNotEmpty)
            .map((item) => item.trim().replaceAll(RegExp(r'\*'), ''))
            .toList();

        result['components'] = componentList;
      } else {
        // Extract items from lines that look like food items
        final itemRegex = RegExp(
            r'(?:contains|includes?|has|with)\s+([\w\s,]+)(?:\.|$)',
            caseSensitive: false);
        final itemMatches = itemRegex.allMatches(text);

        List<String> items = [];
        for (final match in itemMatches) {
          if (match.groupCount >= 1) {
            String components = match.group(1) ?? '';
            items.addAll(components
                .split(',')
                .where((item) => item.trim().isNotEmpty)
                .map((item) => item.trim()));
          }
        }

        if (items.isNotEmpty) {
          result['components'] = items;
        }
      }

      // Extract calories - handle number ranges like 800-1200
      final caloriesRegex = RegExp(
          r'(\d+)(?:\s*-\s*(\d+))?\s*(?:kcal|calories)',
          caseSensitive: false);
      final caloriesMatch = caloriesRegex.firstMatch(text);

      if (caloriesMatch != null) {
        if (caloriesMatch.groupCount >= 2 && caloriesMatch.group(2) != null) {
          // Range found - use the middle value
          int min = int.tryParse(caloriesMatch.group(1) ?? '0') ?? 0;
          int max = int.tryParse(caloriesMatch.group(2) ?? '0') ?? 0;
          result['calories'] = ((min + max) / 2).round().toString();
        } else {
          // Single value
          result['calories'] = caloriesMatch.group(1) ?? 'N/A';
        }
      }

      // Extract protein with range support
      final proteinRegex = RegExp(
          r'(\d+(?:\.\d+)?)(?:\s*-\s*(\d+(?:\.\d+)?))?(?:\s*grams|\s*g) (?:of )?protein',
          caseSensitive: false);
      final proteinMatch = proteinRegex.firstMatch(text);

      if (proteinMatch != null) {
        if (proteinMatch.groupCount >= 2 && proteinMatch.group(2) != null) {
          // Range found - use the middle value
          double min = double.tryParse(proteinMatch.group(1) ?? '0') ?? 0;
          double max = double.tryParse(proteinMatch.group(2) ?? '0') ?? 0;
          result['protein'] = ((min + max) / 2).toString();
        } else {
          // Single value
          result['protein'] = proteinMatch.group(1) ?? 'N/A';
        }
      }

      // Extract carbs with range support
      final carbsRegex = RegExp(
          r'(\d+(?:\.\d+)?)(?:\s*-\s*(\d+(?:\.\d+)?))?(?:\s*grams|\s*g) (?:of )?carb',
          caseSensitive: false);
      final carbsMatch = carbsRegex.firstMatch(text);

      if (carbsMatch != null) {
        if (carbsMatch.groupCount >= 2 && carbsMatch.group(2) != null) {
          // Range found - use the middle value
          double min = double.tryParse(carbsMatch.group(1) ?? '0') ?? 0;
          double max = double.tryParse(carbsMatch.group(2) ?? '0') ?? 0;
          result['carbs'] = ((min + max) / 2).toString();
        } else {
          // Single value
          result['carbs'] = carbsMatch.group(1) ?? 'N/A';
        }
      }

      // Extract fat with range support
      final fatRegex = RegExp(
          r'(\d+(?:\.\d+)?)(?:\s*-\s*(\d+(?:\.\d+)?))?(?:\s*grams|\s*g) (?:of )?fat',
          caseSensitive: false);
      final fatMatch = fatRegex.firstMatch(text);

      if (fatMatch != null) {
        if (fatMatch.groupCount >= 2 && fatMatch.group(2) != null) {
          // Range found - use the middle value
          double min = double.tryParse(fatMatch.group(1) ?? '0') ?? 0;
          double max = double.tryParse(fatMatch.group(2) ?? '0') ?? 0;
          result['fat'] = ((min + max) / 2).toString();
        } else {
          // Single value
          result['fat'] = fatMatch.group(1) ?? 'N/A';
        }
      }

      // Determine if healthy based on keywords
      if (text.toLowerCase().contains("healthy") &&
          !text.toLowerCase().contains("not healthy") &&
          !text.toLowerCase().contains("unhealthy")) {
        result['isHealthy'] = true;
      } else if (text.toLowerCase().contains("unhealthy") ||
          text.toLowerCase().contains("not healthy")) {
        result['isHealthy'] = false;
      } else if (text.toLowerCase().contains("moderat")) {
        result['isHealthy'] = null; // Neutral for "moderate"
      }

      // Extract health information
      final healthInfoRegex = RegExp(
          r'(?:Health Information|Nutritional highlights|Health assessment).*?:(.*?)(?:\n\d\.|\n$)',
          caseSensitive: false,
          dotAll: true);
      final healthMatch = healthInfoRegex.firstMatch(text);

      if (healthMatch != null && healthMatch.groupCount >= 1) {
        String healthInfo = healthMatch.group(1)?.trim() ?? '';
        healthInfo = healthInfo.replaceAll(RegExp(r'\*'), '').trim();
        if (healthInfo.isNotEmpty) {
          result['healthInfo'] = healthInfo;
        }
      } else {
        // Look for sentences about health
        final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
        for (final sentence in sentences) {
          if (sentence.length > 20 &&
              (sentence.toLowerCase().contains("nutrient") ||
                  sentence.toLowerCase().contains("health") ||
                  sentence.toLowerCase().contains("nutrition") ||
                  sentence.toLowerCase().contains("benefit"))) {
            result['healthInfo'] = sentence.trim();
            break;
          }
        }
      }
    } catch (e) {
      print("Error extracting food data: $e");
      // If error occurs in extraction, keep defaults and add error info
      result['error'] = e.toString();
    }

    return result;
  }
}
