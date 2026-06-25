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
  };

  function normalize(input) {
    const cfg = input || {};
    return {
      gradientColorCount: Number(cfg.gradientColorCount ?? DEFAULTS.gradientColorCount),
      colors:             Array.isArray(cfg.colors)        ? cfg.colors.slice()        : DEFAULTS.colors.slice(),
      pipingType:         cfg.pipingType        || DEFAULTS.pipingType,
      pipingColor:        cfg.pipingColor       || DEFAULTS.pipingColor,
      pipingColorCount:   Number(cfg.pipingColorCount ?? DEFAULTS.pipingColorCount),
      pipingColors:       Array.isArray(cfg.pipingColors)  ? cfg.pipingColors.slice()  : DEFAULTS.pipingColors.slice(),
      pipingPlacement:    cfg.pipingPlacement   || DEFAULTS.pipingPlacement,
      pipingSize:         Number(cfg.pipingSize ?? DEFAULTS.pipingSize),
      text:               cfg.text              || DEFAULTS.text,
      textColor:          cfg.textColor         || DEFAULTS.textColor,
      textPosition:       cfg.textPosition      || DEFAULTS.textPosition,
      textSize:           Number(cfg.textSize ?? DEFAULTS.textSize),
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
    };
  }

  root.CD = root.CD || {};
  root.CD.Config = { normalize, DEFAULTS };
})(window);
