/**
 * ─────────────────────────────────────────────────────────────
 * center_addons.js — candles, ribbon, secret message, sparklers
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  // ── candles ───────────────────────────────────────────────
  function buildCandles(group, R, topY, color) {
    const count = 5, cr = R * 0.5;
    const stickMat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.3, clearcoat: 0.5,
    });
    const flameMat = new THREE.MeshStandardMaterial({
      color: 0xFF8800, emissive: 0xFF6600, emissiveIntensity: 2,
    });
    for (let i = 0; i < count; i++) {
      const a = (i / count) * Math.PI * 2 - Math.PI * 0.5;
      const x = Math.cos(a) * cr, z = Math.sin(a) * cr;

      const stick = new THREE.Mesh(
        new THREE.CylinderGeometry(R * 0.018, R * 0.022, R * 0.35, 12),
        stickMat,
      );
      stick.position.set(x, topY + R * 0.175, z);
      stick.castShadow = true;
      group.add(stick);

      const flame = new THREE.Mesh(
        new THREE.ConeGeometry(R * 0.02, R * 0.06, 8),
        flameMat,
      );
      flame.position.set(x, topY + R * 0.38, z);
      group.add(flame);
    }
  }

  // ── gift ribbon (single ribbon + bow on side) ────────────
  function buildGiftRibbon(group, R, H, baseY, color) {
    const topY  = baseY + H;
    const midY  = baseY + H * 0.5;
    const segs  = 128;
    const w     = R * 0.048;
    const mat   = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color),
      roughness: 0.12, metalness: 0.12,
      clearcoat: 1.0, clearcoatRoughness: 0.03,
    });

    // horizontal ring
    const hPts = [];
    for (let i = 0; i <= segs; i++) {
      const a = (i / segs) * Math.PI * 2;
      hPts.push(new THREE.Vector3(
        Math.cos(a) * (R + w * 0.25), midY, Math.sin(a) * (R + w * 0.25),
      ));
    }
    hPts.push(hPts[0].clone());
    const ribbon = new THREE.Mesh(
      new THREE.TubeGeometry(new THREE.CatmullRomCurve3(hPts, true),
                              segs, w * 0.52, 12, true),
      mat,
    );
    ribbon.castShadow = ribbon.receiveShadow = true;
    group.add(ribbon);

    // bow on front
    const bw = R * 0.07;
    const g = new THREE.Group();
    g.position.set(0, midY, R + w * 0.3);

    const makeLoop = (side) => {
      const sh = new THREE.Shape();
      sh.moveTo(0, 0);
      sh.bezierCurveTo( side * w * 0.25,  w * 3.4,  side * w * 2.2,  w * 3.4,  side * w * 1.9, 0);
      sh.bezierCurveTo( side * w * 2.2, -w * 0.9,  side * w * 0.25, -w * 0.9, 0, 0);
      const geo = new THREE.ExtrudeGeometry(sh, {
        depth: bw * 0.42, bevelEnabled: true,
        bevelSize: bw * 0.07, bevelThickness: bw * 0.07, curveSegments: 20,
      });
      geo.center();
      const m = new THREE.Mesh(geo, mat);
      m.position.set(side * bw * 1.3, bw * 0.1, bw * 0.22);
      m.rotation.z = side * 0.18;
      m.castShadow = true;
      return m;
    };
    g.add(makeLoop(1));
    g.add(makeLoop(-1));

    const knot = new THREE.Mesh(new THREE.SphereGeometry(bw * 0.5, 16, 16), mat);
    knot.scale.set(1.0, 0.82, 0.68);
    knot.position.set(0, 0, bw * 0.26);
    knot.castShadow = true;
    g.add(knot);

    const makeTail = (side) => {
      const pts = [];
      for (let t = 0; t <= 14; t++) {
        const u = t / 14;
        pts.push(new THREE.Vector3(
          side * (bw * 0.32 + u * bw * 0.45),
          -(u * H * 0.30),
          bw * 0.15 - u * bw * 0.08,
        ));
      }
      const m = new THREE.Mesh(
        new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 16, bw * 0.16, 8, false),
        mat,
      );
      m.castShadow = true;
      return m;
    };
    g.add(makeTail(1));
    g.add(makeTail(-1));
    group.add(g);
  }

  // ── secret message (envelope) ────────────────────────────
  function buildSecretMessage(group, R, topY) {
    const paperMat = new THREE.MeshPhysicalMaterial({
      color: 0xFFF8E7, roughness: 0.3, clearcoat: 0.4,
    });
    const env = new THREE.Mesh(
      new THREE.BoxGeometry(R * 0.35, R * 0.02, R * 0.25),
      paperMat,
    );
    env.position.set(0, topY + R * 0.02, 0);
    env.castShadow = true;
    group.add(env);

    const flap = new THREE.Mesh(
      new THREE.BoxGeometry(R * 0.35, R * 0.005, R * 0.13),
      new THREE.MeshPhysicalMaterial({ color: 0xFFE0B2, roughness: 0.3 }),
    );
    flap.position.set(0, topY + R * 0.035, -R * 0.06);
    flap.rotation.x = -0.4;
    group.add(flap);

    const seal = new THREE.Mesh(
      new THREE.CylinderGeometry(R * 0.025, R * 0.025, R * 0.005, 12),
      new THREE.MeshStandardMaterial({ color: 0xCC0000 }),
    );
    seal.position.set(0, topY + R * 0.04, 0);
    group.add(seal);
  }

  // ── sparklers ────────────────────────────────────────────
  function buildSparklers(group, R, topY) {
    const wireMat = new THREE.MeshStandardMaterial({ color: 0xCCCCCC, metalness: 0.8 });
    const sparkMat = new THREE.MeshStandardMaterial({
      color: 0xFFFF00, emissive: 0xFFAA00, emissiveIntensity: 3,
    });
    for (let i = 0; i < 3; i++) {
      const a = (i / 3) * Math.PI * 2;
      const sx = Math.cos(a) * R * 0.35, sz = Math.sin(a) * R * 0.35;
      const wire = new THREE.Mesh(
        new THREE.CylinderGeometry(R * 0.006, R * 0.006, R * 0.5, 6),
        wireMat,
      );
      wire.position.set(sx, topY + R * 0.25, sz);
      wire.castShadow = true;
      group.add(wire);

      for (let j = 0; j < 8; j++) {
        const sp = new THREE.Mesh(new THREE.SphereGeometry(R * 0.012, 6, 6), sparkMat);
        const sa = Math.random() * Math.PI * 2;
        const sr = R * (0.02 + Math.random() * 0.06);
        sp.position.set(
          sx + Math.cos(sa) * sr,
          topY + R * (0.45 + Math.random() * 0.15),
          sz + Math.sin(sa) * sr,
        );
        group.add(sp);
      }
    }
  }

  root.CD = root.CD || {};
  root.CD.CenterAddons = {
    buildCandles, buildGiftRibbon, buildSecretMessage, buildSparklers,
  };
})(window);
