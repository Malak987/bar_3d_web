import 'dart:convert';
import 'dart:js/js_wasm.dart';
import 'package:http/http.dart' as http;

/// 🔐 Secure Auth Transfer Token Exchange Service
///
/// Flow:
/// 1. Flutter opens WebView with ?token=XYZ
/// 2. This service reads token from URL
/// 3. Calls backend to exchange transfer token for JWT session
/// 4. JWT is stored in localStorage for subsequent API calls
///
/// ✅ JWT-based auth — NO cookies, NO credentials: 'include'
/// This avoids CORS preflight failures caused by wildcard origins
/// combined with credential headers.
class AuthTransferService {
  static const String baseUrl = 'https://bar-backend.runasp.net';
  static const String exchangePath = '/api/AuthTransfer/ExchangeTransferToken';

  /// Check if URL has auth transfer token
  static String? getTransferTokenFromUrl() {
    try {
      final search = _getLocationSearch();
      if (search == null || search.isEmpty) return null;

      final params = search.startsWith('?')
          ? search.substring(1).split('&')
          : search.split('&');

      for (final param in params) {
        final parts = param.split('=');
        if (parts.length == 2 && parts[0] == 'token') {
          return parts[1];
        }
      }
      return null;
    } catch (e) {
      print('[AUTH_TRANSFER] Error reading URL token: $e');
      return null;
    }
  }

  /// Get location.search from JS
  static String? _getLocationSearch() {
    try {
      if (const bool.fromEnvironment('dart.library.jsinterop', defaultValue: false)) {
        return _getSearchFromWeb();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Exchange transfer token for authenticated session (JWT)
  /// Called once when page loads with ?token= parameter
  static Future<Map<String, dynamic>> exchangeTransferToken() async {
    final token = getTransferTokenFromUrl();
    if (token == null || token.isEmpty) {
      print('[AUTH_TRANSFER] No token found in URL');
      return {'success': false, 'error': 'No token in URL'};
    }

    print('[AUTH_TRANSFER] Token received: ${token.substring(0, 8)}...');
    print('[AUTH_TRANSFER] Exchange request started');

    try {
      // ✅ NO credentials/cookies — pure JSON POST with token in body.
      //    This avoids CORS preflight failures.
      final response = await http.post(
        Uri.parse('$baseUrl$exchangePath'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'transferToken': token,
        }),
      );

      print('[AUTH_TRANSFER] Exchange response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['isSucceeded'] == true) {
          // Extract JWT from response
          final data = body['data'] as Map<String, dynamic>? ?? body;
          final jwtToken = data['accessToken'] as String?
              ?? data['token'] as String?
              ?? data['jwt'] as String?
              ?? data['authToken'] as String?;

          if (jwtToken != null && jwtToken.isNotEmpty) {
            print('[AUTH_TRANSFER] Exchange success — JWT received');
            // Store token for subsequent API calls
            _storeToken(jwtToken);
            print('[AUTH_TRANSFER] User authenticated ✓');
            return {
              'success': true,
              'token': jwtToken,
            };
          }

          // Backend may use session-based auth (if CORS is properly configured)
          print('[AUTH_TRANSFER] Exchange success (session-based)');
          print('[AUTH_TRANSFER] User authenticated ✓');
          return {'success': true};
        } else {
          print('[AUTH_TRANSFER] ❌ Exchange failed: ${body['message']}');
          return {'success': false, 'error': body['message'] ?? 'Exchange failed'};
        }
      } else {
        print('[AUTH_TRANSFER] ❌ HTTP ${response.statusCode}: ${response.body}');
        return {'success': false, 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('[AUTH_TRANSFER] ❌ Network error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check if user is authenticated (has valid JWT)
  static Future<bool> isAuthenticated() async {
    final token = _readToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    // Check JWT expiry
    if (_isTokenExpired(token)) {
      _clearToken();
      return false;
    }

    return true;
  }

  // ── Token Storage (localStorage wrapper) ──────────────

  static void _storeToken(String token) {
    try {
      // Web: localStorage
      if (const bool.fromEnvironment('dart.library.js_interop', defaultValue: false)) {
        // Use JS interop to set localStorage
        _setLocalStorage('token', token);
      }
    } catch (e) {
      print('[AUTH_TRANSFER] Failed to store token: $e');
    }
  }

  static String? _readToken() {
    try {
      if (const bool.fromEnvironment('dart.library.js_interop', defaultValue: false)) {
        return _getLocalStorage('token');
      }
    } catch (e) {
      print('[AUTH_TRANSFER] Failed to read token: $e');
    }
    return null;
  }

  static void _clearToken() {
    try {
      if (const bool.fromEnvironment('dart.library.js_interop', defaultValue: false)) {
        _removeLocalStorage('token');
      }
    } catch (e) {
      print('[AUTH_TRANSFER] Failed to clear token: $e');
    }
  }

  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = parts[1];
      // Base64url decode
      String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) normalized += '=';
      final decoded = utf8.decode(base64Decode(normalized));
      final data = json.decode(decoded);
      if (data['exp'] != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000);
        return expiry.isBefore(DateTime.now());
      }
      return false;
    } catch (e) {
      return true;
    }
  }
}

// ── JS Interop helpers (declared here for web compilation) ──

@JS('localStorage.getItem')
external String? _getLocalStorage(String key);

@JS('localStorage.setItem')
external void _setLocalStorage(String key, String value);

@JS('localStorage.removeItem')
external void _removeLocalStorage(String key);

/// Helper function to get search params from web API
String? _getSearchFromWeb() {
  try {
    return Uri.base.queryParameters['token'];
  } catch (e) {
    return null;
  }
}