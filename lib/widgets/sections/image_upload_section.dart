import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/web_helpers.dart';

/// 📸 Image Upload Section
///
/// Allows user to:
/// - Upload reference images for their cake design
/// - Preview uploaded images
/// - Remove uploaded images
///
/// Note: These are user-uploaded reference images, NOT the final design image.
/// The final design image is automatically captured when adding to cart.
class ImageUploadSection extends StatefulWidget {
  final Function(Uint8List, String) onUpload;
  final Uint8List? uploadedImage;

  const ImageUploadSection({
    super.key,
    required this.onUpload,
    this.uploadedImage,
  });

  @override
  State<ImageUploadSection> createState() => _ImageUploadSectionState();
}

class _ImageUploadSectionState extends State<ImageUploadSection> {
  bool _uploading = false;

  Future<void> _pickImage() async {
    try {
      setState(() => _uploading = true);

      // Use WebHelpers to pick image from file system
      final dataUrl = await WebHelpers.pickImageAsDataUrl();
      if (dataUrl != null) {
        // Convert data URL to bytes
        final base64Data = dataUrl.contains(',')
            ? dataUrl.split(',').last
            : dataUrl;

        final bytes = base64Decode(base64Data);
        final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.png';

        widget.onUpload(bytes, fileName);
      }

      setState(() => _uploading = false);
    } catch (e) {
      print('[ImageUpload] Error picking image: $e');
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في اختيار الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    // Clear uploaded image - parent should handle this
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2128) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final Color hintColor = isDark ? Colors.grey[400]! : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Title ──
          Row(
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'صورة مرجعية (اختياري)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ارفع صورة لتصميم مستوحى من الإنترنت',
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
            ),
          ),
          const SizedBox(height: 12),

          // ── Upload Area ──
          widget.uploadedImage != null
              ? _buildImagePreview(cardColor, textColor, hintColor)
              : _buildUploadButton(cardColor, textColor, hintColor),
        ],
      ),
    );
  }

  Widget _buildUploadButton(Color cardColor, Color textColor, Color hintColor) {
    return GestureDetector(
      onTap: _uploading ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: _uploading
            ? Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 28,
              color: hintColor,
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط لرفع صورة',
              style: TextStyle(
                fontSize: 13,
                color: hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(Color cardColor, Color textColor, Color hintColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ── Image Preview ──
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              widget.uploadedImage!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),

          // ── Image Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'صورة مرفوعة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(widget.uploadedImage!.length / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(
                    fontSize: 11,
                    color: hintColor,
                  ),
                ),
              ],
            ),
          ),

          // ── Remove Button ──
          IconButton(
            onPressed: _removeImage,
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red[400],
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}