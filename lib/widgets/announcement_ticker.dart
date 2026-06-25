import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// ──────────────────────────────────────────────────────
/// AnnouncementTicker
///
/// RTL marquee that:
///   1. slides down (250ms)
///   2. scrolls the text right→left over [scrollDuration]
///   3. slides up
///   4. repeats every [repeatInterval]
/// ──────────────────────────────────────────────────────
class AnnouncementTicker extends StatefulWidget {
  final String message;
  final Duration scrollDuration;
  final Duration repeatInterval;
  final Color backgroundColor;
  final Color accentColor;
  final double height;

  const AnnouncementTicker({
    super.key,
    required this.message,
    this.scrollDuration  = const Duration(seconds: 12),
    this.repeatInterval  = const Duration(seconds: 10),
    this.backgroundColor = AppColors.primary,
    this.accentColor     = AppColors.teal,
    this.height          = 36.0,
  });

  @override
  State<AnnouncementTicker> createState() => _AnnouncementTickerState();
}

class _AnnouncementTickerState extends State<AnnouncementTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scrollCtrl;
  late final Animation<double>   _scrollAnim;

  Timer? _hideTimer;
  Timer? _repeatTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = AnimationController(
      vsync: this,
      duration: widget.scrollDuration,
    );
    _scrollAnim = CurvedAnimation(parent: _scrollCtrl, curve: Curves.linear);
    Future.delayed(const Duration(milliseconds: 600), _show);
  }

  void _show() {
    if (!mounted) return;
    setState(() => _visible = true);
    _scrollCtrl.forward(from: 0.0);
    _hideTimer = Timer(
      widget.scrollDuration + const Duration(milliseconds: 150),
      _hide,
    );
  }

  void _hide() {
    if (!mounted) return;
    setState(() => _visible = false);
    _repeatTimer = Timer(widget.repeatInterval, _show);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _hideTimer?.cancel();
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: _visible ? widget.height : 0.0,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.backgroundColor,
            Color.lerp(widget.backgroundColor, widget.accentColor, 0.35)!,
          ],
        ),
      ),
      child: _visible ? _buildScroller() : const SizedBox.shrink(),
    );
  }

  Widget _buildScroller() {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return AnimatedBuilder(
          animation: _scrollAnim,
          builder: (context, child) {
            // 0.0 → +w   (off-screen right)
            // 0.5 → 0    (centered)
            // 1.0 → -w   (off-screen left)
            final dx = w * (1.0 - 2.0 * _scrollAnim.value);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: _buildMessageRow(),
        );
      },
    );
  }

  Widget _buildMessageRow() {
    return Center(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.report_problem,
                color: Colors.orange,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
              textDirection: TextDirection.rtl,
              softWrap: false,
            ),
            const SizedBox(width: 8),
            Container(
              width: 1.5,
              height: 14,
              color: widget.accentColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
