# Embedding BAR 3D Cake Designer

The configurator is designed to run inside Flutter Web, mobile WebView, or a normal iframe without depending on the host app's JavaScript runtime.

## iframe example

```html
<iframe
  id="cakeDesigner"
  src="https://your-host/design-cake?transferToken=...&productId=..."
  style="width:100%;height:100%;border:0"
  allow="web-share"
></iframe>

<script>
  const frame = document.getElementById('cakeDesigner');

  window.addEventListener('message', (event) => {
    const msg = event.data;
    if (!msg || msg.source !== 'bar3dcake') return;

    switch (msg.type) {
      case 'bridge-ready':
      case 'ready':
        console.log('Designer ready', msg.payload);
        break;
      case 'asset-progress':
        console.log('Loading progress', msg.payload);
        break;
      case 'customizationAdded':
        console.log('Added to cart', msg.payload);
        break;
      case 'error':
        console.warn('Designer error', msg.payload);
        break;
    }
  });

  function captureFinalImage(containerId) {
    frame.contentWindow.postMessage({
      source: 'bar-ecommerce',
      type: 'bar3dcake:captureFinalImage',
      requestId: crypto.randomUUID(),
      payload: { id: containerId }
    }, '*');
  }
</script>
```

## WebView integration notes

- Enable JavaScript.
- Enable DOM storage/localStorage if auth context is passed that way.
- Do not block `postMessage`/JavaScript bridge handlers.
- Avoid forcing hardware acceleration off; WebGL requires GPU acceleration.
- Listen to both:
  - native bridge handler `customizationAdded` when using Flutter InAppWebView style bridge
  - browser `postMessage` fallback

## Messages emitted by the designer

```json
{ "source": "bar3dcake", "type": "bridge-ready", "payload": { "revision": "160" } }
{ "source": "bar3dcake", "type": "ready", "payload": { "id": "cake-canvas-..." } }
{ "source": "bar3dcake", "type": "asset-progress", "payload": { "stage": "top-image", "progress": 0.55 } }
{ "source": "bar3dcake", "type": "error", "payload": { "code": "webgl-context-lost" } }
```

## Commands accepted by the iframe

Send messages with `type` prefixed by `bar3dcake:`:

- `bar3dcake:updateConfig`
- `bar3dcake:resetCamera`
- `bar3dcake:setQuality` with `payload.mode` = `auto`, `low`, `medium`, or `high`
- `bar3dcake:capturePreviewImage`
- `bar3dcake:captureFinalImage`
- `bar3dcake:exportCustomizationJSON`
- `bar3dcake:exportSelectedOptionsMetadata`
- `bar3dcake:exportPackage`

Example response:

```json
{
  "source": "bar3dcake",
  "type": "captureFinalImage:result",
  "requestId": "req-1",
  "payload": "data:image/png;base64,..."
}
```

## Security recommendations

For production, replace `'*'` with your known ecommerce origin where possible. Keep wildcard only when the designer must be reused across multiple controlled origins and validate incoming messages on the receiver side.
