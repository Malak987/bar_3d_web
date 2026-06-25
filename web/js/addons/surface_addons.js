/**
 * ─────────────────────────────────────────────────────────────
 * surface_addons.js — pearls ring, choco drip, sprinkles, glitter
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  // ── pearl ring around the rim ────────────────────────────
  function buildPearlRing(group, R, topY, color) {
    const count = 24;
    const mat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color),
      roughness: 0.05, clearcoat: 1, clearcoatRoughness: 0.02, metalness: 0.1,
    });
    for (let i = 0; i < count; i++) {
      const a = (i / count) * Math.PI * 2;
      const p = new THREE.Mesh(new THREE.SphereGeometry(R * 0.028, 14, 14), mat);
      p.position.set(Math.cos(a) * R * 0.85, topY + R * 0.035, Math.sin(a) * R * 0.85);
      p.castShadow = true;
      group.add(p);
    }
  }

  // ── chocolate drip around the cake top ───────────────────
  function buildChocoDrip(group, R, H, baseY, color) {
    const count = 16;
    const mat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.15, clearcoat: 0.8,
    });

    const top = new THREE.Mesh(
      new THREE.CylinderGeometry(R, R, R * 0.02, 48),
      mat,
    );
    top.position.y = baseY + H + R * 0.01;
    group.add(top);

    for (let i = 0; i < count; i++) {
      const a  = (i / count) * Math.PI * 2;
      const dl = R * (0.08 + Math.random() * 0.18);

      const drip = new THREE.Mesh(
        new THREE.CylinderGeometry(R * 0.025, R * 0.008, dl, 8),
        mat,
      );
      drip.position.set(Math.cos(a) * R, baseY + H - dl * 0.5, Math.sin(a) * R);
      drip.castShadow = true;
      group.add(drip);

      const tip = new THREE.Mesh(new THREE.SphereGeometry(R * 0.018, 8, 8), mat);
      tip.position.set(Math.cos(a) * R, baseY + H - dl, Math.sin(a) * R);
      group.add(tip);
    }
  }

  // ── sprinkles (white / gold / silver only) ───────────────
  function buildSprinkles(group, R, topY, color) {
    const count = 50;
    const c = new THREE.Color(color);
    const metallic = color === '#D4A24A' || color === '#B0BEC5';
    for (let i = 0; i < count; i++) {
      const a    = Math.random() * Math.PI * 2;
      const dist = Math.random() * R * 0.75;
      const sp   = new THREE.Mesh(
        new THREE.SphereGeometry(R * 0.012, 8, 8),
        new THREE.MeshPhysicalMaterial({
          color: c, roughness: 0.15, clearcoat: 0.8,
          metalness: metallic ? 0.5 : 0,
        }),
      );
      sp.position.set(Math.cos(a) * dist, topY + R * 0.015, Math.sin(a) * dist);
      group.add(sp);
    }
  }

  // ── glitter (small emissive octahedrons) ─────────────────
  function buildGlitter(group, R, topY, color) {
    const count = 80;
    const c = new THREE.Color(color);
    const mat = new THREE.MeshStandardMaterial({
      color: c, emissive: c, emissiveIntensity: 0.6,
      metalness: 0.8, roughness: 0.1,
    });
    for (let i = 0; i < count; i++) {
      const a    = Math.random() * Math.PI * 2;
      const dist = Math.random() * R * 0.8;
      const gl = new THREE.Mesh(
        new THREE.OctahedronGeometry(R * (0.006 + Math.random() * 0.008), 0),
        mat,
      );
      gl.position.set(Math.cos(a) * dist, topY + R * 0.01, Math.sin(a) * dist);
      gl.rotation.set(Math.random() * Math.PI, Math.random() * Math.PI, Math.random() * Math.PI);
      group.add(gl);
    }
  }

  root.CD = root.CD || {};
  root.CD.SurfaceAddons = {
    buildPearlRing, buildChocoDrip, buildSprinkles, buildGlitter,
  };
})(window);
