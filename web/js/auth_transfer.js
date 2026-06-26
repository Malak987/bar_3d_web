/**
 * 🔐 Auth Transfer Token Exchange — Hardened for Phase 2
 *
 * Phase 2 improvements:
 * 1. Replay protection — tracks used tokens to prevent reuse
 * 2. JWT expiry validation — checks exp claim before using token
 * 3. Explicit URL cleanup — uses replaceState so token disappears from history
 * 4. Session persistence — stores session across page reloads
 * 5. Unauthorized fallback — blocks access when no valid auth
 *
 * Security properties:
 * - Transfer tokens are single-use (tracked by hash in localStorage)
 * - JWT expiry is validated on every check
 * - Token is removed from URL using replaceState (no history entry)
 * - Session state survives page reloads
 */

const AUTH_API_BASE = 'https://bar-backend.runasp.net';
const EXCHANGE_PATH = '/api/AuthTransfer/ExchangeTransferToken';

// ── Replay protection constants ─────────────────────────────────────────

const _USED_TOKENS_KEY = 'bar_used_transfer_tokens';
const _SESSION_KEY = 'bar_session_state';

/**
 * Check if a transfer token has already been exchanged.
 * Uses a hash of the token for storage (not the token itself).
 * @param {string} token
 * @returns {boolean} true if token was already used
 */
function _isTokenUsed(token) {
  try {
    const hash = _hashToken(token);
    const raw = localStorage.getItem(_USED_TOKENS_KEY);
    if (!raw) return false;
    const used = JSON.parse(raw);
    return Array.isArray(used) && used.includes(hash);
  } catch (_) {
    return false;
  }
}

/**
 * Mark a token as used after successful exchange.
 * Token is permanently blacklisted — cannot be replayed.
 * @param {string} token
 */
function _markTokenUsed(token) {
  try {
    const hash = _hashToken(token);
    const raw = localStorage.getItem(_USED_TOKENS_KEY);
    let used = raw ? JSON.parse(raw) : [];
    if (!Array.isArray(used)) used = [];
    if (!used.includes(hash)) {
      used.push(hash);
      localStorage.setItem(_USED_TOKENS_KEY, JSON.stringify(used));
      console.log('[AUTH_TRANSFER] Token marked as used:', hash.substring(0, 8) + '...');
    }
  } catch (e) {
    console.warn('[AUTH_TRANSFER] Failed to mark token used:', e);
  }
}

/**
 * Simple string hash for token deduplication.
 * Not cryptographic — just for dedup tracking.
 * @param {string} str
 * @returns {string}
 */
function _hashToken(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const chr = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + chr;
    hash = hash & hash;
  }
  return Math.abs(hash).toString();
}

/**
 * Check if a JWT is expired by parsing its exp claim.
 * @param {string} token
 * @returns {boolean} true if expired
 */
function _isJwtExpired(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return true;
    const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
    if (payload.exp) {
      return payload.exp * 1000 < Date.now();
    }
    // No exp claim — consider valid
    return false;
  } catch (_) {
    return true;
  }
}

/**
 * Store session state for page-reload persistence.
 * @param {object} session
 */
function _storeSession(session) {
  try {
    localStorage.setItem(_SESSION_KEY, JSON.stringify({
      jwt: session.jwt || null,
      createdAt: session.createdAt || new Date().toISOString(),
      expiresAt: session.expiresAt || new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
      authMethod: session.authMethod || 'transfer_exchange',
    }));
  } catch (e) {
    console.warn('[AUTH_TRANSFER] Failed to store session:', e);
  }
}

/**
 * Get stored session (validates expiry).
 * @returns {object|null}
 */
function _getStoredSession() {
  try {
    const raw = localStorage.getItem(_SESSION_KEY);
    if (!raw) return null;
    const session = JSON.parse(raw);
    if (session.expiresAt && new Date(session.expiresAt) < new Date()) {
      // Session expired — clear it
      localStorage.removeItem(_SESSION_KEY);
      return null;
    }
    return session;
  } catch (_) {
    localStorage.removeItem(_SESSION_KEY);
    return null;
  }
}

/**
 * Clear all auth state (logout).
 */
function clearSession() {
  localStorage.removeItem('token');
  localStorage.removeItem(_SESSION_KEY);
  localStorage.removeItem('bar_user_context');
  localStorage.removeItem('bar_transfer_token');
  // Note: used tokens list is intentionally kept for replay protection
  // across sessions on the same device.
  window.__IS_AUTHENTICATED__ = false;
  console.log('[AUTH_TRANSFER] Session cleared');
}

// ── Token Exchange ──────────────────────────────────────────────────────

/**
 * Exchange transfer token for authenticated session (JWT)
 *
 * Phase 2 flow:
 * 1. Check replay protection — reject if token already used
 * 2. Exchange with backend
 * 3. Mark token as used (replay protection)
 * 4. Store session
 * 5. Remove token from URL using replaceState
 *
 * @param {string} transferToken - The token from URL parameter
 * @returns {Promise<{success: boolean, token?: string, error?: string}>}
 */
