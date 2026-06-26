// ─────────────────────────────────────────────────────────────────────────
// 🔐 Auth Gate — Barrel Export
// ─────────────────────────────────────────────────────────────────────────
//
// This file re-exports all auth gate components for convenient imports.
//
// Primary export:
//   - DesignerAuthGate  — The outermost gate for the entire application
//     ├── Access classification (WebView vs standalone browser)
//     ├── Authentication (session check → token exchange)
//     ├── Loading options (ONLY after auth succeeds)
//     └── Mount designer (3D scene created only after auth)
//
// Secondary exports:
//   - AuthGate — Individual auth error screens (legacy)
//   - StandaloneUnauthorizedPage — Direct browser unauthorized screen
//   - UnauthorizedPage — WebView/iframe unauthorized screen
//
// Usage:
//   import 'package:bar_3d_web/widgets/auth_gate.dart';
//   import 'package:bar_3d_web/widgets/auth_gate/designer_auth_gate.dart'; // for type access
//
// ─────────────────────────────────────────────────────────────────────────

export 'auth_gate/designer_auth_gate.dart';
export 'auth_gate/standalone_unauthorized_page.dart';
export 'auth_gate/unauthorized_page.dart';