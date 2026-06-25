import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/cake_config.dart';
import '../../services/web_helpers.dart';
import '../common/section.dart';
import '../common/light_slider.dart';
import '../common/preview_image.dart';

/// Section 7 — Photo on top of cake
class PhotoSection extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const PhotoSection({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Section(
      number: 7,
      title: 'PHOTO',
      arabicTitle: 'الصورة الشخصية',
      subtitle: 'أضف صورتك المفضلة على وجه الكيكة',
      child: Column(
        children: [
          _uploadButton(),
          if (config.topImage != null) ...[
            const SizedBox(height: 10),
            _imagePreview(),
            const SizedBox(height: 8),
            LightSlider(
              label: 'حجم الصورة',
              value: config.imageScale,
              min: 0.3,
              max: 1.0,
              display: '${(config.imageScale * 100).round()}%',
              onChanged: (v) => onChanged(config.copyWith(imageScale: v)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _uploadButton() {
    return GestureDetector(
      onTap: () async {
        final url = await WebHelpers.pickImageAsDataUrl();
        if (url != null) onChanged(config.copyWith(topImage: url));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: const Column(
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.primary, size: 28),
            SizedBox(height: 6),
            Text(
              'Upload Photo Frame Image',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: PreviewImage(data: config.topImage!, size: 60),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'صورة محددة ✓',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: () => onChanged(config.copyWith(topImage: null)),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
