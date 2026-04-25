import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/tecnico_login_response.dart';

class TecnicoAuthService {
  static const String _baseUrl = ApiConfig.baseUrl;
  static const String _tecnicoTokenKey = 'tecnico_token';
  static const String _tecnicoIdKey = 'tecnico_user_id';
  static const String _tecnicoRolKey = 'tecnico_user_rol';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<TecnicoLoginResponse> loginTecnico(String email, String password) async {
    debugPrint('[TecnicoAuthService] loginTecnico -> $email');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/usuarios/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = TecnicoLoginResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      if (data.usuario.idRol != 3) {
        throw Exception('Esta app es solo para tecnicos (rol=3)');
      }

      await _storage.write(key: _tecnicoTokenKey, value: data.accessToken);
      await _storage.write(
        key: _tecnicoIdKey,
        value: data.usuario.idUsuario.toString(),
      );
      await _storage.write(
        key: _tecnicoRolKey,
        value: data.usuario.idRol.toString(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data.accessToken);
      await prefs.setString('user_id', data.usuario.idUsuario.toString());
      await prefs.setString('user_rol', data.usuario.idRol.toString());
      await prefs.setString('user_name', data.usuario.nombre);
      await prefs.setString('user_email', data.usuario.email);

      debugPrint('[TecnicoAuthService] loginTecnico <- OK ${data.usuario.nombre}');
      return data;
    }

    String error = 'Error de autenticacion';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      error = (body['detail'] ?? error).toString();
    } catch (_) {
      error = 'Error ${response.statusCode}: ${response.body}';
    }

    throw Exception(error);
  }

  Future<String?> getTecnicoToken() async {
    return _storage.read(key: _tecnicoTokenKey);
  }

  Future<int?> getTecnicoId() async {
    final id = await _storage.read(key: _tecnicoIdKey);
    return id != null ? int.tryParse(id) : null;
  }

  Future<int?> getTecnicoRol() async {
    final id = await _storage.read(key: _tecnicoRolKey);
    return id != null ? int.tryParse(id) : null;
  }

  Future<bool> isTecnicoLoggedIn() async {
    final token = await _storage.read(key: _tecnicoTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    debugPrint('[TecnicoAuthService] logout');
    await _storage.delete(key: _tecnicoTokenKey);
    await _storage.delete(key: _tecnicoIdKey);
    await _storage.delete(key: _tecnicoRolKey);
  }
}
