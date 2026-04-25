import 'package:flutter/material.dart';

import '../models/asignacion_response.dart';
import '../services/auth_service.dart';
import '../services/tecnico_asignaciones_service.dart';
import '../services/tecnico_auth_service.dart';

class TecnicoDashboardScreen extends StatefulWidget {
  const TecnicoDashboardScreen({super.key});

  @override
  State<TecnicoDashboardScreen> createState() => _TecnicoDashboardScreenState();
}

class _TecnicoDashboardScreenState extends State<TecnicoDashboardScreen> {
  final TecnicoAsignacionesService _tecnicoService =
      TecnicoAsignacionesService();
  final AuthService _authService = AuthService();
  final TecnicoAuthService _tecnicoAuthService = TecnicoAuthService();

  AsignacionResponse? _asignacion;
  IncidenteResponse? _incidente;
  bool _isLoading = true;
  String? _errorMessage;

  void _log(String message) {
    debugPrint('[TEC DASH] $message');
  }

  @override
  void initState() {
    super.initState();
    _log('initState -> dashboard tecnico inicializado');
    _loadAsignacion();
  }

  Future<void> _loadAsignacion() async {
    _log('_loadAsignacion -> INICIO');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _log('_loadAsignacion -> solicitando asignacion actual');
      final asig = await _tecnicoService.getAsignacionActual();
      if (asig == null) {
        _log('_loadAsignacion -> sin asignacion activa (null)');
        setState(() {
          _asignacion = null;
          _incidente = null;
          _isLoading = false;
        });
        return;
      }

      _log(
        '_loadAsignacion -> asignacion recibida '
        'idAsignacion=${asig.idAsignacion}, idIncidente=${asig.idIncidente}, '
        'estado=${asig.estadoAsignacion}',
      );

      final incidente = asig.incidente;
      _log(
        '_loadAsignacion -> incidente embebido '
        'idIncidente=${incidente.idIncidente}, categoria=${incidente.categoria}, '
        'prioridad=${incidente.prioridad}',
      );

      setState(() {
        _asignacion = asig;
        _incidente = incidente;
        _isLoading = false;
      });

      _log('_loadAsignacion -> FIN OK');
    } catch (e, st) {
      _log('_loadAsignacion -> ERROR: $e');
      _log('_loadAsignacion -> STACK: $st');
      setState(() {
        _errorMessage = _mapError(e);
        _isLoading = false;
      });
    }
  }

  String _mapError(dynamic error) {
    final text = error.toString();
    _log('_mapError -> raw=$text');
    if (text.contains('404')) {
      return 'No hay asignacion actual. Espera a que un taller te asigne.';
    }
    if (text.contains('401')) {
      return 'Sesion expirada. Vuelve a iniciar sesion.';
    }
    if (text.contains('409')) {
      return 'Ya tienes otra asignacion activa. Completala primero.';
    }
    if (text.contains('Connection') || text.contains('SocketException')) {
      return 'Error de conexion. Verifica tu internet.';
    }
    return 'Error: $error';
  }

  Future<void> _handleIniciarViaje() async {
    if (_asignacion == null) return;
    _log('_handleIniciarViaje -> INICIO idAsignacion=${_asignacion!.idAsignacion} estado=${_asignacion!.estadoAsignacion}');

    try {
      final updated = await _tecnicoService.iniciarViaje(_asignacion!.idAsignacion);
      _log('_handleIniciarViaje -> OK nuevoEstado=${updated.estadoAsignacion}');
      setState(() => _asignacion = updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viaje iniciado. Dirigete al cliente.')),
      );
    } catch (e, st) {
      _log('_handleIniciarViaje -> ERROR: $e');
      _log('_handleIniciarViaje -> STACK: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mapError(e))),
      );
    }
  }

  Future<void> _handleCompletar() async {
    if (_asignacion == null) return;
    _log('_handleCompletar -> abrir dialogo idAsignacion=${_asignacion!.idAsignacion} estado=${_asignacion!.estadoAsignacion}');

    final resumenController = TextEditingController();
    final costoController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Completar Servicio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Costo estimado (opcional)'),
              const SizedBox(height: 8),
              TextField(
                controller: costoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Ej: 85000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Resumen del trabajo (opcional)'),
              const SizedBox(height: 8),
              TextField(
                controller: resumenController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe el trabajo realizado',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final costo = double.tryParse(costoController.text.trim());
                  final resumen = resumenController.text.trim().isEmpty
                      ? null
                      : resumenController.text.trim();

                  _log('_handleCompletar -> enviando completar costo=$costo resumenLen=${resumen?.length ?? 0}');

                  final updated = await _tecnicoService.completar(
                    _asignacion!.idAsignacion,
                    costoEstimado: costo,
                    resumenTrabajo: resumen,
                  );
                  _log('_handleCompletar -> OK nuevoEstado=${updated.estadoAsignacion}');
                  setState(() => _asignacion = updated);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Servicio completado.')),
                  );
                } catch (e, st) {
                  _log('_handleCompletar -> ERROR: $e');
                  _log('_handleCompletar -> STACK: $st');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_mapError(e))),
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    _log('_logout -> limpiando sesiones tecnico/general');
    await _tecnicoAuthService.logout();
    await _authService.logout();
    _log('_logout -> completado, navegando a /login');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Color _getColorForEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.grey;
      case 'aceptada':
        return Colors.green;
      case 'en_camino':
        return Colors.blue;
      case 'completada':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Icons.schedule;
      case 'aceptada':
        return Icons.check_circle;
      case 'en_camino':
        return Icons.directions_car;
      case 'completada':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  Widget _buildActionButtons() {
    if (_asignacion == null) return const SizedBox.shrink();

    switch (_asignacion!.estadoAsignacion) {
      case 'pendiente':
        return Card(
          color: Colors.grey[200],
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Esperando que el taller acepte la asignacion...',
              textAlign: TextAlign.center,
            ),
          ),
        );

      case 'aceptada':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleIniciarViaje,
            icon: const Icon(Icons.directions_car),
            label: const Text('Iniciar Viaje'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        );

      case 'en_camino':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleCompletar,
            icon: const Icon(Icons.check_circle),
            label: const Text('Completar Servicio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );

      case 'completada':
        return Card(
          color: Colors.green[50],
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Servicio completado. El cliente puede evaluar tu trabajo.',
              textAlign: TextAlign.center,
            ),
          ),
        );

      default:
        return Text('Estado desconocido: ${_asignacion!.estadoAsignacion}');
    }
  }

  @override
  Widget build(BuildContext context) {
    _log(
      'build -> isLoading=$_isLoading, error=${_errorMessage != null}, '
      'hasAsignacion=${_asignacion != null}, '
      'estado=${_asignacion?.estadoAsignacion ?? 'null'}',
    );

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Asignacion')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi Asignacion')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _loadAsignacion,
                      child: const Text('Reintentar'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar sesion'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_asignacion == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Asignacion'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAsignacion),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: const Center(
          child: Text('No hay asignacion pendiente en este momento.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Asignacion Actual'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAsignacion),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAsignacion,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: _getColorForEstado(_asignacion!.estadoAsignacion),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estado', style: TextStyle(color: Colors.white70)),
                          Text(
                            _asignacion!.estadoAsignacion.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _getIconForEstado(_asignacion!.estadoAsignacion),
                        size: 40,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_asignacion!.etaMinutos != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('ETA: ${_asignacion!.etaMinutos} minutos'),
                  ),
                ),
              const SizedBox(height: 16),
              Text('Detalle del Incidente', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('👤 Cliente', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(
                        _incidente?.usuario?['nombre'] ?? _asignacion!.incidente.usuario?['nombre'] ?? 'Nombre no disponible',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if ((_incidente?.usuario?['telefono'] ?? _asignacion!.incidente.usuario?['telefono']) != null)
                        Text('Tel: ${_incidente?.usuario?['telefono'] ?? _asignacion!.incidente.usuario?['telefono']}'),
                      
                      const Divider(),
                      
                      const Text('🚗 Vehículo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Row(
                        children: [
                          Text(
                            _incidente?.vehiculo?['placa'] ?? _asignacion!.incidente.vehiculo?['placa'] ?? 'Placa N/A',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_incidente?.vehiculo?['marca'] ?? _asignacion!.incidente.vehiculo?['marca'] ?? ''} ${_incidente?.vehiculo?['modelo'] ?? _asignacion!.incidente.vehiculo?['modelo'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if ((_incidente?.vehiculo?['color'] ?? _asignacion!.incidente.vehiculo?['color']) != null)
                        Text('Color: ${_incidente?.vehiculo?['color'] ?? _asignacion!.incidente.vehiculo?['color']}'),
                        
                      const Divider(),
                      const Text('⚠️ Problema', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('Categoria: ${_incidente?.categoria ?? _asignacion!.incidente.categoria}'),
                      Text('Prioridad: ${_incidente?.prioridad ?? _asignacion!.incidente.prioridad}'),
                      const SizedBox(height: 4),
                      const Text('Descripcion:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_incidente?.descripcionUsuario ?? _asignacion!.incidente.descripcionUsuario),
                      if ((_incidente?.resumenIa ?? _asignacion!.incidente.resumenIa) != null) ...[
                        const SizedBox(height: 8),
                        const Text('Analisis IA:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text((_incidente?.resumenIa ?? _asignacion!.incidente.resumenIa)!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
