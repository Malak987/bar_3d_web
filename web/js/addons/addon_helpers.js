/**
 * ─────────────────────────────────────────────────────────────
 * addon_helpers.js — Shared utilities for addons
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  // Default colour per addon
  const DEFAULTS = {
    candles:            '#FF6B6B',
    giftRibbon:         '#D4A24A',
    bow:                '#D4A24A',
    secretMessage:      '#FFFFFF',
    sparklers:          '#FFD700',
    naturalFlowers:     '#FF1493',
    artificialFlowers:  '#FF80AB',
    babyFlower:         '#F8BBD0',
    butterflies:        '#9C27B0',
    fruits:             '#FF4444',
    babyHeartChocolate: '#3D1A0A',
    pearls:             '#FFFFFF',
    sprinkles:          '#FFFFFF',
    glitter:            '#FFD700',
    chocoDrip:          '#3D1A0A',
  };

  // category → bucket
  const CATEGORY = {
    candles:           'center',
    giftRibbon:        'center',
    secretMessage:     'center',
    sparklers:         'center',
    bow:               'edge',
    naturalFlowers:    'edge',
    artificialFlowers: 'edge',
    babyFlower:        'edge',
    butterflies:       'edge',
    fruits:            'edge',
    babyHeartChocolate: 'edge',
    pearls:            'fullring',
    chocoDrip:         'fullring',
    sprinkles:         'surface',
    glitter:           'surface',
  };

  function colorFor(cfg, id) {
    if (cfg.addonColors && cfg.addonColors[id]) return cfg.addonColors[id];
    return DEFAULTS[id] || '#FFFFFF';
  }

  function bucketize(ids) {
    const out = { center: [], edge: [], fullring: [], surface: [] };
    for (const id of ids) {
      const b = CATEGORY[id] || 'edge';
      out[b].push(id);
    }
    return out;
  }

  // ── Instancing helpers ────────────────────────────────────
  // These exist so addon builders never need to create N separate THREE.Mesh
  // objects for N repeated decorations (flowers around the edge, sparks on a
  // sparkler, pearls on a ring...). Each repeated shape becomes ONE
  // InstancedMesh draw call instead of N individual ones — same visual
  // result, a fraction of the GPU/CPU cost, especially on mobile.

  /**
   * One shared base geometry + material, repeated at N placements.
   * `matrices` is an array of THREE.Matrix4 (translation/rotation/scale
   * baked in per-instance — non-uniform scale is fine, e.g. varying a
   * drip's length).
   */
  function instanceSimple(group, geometry, material, matrices, castShadow) {
    if (!matrices.length) return null;
    const inst = new THREE.InstancedMesh(geometry, material, matrices.length);
    for (let i = 0; i < matrices.length; i++) inst.setMatrixAt(i, matrices[i]);
    inst.instanceMatrix.needsUpdate = true;
    inst.computeBoundingSphere();
    if (castShadow !== false) { inst.castShadow = true; inst.receiveShadow = true; }
    group.add(inst);
    return inst;
  }

  /**
   * For composite items (e.g. a flower = 6 petals + 1 core, in two
   * materials): merge each part's LOCAL geometry (already offset from the
   * item's own center via `matrix`) into one geometry per material.
   * `parts`: [{ geometry, material, matrix? }]
   * Returns Map<material, mergedGeometry> — one entry per distinct material.
   */
  function mergeParts(parts) {
    const byMat = new Map();
    for (const p of parts) {
      let g = p.geometry.clone();
      if (p.matrix) g.applyMatrix4(p.matrix);
      if (g.index) g = g.toNonIndexed();
      if (!byMat.has(p.material)) byMat.set(p.material, []);
      byMat.get(p.material).push(g);
    }
    const out = new Map();
    for (const [mat, geos] of byMat.entries()) {
      let merged = geos[0];
      if (geos.length > 1) {
        merged = THREE.mergeGeometries(geos, false) || geos[0];
        for (const g of geos) if (g !== merged) g.dispose();
      }
      merged.computeBoundingSphere();
      out.set(mat, merged);
    }
    return out;
  }

  /**
   * Takes the Map from mergeParts() and repeats each per-material merged
   * shape across every world placement in `matrices` — one InstancedMesh
   * per material (so a 2-material flower repeated 8 times = 2 draw calls
   * total, not 8 × 7 = 56).
   */
  function placeInstances(group, mergedMap, matrices, castShadow) {
    for (const [mat, geo] of mergedMap.entries()) {
      instanceSimple(group, geo, mat, matrices, castShadow);
    }
  }

  /** Build ONE item's local-space parts once, then instance it N times. */
  function buildRepeated(group, matrices, buildOneItemParts, castShadow) {
    const parts = buildOneItemParts();
    placeInstances(group, mergeParts(parts), matrices, castShadow);
  }

  root.CD = root.CD || {};
  root.CD.AddonHelpers = {
    colorFor, bucketize, DEFAULTS, CATEGORY,
    instanceSimple, mergeParts, placeInstances, buildRepeated,
  };
})(window);