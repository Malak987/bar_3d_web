/**
 * ─────────────────────────────────────────────────────────────
 * color_utils.js — Color/gradient helpers
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  const _tmp = new THREE.Color();

  const ColorUtils = {
    /** "#RRGGBB" → THREE.Color */
    hex(h) {
      return new THREE.Color(h);
    },

    /**
     * Sample a multi-stop gradient.
     * @param  {string[]} stops  e.g. ['#FFF', '#F00', '#000']
     * @param  {number}   count  1..3 — how many stops are active
     * @param  {number}   t      0..1 — interp parameter
     * @return {THREE.Color}
     */
    sampleGradient(stops, count, t) {
      const c0 = new THREE.Color(stops[0]);
      if (count <= 1) return c0;

      const c1 = new THREE.Color(stops[1] || stops[0]);
      if (count === 2) return c0.lerp(c1, t);

      const c2 = new THREE.Color(stops[2] || stops[1] || stops[0]);
      return t < 0.5
        ? c0.lerp(c1, t * 2)
        : c1.lerp(c2, (t - 0.5) * 2);
    },

    /** Same as sampleGradient but returns hex string */
    sampleGradientHex(stops, count, t) {
      return '#' + ColorUtils.sampleGradient(stops, count, t).getHexString();
    },

    /** Perceived luminance < 0.5 */
    isDark(color) {
      return color.r * 0.299 + color.g * 0.587 + color.b * 0.114 < 0.5;
    },
  };

  root.CD = root.CD || {};
  root.CD.ColorUtils = ColorUtils;
})(window);
