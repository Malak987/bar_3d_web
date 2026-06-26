import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/access_detector.dart';

/// 🔐 Standalone Unauthorized Page — Shown when designer is accessed
/// directly from a browser without valid authentication.
///
/// This is the FULL unauthorized experience for direct browser access.
/// The user sees clear messaging that this is an internal module
/// that must be accessed through the BAR application.
class StandaloneUnauthorizedPage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AccessClassification? accessClassification;

  const StandaloneUnauthorizedPage({
    super.key,
    required this.message,
    required this.onRetry,
    this.accessClassification,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Large icon ──
                _LargeIcon(),
                const SizedBox(height: 28),

                // ── Main title ──
                const Text(
                  'المصمم متاح داخل تطبيق BAR فقط',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Explanation ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [AppColors.cardShadow],
                  ),
                  child: Column(
                    children: [
                      _ExplanationRow(
                        icon: Icons.phone_android,
                        color: AppColors.teal,
                        text: 'افتح المصمم من تطبيق BAR على جوالك',
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _ExplanationRow(
                        icon: Icons.web,
                        color: AppColors.teal,
                        text: 'أو من خلال الموقع الرسمي لـ BAR على الويب',
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      _ExplanationRow(
                        icon: Icons.lock_outline,
                        color: Colors.orange,
                        text: 'الرابط الحالي لا يعمل من المتصفح مباشرة',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Error message ──
                if (message.isNotEmpty &&
                    !message.contains('يلزم') &&
                    !message.contains('تسجيل الدخول'))
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Security notice ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 18, color: AppColors.textLight),
                          SizedBox(width: 8),
                          Text(
                            'حماية的安全性 Security',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _SecurityPoint(
                        text: 'المصمم يعمل داخل تطبيق مشفر — لا يمكن فتحه مباشرة',
                      ),
                      const SizedBox(height: 6),
                      _SecurityPoint(
                        text: 'كل رابط دخول يعمل لمرة واحدة فقط',
                      ),
                      const SizedBox(height: 6),
                      _SecurityPoint(
                        text: 'جلستك تنتهي تلقائياً بعد فترة محددة',
                      ),
                      const SizedBox(height: 6),
                      _SecurityPoint(
                        text: 'لا يتم تحميل بيانات التصميم إلا بعد المصادقة',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Access type indicator ──
                if (accessClassification != null) ...[
                  _AccessInfoRow(classification: accessClassification!),
                  const SizedBox(height: 20),
                ],

                // ── Retry button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Help text ──
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.help_outline, color: AppColors.textLight, size: 20),
                      SizedBox(height: 8),
                      Text(
                        'إذا وصلت إلى هذه الصفحة من تطبيق BAR، '
                        'يرجى التأكد من تحديث التطبيق إلى آخر إصدار.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.lock_outline, color: AppColors.primary, size: 48),
          Positioned(
            right: 16,
            bottom: 16,
            child: Icon(Icons.block, color: Colors.red, size: 24),
          ),
        ],
      ),
    );
  }
}

class _ExplanationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ExplanationRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color == Colors.orange ? Colors.orange.shade700 : AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityPoint extends StatelessWidget {
  final String text;
  const _SecurityPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 14, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccessInfoRow extends StatelessWidget {
  final AccessClassification classification;

  const _AccessInfoRow({required this.classification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_outlined, size: 15, color: AppColors.textLight),
          const SizedBox(width: 8),
          Text(
            'Access: ${AccessDetector.accessDescription}',
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '•',
            style: TextStyle(color: Colors.orange.shade300),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              classification.reason,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}