import 'package:flutter/material.dart';

import '../models/asignacion_response.dart';
import '../models/completar_servicio_form.dart';
import '../services/tecnico_asignaciones_service.dart';
import '../widgets/completar_servicio_dialog.dart';

class AsignacionDetalleScreen extends StatefulWidget {
  final int idAsignacion;

  const AsignacionDetalleScreen({
    super.key,
    required this.idAsignacion,
  });

  @override
  State<AsignacionDetalleScreen> createState() => _AsignacionDetalleScreenState();
}

class _AsignacionDetalleScreenState extends State<AsignacionDetalleScreen> {
  final TecnicoAsignacionesService _asignacionesService = TecnicoAsignacionesService();

  AsignacionResponse? _asignacion;
  bool _iniciandoViaje = false;

  void _abrirDialogoCompletar() {
    showDialog(
      context: context,
      builder: (context) => CompletarServicioDialog(
        onConfirm: _completarServicio,
      ),
    );
  }

  Future<void> _completarServicio(CompletarServicioForm form) async {
    try {
      final resultado = await _asignacionesService.completarServicio(
        widget.idAsignacion,
        costoEstimado: form.costoEstimado,
        resumenTrabajo: form.resumenTrabajo,
      );

      if (!mounted) return;

      setState(() {
        _asignacion = resultado;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servicio completado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al completar servicio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _iniciarViajeAhora() async {
    setState(() => _iniciandoViaje = true);

    try {
      final resultado = await _asignacionesService.iniciarViaje(widget.idAsignacion);

      if (!mounted) return;

      setState(() {
        _asignacion = resultado;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viaje iniciado. Estado: ${resultado.estadoAsignacion}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _iniciandoViaje = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidente = _asignacion?.incidente;
    final estadoAsignacion = _asignacion?.estadoAsignacion ?? 'aceptada';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Asignacion'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Incidente',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text('ID Asignacion: ${widget.idAsignacion}'),
                    Text('Categoria: ${incidente?.categoria ?? 'Pendiente de cargar'}'),
                    Text('Prioridad: ${incidente?.prioridad ?? 'No disponible'}'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Descripcion: ${incidente?.descripcionUsuario ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado de la Asignacion',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: estadoAsignacion == 'aceptada'
                            ? Colors.orange.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estadoAsignacion,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (estadoAsignacion == 'aceptada')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _iniciandoViaje ? null : _iniciarViajeAhora,
                  icon: _iniciandoViaje
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.navigation),
                  label: const Text('Iniciar Viaje'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (estadoAsignacion == 'en_camino')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _abrirDialogoCompletar,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Completar Servicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (estadoAsignacion == 'completada')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Servicio Completado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'El cliente ya puede evaluar el servicio',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