export async function exchangeAuthToken(transferToken) {
  if (!transferToken || transferToken.trim() === '') {
    console.warn('[AUTH_TRANSFER] No token provided');
    return { success: false, error: 'No token provided' };
  }

  console.log('[AUTH_TRANSFER] Token received:', transferToken.substring(0, 8) + '...');

  // ── Replay protection check ──
  if (_isTokenUsed(transferToken)) {
    console.warn('[AUTH_TRANSFER] 🚫 REPLAY BLOCKED: Token was already exchanged');
    return {
      success: false,
      error: 'This authentication link has already been used and cannot be reused. '
           + 'Please open the designer from the app again for a new link.'
    };
  }

  try {
    const response = await fetch(`${AUTH_API_BASE}${EXCHANGE_PATH}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({
        transferToken: transferToken
      }),
    });

    console.log('[AUTH_TRANSFER] Exchange response status:', response.status);

    if (!response.ok) {
      const errorText = await response.text().catch(() => '');
      console.error('[AUTH_TRANSFER] ❌ HTTP', response.status, ':', errorText);
      return { success: false, error: 'HTTP ' + response.status };
    }

    const data = await response.json();

    if (data.isSucceeded === true) {
      const responseData = data.data || data;
      const jwtToken = responseData.accessToken || responseData.token ||
                       responseData.jwt || responseData.authToken;

      if (jwtToken) {
        console.log('[AUTH_TRANSFER] Exchange success — JWT received');

        // ── Mark token as used BEFORE storing (replay protection) ──
        _markTokenUsed(transferToken);

        // ── Store session ──
        const session = {
          jwt: jwtToken,
          createdAt: new Date().toISOString(),
          expiresAt: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
          authMethod: 'transfer_exchange',
        };
        _storeSession(session);

        // ── Store JWT ──
        localStorage.setItem('token', jwtToken);
        window.__IS_AUTHENTICATED__ = true;

        // ── Remove token from URL using replaceState ──
        // ⚠️ replaceState does NOT add to browser history.
        // The back button will NOT revisit the URL with the token.
        _removeTokenFromUrl();

        console.log('[AUTH_TRANSFER] ✅ All auth steps complete — session stored, URL cleaned');
        return { success: true, token: jwtToken };
      }

      // Backend may use cookie-based auth
      if (data.isSucceeded === true) {
        console.log('[AUTH_TRANSFER] Exchange success (session-based)');

        _markTokenUsed(transferToken);
        _storeSession({
          jwt: null,
          createdAt: new Date().toISOString(),
          expiresAt: new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(),
          authMethod: 'transfer_exchange',
        });
        window.__IS_AUTHENTICATED__ = true;
        _removeTokenFromUrl();

        return { success: true };
      }
    }

    const errorMsg = data.message || 'Token exchange failed';
    console.error('[AUTH_TRANSFER] ❌ Exchange failed:', errorMsg);
    return { success: false, error: errorMsg };
  } catch (error) {
    console.error('[AUTH_TRANSFER] ❌ Network error:', error);
    return { success: false, error: error.message || 'Network error' };
  }
}

/**
 * Remove transfer token from URL using replaceState.
 * This ensures the token disappears from browser history.
 */
function _removeTokenFromUrl() {
  try {
    const url = new URL(window.location.href);
    const tokenKeys = ['token', 'transferToken', 'authTransferToken', 'auth_transfer_token', 'transfer_token', 't'];
    let changed = false;

    tokenKeys.forEach(key => {
      if (url.searchParams.has(key)) {
        url.searchParams.delete(key);
        changed = true;
      }
    });

    // Also check hash fragment
    if (url.hash) {
      const hashUrl = new URL(url.hash.substring(1), window.location.origin);
      tokenKeys.forEach(key => {
        if (hashUrl.searchParams.has(key)) {
          hashUrl.searchParams.delete(key);
          changed = true;
        }
      });
      if (changed) {
        url.hash = hashUrl.toString().replace(window.location.origin, '');
      }
    }

    if (changed) {
      // ⚠️ replaceState — does NOT add to browser history
      // The back button will NOT go back to the URL with the token.
      window.history.replaceState(null, document.title, url.toString());
      console.log('[AUTH_TRANSFER] ✅ Token removed from URL (no history entry)');
    }
  } catch (e) {
    console.warn('[AUTH_TRANSFER] Failed to remove token from URL:', e);
  }
}

// ── Authentication State ────────────────────────────────────────────────

/**
 * Check if user is authenticated.
 * Priority: stored session > JWT in localStorage
 * @returns {boolean}
 */
export function checkAuthentication() {
  // Check stored session first (validates expiry)
  const session = _getStoredSession();
  if (session && (session.jwt || !_isTokenUsed(''))) {
    // Session exists and not expired
    // For cookie-based auth, just check session exists
    if (!session.jwt) return true;

    // For token-based auth, validate JWT expiry
    if (!_isJwtExpired(session.jwt)) {
      return true;
    }
  }

  // Fallback: check JWT in localStorage
  const token = localStorage.getItem('token');
  if (token && !_isJwtExpired(token)) {
    return true;
  }

  // Clear stale data
  localStorage.removeItem('token');
  localStorage.removeItem(_SESSION_KEY);
  return false;
}

/**
 * Get auth token from URL parameters
 * @returns {string|null}
 */
export function getTokenFromUrl() {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get('token') ||
         urlParams.get('transferToken') ||
         urlParams.get('authTransferToken') ||
         null;
}

// ── Public API ───────────────────────────────────────────────────────────

window.AuthTransfer = {
  exchange: exchangeAuthToken,
  check: checkAuthentication,
  getToken: getTokenFromUrl,
  clear: clearSession,
  // Expose for debugging
  _isTokenUsed: _isTokenUsed,
  _getStoredSession: _getStoredSession,
};