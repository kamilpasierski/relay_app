import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:relay_app/core/config/api_config.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final http.Client httpClient;
  final FlutterSecureStorage storage;
  static const _tokenKey = 'auth_token';

  AuthService({http.Client? httpClient, FlutterSecureStorage? storage})
    : httpClient = httpClient ?? http.Client(),
      storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await storage.read(key: _tokenKey);
  }

  Future<void> logout() async {
    await storage.delete(key: _tokenKey);
  }

  Future<void> clearSession() async {
    await storage.delete(key: _tokenKey);
  }

  Future<bool> verifyTwoFactorCode(
    String intermediateToken,
    String code,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/2fa/verify');

    try {
      final response = await httpClient.post(
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
      final response = await httpClient.get(
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
      final response = await httpClient.put(
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
      final response = await httpClient.post(
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
      final response = await httpClient.post(
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
      final response = await httpClient.get(
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
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId:
            '174977229271-gcfhv7vkko8rh9ocnraa5ft7v50p4fqh.apps.googleusercontent.com',
      );

      await googleSignIn.signOut();

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'https://www.googleapis.com/auth/userinfo.profile',
      ]);

      final String? providerToken =
          googleAuth.idToken ?? clientAuth.accessToken;

      if (providerToken == null) {
        debugPrint('Błąd: Nie udało się wyciągnąć tokena od dostawcy Google.');
        return false;
      }

      final response = await httpClient.post(
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
        debugPrint(
          'Błąd Google Auth na backendzie: ${response.statusCode} - ${response.body}',
        );
      }
      return false;
    } catch (e) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('Logowanie Google anulowane przez użytkownika.');
        return false;
      }

      debugPrint('Wystąpił nieoczekiwany błąd podczas logowania Google: $e');
      return false;
    }
  }

  Future<bool?> get2FAStatus() async {
    final token = await getToken();
    if (token == null) return null;

    final url = Uri.parse('${ApiConfig.baseUrl}/user/2fa/status');

    try {
      final response = await httpClient.get(
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
      final response = await httpClient.post(
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
      final response = await httpClient.post(
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
