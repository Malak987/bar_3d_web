/** marble_texture.js — cached procedural marble, 100% matched to bar3dcake look. */
(function (root) {
  'use strict';

  const _cache = new Map();

  function createMarbleTexture(profile) {
    const SIZE = 1024; // 100% matched to bar3dcake
    const key = String(SIZE);
    if (_cache.has(key)) return _cache.get(key);

    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = SIZE;
    const ctx = canvas.getContext('2d');

    ctx.fillStyle = '#08080a';
    ctx.fillRect(0, 0, SIZE, SIZE);
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    for (let i = 0; i < 60; i++) { // 100% matched to bar3dcake vein count
      ctx.beginPath();
      let x = Math.random() * SIZE;
      let y = Math.random() * SIZE;
      ctx.moveTo(x, y);
      for (let j = 0; j < 6; j++) {
        const cp1x = x + (Math.random() - 0.5) * 400;
        const cp1y = y + (Math.random() - 0.5) * 400;
        const cp2x = x + (Math.random() - 0.5) * 400;
        const cp2y = y + (Math.random() - 0.5) * 400;
        const ex = x + (Math.random() - 0.5) * 600;
        const ey = y + (Math.random() - 0.5) * 600;
        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, ex, ey);
        x = ex; y = ey;
      }
      const brightness = Math.floor(Math.random() * 40 + 20);
      const goldHint = Math.random() > 0.7 ? 30 : 0;
      const alpha = Math.random() * 0.15 + 0.05;
      ctx.lineWidth = Math.random() * 25 + 5;
      ctx.strokeStyle = `rgba(${brightness + goldHint}, ${brightness}, ${brightness}, ${alpha})`;
      ctx.stroke();
    }

    const img = ctx.getImageData(0, 0, SIZE, SIZE);
    const d = img.data;
    for (let i = 0; i < d.length; i += 4) {
      const n = (Math.random() - 0.5) * 10; // 100% matched to bar3dcake noise grain
      d[i] += n; d[i + 1] += n; d[i + 2] += n;
    }
    ctx.putImageData(img, 0, 0);

    const tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(3, 3);
    tex.anisotropy = 16; // 100% matched to bar3dcake sharpness
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
