/** marble_texture.js — cached procedural marble, adaptive resolution. */
(function (root) {
  'use strict';

  const _cache = new Map();

  function createMarbleTexture(profile) {
    profile = profile || (root.CD.Perf && root.CD.Perf.profile()) || { marbleSize: 768, anisotropy: 4 };
    const SIZE = profile.marbleSize || 768;
    const key = String(SIZE);
    if (_cache.has(key)) return _cache.get(key);

    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = SIZE;
    const ctx = canvas.getContext('2d', { willReadFrequently: true });

    ctx.fillStyle = '#08080a';
    ctx.fillRect(0, 0, SIZE, SIZE);
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    const veinCount = profile.low ? 28 : 42;
    for (let i = 0; i < veinCount; i++) {
      ctx.beginPath();
      let x = Math.random() * SIZE;
      let y = Math.random() * SIZE;
      ctx.moveTo(x, y);
      for (let j = 0; j < 5; j++) {
        const scale = SIZE / 1024;
        const cp1x = x + (Math.random() - 0.5) * 400 * scale;
        const cp1y = y + (Math.random() - 0.5) * 400 * scale;
        const cp2x = x + (Math.random() - 0.5) * 400 * scale;
        const cp2y = y + (Math.random() - 0.5) * 400 * scale;
        const ex = x + (Math.random() - 0.5) * 600 * scale;
        const ey = y + (Math.random() - 0.5) * 600 * scale;
        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, ex, ey);
        x = ex; y = ey;
      }
      const brightness = Math.floor(Math.random() * 40 + 20);
      const goldHint = Math.random() > 0.7 ? 30 : 0;
      ctx.lineWidth = (Math.random() * 18 + 4) * (SIZE / 1024);
      ctx.strokeStyle = `rgba(${brightness + goldHint}, ${brightness}, ${brightness}, ${Math.random() * 0.12 + 0.04})`;
      ctx.stroke();
    }

    const img = ctx.getImageData(0, 0, SIZE, SIZE);
    const d = img.data;
    for (let i = 0; i < d.length; i += 8) {
      const n = (Math.random() - 0.5) * 8;
      d[i] += n; d[i + 1] += n; d[i + 2] += n;
    }
    ctx.putImageData(img, 0, 0);

    const tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(3, 3);
    tex.anisotropy = profile.anisotropy || 4;
    tex.colorSpace = THREE.SRGBColorSpace;
    _cache.set(key, tex);
    return tex;
  }

  function dispose() {
    for (const tex of _cache.values()) tex.dispose();
    _cache.clear();
  }

  root.CD = root.CD || {};
  root.CD.MarbleTexture = { create: createMarbleTexture, dispose };
})(window);
