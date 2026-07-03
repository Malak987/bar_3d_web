/**
 * orbit_controls.js — Smooth OrbitControls (mouse + touch)
 * Tuned for buttery-smooth rotation with proper damping.
 * No hard clamps — uses momentum-based physics for natural feel.
 */
(function () {
  'use strict';
  if (typeof THREE === 'undefined' || THREE.OrbitControls) return;

  THREE.OrbitControls = function (camera, dom) {
    const scope = this;
    this.camera   = camera;
    this.domElement = dom;
    this.target   = new THREE.Vector3();
    this.enableDamping = true;
    this.dampingFactor = 0.1;
    this.rotateSpeed   = 0.42;
    this.zoomSpeed     = 0.85;
    this.enableRotate  = true;
    this.enableZoom    = true;
    this.enablePan     = false;      // Pan disabled — zoom only
    this.minDistance   = 1.05;
    this.maxDistance   = 5.6;
    this.minPolarAngle = 0.15;
    this.maxPolarAngle = Math.PI / 2 - 0.05;
    this.autoRotate    = false;
    this.autoRotateSpeed = 1.0;
    this.onChange = null;
    // Fired on drag/pinch start & end (after touch/mouse up) so the caller
    // can temporarily render at reduced resolution while the user is
    // actively moving the camera — makes rotate/zoom feel instant, then
    // the full-quality frame snaps back in once they let go.
    this.isInteracting = false;
    this.onInteractionStart = null;
    this.onInteractionEnd = null;

    const STATE = { NONE: -1, ROTATE: 0, DOLLY: 1 };
    let state = STATE.NONE;
    let scale = 1;

    const spherical      = new THREE.Spherical();
    const sphericalDelta = new THREE.Spherical();

    const rotateStart = new THREE.Vector2();
    const rotateEnd   = new THREE.Vector2();
    const rotateDelta = new THREE.Vector2();

    let touchStartDist = 0;

    const offset    = new THREE.Vector3();
    const quat      = new THREE.Quaternion().setFromUnitVectors(camera.up, new THREE.Vector3(0, 1, 0));
    const quatInv   = quat.clone().invert();
    const lastPos   = new THREE.Vector3();
    const EPS       = 1e-6;

    this.update = function () {
      offset.copy(camera.position).sub(scope.target);
      offset.applyQuaternion(quat);
      spherical.setFromVector3(offset);

      if (scope.autoRotate && state === STATE.NONE) {
        sphericalDelta.theta -= (2 * Math.PI) / 60 / 60 * scope.autoRotateSpeed;
      }

      if (scope.enableDamping) {
        spherical.theta += sphericalDelta.theta * scope.dampingFactor;
        spherical.phi   += sphericalDelta.phi   * scope.dampingFactor;
      } else {
        spherical.theta += sphericalDelta.theta;
        spherical.phi   += sphericalDelta.phi;
      }

      // Clamp vertical angle
      spherical.phi = Math.max(scope.minPolarAngle, Math.min(scope.maxPolarAngle, spherical.phi));

      // Apply zoom
      spherical.radius = Math.max(scope.minDistance,
                          Math.min(scope.maxDistance, spherical.radius * scale));

      offset.setFromSpherical(spherical);
      offset.applyQuaternion(quatInv);
      camera.position.copy(scope.target).add(offset);
      camera.lookAt(scope.target);

      if (scope.enableDamping) {
        sphericalDelta.theta *= 1 - scope.dampingFactor;
        sphericalDelta.phi   *= 1 - scope.dampingFactor;
        // Stop when values are negligible
        if (Math.abs(sphericalDelta.theta) < 0.00001) sphericalDelta.theta = 0;
        if (Math.abs(sphericalDelta.phi)   < 0.00001) sphericalDelta.phi = 0;
      } else {
        sphericalDelta.set(0, 0, 0);
      }
      scale = 1;

      if (lastPos.distanceToSquared(camera.position) > EPS) {
        lastPos.copy(camera.position);
        if (typeof scope.onChange === 'function') scope.onChange();
        return true;
      }
      return false;
    };

    // ── Mouse ────────────────────────────────────────────

    function onMouseDown(e) {
      if (!scope.enableRotate && e.button === 0) return;
      if (e.button === 0) {
        state = STATE.ROTATE;
        rotateStart.set(e.clientX, e.clientY);
        document.addEventListener('mousemove', onMouseMove);
        document.addEventListener('mouseup',   onMouseUp);
        scope.isInteracting = true;
        if (typeof scope.onInteractionStart === 'function') scope.onInteractionStart();
      }
    }

    function onMouseMove(e) {
      if (state !== STATE.ROTATE) return;
      rotateEnd.set(e.clientX, e.clientY);
      rotateDelta.subVectors(rotateEnd, rotateStart);

      sphericalDelta.theta -= (2 * Math.PI * rotateDelta.x * scope.rotateSpeed) / dom.clientHeight;
      sphericalDelta.phi   -= (2 * Math.PI * rotateDelta.y * scope.rotateSpeed) / dom.clientHeight;

      rotateStart.copy(rotateEnd);
      if (typeof scope.onChange === 'function') scope.onChange();
    }

    function onMouseUp() {
      state = STATE.NONE;
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup',   onMouseUp);
      scope.isInteracting = false;
      if (typeof scope.onInteractionEnd === 'function') scope.onInteractionEnd();
    }

    function onWheel(e) {
      if (!scope.enableZoom) return;
      const factor = Math.pow(0.95, scope.zoomSpeed);
      scale *= e.deltaY < 0 ? factor : 1 / factor;
      if (typeof scope.onChange === 'function') scope.onChange();
    }

    // ── Touch ────────────────────────────────────────────

    function onTouchStart(e) {
      if (e.touches.length === 1 && scope.enableRotate) {
        state = STATE.ROTATE;
        rotateStart.set(e.touches[0].pageX, e.touches[0].pageY);
      } else if (e.touches.length === 2 && scope.enableZoom) {
        state = STATE.DOLLY;
        const dx = e.touches[0].pageX - e.touches[1].pageX;
        const dy = e.touches[0].pageY - e.touches[1].pageY;
        touchStartDist = Math.hypot(dx, dy);
      }
      scope.isInteracting = true;
      if (typeof scope.onInteractionStart === 'function') scope.onInteractionStart();
    }

    function onTouchMove(e) {
      e.preventDefault();
      if (state === STATE.ROTATE && e.touches.length === 1) {
        rotateEnd.set(e.touches[0].pageX, e.touches[0].pageY);
        rotateDelta.subVectors(rotateEnd, rotateStart);

        sphericalDelta.theta -= (2 * Math.PI * rotateDelta.x * scope.rotateSpeed) / dom.clientHeight;
        sphericalDelta.phi   -= (2 * Math.PI * rotateDelta.y * scope.rotateSpeed) / dom.clientHeight;

        rotateStart.copy(rotateEnd);
        if (typeof scope.onChange === 'function') scope.onChange();

      } else if (state === STATE.DOLLY && e.touches.length === 2) {
        const dx = e.touches[0].pageX - e.touches[1].pageX;
        const dy = e.touches[0].pageY - e.touches[1].pageY;
        const d  = Math.hypot(dx, dy);
        const factor = Math.pow(0.95, scope.zoomSpeed);
        scale *= d > touchStartDist ? factor : 1 / factor;
        touchStartDist = d;
        if (typeof scope.onChange === 'function') scope.onChange();
      }
    }

    function onTouchEnd() {
      state = STATE.NONE;
      scope.isInteracting = false;
      if (typeof scope.onInteractionEnd === 'function') scope.onInteractionEnd();
    }
    function noop(e) { e.preventDefault(); }

    dom.addEventListener('mousedown',   onMouseDown);
    dom.addEventListener('wheel',       onWheel,      { passive: true });
    dom.addEventListener('contextmenu', noop);
    dom.addEventListener('touchstart',  onTouchStart, { passive: false });
    dom.addEventListener('touchmove',   onTouchMove,  { passive: false });
    dom.addEventListener('touchend',    onTouchEnd);

    this.dispose = function () {
      dom.removeEventListener('mousedown',   onMouseDown);
      dom.removeEventListener('wheel',       onWheel);
      dom.removeEventListener('contextmenu', noop);
      dom.removeEventListener('touchstart',  onTouchStart);
      dom.removeEventListener('touchmove',   onTouchMove);
      dom.removeEventListener('touchend',    onTouchEnd);
    };
  };
})();