/* ════════════════════════════════════════════════════════════════════════
 *  bar_auth_bridge.js
 *  ──────────────────────────────────────────────────────────────────────
 *  Plain-JS auth bridge between the Bar3DCake web app and the Flutter
 *  mobile app that hosts it inside a WebView.
 *
 *  Loaded from index.html BEFORE the Flutter Web bundle so its helpers
 *  are available the instant any page script runs.
 *
 *  🔐 Architecture (Single Source of Truth = Flutter):
 *    1. Flutter injects the JWT into `localStorage['token']` at
 *       `documentStart` (via flutter_inappwebview UserScript).
 *    2. Every `fetch()` call inside this app should go through
 *       `BarAuth.fetch(url, init)` which:
 *         • attaches `Authorization: Bearer <jwt>` automatically
 *         • on 401, asks Flutter for a fresh token and retries once
 *         • if still 401, notifies Flutter to force-logout
 *    3. Web code can ALSO listen for `bar:token` and `bar:logout`
 *       DOM events for reactive UI updates.
 *
 *  🚫 Never:
 *    • Hardcode the token anywhere.
 *    • Store the token in cookies (irrelevant in WebView).
 *    • Put the token in URL query params.
 * ════════════════════════════════════════════════════════════════════════ */
(function (global) {
  'use strict';

  // ── Constants ────────────────────────────────────────────────────────
  var TOKEN_KEY = 'token';
  var CONTEXT_KEY = 'bar_user_context';
  var BRIDGE_NAME = 'BarAuthBridge';
  var GENERIC_BRIDGE = 'FlutterBridge';

  // ── Internal logging (toggle via BarAuth.setDebug(true)) ────────────
  var DEBUG = true;
  function log() {
    if (!DEBUG) return;
    var args = ['%c[BAR-AUTH]', 'color:#0D9E8A;font-weight:bold;'];
    for (var i = 0; i < arguments.length; i++) args.push(arguments[i]);
    console.log.apply(console, args);
  }
  function warn() {
    var args = ['%c[BAR-AUTH]', 'color:#e58a00;font-weight:bold;'];
    for (var i = 0; i < arguments.length; i++) args.push(arguments[i]);
    console.warn.apply(console, args);
  }

  function redact(token) {
    if (!token) return '<empty>';
    if (token.length <= 16) return '****';
    return token.substring(0, 8) + '…' + token.substring(token.length - 8);
  }

  // ── Bridge availability ─────────────────────────────────────────────
  function hasFlutterBridge() {
    try {
      return !!(window.flutter_inappwebview &&
        typeof window.flutter_inappwebview.callHandler === 'function');
    } catch (e) { return false; }
  }

  function callFlutter(handler, payload) {
    if (!hasFlutterBridge()) {
      warn('callFlutter("' + handler + '") → no bridge (plain browser?)');
      return Promise.resolve(null);
    }
    try {
      return window.flutter_inappwebview.callHandler(handler, payload);
    } catch (e) {
      warn('callFlutter("' + handler + '") threw:', e);
      return Promise.resolve(null);
    }
  }

  // ── Token storage helpers ───────────────────────────────────────────
  function readToken() {
    try {
      var t = window.localStorage.getItem(TOKEN_KEY);
      if (t) return t;
      var raw = window.localStorage.getItem(CONTEXT_KEY);
      if (raw) {
        var ctx = JSON.parse(raw);
        return ctx && ctx.token ? ctx.token : null;
      }
    } catch (e) { /* localStorage might be locked in privacy mode */ }
    return null;
  }

  function writeToken(token) {
    try {
      if (token) window.localStorage.setItem(TOKEN_KEY, token);
      else window.localStorage.removeItem(TOKEN_KEY);
    } catch (e) {}
    // Dispatch a DOM event so listeners (Flutter Web, vanilla JS, …) can
    // react without polling localStorage.
    try {
      window.dispatchEvent(new CustomEvent('bar:token', { detail: token || '' }));
    } catch (e) {}
  }

  // ── JWT helpers ─────────────────────────────────────────────────────
  function decodeJwtPayload(token) {
    if (!token) return null;
    try {
      var parts = token.split('.');
      if (parts.length !== 3) return null;
      var b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      // pad to 4
      while (b64.length % 4) b64 += '=';
      var json = atob(b64);
      return JSON.parse(decodeURIComponent(escape(json)));
    } catch (e) { return null; }
  }

  function jwtSummary(token) {
    var payload = decodeJwtPayload(token);
    var out = { present: !!token, redacted: redact(token), decoded: !!payload };
    if (!payload) return out;
    if (typeof payload.exp === 'number') {
      var expiry = new Date(payload.exp * 1000);
      out.exp = expiry.toISOString();
      out.expired = expiry.getTime() <= Date.now();
      out.remainingSec = Math.round((expiry.getTime() - Date.now()) / 1000);
    } else {
      out.exp = '<missing>';
    }
    if (payload.sub) out.sub = redact(payload.sub);
    return out;
  }

  // ── Public bridge API ───────────────────────────────────────────────

  /**
   * Asks Flutter for the latest token. Updates localStorage and returns
   * the new value (or null if Flutter has none either).
   */
  function requestTokenFromFlutter() {
    return callFlutter(BRIDGE_NAME, 'getToken').then(function (res) {
      var token = null;
      if (res && typeof res === 'object' && res.token) token = res.token;
      else if (typeof res === 'string') token = res;
      if (token) {
        log('✓ refreshed token from Flutter:', jwtSummary(token));
        writeToken(token);
        return token;
      }
      warn('Flutter returned no token (user probably not logged in)');
      return null;
    }).catch(function (err) {
      warn('requestTokenFromFlutter failed:', err);
      return null;
    });
  }

  /**
   * Tells Flutter the session is dead (401 from server). Flutter will:
   *   1) Clear secure-storage token
   *   2) Pop the WebView screen
   *   3) Route user to LoginScreen
   */
  function notifyTokenExpired(reason) {
    log('🔒 notifying Flutter TOKEN_EXPIRED (' + (reason || 'unknown') + ')');
    return callFlutter(GENERIC_BRIDGE, {
      type: 'TOKEN_EXPIRED',
      payload: { reason: reason || 'unknown', at: new Date().toISOString() }
    });
  }

  /**
   * Drop-in `fetch` replacement that:
   *   • attaches Authorization header,
   *   • retries once with a fresh token on 401,
   *   • notifies Flutter to logout if the second attempt is also 401.
   *
   * Usage:
   *   BarAuth.fetch('/api/Carts/GetCart').then(r => r.json())
   */
  function authedFetch(input, init) {
    init = init || {};
    init.headers = init.headers || {};

    function attach(token) {
      var headers = new Headers(init.headers);
      headers.set('Content-Type', headers.get('Content-Type') || 'application/json');
      if (token) headers.set('Authorization', 'Bearer ' + token);
      return Object.assign({}, init, { headers: headers });
    }

    var token = readToken();

    function doFetch(t) {
      log('→ fetch', { url: typeof input === 'string' ? input : input.url, hasAuth: !!t });
      return fetch(input, attach(t));
    }

    var firstAttempt;
    if (!token) {
      // Cold start: pull from Flutter before sending the request at all.
      firstAttempt = requestTokenFromFlutter().then(function (t) {
        if (!t) {
          notifyTokenExpired('no_token_on_web');
          // Return a synthetic 401 so callers see a consistent shape.
          return new Response(null, { status: 401, statusText: 'No token' });
        }
        return doFetch(t);
      });
    } else {
      firstAttempt = doFetch(token);
    }

    return firstAttempt.then(function (res) {
      if (res.status !== 401) return res;

      log('← 401 received, requesting fresh token from Flutter…');
      return requestTokenFromFlutter().then(function (fresh) {
        if (!fresh) {
          notifyTokenExpired('no_token_after_refresh');
          return res;
        }
        return doFetch(fresh).then(function (retryRes) {
          if (retryRes.status === 401) {
            warn('← 401 again after refresh → token truly dead');
            notifyTokenExpired('still_401_after_refresh');
          }
          return retryRes;
        });
      });
    });
  }

  /**
   * Convenience JSON helper:
   *   BarAuth.json('/api/Carts/GetCart').then(data => ...)
   */
  function authedJson(input, init) {
    return authedFetch(input, init).then(function (r) {
      return r.ok ? r.json() : Promise.reject({ status: r.status });
    });
  }

  /**
   * Diagnostic — prints both web-side and Flutter-side token snapshots so
   * you can verify they agree.
   *
   * Usage in devtools:  await BarAuth.debugSnapshot();
   */
  function debugSnapshot() {
    var web = jwtSummary(readToken());
    log('═══ WEB-SIDE TOKEN SNAPSHOT ═══');
    log('hasFlutterBridge :', hasFlutterBridge());
    log('jwt              :', web);
    return callFlutter(BRIDGE_NAME, 'debugSnapshot').then(function (flutter) {
      log('Flutter snapshot :', flutter);
      log('═════════════════════════════════');
      return { web: web, flutter: flutter };
    });
  }

  // ── React to Flutter-pushed events ──────────────────────────────────
  window.addEventListener('barTokenUpdated', function (e) {
    var token = e.detail || '';
    log('← barTokenUpdated (Flutter pushed new token)');
    writeToken(token);
  });

  window.addEventListener('barForceLogout', function () {
    log('← barForceLogout (Flutter requested force logout)');
    writeToken(null);
    try { window.localStorage.removeItem(CONTEXT_KEY); } catch (e) {}
    try { window.dispatchEvent(new CustomEvent('bar:logout')); } catch (e) {}
  });

  // ── Expose ──────────────────────────────────────────────────────────
  global.BarAuth = {
    fetch: authedFetch,
    json: authedJson,
    readToken: readToken,
    requestTokenFromFlutter: requestTokenFromFlutter,
    notifyTokenExpired: notifyTokenExpired,
    debugSnapshot: debugSnapshot,
    jwtSummary: jwtSummary,
    isReady: function () { return !!readToken(); },
    setDebug: function (v) { DEBUG = !!v; }
  };

  // ── Boot diagnostic ─────────────────────────────────────────────────
  if (hasFlutterBridge()) {
    log('bridge available → token summary on boot:', jwtSummary(readToken()));
  } else {
    warn('no Flutter bridge — running in plain browser (debug only)');
  }
})(window);
