/** disposal.js — safely dispose THREE resources, with pool-preservation hooks. */
(function (root) {
  'use strict';

  function disposeTexture(tex, seen) {
    if (!tex || seen.has(tex)) return;
    seen.add(tex);
    if (tex.dispose) tex.dispose();
  }

  function disposeMaterial(mat, opts, seen) {
    opts = opts || {}; seen = seen || new Set();
    if (!mat) return;
    if (Array.isArray(mat)) { mat.forEach((m) => disposeMaterial(m, opts, seen)); return; }
    if (opts.keepMaterial && opts.keepMaterial(mat)) return;
    const textureKeys = ['map', 'alphaMap', 'aoMap', 'bumpMap', 'normalMap', 'roughnessMap', 'metalnessMap', 'emissiveMap', 'envMap', 'lightMap', 'displacementMap'];
    if (!(mat.userData && mat.userData.keepTextureMaps)) {
      for (const key of textureKeys) if (mat[key]) disposeTexture(mat[key], seen);
    }
    if (mat.dispose) mat.dispose();
  }

  function disposeObject(obj, opts) {
    if (!obj) return;
    opts = opts || {};
    const seenTex = new Set();
    obj.traverse((c) => {
      if (c.isMesh || c.isInstancedMesh || c.isLine || c.isPoints) {
        if (c.geometry && !(opts.keepGeometry && opts.keepGeometry(c.geometry))) c.geometry.dispose();
        disposeMaterial(c.material, opts, seenTex);
      }
    });
    if (obj.parent) obj.parent.remove(obj);
  }

  root.CD = root.CD || {};
  root.CD.Disposal = { disposeMaterial, disposeObject };
})(window);
