import 'package:flutter/material.dart';
import '../widgets/outfit_card.dart';
import 'outfit_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Map<String, dynamic>> outfits = [
    {'title': 'Casual Summer Look', 'icon': Icons.wb_sunny_outlined},
    {'title': 'Office Wear', 'icon': Icons.business_center_outlined},
    {'title': 'Rainy Day Outfit', 'icon': Icons.umbrella_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weather Wardrobe'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Outfit Suggestions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: outfits.length,
                itemBuilder: (context, index) {
                  final outfit = outfits[index];

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
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OutfitScreen()),
                );
              },
              child: const Text('View All Outfits'),
            ),
          ],
        ),
      ),
    );
  }
}
