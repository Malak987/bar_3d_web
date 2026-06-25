/**
 * performance.js — production performance helpers for the cake configurator.
 * Keeps the existing business flow intact and only tunes rendering/runtime behavior.
 */
(function (root) {
  'use strict';

  const CD = root.CD = root.CD || {};

  function isMobileLike() {
    const ua = navigator.userAgent || '';
    return /Android|iPhone|iPad|iPod|Mobile/i.test(ua) || (navigator.maxTouchPoints || 0) > 1 || window.innerWidth < 768;
  }

  function memoryTier() {
    const mem = navigator.deviceMemory || 4;
    if (mem <= 2) return 'low';
    if (mem <= 4) return 'mid';
    return 'high';
  }

  function profile() {
    const mobile = isMobileLike();
    const tier = memoryTier();
    const low = tier === 'low' || mobile;
    return {
      mobile,
      tier,
      low,
      dpr: Math.min(window.devicePixelRatio || 1, low ? 1.25 : 1.75),
      antialias: !low,
      shadowMapSize: low ? 512 : 1024,
      topCanvasSize: low ? 1024 : 1536,
      marbleSize: low ? 512 : 768,
      anisotropy: low ? 2 : 4,
      maxRenderMsWhenIdle: 250,
    };
  }

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
      if (child.isMesh || child.isInstancedMesh) child.frustumCulled = true;
    });
  }

  CD.Perf = { isMobileLike, memoryTier, profile, post, markStatic, enableCulling };
})(window);
