import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/wardrobe_service.dart';
import '../utils/app_colors.dart';
import '../models/wardrobe_item.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  final WardrobeService _service = WardrobeService();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _items = [];

  String _selectedCategory = 'All';

  String _formCategory = wardrobeCategories.keys.first;

  String _formWeather = wardrobeWeatherTypes.first;

  String _formOccasion = wardrobeOccasions.first;

  XFile? _selectedImage;

  bool _loading = true;
  bool _saving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });

    _loadItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
    });

    try {
      final data = await _service.getWardrobeItems();

      setState(() {
        _items
          ..clear()
          ..addAll(data.map((e) => Map<String, dynamic>.from(e)));

        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });

      _showMessage('Could not load wardrobe: $e');
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();

    return _items.where((item) {
      final category = item['category']?.toString() ?? '';

      final name = item['name']?.toString() ?? '';

      final categoryMatch =
          _selectedCategory == 'All' || category == _selectedCategory;

      final searchMatch =
          query.isEmpty ||
          name.toLowerCase().contains(query) ||
          category.toLowerCase().contains(query);

      return categoryMatch && searchMatch;
    }).toList();
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage(void Function(void Function()) updateSheet) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) return;

      updateSheet(() {
        _selectedImage = image;
      });
    } catch (e) {
      _showMessage('Could not select image: $e');
    }
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter an item name.');
      return;
    }

    if (_selectedImage == null) {
      _showMessage('Please select an image.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // --------------------------------------------------------
      // UPLOAD
      // --------------------------------------------------------

      final Uint8List bytes = await _selectedImage!.readAsBytes();

      String imageUrl = await _service.uploadImage(bytes, _selectedImage!.name);

      // --------------------------------------------------------
      // BACKGROUND REMOVAL
      // --------------------------------------------------------

      final filename = imageUrl.split('/').last;

      try {
        imageUrl = await _service.removeBackground(filename);
      } catch (e) {
        debugPrint('Background removal unavailable: $e');
      }

      // --------------------------------------------------------
      // DATABASE
      // --------------------------------------------------------

      await _service.createWardrobeItem(
        name: name,
        category: _formCategory,
        weather: _formWeather,
        occasion: _formOccasion,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      Navigator.pop(context);

      _nameController.clear();

      setState(() {
        _selectedImage = null;
        _saving = false;
      });

      await _loadItems();

      _showMessage('✨ Outfit added to your wardrobe!');
    } catch (e) {
      setState(() {
        _saving = false;
      });

      _showMessage('Failed to save outfit: $e');
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final id = item['id'];

    if (id == null) return;

    try {
      await _service.deleteWardrobeItem(int.parse(id.toString()));

      setState(() {
        _items.remove(item);
      });

      _showMessage('Outfit removed.');
    } catch (e) {
      _showMessage('Could not delete outfit: $e');
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // ADD SHEET
  // ============================================================

  void _showAddSheet() {
    _nameController.clear();

    _formCategory = wardrobeCategories.keys.first;

    _formWeather = wardrobeWeatherTypes.first;

    _formOccasion = wardrobeOccasions.first;

    _selectedImage = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),

              child: Container(
                padding: const EdgeInsets.all(24),

                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),

                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Add to My Wardrobe',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.plum,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Upload an outfit and tell us how you wear it.',
                        style: TextStyle(
                          color: AppColors.plum.withOpacity(.65),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // IMAGE
                      GestureDetector(
                        onTap: () async {
                          await _pickImage(setSheetState);
                        },

                        child: Container(
                          height: 210,
                          width: double.infinity,

                          decoration: BoxDecoration(
                            color: AppColors.bgBottom,
                            borderRadius: BorderRadius.circular(20),
                          ),

                          child: _selectedImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 50,
                                      color: AppColors.plum.withOpacity(.6),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text('Tap to upload outfit'),
                                    const SizedBox(height: 5),
                                    Text(
                                      'JPG, PNG',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.plum.withOpacity(.5),
                                      ),
                                    ),
                                  ],
                                )
                              : FutureBuilder<Uint8List>(
                                  future: _selectedImage!.readAsBytes(),

                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Outfit name',
                          filled: true,
                          fillColor: AppColors.bgBottom,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      _sectionTitle('Category'),

                      _chips(wardrobeCategories.keys.toList(), _formCategory, (
                        value,
                      ) {
                        setSheetState(() {
                          _formCategory = value;
                        });
                      }),

                      const SizedBox(height: 18),

                      _sectionTitle('Weather'),

                      _chips(wardrobeWeatherTypes, _formWeather, (value) {
                        setSheetState(() {
                          _formWeather = value;
                        });
                      }),

                      const SizedBox(height: 18),

                      _sectionTitle('Occasion'),

                      _chips(wardrobeOccasions, _formOccasion, (value) {
                        setSheetState(() {
                          _formOccasion = value;
                        });
                      }),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 52,

                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveItem,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.coral,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),

                          child: _saving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'ADD TO WARDROBE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: .7,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.plum,
      ),
    );
  }

  Widget _chips(
    List<String> values,
    String selected,
    Function(String) onSelected,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final selectedValue = value == selected;

        return ChoiceChip(
          label: Text(value),
          selected: selectedValue,
          selectedColor: AppColors.coral,
          backgroundColor: AppColors.bgBottom,
          labelStyle: TextStyle(
            color: selectedValue ? Colors.white : AppColors.plum,
          ),
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }

  // ============================================================
  // ITEM CARD
  // ============================================================

  Widget _itemCard(Map<String, dynamic> item) {
    final imageUrl = _service.buildImageUrl(item['image_url']?.toString());

    final name = item['name']?.toString() ?? 'Outfit';

    final category = item['category']?.toString() ?? '';

    final weather = item['weather']?.toString() ?? '';

    final occasion = item['occasion']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),

                  child: imageUrl.isEmpty
                      ? Container(
                          width: double.infinity,
                          color: AppColors.bgBottom,
                          child: Icon(
                            Icons.checkroom,
                            size: 55,
                            color: AppColors.plum.withOpacity(.4),
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.bgBottom,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _deleteItem(item),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 19,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.plum,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.plum.withOpacity(.6),
                  ),
                ),

                const SizedBox(height: 7),

                Wrap(
                  spacing: 4,
                  children: [
                    if (weather.isNotEmpty) _miniTag('☁ $weather'),

                    if (occasion.isNotEmpty) _miniTag(occasion),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgBottom,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9, color: AppColors.plum),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;

    final categories = ['All', ...wardrobeCategories.keys];

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),

      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'My Wardrobe',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.plum,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${_items.length} pieces • your personal collection',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.plum.withOpacity(.65),
                        ),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: _showAddSheet,

                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // SEARCH
              TextField(
                controller: _searchController,

                decoration: InputDecoration(
                  hintText: 'Search your wardrobe...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.plum),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(.75),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // CATEGORY FILTER
              SizedBox(
                height: 40,

                child: ListView.separated(
                  scrollDirection: Axis.horizontal,

                  itemCount: categories.length,

                  separatorBuilder: (_, __) => const SizedBox(width: 8),

                  itemBuilder: (context, index) {
                    final category = categories[index];

                    final selected = category == _selectedCategory;

                    return ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      selectedColor: AppColors.coral,
                      backgroundColor: Colors.white.withOpacity(.75),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.plum,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : visibleItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.checkroom_outlined,
                              size: 65,
                              color: AppColors.plum.withOpacity(.35),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              _items.isEmpty
                                  ? 'Your wardrobe is waiting ✨'
                                  : 'No matching outfits',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.plum.withOpacity(.7),
                              ),
                            ),

                            const SizedBox(height: 6),

                            if (_items.isEmpty)
                              Text(
                                'Tap + to add your first outfit.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.plum.withOpacity(.5),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadItems,

                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),

                          padding: const EdgeInsets.only(bottom: 25),

                          itemCount: visibleItems.length,

                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: .68,
                              ),

                          itemBuilder: (context, index) {
                            return _itemCard(visibleItems[index]);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
