/** body_builder.js — cake body with baked vertex-color gradient, adaptive segments. */
(function (root) {
  'use strict';

  const _tmp = new THREE.Color();

  function build(group, cfg, R, H, baseY, matPool) {
    const profile = (root.CD.Perf && root.CD.Perf.profile()) || { low: false };
    const radSegs = profile.low ? 48 : 64;
    const hSegs = profile.low ? 20 : 28;
    const geo = new THREE.CylinderGeometry(R, R, H, radSegs, hSegs, false);
    const pos = geo.attributes.position.array;
    const cnt = geo.attributes.position.count;
    const col = new Float32Array(cnt * 3);

    const c0 = new THREE.Color(cfg.colors[0]);
    const c1 = new THREE.Color(cfg.colors[1] || cfg.colors[0]);
    const c2 = new THREE.Color(cfg.colors[2] || cfg.colors[1] || cfg.colors[0]);
    const n = cfg.gradientColorCount;

    for (let i = 0; i < cnt; i++) {
      const y = pos[i * 3 + 1];
      const t = Math.max(0, Math.min(1, (y + H * 0.5) / H));
      if (n === 1) _tmp.copy(c0);
      else if (n === 2) _tmp.copy(c0).lerp(c1, t);
      else if (t < 0.5) _tmp.copy(c0).lerp(c1, t * 2);
      else _tmp.copy(c1).lerp(c2, (t - 0.5) * 2);
      col[i * 3] = _tmp.r; col[i * 3 + 1] = _tmp.g; col[i * 3 + 2] = _tmp.b;
    }
    geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
    geo.computeBoundingSphere();

    const mat = new THREE.MeshPhysicalMaterial({
      vertexColors: true,
      roughness: cfg.roughness,
      metalness: cfg.metalness,
      clearcoat: cfg.clearcoat,
      clearcoatRoughness: 0.2,
    });

    const mesh = new THREE.Mesh(geo, mat);
    mesh.position.y = baseY + H * 0.5;
    mesh.castShadow = mesh.receiveShadow = true;
    mesh.frustumCulled = true;
    group.add(mesh);

    const topColor = resolveTopColor(cfg);
    const capMat = matPool
      ? matPool.physical('#' + topColor.getHexString(), { roughness: cfg.roughness, metalness: cfg.metalness, clearcoat: cfg.clearcoat, clearcoatRoughness: 0.2 })
      : new THREE.MeshPhysicalMaterial({ color: topColor, roughness: cfg.roughness, metalness: cfg.metalness, clearcoat: cfg.clearcoat });
    const cap = new THREE.Mesh(new THREE.CylinderGeometry(R, R, 0.005, radSegs), capMat);
    cap.position.y = baseY + H;
    cap.receiveShadow = true;
    cap.frustumCulled = true;
    group.add(cap);

    return { topColor };
  }

  function resolveTopColor(cfg) {
    const n = cfg.gradientColorCount;
    const c = cfg.colors;
    if (n === 1) return new THREE.Color(c[0]);
    if (n === 2) return new THREE.Color(c[1] || c[0]);
    return new THREE.Color(c[2] || c[1] || c[0]);
  }

  root.CD = root.CD || {};
  root.CD.BodyBuilder = { build, resolveTopColor };
})(window);
