import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/cake_config.dart';
import '../announcement_ticker.dart';
import '../cake_canvas_view.dart';
import '../controls_panel.dart';
import 'bottom_bar.dart';
import 'pickup_info.dart';
import 'preview_badge.dart';

class MainMobileLayout extends StatelessWidget {
  final CakeConfig config;
  final CakeCanvasController canvasController;
  final ValueChanged<CakeConfig> onChanged;
  final VoidCallback onDownload;
  final VoidCallback? onPickup;
  final PickupInfo? pickupInfo;

  const MainMobileLayout({
    super.key,
    required this.config,
    required this.canvasController,
    required this.onChanged,
    required this.onDownload,
    this.onPickup,
    this.pickupInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const AnnouncementTicker(
        message: 'هذا الشكل واقعى بنسبه 70%',
        scrollDuration: Duration(seconds: 10),
        repeatInterval: Duration(seconds: 10),
      ),
      _canvasArea(),
      _divider(),
      Expanded(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ControlsPanel(config: config, onChanged: onChanged, onResetCamera: canvasController.resetCamera, isMobile: true),
        ),
      ),
      Directionality(
        textDirection: TextDirection.ltr,
        child: BottomBar(onDownload: onDownload, onPickup: onPickup, pickupInfo: pickupInfo),
      ),
    ]);
  }

  Widget _canvasArea() => LayoutBuilder(
    builder: (context, constraints) {
      final screenH = MediaQuery.of(context).size.height;
      final screenW = MediaQuery.of(context).size.width;
      final isTablet = screenW >= 600;

      // Responsive canvas height
      double canvasH;
      if (isTablet) {
        canvasH = (screenH * 0.40).clamp(280.0, 450.0);
      } else if (screenH < 600) {
        canvasH = (screenH * 0.35).clamp(180.0, 240.0);
      } else if (screenH < 750) {
        canvasH = (screenH * 0.38).clamp(240.0, 300.0);
      } else {
        canvasH = (screenH * 0.40).clamp(280.0, 380.0);
      }

      return Container(
        decoration: const BoxDecoration(color: AppColors.bg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, spreadRadius: 4, offset: const Offset(0, 14))],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            child: SizedBox(height: canvasH, width: double.infinity, child: Stack(children: [
              Positioned.fill(child: CakeCanvasView(config: config, controller: canvasController)),
              const Positioned(top: 18, right: 18, child: PremiumPreviewBadge()),
            ])),
          ),
        ),
      );
    },
  );

  Widget _divider() => Container(
    height: 18, width: double.infinity,
    decoration: const BoxDecoration(color: AppColors.bg, border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.2))),
  );
}
