import 'package:flutter/cupertino.dart';
import '../../pages/cake_designer_page.dart';
import 'flutter_splash.dart';

/// Entry point gate — no artificial delay, goes straight to designer.
///
/// The CakeDesignerPage handles its own loading states:
///   1. Auth loading screen (3D scene blocked)
///   2. Unauthorized screen (auth failed)
///   3. Designer ready (auth succeeded)
///
/// The 2-second splash delay was removed because:
///   - It delays auth validation unnecessarily
///   - The page has its own loading UX with progress indicators
///   - Users on slow connections see a blank screen instead of progress
class FlutterSplashGate extends StatefulWidget {
  const FlutterSplashGate({super.key});

  @override
  State<FlutterSplashGate> createState() => _FlutterSplashGateState();
}

class _FlutterSplashGateState extends State<FlutterSplashGate> {
  bool _showApp = false;

  @override
  void initState() {
    super.initState();
    // No artificial delay — auth validation starts immediately.
    // The page will show a progress indicator during auth.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showApp = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showApp
          ? const KeyedSubtree(
              key: ValueKey('app'),
              child: CakeDesignerPage(),
            )
          : const KeyedSubtree(
              key: ValueKey('splash'),
              child: FlutterSplash(),
            ),
    );
  }
}