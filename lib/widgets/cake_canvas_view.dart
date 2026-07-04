import 'dart:async';
import 'dart:math';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

import '../models/cake_config.dart';
import '../services/cake_designer_js.dart';

/// External controller exposing imperative operations
class CakeCanvasController {
  CakeCanvasViewState? _state;

  String? captureScreenshot() => _state?.captureScreenshot();
  String? capturePreviewImage() => _state?.capturePreviewImage();
  String? captureFinalImage() => _state?.captureFinalImage();
  String exportCustomizationJSON() => _state?.exportCustomizationJSON() ?? '{}';
  String exportSelectedOptionsMetadata(Map<String, dynamic> extra) =>
      _state?.exportSelectedOptionsMetadata(extra) ?? '{}';
  String exportPackage(Map<String, dynamic> extra) => _state?.exportPackage(extra) ?? '{}';
  void setQuality(String mode) => _state?.setQuality(mode);
  void resetCamera() => _state?.resetCamera();
}

/// ──────────────────────────────────────────────────────
/// CakeCanvasView — Flutter wrapper around the JS scene
/// ──────────────────────────────────────────────────────
class CakeCanvasView extends StatefulWidget {
  final CakeConfig config;
  final CakeCanvasController controller;

  const CakeCanvasView({
    super.key,
    required this.config,
    required this.controller,
  });

  @override
  State<CakeCanvasView> createState() => CakeCanvasViewState();
}

class CakeCanvasViewState extends State<CakeCanvasView> {
  late final String _containerId;
  late final String _viewType;

  bool _mounted = false;
  bool _isMounting = false;
  Timer? _debounce;
  StreamSubscription<html.MessageEvent>? _messageSub;
  double _loadProgress = 0.08;
  String _loadingMessage = 'جاري تجهيز المعاينة...';
  String? _mountError;
  Timer? _readyFallbackTimer;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;

    final seed =
        DateTime.now().microsecondsSinceEpoch + Random().nextInt(999999);
    _containerId = 'cake-canvas-$seed';
    _viewType = 'cake-view-$seed';

