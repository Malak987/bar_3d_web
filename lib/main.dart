import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/app_colors.dart';
import 'widgets/auth_gate/designer_auth_gate.dart';

void main() {
  runApp(const CakeDesignerApp());
}

class CakeDesignerApp extends StatelessWidget {
  const CakeDesignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Design Cake - BAR',
      theme: _buildTheme(),
      builder: (context, child) => _buildResponsiveShell(context, child),
      home: const Directionality(
        textDirection: TextDirection.ltr,
        child: DesignerAuthGate(),
      ),
    );
  }

  ThemeData _buildTheme() => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bg,
    useMaterial3: true,
    fontFamily: 'sans-serif',
  );

  Widget _buildResponsiveShell(BuildContext context, Widget? child) {
    return ResponsiveBreakpoints.builder(
      breakpoints: [
        const Breakpoint(start: 0, end: 599, name: MOBILE),
        const Breakpoint(start: 600, end: 979, name: TABLET),
        const Breakpoint(start: 980, end: double.infinity, name: DESKTOP),
      ],
      // No Center/ResponsiveScaledBox on mobile: the designer is an embedded
      // full-screen module and must fill the WebView/iframe exactly.
      child: child ?? const SizedBox.shrink(),
    );
  }
}
