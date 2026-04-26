import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

/// Handler global para mensajes en background (debe ser top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Mensaje en background: ${message.messageId}');
}

class NotificationService {
  static const String _baseUrl = ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  static bool _initialized = false;

  /// Inicializa FCM. Llámalo una sola vez en main() tras Firebase.initializeApp().
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Solicitar permiso en iOS / Android 13+
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permiso: ${settings.authorizationStatus}');

    // Registrar token en el backend al obtenerlo
    FirebaseMessaging.instance.onTokenRefresh.listen(_registrarToken);
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registrarToken(token);
    }

    // Mensajes en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
    });

    // App abierta desde notificación (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Abierto desde notificación: ${message.data}');
    });
  }

  /// Fuerza registro del token actual en backend.
  /// Útil justo después de login para evitar perder el registro del token.
  Future<void> syncTokenWithBackend() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] No hay token para sincronizar');
        return;
      }
      await _registrarToken(token);
    } catch (e) {
      debugPrint('[FCM] Error en syncTokenWithBackend: $e');
    }
  }

  Future<void> _registrarToken(String token) async {
    try {
      final authToken = await _authService.getToken();
      if (authToken == null) {
        debugPrint('[FCM] Sin auth token, no se puede registrar push token aún');
        return;
      }

      await http.post(
        Uri.parse('$_baseUrl/notificaciones/push-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'push_token': token}),
      );
      debugPrint('[FCM] Token registrado en backend');
    } catch (e) {
      debugPrint('[FCM] Error al registrar token: $e');
    }
  }
}
