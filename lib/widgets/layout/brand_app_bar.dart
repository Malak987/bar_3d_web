import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// ──────────────────────────────────────────────────────
/// BrandAppBar — Top header with logo, title and Save btn
/// ──────────────────────────────────────────────────────
class BrandAppBar extends StatelessWidget {
  final VoidCallback onDownload;

  const BrandAppBar({super.key, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 14),
          _logo(),
          const SizedBox(width: 12),
          _titleColumn(),
          const Spacer(),
          _saveButton(),
        ],
      ),
    );
  }

  Widget _backButton() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.primary,
        ),
      );

  Widget _logo() => Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.teal, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.teal,
              child: const Icon(
                Icons.cake_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      );

  Widget _titleColumn() => const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Design Cake',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            'صمّم تورتتك بنفسك ✨',
            style: TextStyle(color: AppColors.textLight, fontSize: 11),
          ),
        ],
      );

  Widget _saveButton() => GestureDetector(
        onTap: onDownload,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.teal, AppColors.tealDark],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_rounded, size: 17, color: Colors.white),
              SizedBox(width: 7),
              Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
}
