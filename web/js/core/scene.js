/**
 * scene.js — Renderer, camera, lights and floor.
 * Production tuned: adaptive DPR/shadows, precompiled shaders, frustum culling,
 * smaller light count on low-end devices, and thorough disposal.
 */
(function (root) {
  'use strict';

  class CakeScene {
    constructor(container, hooks) {
      this.container = container;
      this.hooks = hooks || {};
      this.renderer = null;
      this.camera = null;
      this.scene = null;
      this.controls = null;
      this.profile = (root.CD.Perf && root.CD.Perf.profile()) || { dpr: 1.5, low: false, shadowMapSize: 1024, antialias: true };
      this._lastW = 0;
      this._lastH = 0;
      this._ownedTextures = [];
      this._contextLost = false;
      this._qualityMode = 'auto';
      this._qualityScale = 1;
      this._onContextLost = null;
      this._onContextRestored = null;

      this._build();
      this._addLights();
      this._addFloor();
    }

    _readSize() {
      const rect = this.container.getBoundingClientRect();
      const w = Math.max(Math.floor(rect.width || this.container.clientWidth || 1), 1);
      const h = Math.max(Math.floor(rect.height || this.container.clientHeight || 1), 1);
      return { w, h };
    }

    _build() {
      const { w, h } = this._readSize();
      this._lastW = w;
      this._lastH = h;

      this.renderer = new THREE.WebGLRenderer({
        antialias: this.profile.antialias,
        alpha: false,
        preserveDrawingBuffer: false,
        powerPreference: 'high-performance',
      });
      this.renderer.setPixelRatio(this._effectiveDpr());
      this.renderer.setSize(w, h, false);
      this.renderer.shadowMap.enabled = true;
      this.renderer.shadowMap.type = this.profile.low ? THREE.PCFShadowMap : THREE.PCFSoftShadowMap;
      this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
      this.renderer.toneMappingExposure = 1.15;
      if ('outputColorSpace' in this.renderer) this.renderer.outputColorSpace = THREE.SRGBColorSpace;

      const c = this.renderer.domElement;
      c.style.cssText = [
        'display:block', 'width:100%', 'height:100%', 'max-width:100%', 'max-height:100%',
        'position:absolute', 'top:0', 'left:0', 'box-sizing:border-box',
        'touch-action:none', 'user-select:none', '-webkit-user-select:none',
      ].join(';');

      this._onContextLost = (event) => {
        event.preventDefault();
        this._contextLost = true;
        this.hooks.error && this.hooks.error('webgl-context-lost');
      };
      this._onContextRestored = () => {
        this._contextLost = false;
        this.hooks.invalidate && this.hooks.invalidate('webgl-context-restored');
      };
      c.addEventListener('webglcontextlost', this._onContextLost, false);
      c.addEventListener('webglcontextrestored', this._onContextRestored, false);

      this.container.innerHTML = '';
      this.container.appendChild(c);

      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x1a1f2e);
      this.scene.fog = new THREE.FogExp2(0x1a1f2e, this.profile.low ? 0.014 : 0.018);

      this.camera = new THREE.PerspectiveCamera(32, w / h, 0.1, 80);
      this.camera.position.set(2.05, 1.55, 2.35);

      this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
      this.controls.enableDamping = true;
      this.controls.dampingFactor = 0.08;
      this.controls.minDistance = 1.05;
      this.controls.maxDistance = 5.6;
      this.controls.maxPolarAngle = Math.PI * 0.75;
      this.controls.target.set(0, 0.52, 0);
      this.controls.onChange = () => this.hooks.invalidate && this.hooks.invalidate('controls');
      this.controls.update();
    }

    _effectiveDpr() {
      const base = this.profile.dpr || 1;
      if (this._qualityMode === 'low') return Math.min(base, 1.0);
      if (this._qualityMode === 'medium') return Math.min(base, 1.35);
      if (this._qualityMode === 'high') return Math.min(window.devicePixelRatio || 1, 2.0);
      return Math.max(0.75, base * this._qualityScale);
    }

    setQuality(mode) {
      this._qualityMode = mode || 'auto';
      this._qualityScale = 1;
      if (this.renderer) this.renderer.setPixelRatio(this._effectiveDpr());
      this.hooks.invalidate && this.hooks.invalidate('quality-change');
    }

    degradeQuality(reason) {
      if (this._qualityMode !== 'auto' || this._qualityScale <= 0.72) return false;
      this._qualityScale = Math.max(0.72, this._qualityScale - 0.14);
      if (this.renderer) this.renderer.setPixelRatio(this._effectiveDpr());
      this.hooks.error && this.hooks.error('quality-degraded', { reason: reason || 'slow-frame', dpr: this._effectiveDpr() });
      this.hooks.invalidate && this.hooks.invalidate('quality-degraded');
      return true;
    }

    _addLights() {
      this.scene.add(new THREE.AmbientLight(0xffe8cc, this.profile.low ? 0.72 : 0.55));

      const key = new THREE.DirectionalLight(0xffd9a8, this.profile.low ? 1.15 : 1.3);
      key.position.set(4, 8, 4);
      key.castShadow = true;
      key.shadow.mapSize.set(this.profile.shadowMapSize, this.profile.shadowMapSize);
      const s = key.shadow.camera;
      s.near = 0.5; s.far = 13; s.left = -2.2; s.right = 2.2; s.top = 2.2; s.bottom = -2.2;
      key.shadow.bias = -0.00045;
      this.scene.add(key);

      const fill = new THREE.DirectionalLight(0xffc088, this.profile.low ? 0.38 : 0.5);
      fill.position.set(-4, 4, -4);
      this.scene.add(fill);

      if (!this.profile.low) {
        const rimPoint = new THREE.PointLight(0xffcc88, 0.85, 10);
        rimPoint.position.set(0, 1.2, -2.2);
        this.scene.add(rimPoint);

        const top = new THREE.PointLight(0xffeebb, 0.28, 6);
        top.position.set(0, 2.5, 0);
        this.scene.add(top);
      }

      const loader = new THREE.TextureLoader();
      loader.load('glow.png', (glowTex) => {
        if (!this.scene) { glowTex.dispose(); return; }
        this._ownedTextures.push(glowTex);
        glowTex.colorSpace = THREE.SRGBColorSpace;
        const glow = new THREE.Mesh(
          new THREE.PlaneGeometry(3.5, 3.5),
          new THREE.MeshBasicMaterial({
            map: glowTex,
            transparent: true,
            opacity: this.profile.low ? 0.14 : 0.22,
            depthWrite: false,
            blending: THREE.AdditiveBlending,
            color: 0xffcc88,
          }),
        );
        glow.rotation.x = -Math.PI / 2;
        glow.position.y = 0.011;
        glow.renderOrder = -1;
        this.scene.add(glow);
        this.hooks.invalidate && this.hooks.invalidate('glow-loaded');
      }, undefined, () => {
        this.hooks.error && this.hooks.error('glow-load-failed');
      });
    }

    _addFloor() {
      const shadowPlane = new THREE.Mesh(
        new THREE.PlaneGeometry(8, 8),
        new THREE.ShadowMaterial({ opacity: this.profile.low ? 0.42 : 0.58 }),
      );
      shadowPlane.rotation.x = -Math.PI / 2;
      shadowPlane.receiveShadow = true;
      this.scene.add(shadowPlane);

      const floorTex = root.CD.MarbleTexture.create(this.profile);
      const floorMat = new THREE.MeshStandardMaterial({
        map: floorTex,
        color: 0xffffff,
        roughness: 0.28,
        metalness: this.profile.low ? 0.18 : 0.32,
      });
      floorMat.userData.keepTextureMaps = true;
      const floor = new THREE.Mesh(
        new THREE.PlaneGeometry(16, 16),
        floorMat,
      );
      floor.rotation.x = -Math.PI / 2;
      floor.position.y = -0.01;
      floor.receiveShadow = !this.profile.low;
      this.scene.add(floor);

      if (this.renderer && typeof this.renderer.compile === 'function') {
        try { this.renderer.compile(this.scene, this.camera); } catch (_) {}
      }
    }

    handleResize() {
      const { w, h } = this._readSize();
      if (w === this._lastW && h === this._lastH) return false;
      this._lastW = w;
      this._lastH = h;
      this.camera.aspect = w / h;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(w, h, false);
      if (this.controls) this.controls.update();
      return true;
    }

    resetCamera() {
      this.camera.position.set(2.05, 1.55, 2.35);
      this.controls.target.set(0, 0.52, 0);
      this.controls.update();
      this.hooks.invalidate && this.hooks.invalidate('reset-camera');
    }

    captureScreenshot(options) {
      options = options || {};
      const canvas = this.renderer.domElement;
      const old = {
        dpr: this.renderer.getPixelRatio(),
        w: canvas.width,
        h: canvas.height,
        cssW: canvas.style.width,
        cssH: canvas.style.height,
      };

      const width = Math.max(1, Math.floor(options.width || canvas.width));
      const height = Math.max(1, Math.floor(options.height || canvas.height));
      const type = options.type || 'image/png';
      const quality = options.quality == null ? 0.92 : options.quality;

      if (options.width && options.height) {
        this.renderer.setPixelRatio(1);
        this.renderer.setSize(width, height, false);
        this.camera.aspect = width / height;
        this.camera.updateProjectionMatrix();
      }

      if (this._contextLost) return null;
      this.renderer.render(this.scene, this.camera);
      let out = null;
      try { out = canvas.toDataURL(type, quality); }
      catch (e) { this.hooks.error && this.hooks.error('capture-failed', e); }

      if (options.width && options.height) {
        this.renderer.setPixelRatio(old.dpr);
        this.renderer.setSize(this._lastW, this._lastH, false);
        this.camera.aspect = this._lastW / this._lastH;
        this.camera.updateProjectionMatrix();
        this.hooks.invalidate && this.hooks.invalidate('capture-restore');
      }
      return out;
    }

    dispose() {
      const canvas = this.renderer && this.renderer.domElement;
      if (canvas && this._onContextLost) canvas.removeEventListener('webglcontextlost', this._onContextLost);
      if (canvas && this._onContextRestored) canvas.removeEventListener('webglcontextrestored', this._onContextRestored);
      if (this.controls) this.controls.dispose();
      if (this.scene) root.CD.Disposal.disposeObject(this.scene);
      for (const tex of this._ownedTextures) tex.dispose();
      this._ownedTextures.length = 0;
      if (this.renderer) {
        this.renderer.renderLists && this.renderer.renderLists.dispose();
        this.renderer.dispose();
        try { this.renderer.forceContextLoss(); } catch (_) {}
      }
      if (this.container) this.container.innerHTML = '';
      this.renderer = this.camera = this.scene = this.controls = null;
    }
  }

  root.CD = root.CD || {};
  root.CD.Scene = CakeScene;
})(window);
