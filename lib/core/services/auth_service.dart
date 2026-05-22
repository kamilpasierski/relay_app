import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:relay_app/core/config/api_config.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> verifyTwoFactorCode(
    String intermediateToken,
    String code,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/2fa/verify');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'intermediate_token': intermediateToken,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          await saveToken(data['access_token']);
          return true;
        }
      } else {
        debugPrint(
          'Błąd 2FA. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Błąd połączenia 2FA: $e');
      return false;
    }
    return false;
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.userProfile),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Błąd pobierania profilu: $e');
    }
    return null;
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
    String newPasswordConfirmation,
  ) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('${ApiConfig.baseUrl}/user/password');

    try {
      final response = await http.put(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPasswordConfirmation,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Błąd zmiany hasła. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Błąd połączenia: $e');
      return false;
    }
  }

  Future<bool> sendMobileResetPin(String email) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/public/mobile/password/email');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Błąd wysyłania PIN-u. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Błąd połączenia: $e');
      return false;
    }
  }

  Future<bool> resetPasswordWithPin(
    String email,
    String pin,
    String password,
    String passwordConfirmation,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/public/mobile/password/reset');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'pin': pin,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
          'Błąd resetu hasła. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Błąd połączenia: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('${ApiConfig.baseUrl}/user');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Błąd pobierania profilu użytkownika: $e');
    }
    return null;
  }

  Future<bool> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final googleUser = await googleSignIn.authenticate();

      final scopes = ['email', 'profile'];
      var clientAuth = await googleUser.authorizationClient
          .authorizationForScopes(scopes);

      clientAuth ??= await googleUser.authorizationClient.authorizeScopes(
        scopes,
      );
      final String providerToken = clientAuth.accessToken;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/google'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'provider_token': providerToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await saveToken(data['token']);
          return true;
        }
      } else {
        debugPrint('Błąd Google Auth na backendzie: ${response.body}');
      }
      return false;
    } catch (e) {
      debugPrint('Anulowano logowanie lub wystąpił błąd: $e');
      return false;
    }
  }

  Future<bool?> get2FAStatus() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('${ApiConfig.baseUrl}/user/2fa/status');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['two_factor_enabled'] ?? false;
      }
    } catch (e) {
      debugPrint('Błąd pobierania statusu 2FA: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> enable2FA() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('${ApiConfig.baseUrl}/auth/2fa/setup');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint(
          'Błąd włączania 2FA: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Wyjątek sieciowy podczas włączania 2FA: $e');
      return null;
    }
  }

  Future<bool> disable2FA() async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('${ApiConfig.baseUrl}/auth/2fa/disable');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Wyjątek sieciowy podczas wyłączania 2FA: $e');
      return false;
    }
  }
}
