/**
 * ─────────────────────────────────────────────────────────────
 * surface_addons.js — pearls ring, choco drip, sprinkles, glitter
 *
 * All four of these place many identical (or near-identical, just
 * scaled) shapes around the cake. Every one is now a single
 * InstancedMesh instead of N separate Mesh + N separate Material
 * objects — visually identical, a fraction of the draw calls.
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  const AH = root.CD.AddonHelpers;

  // ── pearl ring around the rim ────────────────────────────
  function buildPearlRing(group, R, topY, color) {
    const count = 24;
    const mat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color),
      roughness: 0.05, clearcoat: 1, clearcoatRoughness: 0.02, metalness: 0.1,
    });
    const geo = new THREE.SphereGeometry(R * 0.028, 14, 14);

    const matrices = [];
    for (let i = 0; i < count; i++) {
      const a = (i / count) * Math.PI * 2;
      matrices.push(new THREE.Matrix4().makeTranslation(
        Math.cos(a) * R * 0.85, topY + R * 0.035, Math.sin(a) * R * 0.85,
      ));
    }
    AH.instanceSimple(group, geo, mat, matrices, true);
  }

  // ── chocolate drip around the cake top ───────────────────
  function buildChocoDrip(group, R, H, baseY, color) {
    const count = 16;
    const mat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.15, clearcoat: 0.8,
    });

    // the flat top disc only appears once — no instancing needed
    const top = new THREE.Mesh(new THREE.CylinderGeometry(R, R, R * 0.02, 48), mat);
    top.position.y = baseY + H + R * 0.01;
    top.castShadow = true;
    group.add(top);

    // Drips vary in length, but that's just a non-uniform Y-scale on a
    // single unit-length cone — no need for N different geometries.
    const dripUnit = new THREE.CylinderGeometry(R * 0.025, R * 0.008, 1, 8);
    dripUnit.translate(0, -0.5, 0); // pivot at the top so scale.y stretches downward
    const tipGeo = new THREE.SphereGeometry(R * 0.018, 8, 8);

    const dripMatrices = [];
    const tipMatrices = [];
    for (let i = 0; i < count; i++) {
      const a  = (i / count) * Math.PI * 2;
      const dl = R * (0.08 + Math.random() * 0.18);
      const x = Math.cos(a) * R, z = Math.sin(a) * R;
      const topOfDrip = baseY + H;

      const dm = new THREE.Matrix4().compose(
        new THREE.Vector3(x, topOfDrip, z),
        new THREE.Quaternion(),
        new THREE.Vector3(1, dl, 1),
      );
      dripMatrices.push(dm);
      tipMatrices.push(new THREE.Matrix4().makeTranslation(x, topOfDrip - dl, z));
    }
    AH.instanceSimple(group, dripUnit, mat, dripMatrices, true);
    AH.instanceSimple(group, tipGeo, mat, tipMatrices, false);
  }

  // ── sprinkles (white / gold / silver only) ───────────────
  function buildSprinkles(group, R, topY, color) {
    const count = 50;
    const metallic = color === '#D4A24A' || color === '#B0BEC5';
    const mat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.15, clearcoat: 0.8,
      metalness: metallic ? 0.5 : 0,
    });
    const geo = new THREE.SphereGeometry(R * 0.012, 8, 8);

    const matrices = [];
    for (let i = 0; i < count; i++) {
      const a    = Math.random() * Math.PI * 2;
      const dist = Math.random() * R * 0.75;
      matrices.push(new THREE.Matrix4().makeTranslation(
        Math.cos(a) * dist, topY + R * 0.015, Math.sin(a) * dist,
      ));
    }
    AH.instanceSimple(group, geo, mat, matrices, false);
  }

  // ── glitter (small emissive octahedrons) ─────────────────
  function buildGlitter(group, R, topY, color) {
    const count = 80;
    const c = new THREE.Color(color);
    const mat = new THREE.MeshStandardMaterial({
      color: c, emissive: c, emissiveIntensity: 0.6,
      metalness: 0.8, roughness: 0.1,
    });
    // Unit octahedron; per-instance scale reproduces the original random
    // size range (R * 0.006–0.014) without needing a distinct geometry
    // for each particle.
    const geo = new THREE.OctahedronGeometry(1, 0);

    const matrices = [];
    for (let i = 0; i < count; i++) {
      const a    = Math.random() * Math.PI * 2;
      const dist = Math.random() * R * 0.8;
      const size = R * (0.006 + Math.random() * 0.008);
      const q = new THREE.Quaternion().setFromEuler(new THREE.Euler(
        Math.random() * Math.PI, Math.random() * Math.PI, Math.random() * Math.PI,
      ));
      matrices.push(new THREE.Matrix4().compose(
        new THREE.Vector3(Math.cos(a) * dist, topY + R * 0.01, Math.sin(a) * dist),
        q,
        new THREE.Vector3(size, size, size),
      ));
    }
    AH.instanceSimple(group, geo, mat, matrices, false);
  }

  root.CD = root.CD || {};
  root.CD.SurfaceAddons = {
    buildPearlRing, buildChocoDrip, buildSprinkles, buildGlitter,
  };
})(window);