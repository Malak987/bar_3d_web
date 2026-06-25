# BAR 3D Cake Designer — Flutter Web + Three.js

Professional 3D cake customization module for ecommerce, built with **Flutter Web** UI and a high-performance **vanilla Three.js** renderer embedded through `HtmlElementView`.

> The project keeps the existing customization flow, API payloads, Cubits and business logic intact. Production optimizations are implemented around rendering, exports, embedding and hosting.

---

## Architecture

```text
Flutter Web
  ├─ Wizard / Controls / Review UI
  ├─ Existing API services + business payloads
  ├─ CakeCanvasView
  │   └─ HtmlElementView container
  └─ JS interop service
        ↕
window.cakeDesigner
  ├─ Three.js scene
  ├─ Diff-based cake subsystem rebuilds
  ├─ Geometry/material pools
  ├─ Invalidation-driven render loop
  └─ Export / postMessage APIs
```

Key renderer files:

```text
web/js/cake_designer.js
web/js/core/cake_designer_instance.js
web/js/core/scene.js
web/js/core/orbit_controls.js
web/js/utils/performance.js
web/js/utils/disposal.js
web/js/builders/*
web/js/addons/*
```

Three.js is vendored locally:

```text
web/js/vendor/three.min.js
```

No CDN is required at runtime.

---

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

---

## Production checks

Run the project-level validation helper before release:

```bash
./scripts/production_check.sh
```

Extra docs:

- `docs/EMBEDDING.md` — iframe/WebView integration examples.
- `docs/PRODUCTION_CHECKLIST.md` — release checklist.
- `PRODUCTION_OPTIMIZATION.md` — summary of optimization work.

## Production builds

Preferred when supported:

```bash
flutter build web --release --wasm
```

Fallback:

```bash
flutter build web --release --web-renderer canvaskit
```

Deploy output:

```text
build/web
```

Firebase hosting is configured in `firebase.json` with:

- SPA rewrite to `index.html`
- long-cache headers for immutable JS/assets
- no-cache for `index.html` and `flutter_bootstrap.js`
- safe security headers that do not block iframe/WebView embedding

Deploy example:

```bash
firebase deploy --only hosting
```

---

## Renderer performance features

- Diff-based rebuilds: only the affected cake subsystem is rebuilt.
- Invalidation-driven render loop: no continuous RAF while idle.
- Adaptive quality profile for mobile/low-memory devices.
- Lower DPR/shadow/texture sizes on weaker devices.
- Geometry and material pooling.
- Safe disposal of textures/materials/geometries.
- Instanced meshes for repeated piping and decorations.
- Merged pedestal geometry to reduce draw calls.
- Frustum culling enabled for generated meshes.
- Lazy/non-blocking glow texture loading.
- WebGL context lost/restored handling.

---

## Flutter export API

Use `CakeCanvasController`:

```dart
final image = canvasController.captureScreenshot();
final preview = canvasController.capturePreviewImage();
final finalRender = canvasController.captureFinalImage();

final designJson = canvasController.exportCustomizationJSON();
final metadata = canvasController.exportSelectedOptionsMetadata({
  'finalPrice': totalPrice,
});
final fullPackage = canvasController.exportPackage({
  'finalPrice': totalPrice,
});
```

The existing Add-To-Cart flow now exports preview/final images and returns additive metadata while preserving old fields.

---

## JavaScript public API

After the bridge is ready:

```js
window.cakeDesigner.mount(containerId, config)
window.cakeDesigner.updateConfig(containerId, config)
window.cakeDesigner.resetCamera(containerId)
window.cakeDesigner.setQuality(containerId, 'auto' | 'low' | 'medium' | 'high')
window.cakeDesigner.captureScreenshot(containerId, options)
window.cakeDesigner.capturePreviewImage(containerId)
window.cakeDesigner.captureFinalImage(containerId)
window.cakeDesigner.exportCustomizationJSON(containerId)
window.cakeDesigner.exportSelectedOptionsMetadata(containerId, extra)
window.cakeDesigner.exportPackage(containerId, extra)
window.cakeDesigner.dispose(containerId)
```

Example capture options:

```js
window.cakeDesigner.captureScreenshot(id, {
  width: 1600,
  height: 1600,
  type: 'image/png',
  quality: 0.92
})
```

---

## postMessage embedding API

The module can run inside:

- Flutter Web
- WebView
- iframe

Host apps can listen for renderer messages:

```js
window.addEventListener('message', (event) => {
  const msg = event.data;
  if (msg?.source !== 'bar3dcake') return;
  console.log(msg.type, msg.payload);
});
```

Common events:

```text
bridge-ready
ready
asset-progress
error
```

Host apps can also send commands:

```js
iframe.contentWindow.postMessage({
  source: 'bar-ecommerce',
  type: 'bar3dcake:captureFinalImage',
  requestId: 'req-1',
  payload: { id: 'cake-canvas-...' }
}, '*');
```

The iframe replies with:

```js
{
  source: 'bar3dcake',
  type: 'captureFinalImage:result',
  requestId: 'req-1',
  payload: 'data:image/png;base64,...'
}
```

---

## Optional REST integration helper

`lib/services/cake_customization_export_service.dart` provides generic methods for host/backend integrations without modifying the existing API logic:

```dart
uploadFinalImage(...)
uploadPreviewImage(...)
uploadDesignJson(...)
uploadCustomizationMetadata(...)
createCustomization(...) // returns customization ID when present
```

---

## Production notes

- Keep `web/js/vendor/three.min.js` version aligned with renderer compatibility.
- Enable gzip/brotli at the hosting/CDN layer.
- Avoid `X-Frame-Options: DENY/SAMEORIGIN` if the module must be embedded in an iframe.
- Be careful with COOP/COEP headers: they can improve advanced Wasm/shared-memory scenarios but may break ecommerce embedding depending on origin setup.
- Run `flutter analyze` and device testing on Chrome, Safari iOS, Android WebView and desktop before release.

---

## Important constraint

Do not rewrite or bypass existing:

- API service logic
- Cubits
- backend payload models
- customization flow

Optimizations should remain additive and compatible.
