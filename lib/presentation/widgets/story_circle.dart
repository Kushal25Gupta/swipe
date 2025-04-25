import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

class StoryCircle extends StatelessWidget {
  final String? imageUrl;
  final bool isAddButton;
  final bool hasUnseenStories;
  final double size;
  final VoidCallback? onTap;

  const StoryCircle({
    Key? key,
    this.imageUrl,
    this.isAddButton = false,
    this.hasUnseenStories = false,
    this.size = 56,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasUnseenStories
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.7),
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: !hasUnseenStories
              ? Border.all(
                  color: Colors.white24,
                  width: 1,
                )
              : null,
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            shape: BoxShape.circle,
          ),
          child: isAddButton
              ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(size / 2),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[900],
                            child: const Icon(
                              Icons.person,
                              color: Colors.white38,
                              size: 24,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: const Icon(
                            Icons.person,
                            color: Colors.white38,
                            size: 24,
                          ),
                        ),
                ),
        ),
      ),
    );
  }
} 