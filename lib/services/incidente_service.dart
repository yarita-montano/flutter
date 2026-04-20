import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/incidente.dart';
import '../models/evidencia.dart';

class IncidenteService {
  // En emulador Android, 10.0.2.2 apunta al localhost de la máquina host
  static const String baseUrl = "http://10.0.2.2:8000";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// 🚨 CREAR EMERGENCIA
  Future<Map<String, dynamic>> crearIncidencia({
    required int idVehiculo,
    required String descripcionUsuario,
    required double latitud,
    required double longitud,
  }) async {
    try {
      print('[INCIDENTE] 🚨 Reportando emergencia...');
      print('[INCIDENTE] Vehículo: $idVehiculo');
      print('[INCIDENTE] Descripción: $descripcionUsuario');
      print('[INCIDENTE] GPS: $latitud, $longitud');

      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'No autenticado'};
      }

      final body = {
        'id_vehiculo': idVehiculo,
        'descripcion_usuario': descripcionUsuario,
        'latitud': latitud,
        'longitud': longitud,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/incidencias/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      print('[INCIDENTE] Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final incidente =
            IncidenteResponse.fromJson(jsonDecode(response.body));
        print('[INCIDENTE] ✅ Emergencia reportada: #${incidente.idIncidente}');

        return {
          'success': true,
          'incidente': incidente,
          'message': '✅ Emergencia reportada. Técnicos en camino...',
        };
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['detail'] ?? 'Datos inválidos',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sesión expirada',
          'code': 'AUTH_EXPIRED',
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Vehículo no encontrado'};
      }

      return {'success': false, 'error': 'Error al reportar emergencia'};
    } on TimeoutException catch (_) {
      print('[INCIDENTE] ❌ Timeout');
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      print('[INCIDENTE] ❌ Exception: $e');
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  /// 📋 LISTAR MIS EMERGENCIAS
  Future<Map<String, dynamic>> listarMisIncidencias() async {
    try {
      print('[INCIDENTE] 📋 Cargando historial...');

      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'No autenticado'};
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/incidencias/mis-incidencias'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      print('[INCIDENTE] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final incidencias =
            data.map((json) => IncidenteDetalle.fromJson(json)).toList();

        print('[INCIDENTE] ✅ ${incidencias.length} incidencias cargadas');
        return {'success': true, 'incidencias': incidencias};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sesión expirada',
          'code': 'AUTH_EXPIRED',
        };
      }

      return {'success': false, 'error': 'Error al cargar incidencias'};
    } catch (e) {
      print('[INCIDENTE] ❌ Exception: $e');
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  /// 📌 OBTENER DETALLE
  Future<Map<String, dynamic>> obtenerIncidencia(int idIncidente) async {
    try {
      print('[INCIDENTE] 📌 Cargando detalle #$idIncidente...');

      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'No autenticado'};
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/incidencias/$idIncidente'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final incidente =
            IncidenteDetalle.fromJson(jsonDecode(response.body));
        return {'success': true, 'incidente': incidente};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sesión expirada',
          'code': 'AUTH_EXPIRED',
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Incidencia no encontrada'};
      }

      return {'success': false, 'error': 'Error al cargar incidencia'};
    } catch (e) {
      print('[INCIDENTE] ❌ Exception: $e');
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  /// 📷 SUBIR EVIDENCIA (imagen / audio)
  Future<Map<String, dynamic>> subirEvidencia({
    required int idIncidente,
    required int idTipoEvidencia,
    required File archivo,
  }) async {
    try {
      print('[EVIDENCIA] 📤 Subiendo archivo...');
      print('[EVIDENCIA] Incidente: $idIncidente, Tipo: $idTipoEvidencia');
      print('[EVIDENCIA] Ruta: ${archivo.path}');

      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'No autenticado'};
      }

      final uri = Uri.parse('$baseUrl/incidencias/$idIncidente/evidencias');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['id_tipo_evidencia'] = idTipoEvidencia.toString();
      request.files
          .add(await http.MultipartFile.fromPath('archivo', archivo.path));

      final streamed =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      print('[EVIDENCIA] Status: ${response.statusCode}');
      print('[EVIDENCIA] Body: ${response.body}');

      if (response.statusCode == 201) {
        final evidencia = Evidencia.fromJson(jsonDecode(response.body));
        print('[EVIDENCIA] ✅ Subida: #${evidencia.idEvidencia}');
        return {'success': true, 'evidencia': evidencia};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sesión expirada',
          'code': 'AUTH_EXPIRED',
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Incidente no encontrado'};
      }

      return {'success': false, 'error': 'Error ${response.statusCode}'};
    } on TimeoutException catch (_) {
      return {'success': false, 'error': 'Tiempo de conexión agotado (60s)'};
    } catch (e) {
      print('[EVIDENCIA] ❌ Exception: $e');
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  /// 📋 LISTAR EVIDENCIAS DE UN INCIDENTE
  Future<Map<String, dynamic>> listarEvidencias(int idIncidente) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'error': 'No autenticado'};
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/incidencias/$idIncidente/evidencias'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final evidencias =
            data.map((j) => Evidencia.fromJson(j)).toList();
        return {'success': true, 'evidencias': evidencias};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Sesión expirada',
          'code': 'AUTH_EXPIRED',
        };
      }

      return {'success': false, 'error': 'Error al cargar evidencias'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  /// 📍 OBTENER UBICACIÓN ACTUAL
  Future<Map<String, double>?> obtenerUbicacionActual() async {
    try {
      print('[GPS] 📍 Solicitando ubicación...');

      final permiso = await _verificarPermisoGPS();
      if (!permiso) {
        print('[GPS] ❌ Permiso denegado');
        return null;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      print('[GPS] ✅ ${posicion.latitude}, ${posicion.longitude}');
      return {
        'latitud': posicion.latitude,
        'longitud': posicion.longitude,
      };
    } catch (e) {
      print('[GPS] ❌ Exception: $e');
      return null;
    }
  }

  /// 🔐 Verificar permisos GPS
  Future<bool> _verificarPermisoGPS() async {
    try {
      final habilitado = await Geolocator.isLocationServiceEnabled();
      if (!habilitado) {
        print('[GPS] ❌ Servicios de ubicación deshabilitados');
        return false;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          return false;
        }
      }

      if (permiso == LocationPermission.deniedForever) {
        print('[GPS] ❌ Permiso permanentemente denegado');
        return false;
      }

      print('[GPS] ✅ Permiso otorgado');
      return true;
    } catch (e) {
      print('[GPS] ❌ Error: $e');
      return false;
    }
  }
}
