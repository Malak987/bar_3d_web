import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/color_utils.dart';

/// Displays either a data-URL or a normal network image
class PreviewImage extends StatelessWidget {
  final String data;
  final double size;

  const PreviewImage({
    super.key,
    required this.data,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = tryDecodeDataUrl(data);
    final fallback = _fallback();

    if (bytes != null) {
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return Image.network(
      data,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _fallback() => Container(
        width: size,
        height: size,
        color: const Color(0xFFF3F4F6),
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.hint,
        ),
      );
}
