import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/access_detector.dart';

/// 🔐 Unauthorized Page — Shown when access path is known (WebView/iframe)
/// but no valid authentication session exists.
///
/// This is for cases where the user has opened the designer through
/// an allowed channel (mobile app / BAR web app) but the session
/// has expired or the transfer token is invalid.
class UnauthorizedPage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AccessClassification? accessClassification;

  const UnauthorizedPage({
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
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Icon ──
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_off_outlined,
                    color: Colors.amber,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Main message ──
                Text(
                  message.isNotEmpty
                      ? message
                      : 'انتهت صلاحية جلستك',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Explanation ──
                const Text(
                  'جلستك في المصمم قد انتهت صلاحيتها.\n'
                  'يرجى إعادة فتح المصمم من التطبيق.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Security badge ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.teal.withOpacity(0.20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.security, color: AppColors.teal.withOpacity(0.8), size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Session Protected',
                        style: TextStyle(
                          color: AppColors.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Access info ──
                if (accessClassification != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          accessClassification!.accessType == AccessType.mobileAppWebView
                              ? Icons.phone_android
                              : Icons.web,
                          size: 14,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AccessDetector.accessDescription,
                          style: const TextStyle(
                            color: AppColors.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}