# Production optimization notes

This project was optimized without rewriting the customization flow and without changing the existing API logic or Cubits.

## Rendering

- Diff-based rebuilds are preserved.
- Three.js rendering is invalidation-driven, so the RAF loop stops while idle.
- Adaptive quality profile lowers DPR, shadows, texture size and light count on mobile/low-memory devices.
- Geometry/material pools are preserved and disposed safely.
- Top text/photo texture is adaptive and lazily finalized.
- Frustum culling is enabled on generated meshes/instanced meshes.
- Renderer uses `powerPreference: high-performance` and releases WebGL context on dispose.
- IntersectionObserver pauses rendering while the canvas is off-screen.
- Runtime quality can be forced with `setQuality(auto|low|medium|high)`, and auto mode can degrade DPR after repeated slow frames.

## Export API

Available from Flutter via `CakeCanvasController`:

- `captureScreenshot()`
- `capturePreviewImage()`
- `captureFinalImage()`
- `exportCustomizationJSON()`
- `exportSelectedOptionsMetadata(extra)`
- `exportPackage(extra)`

Available from JS/host:

- `window.cakeDesigner.capturePreviewImage(id)`
- `window.cakeDesigner.captureFinalImage(id)`
- `window.cakeDesigner.exportCustomizationJSON(id)`
- `window.cakeDesigner.exportSelectedOptionsMetadata(id, extra)`
- `window.cakeDesigner.exportPackage(id, extra)`

## Host embedding

The renderer posts messages with this shape:

```json
{ "source": "bar3dcake", "type": "ready", "payload": {} }
```

This works in Flutter Web, WebView and iframe parents using `postMessage`.

## Optional REST upload integration

Use `CakeCustomizationExportService` for optional host/backend integrations. It exposes:

- `uploadFinalImage(...)`
- `uploadPreviewImage(...)`
- `uploadDesignJson(...)`
- `uploadCustomizationMetadata(...)`
- `createCustomization(...)` returning the generated customization ID when the backend response includes one.

Existing backend/API service code was not modified.

## Responsive UI

The wizard now adapts by width:

- Mobile: compact vertical flow with preview above controls.
- Tablet: taller preview and wider padding.
- Desktop: large configurator canvas beside a fixed-width control/review panel.

`CakeConfig` now has value equality, so Flutter avoids sending duplicated config updates to the JS bridge during parent rebuilds.

## Bundle/startup

- Three.js is vendored locally at `web/js/vendor/three.min.js`, so the configurator does not depend on a CDN inside WebView/iframe.
- Critical scripts are preloaded in `web/index.html`.
- The canvas overlay now shows loading progress, a retry state, and WebGL error recovery messaging.
- Unused build-time packages were moved from `dependencies` to `dev_dependencies` (`device_preview`, `flutter_launcher_icons`) to keep production dependency resolution cleaner.

## Flutter Web production build

Recommended builds:

```bash
flutter build web --release --wasm
```

Fallback when a dependency/browser does not support Wasm:

```bash
flutter build web --release --web-renderer canvaskit
```

For smaller startup on normal ecommerce embedding, prefer release builds, gzip/brotli on the hosting server, and long-cache static JS/assets with content hashes.
