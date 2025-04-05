import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/meal_plan.dart';
import '../../models/food_item.dart';
import '../../providers/diet_provider.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  bool _showDebugInfo = false;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    final dietProvider = Provider.of<DietProvider>(context);
    final mealPlan = dietProvider.currentMealPlan;

    if (mealPlan == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Your Meal Plan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_meals, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No meal plan available',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/diet-plan-form'),
                child: const Text('Create a Meal Plan'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Meal Plan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final dietProvider =
                  Provider.of<DietProvider>(context, listen: false);
              setState(() => _isRefreshing = true);
              // Reset session and generate new meal plan
              dietProvider.resetSession();
              dietProvider.generateMealPlan().then((_) {
                setState(() => _isRefreshing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generated a new meal plan!')),
                );
              }).catchError((error) {
                setState(() => _isRefreshing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              });
            },
            tooltip: 'Generate New Plan',
          ),
          // Debug toggle button
          IconButton(
            icon: Icon(_showDebugInfo ? Icons.bug_report : Icons.info_outline),
            onPressed: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
              });
            },
            tooltip: 'Toggle Debug Info',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nutrition overview card
                _buildNutritionSummaryCard(mealPlan),

                const SizedBox(height: 24),

                _buildMealSection('Breakfast', mealPlan.breakfast, context),
                _buildMealSection('Lunch', mealPlan.lunch, context),
                _buildMealSection('Dinner', mealPlan.dinner, context),
                _buildMealSection('Snacks', mealPlan.snacks, context),

                if (mealPlan.notes?.isNotEmpty == true)
                  _buildNotesSection(mealPlan.notes!, context),

                // Debug information section
                if (_showDebugInfo) _buildDebugSection(mealPlan, dietProvider),

                const SizedBox(height: 32),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Meal plan saved successfully'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Save Meal Plan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionSummaryCard(MealPlan mealPlan) {
    // Calculate total nutrition values
    int totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var food in [
      ...mealPlan.breakfast,
      ...mealPlan.lunch,
      ...mealPlan.dinner,
      ...mealPlan.snacks
    ]) {
      totalCalories += food.calories;
      totalProtein += food.protein;
      totalCarbs += food.carbs;
      totalFat += food.fat;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Nutrition Summary',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNutritionValue(
                    'Calories', '$totalCalories', 'kcal', Colors.orange),
                _buildNutritionValue('Protein', totalProtein.toStringAsFixed(1),
                    'g', Colors.red),
                _buildNutritionValue(
                    'Carbs', totalCarbs.toStringAsFixed(1), 'g', Colors.blue),
                _buildNutritionValue(
                    'Fat', totalFat.toStringAsFixed(1), 'g', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fix the _buildNutritionValue method to handle both Color and MaterialColor
  Widget _buildNutritionValue(
      String label, String value, String unit, Color color) {
    return Column(
      children: [
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  // Replace color.shade800 with a darker version of the color
                  color: _getDarkerColor(color),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                unit,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  // Replace color.shade800 with a darker version of the color
                  color: _getDarkerColor(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Add a helper method to get a darker shade of any Color
  Color _getDarkerColor(Color color) {
    // Create a darker version of the color by reducing brightness
    final HSLColor hslColor = HSLColor.fromColor(color);
    return hslColor
        .withLightness((hslColor.lightness - 0.2).clamp(0.0, 1.0))
        .toColor();
  }

  Widget _buildMealSection(
      String title, List<FoodItem> items, BuildContext context) {
    final totalCalories =
        items.fold<int>(0, (sum, item) => sum + item.calories);
    final totalProtein =
        items.fold<double>(0, (sum, item) => sum + item.protein);
    final totalCarbs = items.fold<double>(0, (sum, item) => sum + item.carbs);
    final totalFat = items.fold<double>(0, (sum, item) => sum + item.fat);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMealHeader(title, totalCalories, _getMealColor(title, context),
              _getMealIcon(title)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nutrition summary
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNutrientBadge(
                          'P: ${totalProtein.toStringAsFixed(1)}g',
                          Colors.red.shade400),
                      _buildNutrientBadge(
                          'C: ${totalCarbs.toStringAsFixed(1)}g',
                          Colors.blue.shade400),
                      _buildNutrientBadge('F: ${totalFat.toStringAsFixed(1)}g',
                          Colors.green.shade400),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...items.map((item) => GestureDetector(
                      onTap: () => _showRecipeDetails(context, item),
                      child: _buildFoodItem(item),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          // Replace color.shade800 with the helper method
          color: _getDarkerColor(color),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFoodItem(FoodItem item) {
    // Extract portion size from name if possible
    String displayName = item.name;
    String portion = "";

    // Check for portion sizes in parentheses
    final portionMatch = RegExp(r'(.*)\s*\((.*?)\)').firstMatch(item.name);
    if (portionMatch != null && portionMatch.groupCount >= 2) {
      displayName = portionMatch.group(1)?.trim() ?? item.name;
      portion = portionMatch.group(2)?.trim() ?? "";
    }

    // Wrap the Card in a GestureDetector
    return GestureDetector(
      onTap: () => _showRecipeDetails(context, item),
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food image or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _getFoodImage(item, displayName),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (portion.isNotEmpty)
                      Text(
                        portion,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildNutrientIcon(
                            'P',
                            item.protein.toStringAsFixed(1) + 'g',
                            Colors.red.shade400),
                        const SizedBox(width: 8),
                        _buildNutrientIcon(
                            'C',
                            item.carbs.toStringAsFixed(1) + 'g',
                            Colors.blue.shade400),
                        const SizedBox(width: 8),
                        _buildNutrientIcon(
                            'F',
                            item.fat.toStringAsFixed(1) + 'g',
                            Colors.green.shade400),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.calories} kcal',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodImagePlaceholder(String foodName) {
    // Generate a color based on the food name for consistent colors
    final int hashCode = foodName.isEmpty ? 0 : foodName.hashCode;
    final color = Colors.primaries[hashCode % Colors.primaries.length];

    return Container(
      width: 70,
      height: 70,
      color: color.withOpacity(0.2),
      child: Center(
        child: Text(
          foodName.isNotEmpty ? foodName[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientIcon(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: _getDarkerColor(color),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _getDarkerColor(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(
              notes,
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Debug panel to show raw API responses
  Widget _buildDebugSection(MealPlan mealPlan, DietProvider dietProvider) {
    final jsonMealPlan = {
      'breakfast': mealPlan.breakfast
          .map((f) => {
                'name': f.name,
                'calories': f.calories,
                'protein': f.protein,
                'carbs': f.carbs,
                'fat': f.fat,
              })
          .toList(),
      'lunch': mealPlan.lunch
          .map((f) => {
                'name': f.name,
                'calories': f.calories,
                'protein': f.protein,
                'carbs': f.carbs,
                'fat': f.fat,
              })
          .toList(),
      'dinner': mealPlan.dinner
          .map((f) => {
                'name': f.name,
                'calories': f.calories,
                'protein': f.protein,
                'carbs': f.carbs,
                'fat': f.fat,
              })
          .toList(),
      'snacks': mealPlan.snacks
          .map((f) => {
                'name': f.name,
                'calories': f.calories,
                'protein': f.protein,
                'carbs': f.carbs,
                'fat': f.fat,
              })
          .toList(),
      'notes': mealPlan.notes,
    };
    final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonMealPlan);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.developer_mode, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Debug Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            Text(
              'Raw Meal Plan Data:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  prettyJson,
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'User Profile:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            if (dietProvider.userProfile != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  'Age: ${dietProvider.userProfile!.age}\n'
                  'Height: ${dietProvider.userProfile!.height} cm\n'
                  'Weight: ${dietProvider.userProfile!.weight} kg\n'
                  'Goal: ${dietProvider.userProfile!.goal}\n'
                  'Diet Type: ${dietProvider.userProfile!.dietaryPreference}\n'
                  'Allergies: ${dietProvider.userProfile!.allergies.isEmpty ? 'None' : dietProvider.userProfile!.allergies.join(", ")}',
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: () {
                // Add functionality to copy data to clipboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Debug data copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Debug Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMealColor(String meal, BuildContext context) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return Colors.amber.shade700;
      case 'lunch':
        return Colors.green.shade700;
      case 'dinner':
        return Colors.blue.shade700;
      case 'snacks':
        return Colors.purple.shade700;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  IconData _getMealIcon(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snacks':
        return Icons.apple;
      default:
        return Icons.food_bank;
    }
  }

  Widget _buildMealHeader(
      String title, int calories, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$calories kcal',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the _showRecipeDetails method for better recipe display:

  void _showRecipeDetails(BuildContext context, FoodItem item) {
    // Extract the main food name (without portion size)
    String displayName = item.name;
    String portion = "";

    final portionMatch = RegExp(r'(.*)\s*\((.*?)\)').firstMatch(item.name);
    if (portionMatch != null && portionMatch.groupCount >= 2) {
      displayName = portionMatch.group(1)?.trim() ?? item.name;
      portion = portionMatch.group(2)?.trim() ?? "";
    }

    // Generate cooking instructions based on food name
    final cookingInstructions =
        _generateCookingInstructions(displayName, portion);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food image or placeholder - larger here
                  SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _getFoodImage(item, displayName),
                        ),
                        // Gradient overlay
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Food name at the bottom
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (portion.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Portion: $portion',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Close button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nutrition information
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nutrition facts card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nutrition Facts',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                _buildNutritionRow('Calories',
                                    '${item.calories} kcal', Colors.orange),
                                _buildNutritionRow(
                                    'Protein',
                                    '${item.protein.toStringAsFixed(1)} g',
                                    Colors.red),
                                _buildNutritionRow(
                                    'Carbs',
                                    '${item.carbs.toStringAsFixed(1)} g',
                                    Colors.blue),
                                _buildNutritionRow(
                                    'Fat',
                                    '${item.fat.toStringAsFixed(1)} g',
                                    Colors.green),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // How to prepare card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.restaurant_menu,
                                        color: Colors.deepOrange),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Preparation',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                ...cookingInstructions
                                    .map((step) => Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${cookingInstructions.indexOf(step) + 1}',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  step,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _generateCookingInstructions(String foodName, String portion) {
    final foodLower = foodName.toLowerCase();

    // Common base steps
    final List<String> steps = [
      'Gather all ingredients for $foodName.',
    ];

    // Add food-specific instructions
    if (foodLower.contains('yogurt')) {
      steps.add('Measure $portion of yogurt into a bowl.');
      if (foodLower.contains('berries') || foodLower.contains('fruit')) {
        steps.add('Wash and prepare fresh fruits to add on top.');
        steps
            .add('Sprinkle with your choice of toppings like granola or nuts.');
      }
      if (foodLower.contains('honey')) {
        steps.add('Drizzle with honey to taste.');
      }
    } else if (foodLower.contains('toast') || foodLower.contains('bread')) {
      steps.add('Toast bread to your preferred level of crispness.');
      if (foodLower.contains('avocado')) {
        steps.add('Slice ripe avocado and spread evenly on toast.');
        steps.add('Season with salt, pepper, and optional lemon juice.');
      }
    } else if (foodLower.contains('salad')) {
      steps.add('Wash and chop all vegetables.');
      steps.add('Combine ingredients in a large bowl.');
      steps.add('Prepare dressing and toss just before serving.');
    } else if (foodLower.contains('rice') || foodLower.contains('quinoa')) {
      steps.add('Rinse $portion of grains before cooking.');
      steps.add('Cook according to package instructions until tender.');
      steps.add('Fluff with a fork before serving.');
    } else if (foodLower.contains('tofu')) {
      steps.add('Press tofu to remove excess water.');
      steps.add('Cut into cubes or slices.');
      steps.add('Season and cook until golden brown.');
    } else if (foodLower.contains('curry') || foodLower.contains('stew')) {
      steps.add('Prepare and chop all vegetables.');
      steps.add('Sauté aromatics like onions and garlic.');
      steps.add('Add spices and cook until fragrant.');
      steps.add('Add remaining ingredients and simmer until cooked through.');
    } else if (foodLower.contains('smoothie')) {
      steps.add('Add all ingredients to a blender.');
      steps.add('Blend until smooth, adding liquid as needed.');
      steps.add('Pour into a glass and enjoy immediately.');
    } else {
      // Generic instructions for other foods
      steps.add('Prepare ingredients according to recipe.');
      steps.add('Cook using your preferred method.');
      steps.add('Season to taste and serve in the recommended portion size.');
    }

    // Serving suggestion
    steps.add('Serve $foodName immediately and enjoy!');

    return steps;
  }

  Widget _buildNutritionRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getFoodImage(FoodItem item, String displayName) {
    // Generate a food-specific placeholder if error occurs
    final fallbackWidget = _buildFoodImagePlaceholder(displayName);

    // Add randomization to prevent caching
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 1000;

    // For cleaner food name in image search
    final searchName = displayName.split('with').first.trim();
    final cleanFoodName = searchName.replaceAll(RegExp(r'[^\w\s]'), '').trim();

    // Use multiple image sources with randomization
    final sources = [
      'https://source.unsplash.com/200x200/?${Uri.encodeComponent(cleanFoodName)},food&$random',
      'https://loremflickr.com/200/200/${Uri.encodeComponent(cleanFoodName)},food?lock=$random',
      'https://foodish-api.herokuapp.com/api/images/${_getFoodCategory(cleanFoodName)}?cache=$random'
    ];

    // Randomize image source selection
    final selectedSource = sources[random % sources.length];

    return Image.network(
      selectedSource,
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Try next source if this one fails
        final backupSource =
            'https://picsum.photos/seed/${cleanFoodName.hashCode + random}/200';
        return Image.network(
          backupSource,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallbackWidget,
        );
      },
    );
  }

  String _getFoodCategory(String foodName) {
    final name = foodName.toLowerCase();
    if (name.contains('rice') ||
        name.contains('grain') ||
        name.contains('oat')) {
      return 'rice';
    } else if (name.contains('pasta') || name.contains('noodle')) {
      return 'pasta';
    } else if (name.contains('pizza')) {
      return 'pizza';
    } else if (name.contains('burger')) {
      return 'burger';
    } else if (name.contains('dessert') ||
        name.contains('sweet') ||
        name.contains('cake') ||
        name.contains('yogurt')) {
      return 'dessert';
    } else if (name.contains('vegetable') ||
        name.contains('salad') ||
        name.contains('spinach')) {
      return 'vegetable';
    } else {
      return 'samosa'; // Default category with nice looking images
    }
  }
}
