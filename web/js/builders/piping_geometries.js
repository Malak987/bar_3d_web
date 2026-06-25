/**
 * ─────────────────────────────────────────────────────────────
 * piping_geometries.js
 *
 * Pure-function factory for every piping type. All output is
 * cached via GeometryPool — each (type, size) is computed once.
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  function safeMerge(geos) {
    const clean = geos.map((g) => g.toNonIndexed());
    return THREE.mergeGeometries(clean, false) || clean[0]
        || new THREE.SphereGeometry(0.01, 8, 8);
  }

  function starShape(points, outerR, innerR) {
    const s = new THREE.Shape();
    for (let i = 0; i < points * 2; i++) {
      const r = i % 2 === 0 ? outerR : innerR;
      const a = (i / (points * 2)) * Math.PI * 2;
      if (i === 0) s.moveTo(Math.cos(a) * r, Math.sin(a) * r);
      else         s.lineTo(Math.cos(a) * r, Math.sin(a) * r);
    }
    s.closePath();
    return s;
  }

  // ── Per-type builders ─────────────────────────────────────────

  const builders = {
    round: (S) => new THREE.SphereGeometry(S * 0.55, 20, 20),

    sphere: (S) => new THREE.SphereGeometry(S * 0.95, 32, 32),

    openStar: (S) => {
      const g = new THREE.ExtrudeGeometry(starShape(6, S, S * 0.5), {
        depth: S * 1.2, bevelEnabled: true,
        bevelSize: S * 0.1, bevelThickness: S * 0.1,
      });
      g.center(); return g;
    },

    closedStar: (S) => {
      const g = new THREE.ExtrudeGeometry(starShape(8, S, S * 0.35), {
        depth: S * 1.4, bevelEnabled: true,
        bevelSize: S * 0.08, bevelThickness: S * 0.08,
      });
      g.center(); return g;
    },

    rose: (S) => {
      const parts = [];
      const center = new THREE.ConeGeometry(S * 0.34, S * 0.75, 24);
      center.rotateX(Math.PI / 2); center.translate(0, 0, S * 0.22);
      parts.push(center);

      const rings = [
        { count: 4,  radius: S * 0.2,  size: S * 0.45, z: S * 0.3,  curl: 0.65 },
        { count: 7,  radius: S * 0.48, size: S * 0.58, z: S * 0.18, curl: 0.35 },
        { count: 10, radius: S * 0.78, size: S * 0.72, z: S * 0.05, curl: 0.1  },
      ];
      for (let ri = 0; ri < rings.length; ri++) {
        const r = rings[ri];
        for (let i = 0; i < r.count; i++) {
          const a = (i / r.count) * Math.PI * 2 + ri * 0.25;
          const p = new THREE.SphereGeometry(r.size, 18, 18);
          p.scale(0.36, 0.12, 0.72);
          p.rotateX(r.curl); p.rotateZ(a);
          p.translate(Math.cos(a) * r.radius, Math.sin(a) * r.radius, r.z);
          parts.push(p);
        }
      }
      return safeMerge(parts);
    },

    dropFlower: (S) => {
      const parts = [];
      const petalCount = 5;
      for (let i = 0; i < petalCount; i++) {
        const a = (i / petalCount) * Math.PI * 2;
        const petal = new THREE.SphereGeometry(S * 0.42, 16, 12);
        petal.scale(1.0, 2.2, 0.35);
        petal.rotateZ(a);
        petal.translate(Math.cos(a) * S * 0.45, Math.sin(a) * S * 0.45, S * 0.06);
        parts.push(petal);
      }
      for (let i = 0; i < petalCount; i++) {
        const a = (i / petalCount) * Math.PI * 2 + Math.PI / 5;
        const inner = new THREE.SphereGeometry(S * 0.25, 12, 10);
        inner.scale(0.8, 1.6, 0.3);
        inner.rotateZ(a);
        inner.translate(Math.cos(a) * S * 0.22, Math.sin(a) * S * 0.22, S * 0.12);
        parts.push(inner);
      }
      const core = new THREE.SphereGeometry(S * 0.16, 14, 14);
      core.translate(0, 0, S * 0.15);
      parts.push(core);
      return safeMerge(parts);
    },

    leaf: (S) => {
      const shape = new THREE.Shape();
      shape.moveTo(0, S * 1.45);
      shape.bezierCurveTo(-S * 0.95, S * 0.78, -S * 0.82, -S * 0.55, 0, -S * 0.95);
      shape.bezierCurveTo(S * 0.82, -S * 0.55, S * 0.95, S * 0.78, 0, S * 1.45);
      const blade = new THREE.ExtrudeGeometry(shape, {
        depth: S * 0.22, bevelEnabled: true,
        bevelSize: S * 0.045, bevelThickness: S * 0.035,
        curveSegments: 18,
      });
      blade.center();
      const vein = new THREE.CylinderGeometry(S * 0.035, S * 0.055, S * 2.1, 8);
      vein.translate(0, S * 0.12, S * 0.16);
      const pinch = new THREE.SphereGeometry(S * 0.28, 12, 12);
      pinch.scale(1.5, 0.55, 0.35);
      pinch.translate(0, -S * 0.88, S * 0.12);
      return safeMerge([blade, vein, pinch]);
    },

    shell: (S) => {
      const parts = [];
      const ridges = 7;
      const shellW = S * 1.0;
      const shellH = S * 0.6;
      const shellD = S * 0.35;

      // body
      const body = new THREE.SphereGeometry(1, 32, 16, 0, Math.PI * 2, 0, Math.PI * 0.5);
      body.scale(shellW * 1.0, shellH * 0.72, shellD * 2.2 * 0.5);
      parts.push(body);

      // base
      const base = new THREE.BoxGeometry(shellW * 1.9, S * 0.05, shellD * 4.0);
      base.translate(0, -S * 0.015, 0);
      parts.push(base);

      // ridges
      for (let r = 0; r < ridges; r++) {
        const t = r / (ridges - 1);
        const arch = Math.cos((t - 0.5) * Math.PI);
        const ridgePts = [];
        const N = 24;
        for (let p = 0; p <= N; p++) {
          const u = p / N;
          const x = (u - 0.5) * shellW * 1.65;
          const taper = Math.sin(u * Math.PI) * (1.0 - u * 0.22);
          const wave  = Math.sin(u * Math.PI * 4.0) * S * 0.03 * taper;
          const y = arch * shellH * taper + wave;
          const z = (t - 0.5) * shellD * 2.2;
          ridgePts.push(new THREE.Vector3(x, y, z));
        }
        const curve = new THREE.CatmullRomCurve3(ridgePts);
        const tube  = new THREE.TubeGeometry(curve, 24, S * (0.05 + 0.03 * arch), 8, false);
        parts.push(tube);
      }
      return safeMerge(parts);
    },

    wave: (S) => {
      const parts = [];
      const mkWave = (oy, lz) => {
        const pts = [];
        for (let i = 0; i <= 72; i++) {
          const u = i / 72;
          const x = (u - 0.5) * S * 4.25;
          const y = Math.sin(u * Math.PI * 4.0 - Math.PI * 0.45) * S * 0.72 + (oy || 0);
          const taper = Math.sin(u * Math.PI);
          pts.push(new THREE.Vector3(x, y * (0.88 + taper * 0.18), lz || 0));
        }
        return new THREE.CatmullRomCurve3(pts);
      };
      parts.push(new THREE.TubeGeometry(mkWave(0, S * 0.02), 90, S * 0.34, 18, false));
      for (let r = 0; r < 7; r++) {
        parts.push(new THREE.TubeGeometry(
          mkWave((r - 3) * S * 0.105, S * (0.28 + r * 0.012)),
          90, S * 0.045, 8, false,
        ));
      }
      const lt = new THREE.ConeGeometry(S * 0.22, S * 0.55, 16);
      lt.rotateZ(Math.PI / 2); lt.translate(-S * 2.2, -S * 0.2, S * 0.04);
      const rt = new THREE.ConeGeometry(S * 0.22, S * 0.55, 16);
      rt.rotateZ(-Math.PI / 2); rt.translate(S * 2.2, S * 0.2, S * 0.04);
      parts.push(lt, rt);
      return safeMerge(parts);
    },

    basketWeave: (S) => {
      const parts = [];
      const vert = new THREE.BoxGeometry(S * 0.34, S * 1.95, S * 0.2);
      vert.translate(0, 0, S * 0.06);
      parts.push(vert);
      for (let k = -2; k <= 2; k++) {
        const g = new THREE.CylinderGeometry(S * 0.018, S * 0.018, S * 1.9, 5);
        g.translate(k * S * 0.055, 0, S * 0.18);
        parts.push(g);
      }
      for (let i = 0; i < 4; i++) {
        const y  = -S * 0.66 + i * S * 0.44;
        const ox = i % 2 === 0 ? -S * 0.48 : S * 0.48;
        const h  = new THREE.BoxGeometry(S * 1.42, S * 0.22, S * 0.24);
        h.translate(ox, y, S * 0.14);
        parts.push(h);
        const cap = new THREE.CapsuleGeometry(S * 0.11, S * 1.25, 4, 10);
        cap.rotateZ(Math.PI / 2);
        cap.translate(ox, y, S * 0.25);
        parts.push(cap);
      }
      return safeMerge(parts);
    },

    frenchLace: (S) => {
      const parts = [];
      const mkTube = (pts, r) => parts.push(new THREE.TubeGeometry(
        new THREE.CatmullRomCurve3(pts), 28, r || S * 0.03, 6, false,
      ));
      const mc = new THREE.TorusGeometry(S * 0.82, S * 0.055, 10, 64);
      mc.translate(0, 0, S * 0.03); parts.push(mc);
      const ic = new THREE.TorusGeometry(S * 0.42, S * 0.028, 8, 48);
      ic.translate(0, 0, S * 0.06); parts.push(ic);

      for (let i = 0; i < 8; i++) {
        const a = (i / 8) * Math.PI * 2, n = a + Math.PI / 8;
        mkTube([
          new THREE.Vector3(Math.cos(a) * S * 0.72, Math.sin(a) * S * 0.72, S * 0.06),
          new THREE.Vector3(Math.cos(n) * S * 0.98, Math.sin(n) * S * 0.98, S * 0.06),
          new THREE.Vector3(Math.cos(a + Math.PI / 4) * S * 0.72,
                             Math.sin(a + Math.PI / 4) * S * 0.72, S * 0.06),
        ], S * 0.028);
        const pearl = new THREE.SphereGeometry(S * 0.075, 8, 8);
        pearl.translate(Math.cos(a) * S * 0.82, Math.sin(a) * S * 0.82, S * 0.12);
        parts.push(pearl);
      }
      for (let i = 0; i < 4; i++) {
        const a = (i / 4) * Math.PI * 2 + Math.PI / 4;
        mkTube([
          new THREE.Vector3(0, 0, S * 0.08),
          new THREE.Vector3(Math.cos(a) * S * 0.28, Math.sin(a) * S * 0.28, S * 0.08),
          new THREE.Vector3(Math.cos(a) * S * 0.55, Math.sin(a) * S * 0.55, S * 0.08),
        ], S * 0.025);
      }
      return safeMerge(parts);
    },

    threads: (S) => {
      const p = [];
      for (let i = 0; i < 4; i++) {
        const t = new THREE.CylinderGeometry(S * 0.07, S * 0.07, S * 1.9, 8);
        t.rotateZ(Math.PI / 2);
        t.translate(0, (i - 1.5) * S * 0.23, S * 0.05);
        p.push(t);
      }
      return safeMerge(p);
    },

    grass: (S) => {
      const blades = [];
      const count  = 55;
      for (let i = 0; i < count; i++) {
        const seed  = Math.sin(i * 12.9898) * 43758.5453;
        const noise = seed - Math.floor(seed);
        const a = (i / count) * Math.PI * 2;
        const h = S * (0.8 + noise * 0.5);
        const b = new THREE.CylinderGeometry(S * 0.028, S * 0.045, h, 5);
        b.rotateZ(Math.sin(i * 2.1) * 0.4);
        b.rotateX(Math.PI / 2 + Math.cos(i * 1.7) * 0.25);
        const dist = S * (0.3 + noise * 0.2);
        b.translate(Math.cos(a) * dist, Math.sin(a) * dist, h * 0.4);
        blades.push(b);
      }
      const base = new THREE.CylinderGeometry(S * 0.38, S * 0.4, S * 0.08, 16);
      base.rotateX(Math.PI / 2);
      blades.push(base);
      return safeMerge(blades);
    },

    heart: (S) => {
      const parts  = [];
      const ridges = 7;
      const scaleF = S * 1.1;
      const heartX = (t) => scaleF * 0.85 * Math.pow(Math.sin(t), 3);
      const heartY = (t) => scaleF * 0.85 *
        (0.8125 * Math.cos(t) - 0.3125 * Math.cos(2 * t)
       - 0.125  * Math.cos(3 * t) - 0.0625 * Math.cos(4 * t));

      for (let r = 0; r < ridges; r++) {
        const t = r / (ridges - 1);
        const layerScale = 0.28 + t * 0.72;
        const layerH     = S * (0.72 - t * 0.52);
        const pts = [];
        const N = 48;
        for (let p = 0; p <= N; p++) {
          const angle = (p / N) * Math.PI * 2 - Math.PI * 0.5;
          const hx = heartX(angle) * layerScale;
          const hz = heartY(angle) * layerScale;
          const wave = Math.sin(angle * 6) * S * 0.025 * (1 - t);
          pts.push(new THREE.Vector3(hx, layerH + wave, hz));
        }
        pts.push(pts[0].clone());
        const curve = new THREE.CatmullRomCurve3(pts, true);
        const tube  = new THREE.TubeGeometry(curve, 64, S * (0.055 + t * 0.055), 8, true);
        parts.push(tube);
      }
      // base ring
      const basePts = [];
      const M = 48;
      for (let p = 0; p <= M; p++) {
        const angle = (p / M) * Math.PI * 2 - Math.PI * 0.5;
        basePts.push(new THREE.Vector3(heartX(angle) * 1.05, S * 0.02, heartY(angle) * 1.05));
      }
      basePts.push(basePts[0].clone());
      parts.push(new THREE.TubeGeometry(
        new THREE.CatmullRomCurve3(basePts, true), 64, S * 0.04, 6, true,
      ));
      // tip
      const tip = new THREE.SphereGeometry(S * 0.09, 10, 10);
      tip.translate(0, S * 0.58, -scaleF * 0.34);
      parts.push(tip);
      return safeMerge(parts);
    },
  };

  /**
   * Get the geometry for `type` at size `S`, cached by `(type, S)`.
   * @param {GeometryPool} pool
   */
  function getGeometry(pool, type, S) {
    const key = `${type}_${S.toFixed(5)}`;
    return pool.get(key, () => {
      const b = builders[type];
      if (b) return b(S);
      return new THREE.SphereGeometry(S, 16, 16);
    });
  }

  root.CD = root.CD || {};
  root.CD.PipingGeometries = { getGeometry };
})(window);
