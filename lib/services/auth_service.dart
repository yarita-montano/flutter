import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AuthService {
  // ✅ Manejo automático de emulador y dispositivo físico
  static const bool isEmulator = true; // Cambiar a false para dispositivo físico
  
  // URLs para diferentes ambientes
  static const String _emulatorUrl = 'http://10.0.2.2:8000'; // Android Emulator
  static const String _deviceUrl = 'http://192.168.1.5:8000'; // Cambiar IP según tu red local
  
  // URL base que se selecciona automáticamente
  static const String baseUrl = isEmulator ? _emulatorUrl : _deviceUrl;

  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('🔐 Intentando login con: $email');
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/usuarios/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Login exitoso');
        await _saveUserData(data);
        return {
          'success': true,
          'data': data,
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'error': errorData['detail'] ?? 'Error en login',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Error del servidor: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('access_token', data['access_token'] ?? '');
      await prefs.setString('token_type', data['token_type'] ?? 'bearer');
      await prefs.setString('user_id', data['usuario']['id_usuario'].toString());
      await prefs.setString('user_rol', data['usuario']['id_rol'].toString());
      await prefs.setString('user_name', data['usuario']['nombre'] ?? 'Usuario');
      await prefs.setString('user_email', data['usuario']['email'] ?? '');
      await prefs.setBool('user_activo', data['usuario']['activo'] ?? false);
      await prefs.setString('login_time', DateTime.now().toIso8601String());
      
      debugPrint('✅ Datos guardados en SharedPreferences');
    } catch (e) {
      debugPrint('❌ Error al guardar datos: $e');
      rethrow;
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  // Get user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_rol');
    } catch (e) {
      debugPrint('❌ Error getting user role: $e');
      return null;
    }
  }

  // Get user name
  Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_name');
    } catch (e) {
      debugPrint('❌ Error getting user name: $e');
      return null;
    }
  }

  // Get user email
  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_email');
    } catch (e) {
      debugPrint('❌ Error getting user email: $e');
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking authentication: $e');
      return false;
    }
  }

  // Logout and clear all data
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('token_type');
      await prefs.remove('user_id');
      await prefs.remove('user_rol');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_activo');
      await prefs.remove('login_time');
      debugPrint('✅ Logout completado, datos limpios');
    } catch (e) {
      debugPrint('❌ Error al hacer logout: $e');
    }
  }

  // Make authenticated request
  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final requestHeaders = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        ...?headers,
      };

      final url = Uri.parse('$baseUrl$endpoint');

      debugPrint('📡 $method $endpoint');

      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(url, headers: requestHeaders);
        case 'POST':
          return await http.post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'PUT':
          return await http.put(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
        case 'DELETE':
          return await http.delete(
            url,
            headers: requestHeaders,
          );
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      debugPrint('❌ Error en authenticatedRequest: $e');
      rethrow;
    }
  }

  // ============ VER PERFIL ============
  Future<Map<String, dynamic>> obtenerPerfil() async {
    try {
      final response = await authenticatedRequest('GET', '/usuarios/perfil');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Perfil obtenido correctamente');
        return {'success': true, 'perfil': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Sesión expirada. Por favor inicia sesión nuevamente'};
      } else {
        return {'success': false, 'error': 'Error al obtener perfil: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('❌ Error en obtenerPerfil: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ============ EDITAR PERFIL ============
  Future<Map<String, dynamic>> editarPerfil({
    String? nombre,
    String? telefono,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nombre != null) body['nombre'] = nombre;
      if (telefono != null) body['telefono'] = telefono;
      if (password != null) body['password'] = password;

      if (body.isEmpty) {
        return {'success': false, 'error': 'No hay campos para actualizar'};
      }

      final response = await authenticatedRequest(
        'PUT',
        '/usuarios/perfil',
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Actualizar datos en SharedPreferences si se cambió el nombre
        if (nombre != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', nombre);
        }
        
        debugPrint('✅ Perfil actualizado correctamente');
        return {'success': true, 'perfil': data};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'Sesión expirada. Por favor inicia sesión nuevamente'};
      } else if (response.statusCode == 422) {
        return {'success': false, 'error': 'Datos inválidos. Verifica los campos'};
      } else {
        return {'success': false, 'error': 'Error al actualizar perfil: ${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('❌ Error en editarPerfil: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }
}
