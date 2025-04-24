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

  // Convert FoodItem to a Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
    };
  }

  // Create a FoodItem from a Firebase Map
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['name'] ?? '',
      calories: map['calories'] ?? 0,
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'],
    );
  }
}
