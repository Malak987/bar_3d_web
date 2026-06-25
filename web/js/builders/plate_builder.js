/** plate_builder.js — 3-tier gold pedestal with merged geometry per material. */
(function (root) {
  'use strict';

  const _matCache = {};

  function _gold(hex, opts) {
    const key = hex + JSON.stringify(opts);
    if (_matCache[key]) return _matCache[key];
    const mat = new THREE.MeshPhysicalMaterial(Object.assign({
      color: new THREE.Color(hex),
      metalness: 1.0,
      roughness: opts.roughness,
      clearcoat: 1.0,
      clearcoatRoughness: opts.cr,
    }, opts.extra || {}));
    mat.userData.shared = true;
    _matCache[key] = mat;
    return mat;
  }

  function build(group, R, baseY) {
    const deep = _gold('#B8860B', { roughness: 0.05, cr: 0.03, extra: { reflectivity: 1.0, envMapIntensity: 1.5 } });
    const mid = _gold('#D4A017', { roughness: 0.03, cr: 0.02 });
    const light = _gold('#F0C040', { roughness: 0.02, cr: 0.01 });

    const deepBoxes = [];
    const midBoxes = [];
    const lightBoxes = [];

    // tier 3 outermost
    _box(deepBoxes, R + 0.22, 0.022, baseY - 0.048);
    _edge(lightBoxes, baseY - 0.048, R + 0.22, 0.022, 0.006, 0.009, +1);
    _edge(midBoxes, baseY - 0.048, R + 0.22, 0.022, 0.004, 0.005, -1);

    // tier 2
    _box(midBoxes, R + 0.13, 0.018, baseY - 0.027);
    _edge(lightBoxes, baseY - 0.027, R + 0.13, 0.018, 0.005, 0.007, +1);

    // tier 1
    _box(deepBoxes, R + 0.055, 0.014, baseY - 0.007);
    _edge(lightBoxes, baseY - 0.007, R + 0.055, 0.014, 0.004, 0.006, +1);

    // stem and base trims
    const legH = Math.max(0.01, baseY - 0.055);
    const legW = R * 0.42;
    _boxSize(deepBoxes, legW, legH, legW, legH * 0.5);
    _boxSize(lightBoxes, legW + 0.005, 0.006, legW + 0.005, legH + 0.003);
    _boxSize(midBoxes, legW + 0.04, 0.008, legW + 0.04, 0.004);

    _mesh(group, deepBoxes, deep);
    _mesh(group, midBoxes, mid);
    _mesh(group, lightBoxes, light);

    const glow = new THREE.PointLight(0xd4a520, 0.32, 0.8);
    glow.position.set(0, baseY - 0.01, 0);
    group.add(glow);
  }

  function _box(list, r, h, y) { _boxSize(list, r * 2, h, r * 2, y); }
  function _edge(list, y, r, h, dW, dH, side) { _boxSize(list, (r * 2) + dW, dH, (r * 2) + dW, y + side * (h * 0.5 + dH * 0.5)); }

  function _boxSize(list, w, h, d, y) {
    const g = new THREE.BoxGeometry(w, h, d);
    g.applyMatrix4(new THREE.Matrix4().makeTranslation(0, y, 0));
    list.push(g);
  }

  function _mesh(group, geos, mat) {
    if (!geos.length) return;
    const merged = THREE.mergeGeometries ? THREE.mergeGeometries(geos, false) : geos[0];
    for (const g of geos) if (g !== merged) g.dispose();
    const m = new THREE.Mesh(merged, mat);
    m.castShadow = m.receiveShadow = true;
    m.frustumCulled = true;
    group.add(m);
  }

  root.CD = root.CD || {};
  root.CD.PlateBuilder = { build };
})(window);
