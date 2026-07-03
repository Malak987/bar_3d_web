/**
 * ─────────────────────────────────────────────────────────────
 * config_normalizer.js — Coerce raw config from Dart
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  const DEFAULTS = {
    gradientColorCount: 1,
    colors: ['#f5efe2', '#fcd5ce', '#ec4f8c'],
    pipingType:        'openStar',
    pipingColor:       '#ffffff',
    pipingColorCount:  1,
    pipingColors:      ['#ffffff', '#fcd5ce', '#ec4f8c'],
    pipingPlacement:   'border',
    pipingSize:        1,
    text:              '',
    textColor:         '#6e1423',
    textPosition:      'center',
    textSize:          1,
    fontStyle:         'normal',
    imageScale:        0.8,
    topImage:          null,
    autoRotate:        true,
    cakeScale:         1,
    cakeHeight:        0.42,
    cakeRadius:        0.78,
    plateColor:        '#c9a227',
    roughness:         0.3,
    metalness:         0.05,
    clearcoat:         0.4,
    selectedAddons:    [],
    addonColors:       {},
    secretMessageText: '',
    candleDigits:      [],
  };

  function normalize(input) {
    const cfg = input || {};

    // Normalize pipingType against formatting / casing / alias mismatches
    const rawType = String(cfg.pipingType || DEFAULTS.pipingType).trim();
    let normType = DEFAULTS.pipingType;
    if (rawType.toLowerCase() === 'none' || rawType === 'بدون') {
      normType = 'none';
    } else {
      const typeMap = {
        'openstar': 'openStar', 'open_star': 'openStar', 'open star': 'openStar', 'star': 'openStar',
        'closedstar': 'closedStar', 'closed_star': 'closedStar', 'closed star': 'closedStar',
        'dropflower': 'dropFlower', 'drop_flower': 'dropFlower', 'drop flower': 'dropFlower', 'flower': 'dropFlower',
        'basketweave': 'basketWeave', 'basket_weave': 'basketWeave', 'basket weave': 'basketWeave', 'basket': 'basketWeave',
        'frenchlace': 'frenchLace', 'french_lace': 'frenchLace', 'french lace': 'frenchLace', 'lace': 'frenchLace',
        'thinline': 'thinLine', 'thin_line': 'thinLine', 'thin line': 'thinLine', 'line': 'thinLine',
        'round': 'round', 'sphere': 'sphere', 'rose': 'rose', 'leaf': 'leaf', 'shell': 'shell',
        'wave': 'wave', 'threads': 'threads', 'grass': 'grass', 'heart': 'heart'
      };
      normType = typeMap[rawType.toLowerCase()] || typeMap[rawType] || rawType || DEFAULTS.pipingType;
    }

    // Normalize pipingPlacement
    const rawPlacement = String(cfg.pipingPlacement || DEFAULTS.pipingPlacement).trim().toLowerCase();
    let normPlacement = 'border';
    if (rawPlacement === 'full' || rawPlacement === 'all' || rawPlacement === 'complete') normPlacement = 'full';
    else if (rawPlacement === 'edges' || rawPlacement === 'both' || rawPlacement === 'double') normPlacement = 'edges';

    // Normalize pipingSize: handle absolute sizes sent by Dart (e.g. 0.015) vs multiplier (1.0)
    const rawSize = Number(cfg.pipingSize ?? DEFAULTS.pipingSize);
    let normSize = DEFAULTS.pipingSize;
    if (rawSize > 0 && rawSize <= 0.25) {
      // 0.015 corresponds to standard size 1.0
      normSize = Math.max(0.4, Math.min(3.0, rawSize / 0.015));
    } else if (rawSize > 0) {
      normSize = rawSize;
    }

    return {
      gradientColorCount: Number(cfg.gradientColorCount ?? DEFAULTS.gradientColorCount),
      colors:             Array.isArray(cfg.colors)        ? cfg.colors.slice()        : DEFAULTS.colors.slice(),
      pipingType:         normType,
      pipingColor:        cfg.pipingColor       || DEFAULTS.pipingColor,
      pipingColorCount:   Number(cfg.pipingColorCount ?? DEFAULTS.pipingColorCount),
      pipingColors:       Array.isArray(cfg.pipingColors)  ? cfg.pipingColors.slice()  : DEFAULTS.pipingColors.slice(),
      pipingPlacement:    normPlacement,
      pipingSize:         normSize,
      text:               cfg.text              || DEFAULTS.text,
      textColor:          cfg.textColor         || DEFAULTS.textColor,
      textPosition:       cfg.textPosition      || DEFAULTS.textPosition,
      textSize:           Math.max(1, Number(cfg.textSize ?? DEFAULTS.textSize)),
      fontStyle:          cfg.fontStyle         || DEFAULTS.fontStyle,
      imageScale:         Number(cfg.imageScale ?? DEFAULTS.imageScale),
      topImage:           cfg.topImage          || DEFAULTS.topImage,
      autoRotate:         Boolean(cfg.autoRotate ?? DEFAULTS.autoRotate),
      cakeScale:          Number(cfg.cakeScale ?? DEFAULTS.cakeScale),
      cakeHeight:         Number(cfg.cakeHeight ?? DEFAULTS.cakeHeight),
      cakeRadius:         Number(cfg.cakeRadius ?? DEFAULTS.cakeRadius),
      plateColor:         cfg.plateColor || DEFAULTS.plateColor,
      roughness:          Number(cfg.roughness ?? DEFAULTS.roughness),
      metalness:          Number(cfg.metalness ?? DEFAULTS.metalness),
      clearcoat:          Number(cfg.clearcoat ?? DEFAULTS.clearcoat),
      selectedAddons:     Array.isArray(cfg.selectedAddons) ? cfg.selectedAddons.slice() : [],
      addonColors:        (cfg.addonColors && typeof cfg.addonColors === 'object')
                            ? Object.assign({}, cfg.addonColors) : {},
      secretMessageText:  String(cfg.secretMessageText || ''),
      candleDigits:       Array.isArray(cfg.candleDigits) ? cfg.candleDigits.slice() : [],
    };
  }

  root.CD = root.CD || {};
  root.CD.Config = { normalize, DEFAULTS };
})(window);
