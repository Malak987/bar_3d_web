/**
 * ─────────────────────────────────────────────────────────────
 * addon_helpers.js — Shared utilities for addons
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  // Default colour per addon
  const DEFAULTS = {
    candles:            '#FF6B6B',
    giftRibbon:         '#D4A24A',
    bow:                '#D4A24A',
    secretMessage:      '#FFFFFF',
    sparklers:          '#FFD700',
    naturalFlowers:     '#FF1493',
    artificialFlowers:  '#FF80AB',
    babyFlower:         '#F8BBD0',
    butterflies:        '#9C27B0',
    fruits:             '#FF4444',
    babyHeartChocolate: '#3D1A0A',
    pearls:             '#FFFFFF',
    sprinkles:          '#FFFFFF',
    glitter:            '#FFD700',
    chocoDrip:          '#3D1A0A',
  };

  // category → bucket
  const CATEGORY = {
    candles:           'center',
    giftRibbon:        'center',
    secretMessage:     'center',
    sparklers:         'center',
    bow:               'edge',
    naturalFlowers:    'edge',
    artificialFlowers: 'edge',
    babyFlower:        'edge',
    butterflies:       'edge',
    fruits:            'edge',
    babyHeartChocolate: 'edge',
    pearls:            'fullring',
    chocoDrip:         'fullring',
    sprinkles:         'surface',
    glitter:           'surface',
  };

  function colorFor(cfg, id) {
    if (cfg.addonColors && cfg.addonColors[id]) return cfg.addonColors[id];
    return DEFAULTS[id] || '#FFFFFF';
  }

  function bucketize(ids) {
    const out = { center: [], edge: [], fullring: [], surface: [] };
    for (const id of ids) {
      const b = CATEGORY[id] || 'edge';
      out[b].push(id);
    }
    return out;
  }

  root.CD = root.CD || {};
  root.CD.AddonHelpers = { colorFor, bucketize, DEFAULTS, CATEGORY };
})(window);
