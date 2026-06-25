/**
 * ─────────────────────────────────────────────────────────────
 * orbit_controls.js — Minimal OrbitControls (mouse + touch)
 *
 * Stripped-down inline port — sufficient for our needs and
 * avoids loading the full three-examples bundle.
 * ─────────────────────────────────────────────────────────────
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
    this.dampingFactor = 0.05;
    this.minDistance   = 1.5;
    this.maxDistance   = 7.0;
    this.maxPolarAngle = Math.PI / 2 - 0.05;
    this.autoRotate    = false;
    this.autoRotateSpeed = 2.0;
    this.onChange = null;

    const STATE = { NONE: -1, ROTATE: 0, DOLLY: 1, PAN: 2 };
    let state = STATE.NONE;
    let scale = 1;

    const spherical      = new THREE.Spherical();
    const sphericalDelta = new THREE.Spherical();
    const panOffset      = new THREE.Vector3();

    const rotateStart = new THREE.Vector2();
    const rotateEnd   = new THREE.Vector2();
    const rotateDelta = new THREE.Vector2();
    const panStart    = new THREE.Vector2();
    const panEnd      = new THREE.Vector2();
    const panDelta    = new THREE.Vector2();

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
      spherical.phi    = Math.max(EPS, Math.min(Math.PI - EPS, spherical.phi));
      spherical.radius = Math.max(scope.minDistance,
                          Math.min(scope.maxDistance, spherical.radius * scale));

      scope.target.add(panOffset);
      offset.setFromSpherical(spherical);
      offset.applyQuaternion(quatInv);
      camera.position.copy(scope.target).add(offset);
      camera.lookAt(scope.target);

      if (scope.enableDamping) {
        sphericalDelta.theta *= 1 - scope.dampingFactor;
        sphericalDelta.phi   *= 1 - scope.dampingFactor;
        panOffset.multiplyScalar(1 - scope.dampingFactor);
      } else {
        sphericalDelta.set(0, 0, 0);
        panOffset.set(0, 0, 0);
      }
      scale = 1;

      if (lastPos.distanceToSquared(camera.position) > EPS) {
        lastPos.copy(camera.position);
        if (typeof scope.onChange === 'function') scope.onChange();
        return true;
      }
      return false;
    };

    function onMouseDown(e) {
      if (e.button === 0) { state = STATE.ROTATE; rotateStart.set(e.clientX, e.clientY); }
      else if (e.button === 2) { state = STATE.PAN; panStart.set(e.clientX, e.clientY); }
      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup',   onMouseUp);
    }
    function onMouseMove(e) {
      if (state === STATE.ROTATE) {
        rotateEnd.set(e.clientX, e.clientY);
        rotateDelta.subVectors(rotateEnd, rotateStart);
        sphericalDelta.theta -= (2 * Math.PI * rotateDelta.x) / dom.clientHeight;
        sphericalDelta.phi   -= (2 * Math.PI * rotateDelta.y) / dom.clientHeight;
        rotateStart.copy(rotateEnd);
        if (typeof scope.onChange === 'function') scope.onChange();
      } else if (state === STATE.PAN) {
        panEnd.set(e.clientX, e.clientY);
        panDelta.subVectors(panEnd, panStart);
        const off = new THREE.Vector3();
        off.copy(camera.position).sub(scope.target);
        const dist = off.length() * Math.tan((camera.fov / 2) * Math.PI / 180);
        const left = new THREE.Vector3().setFromMatrixColumn(camera.matrix, 0)
                      .multiplyScalar(-2 * panDelta.x * dist / dom.clientHeight);
        const up   = new THREE.Vector3().setFromMatrixColumn(camera.matrix, 1)
                      .multiplyScalar(2 * panDelta.y * dist / dom.clientHeight);
        panOffset.add(left).add(up);
        panStart.copy(panEnd);
        if (typeof scope.onChange === 'function') scope.onChange();
      }
    }
    function onMouseUp() {
      state = STATE.NONE;
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup',   onMouseUp);
    }
    function onWheel(e) {
      scale *= e.deltaY < 0 ? 0.92 : 1 / 0.92;
      if (typeof scope.onChange === 'function') scope.onChange();
    }
    function onTouchStart(e) {
      if (e.touches.length === 1) {
        state = STATE.ROTATE;
        rotateStart.set(e.touches[0].pageX, e.touches[0].pageY);
      } else if (e.touches.length === 2) {
        state = STATE.DOLLY;
        const dx = e.touches[0].pageX - e.touches[1].pageX;
        const dy = e.touches[0].pageY - e.touches[1].pageY;
        touchStartDist = Math.hypot(dx, dy);
      }
    }
    function onTouchMove(e) {
      e.preventDefault();
      if (state === STATE.ROTATE && e.touches.length === 1) {
        rotateEnd.set(e.touches[0].pageX, e.touches[0].pageY);
        rotateDelta.subVectors(rotateEnd, rotateStart);
        sphericalDelta.theta -= (2 * Math.PI * rotateDelta.x) / dom.clientHeight;
        sphericalDelta.phi   -= (2 * Math.PI * rotateDelta.y) / dom.clientHeight;
        rotateStart.copy(rotateEnd);
        if (typeof scope.onChange === 'function') scope.onChange();
      } else if (state === STATE.DOLLY && e.touches.length === 2) {
        const dx = e.touches[0].pageX - e.touches[1].pageX;
        const dy = e.touches[0].pageY - e.touches[1].pageY;
         const d  = Math.hypot(dx, dy);
                scale *= d > touchStartDist ? 0.92 : 1 / 0.92;  // pinch out = zoom in
                touchStartDist = d;
                if (typeof scope.onChange === 'function') scope.onChange();
      }
    }
    function onTouchEnd() { state = STATE.NONE; }
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
