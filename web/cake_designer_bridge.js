/**
 * cake_designer_bridge.js — Refactored for performance & readability
 *
 * KEY IMPROVEMENTS over original:
 *  1. OrbitControls replaced with THREE.js's own (loaded via importmap / CDN).
 *     Falls back to a minimal inline version when unavailable.
 *  2. Geometry cache is instance-scoped and cleared on rebuild — no stale refs.
 *  3. Addon builders are each in a dedicated, clearly-named method.
 *  4. buildPipingSystem broken into small helpers; placement logic is declarative.
 *  5. Marble texture created once per page-load (static), not per instance.
 *  6. Shadow map resolution configurable; defaults to 1024 for mobile perf.
 *  7. updateConfig debounce is 60 ms (good enough; avoids thrashing).
 *  8. dispose() is thorough: clears ALL timers, removes ALL listeners.
 *  9. withContainerRetry uses exponential-backoff up to 5 s.
 * 10. All magic numbers extracted to named constants at the top of the class.
 */

'use strict';

// ════════════════════════════════════════════════════════════════════
// Guard — THREE must be loaded before this file
// ════════════════════════════════════════════════════════════════════
if (typeof THREE === 'undefined') {
  console.error('[CakeDesigner] THREE.js is not loaded. Add the <script> tag first.');
}

// ════════════════════════════════════════════════════════════════════
// Minimal inline OrbitControls (only loaded when THREE.OrbitControls
// is not already available via the add-ons script)
// ════════════════════════════════════════════════════════════════════
(function injectOrbitControls() {
  if (typeof THREE === 'undefined' || THREE.OrbitControls) return;

  THREE.OrbitControls = function (camera, domElement) {
    this.camera      = camera;
    this.domElement  = domElement;
    this.target      = new THREE.Vector3();
    this.enableDamping   = true;
    this.dampingFactor   = 0.05;
    this.minDistance     = 1.5;
    this.maxDistance     = 7.0;
    this.maxPolarAngle   = Math.PI * 0.75;
    this.autoRotate      = false;
    this.autoRotateSpeed = 2.0;

    var scope   = this;
    var sph     = new THREE.Spherical();
    var sphD    = new THREE.Spherical();
    var scale   = 1;
    var panOff  = new THREE.Vector3();
    var STATE   = { NONE: -1, ROTATE: 0, DOLLY: 1 };
    var state   = STATE.NONE;
    var EPS     = 1e-6;
    var rStart  = new THREE.Vector2();
    var rEnd    = new THREE.Vector2();
    var rDelta  = new THREE.Vector2();
    var dStart  = new THREE.Vector2();
    var dEnd    = new THREE.Vector2();
    var dDelta  = new THREE.Vector2();

    // ── Update ──────────────────────────────────────────────────────
    this.update = (function () {
      var offset   = new THREE.Vector3();
      var quat     = new THREE.Quaternion().setFromUnitVectors(camera.up, new THREE.Vector3(0, 1, 0));
      var quatInv  = quat.clone().invert();
      var lastPos  = new THREE.Vector3();

      return function update() {
        var pos = scope.camera.position;
        offset.copy(pos).sub(scope.target);
        offset.applyQuaternion(quat);
        sph.setFromVector3(offset);

        if (scope.autoRotate && state === STATE.NONE) {
          sphD.theta -= (2 * Math.PI / 60 / 60) * scope.autoRotateSpeed;
        }
        if (scope.enableDamping) {
          sph.theta += sphD.theta * scope.dampingFactor;
          sph.phi   += sphD.phi   * scope.dampingFactor;
        } else {
          sph.theta += sphD.theta;
          sph.phi   += sphD.phi;
        }

        sph.phi    = Math.max(EPS, Math.min(Math.PI - EPS, sph.phi));
        sph.radius *= scale;
        sph.radius  = Math.max(scope.minDistance, Math.min(scope.maxDistance, sph.radius));

        scope.target.add(panOff);
        offset.setFromSpherical(sph);
        offset.applyQuaternion(quatInv);
        pos.copy(scope.target).add(offset);
        scope.camera.lookAt(scope.target);

        if (scope.enableDamping) {
          sphD.theta *= 1 - scope.dampingFactor;
          sphD.phi   *= 1 - scope.dampingFactor;
          panOff.multiplyScalar(1 - scope.dampingFactor);
        } else {
          sphD.set(0, 0, 0);
          panOff.set(0, 0, 0);
        }
        scale = 1;

        if (lastPos.distanceToSquared(scope.camera.position) > EPS) {
          lastPos.copy(scope.camera.position);
          return true;
        }
        return false;
      };
    })();

    // ── Mouse ───────────────────────────────────────────────────────
    function onMouseDown(e) {
      if (e.button === 0) { state = STATE.ROTATE; rStart.set(e.clientX, e.clientY); }
      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup',   onMouseUp);
    }
    function onMouseMove(e) {
      if (state !== STATE.ROTATE) return;
      rEnd.set(e.clientX, e.clientY);
      rDelta.subVectors(rEnd, rStart);
      var h = domElement.clientHeight;
      sphD.theta -= (2 * Math.PI * rDelta.x) / h;
      sphD.phi   -= (2 * Math.PI * rDelta.y) / h;
      rStart.copy(rEnd);
    }
    function onMouseUp() {
      state = STATE.NONE;
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup',   onMouseUp);
    }
    function onWheel(e) {
      scale *= e.deltaY < 0 ? (1 / 0.95) : 0.95;
    }

    // ── Touch ───────────────────────────────────────────────────────
    var touchDist0 = 0;
    function onTouchStart(e) {
      if (e.touches.length === 1) {
        state = STATE.ROTATE;
        rStart.set(e.touches[0].pageX, e.touches[0].pageY);
      } else if (e.touches.length === 2) {
        state = STATE.DOLLY;
        var dx = e.touches[0].pageX - e.touches[1].pageX;
        var dy = e.touches[0].pageY - e.touches[1].pageY;
        touchDist0 = Math.sqrt(dx * dx + dy * dy);
      }
    }
    function onTouchMove(e) {
      e.preventDefault();
      if (state === STATE.ROTATE && e.touches.length === 1) {
        rEnd.set(e.touches[0].pageX, e.touches[0].pageY);
        rDelta.subVectors(rEnd, rStart);
        var h = domElement.clientHeight;
        sphD.theta -= (2 * Math.PI * rDelta.x) / h;
        sphD.phi   -= (2 * Math.PI * rDelta.y) / h;
        rStart.copy(rEnd);
      } else if (state === STATE.DOLLY && e.touches.length === 2) {
        var dx   = e.touches[0].pageX - e.touches[1].pageX;
        var dy   = e.touches[0].pageY - e.touches[1].pageY;
        var dist = Math.sqrt(dx * dx + dy * dy);
        scale   *= dist > touchDist0 ? (1 / 0.95) : 0.95;
        touchDist0 = dist;
      }
    }
    function onTouchEnd() { state = STATE.NONE; }

    domElement.addEventListener('mousedown',   onMouseDown);
    domElement.addEventListener('wheel',       onWheel, { passive: true });
    domElement.addEventListener('contextmenu', function (e) { e.preventDefault(); });
    domElement.addEventListener('touchstart',  onTouchStart, { passive: false });
    domElement.addEventListener('touchmove',   onTouchMove,  { passive: false });
    domElement.addEventListener('touchend',    onTouchEnd);

    this.dispose = function () {
      domElement.removeEventListener('mousedown',   onMouseDown);
      domElement.removeEventListener('wheel',       onWheel);
      domElement.removeEventListener('touchstart',  onTouchStart);
      domElement.removeEventListener('touchmove',   onTouchMove);
      domElement.removeEventListener('touchend',    onTouchEnd);
    };
  };
})();

// ════════════════════════════════════════════════════════════════════
// Minimal mergeGeometries (only used if THREE.BufferGeometryUtils
// is not available on the page)
// ════════════════════════════════════════════════════════════════════
(function injectMergeGeometries() {
  if (typeof THREE === 'undefined') return;
  if (THREE.BufferGeometryUtils && THREE.BufferGeometryUtils.mergeGeometries) {
    THREE.mergeGeometries = THREE.BufferGeometryUtils.mergeGeometries.bind(THREE.BufferGeometryUtils);
    return;
  }
  // Fallback: position-only merge
  THREE.mergeGeometries = function (geos) {
    if (!geos || !geos.length) return null;
    if (geos.length === 1) return geos[0];
    var total = 0;
    for (var i = 0; i < geos.length; i++) total += geos[i].attributes.position.count;
    var pos = new Float32Array(total * 3);
    var off = 0;
    for (var i = 0; i < geos.length; i++) {
      pos.set(geos[i].attributes.position.array, off);
      off += geos[i].attributes.position.array.length;
    }
    var merged = new THREE.BufferGeometry();
    merged.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    merged.computeVertexNormals();
    merged.computeBoundingSphere();
    return merged;
  };
})();

// ════════════════════════════════════════════════════════════════════
// Static marble texture (created once, shared across all instances)
// ════════════════════════════════════════════════════════════════════
var _sharedMarbleTexture = null;
function getMarbleTexture() {
  if (_sharedMarbleTexture) return _sharedMarbleTexture;

  var size   = 512; // smaller than original 1024 — still looks great
  var canvas = document.createElement('canvas');
  canvas.width = canvas.height = size;
  var ctx = canvas.getContext('2d');

  // Base
  ctx.fillStyle = '#08080a';
  ctx.fillRect(0, 0, size, size);

  // Veins
  ctx.lineCap = ctx.lineJoin = 'round';
  for (var i = 0; i < 40; i++) {
    ctx.beginPath();
    var x = Math.random() * size, y = Math.random() * size;
    ctx.moveTo(x, y);
    for (var j = 0; j < 5; j++) {
      var ex = x + (Math.random() - 0.5) * 500;
      var ey = y + (Math.random() - 0.5) * 500;
      ctx.bezierCurveTo(
        x + (Math.random() - 0.5) * 350, y + (Math.random() - 0.5) * 350,
        x + (Math.random() - 0.5) * 350, y + (Math.random() - 0.5) * 350,
        ex, ey
      );
      x = ex; y = ey;
    }
    var b  = Math.floor(Math.random() * 40 + 15);
    var gH = Math.random() > 0.7 ? 25 : 0;
    ctx.lineWidth   = Math.random() * 20 + 4;
    ctx.strokeStyle = 'rgba(' + (b + gH) + ',' + b + ',' + b + ',' + (Math.random() * 0.12 + 0.04) + ')';
    ctx.stroke();
  }

  // Grain
  var id   = ctx.getImageData(0, 0, size, size);
  var data = id.data;
  for (var i = 0; i < data.length; i += 4) {
    var n = (Math.random() - 0.5) * 8;
    data[i]   += n; data[i + 1] += n; data[i + 2] += n;
  }
  ctx.putImageData(id, 0, 0);

  var tex = new THREE.CanvasTexture(canvas);
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.repeat.set(2, 2);
  tex.anisotropy = 8;
  _sharedMarbleTexture = tex;
  return tex;
}

