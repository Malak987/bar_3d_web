/** cake_designer.js — Public API (window.cakeDesigner). */
(function (root) {
  'use strict';

  if (typeof THREE === 'undefined') {
    console.error('[CakeDesigner] THREE.js is not loaded!');
    return;
  }

  const instances = new Map();
  const C = root.CD;

  function withContainer(id, callback, attempt) {
    attempt = attempt || 0;
    const el = document.getElementById(id);
    if (!el) {
      if (attempt < 50) return setTimeout(() => withContainer(id, callback, attempt + 1), 100);
      C.Perf && C.Perf.post('error', { code: 'container-not-found', id });
      return;
    }
    if ((el.clientWidth < 10 || el.clientHeight < 10) && attempt < 50) {
      return setTimeout(() => withContainer(id, callback, attempt + 1), 100);
    }
    callback(el);
  }

  function inst(id) { return instances.get(id) || null; }
  function safe(id, op, fallback) {
    try { const x = inst(id); return x ? op(x) : fallback; }
    catch (e) { console.warn('[CakeDesigner] API call failed', e); C.Perf && C.Perf.post('error', { code: 'api-call-failed', message: String(e) }); return fallback; }
  }

  root.cakeDesigner = {
    mount(id, config) {
      if (instances.has(id)) { instances.get(id).updateConfig(config); return; }
      withContainer(id, (el) => {
        if (instances.has(id)) { instances.get(id).updateConfig(config); return; }
        try { instances.set(id, new C.Instance(el, config || {})); }
        catch (e) { console.error('[CakeDesigner] mount failed', e); C.Perf && C.Perf.post('error', { code: 'mount-failed', message: String(e) }); }
      });
    },
    updateConfig(id, config) { return safe(id, (x) => x.updateConfig(config)); },
    resetCamera(id) { return safe(id, (x) => x.resetCamera()); },
    setQuality(id, mode) { return safe(id, (x) => x.setQuality(mode || 'auto')); },
    captureScreenshot(id, options) { return safe(id, (x) => x.captureScreenshot(options || {}), null); },
    capturePreviewImage(id) { return safe(id, (x) => x.capturePreviewImage(), null); },
    captureFinalImage(id) { return safe(id, (x) => x.captureFinalImage(), null); },
    exportCustomizationJSON(id) { return safe(id, (x) => x.exportCustomizationJSON(), '{}'); },
    exportSelectedOptionsMetadata(id, extra) { return safe(id, (x) => x.exportSelectedOptionsMetadata(extra || {}), '{}'); },
    exportPackage(id, extra) { return safe(id, (x) => x.exportPackage(extra || {}), '{}'); },
    getStats(id) { return safe(id, (x) => x.getStats(), {}); },
    dispose(id) {
      const x = instances.get(id);
      if (!x) return;
      x.dispose();
      instances.delete(id);
    },
    disposeAll() {
      for (const [id, x] of instances) { try { x.dispose(); } catch (_) {} instances.delete(id); }
    },
  };

  // Host apps (iframe/WebView) can drive the module through postMessage without
  // reaching into the iframe DOM. Example:
  // { source:'bar-ecommerce', type:'bar3dcake:captureFinalImage', payload:{ id:'cake-canvas-...' } }
  root.addEventListener('message', function (event) {
    const data = event.data || {};
    if (!data || typeof data.type !== 'string' || data.type.indexOf('bar3dcake:') !== 0) return;
    const payload = data.payload || {};
    const id = payload.id;
    const type = data.type.replace('bar3dcake:', '');
    let result = null;
    if (type === 'updateConfig') result = root.cakeDesigner.updateConfig(id, payload.config || {});
    else if (type === 'resetCamera') result = root.cakeDesigner.resetCamera(id);
    else if (type === 'setQuality') result = root.cakeDesigner.setQuality(id, payload.mode || 'auto');
    else if (type === 'capturePreviewImage') result = root.cakeDesigner.capturePreviewImage(id);
    else if (type === 'captureFinalImage') result = root.cakeDesigner.captureFinalImage(id);
    else if (type === 'exportCustomizationJSON') result = root.cakeDesigner.exportCustomizationJSON(id);
    else if (type === 'exportSelectedOptionsMetadata') result = root.cakeDesigner.exportSelectedOptionsMetadata(id, payload.extra || {});
    else if (type === 'exportPackage') result = root.cakeDesigner.exportPackage(id, payload.extra || {});
    else return;
    try { event.source && event.source.postMessage({ source: 'bar3dcake', type: type + ':result', requestId: data.requestId, payload: result }, event.origin || '*'); } catch (_) {}
  });

  C.Perf && C.Perf.post('bridge-ready', { revision: THREE.REVISION });
})(window);
