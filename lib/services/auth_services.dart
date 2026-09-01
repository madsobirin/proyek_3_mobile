import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthServices {
  final ApiService _api = ApiService();

  // ── Login Manual ──
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final data = _api.handleResponse(response);
      final user = UserModel.fromJson({
        ...data['user'],
        'token': data['token'],
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      await prefs.setString('token', data['token']);

      return {'success': true, 'user': user};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  // ── Register ──
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _api.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      final data = _api.handleResponse(response);

      // Register berhasil — ada token langsung
      if (data['token'] != null) {
        final user = UserModel.fromJson({
          ...data['user'],
          'token': data['token'],
        });

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(user.toJson()));
        await prefs.setString('token', data['token']);

        return {'success': true, 'user': user};
      }
      // Register berhasil tanpa token (perlu login)
      return {'success': true, 'user': null};
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  // ── Login Google ──
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      print('=== DEBUG GOOGLE SIGN-IN ===');
      print('1. Web Client ID (serverClientId): ${Config.googleClientId}');

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        // Web hanya support clientId, mobile hanya support serverClientId
        clientId: kIsWeb ? Config.googleClientId : null,
        serverClientId: kIsWeb ? null : Config.googleClientId,
      );

      print('2. Memulai googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('3. User membatalkan login.');
        return {'success': false, 'message': 'Login dibatalkan.'};
      }
      print('3. Google user diperoleh: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final idToken = googleAuth.idToken;
      print('4. idToken: ${idToken != null ? "ADA (${idToken.substring(0, 20)}...)" : "NULL"}');

      if (idToken == null) {
        return {'success': false, 'message': 'Gagal mendapatkan token Google.'};
      }

      print('5. Mengirim idToken ke backend...');
      final response = await _api.post('/auth/google', {'id_token': idToken});
      final data = _api.handleResponse(response);

      final user = UserModel.fromJson({
        ...data['user'],
        'token': data['token'],
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson()));
      await prefs.setString('token', data['token']);

      print('6. Login Google BERHASIL!');
      return {'success': true, 'user': user};
    } catch (e) {
      print('!!! ERROR GOOGLE SIGN-IN: $e');
      final errorString = e.toString();
      if (errorString.contains('network_error') || 
          errorString.contains('ApiException: 7') || 
          errorString.contains('Tidak ada koneksi internet')) {
        return {
          'success': false, 
          'message': 'Tidak ada koneksi internet. Silakan periksa jaringan Anda.'
        };
      }
      return {
        'success': false, 
        'message': errorString.replaceFirst('Exception: ', '')
      };
    }
  }

  // ── Logout ──
  Future<void> logout() async {
    try {
      final response = await _api.post('/auth/logout', {});
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Logged out successfully from server
      }
    } catch (_) {}

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.disconnect();
    } catch (_) {}

    // Hapus semua local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
  }

  // ── Get current user dari local storage ──
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson == null) return null;
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  // ── Get token ──
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
