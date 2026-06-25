/** merge_geometries.js — small safe BufferGeometry merge helper. */
(function () {
  'use strict';
  if (typeof THREE === 'undefined' || THREE.mergeGeometries) return;

  THREE.mergeGeometries = function (geometries, useGroups) {
    if (!geometries || geometries.length === 0) return null;
    if (geometries.length === 1) return geometries[0];

    const merged = new THREE.BufferGeometry();
    let totalVertices = 0;
    let totalIndices = 0;
    let hasIndex = false;

    for (const g of geometries) {
      totalVertices += g.attributes.position.count;
      if (g.index) { hasIndex = true; totalIndices += g.index.count; }
      else totalIndices += g.attributes.position.count;
    }

    const positions = new Float32Array(totalVertices * 3);
    const normals = geometries[0].attributes.normal ? new Float32Array(totalVertices * 3) : null;
    const uvs = geometries[0].attributes.uv ? new Float32Array(totalVertices * 2) : null;
    const IndexArray = totalVertices > 65535 ? Uint32Array : Uint16Array;
    const indices = hasIndex ? new IndexArray(totalIndices) : null;

    let vOffset = 0;
    let pOffset = 0;
    let nOffset = 0;
    let uvOffset = 0;
    let iOffset = 0;

    for (let gi = 0; gi < geometries.length; gi++) {
      const g = geometries[gi];
      const vc = g.attributes.position.count;
      positions.set(g.attributes.position.array, pOffset);
      pOffset += g.attributes.position.array.length;
      if (normals) {
        if (g.attributes.normal) normals.set(g.attributes.normal.array, nOffset);
        nOffset += vc * 3;
      }
      if (uvs) {
        if (g.attributes.uv) uvs.set(g.attributes.uv.array, uvOffset);
        uvOffset += vc * 2;
      }
      const groupStart = iOffset;
      if (indices) {
        if (g.index) {
          const src = g.index.array;
          for (let i = 0; i < src.length; i++) indices[iOffset++] = src[i] + vOffset;
        } else {
          for (let i = 0; i < vc; i++) indices[iOffset++] = i + vOffset;
        }
      }
      if (useGroups) merged.addGroup(groupStart, iOffset - groupStart, gi);
      vOffset += vc;
    }

    merged.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    if (normals) merged.setAttribute('normal', new THREE.BufferAttribute(normals, 3));
    if (uvs) merged.setAttribute('uv', new THREE.BufferAttribute(uvs, 2));
    if (indices) merged.setIndex(new THREE.BufferAttribute(indices, 1));
    merged.computeBoundingSphere();
    return merged;
  };
})();
