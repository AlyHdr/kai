import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text(
            'About Kai',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Kai is an AI-powered nutrition assistant that generates general dietary insights using publicly available nutritional concepts and machine learning models.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 12),
          Text(
            'The information provided by Kai is not based on clinical studies or individual medical data, and may not be accurate for all users.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Disclaimer:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Kai does not provide medical or health advice. All content is for educational and informational purposes only. Always consult a qualified healthcare provider or registered dietitian before making changes to your diet or lifestyle.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Calculation Sources:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'The AI model is prompted to use the Mifflin-St Jeor formula (Mifflin et al., 1990) for calorie target calculation . Activity multipliers from WHO/FAO/UNU (2001). Macronutrient ranges per USDA Dietary Guidelines (2020–2025).',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
