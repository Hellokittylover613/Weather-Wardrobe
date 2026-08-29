import 'package:flutter/material.dart';

import '../models/wardrobe_item.dart';
import '../services/wardrobe_service.dart';
import '../utils/app_colors.dart';

class WardrobeItemCard extends StatelessWidget {
  final WardrobeItem item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const WardrobeItemCard({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final WardrobeService service = WardrobeService();

    final String imageUrl = service.buildImageUrl(item.imageUrl);
    debugPrint('RAW IMAGE URL: ${item.imageUrl}');
    debugPrint('FINAL IMAGE URL: $imageUrl');

    debugPrint('--------------------------------');
    debugPrint('WARDROBE ITEM: ${item.name}');
    debugPrint('RAW IMAGE URL: ${item.imageUrl}');
    debugPrint('FINAL IMAGE URL: $imageUrl');
    debugPrint('--------------------------------');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.plum.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // IMAGE
          // ======================================================
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              width: double.infinity,
              color: AppColors.bgBottom,
              child: imageUrl.isEmpty
                  ? _placeholder()
                  : Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('================================');
                        debugPrint('WARDROBE IMAGE FAILED');
                        debugPrint('RAW URL: ${item.imageUrl}');
                        debugPrint('FINAL URL: $imageUrl');
                        debugPrint('ERROR: $error');
                        debugPrint('================================');

                        return _imageError();
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) {
                          return child;
                        }

                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
            ),
          ),

          // ======================================================
          // DETAILS
          // ======================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.plum,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(
                          Icons.more_vert,
                          color: AppColors.plum.withOpacity(0.65),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          }

                          if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 10),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline),
                                SizedBox(width: 10),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.plum.withOpacity(0.65),
                    ),
                  ),

                  const Spacer(),

                  if (item.weather.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          size: 14,
                          color: AppColors.coral,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.weather,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.plum.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 3),

                  if (item.occasion.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 14,
                          color: AppColors.coral,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.occasion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.plum.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(item.icon, size: 55, color: AppColors.plum.withOpacity(0.35)),
    );
  }

  Widget _imageError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: AppColors.plum.withOpacity(0.35),
          ),
          const SizedBox(height: 8),
          Text(
            'Image unavailable',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.plum.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