    _messageSub = html.window.onMessage.listen(_handleHostMessage);

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      // ★ الحاوية الخارجية — تضمن مساحة كاملة بدون أي قص
      final div = html.DivElement()
        ..id = _containerId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.background = '#1a1f2e'
        ..style.boxSizing = 'border-box'
        ..style.margin = '0'
        ..style.padding = '0'
        ..style.display = 'block';
      return div;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _mountScene());
  }

  @override
  void didUpdateWidget(covariant CakeCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mounted || oldWidget.config == widget.config) return;

    // Debounce updates so slider drags don't flood the JS bridge.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 30), () {
      if (mounted && _mounted) {
        CakeDesignerJs.updateConfig(_containerId, widget.config);
      }
    });
  }

  Future<void> _mountScene() async {
    if (_isMounting || !mounted) return;
    _isMounting = true;
    setState(() {
      _mountError = null;
      _loadProgress = 0.08;
      _loadingMessage = 'جاري تحميل محرك العرض...';
    });

    // Fast poll: wait up to 5s (50 × 100ms) for the JS bridge.
    for (int i = 0; i < 50; i++) {
      if (!mounted) { _isMounting = false; return; }
      if (CakeDesignerJs.isReady) break;
      if (i % 5 == 0 && mounted) {
        setState(() => _loadProgress = (0.08 + i / 80).clamp(0.08, 0.62).toDouble());
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted || !CakeDesignerJs.isReady) {
      _isMounting = false;
      if (mounted) {
        setState(() {
          _mountError = 'تعذر تحميل محرك التصميم ثلاثي الأبعاد';
          _loadingMessage = 'حدث خطأ في التحميل';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loadProgress = 0.72;
        _loadingMessage = 'جاري بناء التصميم...';
      });
    }
    // Minimal delay so the loading UI paints before heavy mount work
    await Future.delayed(const Duration(milliseconds: 40));
    if (!mounted) { _isMounting = false; return; }

    CakeDesignerJs.mount(_containerId, widget.config);
    if (mounted) {
      setState(() {
        _mounted = true;
        _loadProgress = 1;
        _loadingMessage = 'تم التحميل';
      });
    }
    _isMounting = false;
  }

  void _handleHostMessage(html.MessageEvent event) {
    if (!mounted) return;
    try {
      final data = event.data;
      final source = _readMessageValue(data, 'source');
      if (source != 'bar3dcake') return;

      final type = _readMessageValue(data, 'type')?.toString();
      final payload = _readMessageValue(data, 'payload');
      if (type == 'ready') {
        final id = _readMessageValue(payload, 'id')?.toString();
        if (id == _containerId) {
          _readyFallbackTimer?.cancel();
          setState(() {
            _mounted = true;
            _mountError = null;
            _loadProgress = 1;
            _loadingMessage = 'تم التحميل';
          });
        }
      } else if (type == 'bridge-ready') {
        setState(() {
          _loadProgress = _loadProgress < 0.45 ? 0.45 : _loadProgress;
          _loadingMessage = 'تم تحميل محرك العرض...';
        });
      } else if (type == 'asset-progress') {
        final progress = _readMessageValue(payload, 'progress');
        setState(() {
          if (progress is num) {
            _loadProgress = progress.toDouble().clamp(0.0, 1.0).toDouble();
          }
          _loadingMessage = 'جاري تحميل عناصر التصميم...';
        });
      } else if (type == 'error') {
        final code = _readMessageValue(payload, 'code')?.toString() ?? '';
        final fatal = code == 'mount-failed' ||
            code == 'container-not-found' ||
            code == 'apply-config-failed' ||
            code == 'webgl-context-lost' ||
            code == 'webgl-not-supported';
        if (fatal && !_mounted) {
          final msg = code == 'webgl-not-supported' || code == 'webgl-context-lost'
              ? 'جهازك لا يدعم العرض ثلاثي الأبعاد — جرّب متصفح أحدث أو جهاز آخر'
              : 'حدث خطأ في المعاينة، يمكنك إعادة المحاولة';
          setState(() => _mountError = msg);
        }
      }
    } catch (_) {}
  }

  Object? _readMessageValue(Object? data, String key) {
    if (data == null) return null;
    if (data is Map) return data[key];
    try {
      return (data as dynamic)[key];
    } catch (_) {
      return null;
    }
  }

  String? captureScreenshot() {
    if (!_mounted) return null;
    return CakeDesignerJs.captureScreenshot(_containerId);
  }

  String? capturePreviewImage() {
    if (!_mounted) return null;
    return CakeDesignerJs.capturePreviewImage(_containerId);
  }

  String? captureFinalImage() {
    if (!_mounted) return null;
    return CakeDesignerJs.captureFinalImage(_containerId);
  }

  String exportCustomizationJSON() {
    if (!_mounted) return '{}';
    return CakeDesignerJs.exportCustomizationJSON(_containerId);
  }

  String exportSelectedOptionsMetadata(Map<String, dynamic> extra) {
    if (!_mounted) return '{}';
    return CakeDesignerJs.exportSelectedOptionsMetadata(_containerId, extra);
  }

  String exportPackage(Map<String, dynamic> extra) {
    if (!_mounted) return '{}';
    return CakeDesignerJs.exportPackage(_containerId, extra);
  }

  void setQuality(String mode) {
    if (!_mounted) return;
    CakeDesignerJs.setQuality(_containerId, mode);
  }

  void resetCamera() {
    if (!_mounted) return;
    CakeDesignerJs.resetCamera(_containerId);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _readyFallbackTimer?.cancel();
    _messageSub?.cancel();
    CakeDesignerJs.dispose(_containerId);
    if (widget.controller._state == this) widget.controller._state = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ★ SizedBox.expand يضمن إن الـ widget يأخذ كل المساحة المتاحة دون
    // أي قيود من parents (Stack/Column/...)
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFFE8F0F0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // RepaintBoundary prevents Flutter from re-painting the canvas
            // every time controls rebuild — Three.js draws into its own DOM.
            Positioned.fill(
              child: RepaintBoundary(
                child: HtmlElementView(viewType: _viewType),
              ),
            ),
            if (!_mounted || _mountError != null)
              _LoadingOverlay(
                progress: _loadProgress,
                message: _loadingMessage,
                error: _mountError,
                onRetry: () {
                  CakeDesignerJs.dispose(_containerId);
                  setState(() {
                    _mounted = false;
                    _mountError = null;
                    _loadProgress = 0.08;
                  });
                  _mountScene();
                },
              ),
            if (_mounted)
              const Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Center(child: _HintBar()),
              ),
          ],
        ),
      ),
    );
  }
}

// ── private widgets ─────────────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  final double progress;
  final String message;
  final String? error;
  final VoidCallback onRetry;

  const _LoadingOverlay({
    required this.progress,
    required this.message,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Positioned.fill(
      child: Container(
        color: const Color(0xFFE8F0F0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasError)
                  const Icon(Icons.refresh_rounded, color: Color(0xFF008080), size: 42)
                else
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      value: progress <= 0 || progress >= 1 ? null : progress,
                      color: const Color(0xFF008080),
                      strokeWidth: 3,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  hasError ? error! : message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w700),
                ),
                if (!hasError) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0).toDouble(),
                      minHeight: 5,
                      color: const Color(0xFF008080),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
                if (hasError) ...[
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080)),
                    child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  const _HintBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: const Text(
        'اسحب للتدوير • قرّب أو بعّد للتكبير والتصغير',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
      ),
    );
  }
}
