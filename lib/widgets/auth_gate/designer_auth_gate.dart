import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/addon_options.dart';
import '../../data/cake_options.dart';
import '../../data/palette_colors.dart';
import '../../models/cake_config.dart';
import '../../services/access_detector.dart';
import '../../services/api_service.dart';
import '../../services/auth_guard.dart';
import '../../services/session_validator.dart';
import '../../services/web_helpers.dart';
import '../../pages/cake_designer_page.dart';
import 'standalone_unauthorized_page.dart';
import 'unauthorized_page.dart';

/// 🔐 DesignerAuthGate — The outermost gate for the entire application
///
/// Manages the complete startup sequence:
///
///   1. Render minimal splash (3D engine NOT loaded yet)
///   2. Classify access (WebView vs standalone browser)
///   3. Authenticate (session check → token exchange → unauthorized)
///   4. Load customization options (ONLY after auth succeeds)
///   5. Mount DesignerApp with full 3D scene
///
/// 🚫 CRITICAL: The Three.js engine and 3D scene are NEVER initialized
///    until the AuthGate reaches the `authorized` state.
class DesignerAuthGate extends StatefulWidget {
  const DesignerAuthGate({super.key});

  @override
  State<DesignerAuthGate> createState() => _DesignerAuthGateState();
}

class _DesignerAuthGateState extends State<DesignerAuthGate> {
  GateState _state = GateState.initializing;
  String _loadingMessage = 'جاري بدء المصمم...';
  double _loadingProgress = 0.0;
  CakeConfig? _loadedConfig;
  AuthSession? _authSession;
  AccessClassification? _accessClassification;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runGate());
  }

  Future<void> _runGate() async {
    if (!mounted) return;

    // ── Step 1: Access classification ──
    _setState(GateState.accessChecking, 'جاري فحص بيئة التشغيل...', 0.05);
    final access = AccessDetector.classification;
    _accessClassification = access;

    print('[AuthGate] Access: ${access.accessType.name} — ${access.reason}');
    WebHelpers.notifyFlutterBridge('LOG_EVENT', {
      'message': 'Access type: ${access.accessType.name}',
      'accessType': access.accessType.name,
    });

    // ── Step 2: Authentication ──
    if (access.isAllowed == true) {
      _setState(GateState.authenticating, 'تم التعرف عليك ✓', 0.10);
      print('[AuthGate] Access allowed (${access.accessType.name}) — proceeding');
    } else {
      _setState(GateState.authenticating, 'جاري التحقق من حسابك...', 0.10);
      print('[AuthGate] Auth check required (${access.accessType.name})');
    }

    final authResult = await ApiService.ensureAuthenticated();

    if (!mounted) return;

    if (!authResult.isAuthorized) {
      _loadingMessage = authResult.message ?? 'Authentication failed';
      _setState(GateState.unauthorized, _loadingMessage, 0.0);

      print('[AuthGate] 🚫 Authorization failed: ${authResult.message}');
      WebHelpers.notifyFlutterBridge('LOG_EVENT', {
        'message': 'Authorization failed: ${authResult.message}',
        'accessType': access.accessType.name,
      });
      return;
    }

    _authSession = authResult.session;
    _setState(GateState.authenticating, 'تم التحقق من حسابك ✓', 0.20);
    print('[AuthGate] ✅ Auth: method=${authResult.session?.authMethod}');

    // ── Step 3: Load customization options ──
    // Only loaded AFTER auth succeeds
    _setState(GateState.loadingOptions, 'جاري تحميل بيانات التصميم...', 0.30);
    print('[AuthGate] Step 3: Loading customization options');

    final ok = await ApiService.loadCustomization();

    if (!mounted) return;

    if (!ok) {
      _setState(GateState.error, 'تعذر تحميل بيانات التصميم', 0.0);
      return;
    }

    _setState(GateState.loadingOptions, 'تم تحميل التصميم ✓', 0.90);
    print('[AuthGate] ✅ Options: '
        '${baseFlavors.length}flv ${cakeSizes.length}sz '
        '${paletteColors.length}col ${pipingOptions.length}pip '
        '${addonOptions.length}add');

    // ── Step 4: Build initial config ──
    final config = _createInitialConfig();

    _setState(GateState.ready, 'المصمم جاهز ✨', 1.0);
    print('[AuthGate] ✅ Gate complete — mounting designer');

    setState(() {
      _loadedConfig = config;
      _state = GateState.ready;
    });
  }

  CakeConfig _createInitialConfig() {
    final size = cakeSizes.isNotEmpty ? cakeSizes.first : null;
    final flavor = baseFlavors.isNotEmpty ? baseFlavors.first : null;
    final piping = pipingOptions.isNotEmpty ? pipingOptions.first : null;
    final colors = paletteColors.isNotEmpty
        ? paletteColors.take(3).map((c) => c.hex).toList()
        : <String>['#f5efe2', '#fcd5ce', '#ec4f8c'];
    while (colors.length < 3) colors.add('#FFFFFF');

    return CakeConfig(
      cakeRadius: size?.radius ?? 0.78,
      cakeHeight: size?.height ?? 0.42,
      baseFlavor: flavor?.id ?? '',
      colors: colors,
      pipingType: piping?.id ?? 'openStar',
      pipingColor: colors.isNotEmpty ? colors.first : '#FFFFFF',
      pipingColors: colors,
      pipingColorCount: 1,
      gradientColorCount: 1,
      selectedAddons: const [],
      addonColors: const {},
      autoRotate: true,
      cakeScale: 1.0,
      // Required CakeConfig parameters
      pipingPlacement: 'border',
      pipingSize: 0.015,
      text: '',
      textColor: '#000000',
      textPosition: 'center',
      textSize: 0.08,
      fontStyle: 'normal',
      imageScale: 1.0,
      topImage: null,
      plateColor: '#f5efe2',
      roughness: 0.5,
      metalness: 0.0,
      clearcoat: 0.8,
      edgeTop: false,
      edgeBottom: false,
      secretMessageText: '',
    );
  }

  void _setState(GateState state, String message, double progress) {
    if (mounted) {
      setState(() {
        _state = state;
        _loadingMessage = message;
        _loadingProgress = progress;
      });
    }
  }

  void _retry() {
    print('[AuthGate] Retrying gate sequence...');
    AuthGuard.logout();
    setState(() {
      _state = GateState.initializing;
      _loadedConfig = null;
      _errorMessage = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _runGate());
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case GateState.initializing:
      case GateState.accessChecking:
      case GateState.authenticating:
      case GateState.loadingOptions:
        return _GateLoadingScreen(
          message: _loadingMessage,
          progress: _loadingProgress,
          accessClassification: _accessClassification,
        );

      case GateState.ready:
      // 🚫 3D scene ONLY created here — after auth + options loaded
        return CakeDesignerPage.fromAuthGate(
          preloadedConfig: _loadedConfig!,
          authSession: _authSession,
          accessClassification: _accessClassification,
        );

      case GateState.unauthorized:
        return _buildUnauthorizedScreen();

      case GateState.error:
        return _GateErrorScreen(
          message: _errorMessage ?? _loadingMessage,
          onRetry: _retry,
        );
    }
  }

  Widget _buildUnauthorizedScreen() {
    final isStandalone = _accessClassification?.accessType ==
        AccessType.standaloneBrowser ||
        _accessClassification?.accessType == AccessType.unknownCrossOrigin;

    if (isStandalone) {
      return StandaloneUnauthorizedPage(
        message: _loadingMessage,
        onRetry: _retry,
        accessClassification: _accessClassification,
      );
    }

    return UnauthorizedPage(
      message: _loadingMessage,
      onRetry: _retry,
      accessClassification: _accessClassification,
    );
  }
}

