/**
 * 🔐 Auth Transfer Token Exchange
 *
 * Handles the secure auth transfer from Flutter app to WebView.
 *
 * Flow:
 * 1. Flutter generates a transfer token via GenerateTransferToken API
 * 2. WebView is opened with ?token=XYZ
 * 3. This script exchanges the token for a JWT session
 * 4. JWT is stored in localStorage for subsequent API calls
 *
 * ✅ NO cookies or credentials needed — pure token-based auth
 */

const AUTH_API_BASE = 'https://bar-backend.runasp.net';
const EXCHANGE_PATH = '/api/AuthTransfer/ExchangeTransferToken';

/**
 * Exchange transfer token for authenticated session (JWT)
 * @param {string} transferToken - The token from URL parameter
 * @returns {Promise<{success: boolean, token?: string, error?: string}>}
 */
export async function exchangeAuthToken(transferToken) {
  if (!transferToken || transferToken.trim() === '') {
    console.warn('[AUTH_TRANSFER] No token provided');
    return { success: false, error: 'No token provided' };
  }

  console.log('[AUTH_TRANSFER] Token received:', transferToken.substring(0, 8) + '...');
  console.log('[AUTH_TRANSFER] Exchange request started');

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
      // ✅ NO credentials: 'include' — the backend returns JWT in response body,
      //    not as a cookie. Including credentials triggers a CORS preflight that
      //    fails because the backend uses Access-Control-Allow-Origin: *
      //    which is incompatible with credentials mode.
    });

    console.log('[AUTH_TRANSFER] Exchange response status:', response.status);

    if (!response.ok) {
      const errorText = await response.text().catch(() => '');
      console.error('[AUTH_TRANSFER] ❌ HTTP', response.status, ':', errorText);
      return { success: false, error: 'HTTP ' + response.status };
    }

    const data = await response.json();
    console.log('[AUTH_TRANSFER] Exchange response body:', JSON.stringify(data).substring(0, 200));

    if (data.isSucceeded === true) {
      // Extract JWT from any common response shape
      const responseData = data.data || data;
      const jwtToken = responseData.accessToken || responseData.token || responseData.jwt || responseData.authToken;

      if (jwtToken) {
        console.log('[AUTH_TRANSFER] Exchange success — JWT received');
        localStorage.setItem('token', jwtToken);
        window.__IS_AUTHENTICATED__ = true;
        console.log('[AUTH_TRANSFER] User authenticated ✓');
        return { success: true, token: jwtToken };
      } else if (data.isSucceeded === true) {
        // Backend may set auth via session cookie (if CORS is properly configured)
        console.log('[AUTH_TRANSFER] Exchange success (session-based)');
        window.__IS_AUTHENTICATED__ = true;
        console.log('[AUTH_TRANSFER] User authenticated ✓');
        return { success: true };
      } else {
        console.error('[AUTH_TRANSFER] ❌ Exchange succeeded but no token:', data.message);
        return { success: false, error: data.message || 'No token in response' };
      }
    } else {
      const errorMsg = data.message || 'Token exchange failed';
      console.error('[AUTH_TRANSFER] ❌ Exchange failed:', errorMsg);
      return { success: false, error: errorMsg };
    }
  } catch (error) {
    console.error('[AUTH_TRANSFER] ❌ Network error:', error);
    return { success: false, error: error.message || 'Network error' };
  }
}

/**
 * Check if user is authenticated (has JWT in localStorage)
 * @returns {boolean}
 */
export function checkAuthentication() {
  const token = localStorage.getItem('token');
  if (!token) return false;

  // Basic JWT expiry check
  try {
    const parts = token.split('.');
    if (parts.length === 3) {
      const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));
      if (payload.exp && payload.exp * 1000 < Date.now()) {
        console.warn('[AUTH_TRANSFER] Token expired');
        localStorage.removeItem('token');
        return false;
      }
    }
  } catch (e) { /* ignore parse errors */ }

  return true;
}

/**
 * Get auth token from URL parameters
 * @returns {string|null}
 */
export function getTokenFromUrl() {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get('token');
}

/**
 * Clear authentication session
 */
export function clearSession() {
  window.__IS_AUTHENTICATED__ = false;
  localStorage.removeItem('token');
  console.log('[AUTH_TRANSFER] Session cleared');
}

// Make available globally for debugging
window.AuthTransfer = {
  exchange: exchangeAuthToken,
  check: checkAuthentication,
  getToken: getTokenFromUrl,
  clear: clearSession,
};