import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/gemini_vision_service.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _isLoading = false;
  Map<String, dynamic>? _foodAnalysis;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image == null) return;

      // Get bytes - works on all platforms including web
      final bytes = await image.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _foodAnalysis = null;
        _errorMessage = null;
      });

      // Automatically analyze the image
      _analyzeFood();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (photo == null) return;

      // Get bytes - works on all platforms including web
      final bytes = await photo.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _foodAnalysis = null;
        _errorMessage = null;
      });

      // Automatically analyze the image
      _analyzeFood();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to take photo: $e';
      });
    }
  }

  Future<void> _analyzeFood() async {
    if (_imageBytes == null) return;

    setState(() {
      _isLoading = true;
      _foodAnalysis = null;
      _errorMessage = null;
    });

    try {
      final analysis = await GeminiVisionService.analyzeFood(_imageBytes!);

      setState(() {
        _foodAnalysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error analyzing food: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Nutritional Scanner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image display area
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _imageBytes == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_search,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Upload a food image to analyze',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  // Using Image.memory which works on web and mobile
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Photo buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload Image'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing food...'),
                  ],
                ),
              ),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(color: Colors.red[700]),
                ),
              ),

            // Food analysis results
            if (_foodAnalysis != null && !_isLoading)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _foodAnalysis!['foodName'] ?? 'Unknown Food',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Nutritional info
                      _buildNutrientRow(
                          'Calories',
                          '${_foodAnalysis!['calories'] ?? 'N/A'} kcal',
                          Icons.local_fire_department),
                      _buildNutrientRow(
                          'Protein',
                          '${_foodAnalysis!['protein'] ?? 'N/A'} g',
                          Icons.fitness_center),
                      _buildNutrientRow('Carbs',
                          '${_foodAnalysis!['carbs'] ?? 'N/A'} g', Icons.grain),
                      _buildNutrientRow('Fat',
                          '${_foodAnalysis!['fat'] ?? 'N/A'} g', Icons.opacity),

                      const SizedBox(height: 16),

                      // After the nutritional values, add this section to display components
                      if (_foodAnalysis!.containsKey('components') &&
                          _foodAnalysis!['components'] is List &&
                          (_foodAnalysis!['components'] as List).isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'Main Components:',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...(_foodAnalysis!['components'] as List)
                                .map((component) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.fiber_manual_record,
                                              size: 12, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              component,
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

                      // Health info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_foodAnalysis!['isHealthy'] == true)
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_foodAnalysis!['isHealthy'] == true)
                                ? Colors.green[300]!
                                : Colors.orange[300]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  (_foodAnalysis!['isHealthy'] == true)
                                      ? Icons.check_circle
                                      : Icons.info,
                                  color: (_foodAnalysis!['isHealthy'] == true)
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (_foodAnalysis!['isHealthy'] == true)
                                      ? 'Healthy Choice'
                                      : 'Consume in Moderation',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: (_foodAnalysis!['isHealthy'] == true)
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _foodAnalysis!['healthInfo'] ??
                                  'No health information available.',
                              style: GoogleFonts.poppins(),
                            ),
                          ],
                        ),
                      ),

                      // Display the raw response in a collapsible section for detailed info
                      ExpansionTile(
                        title: Text(
                          'Detailed Food Analysis',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _foodAnalysis!['rawResponse'] ??
                                  'No detailed analysis available',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ),
                        ],
                      ),

                      // Add this below the ExpansionTile or where appropriate
                      if (_foodAnalysis!.containsKey('error'))
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: _analyzeFood,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry Analysis'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
