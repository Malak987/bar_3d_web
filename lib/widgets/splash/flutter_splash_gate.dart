import 'package:flutter/cupertino.dart';
import '../../pages/cake_designer_page.dart';
import 'flutter_splash.dart';

class FlutterSplashGate extends StatefulWidget {
  const FlutterSplashGate({super.key});
  static const Duration splashDuration = Duration(seconds: 2);
  @override
  State<FlutterSplashGate> createState() => _FlutterSplashGateState();
}

class _FlutterSplashGateState extends State<FlutterSplashGate> {
  bool _showApp = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(FlutterSplashGate.splashDuration, () {
      if (mounted) setState(() => _showApp = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 850),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _showApp
          ? const KeyedSubtree(key: ValueKey('app'), child: CakeDesignerPage())
          : const KeyedSubtree(key: ValueKey('splash'), child: FlutterSplash()),
    );
  }
}
