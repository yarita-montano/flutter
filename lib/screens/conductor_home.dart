import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/vehiculo_service.dart';
import 'reportar_emergencia_screen.dart';

class ConductorHomeScreen extends StatefulWidget {
  const ConductorHomeScreen({super.key});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  final AuthService _authService = AuthService();
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await _authService.getUserName();
    final email = await _authService.getUserEmail();

    setState(() {
      _userName = name ?? 'Usuario';
      _userEmail = email ?? '';
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergencias Vehiculares',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
            tooltip: 'Mi Perfil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Profile Section
                  Container(
                    color: Colors.red.shade600,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userEmail,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '👤 Cliente (Conductor)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Report Emergency Card
                        _buildActionCard(
                          icon: Icons.warning,
                          title: 'Reportar Emergencia',
                          description: 'Solicitar asistencia vehicular',
                          color: Colors.red,
                          onTap: () async {
                            // Obtener vehículos del usuario
                            final vehiculoService = VehiculoService();
                            final resultado = await vehiculoService.listarMisVehiculos();
                            
                            if (resultado['success']) {
                              final vehiculos = resultado['vehiculos'] ?? [];
                              
                              if (!mounted) return;
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReportarEmergenciaScreen(
                                    vehiculos: vehiculos,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(resultado['error'] ?? 'Error al cargar vehículos'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // My Vehicles Card
                        _buildActionCard(
                          icon: Icons.directions_car,
                          title: 'Mis Vehículos',
                          description: 'Gestionar vehículos registrados',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pushNamed(context, '/mis-vehiculos');
                          },
                        ),
                        const SizedBox(height: 16),

                        // View Incidents Card
                        _buildActionCard(
                          icon: Icons.history,
                          title: 'Mis Incidentes',
                          description: 'Ver historial de emergencias',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pushNamed(context, '/historial-emergencias');
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Info Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Información Importante',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Reporta tu emergencia vehicular y recibirás asistencia de nuestros técnicos calificados.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Mantén tu perfil actualizado para recibir mejor asistencia.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• El token de autenticación expira en 30 minutos por seguridad.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
