import 'package:flutter/material.dart';

class WardrobeItem {
  final int? id;
  final String name;
  final String category;
  final String weather;
  final String occasion;
  final String? color;
  final String? imageUrl;
  final IconData icon;

  const WardrobeItem({
    this.id,
    required this.name,
    required this.category,
    required this.weather,
    required this.occasion,
    this.color,
    this.imageUrl,
    required this.icon,
  });

  // ------------------------------------------------------------
  // FROM JSON
  // ------------------------------------------------------------

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    final String category = json['category']?.toString() ?? 'Tops';

    return WardrobeItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString() ?? 'Wardrobe Item',
      category: category,
      weather: json['weather']?.toString() ?? 'Any',
      occasion: json['occasion']?.toString() ?? 'Any',
      color: json['color']?.toString(),
      imageUrl: json['image_url']?.toString(),
      icon: wardrobeCategories[category] ?? Icons.checkroom,
    );
  }

  // ------------------------------------------------------------
  // TO JSON
  // ------------------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'weather': weather,
      'occasion': occasion,
      'color': color,
      'image_url': imageUrl,
    };
  }
}

// ============================================================
// WARDROBE CATEGORIES
// ============================================================

const Map<String, IconData> wardrobeCategories = {
  'Tops': Icons.checkroom,
  'Bottoms': Icons.shopping_bag_outlined,
  'Outerwear': Icons.layers_outlined,
  'Shoes': Icons.directions_walk,
  'Accessories': Icons.watch_outlined,
};

// ============================================================
// WEATHER TYPES
// ============================================================

const List<String> wardrobeWeatherTypes = [
  'Any',
  'Hot',
  'Warm',
  'Cool',
  'Cold',
  'Rainy',
];

// ============================================================
// OCCASIONS
// ============================================================

const List<String> wardrobeOccasions = [
  'Any',
  'Casual',
  'Formal',
  'Work',
  'University',
  'Party',
  'Sports',
];