// ── Gate States ─────────────────────────────────────────────────────────

enum GateState {
  initializing,
  accessChecking,
  authenticating,
  loadingOptions,
  ready,
  unauthorized,
  error,
}

// ── Loading Screen ──────────────────────────────────────────────────────

class _GateLoadingScreen extends StatelessWidget {
  final String message;
  final double progress;
  final AccessClassification? accessClassification;

  const _GateLoadingScreen({
    required this.message,
    required this.progress,
    this.accessClassification,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedLogo(),
            const SizedBox(height: 28),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            if (progress > 0 && progress < 1) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.border,
                    color: AppColors.teal,
                    minHeight: 4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _PhaseIndicator(progress: progress),
            if (accessClassification != null) ...[
              const SizedBox(height: 16),
              _AccessTypeBadge(classification: accessClassification!),
            ],
            const SizedBox(height: 20),
            const _SecurityNote(),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: 45,
            height: 45,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.teal,
              child: const Icon(Icons.cake_rounded, color: Colors.white, size: 36),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final double progress;
  const _PhaseIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    final phase = progress < 0.25
        ? 'التحقق من حسابك'
        : progress < 0.55
        ? 'تم التحقق ✓'
        : progress < 0.92
        ? 'جاري تحميل التصميم...'
        : 'جاهز ✨';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
        ),
        const SizedBox(width: 8),
        Text(phase, style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AccessTypeBadge extends StatelessWidget {
  final AccessClassification classification;
  const _AccessTypeBadge({required this.classification});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;

    switch (classification.accessType) {
      case AccessType.mobileAppWebView:
        icon = Icons.phone_android;
        color = AppColors.teal;
        label = 'Mobile App';
        break;
      case AccessType.barWebEmbed:
        icon = Icons.web;
        color = AppColors.teal;
        label = 'Web Application';
        break;
      case AccessType.standaloneBrowser:
        icon = Icons.public;
        color = Colors.orange;
        label = 'Direct Browser';
        break;
      case AccessType.unknownCrossOrigin:
        icon = Icons.dns_outlined;
        color = Colors.amber;
        label = 'Embedded';
        break;
      case AccessType.unknown:
        icon = Icons.help_outline;
        color = Colors.grey;
        label = 'Unknown';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security, size: 13, color: AppColors.textLight),
          SizedBox(width: 6),
          Text(
            '3D engine will load after authentication',
            style: TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Error Screen ────────────────────────────────────────────────────────

class _GateErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _GateErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.10), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline, color: Colors.red, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}