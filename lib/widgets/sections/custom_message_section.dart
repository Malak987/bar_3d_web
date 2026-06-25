import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// 💬 Custom Message & Notes Section
///
/// Allows user to:
/// - Add custom message text to display on the cake
/// - Add special notes/instructions for the order
class CustomMessageSection extends StatelessWidget {
  final TextEditingController? messageController;
  final TextEditingController? notesController;

  const CustomMessageSection({
    super.key,
    this.messageController,
    this.notesController,
  });

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
              Icon(Icons.message_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'الرسالة والملاحظات',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Custom Message ──
          _buildTextField(
            controller: messageController,
            hintText: 'اكتب رسالتك هنا (مثال: عيد ميلاد سعيد 🎂)',
            labelText: 'رسالة مخصصة',
            icon: Icons.edit_note,
            maxLines: 2,
            cardColor: cardColor,
            textColor: textColor,
            hintColor: hintColor,
          ),
          const SizedBox(height: 12),

          // ── Notes ──
          _buildTextField(
            controller: notesController,
            hintText: 'أي ملاحظات خاصة (مثال: زيادة كريمة)',
            labelText: 'ملاحظات',
            icon: Icons.note_alt_outlined,
            maxLines: 2,
            cardColor: cardColor,
            textColor: textColor,
            hintColor: hintColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hintText,
    required String labelText,
    required IconData icon,
    int maxLines = 1,
    required Color cardColor,
    required Color textColor,
    required Color hintColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(fontSize: 14, color: textColor),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(fontSize: 12, color: hintColor),
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 13, color: hintColor.withOpacity(0.7)),
          prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}