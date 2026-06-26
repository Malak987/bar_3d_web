import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:http/http.dart' as http;

import 'session_validator.dart';
import 'web_helpers.dart';

/// 🔐 Auth Guard — Single source of truth for authentication state
///
/// This guard implements the complete authentication flow:
/// 1. Check for existing valid session (bypass transfer flow)
/// 2. Exchange transfer token if available in URL
/// 3. Reject used/expired tokens with replay protection
/// 4. Block 3D scene initialization until auth succeeds
///
/// Never blocks for non-authenticated users who just want to browse.
/// Only blocks commerce operations (Add To Cart).
///
/// Usage:
///   final state = await AuthGuard.ensureAuthenticated();
///   if (state.status == AuthStatus.authorized) { ... }
class AuthGuard {
  static const String _baseUrl = 'https://bar-backend.runasp.net';
  static const String _exchangePath = '/api/AuthTransfer/ExchangeTransferToken';

  static const Duration _tokenExpiryWindow = Duration(seconds: 60);

  // ── Auth Status ───────────────────────────────────────

  static AuthStatus currentStatus = AuthStatus.unknown;
  static AuthSession? _currentSession;

  /// Returns the current authenticated session or null
  static AuthSession? get session => _currentSession;

  /// Check if we have a valid authenticated session
  static bool get isAuthenticated =>
      _currentSession != null &&
          !_currentSession!.isExpired &&
          SessionValidator.hasValidJwt();

  // ── Primary Entry Point ───────────────────────────────

  /// Ensures authentication is established.
  /// Returns immediately with AuthStatus.authorized if session already valid.
  /// Exchanges transfer token if URL contains one.
  /// Returns AuthStatus.unauthorized if no valid auth can be established.
  ///
  /// ⚠️ This method is idempotent — multiple calls don't trigger multiple exchanges.
  /// ⚠️ Must be called before the 3D scene initializes.
  static Future<AuthResult> ensureAuthenticated() async {
    print('[AuthGuard] ════════════════════════════════════════════════');
    print('[AuthGuard] 🔐 Starting authentication flow');
    print('[AuthGuard] ════════════════════════════════════════════════');

    // ── Step 1: Check for existing valid session ─────────
    print('[AuthGuard] Step 1: Checking for existing session...');
    final existingSession = SessionValidator.getCurrentSession();
    if (existingSession != null && !existingSession.isExpired) {
      print('[AuthGuard] ✅ Existing valid session found — bypassing transfer flow');
      _currentSession = existingSession;
      currentStatus = AuthStatus.authorized;
      return AuthResult(
        status: AuthStatus.authorized,
        session: existingSession,
        message: 'Existing authenticated session',
      );
    }
    print('[AuthGuard] ❌ No existing session found');

    // Also check JWT directly (session might not be stored yet)
    print('[AuthGuard] Step 2: Checking for valid JWT in localStorage...');
    if (SessionValidator.hasValidJwt()) {
      final jwt = SessionValidator.getJwt();
      if (jwt != null) {
        print('[AuthGuard] ✅ Valid JWT found — session restored (preview: ${jwt.substring(0, 20)}...)');
        _currentSession = AuthSession.fromExistingJwt(jwt: jwt);
        currentStatus = AuthStatus.authorized;
        return AuthResult(
          status: AuthStatus.authorized,
          session: _currentSession,
          message: 'Authenticated via existing JWT',
        );
      }
    }
    print('[AuthGuard] ❌ No valid JWT in localStorage');

    // ── Step 3: Try to read transfer token from URL ─────
    print('[AuthGuard] Step 3: Reading transfer token from URL...');
    final token = _readTransferTokenFromUrl();
    if (token != null && token.isNotEmpty) {
      print('[AuthGuard] ✅ Token found in URL (preview: ${token.substring(0, 8)}...)');
      return await _exchangeTransferToken(token);
    }

    // ── Step 4: No auth available ────────────────────────
    print('[AuthGuard] ❌ No transfer token in URL and no existing session');
    print('[AuthGuard] 💡 Tip: If you expected a token, check the URL contains ?token= parameter');
    currentStatus = AuthStatus.unauthorized;
    _currentSession = null;
    return AuthResult(
      status: AuthStatus.unauthorized,
      message: 'No transfer token in URL and no existing session. '
          'Designer requires authentication via transfer token.',
    );
  }

