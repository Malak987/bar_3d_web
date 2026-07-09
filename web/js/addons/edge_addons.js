/**
 * ─────────────────────────────────────────────────────────────
 * edge_addons.js — flowers, butterflies, fruits, hearts, bow
 *
 * Every "N copies of the same decoration around the edge" case now
 * builds ONE item's local-space parts once, merges same-material
 * parts into a single geometry, then repeats that with InstancedMesh
 * across all N placements. Same look, a fraction of the draw calls
 * (e.g. 8 flowers × 7 parts = 56 meshes before → 2 draw calls now).
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  const AH = root.CD.AddonHelpers;
  const _dummy = new THREE.Object3D();

  /** Build a local-space THREE.Matrix4 via the usual position/rotation/scale dance. */
  function localMatrix(px, py, pz, rx, ry, rz, sx, sy, sz) {
    _dummy.position.set(px || 0, py || 0, pz || 0);
    _dummy.rotation.set(rx || 0, ry || 0, rz || 0);
    _dummy.scale.set(sx == null ? 1 : sx, sy == null ? 1 : sy, sz == null ? 1 : sz);
    _dummy.updateMatrix();
    return _dummy.matrix.clone();
  }

  function worldMatrix(px, py, pz, ry) {
    return localMatrix(px, py, pz, 0, ry || 0, 0);
  }

  // ── natural flowers ──────────────────────────────────────
  function buildNaturalFlowers(group, R, topY, color, startA, arc) {
    const count = 4;
    const petalMat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.3, clearcoat: 0.4,
    });
    const coreMat = new THREE.MeshStandardMaterial({ color: 0xFFD700 });
    const pivotY = topY + R * 0.06;

    const parts = [];
    for (let p = 0; p < 6; p++) {
      const pa = (p / 6) * Math.PI * 2;
      parts.push({
        geometry: new THREE.SphereGeometry(R * 0.055, 10, 10),
        material: petalMat,
        matrix: localMatrix(Math.cos(pa) * R * 0.06, 0, Math.sin(pa) * R * 0.06, 0, 0, 0, 1.5, 0.35, 1.2),
      });
    }
    parts.push({
      geometry: new THREE.SphereGeometry(R * 0.03, 10, 10),
      material: coreMat,
      matrix: localMatrix(0, R * 0.01, 0),
    });

    const placements = [];
    for (let i = 0; i < count; i++) {
      const a = startA + (i + 0.5) / count * arc;
      placements.push(worldMatrix(Math.cos(a) * R * 0.75, pivotY, Math.sin(a) * R * 0.75));
    }
    AH.placeInstances(group, AH.mergeParts(parts), placements, true);
  }

  // ── artificial flowers ───────────────────────────────────
  function buildArtificialFlowers(group, R, topY, color, startA, arc) {
    const count = 5;
    const petalMat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.25, clearcoat: 0.6,
    });
    const coreMat = new THREE.MeshStandardMaterial({ color: 0xFFEE58 });
    const pivotY = topY + R * 0.045;

    const parts = [];
    for (let p = 0; p < 5; p++) {
      const pa = (p / 5) * Math.PI * 2;
      parts.push({
        geometry: new THREE.SphereGeometry(R * 0.048, 10, 10),
        material: petalMat,
        matrix: localMatrix(Math.cos(pa) * R * 0.055, 0, Math.sin(pa) * R * 0.055, 0, 0, 0, 1.8, 0.25, 1.3),
      });
    }
    parts.push({
      geometry: new THREE.SphereGeometry(R * 0.022, 8, 8),
      material: coreMat,
      matrix: localMatrix(0, R * 0.01, 0),
    });

    const placements = [];
    for (let i = 0; i < count; i++) {
      const a = startA + (i + 0.5) / count * arc;
      placements.push(worldMatrix(Math.cos(a) * R * 0.7, pivotY, Math.sin(a) * R * 0.7));
    }
    AH.placeInstances(group, AH.mergeParts(parts), placements, true);
  }

  // ── baby flowers ─────────────────────────────────────────
  function buildBabyFlower(group, R, topY, color, startA, arc) {
    const count = 6;
    const petalMat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.3, clearcoat: 0.5,
    });
    const coreMat = new THREE.MeshStandardMaterial({ color: 0xFFE0B2 });
    const pivotY = topY + R * 0.035;

    const parts = [];
    for (let p = 0; p < 5; p++) {
      const pa = (p / 5) * Math.PI * 2;
      parts.push({
        geometry: new THREE.SphereGeometry(R * 0.03, 8, 8),
        material: petalMat,
        matrix: localMatrix(Math.cos(pa) * R * 0.03, 0, Math.sin(pa) * R * 0.03, 0, 0, 0, 1.3, 0.3, 1.1),
      });
    }
    parts.push({
      geometry: new THREE.SphereGeometry(R * 0.015, 8, 8),
      material: coreMat,
      matrix: localMatrix(0, R * 0.005, 0),
    });

    const placements = [];
    for (let i = 0; i < count; i++) {
      const a = startA + (i + 0.5) / count * arc;
      placements.push(worldMatrix(Math.cos(a) * R * 0.7, pivotY, Math.sin(a) * R * 0.7));
    }
    AH.placeInstances(group, AH.mergeParts(parts), placements, true);
  }

  // ── butterflies ──────────────────────────────────────────
  function buildButterflies(group, R, topY, color, startA, arc) {
    const count = 3;
    const wingMat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.2, clearcoat: 0.6,
      side: THREE.DoubleSide,
    });
    const bodyMat = new THREE.MeshStandardMaterial({ color: 0x1A1A1A });
    const spotMat = new THREE.MeshStandardMaterial({ color: 0xFFFFFF });

    // Build ONE butterfly's parts (in its own local frame — same coordinates
    // the original code used as children of the per-butterfly group).
    const parts = [];
    parts.push({
      geometry: new THREE.CapsuleGeometry(R * 0.012, R * 0.07, 4, 8),
      material: bodyMat,
      matrix: localMatrix(0, 0, 0, 0, 0, Math.PI * 0.1),
    });
    parts.push({
      geometry: new THREE.SphereGeometry(R * 0.016, 8, 8),
      material: bodyMat,
      matrix: localMatrix(0, R * 0.05, 0),
    });
    for (let s = -1; s <= 1; s += 2) {
      parts.push({
        geometry: new THREE.CylinderGeometry(R * 0.003, R * 0.003, R * 0.04, 4),
        material: bodyMat,
        matrix: localMatrix(s * R * 0.012, R * 0.08, 0, 0, 0, s * 0.5),
      });
      parts.push({
        geometry: new THREE.SphereGeometry(R * 0.005, 6, 6),
        material: bodyMat,
        matrix: localMatrix(s * R * 0.025, R * 0.1, 0),
      });
    }

    const ws = R * 0.14;
    const upperShape = new THREE.Shape();
    upperShape.moveTo(0, 0);
    upperShape.bezierCurveTo(ws * 0.5, ws * 0.3, ws * 1.1, ws * 0.6, ws * 0.8, ws);
    upperShape.bezierCurveTo(ws * 0.5, ws * 1.2, ws * 0.1, ws * 0.8, 0, ws * 0.5);
    upperShape.bezierCurveTo(-ws * 0.1, ws * 0.8, -ws * 0.5, ws * 1.2, -ws * 0.8, ws);
    upperShape.bezierCurveTo(-ws * 1.1, ws * 0.6, -ws * 0.5, ws * 0.3, 0, 0);
    const upperGeo = new THREE.ShapeGeometry(upperShape);

    const ls = R * 0.09;
    const lowerShape = new THREE.Shape();
    lowerShape.moveTo(0, 0);
    lowerShape.bezierCurveTo(ls * 0.6, -ls * 0.2, ls * 0.9, -ls * 0.6, ls * 0.5, -ls * 0.8);
    lowerShape.bezierCurveTo(ls * 0.2, -ls * 0.7, 0, -ls * 0.3, 0, 0);
    const lowerGeo = new THREE.ShapeGeometry(lowerShape);

    for (let side = -1; side <= 1; side += 2) {
      parts.push({
        geometry: upperGeo, material: wingMat,
        matrix: localMatrix(side * R * 0.015, R * 0.02, -R * 0.01, 0, side * 0.15, 0),
      });
      parts.push({
        geometry: new THREE.CircleGeometry(R * 0.015, 8), material: spotMat,
        matrix: localMatrix(side * R * 0.06, R * 0.06, side * R * 0.005),
      });
      parts.push({
        geometry: lowerGeo, material: wingMat,
        matrix: localMatrix(side * R * 0.012, -R * 0.02, -R * 0.01, 0, side * 0.15, 0),
      });
    }

    const merged = AH.mergeParts(parts);

    const placements = [];
    for (let i = 0; i < count; i++) {
      const a = startA + (i + 0.5) / count * arc;
      placements.push(worldMatrix(
        Math.cos(a) * R * 0.7, topY + R * 0.22, Math.sin(a) * R * 0.7,
        -a + Math.PI * 0.5,
      ));
    }
    AH.placeInstances(group, merged, placements, false);
  }

  // ── fruits (mix of strawberry/blueberry/raspberry) ───────
  // Only 4 total by design — already cheap, left as individual meshes for
  // simplicity (merging 3 different fruit shapes buys nothing meaningful).
  function buildFruits(group, R, topY, startA, arc) {
    const items = [
      { offset: 0.15, type: 'strawberry' },
      { offset: 0.4,  type: 'blueberry' },
      { offset: 0.65, type: 'raspberry' },
      { offset: 0.85, type: 'blueberry' },
    ];
    for (const it of items) {
      const a  = startA + it.offset * arc;
      const fx = Math.cos(a) * R * 0.65;
      const fz = Math.sin(a) * R * 0.65;

      if (it.type === 'strawberry') {
        const b = new THREE.Mesh(
          new THREE.ConeGeometry(R * 0.045, R * 0.08, 10),
          new THREE.MeshPhysicalMaterial({ color: 0xCC2222, roughness: 0.4, clearcoat: 0.5 }),
        );
        b.position.set(fx, topY + R * 0.06, fz);
        b.castShadow = true;
        group.add(b);

        const leaf = new THREE.Mesh(
          new THREE.SphereGeometry(R * 0.02, 8, 8),
          new THREE.MeshStandardMaterial({ color: 0x228B22 }),
        );
        leaf.scale.set(1.5, 0.3, 1);
        leaf.position.set(fx, topY + R * 0.1, fz);
        group.add(leaf);
      } else if (it.type === 'raspberry') {
        const rb = new THREE.Mesh(
          new THREE.SphereGeometry(R * 0.035, 12, 12),
          new THREE.MeshPhysicalMaterial({ color: 0xB71C1C, roughness: 0.5, clearcoat: 0.3 }),
        );
        rb.position.set(fx, topY + R * 0.04, fz);
        rb.castShadow = true;
        group.add(rb);
      } else {
        const bb = new THREE.Mesh(
          new THREE.SphereGeometry(R * 0.03, 12, 12),
          new THREE.MeshPhysicalMaterial({ color: 0x2244AA, roughness: 0.3, clearcoat: 0.6 }),
        );
        bb.position.set(fx, topY + R * 0.035, fz);
        bb.castShadow = true;
        group.add(bb);
      }
    }
  }

  // ── baby heart chocolates ─────────────────────────────────
  function buildBabyHearts(group, R, topY, color, startA, arc) {
    const count = 5;
    const mat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.25, clearcoat: 0.7,
    });

    // All 3 parts share one material — merge them into a single heart
    // shape, then instance that shape N times.
    const parts = [
      { geometry: new THREE.SphereGeometry(R * 0.03, 10, 10), material: mat,
        matrix: localMatrix(-R * 0.018, 0, 0) },
      { geometry: new THREE.SphereGeometry(R * 0.03, 10, 10), material: mat,
        matrix: localMatrix(R * 0.018, 0, 0) },
      { geometry: new THREE.ConeGeometry(R * 0.042, R * 0.05, 10), material: mat,
        matrix: localMatrix(0, -R * 0.03, 0, 0, 0, Math.PI) },
    ];
    const merged = AH.mergeParts(parts);

    const placements = [];
    for (let i = 0; i < count; i++) {
      const a = startA + (i + 0.5) / count * arc;
      placements.push(worldMatrix(Math.cos(a) * R * 0.7, topY + R * 0.04, Math.sin(a) * R * 0.7));
    }
    AH.placeInstances(group, merged, placements, false);
  }

  // ── 4 small bows on the rim ──────────────────────────────
  function buildBows(group, R, H, baseY, color) {
    const count = 4;
    const topY  = baseY + H;
    const mat   = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.15, metalness: 0.08,
      clearcoat: 1.0, clearcoatRoughness: 0.04,
    });
    const w = R * 0.06;

    const makeLoopGeo = (side) => {
      const sh = new THREE.Shape();
      sh.moveTo(0, 0);
      sh.bezierCurveTo( side * w * 0.25,  w * 3.4, side * w * 2.2,  w * 3.4, side * w * 1.9, 0);
      sh.bezierCurveTo( side * w * 2.2, -w * 0.9, side * w * 0.25, -w * 0.9, 0, 0);
      const geo = new THREE.ExtrudeGeometry(sh, {
        depth: w * 0.45, bevelEnabled: true,
        bevelSize: w * 0.07, bevelThickness: w * 0.07, curveSegments: 20,
      });
      geo.center();
      return geo;
    };

    const makeTailGeo = (side) => {
      const pts = [];
      for (let t = 0; t <= 14; t++) {
        const u = t / 14;
        pts.push(new THREE.Vector3(
          side * (w * 0.3 + u * w * 0.38),
          -u * H * 0.48,
          w * 0.18 - u * w * 0.1,
        ));
      }
      return new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 18, w * 0.21, 8, false);
    };

    // All parts of one bow share the same material — merge into one shape,
    // then instance that shape around the rim.
    const parts = [
      { geometry: makeLoopGeo(1),  material: mat,
        matrix: localMatrix(w * 1.0, w * 0.15, w * 0.22, 0, 0, 0.18) },
      { geometry: makeLoopGeo(-1), material: mat,
        matrix: localMatrix(-w * 1.0, w * 0.15, w * 0.22, 0, 0, -0.18) },
      { geometry: new THREE.SphereGeometry(w * 0.52, 16, 16), material: mat,
        matrix: localMatrix(0, 0, w * 0.28, 0, 0, 0, 1.0, 0.82, 0.68) },
      { geometry: makeTailGeo(1),  material: mat, matrix: localMatrix() },
      { geometry: makeTailGeo(-1), material: mat, matrix: localMatrix() },
    ];
    const merged = AH.mergeParts(parts);

    const placements = [];
    for (let i = 0; i < count; i++) {
      const a  = (i + 0.5) / count * Math.PI * 2;
      const bx = Math.cos(a) * R, bz = Math.sin(a) * R;
      // Reproduce the original g.lookAt(bx*2, topY, bz*2) orientation: the
      // bow faces directly outward, i.e. rotated by the same angle `a`.
      placements.push(worldMatrix(bx, topY, bz, -a - Math.PI / 2));
    }
    AH.placeInstances(group, merged, placements, true);
  }

  root.CD = root.CD || {};
  root.CD.EdgeAddons = {
    buildNaturalFlowers, buildArtificialFlowers, buildBabyFlower,
    buildButterflies, buildFruits, buildBabyHearts, buildBows,
  };
})(window);