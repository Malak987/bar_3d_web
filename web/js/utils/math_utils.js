/**
 * ─────────────────────────────────────────────────────────────
 * math_utils.js — Small math helpers
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  const MathUtils = {
    /** Clamp v to [min, max] */
    clamp(v, min, max) {
      return v < min ? min : v > max ? max : v;
    },

    /** Smooth lerp(a, b, t) */
    lerp(a, b, t) {
      return a + (b - a) * t;
    },

    /** Deterministic pseudo-random (used for grass/sprinkle layouts) */
    seeded(i, salt) {
      const s = Math.sin(i * 12.9898 + (salt || 0)) * 43758.5453;
      return s - Math.floor(s);
    },
  };

  root.CD = root.CD || {};
  root.CD.MathUtils = MathUtils;
})(window);
