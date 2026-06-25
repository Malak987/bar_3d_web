/**
 * ─────────────────────────────────────────────────────────────
 * piping_builder.js
 *
 * Places piping (top edge / full coverage / both edges) using
 * InstancedMesh for maximum throughput. One material per ring,
 * one geometry per (type, size).
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  const C = root.CD;

  // ── helpers ───────────────────────────────────────────────

  function pipingColor(cfg, t) {
    const stops = cfg.pipingColors && cfg.pipingColors.length
                    ? cfg.pipingColors
                    : [cfg.pipingColor, cfg.pipingColor, cfg.pipingColor];
    const cnt = Math.max(1, Math.min(3, cfg.pipingColorCount || 1));
    return C.ColorUtils.sampleGradientHex(stops, cnt, t);
  }

  function _hasBlockTopAddons(cfg) {
    const BLOCK = ['giftRibbon', 'naturalFlowers', 'artificialFlowers',
                   'babyFlower', 'fruits', 'babyHeartChocolate',
                   'pearls', 'chocoDrip', 'sprinkles', 'glitter'];
    return cfg.selectedAddons && cfg.selectedAddons.some((a) => BLOCK.indexOf(a) !== -1);
  }

  // ── core placement ────────────────────────────────────────

  function build(group, cfg, R, H, baseY, pools) {
    if (cfg.pipingType === 'none') return;

    const S    = 0.072 * cfg.pipingSize;
    const topY = baseY + H + S * 0.4;

    const hasTop = (cfg.text && cfg.text.trim().length > 0) || !!cfg.topImage;
    const fillTop = cfg.pipingPlacement === 'full'
                    && !hasTop
                    && !_hasBlockTopAddons(cfg);

    const isEdges = cfg.pipingPlacement === 'edges';
    const isFull  = cfg.pipingPlacement === 'full';

    // route to specialised "ring-on-ring" builders for some types
    if (cfg.pipingType === 'threads') {
      return RingTypes.threads (group, cfg, R, H, baseY, S, topY, fillTop, isEdges, pools);
    }
    if (cfg.pipingType === 'wave') {
      return RingTypes.wave    (group, cfg, R, H, baseY, S, topY, fillTop, isEdges, pools);
    }
    if (cfg.pipingType === 'thinLine') {
      return RingTypes.thinLine(group, cfg, R, H, baseY, S, topY, fillTop, isEdges, pools);
    }

    // shell / heart use dedicated instanced rings
    if (cfg.pipingType === 'shell' || cfg.pipingType === 'heart') {
      const ringFn = cfg.pipingType === 'shell' ? _shellRing : _heartRing;
      const topRings = [];
      if (fillTop) {
        let cur = R - S * 2.4;
        while (cur > S * 2.7) { topRings.push(cur); cur -= S * 2.0; }
      }
      topRings.push(R - S * 0.85);
      const fct = isFull ? 1 : 0;
      for (const rr of topRings) ringFn(group, cfg, rr, topY, S, fct, false, pools);

      if (isFull) {
        const rows  = Math.max(3, Math.round(H / (S * 1.5)));
        const start = baseY + S * 0.1;
        const end   = baseY + H - S * 0.1;
        for (let j = 0; j <= rows; j++) {
          const y = start + (j / rows) * (end - start);
          ringFn(group, cfg, R + S * 0.15, y, S, j / rows, true, pools);
        }
      }
      if (isEdges) ringFn(group, cfg, R + S * 0.15, baseY + S * 0.7, S, 0, true, pools);
      return;
    }

    // ── generic types (openStar, closedStar, rose, dropFlower, …)
    if (fillTop) {
      let cur = R - S * 2.5;
      while (cur > 0.1) {
        _genericRing(group, cfg, cur, topY, S, false, 1, pools);
        cur -= S * 2.2;
      }
    }
    const fct = isFull ? 1 : 0;
    _genericRing(group, cfg, R - S * 0.8, topY, S, false, fct, pools);

    if (isFull) {
      const rows = Math.round(H / (S * 2.2));
      for (let j = 0; j <= rows; j++) {
        _genericRing(group, cfg, R + S * 0.15,
                     baseY + (j / rows) * H, S, true, j / rows, pools);
      }
    }
    if (isEdges) {
      _genericRing(group, cfg, R + S * 0.15, baseY + S * 0.7, S, true, 0, pools);
    }
  }

  // ── generic InstancedMesh ring ────────────────────────────

  function _spacing(type, S) {
    switch (type) {
      case 'heart':       return S * 2.0;
      case 'basketWeave': return S * 1.15;
      case 'wave':        return S * 2.6;
      case 'round':       return S * 1.2;
      default:            return S * 1.8;
    }
  }

  function _genericRing(group, cfg, r, y, S, isSide, colorT, pools) {
    const circ = 2 * Math.PI * r;
    const cnt  = Math.max(12, Math.floor(circ / _spacing(cfg.pipingType, S)));

    const geo = C.PipingGeometries.getGeometry(pools.geo, cfg.pipingType, S);
    const hex = pipingColor(cfg, cfg.pipingPlacement === 'full' ? colorT : 0);
    const isMetal = hex.toLowerCase() === '#d4a24a';
    const mat = pools.mat.physical(hex, {
      roughness: 0.35, clearcoat: 0.4, metalness: isMetal ? 0.8 : 0.0,
    });

    const inst = new THREE.InstancedMesh(geo, mat, cnt);
    inst.castShadow = inst.receiveShadow = true;
    const dummy = new THREE.Object3D();

    for (let i = 0; i < cnt; i++) {
      const a = (i / cnt) * Math.PI * 2;
      const x = r * Math.cos(a);
      const z = r * Math.sin(a);

      if (isSide) {
        if (cfg.pipingType === 'heart') {
          dummy.position.set(x, y, z);
          dummy.rotation.set(0, a + Math.PI * 0.5, 0);
          dummy.rotateX(Math.PI * 0.08);
        } else {
          dummy.position.set(x, y, z);
          dummy.lookAt(x + Math.cos(a), y, z + Math.sin(a));
          dummy.rotateZ(Math.PI / 2);
        }
      } else if (cfg.pipingType === 'heart') {
        dummy.position.set(x, y + S * 0.08, z);
        _orientUpAlongTangent(dummy, a);
        dummy.rotateY(Math.PI / 2);
      } else {
        dummy.position.set(x, y + S * 0.2, z);
        dummy.rotation.set(-Math.PI / 2, 0, a, 'XYZ');
      }
      dummy.updateMatrix();
      inst.setMatrixAt(i, dummy.matrix);
    }
    inst.instanceMatrix.needsUpdate = true;
    group.add(inst);
  }

  function _orientUpAlongTangent(dummy, a) {
    const up      = new THREE.Vector3(0, 1, 0);
    const tan     = new THREE.Vector3(-Math.sin(a), 0, Math.cos(a));
    const cross   = new THREE.Vector3().crossVectors(tan, up).normalize();
    const m       = new THREE.Matrix4().makeBasis(tan, up, cross);
    dummy.setRotationFromMatrix(m);
  }

  // ── shell ring (specialised orientation) ─────────────────

  function _shellRing(group, cfg, r, y, S, colorT, isSide, pools) {
    const circ  = 2 * Math.PI * r;
    const shellW = S * 1.4;
    const cnt   = Math.max(10, Math.floor(circ / (shellW * 0.92)));

    const geo = C.PipingGeometries.getGeometry(pools.geo, 'shell', S);
    const hex = pipingColor(cfg, cfg.pipingPlacement === 'full' ? colorT : 0);
    const mat = pools.mat.physical(hex, { roughness: 0.35, clearcoat: 0.4, metalness: 0 });

    const inst = new THREE.InstancedMesh(geo, mat, cnt);
    inst.castShadow = inst.receiveShadow = true;
    const dummy = new THREE.Object3D();

    for (let i = 0; i < cnt; i++) {
      const a = (i / cnt) * Math.PI * 2;
      const x = r * Math.cos(a), z = r * Math.sin(a);
      if (isSide) {
        dummy.position.set(x, y, z);
        dummy.lookAt(x * 2, y, z * 2);
        dummy.rotateX(Math.PI * 0.5);
        dummy.rotateY(Math.PI);
      } else {
        dummy.position.set(x, y, z);
        dummy.rotation.set(0, 0, 0);
        _orientUpAlongTangent(dummy, a);
      }
      dummy.updateMatrix();
      inst.setMatrixAt(i, dummy.matrix);
    }
    inst.instanceMatrix.needsUpdate = true;
    group.add(inst);
  }

  // ── heart ring ────────────────────────────────────────────

  function _heartRing(group, cfg, r, y, S, colorT, isSide, pools) {
    const circ = 2 * Math.PI * r;
    const heartW = S * 1.8;
    const cnt = Math.max(10, Math.floor(circ / (heartW * 0.95)));

    const geo = C.PipingGeometries.getGeometry(pools.geo, 'heart', S);
    const hex = pipingColor(cfg, cfg.pipingPlacement === 'full' ? colorT : 0);
    const mat = pools.mat.physical(hex, { roughness: 0.35, clearcoat: 0.4, metalness: 0 });

    const inst = new THREE.InstancedMesh(geo, mat, cnt);
    inst.castShadow = inst.receiveShadow = true;
    const dummy = new THREE.Object3D();

    for (let i = 0; i < cnt; i++) {
      const a = (i / cnt) * Math.PI * 2;
      const x = r * Math.cos(a), z = r * Math.sin(a);
      if (isSide) {
        dummy.position.set(x, y, z);
        dummy.lookAt(x * 2, y, z * 2);
        dummy.rotateY(Math.PI);
        dummy.rotateX(-Math.PI * 0.5);
        dummy.rotateX(Math.PI * 0.08);
      } else {
        dummy.position.set(x, y, z);
        dummy.rotation.set(0, 0, 0);
        _orientUpAlongTangent(dummy, a);
        dummy.rotateY(Math.PI / 2);
      }
      dummy.updateMatrix();
      inst.setMatrixAt(i, dummy.matrix);
    }
    inst.instanceMatrix.needsUpdate = true;
    group.add(inst);
  }

  // ════════════════════════════════════════════════════════════
  // Specialised "ring-of-tubes" types
  // ════════════════════════════════════════════════════════════
  const RingTypes = {

    threads(group, cfg, R, H, baseY, S, topY, fillTop, isEdges, pools) {
      const mkTorus = (r, y, t) => {
        const hex = pipingColor(cfg, cfg.pipingPlacement === 'full' ? t : 0);
        const m = new THREE.Mesh(
          new THREE.TorusGeometry(r, S * 0.055, 12, 180),
          pools.mat.physical(hex, { roughness: 0.25, clearcoat: 0.6, metalness: 0.05 }),
        );
        m.rotation.x = -Math.PI / 2;
        m.position.y = y + S * 0.08;
        m.castShadow = m.receiveShadow = true;
        group.add(m);
      };
      const radii = fillTop
        ? (() => { const a = []; let c = R - S * 1.1;
                   while (c > S * 2.5) { a.push(c); c -= S * 0.55; } return a; })()
        : [R - S * 1.1, R - S * 1.65, R - S * 2.2].filter((v) => v > S * 2.5);

      for (const rr of radii) mkTorus(rr, topY, 0);

      if (cfg.pipingPlacement === 'full') {
        const rows = Math.max(5, Math.round(H / (S * 0.9)));
        for (let j = 0; j <= rows; j++) mkTorus(R + S * 0.1, baseY + (j / rows) * H, j / rows);
      }
      if (isEdges) mkTorus(R + S * 0.1, baseY + S * 0.7, 0);
    },

    wave(group, cfg, R, H, baseY, S, topY, fillTop, isEdges, pools) {
      const matFor = (t) => pools.mat.physical(
        pipingColor(cfg, cfg.pipingPlacement === 'full' ? t : 0),
        { roughness: 0.25, clearcoat: 0.6, metalness: 0.05 },
      );

      const mkTopRing = (rr, y, t) => {
        const wc = Math.max(8, Math.round(rr / (S * 0.12)));
        const curve = (rOff, yOff) => {
          const pts = [];
          for (let i = 0; i <= 240; i++) {
            const u = i / 240, a = u * Math.PI * 2;
            const wave = Math.sin(a * wc) * S * 0.16;
            pts.push(new THREE.Vector3(
              Math.cos(a) * (rr + rOff + wave),
              y + yOff,
              Math.sin(a) * (rr + rOff + wave),
            ));
          }
          return new THREE.CatmullRomCurve3(pts, true);
        };
        const base = new THREE.Mesh(
          new THREE.TubeGeometry(curve(0, S * 0.07), 260, S * 0.25, 18, true),
          matFor(t),
        );
        base.castShadow = base.receiveShadow = true;
        group.add(base);
        for (let r = -3; r <= 3; r++) {
          const rm = new THREE.Mesh(
            new THREE.TubeGeometry(curve(r * S * 0.085, S * (0.29 + Math.abs(r) * 0.006)),
                                   260, S * 0.035, 8, true),
            matFor(t),
          );
          rm.castShadow = rm.receiveShadow = true;
          group.add(rm);
        }
      };

      const mkSideRing = (rr, y, t) => {
        const wc = Math.max(8, Math.round(rr / (S * 0.14)));
        const curve = (vOff, rOff) => {
          const pts = [];
          for (let i = 0; i <= 240; i++) {
            const u = i / 240, a = u * Math.PI * 2;
            pts.push(new THREE.Vector3(
              Math.cos(a) * (rr + rOff),
              y + vOff + Math.sin(a * wc) * S * 0.18,
              Math.sin(a) * (rr + rOff),
            ));
          }
          return new THREE.CatmullRomCurve3(pts, true);
        };
        const base = new THREE.Mesh(
          new THREE.TubeGeometry(curve(0, S * 0.06), 240, S * 0.2, 16, true),
          matFor(t),
        );
        base.castShadow = base.receiveShadow = true;
        group.add(base);
        for (let r = -3; r <= 3; r++) {
          const rm = new THREE.Mesh(
            new THREE.TubeGeometry(curve(r * S * 0.055, S * (0.26 + Math.abs(r) * 0.012)),
                                   240, S * 0.032, 8, true),
            matFor(t),
          );
          rm.castShadow = rm.receiveShadow = true;
          group.add(rm);
        }
      };

      const topRings = [];
      if (fillTop) {
        let cur = R - S * 2.2;
        while (cur > S * 1.5) { topRings.push(cur); cur -= S * 1.6; }
      }
      topRings.push(R - S * 0.8);
      for (const rr of topRings) mkTopRing(rr, topY, 0);

      if (cfg.pipingPlacement === 'full') {
        const rows = Math.max(4, Math.round(H / (S * 1.4)));
        for (let j = 0; j <= rows; j++) mkSideRing(R + S * 0.15, baseY + (j / rows) * H, j / rows);
      }
      if (isEdges) mkSideRing(R + S * 0.15, baseY + S * 0.7, 0);
    },

    thinLine(group, cfg, R, H, baseY, S, topY, fillTop, isEdges, pools) {
      const mkRing = (r, y, t) => {
        const hex = pipingColor(cfg, cfg.pipingPlacement === 'full' ? t : 0);
        const m = new THREE.Mesh(
          new THREE.TorusGeometry(r, S * 0.15, 16, 128),
          pools.mat.physical(hex, { roughness: 0.25, clearcoat: 0.6, metalness: 0.05 }),
        );
        m.rotation.x = -Math.PI / 2;
        m.position.y = y;
        m.castShadow = m.receiveShadow = true;
        group.add(m);
      };
      if (fillTop) {
        let cur = R - S * 2.5;
        while (cur > 0.1) { mkRing(cur, topY, 1); cur -= S * 2.2; }
      }
      mkRing(R - S * 0.8, topY, 0);
      if (cfg.pipingPlacement === 'full') {
        const rows = Math.round(H / (S * 2.2));
        for (let j = 0; j <= rows; j++) mkRing(R + S * 0.1, baseY + (j / rows) * H, j / rows);
      }
      if (isEdges) mkRing(R + S * 0.1, baseY + S * 0.7, 0);
    },
  };

  root.CD = root.CD || {};
  root.CD.PipingBuilder = { build, pipingColor };
})(window);
