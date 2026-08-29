import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/wardrobe_service.dart';
import '../utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final WardrobeService _service = WardrobeService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _loadingStats = true;
  bool _uploadingPhoto = false;
  bool _photoLoadFailed = false;

  int _totalItems = 0;
  int _categoryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // ============================================================
  // LOAD WARDROBE STATS
  // ============================================================

  Future<void> _loadStats() async {
    try {
      final items = await _service.getWardrobeItems();

      final categories = <String>{};

      for (final item in items) {
        final category = item['category']?.toString();
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      if (!mounted) return;

      setState(() {
        _totalItems = items.length;
        _categoryCount = categories.length;
        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingStats = false;
      });
    }
  }

  // ============================================================
  // PICK + UPLOAD PROFILE PICTURE
  // ============================================================

  Future<void> _pickAndUploadProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('You must be logged in to set a profile picture.');
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image == null) return;

      setState(() {
        _uploadingPhoto = true;
      });

      final Uint8List bytes = await image.readAsBytes();

      final rawUrl = await _service.uploadImage(bytes, image.name);

      final fullUrl = _service.buildImageUrl(rawUrl);

      await user.updatePhotoURL(fullUrl);
      await user.reload();

      if (!mounted) return;

      setState(() {
        _uploadingPhoto = false;
        _photoLoadFailed = false;
      });

      _showMessage('Profile picture updated!');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _uploadingPhoto = false;
      });

      _showMessage('Could not update profile picture: $e');
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access your wardrobe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'Wardrobe User');

    final email = user?.email ?? '';

    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    final hasPhoto =
        (user?.photoURL != null &&
        user!.photoURL!.isNotEmpty &&
        !_photoLoadFailed);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.plum,
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.plum,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ======================================================
              // AVATAR + NAME + EMAIL
              // ======================================================
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _uploadingPhoto
                          ? null
                          : _pickAndUploadProfilePicture,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.coral.withOpacity(0.15),
                            backgroundImage: hasPhoto
                                ? NetworkImage(user.photoURL!)
                                : null,
                            onBackgroundImageError: hasPhoto
                                ? (error, stackTrace) {
                                    if (!mounted) return;
                                    setState(() {
                                      _photoLoadFailed = true;
                                    });
                                  }
                                : null,
                            child: _uploadingPhoto
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : (!hasPhoto
                                      ? Text(
                                          initial,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.coral,
                                          ),
                                        )
                                      : null),
                          ),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.plum,
                      ),
                    ),

                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.plum.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ======================================================
              // WARDROBE STATS
              // ======================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _loadingStats
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statColumn('$_totalItems', 'Items'),
                          Container(
                            height: 36,
                            width: 1,
                            color: AppColors.plum.withOpacity(.15),
                          ),
                          _statColumn('$_categoryCount', 'Categories'),
                        ],
                      ),
              ),

              const Spacer(),

              // ======================================================
              // LOGOUT
              // ======================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.plum,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.plum.withOpacity(.6)),
        ),
      ],
    );
  }
}
