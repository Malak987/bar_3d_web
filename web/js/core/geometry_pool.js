/**
 * ─────────────────────────────────────────────────────────────
 * geometry_pool.js
 *
 * Each (type, size) pair is built ONCE and reused everywhere.
 * Heart/Shell/Rose etc. carry hundreds of vertices — caching
 * them eliminates the worst frame-time spikes during rebuilds.
 * ─────────────────────────────────────────────────────────────
 */
(function (root) {
  'use strict';

  class GeometryPool {
    constructor() { this.cache = new Map(); }

    /** Get a cached geometry, or compute & cache it via `factory`. */
    get(key, factory) {
      let g = this.cache.get(key);
      if (!g) { g = factory(); this.cache.set(key, g); }
      return g;
    }

    /** Dispose every cached geometry */
    dispose() {
      for (const g of this.cache.values()) g.dispose();
      this.cache.clear();
    }
  }

  root.CD = root.CD || {};
  root.CD.GeometryPool = GeometryPool;
})(window);
