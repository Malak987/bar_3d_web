# Production checklist

## Before build

- [ ] Confirm backend base URL and auth transfer flow are correct for production.
- [ ] Run `flutter pub get`.
- [ ] Run `flutter analyze`.
- [ ] Run `./scripts/production_check.sh`.
- [ ] Test with a realistic product/catalog dataset.
- [ ] Test add-to-cart with final rendered image upload.

## Rendering tests

- [ ] Chrome desktop mid-range laptop.
- [ ] Safari iOS.
- [ ] Android Chrome.
- [ ] Android WebView inside the ecommerce app.
- [ ] iframe embedding inside the ecommerce web app.
- [ ] Long session test: customize repeatedly for 10+ minutes and verify memory does not grow continuously.
- [ ] WebGL context loss recovery test where possible.

## Export tests

- [ ] Preview image generated at review step.
- [ ] Final image generated at add-to-cart step.
- [ ] `customizationJson` is returned in host payload.
- [ ] `customizationMetadata` is returned in host payload.
- [ ] Final calculated price is present.
- [ ] Existing legacy fields are still present.

## Hosting tests

- [ ] `index.html` is not cached.
- [ ] `flutter_bootstrap.js`, `flutter.js`, `main.dart.js` are not stale after deploy.
- [ ] `web/js/**`, `assets/**`, `icons/**` cache correctly.
- [ ] gzip/brotli enabled at CDN/hosting layer.
- [ ] iframe embedding is not blocked by headers.

## Build commands

Preferred:

```bash
flutter build web --release --wasm
```

Fallback:

```bash
flutter build web --release --web-renderer canvaskit
```

Deploy Firebase:

```bash
firebase deploy --only hosting
```
