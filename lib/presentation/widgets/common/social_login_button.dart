import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';

enum SocialLoginType { google, apple, facebook }

class SocialLoginButton extends StatelessWidget {
  final SocialLoginType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _getIcon(),
                    const SizedBox(width: 12),
                    Text(
                      _getText(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _getIcon() {
    String assetPath;
    switch (type) {
      case SocialLoginType.google:
        assetPath = 'assets/images/google_logo.svg';
        break;
      case SocialLoginType.apple:
        assetPath = 'assets/images/apple_logo.svg';
        break;
      case SocialLoginType.facebook:
        assetPath = 'assets/images/facebook_logo.svg';
        break;
    }

    return SvgPicture.asset(
      assetPath,
      width: 24,
      height: 24,
    );
  }

  String _getText() {
    switch (type) {
      case SocialLoginType.google:
        return 'Continue with Google';
      case SocialLoginType.apple:
        return 'Continue with Apple';
      case SocialLoginType.facebook:
        return 'Continue with Facebook';
    }
  }
} 