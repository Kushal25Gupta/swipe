import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SwipeButtons extends StatelessWidget {
  final VoidCallback onRewind;
  final VoidCallback onPass;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final VoidCallback onBoost;

  const SwipeButtons({
    super.key,
    required this.onRewind,
    required this.onPass,
    required this.onSuperLike,
    required this.onLike,
    required this.onBoost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            onTap: onRewind,
            icon: Icons.refresh_rounded,
            color: AppColors.primary,
            size: 44,
            iconSize: 22,
            tooltip: 'Rewind',
          ),
          _buildCircleButton(
            onTap: onPass,
            icon: Icons.close_rounded,
            color: const Color(0xFFFF4458),
            size: 54,
            iconSize: 28,
            tooltip: 'Pass',
          ),
          _buildCircleButton(
            onTap: onSuperLike,
            icon: Icons.star_rounded,
            color: const Color(0xFF00D1FF),
            size: 44,
            iconSize: 22,
            tooltip: 'Super Like',
          ),
          _buildCircleButton(
            onTap: onLike,
            icon: Icons.favorite_rounded,
            color: const Color(0xFF00FE7E),
            size: 54,
            iconSize: 28,
            tooltip: 'Like',
          ),
          _buildCircleButton(
            onTap: onBoost,
            icon: Icons.bolt_rounded,
            color: AppColors.primary,
            size: 44,
            iconSize: 22,
            tooltip: 'Boost',
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required String tooltip,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundDark,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
} 