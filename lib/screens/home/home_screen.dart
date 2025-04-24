import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/diet_provider.dart';
import '../../models/meal_plan.dart';
import '../diet_plan/saved_diet_plans_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<MealPlan> _recentDietPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentDietPlans();
  }

  Future<void> _loadRecentDietPlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dietProvider = Provider.of<DietProvider>(context, listen: false);
      final plans = await dietProvider.getSavedMealPlans();
      
      // Only show up to 2 most recent plans
      setState(() {
        _recentDietPlans = plans.take(2).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recent diet plans: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dietProvider = Provider.of<DietProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NutriScan AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentDietPlans,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero section
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade300, Colors.green.shade700],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Personal\nNutrition Assistant',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI-powered diet plans and food analysis',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main features
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Feature Cards
                    _buildFeatureCard(
                      context,
                      'Create Personalized Diet Plan',
                      'Get AI-generated meal plans based on your health goals',
                      Icons.restaurant_menu,
                      Colors.orange.shade100,
                      () => Navigator.pushNamed(context, '/diet-plan-form'),
                    ),

                    _buildFeatureCard(
                      context,
                      'Scan Food with AI',
                      'Take a photo to identify food and get nutritional info',
                      Icons.camera_alt,
                      Colors.blue.shade100,
                      () => Navigator.pushNamed(context, '/food-scanner'),
                    ),

                    _buildFeatureCard(
                      context,
                      'View Saved Diet Plans',
                      'Access your personalized diet plans',
                      Icons.history,
                      Colors.green.shade100,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedDietPlansScreen(),
                        ),
                      ),
                    ),

                    // Your Diet Plans section
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Diet Plans',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SavedDietPlansScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'See All',
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // User's diet plans section
                    _buildDietPlansSection(),

                    const SizedBox(height: 24),
                    
                    // Diet types section
                    Text(
                      'Diet Types',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Diet type grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildDietTypeCard('Keto', 'Low carb, high fat',
                            'assets/keto.jpg', Colors.red.shade100),
                        _buildDietTypeCard('Vegetarian', 'Plant-based options',
                            'assets/vegetarian.jpg', Colors.green.shade100),
                        _buildDietTypeCard('Vegan', 'Entirely plant-based',
                            'assets/vegan.jpg', Colors.teal.shade100),
                        _buildDietTypeCard('Paleo', 'Ancestral nutrition',
                            'assets/paleo.jpg', Colors.amber.shade100),
                      ],
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

  Widget _buildDietPlansSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_recentDietPlans.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.no_food,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No saved diet plans yet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Diet Plan'),
                onPressed: () => Navigator.pushNamed(context, '/diet-plan-form'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: _recentDietPlans.map((plan) => _buildDietPlanCard(plan)).toList(),
    );
  }

  Widget _buildDietPlanCard(MealPlan plan) {
    final createdDate = plan.createdAt != null
        ? '${plan.createdAt!.day}/${plan.createdAt!.month}/${plan.createdAt!.year}'
        : 'Unknown date';
        
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to view diet plan details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SavedDietPlansScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant_menu, color: Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diet Plan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Created on $createdDate',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Nutrition info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNutritionBadge('${plan.totalCalories} kcal', 'Calories'),
                  _buildNutritionBadge('${plan.totalProtein.toStringAsFixed(1)}g', 'Protein'),
                  _buildNutritionBadge('${plan.totalCarbs.toStringAsFixed(1)}g', 'Carbs'),
                  _buildNutritionBadge('${plan.totalFat.toStringAsFixed(1)}g', 'Fat'),
                ],
              ),
              const SizedBox(height: 12),
              // Meals summary
              Wrap(
                spacing: 8,
                children: [
                  _buildMealChip('${plan.breakfast.length} Breakfast'),
                  _buildMealChip('${plan.lunch.length} Lunch'),
                  _buildMealChip('${plan.dinner.length} Dinner'),
                  _buildMealChip('${plan.snacks.length} Snacks'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionBadge(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMealChip(String label) {
    return Chip(
      label: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12),
      ),
      backgroundColor: Colors.grey[200],
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title,
      String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDietTypeCard(
      String title, String subtitle, String imageAsset, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.food_bank, size: 48),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
