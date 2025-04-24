import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/diet_provider.dart';
import '../../models/meal_plan.dart';
import '../../models/food_item.dart';
import 'saved_diet_plans_screen.dart';

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dietProvider = Provider.of<DietProvider>(context);
    final mealPlan = dietProvider.currentMealPlan;

    if (mealPlan == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Meal Plan'),
        ),
        body: const Center(
          child: Text('No meal plan generated yet.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Meal Plan'),
        actions: [
          // Add save button to app bar
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Diet Plan',
            onPressed: () async {
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text("Saving diet plan..."),
                      ],
                    ),
                  );
                },
              );

              try {
                // Save meal plan using the provider
                String? savedId = await dietProvider.saveMealPlan();
                
                // Pop loading dialog
                Navigator.pop(context);
                
                if (savedId != null) {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Diet plan saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Ask user if they want to view saved plans
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Diet Plan Saved'),
                      content: const Text('Would you like to view your saved diet plans?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Not Now'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SavedDietPlansScreen(),
                              ),
                            );
                          },
                          child: const Text('View Saved Plans'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save diet plan. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Pop loading dialog and show error
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          
          // Add button to view saved plans
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Saved Plans',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedDietPlansScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nutrition summary card
            _buildNutritionSummaryCard(context, mealPlan),
            const SizedBox(height: 24),

            // Breakfast section
            _buildMealSection(context, 'Breakfast', mealPlan.breakfast),

            // Lunch section
            _buildMealSection(context, 'Lunch', mealPlan.lunch),

            // Dinner section
            _buildMealSection(context, 'Dinner', mealPlan.dinner),

            // Snacks section
            _buildMealSection(context, 'Snacks', mealPlan.snacks),

            if (mealPlan.notes != null && mealPlan.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Notes',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  mealPlan.notes!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSummaryCard(BuildContext context, MealPlan mealPlan) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionItem('Calories',
                    '${mealPlan.totalCalories} kcal', Colors.orange),
                _buildNutritionItem(
                    'Protein',
                    '${mealPlan.totalProtein.toStringAsFixed(1)} g',
                    Colors.red),
                _buildNutritionItem('Carbs',
                    '${mealPlan.totalCarbs.toStringAsFixed(1)} g', Colors.blue),
                _buildNutritionItem('Fat',
                    '${mealPlan.totalFat.toStringAsFixed(1)} g', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection(
      BuildContext context, String title, List<FoodItem> foods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${foods.length} items',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...foods.map((food) => _buildFoodItem(food)).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFoodItem(FoodItem food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.restaurant,
                color: Colors.green.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${food.calories} kcal',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'P: ${food.protein.toStringAsFixed(1)}g',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'C: ${food.carbs.toStringAsFixed(1)}g',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'F: ${food.fat.toStringAsFixed(1)}g',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
