import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// ──────────────────────────────────────────────────────
/// FlutterSplash — تصميم Minimal فخم
///
/// • اللوجو الفعلي (logo.png) في النص
/// • لودر دقيق تحته (لاين رفيع)
/// • بدون نص — أنظف وأكثر أناقة
/// • Subtle fade-in animation
/// ──────────────────────────────────────────────────────
class FlutterSplash extends StatefulWidget {
  const FlutterSplash({super.key});

  @override
  State<FlutterSplash> createState() => _FlutterSplashState();
}

class _FlutterSplashState extends State<FlutterSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logo(),
              const SizedBox(height: 28),
              _loader(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Logo ────────────────────────────────────────────
  Widget _logo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          height: 45,
          width: 45,
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.teal,
            child: const Icon(
              Icons.cake_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Minimal thin line loader ────────────────────────
  Widget _loader() {
    return SizedBox(
      width: 60,
      height: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          backgroundColor: AppColors.border.withOpacity(0.5),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
        ),
      ),
    );
  }
}
