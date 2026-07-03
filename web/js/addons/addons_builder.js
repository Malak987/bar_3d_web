/**
 * ─────────────────────────────────────────────────────────────
 * addons_builder.js — Routes each selected addon to its builder
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  const C = root.CD;

  function build(group, cfg, R, H, baseY) {
    const ids = cfg.selectedAddons;
    if (!ids || ids.length === 0) return;

    // bow / giftRibbon + full coverage → force edges
    const hasRibbon = ids.indexOf('bow') !== -1 || ids.indexOf('giftRibbon') !== -1;
    if (hasRibbon && cfg.pipingPlacement === 'full') {
      cfg.pipingPlacement = 'edges';
    }

    const topY = baseY + H;
    const buckets = C.AddonHelpers.bucketize(ids);

    // 1. surface
    for (const id of buckets.surface) {
      const col = C.AddonHelpers.colorFor(cfg, id);
      if (id === 'sprinkles') C.SurfaceAddons.buildSprinkles(group, R, topY, col);
      if (id === 'glitter')   C.SurfaceAddons.buildGlitter  (group, R, topY, col);
    }

    // 2. full-ring (pearls, chocoDrip)
    for (const id of buckets.fullring) {
      const col = C.AddonHelpers.colorFor(cfg, id);
      if (id === 'pearls')    C.SurfaceAddons.buildPearlRing(group, R, topY, col);
      if (id === 'chocoDrip') C.SurfaceAddons.buildChocoDrip(group, R, H, baseY, col);
    }

    // 3. edge (split angular arc per addon)
    const eCount = buckets.edge.length;
    for (let i = 0; i < eCount; i++) {
      const id  = buckets.edge[i];
      const col = C.AddonHelpers.colorFor(cfg, id);
      const sa  = (i / eCount) * Math.PI * 2;
      const arc = (Math.PI * 2) / eCount;

      switch (id) {
        case 'naturalFlowers':     C.EdgeAddons.buildNaturalFlowers    (group, R, topY, col, sa, arc); break;
        case 'artificialFlowers':  C.EdgeAddons.buildArtificialFlowers (group, R, topY, col, sa, arc); break;
        case 'babyFlower':         C.EdgeAddons.buildBabyFlower        (group, R, topY, col, sa, arc); break;
        case 'butterflies':        C.EdgeAddons.buildButterflies       (group, R, topY, col, sa, arc); break;
        case 'fruits':             C.EdgeAddons.buildFruits            (group, R, topY, sa, arc);       break;
        case 'babyHeartChocolate': C.EdgeAddons.buildBabyHearts        (group, R, topY, col, sa, arc); break;
        case 'bow':                C.EdgeAddons.buildBows              (group, R, H, baseY, col);      break;
      }
    }

    // 4. center
    for (const id of buckets.center) {
      const col = C.AddonHelpers.colorFor(cfg, id);
      if (id === 'candles')       C.CenterAddons.buildCandles      (group, R, topY, col, cfg);
      if (id === 'giftRibbon')    C.CenterAddons.buildGiftRibbon   (group, R, H, baseY, col);
      if (id === 'secretMessage') C.CenterAddons.buildSecretMessage(group, R, topY);
      if (id === 'sparklers')     C.CenterAddons.buildSparklers    (group, R, topY);
    }
  }

  root.CD = root.CD || {};
  root.CD.AddonsBuilder = { build };
})(window);
