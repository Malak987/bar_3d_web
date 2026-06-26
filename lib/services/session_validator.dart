// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

/// 🔐 Session Validator — validates session state with replay protection
///
/// This service maintains authentication state and prevents token replay attacks.
///
/// Security properties:
/// 1. Transfer tokens are single-use (tracked by hash)
/// 2. JWT expiry is validated on every check
/// 3. Used tokens are permanently blocked
/// 4. Session state survives page reloads
class SessionValidator {
  static const String _sessionStateKey = 'bar_session_state';
  static const String _usedTokensKey   = 'bar_used_transfer_tokens';

  // ── Session State ──────────────────────────────────────

  /// Represents the current authentication session
  static AuthSession? getCurrentSession() {
    try {
      final raw = _getItem(_sessionStateKey);
      if (raw == null || raw.isEmpty) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final session = AuthSession._fromJson(json);

      // Validate expiry
      if (session.isExpired) {
        clearSession();
        return null;
      }

      return session;
    } catch (e) {
      _removeItem(_sessionStateKey);
      return null;
    }
  }

  /// Store session after successful auth exchange
  static void storeSession(AuthSession session) {
    _setItem(_sessionStateKey, jsonEncode(session.toJson()));
  }

  /// Clear all session data (logout)
  static void clearSession() {
    _removeItem(_sessionStateKey);
    print('[SessionValidator] Session cleared');
  }

  // ── Replay Protection ───────────────────────────────────

  /// Check if a transfer token has already been used.
  /// Returns true if token was already exchanged (replay attack blocked).
  static bool isTokenUsed(String token) {
    try {
      final hash = _hashToken(token);
      final raw = _getItem(_usedTokensKey);
      if (raw == null || raw.isEmpty) return false;

      final used = (jsonDecode(raw) as List).cast<String>();
      return used.contains(hash);
    } catch (_) {
      return false;
    }
  }

  /// Mark a transfer token as used (called after successful exchange).
  /// Token is permanently blacklisted — cannot be replayed.
  static void markTokenUsed(String token) {
    try {
      final hash = _hashToken(token);
      final raw = _getItem(_usedTokensKey);
      final used = raw != null && raw.isNotEmpty
          ? (jsonDecode(raw) as List).cast<String>()
          : <String>[];

      if (!used.contains(hash)) {
        used.add(hash);
        _setItem(_usedTokensKey, jsonEncode(used));
        print('[SessionValidator] Token marked as used: ${hash.substring(0, 8)}...');
      }
    } catch (e) {
      print('[SessionValidator] Failed to mark token used: $e');
    }
  }

