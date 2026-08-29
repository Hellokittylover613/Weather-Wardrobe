import 'package:flutter/material.dart';
import '../widgets/outfit_card.dart';

class OutfitScreen extends StatelessWidget {
  const OutfitScreen({super.key});

  static const List<Map<String, dynamic>> allOutfits = [
    {'title': 'Winter Layer Style', 'icon': Icons.ac_unit_outlined},
    {'title': 'Beach Outfit', 'icon': Icons.beach_access_outlined},
    {'title': 'Party Wear', 'icon': Icons.celebration_outlined},
    {'title': 'Workout Outfit', 'icon': Icons.fitness_center_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Outfits'), centerTitle: true),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allOutfits.length,
        itemBuilder: (context, index) {
          final outfit = allOutfits[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: OutfitCard(
              title: outfit['title'] as String,
              image: '',
              icon: outfit['icon'] as IconData,
            ),
          );
        },
      ),
    );
  }
}
