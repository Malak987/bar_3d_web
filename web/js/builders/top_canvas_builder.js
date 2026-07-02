/**
 * top_canvas_builder.js — Renders photo/text into one CanvasTexture.
 * Adaptive texture size reduces memory on mobile while keeping high quality.
 */
(function (root) {
  'use strict';

  function build(group, cfg, radius, topY, bgColor) {
    const hasText = cfg.text && cfg.text.trim().length > 0;
    const hasImage = !!cfg.topImage;
    if (!hasText && !hasImage) return;

    const profile = (root.CD.Perf && root.CD.Perf.profile()) || { topCanvasSize: 1536 };
    const SIZE = profile.topCanvasSize || 1536;
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = SIZE;
    const ctx = canvas.getContext('2d', { alpha: false });

    ctx.fillStyle = '#' + bgColor.getHexString();
    ctx.fillRect(0, 0, SIZE, SIZE);

    const token = (group.userData.topBuildToken || 0) + 1;
    group.userData.topBuildToken = token;

    const finalize = () => {
      if (group.userData.topBuildToken !== token) return;
      if (hasText) _drawText(ctx, cfg, SIZE);
      _attachMesh(group, canvas, radius, topY);
      root.CD.Perf && root.CD.Perf.post('asset-progress', { stage: 'top-ready', progress: 1 });
    };

    if (hasImage) _drawImage(ctx, cfg, SIZE, finalize);
    else finalize();
  }

  function _drawImage(ctx, cfg, SIZE, done) {
    root.CD.Perf && root.CD.Perf.post('asset-progress', { stage: 'top-image', progress: 0.55 });
    const img = new Image();
    img.decoding = 'async';
    img.loading = 'eager';
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      const cx = SIZE / 2, cy = SIZE / 2;
      const r = (SIZE / 2) * cfg.imageScale;
      ctx.save();
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.clip();
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = 'high';
      ctx.drawImage(img, cx - r, cy - r, r * 2, r * 2);
      ctx.restore();
      ctx.save();
      ctx.strokeStyle = cfg.pipingColor;
      ctx.lineWidth = SIZE * 0.015;
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
      done();
    };
    img.onerror = done;
    img.src = cfg.topImage;
  }

  function _drawText(ctx, cfg, SIZE) {
    ctx.save();
    const cx = SIZE / 2;
    let cy = SIZE / 2;
    if (cfg.textPosition === 'top') cy = SIZE * 0.22;
    if (cfg.textPosition === 'bottom') cy = SIZE * 0.78;
    let family = 'Arial, sans-serif';
    let style = 'normal';
    let weight = 'bold';
    if (cfg.fontStyle === 'amiri') { family = 'serif'; style = 'italic'; }
    if (cfg.fontStyle === 'cursive') family = 'cursive';
    const fontSize = SIZE * 0.08 * cfg.textSize;
    ctx.font = `${style} ${weight} ${fontSize}px ${family}`;
    ctx.fillStyle = cfg.textColor;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.shadowColor = 'rgba(0,0,0,0.55)';
    ctx.shadowBlur = Math.max(6, SIZE * 0.008);
    ctx.shadowOffsetX = ctx.shadowOffsetY = Math.max(2, SIZE * 0.002);
    ctx.fillText(cfg.text, cx, cy, SIZE * 0.88);
    ctx.restore();
  }

  function _attachMesh(group, canvas, radius, topY) {
    const profile = (root.CD.Perf && root.CD.Perf.profile()) || { anisotropy: 8 };
    const tex = new THREE.CanvasTexture(canvas);
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.generateMipmaps = true;
    tex.minFilter = THREE.LinearMipmapLinearFilter;
    tex.magFilter = THREE.LinearFilter;
    tex.anisotropy = profile.anisotropy || 8;
    tex.needsUpdate = true;

    const overlay = new THREE.Mesh(
      new THREE.CircleGeometry(radius - 0.005, 96),
      new THREE.MeshBasicMaterial({ map: tex, transparent: true, side: THREE.DoubleSide, toneMapped: false }),
    );
    overlay.rotation.x = -Math.PI / 2;
    overlay.position.y = topY;
    overlay.frustumCulled = false;
    group.add(overlay);
  }

  root.CD = root.CD || {};
  root.CD.TopCanvasBuilder = { build };
})(window);