// ════════════════════════════════════════════════════════════════════
// Instance map
// ════════════════════════════════════════════════════════════════════
var _instances = new Map();

// ════════════════════════════════════════════════════════════════════
// Config normalizer
// ════════════════════════════════════════════════════════════════════
function normalizeConfig(cfg) {
  cfg = cfg || {};
  return {
    gradientColorCount: Number(cfg.gradientColorCount ?? 1),
    colors:             Array.isArray(cfg.colors) ? cfg.colors.slice() : ['#f5efe2', '#fcd5ce', '#ec4f8c'],
    pipingType:         cfg.pipingType         || 'openStar',
    pipingColor:        cfg.pipingColor        || '#ffffff',
    pipingColorCount:   Number(cfg.pipingColorCount ?? 1),
    pipingColors:       Array.isArray(cfg.pipingColors) ? cfg.pipingColors.slice() : ['#ffffff'],
    pipingPlacement:    cfg.pipingPlacement    || 'border',
    pipingSize:         Number(cfg.pipingSize  ?? 1),
    text:               cfg.text               || '',
    textColor:          cfg.textColor          || '#032E3F',
    textPosition:       cfg.textPosition       || 'center',
    textSize:           Number(cfg.textSize    ?? 1),
    fontStyle:          cfg.fontStyle          || 'normal',
    imageScale:         Number(cfg.imageScale  ?? 0.8),
    topImage:           cfg.topImage           || null,
    autoRotate:         cfg.autoRotate !== false,
    cakeScale:          Number(cfg.cakeScale   ?? 1),
    cakeHeight:         Number(cfg.cakeHeight  ?? 0.42),
    cakeRadius:         Number(cfg.cakeRadius  ?? 0.78),
    plateColor:         cfg.plateColor         || '#c9a227',
    roughness:          Number(cfg.roughness   ?? 0.3),
    metalness:          Number(cfg.metalness   ?? 0.05),
    clearcoat:          Number(cfg.clearcoat   ?? 0.4),
    selectedAddons:     Array.isArray(cfg.selectedAddons) ? cfg.selectedAddons.slice() : [],
    addonColors:        (cfg.addonColors && typeof cfg.addonColors === 'object') ? Object.assign({}, cfg.addonColors) : {},
    secretMessageText:  String(cfg.secretMessageText || ''),
  };
}

// ════════════════════════════════════════════════════════════════════
// Material helpers
// ════════════════════════════════════════════════════════════════════
function disposeMaterial(mat) {
  if (!mat) return;
  if (Array.isArray(mat)) { mat.forEach(disposeMaterial); return; }
  if (mat.map) mat.map.dispose();
  mat.dispose();
}

function mkPhys(params) {
  return new THREE.MeshPhysicalMaterial(params);
}

// ════════════════════════════════════════════════════════════════════
// CakeDesignerInstance
// ════════════════════════════════════════════════════════════════════
class CakeDesignerInstance {

  // ── Constants ────────────────────────────────────────────────────
  static CAM_POS  = new THREE.Vector3(1.6, 4.5, 2.0);
  static CAM_TGT  = new THREE.Vector3(0, 0.6, 0);
  static SHADOW_SIZE = 1024;
  static DEBOUNCE_MS = 60;

  constructor(container, config) {
    this.container  = container;
    this.config     = normalizeConfig(config);
    this.scene      = null;
    this.camera     = null;
    this.renderer   = null;
    this.controls   = null;
    this.cakeGroup  = null;
    this.animId     = null;
    this._geoCache  = new Map();
    this._debounce  = null;
    this._disposed  = false;
    this._onResize  = this._handleResize.bind(this);
    this._resizeObs = null;

    this._init();
  }

