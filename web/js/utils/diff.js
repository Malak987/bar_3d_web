/**
 * ─────────────────────────────────────────────────────────────
 * diff.js — Compute which sub-system needs to be rebuilt
 *
 * Returns a set of "dirty flags" so the renderer only does the
 * work that actually changed. This is the single biggest perf
 * win — sliding a piping-size slider should NOT rebuild the
 * cake body / addons / plate.
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  const FLAGS = {
    BODY:   'body',    // cake cylinder + top cap + gradient
    PIPING: 'piping',  // piping rings + threads/wave/...
    TOP:    'top',     // text + image on top
    ADDONS: 'addons',  // candles / flowers / etc.
    PLATE:  'plate',   // pedestal
    TRANSFORM: 'transform', // scale only
  };

  // Which config keys feed each subsystem
  const KEYS = {
    body: [
      'gradientColorCount', 'colors',
      'cakeRadius', 'cakeHeight',
      'roughness', 'metalness', 'clearcoat',
      'baseFlavor',
    ],
    piping: [
      'pipingType', 'pipingColor', 'pipingColorCount', 'pipingColors',
      'pipingPlacement', 'pipingSize',
      'cakeRadius', 'cakeHeight',
      // a top with text/image hides full-coverage top — so depend on those:
      'text', 'topImage', 'selectedAddons',
    ],
    top: [
      'text', 'textColor', 'textPosition', 'textSize', 'fontStyle',
      'topImage', 'imageScale',
      'colors', 'gradientColorCount',
      'pipingColor',
      'cakeRadius', 'cakeHeight',
      'selectedAddons',
    ],
    addons: [
      'selectedAddons', 'addonColors',
      'cakeRadius', 'cakeHeight',
      'secretMessageText',
      'candleDigits',
    ],
    plate: [
      'cakeRadius', 'plateColor',
    ],
    transform: [
      'cakeScale',
    ],
  };

  /**
   * Compute dirty flags between two configs.
   * If `prev` is null, everything is dirty.
   */
  function diff(prev, next) {
    if (!prev) {
      return new Set(Object.values(FLAGS));
    }
    const dirty = new Set();
    for (const flag of Object.keys(KEYS)) {
      for (const key of KEYS[flag]) {
        if (!_eq(prev[key], next[key])) { dirty.add(FLAGS[flag.toUpperCase()] || flag); break; }
      }
    }
    return dirty;
  }

  function _eq(a, b) {
    if (a === b) return true;
    if (Array.isArray(a) && Array.isArray(b)) {
      if (a.length !== b.length) return false;
      for (let i = 0; i < a.length; i++) {
        if (!_eq(a[i], b[i])) return false;
      }
      return true;
    }
    if (a && b && typeof a === 'object' && typeof b === 'object') {
      const ka = Object.keys(a), kb = Object.keys(b);
      if (ka.length !== kb.length) return false;
      for (const k of ka) if (!_eq(a[k], b[k])) return false;
      return true;
    }
    return false;
  }

  root.CD = root.CD || {};
  root.CD.Diff = { diff, FLAGS };
})(window);