  // ── Token Exchange ─────────────────────────────────────

  static Future<AuthResult> _exchangeTransferToken(String token) async {
    print('[AuthGuard] Transfer token detected: ${token.substring(0, 8)}...');

    // ── Replay protection: Check if token already used ──
    if (SessionValidator.isTokenUsed(token)) {
      print('[AuthGuard] 🚫 REPLAY BLOCKED: Token was already exchanged');
      currentStatus = AuthStatus.unauthorized;
      return AuthResult(
        status: AuthStatus.unauthorized,
        message: 'This authentication link has already been used and cannot be reused.',
      );
    }

    // ── Exchange with backend ──
    try {
      print('[AuthGuard] Exchanging transfer token...');

      final response = await http.post(
        Uri.parse('$_baseUrl$_exchangePath'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'transferToken': token}),
      );

      print('[AuthGuard] Exchange response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        String? jwtToken;

        if (body['isSucceeded'] == true) {
          // ── Extract JWT ──
          final data = body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body;
          jwtToken = _firstString([
            data['accessToken'],
            data['token'],
            data['jwt'],
            data['authToken'],
          ]);

          if (jwtToken != null && jwtToken.isNotEmpty) {
            // ── Mark token as used BEFORE storing session (replay protection) ──
            SessionValidator.markTokenUsed(token);
            print('[AuthGuard] ✅ Token marked as used (replay protection active)');

            // ── Store session ──
            _currentSession = AuthSession.fromTransferExchange(
              jwt: jwtToken,
              userId: _extractUserId(jwtToken),
            );
            SessionValidator.storeSession(_currentSession!);
            _storeJwt(jwtToken);

            // ── Remove token from URL ──
            _cleanupUrl();

            currentStatus = AuthStatus.authorized;
            print('[AuthGuard] ✅ Auth exchange complete — session stored');

            return AuthResult(
              status: AuthStatus.authorized,
              session: _currentSession,
              message: 'Authentication successful',
            );
          }

          // Exchange succeeded but no JWT — backend may use cookie-based auth
          print('[AuthGuard] Exchange succeeded but no JWT — using cookie auth');

          // Backend may have set a session cookie instead of returning a JWT
          // Store session with null JWT — validate via session check later
          SessionValidator.markTokenUsed(token);
          _currentSession = AuthSession(
            jwt: null,
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 2)),
            authMethod: 'transfer_exchange',
          );
          SessionValidator.storeSession(_currentSession!);
          _cleanupUrl();
          currentStatus = AuthStatus.authorized;
          return AuthResult(
            status: AuthStatus.authorized,
            session: _currentSession,
            message: 'Authenticated via session cookie',
          );
        }

        // Exchange failed
        final errorMsg = body['message']?.toString() ?? 'Authentication failed';
        print('[AuthGuard] ❌ Exchange failed: $errorMsg');

