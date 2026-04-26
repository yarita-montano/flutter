import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/conductor_home.dart';
import 'screens/tecnico_dashboard_screen.dart';
import 'screens/mis_vehiculos_screen.dart';
import 'screens/registrar_vehiculo_screen.dart';
import 'screens/vehiculo_debug_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/reportar_emergencia_screen.dart';
import 'screens/historial_emergencias_screen.dart';
import 'screens/asignacion_detalle_screen.dart';
import 'screens/mensajes_screen.dart';
import 'services/auth_service.dart';
import 'services/tecnico_auth_service.dart';
import 'services/notification_service.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.separator(title: 'INICIANDO APLICACIÓN');

  // SharedPreferences
  try {
    await SharedPreferences.getInstance();
    AppLogger.success('SharedPreferences inicializado', tag: 'MAIN');
  } catch (e) {
    AppLogger.error('Error SharedPreferences', tag: 'MAIN', error: e);
  }

  // Firebase
  try {
    await Firebase.initializeApp();
    await NotificationService().init();
    AppLogger.success('Firebase inicializado', tag: 'MAIN');
  } catch (e) {
    AppLogger.error('Firebase no disponible (sin google-services.json?)', tag: 'MAIN', error: e);
  }

  AppLogger.info('Iniciando aplicación...', tag: 'MAIN');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergencias Vehiculares',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const _InitialScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/conductor-home': (context) => const ConductorHomeScreen(),
        '/tecnico-home': (context) => const TecnicoDashboardScreen(),
        '/tecnico-dashboard': (context) => const TecnicoDashboardScreen(),
        '/mis-vehiculos': (context) => MisVehiculosScreen(),
        '/registrar-vehiculo': (context) => RegistrarVehiculoScreen(),
        '/debug-vehiculos': (context) => VehiculoDebugScreen(),
        '/perfil': (context) => PerfilScreen(),
        '/reportar-emergencia': (context) =>
            const ReportarEmergenciaScreen(vehiculos: []),
        '/historial-emergencias': (context) =>
            const HistorialEmergenciasScreen(),
        '/asignacion-detalle': (context) {
          final id = ModalRoute.of(context)?.settings.arguments as int? ?? 0;
          return AsignacionDetalleScreen(idAsignacion: id);
        },
        '/mensajes': (context) {
          final id = ModalRoute.of(context)?.settings.arguments as int? ?? 0;
          return MensajesScreen(idIncidente: id);
        },
      },
    );
  }
}

class _InitialScreen extends StatefulWidget {
  const _InitialScreen();

  @override
  State<_InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<_InitialScreen> {
  final AuthService _authService = AuthService();
  final TecnicoAuthService _tecnicoAuthService = TecnicoAuthService();

  @override
  void initState() {
    super.initState();
    AppLogger.info('Iniciando verificación de autenticación...', tag: 'INITIAL_SCREEN');
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      AppLogger.debug('Esperando 500ms antes de verificar...', tag: 'INITIAL_SCREEN');
      await Future.delayed(const Duration(milliseconds: 500));
      
      AppLogger.info('Verificando si hay sesión activa...', tag: 'INITIAL_SCREEN');
      
      final isAuthenticated = await _authService.isAuthenticated();
      AppLogger.info('Estado de autenticación: ${isAuthenticated ? 'Autenticado ✅' : 'No autenticado ❌'}', tag: 'INITIAL_SCREEN');

      if (!mounted) {
        AppLogger.warning('El widget fue desmontado, canceling navegación', tag: 'INITIAL_SCREEN');
        return;
      }

      if (isAuthenticated) {
        final userRole = await _authService.getUserRole();
        final userName = await _authService.getUserName();
        final userId = await _authService.getUserId();
        final tecnicoLogged = await _tecnicoAuthService.isTecnicoLoggedIn();

        AppLogger.table('Información de Usuario', {
          'Nombre': userName ?? 'N/A',
          'ID': userId ?? 'N/A',
          'Rol': userRole ?? 'N/A',
          'Token Técnico': tecnicoLogged ? 'Sí' : 'No',
        }, tag: 'INITIAL_SCREEN');

        if (userRole == '1') {
          AppLogger.success('Navegando a: Conductor Home', tag: 'INITIAL_SCREEN');
          Navigator.of(context).pushReplacementNamed('/conductor-home');
        } else if (userRole == '3') {
          AppLogger.success('Navegando a: Técnico Dashboard', tag: 'INITIAL_SCREEN');
          Navigator.of(context).pushReplacementNamed('/tecnico-dashboard');
        } else {
          AppLogger.warning('Rol desconocido: $userRole', tag: 'INITIAL_SCREEN');
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        AppLogger.info('Sin sesión activa, navegando a Login', tag: 'INITIAL_SCREEN');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error crítico al verificar autenticación',
        tag: 'INITIAL_SCREEN',
        error: e,
        stackTrace: stackTrace,
      );
      
      if (mounted) {
        AppLogger.info('Navegando a Login como fallback', tag: 'INITIAL_SCREEN');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emergency_share,
              size: 80,
              color: Colors.red.shade600,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Emergencias Vehiculares',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Inicializando...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
