class ApiConfig {
  // 🔧 Cambia a `false` cuando pruebes en dispositivo físico.
  static const bool isEmulator = false;

  // Emulador Android: 10.0.2.2 → apunta al localhost del host.
  static const String _emulatorUrl = 'http://10.0.2.2:8000';

  // Dispositivo físico: IP LAN de tu PC (la misma red Wi-Fi).
  // Cámbiala si tu router asigna otra IP.
  static const String _deviceUrl = 'http://192.168.1.102:8000';

  static const String baseUrl = isEmulator ? _emulatorUrl : _deviceUrl;
}