        return AuthResult(
          status: AuthStatus.unauthorized,
          message: errorMsg,
        );
      }

      // HTTP error
      print('[AuthGuard] ❌ HTTP ${response.statusCode}: ${response.body}');
      return AuthResult(
        status: AuthStatus.unauthorized,
        message: 'Authentication failed (HTTP ${response.statusCode})',
      );

    } catch (e) {
      print('[AuthGuard] ❌ Network error during exchange: $e');
      return AuthResult(
        status: AuthStatus.error,
        message: 'Network error during authentication: $e',
      );
    }
  }

  // ── Session Validation on Reload ───────────────────────

  /// Validates the current session state after page reload.
  /// Returns updated auth result.
  static Future<AuthResult> validateOnReload() async {
    final session = SessionValidator.getCurrentSession();

    if (session == null) {
      print('[AuthGuard] No stored session — need to re-authenticate');
      return await ensureAuthenticated();
    }

    if (session.isExpired) {
      print('[AuthGuard] Session expired — clearing and requiring re-auth');
      SessionValidator.clearSession();
      _currentSession = null;
      currentStatus = AuthStatus.unauthorized;
      return AuthResult(
        status: AuthStatus.unauthorized,
        message: 'Your session has expired. Please re-authenticate.',
      );
    }

    // Session valid — restore
    _currentSession = session;
    currentStatus = AuthStatus.authorized;
    print('[AuthGuard] Session valid on reload — restored');
    return AuthResult(
      status: AuthStatus.authorized,
      session: session,
      message: 'Session restored',
    );
  }

  // ── Logout ─────────────────────────────────────────────

  /// Performs full logout — clears all auth state
  static void logout() {
    print('[AuthGuard] Performing full logout');
    SessionValidator.fullLogout();
    _currentSession = null;
    currentStatus = AuthStatus.unauthorized;
    WebHelpers.removeQueryParams(const [
      'transferToken',
      'token',
      'authTransferToken',
      'auth_transfer_token',
      'transfer_token',
      't',
    ]);
  }

  // ── Helpers ─────────────────────────────────────────────

  static String? _readTransferTokenFromUrl() {
    return WebHelpers.readFirstQueryParam(const [
      'transferToken',
      'token',
      'authTransferToken',
      'auth_transfer_token',
      'transfer_token',
      't',
    ]) ?? WebHelpers.readStoredTransferToken();
  }

  static void _cleanupUrl() {
    // Remove ALL possible token parameter names from URL
    // Use replaceState to avoid adding to browser history
    WebHelpers.removeQueryParams(const [
      'transferToken',
      'token',
      'authTransferToken',
      'auth_transfer_token',
      'transfer_token',
      't',
    ]);
    print('[AuthGuard] ✅ Transfer token removed from URL');
  }

  static void _storeJwt(String jwt) {
    try {
      // Store in localStorage for subsequent API calls
      _setLocalStorage('token', jwt);

      // Also update bar_user_context if it exists
      final raw = _getLocalStorage('bar_user_context');
      if (raw != null && raw.isNotEmpty) {
        final ctx = jsonDecode(raw) as Map<String, dynamic>;
        ctx['token'] = jwt;
        _setLocalStorage('bar_user_context', jsonEncode(ctx));
      }

      print('[AuthGuard] JWT stored in localStorage');
    } catch (e) {
      print('[AuthGuard] Failed to store JWT: $e');
    }
  }

  static String? _firstString(List<dynamic> values) {
    for (final v in values) {
      final s = (v?.toString().trim() ?? '');
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static String? _extractUserId(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) normalized += '=';
      final decoded = jsonDecode(utf8.decode(base64Decode(normalized)))
      as Map<String, dynamic>;
      return decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
          ?.toString() ??
          decoded['nameid']?.toString() ??
          decoded['sub']?.toString();
    } catch (_) {
      return null;
    }
  }
}

// ── Auth Status Enum ───────────────────────────────────────────────────

enum AuthStatus {
  unknown,
  authorized,
  unauthorized,
  error,
}

// ── Auth Result ────────────────────────────────────────────────────────

class AuthResult {
  final AuthStatus status;
  final AuthSession? session;
  final String? message;

  const AuthResult({
    required this.status,
    this.session,
    this.message,
  });

  bool get isAuthorized => status == AuthStatus.authorized;
  bool get isUnauthorized => status == AuthStatus.unauthorized;
  bool get isError => status == AuthStatus.error;

  @override
  String toString() =>
      'AuthResult(status: $status, message: $message, session: $session)';
}

// ── localStorage using dart:html ──────────────────────────────────────

void _setLocalStorage(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

String? _getLocalStorage(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}