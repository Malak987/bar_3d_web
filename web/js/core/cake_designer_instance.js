/**
 * cake_designer_instance.js — per-container instance.
 * Diff based rebuilds are preserved. Rendering is now invalidation driven: no
 * continuous RAF while idle, but still smooth during damping / auto-rotate.
 */
(function (root) {
  'use strict';

  const C = root.CD;

  class CakeDesignerInstance {
    constructor(container, config) {
      this.disposed = false;
      this.visible = !document.hidden;
      this.inViewport = true;
      this._needsRender = true;
      this._slowFrames = 0;
      this._animId = null;
      this._updateTimer = null;
      this._resizeTimer = null;
      this._lastError = null;
      this._metadata = {};

      this.invalidate = this.invalidate.bind(this);
      // Bind these here (before Scene/_apply run) because both can
      // synchronously trigger invalidate() -> requestAnimationFrame(this._animate)
      // during setup. If _animate isn't bound yet at that point, it gets
      // scheduled unbound and later throws "Cannot set properties of
      // undefined (setting '_animId')" in strict mode.
      this._animate = this._animate.bind(this);
      this._scheduleResize = this._scheduleResize.bind(this);
      this._onVisibility = this._onVisibility.bind(this);

      this.scene = new C.Scene(container, {
        invalidate: this.invalidate,
        error: (code, error) => this._handleError(code, error),
      });
      this.geoPool = new C.GeometryPool();
      this.matPool = new C.MaterialPool();
      this._config = null;

      this.rootGroup = new THREE.Group();
      this.bodyGroup = new THREE.Group();
      this.pipingGroup = new THREE.Group();
      this.topGroup = new THREE.Group();
      this.addonsGroup = new THREE.Group();
      this.plateGroup = new THREE.Group();
      this.rootGroup.add(this.plateGroup, this.bodyGroup, this.pipingGroup, this.topGroup, this.addonsGroup);
      this.scene.scene.add(this.rootGroup);

      this.autoRotate = !!config.autoRotate;
      this._apply(C.Config.normalize(config), null);

      window.addEventListener('resize', this._scheduleResize, { passive: true });
      document.addEventListener('visibilitychange', this._onVisibility);
      if (typeof ResizeObserver !== 'undefined') {
        this._ro = new ResizeObserver(this._scheduleResize);
        this._ro.observe(container);
      }
      if (typeof IntersectionObserver !== 'undefined') {
        this._io = new IntersectionObserver((entries) => {
          const entry = entries && entries[0];
          this.inViewport = !entry || entry.isIntersecting;
          if (this.inViewport) this.invalidate('viewport-visible');
        }, { threshold: 0.01 });
        this._io.observe(container);
      }

      setTimeout(() => { if (!this.disposed && this.scene.handleResize()) this.invalidate('initial-resize'); }, 0);
      setTimeout(() => { if (!this.disposed && this.scene.handleResize()) this.invalidate('settled-resize'); }, 180);
      this.invalidate('mount');
      C.Perf.post('ready', { id: container.id });
    }

    updateConfig(rawCfg) {
      const next = C.Config.normalize(rawCfg);
      this.autoRotate = !!next.autoRotate;
      if (this._updateTimer) clearTimeout(this._updateTimer);
      this._updateTimer = setTimeout(() => {
        this._updateTimer = null;
        if (this.disposed) return;
        const prev = this._config;
        try {
          this._apply(next, prev);
          this.invalidate('config');
        } catch (e) {
          this._handleError('apply-config-failed', e);
        }
      }, 40);
    }

    resetCamera() { this.scene.resetCamera(); }
    setQuality(mode) { this.scene.setQuality(mode || 'auto'); }
    captureScreenshot(options) { return this.scene.captureScreenshot(options); }
    capturePreviewImage() { return this.captureScreenshot({ width: 512, height: 512, type: 'image/jpeg', quality: 0.82 }); }
    captureFinalImage() { return this.captureScreenshot({ width: 1600, height: 1600, type: 'image/png' }); }
    exportCustomizationJSON() { return JSON.stringify(this._config || {}, null, 2); }
    exportSelectedOptionsMetadata(extra) {
      return JSON.stringify(Object.assign({}, this._metadata, extra || {}, {
        config: this._config,
        renderer: this.getStats(),
      }));
    }
    exportPackage(extra) {
      const payload = {
        finalImage: this.captureFinalImage(),
        previewImage: this.capturePreviewImage(),
        customizationJson: this._config || {},
        metadata: Object.assign({}, this._metadata, extra || {}),
        price: extra && extra.price,
        stats: this.getStats(),
      };
      return JSON.stringify(payload);
    }
    getStats() {
      const info = this.scene && this.scene.renderer ? this.scene.renderer.info : null;
      return info ? {
        geometries: info.memory.geometries,
        textures: info.memory.textures,
        calls: info.render.calls,
        triangles: info.render.triangles,
        points: info.render.points,
        lines: info.render.lines,
        profile: this.scene.profile,
      } : {};
    }

    dispose() {
      this.disposed = true;
      if (this._updateTimer) clearTimeout(this._updateTimer);
      if (this._resizeTimer) clearTimeout(this._resizeTimer);
      if (this._animId) cancelAnimationFrame(this._animId);
      window.removeEventListener('resize', this._scheduleResize);
      document.removeEventListener('visibilitychange', this._onVisibility);
      if (this._ro) this._ro.disconnect();
      if (this._io) this._io.disconnect();
      this._clear(this.plateGroup); this._clear(this.bodyGroup); this._clear(this.pipingGroup); this._clear(this.topGroup); this._clear(this.addonsGroup);
      if (this.rootGroup && this.rootGroup.parent) this.rootGroup.parent.remove(this.rootGroup);
      this.geoPool.dispose();
      this.matPool.dispose();
      this.scene.dispose();
      this.rootGroup = this.bodyGroup = this.pipingGroup = this.topGroup = this.addonsGroup = this.plateGroup = null;
    }

    invalidate() {
      if (this.disposed || !this.visible) return;
      this._needsRender = true;
      if (!this._animId) this._animId = requestAnimationFrame(this._animate);
    }

    _onVisibility() {
      this.visible = !document.hidden;
      if (this.visible) this.invalidate('visible');
    }

    _scheduleResize() {
      if (this._resizeTimer) clearTimeout(this._resizeTimer);
      this._resizeTimer = setTimeout(() => {
        this._resizeTimer = null;
        if (!this.disposed && this.scene.handleResize()) this.invalidate('resize');
      }, 70);
    }

    _animate() {
      this._animId = null;
      if (this.disposed || !this.visible) return;
      let moving = false;
      if (this.scene.controls) {
        this.scene.controls.autoRotate = false;
        moving = !!this.scene.controls.update();
      }
      if (this.rootGroup && this.autoRotate) {
        this.rootGroup.rotation.y += 0.003;
        moving = true;
      }
      if ((this._needsRender || moving) && !this.scene._contextLost) {
        this._needsRender = false;
        const t0 = performance.now();
        this.scene.renderer.render(this.scene.scene, this.scene.camera);
        const renderMs = performance.now() - t0;
        if (moving && renderMs > 28) this._slowFrames++;
        else this._slowFrames = Math.max(0, this._slowFrames - 1);
        if (this._slowFrames >= 6) {
          this._slowFrames = 0;
          this.scene.degradeQuality('slow-render-' + Math.round(renderMs) + 'ms');
        }
      }
      if (moving || this.autoRotate || this._needsRender) {
        this._animId = requestAnimationFrame(this._animate);
      }
    }

    _apply(next, prev) {
      const FLAGS = C.Diff.FLAGS;
      const dirty = C.Diff.diff(prev, next);
      const R = next.cakeRadius, H = next.cakeHeight, baseY = 0.1;

      if (dirty.has(FLAGS.TRANSFORM)) {
        const s = next.cakeScale;
        this.rootGroup.scale.set(s, s, s);
        this.rootGroup.position.y = 0.02;
      }
      if (dirty.has(FLAGS.PLATE)) {
        this._clear(this.plateGroup);
        C.PlateBuilder.build(this.plateGroup, R, baseY);
        C.Perf.enableCulling(this.plateGroup);
      }
      if (dirty.has(FLAGS.BODY)) {
        this._clear(this.bodyGroup);
        const built = C.BodyBuilder.build(this.bodyGroup, next, R, H, baseY, this.matPool);
        this._topColor = built.topColor;
        C.Perf.enableCulling(this.bodyGroup);
      }
      if (dirty.has(FLAGS.TOP) || dirty.has(FLAGS.BODY)) {
        this._clear(this.topGroup);
        const topBg = this._topColor || C.BodyBuilder.resolveTopColor(next);
        const hasText = next.text && next.text.trim().length > 0;
        const hasImage = !!next.topImage;
        const BLOCK = ['giftRibbon', 'bow', 'naturalFlowers', 'artificialFlowers', 'babyFlower', 'fruits', 'babyHeartChocolate', 'pearls', 'chocoDrip', 'sprinkles', 'glitter'];
        const blocked = next.selectedAddons.some((a) => BLOCK.indexOf(a) !== -1);
        if (hasText || hasImage || !blocked) C.TopCanvasBuilder.build(this.topGroup, next, R, baseY + H + 0.003, topBg);
      }
      if (dirty.has(FLAGS.PIPING)) {
        this._clear(this.pipingGroup);
        C.PipingBuilder.build(this.pipingGroup, next, R, H, baseY, { geo: this.geoPool, mat: this.matPool });
        C.Perf.enableCulling(this.pipingGroup);
      }
      if (dirty.has(FLAGS.ADDONS)) {
        this._clear(this.addonsGroup);
        C.AddonsBuilder.build(this.addonsGroup, next, R, H, baseY);
        C.Perf.enableCulling(this.addonsGroup);
      }
      this._metadata = {
        selectedAddons: next.selectedAddons.slice(),
        addonColors: Object.assign({}, next.addonColors),
        size: { radius: R, height: H, scale: next.cakeScale },
        piping: { type: next.pipingType, placement: next.pipingPlacement, size: next.pipingSize },
        flavor: next.baseFlavor,
        updatedAt: new Date().toISOString(),
      };
      this._config = next;
    }

    _clear(group) {
      if (!group) return;
      group.userData.topBuildToken = (group.userData.topBuildToken || 0) + 1;
      while (group.children.length) {
        const c = group.children.pop();
        C.Disposal.disposeObject(c, {
          keepGeometry: (g) => this._isPooled(g),
          keepMaterial: (m) => this._isPooledMat(m) || (m && m.userData && m.userData.shared),
        });
      }
    }

    _isPooled(geo) { for (const g of this.geoPool.cache.values()) if (g === geo) return true; return false; }
    _isPooledMat(mat) { for (const m of this.matPool.cache.values()) if (m === mat) return true; return false; }

    _handleError(code, error) {
      this._lastError = { code, message: error && (error.message || String(error)), at: Date.now() };
      C.Perf.post('error', this._lastError);
      console.warn('[CakeDesigner]', code, error || '');
    }
  }

  root.CD = root.CD || {};
  root.CD.Instance = CakeDesignerInstance;
})(window);