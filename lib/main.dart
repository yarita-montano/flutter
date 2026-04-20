import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/conductor_home.dart';
import 'screens/tecnico_home.dart';
import 'screens/mis_vehiculos_screen.dart';
import 'screens/registrar_vehiculo_screen.dart';
import 'screens/editar_vehiculo_screen.dart';
import 'screens/vehiculo_debug_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/reportar_emergencia_screen.dart';
import 'screens/historial_emergencias_screen.dart';
import 'screens/subir_evidencia_screen.dart';
import 'services/auth_service.dart';

void main() async {
  // Inicializar WidgetsBinding para operaciones async en main
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-inicializar SharedPreferences
  try {
    await SharedPreferences.getInstance();
    debugPrint('✅ SharedPreferences inicializado correctamente');
  } catch (e) {
    debugPrint('❌ Error al inicializar SharedPreferences: $e');
  }
  
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
        '/tecnico-home': (context) => const TecnicoHomeScreen(),
        '/mis-vehiculos': (context) => MisVehiculosScreen(),
        '/registrar-vehiculo': (context) => RegistrarVehiculoScreen(),
        '/debug-vehiculos': (context) => VehiculoDebugScreen(),
        '/perfil': (context) => PerfilScreen(),
        '/reportar-emergencia': (context) =>
            const ReportarEmergenciaScreen(vehiculos: []),
        '/historial-emergencias': (context) =>
            const HistorialEmergenciasScreen(),
        '/evidencias': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as int;
          return SubirEvidenciaScreen(idIncidente: id);
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

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 Iniciando aplicación...');
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('🔍 Verificando autenticación...');
      
      final isAuthenticated = await _authService.isAuthenticated();
      debugPrint('📋 ¿Autenticado?: $isAuthenticated');

      if (!mounted) return;

      if (isAuthenticated) {
        final userRole = await _authService.getUserRole();
        final userName = await _authService.getUserName();
        
        debugPrint('👤 Usuario: $userName, Rol: $userRole');
        
        if (userRole == '1') {
          debugPrint('✅ Navegando a: Conductor Home');
          Navigator.of(context).pushReplacementNamed('/conductor-home');
        } else if (userRole == '3') {
          debugPrint('✅ Navegando a: Técnico Home');
          Navigator.of(context).pushReplacementNamed('/tecnico-home');
        } else {
          debugPrint('✅ Navegando a: Login');
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        debugPrint('✅ Navegando a: Login');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error al verificar autenticación: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      
      if (mounted) {
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
