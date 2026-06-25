import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/cake_config.dart';

import 'common/section.dart';
import 'sections/size_section.dart';
import 'sections/base_flavor_section.dart';
import 'sections/cake_colors_section.dart';
import 'sections/piping_style_section.dart';
import 'sections/piping_colors_section.dart';
import 'sections/piping_shapes_section.dart';
import 'sections/photo_section.dart';
import 'sections/text_section.dart';
import 'sections/camera_section.dart';
import 'sections/addons_section.dart';

/// ──────────────────────────────────────────────────────
/// ControlsPanel
///
/// Right-side scrollable list of all editor sections.
/// Each section is a self-contained widget — to add or
/// reorder one, simply edit the list below.
/// ──────────────────────────────────────────────────────
class ControlsPanel extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;
  final VoidCallback onResetCamera;
  final bool isMobile;

  const ControlsPanel({
    super.key,
    required this.config,
    required this.onChanged,
    required this.onResetCamera,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      SizeSection        (config: config, onChanged: onChanged),
      BaseFlavorSection  (config: config, onChanged: onChanged),
      CakeColorsSection  (config: config, onChanged: onChanged),
      PipingStyleSection (config: config, onChanged: onChanged),
      PipingColorsSection(config: config, onChanged: onChanged),
      PipingShapesSection(config: config, onChanged: onChanged),
      PhotoSection       (config: config, onChanged: onChanged),
      TextSection        (config: config, onChanged: onChanged),
      AddonsSection      (config: config, onChanged: onChanged),
      CameraSection(
        config: config,
        onChanged: onChanged,
        onResetCamera: onResetCamera,
      ),
    ];

    // Interleave each section with a divider
    final children = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      children.add(sections[i]);
      if (i < sections.length - 1) children.add(const SectionDivider());
    }
    children.add(const SizedBox(height: 16));

    return Container(
      color: AppColors.bg,
      child: ListView(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 8,
          bottom: isMobile ? 8 : 20,
        ),
        children: children,
      ),
    );
  }
}
