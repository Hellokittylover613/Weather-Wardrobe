import 'package:flutter/material.dart';

class OutfitCard extends StatelessWidget {
  final String title;
  final String image;
  final IconData? icon;

  const OutfitCard({
    super.key,
    required this.title,
    required this.image,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: image.isNotEmpty
                ? Image.asset(
                    image,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Icon(
                    icon ?? Icons.checkroom_outlined,
                    size: 70,
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
