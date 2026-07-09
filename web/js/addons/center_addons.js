/**
 * ─────────────────────────────────────────────────────────────
 * center_addons.js — candles, ribbon, secret message, sparklers
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  // ── number-shaped candles (0-9, 1 or 2 digits, gold/silver) ──
  //
  // The candle IS the number — a thick waxy 3D digit sitting on the
  // cake top, with a thin wick sticking out of its top edge and a
  // small flame on the wick.  No separate stick underneath.
  //
  function buildCandles(group, R, topY, color, cfg) {
    // Always show number-shaped candles.
    // Default to [0] when no digits have been picked yet.
    const digits = (cfg && cfg.candleDigits && cfg.candleDigits.length > 0)
      ? cfg.candleDigits.slice(0, 2)
      : [0];

    // ── Material — waxy / metallic candle body ──────────────
    const isGold = color && color.toLowerCase().indexOf('d4a') !== -1;
    const bodyColor = isGold ? 0xD4A24A : 0xC0C0C0;
    const waxMat = new THREE.MeshPhysicalMaterial({
      color: bodyColor,
      roughness: isGold ? 0.22 : 0.18,
      metalness: 0.75,
      clearcoat: 0.9,
      clearcoatRoughness: 0.05,
    });
    const wickMat = new THREE.MeshStandardMaterial({
      color: 0x222222, roughness: 0.9, metalness: 0,
    });
    const flameMat = new THREE.MeshStandardMaterial({
      color: 0xFFAA22, emissive: 0xFF6600, emissiveIntensity: 2.8,
    });
    const glowMat = new THREE.MeshStandardMaterial({
      color: 0xFFFF88, emissive: 0xFFDD44, emissiveIntensity: 1.5,
      transparent: true, opacity: 0.6,
    });

    const count   = digits.length;
    const spacing = count === 1 ? 0 : R * 0.22;
    const candleH = R * 0.30;              // smaller, proportional to cake
    const depth   = candleH * 0.22;        // thickness (z) of the number
    const wickH   = candleH * 0.16;        // wick length
    const flameH  = candleH * 0.14;        // flame size

    for (let i = 0; i < count; i++) {
      const digit = digits[i];
      const xOff  = count === 1 ? 0 : (i === 0 ? -spacing : spacing);

      // ── 1. Number body (the candle itself) ──────────────
      const shape = _digitShape(digit, candleH);
      if (!shape) continue;

      const geo = new THREE.ExtrudeGeometry(shape, {
        depth: depth,
        bevelEnabled: true,
        bevelSize: depth * 0.12,
        bevelThickness: depth * 0.10,
        curveSegments: 14,
        bevelSegments: 2,
      });
      geo.center();

      const body = new THREE.Mesh(geo, waxMat);
      body.position.set(xOff, topY + candleH * 0.5, 0);
      body.castShadow = true;
      body.receiveShadow = true;
      group.add(body);

      // ── 2. Wick (thin cylinder on top of the number) ────
      const wick = new THREE.Mesh(
        new THREE.CylinderGeometry(R * 0.005, R * 0.004, wickH, 6),
        wickMat,
      );
      wick.position.set(xOff, topY + candleH + wickH * 0.5, 0);
      group.add(wick);

      // ── 3. Flame (teardrop-ish cone on top of wick) ─────
      const flame = new THREE.Mesh(
        new THREE.ConeGeometry(R * 0.016, flameH, 8),
        flameMat,
      );
      flame.position.set(xOff, topY + candleH + wickH + flameH * 0.42, 0);
      group.add(flame);

      // Inner bright core
      const core = new THREE.Mesh(
        new THREE.ConeGeometry(R * 0.008, flameH * 0.6, 6),
        glowMat,
      );
      core.position.set(xOff, topY + candleH + wickH + flameH * 0.3, 0);
      group.add(core);

      // ── 4. Point light (warm glow) ──────────────────────
      const glow = new THREE.PointLight(0xFF9933, 0.35, 0.55);
      glow.position.set(xOff, topY + candleH + wickH + flameH * 0.5, 0);
      group.add(glow);
    }
  }

  // ── Digit shape helpers ──────────────────────────────────

  // Generate a THREE.Shape for each digit 0-9
  function _digitShape(d, S) {
    const w = S * 0.3;   // half-width
    const h = S * 0.5;   // half-height
    const t = S * 0.065; // stroke thickness
    const s = new THREE.Shape();

    switch (d) {
      case 0:
        _roundedRect(s, -w, -h, w * 2, h * 2, w * 0.6);
        // hole
        const h0 = new THREE.Path();
        _roundedRect(h0, -w + t, -h + t, (w - t) * 2, (h - t) * 2, w * 0.4);
        s.holes.push(h0);
        return s;
      case 1: {
        // Realistic "1": thick vertical bar + angled serif top-left + solid base
        const s1 = new THREE.Shape();
        const bw = w * 0.55;  // base half-width
        const sw = t * 0.9;   // stem half-width
        // Start bottom-left of base
        s1.moveTo(-bw, -h);
        s1.lineTo(bw, -h);
        s1.lineTo(bw, -h + t * 0.9);
        s1.lineTo(sw, -h + t * 0.9);
        // Right side of stem up
        s1.lineTo(sw, h);
        // Top — angled serif going left
        s1.lineTo(-sw, h);
        s1.lineTo(-w * 0.45, h - t * 1.2);
        s1.lineTo(-sw * 0.6, h - t * 1.2);
        // Left side of stem down
        s1.lineTo(-sw, h - t * 1.4);
        s1.lineTo(-sw, -h + t * 0.9);
        s1.lineTo(-bw, -h + t * 0.9);
        s1.closePath();
        return s1;
      }
      case 2: {
        // Realistic "2": curved top + diagonal middle + flat base
        const s2 = new THREE.Shape();
        // Start bottom-left, go right along base
        s2.moveTo(-w, -h);
        s2.lineTo(w, -h);
        // Right side up to base-top
        s2.lineTo(w, -h + t);
        // Inner base top — then diagonal up to right
        s2.lineTo(-w * 0.5, -h + t);
        // Diagonal stroke going up-right to the curve
        s2.lineTo(w - t, h * 0.15);
        // Right side — curve at top
        s2.quadraticCurveTo(w - t, h * 0.6, w * 0.4, h - t);
        // Top curve inner
        s2.quadraticCurveTo(-w * 0.1, h - t, -w + t, h * 0.45);
        // Left inner side down
        s2.lineTo(-w, h * 0.45);
        // Left outer curve up to top
        s2.quadraticCurveTo(-w, h, w * 0.1, h);
        // Top outer curve right
        s2.quadraticCurveTo(w, h, w, h * 0.35);
        // Outer right side — diagonal down-left
        s2.lineTo(-w * 0.15, -h + t);
        s2.lineTo(-w, -h + t);
        s2.closePath();
        return s2;
      }
      case 3:
        s.moveTo(-w, h);
        s.lineTo(w, h);
        s.lineTo(w, -h);
        s.lineTo(-w, -h);
        s.lineTo(-w, -h + t);
        s.lineTo(w - t, -h + t);
        s.lineTo(w - t, -t * 0.5);
        s.lineTo(-w * 0.3, -t * 0.5);
        s.lineTo(-w * 0.3, t * 0.5);
        s.lineTo(w - t, t * 0.5);
        s.lineTo(w - t, h - t);
        s.lineTo(-w, h - t);
        s.closePath();
        return s;
      case 4: {
        // Right vertical bar (full height)
        s.moveTo(w * 0.4, -h);
        s.lineTo(w * 0.4 + t, -h);
        s.lineTo(w * 0.4 + t, h);
        s.lineTo(w * 0.4, h);
        s.lineTo(w * 0.4, -h);
        // Horizontal bar + diagonal arm as separate sub-path
        const arm = new THREE.Shape();
        arm.moveTo(-w, -t * 0.1);
        arm.lineTo(w, -t * 0.1);
        arm.lineTo(w, -t * 0.1 + t);
        arm.lineTo(-w, -t * 0.1 + t);
        arm.closePath();
        const diag = new THREE.Shape();
        diag.moveTo(-w, -t * 0.1 + t);
        diag.lineTo(w * 0.4, h);
        diag.lineTo(w * 0.4 + t, h);
        diag.lineTo(-w + t, -t * 0.1 + t);
        diag.closePath();
        // Merge: draw the whole 4 as one connected path
        const s4 = new THREE.Shape();
        // Vertical right bar
        s4.moveTo(w * 0.35, -h);
        s4.lineTo(w * 0.35 + t, -h);
        s4.lineTo(w * 0.35 + t, h);
        s4.lineTo(w * 0.35, h);
        // Diagonal going up-left from the cross to top-left
        s4.lineTo(-w, t * 0.5);
        // Horizontal bar across
        s4.lineTo(-w, -t * 0.5);
        s4.lineTo(w * 0.35, -t * 0.5);
        s4.closePath();
        return s4;
      }
      case 5: {
        // ┌──────┐  top bar
        // │
        // ├──────┐  mid bar
        //        │
        // └──────┘  bottom bar
        const s5 = new THREE.Shape();
        // Outer path clockwise
        s5.moveTo(-w, h);           // top-left
        s5.lineTo(w, h);            // top-right
        s5.lineTo(w, h - t);        // top-right inner
        s5.lineTo(-w + t, h - t);   // back left on top bar
        s5.lineTo(-w + t, t * 0.5); // down to mid
        s5.lineTo(w, t * 0.5);      // mid-right
        s5.lineTo(w, -h);           // bottom-right
        s5.lineTo(-w, -h);          // bottom-left
        s5.lineTo(-w, -h + t);      // bottom-left inner
        s5.lineTo(w - t, -h + t);   // bottom bar inner right
        s5.lineTo(w - t, -t * 0.5); // up to mid inner
        s5.lineTo(-w, -t * 0.5);    // mid-left
        s5.closePath();
        return s5;
      }
      case 6: {
        // 6 = full left bar + bottom oval loop + top hook curving right
        const s6 = new THREE.Shape();
        // Outer: top curve + left side + bottom rounded + right side to mid
        s6.moveTo(w * 0.3, h);                     // top hook end
        s6.lineTo(w, h);
        s6.lineTo(w, h - t);
        s6.lineTo(-w + t, h - t);                  // across top inner
        // Left side down
        s6.lineTo(-w + t, -h + w * 0.3);
        // Bottom-left curve
        s6.quadraticCurveTo(-w + t, -h + t, -w * 0.1, -h + t);
        // Bottom across
        s6.lineTo(w * 0.1, -h + t);
        s6.quadraticCurveTo(w - t, -h + t, w - t, -h + w * 0.3);
        // Right side up to mid
        s6.lineTo(w - t, -t * 0.5);
        s6.lineTo(w, -t * 0.5);
        s6.lineTo(w, -h + w * 0.3);
        s6.quadraticCurveTo(w, -h, w * 0.1, -h);
        s6.lineTo(-w * 0.1, -h);
        s6.quadraticCurveTo(-w, -h, -w, -h + w * 0.3);
        // Left side all the way up
        s6.lineTo(-w, h);
        s6.closePath();
        // Hole in the bottom half
        const h6 = new THREE.Path();
        _roundedRect(h6, -w + t * 1.4, -h + t * 1.4, (w - t * 1.4) * 2, (h * 0.5 - t * 0.5) * 2, w * 0.15);
        s6.holes.push(h6);
        return s6;
      }
      case 7:
        s.moveTo(-w, h);
        s.lineTo(w, h);
        s.lineTo(w, h - t);
        s.lineTo(t * 0.5, -h);
        s.lineTo(-t * 0.5, -h);
        s.lineTo(w - t, h - t);
        s.lineTo(-w, h - t);
        s.closePath();
        return s;
      case 8:
        _roundedRect(s, -w, -h, w * 2, h * 2, w * 0.35);
        const h8a = new THREE.Path();
        _roundedRect(h8a, -w + t, t * 0.3, (w - t) * 2, h - t * 1.3, w * 0.2);
        const h8b = new THREE.Path();
        _roundedRect(h8b, -w + t, -h + t, (w - t) * 2, h - t * 1.3, w * 0.2);
        s.holes.push(h8a, h8b);
        return s;
      case 9: {
        // 9 = full right bar + top oval loop + bottom hook curving left
        // (mirror of 6, flipped vertically)
        const s9 = new THREE.Shape();
        // Start bottom-left hook
        s9.moveTo(-w * 0.3, -h);
        s9.lineTo(-w, -h);
        s9.lineTo(-w, -h + t);
        s9.lineTo(w - t, -h + t);
        // Right side up
        s9.lineTo(w - t, h - w * 0.3);
        // Top-right curve
        s9.quadraticCurveTo(w - t, h - t, w * 0.1, h - t);
        // Top across
        s9.lineTo(-w * 0.1, h - t);
        s9.quadraticCurveTo(-w + t, h - t, -w + t, h - w * 0.3);
        // Left side down to mid
        s9.lineTo(-w + t, t * 0.5);
        s9.lineTo(-w, t * 0.5);
        s9.lineTo(-w, h - w * 0.3);
        s9.quadraticCurveTo(-w, h, -w * 0.1, h);
        s9.lineTo(w * 0.1, h);
        s9.quadraticCurveTo(w, h, w, h - w * 0.3);
        // Right side all the way down
        s9.lineTo(w, -h);
        s9.closePath();
        // Hole in the top half
        const h9 = new THREE.Path();
        _roundedRect(h9, -w + t * 1.4, t * 0.3, (w - t * 1.4) * 2, (h * 0.5 - t * 0.5) * 2, w * 0.15);
        s9.holes.push(h9);
        return s9;
      }
      default:
        return null;
    }
  }

  function _roundedRect(shape, x, y, w, h, r) {
    r = Math.min(r, w / 2, h / 2);
    shape.moveTo(x + r, y);
    shape.lineTo(x + w - r, y);
    shape.quadraticCurveTo(x + w, y, x + w, y + r);
    shape.lineTo(x + w, y + h - r);
    shape.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
    shape.lineTo(x + r, y + h);
    shape.quadraticCurveTo(x, y + h, x, y + h - r);
    shape.lineTo(x, y + r);
    shape.quadraticCurveTo(x, y, x + r, y);
  }

  // ── gift ribbon (single ribbon + bow on side) ────────────
  // Every part here shares one material and this only gets built once
  // (not repeated N times), so we just merge all 6 parts straight into a
  // single mesh — 1 draw call instead of 6.
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

    const AH = root.CD.AddonHelpers;
    const parts = [];

    // horizontal ring — already in world space via its own curve points
    const hPts = [];
    for (let i = 0; i <= segs; i++) {
      const a = (i / segs) * Math.PI * 2;
      hPts.push(new THREE.Vector3(
        Math.cos(a) * (R + w * 0.25), midY, Math.sin(a) * (R + w * 0.25),
      ));
    }
    hPts.push(hPts[0].clone());
    parts.push({
      geometry: new THREE.TubeGeometry(new THREE.CatmullRomCurve3(hPts, true), segs, w * 0.52, 12, true),
      material: mat,
      matrix: new THREE.Matrix4(),
    });

    // bow on front — bow-group sits at (0, midY, R + w*0.3); bake that
    // offset directly into each part's world matrix.
    const bw = R * 0.07;
    const bowX = 0, bowY = midY, bowZ = R + w * 0.3;

    const makeLoopGeo = (side) => {
      const sh = new THREE.Shape();
      sh.moveTo(0, 0);
      sh.bezierCurveTo( side * w * 0.25,  w * 3.4,  side * w * 2.2,  w * 3.4,  side * w * 1.9, 0);
      sh.bezierCurveTo( side * w * 2.2, -w * 0.9,  side * w * 0.25, -w * 0.9, 0, 0);
      const geo = new THREE.ExtrudeGeometry(sh, {
        depth: bw * 0.42, bevelEnabled: true,
        bevelSize: bw * 0.07, bevelThickness: bw * 0.07, curveSegments: 20,
      });
      geo.center();
      return geo;
    };
    const dummy = new THREE.Object3D();
    const bakedMatrix = (px, py, pz, rz, sx, sy, sz) => {
      dummy.position.set(px, py, pz);
      dummy.rotation.set(0, 0, rz || 0);
      dummy.scale.set(sx == null ? 1 : sx, sy == null ? 1 : sy, sz == null ? 1 : sz);
      dummy.updateMatrix();
      return dummy.matrix.clone();
    };

    parts.push({
      geometry: makeLoopGeo(1), material: mat,
      matrix: bakedMatrix(bowX + bw * 1.3, bowY + bw * 0.1, bowZ + bw * 0.22, 0.18),
    });
    parts.push({
      geometry: makeLoopGeo(-1), material: mat,
      matrix: bakedMatrix(bowX - bw * 1.3, bowY + bw * 0.1, bowZ + bw * 0.22, -0.18),
    });
    parts.push({
      geometry: new THREE.SphereGeometry(bw * 0.5, 16, 16), material: mat,
      matrix: bakedMatrix(bowX, bowY, bowZ + bw * 0.26, 0, 1.0, 0.82, 0.68),
    });

    const makeTailGeo = (side) => {
      const pts = [];
      for (let t = 0; t <= 14; t++) {
        const u = t / 14;
        pts.push(new THREE.Vector3(
          side * (bw * 0.32 + u * bw * 0.45),
          -(u * H * 0.30),
          bw * 0.15 - u * bw * 0.08,
        ));
      }
      return new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 16, bw * 0.16, 8, false);
    };
    parts.push({ geometry: makeTailGeo(1),  material: mat, matrix: bakedMatrix(bowX, bowY, bowZ) });
    parts.push({ geometry: makeTailGeo(-1), material: mat, matrix: bakedMatrix(bowX, bowY, bowZ) });

    const merged = AH.mergeParts(parts);
    AH.placeInstances(group, merged, [new THREE.Matrix4()], true);
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
    const AH = root.CD.AddonHelpers;
    const wireMat = new THREE.MeshStandardMaterial({ color: 0xCCCCCC, metalness: 0.8 });
    const sparkMat = new THREE.MeshStandardMaterial({
      color: 0xFFFF00, emissive: 0xFFAA00, emissiveIntensity: 3,
    });
    const wireGeo = new THREE.CylinderGeometry(R * 0.006, R * 0.006, R * 0.5, 6);
    const sparkGeo = new THREE.SphereGeometry(R * 0.012, 6, 6);

    const wireMatrices = [];
    const sparkMatrices = [];
    for (let i = 0; i < 3; i++) {
      const a = (i / 3) * Math.PI * 2;
      const sx = Math.cos(a) * R * 0.35, sz = Math.sin(a) * R * 0.35;
      wireMatrices.push(new THREE.Matrix4().makeTranslation(sx, topY + R * 0.25, sz));

      for (let j = 0; j < 8; j++) {
        const sa = Math.random() * Math.PI * 2;
        const sr = R * (0.02 + Math.random() * 0.06);
        sparkMatrices.push(new THREE.Matrix4().makeTranslation(
          sx + Math.cos(sa) * sr,
          topY + R * (0.45 + Math.random() * 0.15),
          sz + Math.sin(sa) * sr,
        ));
      }
    }
    AH.instanceSimple(group, wireGeo, wireMat, wireMatrices, true);
    AH.instanceSimple(group, sparkGeo, sparkMat, sparkMatrices, false);
  }

  root.CD = root.CD || {};
  root.CD.CenterAddons = {
    buildCandles, buildGiftRibbon, buildSecretMessage, buildSparklers,
  };
})(window);