  // ── Initialisation ───────────────────────────────────────────────
  _init() {
    var W = Math.max(this.container.clientWidth  || 300, 1);
    var H = Math.max(this.container.clientHeight || 300, 1);

    // Renderer
    this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, preserveDrawingBuffer: true });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    this.renderer.setSize(W, H);
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type    = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping       = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.15;

    var cvs = this.renderer.domElement;
    cvs.style.display = 'block';
    cvs.style.width = cvs.style.height = '100%';
    this.container.innerHTML = '';
    this.container.appendChild(cvs);

    // Scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x1a1f2e);
    this.scene.fog = new THREE.FogExp2(0x1a1f2e, 0.018);

    // Camera
    this.camera = new THREE.PerspectiveCamera(35, W / H, 0.1, 100);
    this.camera.position.copy(CakeDesignerInstance.CAM_POS);

    // Controls
    this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    this.controls.minDistance   = 1.5;
    this.controls.maxDistance   = 7.0;
    this.controls.maxPolarAngle = Math.PI * 0.75;
    this.controls.target.copy(CakeDesignerInstance.CAM_TGT);
    this.controls.update();

    this._buildLights();
    this._buildFloor();
    this._buildCake();
    this._animate();

    window.addEventListener('resize', this._onResize);
    if (typeof ResizeObserver !== 'undefined') {
      this._resizeObs = new ResizeObserver(() => this._handleResize());
      this._resizeObs.observe(this.container);
    }

    console.log('[CakeDesigner] Scene ready 🎂');
  }

  // ── Lights ───────────────────────────────────────────────────────
  _buildLights() {
    var s = this.scene;
    s.add(new THREE.AmbientLight(0xffe8cc, 0.5));

    var main = new THREE.DirectionalLight(0xffd9a8, 1.3);
    main.position.set(4, 8, 4);
    main.castShadow = true;
    main.shadow.mapSize.setScalar(CakeDesignerInstance.SHADOW_SIZE);
    main.shadow.camera.near   = 0.5;
    main.shadow.camera.far    = 15;
    main.shadow.camera.left   = -2;
    main.shadow.camera.right  = 2;
    main.shadow.camera.top    = 2;
    main.shadow.camera.bottom = -2;
    main.shadow.bias          = -0.0005;
    s.add(main);

    var fill = new THREE.DirectionalLight(0xffc088, 0.5);
    fill.position.set(-4, 4, -4);
    s.add(fill);

    var rim = new THREE.PointLight(0xffcc88, 1.1, 12);
    rim.position.set(0, 1.2, -2.2);
    s.add(rim);

    var side = new THREE.SpotLight(0xffbb66, 0.8, 8, Math.PI / 7, 0.7);
    side.position.set(-2, 1.5, 2);
    side.target.position.set(0, 0.2, 0);
    s.add(side, side.target);

    var plate = new THREE.SpotLight(0xffeedd, 1.2, 5, Math.PI / 5, 0.6);
    plate.position.set(1, 3, 1);
    plate.target.position.set(0, 0.05, 0);
    s.add(plate, plate.target);

    var top = new THREE.PointLight(0xffeebb, 0.4, 6);
    top.position.set(0, 2.5, 0);
    s.add(top);
  }

  // ── Floor ────────────────────────────────────────────────────────
  _buildFloor() {
    // Shadow receiver
    var shadow = new THREE.Mesh(
      new THREE.PlaneGeometry(10, 10),
      new THREE.ShadowMaterial({ opacity: 0.6 })
    );
    shadow.rotation.x = -Math.PI / 2;
    shadow.receiveShadow = true;
    this.scene.add(shadow);

    // Marble
    var floor = new THREE.Mesh(
      new THREE.PlaneGeometry(20, 20),
      mkPhys({ map: getMarbleTexture(), color: 0xffffff, roughness: 0.25, metalness: 0.4 })
    );
    floor.rotation.x   = -Math.PI / 2;
    floor.position.y   = -0.01;
    floor.receiveShadow = true;
    this.scene.add(floor);
  }

  // ════════════════════════════════════════════════════════════════
  // Config update (debounced)
  // ════════════════════════════════════════════════════════════════
  updateConfig(config) {
    this.config = normalizeConfig(config);
    if (this._debounce) clearTimeout(this._debounce);
    this._debounce = setTimeout(() => {
      this._debounce = null;
      if (!this._disposed) this._buildCake();
    }, CakeDesignerInstance.DEBOUNCE_MS);
  }

  // ════════════════════════════════════════════════════════════════
  // Animation loop
  // ════════════════════════════════════════════════════════════════
  _animate() {
    if (this._disposed) return;
    this.animId = requestAnimationFrame(() => this._animate());
    this.controls.update();
    if (this.cakeGroup && this.config.autoRotate) this.cakeGroup.rotation.y += 0.003;
    this.renderer.render(this.scene, this.camera);
  }

  _handleResize() {
    if (!this.container || !this.renderer || !this.camera) return;
    var W = Math.max(this.container.clientWidth  || 1, 1);
    var H = Math.max(this.container.clientHeight || 1, 1);
    this.camera.aspect = W / H;
    this.camera.position.set(W > H ? 3.2 : 2.4, W > H ? 1.9 : 1.6, W > H ? 3.6 : 2.8);
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(W, H);
    this.controls.update();
  }

  resetCamera() {
    this.camera.position.set(2.8, 1.8, 3.2);
    this.controls.target.copy(CakeDesignerInstance.CAM_TGT);
    this.controls.update();
  }

  captureScreenshot() {
    this.renderer.render(this.scene, this.camera);
    return this.renderer.domElement.toDataURL('image/png');
  }

  // ════════════════════════════════════════════════════════════════
  // Scene graph helpers
  // ════════════════════════════════════════════════════════════════
  _disposeCakeGroup() {
    if (!this.cakeGroup) return;
    this.scene.remove(this.cakeGroup);
    this.cakeGroup.traverse(child => {
      if (child.isMesh || child.isInstancedMesh) {
        child.geometry?.dispose();
        disposeMaterial(child.material);
      }
    });
    this.cakeGroup = null;
  }

  // ════════════════════════════════════════════════════════════════
  // Full cake rebuild
  // ════════════════════════════════════════════════════════════════
  _buildCake() {
    if (!this.scene) return;
    this._geoCache.clear();
    this._disposeCakeGroup();

    var g     = new THREE.Group();
    var scale = this.config.cakeScale;
    g.scale.setScalar(scale);
    g.position.y = 0.02;

    var R     = this.config.cakeRadius;
    var H     = this.config.cakeHeight;
    var baseY = 0.1;

    this._buildPedestal(g, R, baseY);
    this._buildBody(g, R, H, baseY);
    this._buildTopCap(g, R, H, baseY);
    this._buildTopContent(g, R, H, baseY);
    this._buildPiping(g, R, H, baseY);
    this._buildAddons(g, R, H, baseY);

    this.scene.add(g);
    this.cakeGroup = g;
  }

  // ── Pedestal ────────────────────────────────────────────────────
  _buildPedestal(group, R, baseY) {
    var mkMat = (hex, r, m) => mkPhys({ color: new THREE.Color(hex), metalness: m ?? 1.0, roughness: r ?? 0.05, clearcoat: 1.0, clearcoatRoughness: 0.03 });
    var deep  = mkMat('#B8860B');
    var mid   = mkMat('#D4A017', 0.03);
    var light = mkMat('#F0C040', 0.02);

    var addPlate = (w, h, y, mat, edgeW, edgeH, edgeY, edgeMat) => {
      var m = new THREE.Mesh(new THREE.BoxGeometry(w, h, w), mat);
      m.position.y = y;
      m.receiveShadow = m.castShadow = true;
      group.add(m);
      if (edgeW) {
        var e = new THREE.Mesh(new THREE.BoxGeometry(edgeW, edgeH, edgeW), edgeMat);
        e.position.y = edgeY;
        group.add(e);
      }
    };

    var p3w = (R + 0.22) * 2, p3h = 0.022;
    addPlate(p3w, p3h, baseY - 0.048, deep, p3w + 0.006, 0.009, baseY - 0.048 + p3h * 0.5 + 0.0045, light);

    var p2w = (R + 0.13) * 2, p2h = 0.018;
    addPlate(p2w, p2h, baseY - 0.027, mid, p2w + 0.005, 0.007, baseY - 0.027 + p2h * 0.5 + 0.0035, light);

    var p1w = (R + 0.055) * 2, p1h = 0.014;
    addPlate(p1w, p1h, baseY - 0.007, deep, p1w + 0.004, 0.006, baseY - 0.007 + p1h * 0.5 + 0.003, light);

    // Leg
    var legH = Math.max(0.01, baseY - 0.055);
    var legW = R * 0.42;
    var leg  = new THREE.Mesh(new THREE.BoxGeometry(legW, legH, legW), deep);
    leg.position.y = legH * 0.5;
    leg.castShadow = true;
    group.add(leg);

    var legTop = new THREE.Mesh(new THREE.BoxGeometry(legW + 0.005, 0.006, legW + 0.005), light);
    legTop.position.y = legH + 0.003;
    group.add(legTop);

    var legBase = new THREE.Mesh(new THREE.BoxGeometry(legW + 0.04, 0.008, legW + 0.04), mid);
    legBase.position.y = 0.004;
    group.add(legBase);

    var glow = new THREE.PointLight(0xd4a520, 0.4, 0.8);
    glow.position.set(0, baseY - 0.01, 0);
    group.add(glow);
  }

  // ── Cake body (vertex gradient) ──────────────────────────────────
  _buildBody(group, R, H, baseY) {
    var radSegs = 64, hSegs = 32;
    var geo     = new THREE.CylinderGeometry(R, R, H, radSegs, hSegs, false);
    var pos     = geo.attributes.position.array;
    var count   = geo.attributes.position.count;
    var cols    = new Float32Array(count * 3);
    var n       = this.config.gradientColorCount;
    var c0      = new THREE.Color(this.config.colors[0]);
    var c1      = new THREE.Color(this.config.colors[1] || this.config.colors[0]);
    var c2      = new THREE.Color(this.config.colors[2] || this.config.colors[1] || this.config.colors[0]);
    var tmp     = new THREE.Color();

    for (var i = 0; i < count; i++) {
      var t = Math.max(0, Math.min(1, (pos[i * 3 + 1] + H * 0.5) / H));
      if (n === 1)      tmp.copy(c0);
      else if (n === 2) tmp.copy(c0).lerp(c1, t);
      else              t < 0.5 ? tmp.copy(c0).lerp(c1, t * 2) : tmp.copy(c1).lerp(c2, (t - 0.5) * 2);
      cols[i * 3] = tmp.r; cols[i * 3 + 1] = tmp.g; cols[i * 3 + 2] = tmp.b;
    }
    geo.setAttribute('color', new THREE.BufferAttribute(cols, 3));

    var mesh = new THREE.Mesh(geo, mkPhys({
      vertexColors: true,
      roughness: this.config.roughness,
      metalness: this.config.metalness,
      clearcoat: this.config.clearcoat,
      clearcoatRoughness: 0.2,
    }));
    mesh.position.y   = baseY + H * 0.5;
    mesh.castShadow   = mesh.receiveShadow = true;
    group.add(mesh);
  }

  // ── Top cap ──────────────────────────────────────────────────────
  _buildTopCap(group, R, H, baseY) {
    var topColor = this._resolveTopColor();
    var cap = new THREE.Mesh(
      new THREE.CylinderGeometry(R, R, 0.005, 64),
      mkPhys({ color: topColor, roughness: this.config.roughness, metalness: this.config.metalness, clearcoat: this.config.clearcoat })
    );
    cap.position.y = baseY + H;
    cap.receiveShadow = true;
    group.add(cap);
  }

  _resolveTopColor() {
    var n = this.config.gradientColorCount;
    var c = this.config.colors;
    if (n === 1) return new THREE.Color(c[0]);
    if (n === 2) return new THREE.Color(c[1] || c[0]);
    return new THREE.Color(c[2] || c[1] || c[0]);
  }

  // ── Top surface content (text / image) ───────────────────────────
  _buildTopContent(group, R, H, baseY) {
    var cfg      = this.config;
    var hasText  = !!(cfg.text && cfg.text.trim().length);
    var hasImage = !!cfg.topImage;
    if (!hasText && !hasImage) return;

    // Block-top addons suppress text/image ONLY when there's no text or image
    var blockIds = ['giftRibbon','naturalFlowers','artificialFlowers',
                    'babyFlower','fruits','babyHeartChocolate','pearls',
                    'chocoDrip','sprinkles','glitter'];
    var hasBlock = cfg.selectedAddons.some(a => blockIds.includes(a));
    if (hasBlock && !hasText && !hasImage) return;

    var topY = baseY + H + 0.003;
    var bgColor = this._resolveTopColor();
    var size    = 2048;
    var canvas  = document.createElement('canvas');
    canvas.width = canvas.height = size;
    var ctx = canvas.getContext('2d');
    ctx.fillStyle = '#' + bgColor.getHexString();
    ctx.fillRect(0, 0, size, size);

    var finalise = () => {
      if (hasText) {
        var cx = size / 2;
        var cy = cfg.textPosition === 'top'    ? size * 0.22
               : cfg.textPosition === 'bottom' ? size * 0.78
               : size / 2;
        var ff  = cfg.fontStyle === 'amiri'   ? 'serif'
                : cfg.fontStyle === 'cursive' ? 'cursive'
                : 'Arial, sans-serif';
        var fw  = 'bold';
        var fi  = cfg.fontStyle === 'amiri' ? 'italic ' : '';
        var fs  = size * 0.08 * cfg.textSize;
        ctx.save();
        ctx.font         = fi + fw + ' ' + fs + 'px ' + ff;
        ctx.fillStyle    = cfg.textColor;
        ctx.textAlign    = 'center';
        ctx.textBaseline = 'middle';
        ctx.shadowColor  = 'rgba(0,0,0,0.6)';
        ctx.shadowBlur   = 16;
        ctx.shadowOffsetX = ctx.shadowOffsetY = 4;
        ctx.fillText(cfg.text, cx, cy);
        ctx.restore();
      }

      var tex = new THREE.CanvasTexture(canvas);
      tex.colorSpace     = THREE.SRGBColorSpace;
      tex.minFilter      = THREE.LinearMipmapLinearFilter;
      tex.magFilter      = THREE.LinearFilter;
      tex.needsUpdate    = true;

      var overlay = new THREE.Mesh(
        new THREE.CircleGeometry(R - 0.005, 128),
        new THREE.MeshBasicMaterial({ map: tex, transparent: true, side: THREE.DoubleSide, toneMapped: false })
      );
      overlay.rotation.x = -Math.PI / 2;
      overlay.position.y = topY;
      group.add(overlay);
    };

    if (hasImage) {
      var img = new Image();
      img.crossOrigin = 'anonymous';
      img.onload = () => {
        var cx = size / 2, cy = size / 2;
        var ir = (size / 2) * cfg.imageScale;
        ctx.save();
        ctx.beginPath();
        ctx.arc(cx, cy, ir, 0, Math.PI * 2);
        ctx.clip();
        ctx.drawImage(img, cx - ir, cy - ir, ir * 2, ir * 2);
        ctx.restore();
        ctx.save();
        ctx.strokeStyle = cfg.pipingColor;
        ctx.lineWidth   = size * 0.015;
        ctx.beginPath(); ctx.arc(cx, cy, ir, 0, Math.PI * 2); ctx.stroke();
        ctx.restore();
        finalise();
      };
      img.onerror = finalise;
      img.src     = cfg.topImage;
    } else {
      finalise();
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Piping system
  // ════════════════════════════════════════════════════════════════
  _buildPiping(group, R, H, baseY) {
    var cfg  = this.config;
    if (cfg.pipingType === 'none') return;

    var S    = 0.072 * cfg.pipingSize;
    var topY = baseY + H + S * 0.4;

    var hasTopContent = !!(cfg.text && cfg.text.trim()) || !!cfg.topImage;
    var blockIds      = ['giftRibbon','naturalFlowers','artificialFlowers',
                         'babyFlower','fruits','babyHeartChocolate',
                         'pearls','chocoDrip','sprinkles','glitter'];
    var hasBlockAddon = cfg.selectedAddons.some(a => blockIds.includes(a));
    var fillTop       = cfg.pipingPlacement === 'full' && !hasTopContent && !hasBlockAddon;
    var isEdges       = cfg.pipingPlacement === 'edges';
    var isFull        = cfg.pipingPlacement === 'full';

    // Dispatch to specialised builders
    switch (cfg.pipingType) {
      case 'threads':     return this._pipingThreads(group, R, H, baseY, S, topY, fillTop, isEdges, isFull);
      case 'wave':        return this._pipingWave(group, R, H, baseY, S, topY, fillTop, isEdges, isFull);
      case 'thinLine':    return this._pipingThinLine(group, R, H, baseY, S, topY, fillTop, isEdges, isFull);
      case 'shell':       return this._pipingShell(group, R, H, baseY, S, topY, fillTop, isEdges, isFull);
      case 'heart':       return this._pipingHeart(group, R, H, baseY, S, topY, fillTop, isEdges, isFull);
      default:            return this._pipingGeneric(group, R, H, baseY, S, topY, fillTop, isEdges, isFull);
    }
  }

  // ── Piping colour resolver ────────────────────────────────────────
  _pipingColor(t) {
    var cols  = this.config.pipingColors && this.config.pipingColors.length
                ? this.config.pipingColors
                : [this.config.pipingColor];
    var count = Math.max(1, Math.min(3, this.config.pipingColorCount || 1));
    var c0    = new THREE.Color(cols[0] || this.config.pipingColor);
    if (count === 1) return '#' + c0.getHexString();
    var c1    = new THREE.Color(cols[1] || cols[0]);
    if (count === 2) return '#' + c0.clone().lerp(c1, t).getHexString();
    var c2    = new THREE.Color(cols[2] || cols[1] || cols[0]);
    return t < 0.5 ? '#' + c0.clone().lerp(c1, t * 2).getHexString()
                   : '#' + c1.clone().lerp(c2, (t - 0.5) * 2).getHexString();
  }

  // ── InstancedMesh ring helper ─────────────────────────────────────
  _pipingRing(group, r, y, S, isSide, colorT, type) {
    type    = type || this.config.pipingType;
    colorT  = colorT || 0;
    var isFull = this.config.pipingPlacement === 'full';

    var circ = 2 * Math.PI * r;
    var sp   = type === 'basketWeave' ? S * 1.15
             : type === 'wave'        ? S * 2.6
             : type === 'round'       ? S * 1.2
             : S * 1.8;
    var cnt  = Math.max(12, Math.floor(circ / sp));
    var geo  = this._getPipingGeo(type, S);
    var hex  = this._pipingColor(isFull ? colorT : 0);
    var isGold = hex.toLowerCase() === '#d4a24a';
    var mat  = mkPhys({ color: new THREE.Color(hex), roughness: 0.35, clearcoat: 0.4, metalness: isGold ? 0.8 : 0 });

    var im    = new THREE.InstancedMesh(geo, mat, cnt);
    im.castShadow = im.receiveShadow = true;
    var dummy = new THREE.Object3D();

    for (var i = 0; i < cnt; i++) {
      var a = (i / cnt) * Math.PI * 2;
      var x = r * Math.cos(a), z = r * Math.sin(a);
      if (isSide) {
        dummy.position.set(x, y, z);
        dummy.lookAt(x + Math.cos(a), y, z + Math.sin(a));
        dummy.rotateZ(Math.PI / 2);
      } else {
        dummy.position.set(x, y + S * 0.2, z);
        dummy.rotation.set(-Math.PI / 2, 0, a, 'XYZ');
      }
      dummy.updateMatrix();
      im.setMatrixAt(i, dummy.matrix);
    }
    im.instanceMatrix.needsUpdate = true;
    group.add(im);
  }

  // ── Generic piping (openStar / closedStar / rose / dropFlower / leaf / grass / sphere / basketWeave / frenchLace) ──
  _pipingGeneric(group, R, H, baseY, S, topY, fillTop, isEdges, isFull) {
    // Fill top
    if (fillTop) {
      var cur = R - S * 2.5;
      while (cur > 0.1) { this._pipingRing(group, cur, topY, S, false, 1); cur -= S * 2.2; }
    }
    // Border ring
    var fct = isFull ? 1 : 0;
    this._pipingRing(group, R - S * 0.8, topY, S, false, fct);
    // Side rings (full)
    if (isFull) {
      var rows = Math.round(H / (S * 2.2));
      for (var j = 0; j <= rows; j++) {
        this._pipingRing(group, R + S * 0.15, baseY + (j / rows) * H, S, true, j / rows);
      }
    }
    // Bottom edge (edges mode)
    if (isEdges) this._pipingRing(group, R + S * 0.15, baseY + S * 0.7, S, true, 0);
  }

  // ── Shell ──────────────────────────────────────────────────────────
  _pipingShell(group, R, H, baseY, S, topY, fillTop, isEdges, isFull) {
    var rings = fillTop ? this._topFillRadii(R, S, 2.4, 0.85, 2.0) : [R - S * 0.85];
    rings.forEach(rr => this._shellRing(group, rr, topY, S, isFull ? 1 : 0, false));
    if (isFull) {
      var rows = Math.max(3, Math.round(H / (S * 1.5)));
      for (var j = 0; j <= rows; j++) this._shellRing(group, R + S * 0.15, baseY + (j / rows) * H, S, j / rows, true);
    }
    if (isEdges) this._shellRing(group, R + S * 0.15, baseY + S * 0.7, S, 0, true);
  }

  _shellRing(group, r, y, S, colorT, isSide) {
    var circ = 2 * Math.PI * r;
    var cnt  = Math.max(10, Math.floor(circ / (S * 1.4 * 0.92)));
    var geo  = this._getPipingGeo('shell', S);
    var mat  = mkPhys({ color: new THREE.Color(this._pipingColor(this.config.pipingPlacement === 'full' ? colorT : 0)), roughness: 0.35, clearcoat: 0.4, metalness: 0 });
    var im   = new THREE.InstancedMesh(geo, mat, cnt);
    im.castShadow = im.receiveShadow = true;
    var dummy = new THREE.Object3D();
    for (var i = 0; i < cnt; i++) {
      var a = (i / cnt) * Math.PI * 2;
      var x = r * Math.cos(a), z = r * Math.sin(a);
      if (isSide) {
        dummy.position.set(x, y, z);
        dummy.lookAt(x * 2, y, z * 2);
        dummy.rotateX(Math.PI * 0.5);
        dummy.rotateY(Math.PI);
      } else {
        dummy.position.set(x, y, z);
        var up  = new THREE.Vector3(0, 1, 0);
        var tan = new THREE.Vector3(-Math.sin(a), 0, Math.cos(a));
        var mx  = new THREE.Matrix4().makeBasis(tan, up, new THREE.Vector3().crossVectors(tan, up).normalize());
        dummy.setRotationFromMatrix(mx);
      }
      dummy.updateMatrix();
      im.setMatrixAt(i, dummy.matrix);
    }
    im.instanceMatrix.needsUpdate = true;
    group.add(im);
  }

  // ── Heart ──────────────────────────────────────────────────────────
  _pipingHeart(group, R, H, baseY, S, topY, fillTop, isEdges, isFull) {
    var rings = fillTop ? this._topFillRadii(R, S, 2.4, 0.85, 2.0) : [R - S * 0.85];
    rings.forEach(rr => this._heartRing(group, rr, topY, S, isFull ? 1 : 0, false));
    if (isFull) {
      var rows = Math.max(3, Math.round(H / (S * 1.5)));
      for (var j = 0; j <= rows; j++) this._heartRing(group, R + S * 0.15, baseY + (j / rows) * H, S, j / rows, true);
    }
    if (isEdges) this._heartRing(group, R + S * 0.15, baseY + S * 0.7, S, 0, true);
  }

  _heartRing(group, r, y, S, colorT, isSide) {
    var circ  = 2 * Math.PI * r;
    var cnt   = Math.max(10, Math.floor(circ / (S * 1.8 * 0.95)));
    var geo   = this._getPipingGeo('heart', S);
    var mat   = mkPhys({ color: new THREE.Color(this._pipingColor(this.config.pipingPlacement === 'full' ? colorT : 0)), roughness: 0.35, clearcoat: 0.4, metalness: 0 });
    var im    = new THREE.InstancedMesh(geo, mat, cnt);
    im.castShadow = im.receiveShadow = true;
    var dummy = new THREE.Object3D();
    for (var i = 0; i < cnt; i++) {
      var a = (i / cnt) * Math.PI * 2;
      var x = r * Math.cos(a), z = r * Math.sin(a);
      if (isSide) {
        dummy.position.set(x, y, z);
        dummy.lookAt(x * 2, y, z * 2);
        dummy.rotateY(Math.PI);
        dummy.rotateX(-Math.PI * 0.5);
        dummy.rotateX(Math.PI * 0.08);
      } else {
        dummy.position.set(x, y, z);
        var up  = new THREE.Vector3(0, 1, 0);
        var tan = new THREE.Vector3(-Math.sin(a), 0, Math.cos(a));
        var mx  = new THREE.Matrix4().makeBasis(tan, up, new THREE.Vector3().crossVectors(tan, up).normalize());
        dummy.setRotationFromMatrix(mx);
        dummy.rotateY(Math.PI / 2);
      }
      dummy.updateMatrix();
      im.setMatrixAt(i, dummy.matrix);
    }
    im.instanceMatrix.needsUpdate = true;
    group.add(im);
  }

  // ── Threads / Wave / ThinLine ─────────────────────────────────────
  _pipingThreads(group, R, H, baseY, S, topY, fillTop, isEdges, isFull) {
    var mkTorus = (r, y, t) => {
      var m = new THREE.Mesh(
        new THREE.TorusGeometry(r, S * 0.055, 12, 180),
        mkPhys({ color: new THREE.Color(this._pipingColor(isFull ? t : 0)), roughness: 0.25, clearcoat: 0.6, metalness: 0.05 })
      );
      m.rotation.x = -Math.PI / 2;
      m.position.y = y + S * 0.08;
      m.castShadow = m.receiveShadow = true;
      group.add(m);
    };
    var radii = fillTop ? this._topFillRadii(R, S, 1.1, 1.1, 0.55).concat([R - S * 1.1]) : [R - S * 1.1];
    radii.forEach(rr => mkTorus(rr, topY, 0));
    if (isFull) { var rows = Math.max(5, Math.round(H / (S * 0.9))); for (var j = 0; j <= rows; j++) mkTorus(R + S * 0.1, baseY + (j / rows) * H, j / rows); }
    if (isEdges) mkTorus(R + S * 0.1, baseY + S * 0.7, 0);
  }

  _pipingWave(group, R, H, baseY, S, topY, fillTop, isEdges, isFull) {
    var mkMat = t => mkPhys({ color: new THREE.Color(this._pipingColor(isFull ? t : 0)), roughness: 0.25, clearcoat: 0.6, metalness: 0.05 });
    var mkTopRing = (rr, y, t) => {
      var wc = Math.max(8, Math.round(rr / (S * 0.12)));
      var buildCurve = (rOff, yOff) => {
        var pts = [];
        for (var i = 0; i <= 240; i++) { var u = i / 240, a = u * Math.PI * 2; pts.push(new THREE.Vector3(Math.cos(a) * (rr + rOff + Math.sin(a * wc) * S * 0.16), y + yOff, Math.sin(a) * (rr + rOff + Math.sin(a * wc) * S * 0.16))); }
        return new THREE.CatmullRomCurve3(pts, true);
      };
      var addTube = (rOff, yOff, rad) => { var m = new THREE.Mesh(new THREE.TubeGeometry(buildCurve(rOff, yOff), 260, rad, rad < 0.05 ? 8 : 18, true), mkMat(t)); m.castShadow = m.receiveShadow = true; group.add(m); };
      addTube(0, S * 0.07, S * 0.25);
      for (var r = -3; r <= 3; r++) addTube(r * S * 0.085, S * (0.29 + Math.abs(r) * 0.006), S * 0.035);
    };
    var mkSideRing = (rr, y, t) => {
      var wc = Math.max(8, Math.round(rr / (S * 0.14)));
      var buildCurve = (vOff, rOff) => {
        var pts = [];
        for (var i = 0; i <= 240; i++) { var u = i / 240, a = u * Math.PI * 2; pts.push(new THREE.Vector3(Math.cos(a) * (rr + rOff), y + vOff + Math.sin(a * wc) * S * 0.18, Math.sin(a) * (rr + rOff))); }
        return new THREE.CatmullRomCurve3(pts, true);
      };
      var addTube = (vOff, rOff, rad) => { var m = new THREE.Mesh(new THREE.TubeGeometry(buildCurve(vOff, rOff), 240, rad, rad < 0.05 ? 8 : 16, true), mkMat(t)); m.castShadow = m.receiveShadow = true; group.add(m); };
      addTube(0, S * 0.06, S * 0.2);
      for (var r = -3; r <= 3; r++) addTube(r * S * 0.055, S * (0.26 + Math.abs(r) * 0.012), S * 0.032);
    };
    var topRings = fillTop ? this._topFillRadii(R, S, 2.2, 0.8, 1.6) : [R - S * 0.8];
    topRings.forEach(rr => mkTopRing(rr, topY, 0));
    if (isFull) { var rows = Math.max(4, Math.round(H / (S * 1.4))); for (var j = 0; j <= rows; j++) mkSideRing(R + S * 0.15, baseY + (j / rows) * H, j / rows); }
    if (isEdges) mkSideRing(R + S * 0.15, baseY + S * 0.7, 0);
  }

  _pipingThinLine(group, R, H, baseY, S, topY, fillTop, isEdges, isFull) {
    var mkRing = (r, y, t) => {
      var m = new THREE.Mesh(
        new THREE.TorusGeometry(r, S * 0.15, 16, 128),
        mkPhys({ color: new THREE.Color(this._pipingColor(isFull ? t : 0)), roughness: 0.25, clearcoat: 0.6, metalness: 0.05 })
      );
      m.rotation.x = -Math.PI / 2; m.position.y = y; m.castShadow = m.receiveShadow = true; group.add(m);
    };
    if (fillTop) { var cur = R - S * 2.5; while (cur > 0.1) { mkRing(cur, topY, 1); cur -= S * 2.2; } }
    mkRing(R - S * 0.8, topY, 0);
    if (isFull) { var rows = Math.round(H / (S * 2.2)); for (var j = 0; j <= rows; j++) mkRing(R + S * 0.1, baseY + (j / rows) * H, j / rows); }
    if (isEdges) mkRing(R + S * 0.1, baseY + S * 0.7, 0);
  }

  // ── Top fill radii helper ─────────────────────────────────────────
  _topFillRadii(R, S, startOff, endOff, step) {
    var radii = [], cur = R - S * startOff;
    while (cur > S * (endOff * 2)) { radii.push(cur); cur -= S * step; }
    radii.push(R - S * endOff);
    return radii;
  }

  // ════════════════════════════════════════════════════════════════
  // Geometry cache
  // ════════════════════════════════════════════════════════════════
  _getPipingGeo(type, S) {
    var key = type + '_' + S.toFixed(5);
    if (this._geoCache.has(key)) return this._geoCache.get(key);
    var geo = this._createPipingGeo(type, S);
    this._geoCache.set(key, geo);
    return geo;
  }

  _createPipingGeo(type, S) {
    switch (type) {
      case 'round':       return new THREE.SphereGeometry(S * 0.55, 20, 20);
      case 'sphere':      return new THREE.SphereGeometry(S * 0.95, 32, 32);

      case 'openStar': {
        var g = new THREE.ExtrudeGeometry(this._starShape(6, S, S * 0.5), { depth: S * 1.2, bevelEnabled: true, bevelSize: S * 0.1, bevelThickness: S * 0.1 });
        g.center(); return g;
      }
      case 'closedStar': {
        var g = new THREE.ExtrudeGeometry(this._starShape(8, S, S * 0.35), { depth: S * 1.4, bevelEnabled: true, bevelSize: S * 0.08, bevelThickness: S * 0.08 });
        g.center(); return g;
      }

      case 'rose':        return this._geoRose(S);
      case 'dropFlower':  return this._geoDropFlower(S);
      case 'leaf':        return this._geoLeaf(S);
      case 'shell':       return this._geoShell(S);
      case 'heart':       return this._geoHeart(S);
      case 'wave':        return this._geoWave(S);
      case 'basketWeave': return this._geoBasketWeave(S);
      case 'frenchLace':  return this._geoFrenchLace(S);
      case 'threads':     return this._geoThreads(S);
      case 'grass':       return this._geoGrass(S);

      default: return new THREE.SphereGeometry(S, 16, 16);
    }
  }

  // ── Shape/geometry factories ──────────────────────────────────────
  _starShape(pts, outer, inner) {
    var sh = new THREE.Shape();
    for (var i = 0; i < pts * 2; i++) {
      var r = i % 2 === 0 ? outer : inner;
      var a = (i / (pts * 2)) * Math.PI * 2;
      i === 0 ? sh.moveTo(Math.cos(a) * r, Math.sin(a) * r) : sh.lineTo(Math.cos(a) * r, Math.sin(a) * r);
    }
    sh.closePath(); return sh;
  }

  _merge(geos) {
    var clean = geos.map(g => g.toNonIndexed());
    return THREE.mergeGeometries(clean, false) || clean[0] || new THREE.SphereGeometry(0.01, 4, 4);
  }

  _geoRose(S) {
    var parts  = [(() => { var c = new THREE.ConeGeometry(S * 0.34, S * 0.75, 24); c.rotateX(Math.PI / 2); c.translate(0, 0, S * 0.22); return c; })()];
    [[4, 0.2, 0.45, 0.3, 0.65],[7, 0.48, 0.58, 0.18, 0.35],[10, 0.78, 0.72, 0.05, 0.1]].forEach(([n, rad, sz, z, curl]) => {
      for (var i = 0; i < n; i++) {
        var a = (i / n) * Math.PI * 2;
        var p = new THREE.SphereGeometry(sz * S, 18, 18); p.scale(0.36, 0.12, 0.72); p.rotateX(curl); p.rotateZ(a); p.translate(Math.cos(a) * rad * S, Math.sin(a) * rad * S, z * S); parts.push(p);
      }
    });
    return this._merge(parts);
  }

  _geoDropFlower(S) {
    var parts = [];
    for (var i = 0; i < 5; i++) {
      var a = (i / 5) * Math.PI * 2;
      var p = new THREE.SphereGeometry(S * 0.42, 16, 12); p.scale(1.0, 2.2, 0.35); p.rotateZ(a); p.translate(Math.cos(a) * S * 0.45, Math.sin(a) * S * 0.45, S * 0.06); parts.push(p);
      var q = new THREE.SphereGeometry(S * 0.25, 12, 10); var b = (i / 5) * Math.PI * 2 + Math.PI / 5; q.scale(0.8, 1.6, 0.3); q.rotateZ(b); q.translate(Math.cos(b) * S * 0.22, Math.sin(b) * S * 0.22, S * 0.12); parts.push(q);
    }
    var core = new THREE.SphereGeometry(S * 0.16, 14, 14); core.translate(0, 0, S * 0.15); parts.push(core);
    return this._merge(parts);
  }

  _geoLeaf(S) {
    var sh = new THREE.Shape();
    sh.moveTo(0, S * 1.45);
    sh.bezierCurveTo(-S * 0.95, S * 0.78, -S * 0.82, -S * 0.55, 0, -S * 0.95);
    sh.bezierCurveTo( S * 0.82, -S * 0.55,  S * 0.95,  S * 0.78, 0,  S * 1.45);
    var blade = new THREE.ExtrudeGeometry(sh, { depth: S * 0.22, bevelEnabled: true, bevelSize: S * 0.045, bevelThickness: S * 0.035, curveSegments: 18 }); blade.center();
    var vein  = new THREE.CylinderGeometry(S * 0.035, S * 0.055, S * 2.1, 8); vein.translate(0, S * 0.12, S * 0.16);
    var pinch = new THREE.SphereGeometry(S * 0.28, 12, 12); pinch.scale(1.5, 0.55, 0.35); pinch.translate(0, -S * 0.88, S * 0.12);
    return this._merge([blade, vein, pinch]);
  }

  _geoShell(S) {
    var parts = [], ridges = 7;
    var bGeo = new THREE.SphereGeometry(1, 32, 16, 0, Math.PI * 2, 0, Math.PI * 0.5);
    bGeo.scale(S * 1.0, S * 0.72 * 0.72, S * 0.35 * 2.2 * 0.5); parts.push(bGeo);
    var base = new THREE.BoxGeometry(S * 1.9 * 1.0, S * 0.05, S * 0.35 * 4.0); base.translate(0, -S * 0.015, 0); parts.push(base);
    for (var r = 0; r < ridges; r++) {
      var t     = r / (ridges - 1);
      var arch  = Math.cos((t - 0.5) * Math.PI);
      var pts   = [];
      for (var p = 0; p <= 24; p++) {
        var u     = p / 24;
        var x     = (u - 0.5) * S * 1.65;
        var taper = Math.sin(u * Math.PI) * (1.0 - u * 0.22);
        var wave  = Math.sin(u * Math.PI * 4.0) * S * 0.03 * taper;
        pts.push(new THREE.Vector3(x, arch * S * 0.6 * taper + wave, (t - 0.5) * S * 0.35 * 2.2));
      }
      var thick = S * (0.05 + 0.03 * arch);
      parts.push(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 24, thick, 8, false));
    }
    return this._merge(parts);
  }

  _geoHeart(S) {
    var parts = [], ridges = 7, sf = S * 1.1;
    var hx = t => sf * 0.85 * Math.pow(Math.sin(t), 3);
    var hy = t => sf * 0.85 * (0.8125 * Math.cos(t) - 0.3125 * Math.cos(2 * t) - 0.125 * Math.cos(3 * t) - 0.0625 * Math.cos(4 * t));
    for (var r = 0; r < ridges; r++) {
      var t   = r / (ridges - 1), ls = 0.28 + t * 0.72, lh = S * (0.72 - t * 0.52);
      var pts = [];
      for (var p = 0; p <= 48; p++) { var a = (p / 48) * Math.PI * 2 - Math.PI * 0.5; pts.push(new THREE.Vector3(hx(a) * ls, lh + Math.sin(a * 6) * S * 0.025 * (1 - t), hy(a) * ls)); }
      pts.push(pts[0].clone());
      parts.push(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts, true), 64, S * (0.055 + t * 0.055), 8, true));
    }
    // base ring
    var bpts = []; for (var p = 0; p <= 48; p++) { var a = (p / 48) * Math.PI * 2 - Math.PI * 0.5; bpts.push(new THREE.Vector3(hx(a) * 1.05, S * 0.02, hy(a) * 1.05)); } bpts.push(bpts[0].clone());
    parts.push(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(bpts, true), 64, S * 0.04, 6, true));
    // tip
    var tip = new THREE.SphereGeometry(S * 0.09, 10, 10); tip.translate(0, S * 0.58, -sf * 0.34); parts.push(tip);
    return this._merge(parts);
  }

  _geoWave(S) {
    var parts = [];
    var mkC = (oy, lz) => { var pts = []; for (var i = 0; i <= 72; i++) { var u = i / 72; pts.push(new THREE.Vector3((u - 0.5) * S * 4.25, Math.sin(u * Math.PI * 4 - Math.PI * 0.45) * S * 0.72 * (0.88 + Math.sin(u * Math.PI) * 0.18) + oy, lz)); } return new THREE.CatmullRomCurve3(pts); };
    parts.push(new THREE.TubeGeometry(mkC(0, S * 0.02), 90, S * 0.34, 18, false));
    for (var r = 0; r < 7; r++) parts.push(new THREE.TubeGeometry(mkC((r - 3) * S * 0.105, S * (0.28 + r * 0.012)), 90, S * 0.045, 8, false));
    var lt = new THREE.ConeGeometry(S * 0.22, S * 0.55, 16); lt.rotateZ(Math.PI / 2); lt.translate(-S * 2.2, -S * 0.2, S * 0.04); parts.push(lt);
    var rt = new THREE.ConeGeometry(S * 0.22, S * 0.55, 16); rt.rotateZ(-Math.PI / 2); rt.translate(S * 2.2, S * 0.2, S * 0.04); parts.push(rt);
    return this._merge(parts);
  }

  _geoBasketWeave(S) {
    var parts = []; var v = new THREE.BoxGeometry(S * 0.34, S * 1.95, S * 0.2); v.translate(0, 0, S * 0.06); parts.push(v);
    for (var k = -2; k <= 2; k++) { var c = new THREE.CylinderGeometry(S * 0.018, S * 0.018, S * 1.9, 5); c.translate(k * S * 0.055, 0, S * 0.18); parts.push(c); }
    for (var i = 0; i < 4; i++) { var y = -S * 0.66 + i * S * 0.44, ox = i % 2 === 0 ? -S * 0.48 : S * 0.48; var h = new THREE.BoxGeometry(S * 1.42, S * 0.22, S * 0.24); h.translate(ox, y, S * 0.14); parts.push(h); var cap = new THREE.CapsuleGeometry(S * 0.11, S * 1.25, 4, 10); cap.rotateZ(Math.PI / 2); cap.translate(ox, y, S * 0.25); parts.push(cap); }
    return this._merge(parts);
  }

  _geoFrenchLace(S) {
    var parts = [];
    var mkT   = (pts, r) => parts.push(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 28, r || S * 0.03, 6, false));
    parts.push((() => { var t = new THREE.TorusGeometry(S * 0.82, S * 0.055, 10, 64); t.translate(0, 0, S * 0.03); return t; })());
    parts.push((() => { var t = new THREE.TorusGeometry(S * 0.42, S * 0.028, 8, 48); t.translate(0, 0, S * 0.06); return t; })());
    for (var i = 0; i < 8; i++) {
      var a = (i / 8) * Math.PI * 2, n = a + Math.PI / 8;
      mkT([new THREE.Vector3(Math.cos(a) * S * 0.72, Math.sin(a) * S * 0.72, S * 0.06), new THREE.Vector3(Math.cos(n) * S * 0.98, Math.sin(n) * S * 0.98, S * 0.06), new THREE.Vector3(Math.cos(a + Math.PI / 4) * S * 0.72, Math.sin(a + Math.PI / 4) * S * 0.72, S * 0.06)], S * 0.028);
      var pe = new THREE.SphereGeometry(S * 0.075, 8, 8); pe.translate(Math.cos(a) * S * 0.82, Math.sin(a) * S * 0.82, S * 0.12); parts.push(pe);
    }
    for (var i = 0; i < 4; i++) { var a = (i / 4) * Math.PI * 2 + Math.PI / 4; mkT([new THREE.Vector3(0, 0, S * 0.08), new THREE.Vector3(Math.cos(a) * S * 0.28, Math.sin(a) * S * 0.28, S * 0.08), new THREE.Vector3(Math.cos(a) * S * 0.55, Math.sin(a) * S * 0.55, S * 0.08)], S * 0.025); }
    return this._merge(parts);
  }

  _geoThreads(S) {
    var p = [];
    for (var i = 0; i < 4; i++) { var t = new THREE.CylinderGeometry(S * 0.07, S * 0.07, S * 1.9, 8); t.rotateZ(Math.PI / 2); t.translate(0, (i - 1.5) * S * 0.23, S * 0.05); p.push(t); }
    return this._merge(p);
  }

  _geoGrass(S) {
    var blades = [];
    for (var i = 0; i < 55; i++) {
      var seed = Math.sin(i * 12.9898) * 43758.5453, noise = seed - Math.floor(seed);
      var a = (i / 55) * Math.PI * 2, h = S * (0.8 + noise * 0.5);
      var b = new THREE.CylinderGeometry(S * 0.028, S * 0.045, h, 5);
      b.rotateZ(Math.sin(i * 2.1) * 0.4); b.rotateX(Math.PI / 2 + Math.cos(i * 1.7) * 0.25);
      b.translate(Math.cos(a) * S * (0.3 + noise * 0.2), Math.sin(a) * S * (0.3 + noise * 0.2), h * 0.4);
      blades.push(b);
    }
    var base = new THREE.CylinderGeometry(S * 0.38, S * 0.4, S * 0.08, 16); base.rotateX(Math.PI / 2); blades.push(base);
    return this._merge(blades);
  }

  // ════════════════════════════════════════════════════════════════
  // Add-ons
  // ════════════════════════════════════════════════════════════════
  _addonColor(id) {
    if (this.config.addonColors && this.config.addonColors[id]) return this.config.addonColors[id];
    return { candles:'#FF6B6B', giftRibbon:'#D4A24A', bow:'#D4A24A', secretMessage:'#FFFFFF', sparklers:'#FFD700', naturalFlowers:'#FF1493', artificialFlowers:'#FF80AB', babyFlower:'#F8BBD0', butterflies:'#9C27B0', fruits:'#FF4444', babyHeartChocolate:'#3D1A0A', pearls:'#FFFFFF', sprinkles:'#FFFFFF', glitter:'#FFD700', chocoDrip:'#3D1A0A' }[id] || '#FFFFFF';
  }

  _buildAddons(group, R, H, baseY) {
    var addons = this.config.selectedAddons;
    if (!addons || !addons.length) return;

    // Enforce: bow / giftRibbon incompatible with 'full'
    if ((addons.includes('bow') || addons.includes('giftRibbon')) && this.config.pipingPlacement === 'full') {
      this.config.pipingPlacement = 'edges';
    }

    var topY    = baseY + H;
    var CAT_MAP = {
      candles:'center', giftRibbon:'center', secretMessage:'center', sparklers:'center',
      bow:'edge', naturalFlowers:'edge', artificialFlowers:'edge', babyFlower:'edge',
      butterflies:'edge', fruits:'edge', babyHeartChocolate:'edge',
      pearls:'fullring', chocoDrip:'fullring',
      sprinkles:'surface', glitter:'surface',
    };

    var center  = [], edge = [], fullring = [], surface = [];
    addons.forEach(id => {
      var c = CAT_MAP[id] || 'edge';
      if (c === 'center')   center.push(id);
      else if (c === 'edge') edge.push(id);
      else if (c === 'fullring') fullring.push(id);
      else surface.push(id);
    });

    // Surface
    surface.forEach(id => {
      if (id === 'sprinkles') this._addonSprinkles(group, R, topY, this._addonColor(id));
      if (id === 'glitter')   this._addonGlitter(group, R, topY, this._addonColor(id));
    });

    // Fullring
    fullring.forEach(id => {
      if (id === 'pearls')    this._addonPearls(group, R, topY, this._addonColor(id));
      if (id === 'chocoDrip') this._addonChocoDrip(group, R, H, baseY, this._addonColor(id));
    });

    // Edge (arc-distributed)
    var n = edge.length;
    edge.forEach((id, ei) => {
      var col = this._addonColor(id);
      var sa  = (ei / n) * Math.PI * 2;
      var arc = (Math.PI * 2) / n;
      if (id === 'bow')                this._addonBow(group, R, H, baseY, col, 0, Math.PI * 2);
      else if (id === 'naturalFlowers') this._addonNaturalFlowers(group, R, topY, col, sa, arc);
      else if (id === 'artificialFlowers') this._addonArtificialFlowers(group, R, topY, col, sa, arc);
      else if (id === 'babyFlower')     this._addonBabyFlower(group, R, topY, col, sa, arc);
      else if (id === 'butterflies')    this._addonButterflies(group, R, topY, col, sa, arc);
      else if (id === 'fruits')         this._addonFruits(group, R, topY, sa, arc);
      else if (id === 'babyHeartChocolate') this._addonBabyHeartChoco(group, R, topY, col, sa, arc);
      else if (id === 'pearls')         this._addonPearls(group, R, topY, col);
    });

    // Center
    center.forEach(id => {
      var col = this._addonColor(id);
      if (id === 'candles')       this._addonCandles(group, R, topY, col);
      if (id === 'giftRibbon')    this._addonGiftRibbon(group, R, H, baseY, col);
      if (id === 'secretMessage') this._addonSecretMessage(group, R, topY);
      if (id === 'sparklers')     this._addonSparklers(group, R, topY);
    });
  }

  // ── Addon builders ────────────────────────────────────────────────
  _addonCandles(group, R, topY, color) {
    var count = 5, cr = R * 0.5;
    var mat  = mkPhys({ color: new THREE.Color(color), roughness: 0.3, clearcoat: 0.5 });
    var fMat = new THREE.MeshStandardMaterial({ color: 0xFF8800, emissive: 0xFF6600, emissiveIntensity: 2 });
    for (var i = 0; i < count; i++) {
      var a = (i / count) * Math.PI * 2 - Math.PI * 0.5;
      var x = Math.cos(a) * cr, z = Math.sin(a) * cr;
      var stick = new THREE.Mesh(new THREE.CylinderGeometry(R * 0.018, R * 0.022, R * 0.35, 12), mat);
      stick.position.set(x, topY + R * 0.175, z); stick.castShadow = true; group.add(stick);
      var flame = new THREE.Mesh(new THREE.ConeGeometry(R * 0.02, R * 0.06, 8), fMat);
      flame.position.set(x, topY + R * 0.38, z); group.add(flame);
    }
  }

  _addonGiftRibbon(group, R, H, baseY, color) {
    var midY = baseY + H * 0.5, segs = 128, w = R * 0.048;
    var mat  = mkPhys({ color: new THREE.Color(color), roughness: 0.12, metalness: 0.12, clearcoat: 1.0, clearcoatRoughness: 0.03 });
    // Horizontal band
    var hPts = [];
    for (var i = 0; i <= segs; i++) { var a = (i / segs) * Math.PI * 2; hPts.push(new THREE.Vector3(Math.cos(a) * (R + w * 0.25), midY, Math.sin(a) * (R + w * 0.25))); }
    hPts.push(hPts[0].clone());
    group.add(new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(hPts, true), segs, w * 0.52, 12, true), mat));
    // Bow group at front
    var bw = R * 0.07;
    var g2 = new THREE.Group(); g2.position.set(0, midY, R + w * 0.3);
    var mkLoop = side => {
      var sh = new THREE.Shape();
      sh.moveTo(0, 0); sh.bezierCurveTo(side * w * 0.25, w * 3.4, side * w * 2.2, w * 3.4, side * w * 1.9, 0); sh.bezierCurveTo(side * w * 2.2, -w * 0.9, side * w * 0.25, -w * 0.9, 0, 0);
      var geo = new THREE.ExtrudeGeometry(sh, { depth: bw * 0.42, bevelEnabled: true, bevelSize: bw * 0.07, bevelThickness: bw * 0.07, curveSegments: 20 }); geo.center();
      var m   = new THREE.Mesh(geo, mat); m.position.set(side * bw * 1.3, bw * 0.1, bw * 0.22); m.rotation.z = side * 0.18; m.castShadow = true; return m;
    };
    g2.add(mkLoop(1), mkLoop(-1));
    var knot = new THREE.Mesh(new THREE.SphereGeometry(bw * 0.5, 16, 16), mat); knot.scale.set(1, 0.82, 0.68); knot.position.set(0, 0, bw * 0.26); knot.castShadow = true; g2.add(knot);
    var mkTail = side => {
      var pts = []; for (var t = 0; t <= 14; t++) { var u = t / 14; pts.push(new THREE.Vector3(side * (bw * 0.32 + u * bw * 0.45), -u * H * 0.30, bw * 0.15 - u * bw * 0.08)); }
      var m = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 16, bw * 0.16, 8, false), mat); m.castShadow = true; return m;
    };
    g2.add(mkTail(1), mkTail(-1));
    group.add(g2);
  }

  _addonBow(group, R, H, baseY, color, startA, arc) {
    var count = 4, topY = baseY + H;
    var mat   = mkPhys({ color: new THREE.Color(color), roughness: 0.15, metalness: 0.08, clearcoat: 1.0, clearcoatRoughness: 0.04 });
    for (var i = 0; i < count; i++) {
      var a = startA + (i + 0.5) / count * arc;
      var g = new THREE.Group(); g.position.set(Math.cos(a) * R, topY, Math.sin(a) * R); g.lookAt(Math.cos(a) * R * 2, topY, Math.sin(a) * R * 2);
      var w = R * 0.06;
      var mkLoop = side => {
        var sh = new THREE.Shape(); sh.moveTo(0, 0); sh.bezierCurveTo(side * w * 0.25, w * 3.4, side * w * 2.2, w * 3.4, side * w * 1.9, 0); sh.bezierCurveTo(side * w * 2.2, -w * 0.9, side * w * 0.25, -w * 0.9, 0, 0);
        var geo = new THREE.ExtrudeGeometry(sh, { depth: w * 0.45, bevelEnabled: true, bevelSize: w * 0.07, bevelThickness: w * 0.07, curveSegments: 20 }); geo.center();
        var m = new THREE.Mesh(geo, mat); m.position.set(side * w * 1.0, w * 0.15, w * 0.22); m.rotation.z = side * 0.18; m.castShadow = true; return m;
      };
      g.add(mkLoop(1), mkLoop(-1));
      var knot = new THREE.Mesh(new THREE.SphereGeometry(w * 0.52, 16, 16), mat); knot.scale.set(1, 0.82, 0.68); knot.position.set(0, 0, w * 0.28); knot.castShadow = true; g.add(knot);
      var mkTail = side => {
        var pts = []; for (var t = 0; t <= 14; t++) { var u = t / 14; pts.push(new THREE.Vector3(side * (w * 0.3 + u * w * 0.38), -u * H * 0.48, w * 0.18 - u * w * 0.1)); }
        var m = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 18, w * 0.21, 8, false), mat); m.castShadow = true; return m;
      };
      g.add(mkTail(1), mkTail(-1));
      group.add(g);
    }
  }

  _addonSecretMessage(group, R, topY) {
    var mat  = mkPhys({ color: 0xFFF8E7, roughness: 0.3, clearcoat: 0.4 });
    var env  = new THREE.Mesh(new THREE.BoxGeometry(R * 0.35, R * 0.02, R * 0.25), mat); env.position.set(0, topY + R * 0.02, 0); env.castShadow = true; group.add(env);
    var flap = new THREE.Mesh(new THREE.BoxGeometry(R * 0.35, R * 0.005, R * 0.13), mkPhys({ color: 0xFFE0B2, roughness: 0.3 }))); flap.position.set(0, topY + R * 0.035, -R * 0.06); flap.rotation.x = -0.4; group.add(flap);
    var seal = new THREE.Mesh(new THREE.CylinderGeometry(R * 0.025, R * 0.025, R * 0.005, 12), new THREE.MeshStandardMaterial({ color: 0xCC0000 })); seal.position.set(0, topY + R * 0.04, 0); group.add(seal);
  }

  _addonSparklers(group, R, topY) {
    var wMat = new THREE.MeshStandardMaterial({ color: 0xCCCCCC, metalness: 0.8 });
    var sMat = new THREE.MeshStandardMaterial({ color: 0xFFFF00, emissive: 0xFFAA00, emissiveIntensity: 3 });
    for (var i = 0; i < 3; i++) {
      var a = (i / 3) * Math.PI * 2, sx = Math.cos(a) * R * 0.35, sz = Math.sin(a) * R * 0.35;
      var wire = new THREE.Mesh(new THREE.CylinderGeometry(R * 0.006, R * 0.006, R * 0.5, 6), wMat); wire.position.set(sx, topY + R * 0.25, sz); wire.castShadow = true; group.add(wire);
      for (var j = 0; j < 8; j++) {
        var sp = new THREE.Mesh(new THREE.SphereGeometry(R * 0.012, 6, 6), sMat);
        var sa = Math.random() * Math.PI * 2, sr = R * (0.02 + Math.random() * 0.06);
        sp.position.set(sx + Math.cos(sa) * sr, topY + R * (0.45 + Math.random() * 0.15), sz + Math.sin(sa) * sr); group.add(sp);
      }
    }
  }

  _addonNaturalFlowers(group, R, topY, color, startA, arc) {
    var cnt = 4, c = new THREE.Color(color);
    var pMat  = mkPhys({ color: c, roughness: 0.3, clearcoat: 0.4 });
    var cMat  = new THREE.MeshStandardMaterial({ color: 0xFFD700 });
    for (var i = 0; i < cnt; i++) {
      var a = startA + (i + 0.5) / cnt * arc, fx = Math.cos(a) * R * 0.75, fz = Math.sin(a) * R * 0.75;
      for (var p = 0; p < 6; p++) { var pa = (p / 6) * Math.PI * 2; var petal = new THREE.Mesh(new THREE.SphereGeometry(R * 0.055, 10, 10), pMat); petal.scale.set(1.5, 0.35, 1.2); petal.position.set(fx + Math.cos(pa) * R * 0.06, topY + R * 0.06, fz + Math.sin(pa) * R * 0.06); group.add(petal); }
      var core = new THREE.Mesh(new THREE.SphereGeometry(R * 0.03, 10, 10), cMat); core.position.set(fx, topY + R * 0.07, fz); group.add(core);
    }
  }

  _addonArtificialFlowers(group, R, topY, color, startA, arc) {
    var cnt = 5, c = new THREE.Color(color);
    var pMat = mkPhys({ color: c, roughness: 0.25, clearcoat: 0.6 });
    var cMat = new THREE.MeshStandardMaterial({ color: 0xFFEE58 });
    for (var i = 0; i < cnt; i++) {
      var a = startA + (i + 0.5) / cnt * arc, fx = Math.cos(a) * R * 0.7, fz = Math.sin(a) * R * 0.7;
      for (var p = 0; p < 5; p++) { var pa = (p / 5) * Math.PI * 2; var petal = new THREE.Mesh(new THREE.SphereGeometry(R * 0.048, 10, 10), pMat); petal.scale.set(1.8, 0.25, 1.3); petal.position.set(fx + Math.cos(pa) * R * 0.055, topY + R * 0.045, fz + Math.sin(pa) * R * 0.055); group.add(petal); }
      var core = new THREE.Mesh(new THREE.SphereGeometry(R * 0.022, 8, 8), cMat); core.position.set(fx, topY + R * 0.055, fz); group.add(core);
    }
  }

  _addonBabyFlower(group, R, topY, color, startA, arc) {
    var cnt = 6, c = new THREE.Color(color);
    var pMat = mkPhys({ color: c, roughness: 0.3, clearcoat: 0.5 });
    var cMat = new THREE.MeshStandardMaterial({ color: 0xFFE0B2 });
    for (var i = 0; i < cnt; i++) {
      var a = startA + (i + 0.5) / cnt * arc, fx = Math.cos(a) * R * 0.7, fz = Math.sin(a) * R * 0.7;
      for (var p = 0; p < 5; p++) { var pa = (p / 5) * Math.PI * 2; var petal = new THREE.Mesh(new THREE.SphereGeometry(R * 0.03, 8, 8), pMat); petal.scale.set(1.3, 0.3, 1.1); petal.position.set(fx + Math.cos(pa) * R * 0.03, topY + R * 0.035, fz + Math.sin(pa) * R * 0.03); group.add(petal); }
      var core = new THREE.Mesh(new THREE.SphereGeometry(R * 0.015, 8, 8), cMat); core.position.set(fx, topY + R * 0.04, fz); group.add(core);
    }
  }

  _addonButterflies(group, R, topY, color, startA, arc) {
    var cnt = 3, c = new THREE.Color(color);
    var wMat = mkPhys({ color: c, roughness: 0.2, clearcoat: 0.6, side: THREE.DoubleSide });
    var bMat = new THREE.MeshStandardMaterial({ color: 0x1A1A1A });
    var sMat = new THREE.MeshStandardMaterial({ color: 0xFFFFFF });
    for (var i = 0; i < cnt; i++) {
      var a = startA + (i + 0.5) / cnt * arc;
      var g = new THREE.Group(); g.position.set(Math.cos(a) * R * 0.7, topY + R * 0.22, Math.sin(a) * R * 0.7); g.rotation.y = -a + Math.PI * 0.5;
      var body = new THREE.Mesh(new THREE.CapsuleGeometry(R * 0.012, R * 0.07, 4, 8), bMat); body.rotation.z = Math.PI * 0.1; g.add(body);
      var head = new THREE.Mesh(new THREE.SphereGeometry(R * 0.016, 8, 8), bMat); head.position.set(0, R * 0.05, 0); g.add(head);
      for (var s = -1; s <= 1; s += 2) {
        var ant = new THREE.Mesh(new THREE.CylinderGeometry(R * 0.003, R * 0.003, R * 0.04, 4), bMat); ant.position.set(s * R * 0.012, R * 0.08, 0); ant.rotation.z = s * 0.5; g.add(ant);
        var tip = new THREE.Mesh(new THREE.SphereGeometry(R * 0.005, 6, 6), bMat); tip.position.set(s * R * 0.025, R * 0.1, 0); g.add(tip);
      }
      var ws = R * 0.14, uSh = new THREE.Shape();
      uSh.moveTo(0, 0); uSh.bezierCurveTo(ws * 0.5, ws * 0.3, ws * 1.1, ws * 0.6, ws * 0.8, ws); uSh.bezierCurveTo(ws * 0.5, ws * 1.2, ws * 0.1, ws * 0.8, 0, ws * 0.5); uSh.bezierCurveTo(-ws * 0.1, ws * 0.8, -ws * 0.5, ws * 1.2, -ws * 0.8, ws); uSh.bezierCurveTo(-ws * 1.1, ws * 0.6, -ws * 0.5, ws * 0.3, 0, 0);
      var uGeo = new THREE.ShapeGeometry(uSh);
      for (var s = -1; s <= 1; s += 2) { var uw = new THREE.Mesh(uGeo, wMat); uw.position.set(s * R * 0.015, R * 0.02, -R * 0.01); uw.rotation.y = s * 0.15; g.add(uw); var spot = new THREE.Mesh(new THREE.CircleGeometry(R * 0.015, 8), sMat); spot.position.set(s * R * 0.06, R * 0.06, s * R * 0.005); g.add(spot); }
      var ls = R * 0.09, lSh = new THREE.Shape();
      lSh.moveTo(0, 0); lSh.bezierCurveTo(ls * 0.6, -ls * 0.2, ls * 0.9, -ls * 0.6, ls * 0.5, -ls * 0.8); lSh.bezierCurveTo(ls * 0.2, -ls * 0.7, 0, -ls * 0.3, 0, 0);
      var lGeo = new THREE.ShapeGeometry(lSh);
      for (var s = -1; s <= 1; s += 2) { var lw = new THREE.Mesh(lGeo, wMat); lw.position.set(s * R * 0.012, -R * 0.02, -R * 0.01); lw.rotation.y = s * 0.15; g.add(lw); }
      group.add(g);
    }
  }

  _addonFruits(group, R, topY, startA, arc) {
    [{ off: 0.15, type: 'strawberry' }, { off: 0.4, type: 'blueberry' }, { off: 0.65, type: 'raspberry' }, { off: 0.85, type: 'blueberry' }].forEach(item => {
      var a = startA + item.off * arc, fx = Math.cos(a) * R * 0.65, fz = Math.sin(a) * R * 0.65;
      if (item.type === 'strawberry') {
        var b = new THREE.Mesh(new THREE.ConeGeometry(R * 0.045, R * 0.08, 10), mkPhys({ color: 0xCC2222, roughness: 0.4, clearcoat: 0.5 })); b.position.set(fx, topY + R * 0.06, fz); b.castShadow = true; group.add(b);
        var lf = new THREE.Mesh(new THREE.SphereGeometry(R * 0.02, 8, 8), new THREE.MeshStandardMaterial({ color: 0x228B22 })); lf.scale.set(1.5, 0.3, 1); lf.position.set(fx, topY + R * 0.1, fz); group.add(lf);
      } else if (item.type === 'raspberry') {
        var rb = new THREE.Mesh(new THREE.SphereGeometry(R * 0.035, 12, 12), mkPhys({ color: 0xB71C1C, roughness: 0.5, clearcoat: 0.3 })); rb.position.set(fx, topY + R * 0.04, fz); rb.castShadow = true; group.add(rb);
      } else {
        var bb = new THREE.Mesh(new THREE.SphereGeometry(R * 0.03, 12, 12), mkPhys({ color: 0x2244AA, roughness: 0.3, clearcoat: 0.6 })); bb.position.set(fx, topY + R * 0.035, fz); bb.castShadow = true; group.add(bb);
      }
    });
  }

  _addonBabyHeartChoco(group, R, topY, color, startA, arc) {
    var cnt = 5, mat = mkPhys({ color: new THREE.Color(color), roughness: 0.25, clearcoat: 0.7 });
    for (var i = 0; i < cnt; i++) {
      var a = startA + (i + 0.5) / cnt * arc, hx = Math.cos(a) * R * 0.7, hz = Math.sin(a) * R * 0.7;
      var l = new THREE.Mesh(new THREE.SphereGeometry(R * 0.03, 10, 10), mat); l.position.set(hx - R * 0.018, topY + R * 0.04, hz); group.add(l);
      var r = new THREE.Mesh(new THREE.SphereGeometry(R * 0.03, 10, 10), mat); r.position.set(hx + R * 0.018, topY + R * 0.04, hz); group.add(r);
      var tip = new THREE.Mesh(new THREE.ConeGeometry(R * 0.042, R * 0.05, 10), mat); tip.position.set(hx, topY + R * 0.01, hz); tip.rotation.z = Math.PI; group.add(tip);
    }
  }

  _addonPearls(group, R, topY, color) {
    var cnt = 24, mat = mkPhys({ color: new THREE.Color(color), roughness: 0.05, clearcoat: 1, clearcoatRoughness: 0.02, metalness: 0.1 });
    for (var i = 0; i < cnt; i++) { var a = (i / cnt) * Math.PI * 2; var p = new THREE.Mesh(new THREE.SphereGeometry(R * 0.028, 14, 14), mat); p.position.set(Math.cos(a) * R * 0.85, topY + R * 0.035, Math.sin(a) * R * 0.85); p.castShadow = true; group.add(p); }
  }

  _addonSprinkles(group, R, topY, color) {
    var cnt = 50, c = new THREE.Color(color);
    for (var i = 0; i < cnt; i++) {
      var a = Math.random() * Math.PI * 2, d = Math.random() * R * 0.75;
      var sp = new THREE.Mesh(new THREE.SphereGeometry(R * 0.012, 8, 8), mkPhys({ color: c, roughness: 0.15, clearcoat: 0.8, metalness: (color === '#D4A24A' || color === '#B0BEC5') ? 0.5 : 0 }));
      sp.position.set(Math.cos(a) * d, topY + R * 0.015, Math.sin(a) * d); group.add(sp);
    }
  }

  _addonGlitter(group, R, topY, color) {
    var cnt = 80, c = new THREE.Color(color);
    var mat = new THREE.MeshStandardMaterial({ color: c, emissive: c, emissiveIntensity: 0.6, metalness: 0.8, roughness: 0.1 });
    for (var i = 0; i < cnt; i++) {
      var a = Math.random() * Math.PI * 2, d = Math.random() * R * 0.8;
      var gl = new THREE.Mesh(new THREE.OctahedronGeometry(R * (0.006 + Math.random() * 0.008), 0), mat);
      gl.position.set(Math.cos(a) * d, topY + R * 0.01, Math.sin(a) * d);
      gl.rotation.set(Math.random() * Math.PI, Math.random() * Math.PI, Math.random() * Math.PI); group.add(gl);
    }
  }

  _addonChocoDrip(group, R, H, baseY, color) {
    var cnt = 16, mat = mkPhys({ color: new THREE.Color(color), roughness: 0.15, clearcoat: 0.8 });
    var top = new THREE.Mesh(new THREE.CylinderGeometry(R, R, R * 0.02, 48), mat); top.position.y = baseY + H + R * 0.01; group.add(top);
    for (var i = 0; i < cnt; i++) {
      var a = (i / cnt) * Math.PI * 2, dl = R * (0.08 + Math.random() * 0.18);
      var drip = new THREE.Mesh(new THREE.CylinderGeometry(R * 0.025, R * 0.008, dl, 8), mat); drip.position.set(Math.cos(a) * R, baseY + H - dl * 0.5, Math.sin(a) * R); drip.castShadow = true; group.add(drip);
      var tip = new THREE.Mesh(new THREE.SphereGeometry(R * 0.018, 8, 8), mat); tip.position.set(Math.cos(a) * R, baseY + H - dl, Math.sin(a) * R); group.add(tip);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Teardown
  // ════════════════════════════════════════════════════════════════
  destroy() {
    this._disposed = true;
    if (this._debounce) { clearTimeout(this._debounce); this._debounce = null; }
    if (this.animId)    cancelAnimationFrame(this.animId);
    window.removeEventListener('resize', this._onResize);
    if (this._resizeObs) this._resizeObs.disconnect();
    this._disposeCakeGroup();
    this._geoCache.clear();
    if (this.controls)  this.controls.dispose();
    if (this.renderer)  this.renderer.dispose();
    if (this.container) this.container.innerHTML = '';
  }
}

// ════════════════════════════════════════════════════════════════════
// Container retry with exponential back-off (max ~5 s)
// ════════════════════════════════════════════════════════════════════
function withContainerRetry(containerId, cb, attempt) {
  attempt = attempt || 0;
  var container = document.getElementById(containerId);
  var ready      = container && container.clientWidth > 10 && container.clientHeight > 10;

  if (!ready) {
    if (attempt >= 20) {
      if (container) { console.warn('[CakeDesigner] Container very small, proceeding anyway.'); cb(container); }
      else console.error('[CakeDesigner] Container not found after 5 s:', containerId);
      return;
    }
    var delay = Math.min(100 * Math.pow(1.3, attempt), 1000);
    setTimeout(() => withContainerRetry(containerId, cb, attempt + 1), delay);
    return;
  }
  cb(container);
}

// ════════════════════════════════════════════════════════════════════
// Public API
// ════════════════════════════════════════════════════════════════════
window.cakeDesigner = {
  mount(containerId, config) {
    if (_instances.has(containerId)) { _instances.get(containerId).updateConfig(config); return; }
    withContainerRetry(containerId, container => {
      if (_instances.has(containerId)) { _instances.get(containerId).updateConfig(config); return; }
      _instances.set(containerId, new CakeDesignerInstance(container, config));
    });
  },
  updateConfig(containerId, config) {
    var inst = _instances.get(containerId); if (inst) inst.updateConfig(config);
  },
  resetCamera(containerId) {
    var inst = _instances.get(containerId); if (inst) inst.resetCamera();
  },
  captureScreenshot(containerId) {
    var inst = _instances.get(containerId); return inst ? inst.captureScreenshot() : null;
  },
  dispose(containerId) {
    var inst = _instances.get(containerId); if (!inst) return; inst.destroy(); _instances.delete(containerId);
  },
};

console.log('[CakeDesigner] Bridge loaded ✓  window.cakeDesigner =', typeof window.cakeDesigner);
