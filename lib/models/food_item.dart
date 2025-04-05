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

  // Generate a placeholder image URL for a food item
  String get placeholderImageUrl {
    // Extract the main food name (without portion size)
    final mainFood = name.split('(').first.trim();

    // Use Pixabay API for more reliable food images (requires no API key for low res)
    if (mainFood.toLowerCase().contains('default') || mainFood.isEmpty) {
      // Return generic food category image for defaults
      return 'https://cdn.pixabay.com/photo/2017/03/23/19/57/asparagus-2169305_640.jpg';
    }

    // Clean the food name and encode
    final cleanName = mainFood.replaceAll(RegExp(r'[^\w\s]'), '');
    final encodedFood = Uri.encodeComponent(cleanName);

    // Use Pixabay API which is more reliable than Unsplash's random API
    return 'https://pixabay.com/api/?key=36507464-01dfb634243afe8e17a41b649&q=$encodedFood+food&image_type=photo&per_page=3';
  }
}
