import 'package:flutter/material.dart';
import '../services/incidente_service.dart';
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

  void _irASubirEvidencia() {
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

    // Solo navegar a SubirEvidenciaScreen en modo NUEVO REPORTE
    // La creación del incidente ocurre allá al presionar "REPORTAR INCIDENTE"
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubirEvidenciaScreen(
          idVehiculo: vehiculoSeleccionado!,
          descripcionUsuario: _descripcionController.text.trim(),
          latitud: latitud!,
          longitud: longitud!,
        ),
      ),
    );
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
                  onPressed: obteniendo ? null : _obtenerUbicacion,
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
                  onPressed: _irASubirEvidencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.shade300,
                  ),
                  icon: const Icon(Icons.upload_file,
                      size: 28, color: Colors.white),
                  label: const Text(
                    '📎 SUBIR EVIDENCIA',
                    style: TextStyle(
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
                  onPressed: () => Navigator.pop(context),
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
