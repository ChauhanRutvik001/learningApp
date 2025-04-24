import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/meal_plan.dart';
import '../../providers/diet_provider.dart';
import 'meal_plan_screen.dart';

class SavedDietPlansScreen extends StatefulWidget {
  const SavedDietPlansScreen({super.key});

  @override
  State<SavedDietPlansScreen> createState() => _SavedDietPlansScreenState();
}

class _SavedDietPlansScreenState extends State<SavedDietPlansScreen> {
  bool _isLoading = true;
  List<MealPlan> _savedPlans = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedPlans();
  }

  Future<void> _loadSavedPlans() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the DietProvider to load saved plans
      final dietProvider = Provider.of<DietProvider>(context, listen: false);
      final plans = await dietProvider.getSavedMealPlans();
      setState(() {
        _savedPlans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDietPlan(String planId) async {
    try {
      // Use the DietProvider to delete the plan
      final dietProvider = Provider.of<DietProvider>(context, listen: false);
      final success = await dietProvider.deleteMealPlan(planId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diet plan deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload plans after deletion
        _loadSavedPlans();
      } else {
        throw Exception('Failed to delete the diet plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting plan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Diet Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedPlans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSavedPlans,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _savedPlans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.no_food,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved diet plans yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generate a new diet plan and save it',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _savedPlans.length,
                      itemBuilder: (context, index) {
                        final plan = _savedPlans[index];
                        return _buildDietPlanCard(context, plan);
                      },
                    ),
    );
  }

  Widget _buildDietPlanCard(BuildContext context, MealPlan plan) {
    final createdDate = plan.createdAt != null
        ? '${plan.createdAt!.day}/${plan.createdAt!.month}/${plan.createdAt!.year}'
        : 'Unknown date';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Created on $createdDate',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nutrition summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniNutritionItem(
                      'Calories',
                      '${plan.totalCalories}',
                      Colors.orange,
                    ),
                    _buildMiniNutritionItem(
                      'Protein',
                      '${plan.totalProtein.toStringAsFixed(1)}g',
                      Colors.red,
                    ),
                    _buildMiniNutritionItem(
                      'Carbs',
                      '${plan.totalCarbs.toStringAsFixed(1)}g',
                      Colors.blue,
                    ),
                    _buildMiniNutritionItem(
                      'Fat',
                      '${plan.totalFat.toStringAsFixed(1)}g',
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Meals summary
                _buildMealSummary('Breakfast', plan.breakfast.length),
                const SizedBox(height: 8),
                _buildMealSummary('Lunch', plan.lunch.length),
                const SizedBox(height: 8),
                _buildMealSummary('Dinner', plan.dinner.length),
                const SizedBox(height: 8),
                _buildMealSummary('Snacks', plan.snacks.length),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Delete button
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                        ),
                      ),
                      onPressed: () => _showDeleteConfirmation(plan.id!),
                    ),
                    const SizedBox(width: 8),
                    
                    // View button
                    ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                      onPressed: () {
                        // Navigate to view the full meal plan
                        // This would require modifying the MealPlanScreen to accept
                        // a MealPlan parameter, but for now we'll use a placeholder
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MealPlanScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniNutritionItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMealSummary(String mealType, int itemCount) {
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 10,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$mealType: ',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$itemCount items',
          style: GoogleFonts.poppins(),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Diet Plan'),
        content: const Text(
          'Are you sure you want to delete this diet plan? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDietPlan(planId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}