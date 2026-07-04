/**
 * performance.js — GPU-aware performance profiling for the cake configurator.
 *
 * Features:
 *   • Real GPU detection via WebGL debug extension (WEBGL_debug_renderer_info)
 *   • 3-tier quality classification: low / mid / high
 *   • Adaptive DPR, shadow map, texture sizes, polygon budgets
 *   • Progressive quality: starts fast, ramps up after first frame
 *   • Scene complexity budget (max triangles / draw calls)
 */
(function (root) {
  'use strict';

  const CD = root.CD = root.CD || {};

  // ── Device detection ──────────────────────────────────────
  function isMobileLike() {
    const ua = navigator.userAgent || '';
    return /Android|iPhone|iPad|iPod|Mobile/i.test(ua)
      || (navigator.maxTouchPoints || 0) > 1
      || window.innerWidth < 768;
  }

  function memoryTier() {
    const mem = navigator.deviceMemory || 4;
    if (mem <= 2) return 'low';
    if (mem <= 4) return 'mid';
    return 'high';
  }

  // ── GPU detection ─────────────────────────────────────────
  function detectGPU() {
    try {
      const c = document.createElement('canvas');
      const gl = c.getContext('webgl') || c.getContext('experimental-webgl');
      if (!gl) return { supported: false, renderer: '', vendor: '', tier: 'low' };

      const ext = gl.getExtension('WEBGL_debug_renderer_info');
      const renderer = ext ? gl.getParameter(ext.UNMASKED_RENDERER_WEBGL) : '';
      const vendor = ext ? gl.getParameter(ext.UNMASKED_VENDOR_WEBGL) : '';
      const maxTex = gl.getParameter(gl.MAX_TEXTURE_SIZE) || 4096;
      const maxVary = gl.getParameter(gl.MAX_VARYING_VECTORS) || 8;

      const r = (renderer || '').toLowerCase();
      const isLowGPU =
        r.includes('swiftshader') || r.includes('llvmpipe') ||
        r.includes('software') || r.includes('mesa') ||
        r.includes('microsoft basic') || r.includes('google') ||
        maxTex < 4096 || maxVary < 12;

      const isHighGPU =
        r.includes('nvidia') || r.includes('geforce') ||
        r.includes('radeon') || r.includes('apple m') ||
        r.includes('apple gpu') || r.includes('adreno 7') ||
        r.includes('adreno 6') || r.includes('mali-g7') ||
        maxTex >= 16384;

      let tier = 'mid';
      if (isLowGPU) tier = 'low';
      else if (isHighGPU) tier = 'high';

      return { supported: true, renderer, vendor, tier, maxTex, maxVary };
    } catch (_) {
      return { supported: false, renderer: '', vendor: '', tier: 'low' };
    }
  }

  // ── WebGL support check ───────────────────────────────────
  function isWebGLSupported() {
    try {
      const c = document.createElement('canvas');
      const gl = c.getContext('webgl2') || c.getContext('webgl') || c.getContext('experimental-webgl');
      return !!gl;
    } catch (_) { return false; }
  }

  // ── Cached GPU info ───────────────────────────────────────
  let _gpuCache = null;
  function gpu() {
    if (!_gpuCache) _gpuCache = detectGPU();
    return _gpuCache;
  }

  // ── Profile (called once at scene creation) ───────────────
  function profile() {
    const mobile = isMobileLike();
    const memTier = memoryTier();
    const gpuInfo = gpu();

    // Combine memory + GPU + mobile into final tier
    let tier;
    if (!gpuInfo.supported || gpuInfo.tier === 'low' || memTier === 'low') {
      tier = 'low';
    } else if (gpuInfo.tier === 'high' && memTier === 'high' && !mobile) {
      tier = 'high';
    } else {
      tier = 'mid';
    }

    const low = tier === 'low';
    const high = tier === 'high';

    return {
      mobile,
      tier,
      low,
      high,
      gpuRenderer: gpuInfo.renderer,
      webglSupported: gpuInfo.supported,

      // DPR: start low for fast first frame, ramp up later
      dpr: low ? 1.0 : (mobile ? 1.15 : 1.3),
      dprFinal: low ? 1.0 : Math.min(window.devicePixelRatio || 1, high ? 2.0 : 1.6),

      // Rendering
      antialias: !low,
      shadowMapSize: low ? 0 : (high ? 1024 : 512),

      // Textures
      topCanvasSize: low ? 768 : (high ? 1536 : 1024),
      marbleSize: low ? 256 : (high ? 768 : 512),
      anisotropy: low ? 1 : (high ? 4 : 2),

      // Geometry budgets
      bodyRadialSegs: low ? 32 : (high ? 64 : 48),
      bodyHeightSegs: low ? 16 : (high ? 32 : 24),
      capRadialSegs:  low ? 32 : (high ? 64 : 48),

      // Scene budget
      maxTriangles: low ? 50000 : (high ? 250000 : 120000),
      maxDrawCalls: low ? 40 : (high ? 150 : 80),
      maxRenderMsWhenIdle: 250,
    };
  }

  // ── PostMessage helper ────────────────────────────────────
  function post(type, payload) {
    const message = { source: 'bar3dcake', type, payload: payload || {} };
    try { root.parent && root.parent.postMessage(message, '*'); } catch (_) {}
    try { root.postMessage(message, '*'); } catch (_) {}
    try { root.dispatchEvent(new CustomEvent('bar3dcake:' + type, { detail: payload || {} })); } catch (_) {}
  }

  function markStatic(obj) {
    if (!obj) return obj;
    obj.matrixAutoUpdate = false;
    obj.updateMatrix();
    return obj;
  }

  function enableCulling(obj) {
    if (!obj) return;
    obj.traverse((child) => {
      if (child.isMesh || child.isInstancedMesh || child.isLine || child.isPoints) {
        if (child.isInstancedMesh && typeof child.computeBoundingSphere === 'function') {
          child.computeBoundingSphere();
        } else if (child.geometry && !child.geometry.boundingSphere && typeof child.geometry.computeBoundingSphere === 'function') {
          child.geometry.computeBoundingSphere();
        }
        child.frustumCulled = true;
      }
    });
  }

  CD.Perf = {
    isMobileLike, memoryTier, detectGPU, gpu, isWebGLSupported,
    profile, post, markStatic, enableCulling,
  };
})(window);
