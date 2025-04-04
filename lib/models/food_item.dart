class FoodItem {
  final String name;
  final int calories;
  final double protein; // in grams
  final double carbs; // in grams
  final double fat; // in grams
  final String? imageUrl;

  FoodItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imageUrl,
  });
}
