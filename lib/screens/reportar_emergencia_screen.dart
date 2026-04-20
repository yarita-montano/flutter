import 'package:flutter/material.dart';
import '../services/incidente_service.dart';
import '../models/incidente.dart';
import 'subir_evidencia_screen.dart';

class ReportarEmergenciaScreen extends StatefulWidget {
  final List<Map<String, dynamic>> vehiculos;

  const ReportarEmergenciaScreen({super.key, this.vehiculos = const []});

  @override
  State<ReportarEmergenciaScreen> createState() =>
      _ReportarEmergenciaScreenState();
}

class _ReportarEmergenciaScreenState extends State<ReportarEmergenciaScreen> {
  final incidenteService = IncidenteService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _descripcionController;

  int? vehiculoSeleccionado;
  double? latitud;
  double? longitud;
  bool obteniendo = false;
  bool reportando = false;
  String? ubicacionTexto;
  String? errorGeneral;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  void _obtenerUbicacion() async {
    setState(() => obteniendo = true);

    final resultado = await incidenteService.obtenerUbicacionActual();

    if (!mounted) return;

    if (resultado != null) {
      setState(() {
        latitud = resultado['latitud'];
        longitud = resultado['longitud'];
        ubicacionTexto =
            '✅ ${resultado['latitud']?.toStringAsFixed(4)}, ${resultado['longitud']?.toStringAsFixed(4)}';
        errorGeneral = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ubicación obtenida'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      setState(() {
        ubicacionTexto = '❌ No se pudo obtener ubicación';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Verifica que GPS esté habilitado'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => obteniendo = false);
  }

  void _reportarEmergencia() async {
    if (!_formKey.currentState!.validate()) return;

    if (vehiculoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Selecciona un vehículo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (latitud == null || longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Obtén tu ubicación'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      reportando = true;
      errorGeneral = null;
    });

    final resultado = await incidenteService.crearIncidencia(
      idVehiculo: vehiculoSeleccionado!,
      descripcionUsuario: _descripcionController.text.trim(),
      latitud: latitud!,
      longitud: longitud!,
    );

    if (!mounted) return;

    if (resultado['success']) {
      final incidente = resultado['incidente'] as IncidenteResponse;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.green.shade50,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('¡Emergencia Reportada!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Incidencia #${incidente.idIncidente}'),
              const SizedBox(height: 8),
              const Text('Técnicos en camino...'),
              const SizedBox(height: 8),
              Text(
                'Estado: ${incidente.getEstadoNombre()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ubicación:\n${incidente.getUbicacion()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, incidente);
              },
              child: const Text('Cerrar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubirEvidenciaScreen(
                      idIncidente: incidente.idIncidente,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Agregar evidencias'),
            ),
          ],
        ),
      );
    } else {
      if (resultado['code'] == 'AUTH_EXPIRED') {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() => errorGeneral = resultado['error']);
      }
    }

    setState(() => reportando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Reportar Emergencia'),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Este es un reporte de emergencia. Técnicos serán asignados automáticamente.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (errorGeneral != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorGeneral!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Text(
                '🚗 Mi Vehículo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: vehiculoSeleccionado,
                decoration: const InputDecoration(
                  hintText: 'Selecciona el vehículo afectado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                items: widget.vehiculos.isEmpty
                    ? const [
                        DropdownMenuItem(
                          enabled: false,
                          child: Text('No tienes vehículos registrados'),
                        ),
                      ]
                    : widget.vehiculos.map<DropdownMenuItem<int>>((v) {
                        return DropdownMenuItem<int>(
                          value: v['id_vehiculo'],
                          child: Text(
                            '${v['marca']} ${v['modelo']} (${v['placa']})',
                          ),
                        );
                      }).toList(),
                onChanged: widget.vehiculos.isEmpty
                    ? null
                    : (v) {
                        setState(() => vehiculoSeleccionado = v);
                      },
                validator: (v) {
                  if (v == null) return 'Selecciona un vehículo';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                '❓ ¿Qué pasó?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Describe el problema con tu vehículo\nEj: Motor hace ruido, no arranca, llanta pinchada, etc.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Ingresa una descripción';
                  if (v!.length < 10) return 'Mínimo 10 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                '📍 Mi Ubicación GPS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: latitud != null
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
                  border: Border.all(
                    color: latitud != null ? Colors.green : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ubicacionTexto != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          ubicacionTexto!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: latitud != null ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: obteniendo || reportando
                            ? null
                            : _obtenerUbicacion,
                        icon: obteniendo
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.location_on),
                        label: Text(
                          obteniendo
                              ? 'Obteniendo...'
                              : 'Obtener Mi Ubicación',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: reportando ? null : _reportarEmergencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.shade300,
                  ),
                  icon: reportando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.emergency,
                          size: 28, color: Colors.white),
                  label: Text(
                    reportando
                        ? '⏳ Reportando...'
                        : '🚨 ¡AUXILIO! REPORTAR AHORA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: reportando ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Consejos:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Describe el problema de forma clara'),
                    Text('• Asegúrate que tu GPS esté activado'),
                    Text('• Un técnico será asignado automáticamente'),
                    Text('• Puedes ver el estado en tu historial'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
