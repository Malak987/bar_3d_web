/**
 * ─────────────────────────────────────────────────────────────
 * edge_addons.js — flowers, butterflies, fruits, hearts, bow
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  // ── natural flowers ──────────────────────────────────────
  function buildNaturalFlowers(group, R, topY, color, startA, arc) {
    const count = 4;
    const petalMat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.3, clearcoat: 0.4,
    });
    const coreMat = new THREE.MeshStandardMaterial({ color: 0xFFD700 });
    for (let i = 0; i < count; i++) {
      const a = startA + (i + 0.5) / count * arc;
      const fx = Math.cos(a) * R * 0.75;
      const fz = Math.sin(a) * R * 0.75;
      for (let p = 0; p < 6; p++) {
        const pa = (p / 6) * Math.PI * 2;
        const petal = new THREE.Mesh(new THREE.SphereGeometry(R * 0.055, 10, 10), petalMat);
        petal.scale.set(1.5, 0.35, 1.2);
        petal.position.set(fx + Math.cos(pa) * R * 0.06, topY + R * 0.06,
                           fz + Math.sin(pa) * R * 0.06);
        group.add(petal);
      }
      const core = new THREE.Mesh(new THREE.SphereGeometry(R * 0.03, 10, 10), coreMat);
      core.position.set(fx, topY + R * 0.07, fz);
      group.add(core);
    }
  }

  // ── artificial flowers ───────────────────────────────────
  function buildArtificialFlowers(group, R, topY, color, startA, arc) {
    const count = 5;
    const petalMat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.25, clearcoat: 0.6,
    });
    const coreMat = new THREE.MeshStandardMaterial({ color: 0xFFEE58 });
    for (let i = 0; i < count; i++) {
      const a = startA + (i + 0.5) / count * arc;
      const fx = Math.cos(a) * R * 0.7;
      const fz = Math.sin(a) * R * 0.7;
      for (let p = 0; p < 5; p++) {
        const pa = (p / 5) * Math.PI * 2;
        const petal = new THREE.Mesh(new THREE.SphereGeometry(R * 0.048, 10, 10), petalMat);
        petal.scale.set(1.8, 0.25, 1.3);
        petal.position.set(fx + Math.cos(pa) * R * 0.055, topY + R * 0.045,
                           fz + Math.sin(pa) * R * 0.055);
        group.add(petal);
      }
      const core = new THREE.Mesh(new THREE.SphereGeometry(R * 0.022, 8, 8), coreMat);
      core.position.set(fx, topY + R * 0.055, fz);
      group.add(core);
    }
  }

  // ── baby flowers ─────────────────────────────────────────
  function buildBabyFlower(group, R, topY, color, startA, arc) {
    const count = 6;
    const petalMat = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.3, clearcoat: 0.5,
    });
    const coreMat = new THREE.MeshStandardMaterial({ color: 0xFFE0B2 });
    for (let i = 0; i < count; i++) {
      const a = startA + (i + 0.5) / count * arc;
      const fx = Math.cos(a) * R * 0.7;
      const fz = Math.sin(a) * R * 0.7;
      for (let p = 0; p < 5; p++) {
        const pa = (p / 5) * Math.PI * 2;
        const petal = new THREE.Mesh(new THREE.SphereGeometry(R * 0.03, 8, 8), petalMat);
        petal.scale.set(1.3, 0.3, 1.1);
        petal.position.set(fx + Math.cos(pa) * R * 0.03, topY + R * 0.035,
                           fz + Math.sin(pa) * R * 0.03);
        group.add(petal);
      }
      const core = new THREE.Mesh(new THREE.SphereGeometry(R * 0.015, 8, 8), coreMat);
      core.position.set(fx, topY + R * 0.04, fz);
      group.add(core);
    }
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

    for (let i = 0; i < count; i++) {
      const a = startA + (i + 0.5) / count * arc;
      const bx = Math.cos(a) * R * 0.7;
      const bz = Math.sin(a) * R * 0.7;
      const g = new THREE.Group();
      g.position.set(bx, topY + R * 0.22, bz);
      g.rotation.y = -a + Math.PI * 0.5;

      const body = new THREE.Mesh(new THREE.CapsuleGeometry(R * 0.012, R * 0.07, 4, 8), bodyMat);
      body.rotation.z = Math.PI * 0.1;
      g.add(body);

      const head = new THREE.Mesh(new THREE.SphereGeometry(R * 0.016, 8, 8), bodyMat);
      head.position.set(0, R * 0.05, 0);
      g.add(head);

      for (let s = -1; s <= 1; s += 2) {
        const ant = new THREE.Mesh(
          new THREE.CylinderGeometry(R * 0.003, R * 0.003, R * 0.04, 4),
          bodyMat,
        );
        ant.position.set(s * R * 0.012, R * 0.08, 0);
        ant.rotation.z = s * 0.5;
        g.add(ant);
        const tip = new THREE.Mesh(new THREE.SphereGeometry(R * 0.005, 6, 6), bodyMat);
        tip.position.set(s * R * 0.025, R * 0.1, 0);
        g.add(tip);
      }

      // upper wings
      const upperShape = new THREE.Shape();
      const ws = R * 0.14;
      upperShape.moveTo(0, 0);
      upperShape.bezierCurveTo(ws * 0.5, ws * 0.3, ws * 1.1, ws * 0.6, ws * 0.8, ws);
      upperShape.bezierCurveTo(ws * 0.5, ws * 1.2, ws * 0.1, ws * 0.8, 0, ws * 0.5);
      upperShape.bezierCurveTo(-ws * 0.1, ws * 0.8, -ws * 0.5, ws * 1.2, -ws * 0.8, ws);
      upperShape.bezierCurveTo(-ws * 1.1, ws * 0.6, -ws * 0.5, ws * 0.3, 0, 0);
      const upperGeo = new THREE.ShapeGeometry(upperShape);

      for (let side = -1; side <= 1; side += 2) {
        const uw = new THREE.Mesh(upperGeo, wingMat);
        uw.position.set(side * R * 0.015, R * 0.02, -R * 0.01);
        uw.rotation.y = side * 0.15;
        g.add(uw);
        const spot = new THREE.Mesh(new THREE.CircleGeometry(R * 0.015, 8), spotMat);
        spot.position.set(side * R * 0.06, R * 0.06, side * R * 0.005);
        g.add(spot);
      }

      // lower wings
      const lowerShape = new THREE.Shape();
      const ls = R * 0.09;
      lowerShape.moveTo(0, 0);
      lowerShape.bezierCurveTo(ls * 0.6, -ls * 0.2, ls * 0.9, -ls * 0.6, ls * 0.5, -ls * 0.8);
      lowerShape.bezierCurveTo(ls * 0.2, -ls * 0.7, 0, -ls * 0.3, 0, 0);
      const lowerGeo = new THREE.ShapeGeometry(lowerShape);

      for (let side = -1; side <= 1; side += 2) {
        const lw = new THREE.Mesh(lowerGeo, wingMat);
        lw.position.set(side * R * 0.012, -R * 0.02, -R * 0.01);
        lw.rotation.y = side * 0.15;
        g.add(lw);
      }

      group.add(g);
    }
  }

  // ── fruits (mix of strawberry/blueberry/raspberry) ───────
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
    for (let i = 0; i < count; i++) {
      const a = startA + (i + 0.5) / count * arc;
      const hx = Math.cos(a) * R * 0.7;
      const hz = Math.sin(a) * R * 0.7;

      const left  = new THREE.Mesh(new THREE.SphereGeometry(R * 0.03, 10, 10), mat);
      left.position.set(hx - R * 0.018, topY + R * 0.04, hz);
      group.add(left);

      const right = new THREE.Mesh(new THREE.SphereGeometry(R * 0.03, 10, 10), mat);
      right.position.set(hx + R * 0.018, topY + R * 0.04, hz);
      group.add(right);

      const tip = new THREE.Mesh(new THREE.ConeGeometry(R * 0.042, R * 0.05, 10), mat);
      tip.position.set(hx, topY + R * 0.01, hz);
      tip.rotation.z = Math.PI;
      group.add(tip);
    }
  }

  // ── 4 small bows on the rim ──────────────────────────────
  function buildBows(group, R, H, baseY, color) {
    const count = 4;
    const topY  = baseY + H;
    const mat   = new THREE.MeshPhysicalMaterial({
      color: new THREE.Color(color), roughness: 0.15, metalness: 0.08,
      clearcoat: 1.0, clearcoatRoughness: 0.04,
    });

    for (let i = 0; i < count; i++) {
      const a  = (i + 0.5) / count * Math.PI * 2;
      const bx = Math.cos(a) * R, bz = Math.sin(a) * R, by = topY;

      const g = new THREE.Group();
      g.position.set(bx, by, bz);
      g.lookAt(bx * 2, by, bz * 2);
      const w = R * 0.06;

      const makeLoop = (side) => {
        const sh = new THREE.Shape();
        sh.moveTo(0, 0);
        sh.bezierCurveTo( side * w * 0.25,  w * 3.4, side * w * 2.2,  w * 3.4, side * w * 1.9, 0);
        sh.bezierCurveTo( side * w * 2.2, -w * 0.9, side * w * 0.25, -w * 0.9, 0, 0);
        const geo = new THREE.ExtrudeGeometry(sh, {
          depth: w * 0.45, bevelEnabled: true,
          bevelSize: w * 0.07, bevelThickness: w * 0.07, curveSegments: 20,
        });
        geo.center();
        const m = new THREE.Mesh(geo, mat);
        m.position.set(side * w * 1.0, w * 0.15, w * 0.22);
        m.rotation.z = side * 0.18;
        m.castShadow = true;
        return m;
      };
      g.add(makeLoop(1));
      g.add(makeLoop(-1));

      const knot = new THREE.Mesh(new THREE.SphereGeometry(w * 0.52, 16, 16), mat);
      knot.scale.set(1.0, 0.82, 0.68);
      knot.position.set(0, 0, w * 0.28);
      knot.castShadow = true;
      g.add(knot);

      const makeTail = (side) => {
        const pts = [];
        for (let t = 0; t <= 14; t++) {
          const u = t / 14;
          pts.push(new THREE.Vector3(
            side * (w * 0.3 + u * w * 0.38),
            -u * H * 0.48,
            w * 0.18 - u * w * 0.1,
          ));
        }
        const m = new THREE.Mesh(
          new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 18, w * 0.21, 8, false),
          mat,
        );
        m.castShadow = true;
        return m;
      };
      g.add(makeTail(1));
      g.add(makeTail(-1));

      group.add(g);
    }
  }

  root.CD = root.CD || {};
  root.CD.EdgeAddons = {
    buildNaturalFlowers, buildArtificialFlowers, buildBabyFlower,
    buildButterflies, buildFruits, buildBabyHearts, buildBows,
  };
})(window);
