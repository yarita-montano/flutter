import 'package:flutter/material.dart';
import '../services/incidente_service.dart';
import '../models/incidente.dart';

class HistorialEmergenciasScreen extends StatefulWidget {
  const HistorialEmergenciasScreen({super.key});

  @override
  State<HistorialEmergenciasScreen> createState() =>
      _HistorialEmergenciasScreenState();
}

class _HistorialEmergenciasScreenState
    extends State<HistorialEmergenciasScreen> {
  final incidenteService = IncidenteService();

  List<IncidenteDetalle> incidencias = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarIncidencias();
  }

  void _cargarIncidencias() async {
    final resultado = await incidenteService.listarMisIncidencias();

    if (!mounted) return;

    if (resultado['success']) {
      setState(() {
        incidencias = resultado['incidencias'] ?? [];
        error = null;
      });
    } else {
      setState(() => error = resultado['error']);
      if (resultado['code'] == 'AUTH_EXPIRED') {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }

    setState(() => cargando = false);
  }

  Color _getColorEstado(int idEstado) {
    switch (idEstado) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Mis Emergencias'),
        centerTitle: true,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            cargando = true;
                            error = null;
                          });
                          _cargarIncidencias();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : incidencias.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('No tienes emergencias reportadas'),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/reportar-emergencia',
                            ),
                            icon: const Icon(Icons.emergency),
                            label: const Text('Reportar Emergencia'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() => cargando = true);
                        _cargarIncidencias();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: incidencias.length,
                        itemBuilder: (context, index) {
                          final inc = incidencias[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorEstado(inc.idEstado),
                                child: const Icon(Icons.emergency,
                                    color: Colors.white),
                              ),
                              title: Text(
                                '#${inc.idIncidente} - ${inc.getMarca()} ${inc.getPlaca()}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    inc.getCategoriaNombre(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    '${inc.getEstadoNombre()} • ${inc.getNivelPrioridad()}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                  Text(
                                    inc.getFechaFormato(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                _showDetailDialog(context, inc);
                              },
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.pushNamed(
            context,
            '/reportar-emergencia',
          );
          if (resultado != null) {
            _cargarIncidencias();
          }
        },
        label: const Text('Nueva Emergencia'),
        icon: const Icon(Icons.emergency),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showDetailDialog(BuildContext context, IncidenteDetalle inc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('#${inc.idIncidente} - Detalles'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Estado:', inc.getEstadoNombre()),
              _detailRow('Vehículo:', '${inc.getMarca()} ${inc.getPlaca()}'),
              _detailRow('Categoría:', inc.getCategoriaNombre()),
              _detailRow('Prioridad:', inc.getNivelPrioridad()),
              _detailRow('Ubicación:', inc.getUbicacion()),
              _detailRow('Fecha:', inc.getFechaFormato()),
              if (inc.descripcionUsuario != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Descripción:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(inc.descripcionUsuario!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold),
              softWrap: true),
          const SizedBox(width: 12),
          Expanded(child: Text(value, softWrap: true)),
        ],
      ),
    );
  }
}
