import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/asignacion_response.dart';
import 'auth_service.dart';
import 'tecnico_auth_service.dart';

class TecnicoAsignacionesService {
  static const String _baseUrl = ApiConfig.baseUrl;
  final TecnicoAuthService _authService = TecnicoAuthService();
  final AuthService _generalAuthService = AuthService();

  String _tokenPreview(String token) {
    if (token.length <= 12) return token;
    return '${token.substring(0, 8)}...${token.substring(token.length - 4)}';
  }

  String _tokenSourceLabel(String source) {
    switch (source) {
      case 'tecnico_secure':
        return 'FlutterSecureStorage';
      case 'general_shared_prefs':
        return 'SharedPreferences';
      default:
        return source;
    }
  }

  Future<List<Map<String, String>>> _obtenerTokensCandidatos() async {
    final tecnicoToken = await _authService.getTecnicoToken();
    final generalToken = await _generalAuthService.getToken();

    final candidatos = <Map<String, String>>[];

    if (tecnicoToken != null && tecnicoToken.isNotEmpty) {
      candidatos.add({'source': 'tecnico_secure', 'token': tecnicoToken});
    }
    if (generalToken != null &&
        generalToken.isNotEmpty &&
        generalToken != tecnicoToken) {
      candidatos.add({'source': 'general_shared_prefs', 'token': generalToken});
    }

    debugPrint(
      '[AUTH DBG] tokens candidatos => '
      'secure=${tecnicoToken != null && tecnicoToken.isNotEmpty}, '
      'general=${generalToken != null && generalToken.isNotEmpty}, '
      'total=${candidatos.length}',
    );

    return candidatos;
  }

  Future<String> _resolverTokenTecnico() async {
    final candidatos = await _obtenerTokensCandidatos();
    if (candidatos.isEmpty) {
      throw Exception('Token no disponible');
    }

    final source = candidatos.first['source']!;
    final token = candidatos.first['token']!;
    debugPrint(
      '[AUTH DBG] token elegido inicial (${_tokenSourceLabel(source)}): '
      '${_tokenPreview(token)}',
    );
    return token;
  }

  Future<AsignacionResponse?> obtenerAsignacionActual() async {
    try {
      final candidatos = await _obtenerTokensCandidatos();
      if (candidatos.isEmpty) {
        throw Exception('Token no disponible');
      }

      Exception? ultimoError;

      for (final candidato in candidatos) {
        final source = candidato['source']!;
        final token = candidato['token']!;

        debugPrint(
          '[API DBG] GET /tecnicos/asignacion-actual '
          'usando ${_tokenSourceLabel(source)} (${_tokenPreview(token)})',
        );

        final response = await http
            .get(
              Uri.parse('$_baseUrl/tecnicos/asignacion-actual'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 15));

        debugPrint(
          '[API DBG] asignacion-actual status=${response.statusCode} '
          'source=${_tokenSourceLabel(source)} body=${response.body}',
        );

        if (response.statusCode == 200) {
          return AsignacionResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          );
        }

        if (response.statusCode == 404) {
          return null;
        }

        if (response.statusCode == 401) {
          ultimoError = Exception(
            '401 con ${_tokenSourceLabel(source)}: ${response.body}',
          );
          continue;
        }

        throw Exception('Error ${response.statusCode}: ${response.body}');
      }

      throw ultimoError ?? Exception('No se pudo validar token tecnico');
    } catch (e) {
      debugPrint('[TecnicoAsignacionesService] obtenerAsignacionActual <- ERROR: $e');
      rethrow;
    }
  }

  Future<AsignacionResponse?> getAsignacionActual() async {
    return obtenerAsignacionActual();
  }

  Future<IncidenteResponse> getIncidenteDetalle(int idIncidente) async {
    final token = await _resolverTokenTecnico();

    final response = await http
        .get(
          Uri.parse('$_baseUrl/incidencias/$idIncidente'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return IncidenteResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception('Error al cargar incidente: ${response.body}');
  }

  Future<Position> _getCurrentLocation() async {
    debugPrint('[TecnicoAsignacionesService] _getCurrentLocation ->');

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Servicio de ubicacion deshabilitado');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicacion denegado');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicacion denegado permanentemente');
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  Future<AsignacionResponse> iniciarViaje(int idAsignacion) async {
    try {
      debugPrint('[TecnicoAsignacionesService] iniciarViaje -> $idAsignacion');

      final position = await _getCurrentLocation();
      final latitud = position.latitude;
      final longitud = position.longitude;

      debugPrint('[TecnicoAsignacionesService] GPS: $latitud, $longitud');

      final token = await _resolverTokenTecnico();
      debugPrint('[AUTH DBG] iniciarViaje token=${_tokenPreview(token)}');

      final response = await http
          .put(
            Uri.parse('$_baseUrl/tecnicos/mis-asignaciones/$idAsignacion/iniciar-viaje'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'latitud_tecnico': latitud,
              'longitud_tecnico': longitud,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[TecnicoAsignacionesService] Response: ${response.statusCode}');
      debugPrint('[API DBG] iniciar-viaje body=${response.body}');

      if (response.statusCode == 200) {
        return AsignacionResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw Exception('Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('[TecnicoAsignacionesService] iniciarViaje <- ERROR: $e');
      rethrow;
    }
  }

  Future<AsignacionResponse> completarServicio(
    int idAsignacion, {
    double? costoEstimado,
    String? resumenTrabajo,
  }) async {
    try {
      debugPrint('[TecnicoAsignacionesService] completarServicio -> $idAsignacion');

      final token = await _resolverTokenTecnico();
      debugPrint('[AUTH DBG] completarServicio token=${_tokenPreview(token)}');

      final body = <String, dynamic>{};
      if (costoEstimado != null) {
        body['costo_estimado'] = costoEstimado;
      }
      if (resumenTrabajo != null && resumenTrabajo.trim().isNotEmpty) {
        body['resumen_trabajo'] = resumenTrabajo.trim();
      }

      final response = await http
          .put(
            Uri.parse('$_baseUrl/tecnicos/mis-asignaciones/$idAsignacion/completar'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[TecnicoAsignacionesService] completarServicio response: ${response.statusCode}');
      debugPrint('[API DBG] completar body=${response.body}');

      if (response.statusCode == 200) {
        return AsignacionResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      throw Exception('Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('[TecnicoAsignacionesService] completarServicio <- ERROR: $e');
      rethrow;
    }
  }

  Future<AsignacionResponse> completar(
    int idAsignacion, {
    double? costoEstimado,
    String? resumenTrabajo,
  }) {
    return completarServicio(
      idAsignacion,
      costoEstimado: costoEstimado,
      resumenTrabajo: resumenTrabajo,
    );
  }
}
