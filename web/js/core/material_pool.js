/**
 * ─────────────────────────────────────────────────────────────
 * material_pool.js
 *
 * MeshPhysicalMaterial creation is expensive — pool by
 * (color, roughness, metalness, clearcoat) to reuse across
 * piping rings, addons, etc.
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  class MaterialPool {
    constructor(lowPower) {
      this.cache = new Map();
      this.lowPower = !!lowPower;
    }

    /**
     * @param {string} colorHex
     * @param {{ roughness?:number, metalness?:number,
     *           clearcoat?:number, clearcoatRoughness?:number,
     *           vertexColors?:boolean }} opts
     */
    physical(colorHex, opts) {
      opts = opts || {};
      // On mobile/low-tier: force clearcoat=0. three.js only compiles the
      // USE_CLEARCOAT shader branch (extra Fresnel + specular lobe per
      // fragment) when clearcoat > 0, so this is a real shader-complexity
      // cut, not just a visual tweak — applied to every piping/addon/body
      // material since they all funnel through this pool.
      const clearcoat = this.lowPower ? 0 : (opts.clearcoat ?? 0.4);
      const clearcoatRoughness = this.lowPower ? 0 : (opts.clearcoatRoughness ?? 0.2);
      const key = [
        colorHex || 'vc',
        opts.roughness ?? 0.3,
        opts.metalness ?? 0.05,
        clearcoat,
        clearcoatRoughness,
        opts.vertexColors ? 1 : 0,
      ].join('|');

      let m = this.cache.get(key);
      if (!m) {
        m = new THREE.MeshPhysicalMaterial({
          color:    colorHex ? new THREE.Color(colorHex) : 0xffffff,
          roughness: opts.roughness ?? 0.3,
          metalness: opts.metalness ?? 0.05,
          clearcoat,
          clearcoatRoughness,
          vertexColors: !!opts.vertexColors,
        });
        this.cache.set(key, m);
      }
      return m;
    }

    /** Standard material (used for emissive accents) */
    standard(colorHex, opts) {
      opts = opts || {};
      const key = ['std', colorHex,
        opts.emissive || '',
        opts.emissiveIntensity ?? 0,
        opts.metalness ?? 0,
        opts.roughness ?? 0.5,
      ].join('|');
      let m = this.cache.get(key);
      if (!m) {
        m = new THREE.MeshStandardMaterial({
          color: new THREE.Color(colorHex),
          emissive: opts.emissive ? new THREE.Color(opts.emissive) : 0x000000,
          emissiveIntensity: opts.emissiveIntensity ?? 0,
          metalness: opts.metalness ?? 0,
          roughness: opts.roughness ?? 0.5,
        });
        this.cache.set(key, m);
      }
      return m;
    }

    dispose() {
      for (const m of this.cache.values()) m.dispose();
      this.cache.clear();
    }
  }

  root.CD = root.CD || {};
  root.CD.MaterialPool = MaterialPool;
})(window);