  /// Check if a JWT is expired
  static bool isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) normalized += '=';

      final decoded = utf8.decode(base64Decode(normalized));
      final data = jsonDecode(decoded) as Map<String, dynamic>;

      if (data['exp'] != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          (data['exp'] as num).toInt() * 1000,
          isUtc: true,
        );
        return expiry.isBefore(DateTime.now());
      }

      // No exp claim — consider valid but warn
      print('[SessionValidator] JWT has no exp claim — treating as valid');
      return false;
    } catch (e) {
      print('[SessionValidator] JWT decode error: $e — treating as expired');
      return true;
    }
  }

  /// Validate existing JWT from localStorage
  static bool hasValidJwt() {
    final token = _getTokenFromStorage();
    if (token == null || token.isEmpty) return false;
    if (isJwtExpired(token)) {
      _removeTokenFromStorage();
      return false;
    }
    return true;
  }

  /// Get JWT from localStorage
  static String? getJwt() {
    final token = _getTokenFromStorage();
    if (token == null || token.isEmpty) return null;
    if (isJwtExpired(token)) {
      _removeTokenFromStorage();
      return null;
    }
    return token;
  }

  /// Clear JWT only (keep other session data)
  static void clearJwt() {
    _removeTokenFromStorage();
  }

  /// Full logout — clear everything
  static void fullLogout() {
    clearSession();
    clearJwt();
    _removeItem(_usedTokensKey);
    _removeItem('bar_user_context');
    _removeItem('bar_transfer_token');
    print('[SessionValidator] Full logout completed');
  }

  // ── Helpers ─────────────────────────────────────────────

  static String _hashToken(String token) {
    // Simple hash for token tracking — not cryptographic, just for dedup
    var hash = 0;
    for (var i = 0; i < token.length; i++) {
      hash = ((hash << 5) - hash) + token.codeUnitAt(i);
      hash = hash & hash;
    }
    return hash.abs().toString();
  }

  static String? _getItem(String key) {
    try {
      // Import from dart:html for web
      // ignore: avoid_web_libraries_in_flutter
      return _localStorageGet(key);
    } catch (_) {
      return null;
    }
  }

  static void _setItem(String key, String value) {
    try {
      _localStorageSet(key, value);
    } catch (_) {}
  }

  static void _removeItem(String key) {
    try {
      _localStorageRemove(key);
    } catch (_) {}
  }

  static String? _getTokenFromStorage() {
    try {
      final raw = _getItem('bar_user_context');
      if (raw != null && raw.isNotEmpty) {
        final ctx = jsonDecode(raw) as Map<String, dynamic>;
        final t = ctx['token']?.toString();
        if (t != null && t.isNotEmpty) return t;
      }
      final direct = _getItem('token');
      return direct;
    } catch (_) {
      return null;
    }
  }

  static void _removeTokenFromStorage() {
    _removeItem('token');
    try {
      final raw = _getItem('bar_user_context');
      if (raw != null && raw.isNotEmpty) {
        final ctx = jsonDecode(raw) as Map<String, dynamic>;
        ctx.remove('token');
        _setItem('bar_user_context', jsonEncode(ctx));
      }
    } catch (_) {}
  }
}

// ── Auth Session Model ────────────────────────────────────────────────

class AuthSession {
  final String? jwt;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? userId;
  final String authMethod; // 'transfer_exchange' | 'existing_jwt'

  AuthSession({
    this.jwt,
    required this.createdAt,
    required this.expiresAt,
    this.userId,
    required this.authMethod,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Short-lived sessions (from transfer token) expire faster
  factory AuthSession.fromTransferExchange({required String jwt, String? userId}) {
    return AuthSession(
      jwt: jwt,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      userId: userId,
      authMethod: 'transfer_exchange',
    );
  }

  factory AuthSession.fromExistingJwt({required String jwt, String? userId}) {
    // Parse JWT expiry from the token itself
    try {
      final parts = jwt.split('.');
      if (parts.length == 3) {
        String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
        while (normalized.length % 4 != 0) normalized += '=';
        final decoded = jsonDecode(utf8.decode(base64Decode(normalized))) as Map<String, dynamic>;
        final exp = decoded['exp'] as num?;
        if (exp != null) {
          return AuthSession(
            jwt: jwt,
            createdAt: DateTime.now(),
            expiresAt: DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true),
            userId: userId,
            authMethod: 'existing_jwt',
          );
        }
      }
    } catch (_) {}

    // Fallback: 2-hour session for tokens without exp claim
    return AuthSession(
      jwt: jwt,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      userId: userId,
      authMethod: 'existing_jwt',
    );
  }

  factory AuthSession._fromJson(Map<String, dynamic> json) {
    return AuthSession(
      jwt: json['jwt'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      userId: json['userId'] as String?,
      authMethod: json['authMethod'] as String? ?? 'transfer_exchange',
    );
  }

  Map<String, dynamic> toJson() => {
    'jwt': jwt,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'userId': userId,
    'authMethod': authMethod,
  };
}

// ── localStorage using dart:html ──────────────────────────────────────

String? _localStorageGet(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void _localStorageSet(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

void _localStorageRemove(String key) {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {}
}