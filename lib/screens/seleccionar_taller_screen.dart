import 'package:flutter/material.dart';
import '../models/incidente.dart';
import '../models/candidato_asignacion.dart';
import '../services/incidente_service.dart';

class SeleccionarTallerScreen extends StatefulWidget {
  final IncidenteDetalle incidente;

  const SeleccionarTallerScreen({
    super.key,
    required this.incidente,
  });

  @override
  State<SeleccionarTallerScreen> createState() =>
      _SeleccionarTallerScreenState();
}

class _SeleccionarTallerScreenState extends State<SeleccionarTallerScreen> {
  final incidenteService = IncidenteService();

  late int tallerSeleccionado;
  bool cambiando = false;

  @override
  void initState() {
    super.initState();
    // El primer candidato es el seleccionado por defecto
    final candidatos = widget.incidente.candidatos;
    tallerSeleccionado = (candidatos != null && candidatos.isNotEmpty)
        ? candidatos.first.idCandidato
        : 0;
  }

  Future<void> _cambiarTaller(int nuevoIdCandidato) async {
    setState(() => cambiando = true);

    final resultado = await incidenteService.cambiarTaller(
      idIncidente: widget.incidente.idIncidente,
      idCandidato: nuevoIdCandidato,
    );

    if (!mounted) return;

    if (resultado['success']) {
      setState(() {
        tallerSeleccionado = nuevoIdCandidato;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Taller cambiado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${resultado['error'] ?? 'Error al cambiar taller'}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => cambiando = false);
  }

  Future<void> _contactarTaller(TallerMini taller) async {
    final phone = taller.telefono;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teléfono no disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📱 ${taller.nombre}: $phone'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _confirmarYCerrar() {
    Navigator.of(context).pop(tallerSeleccionado);
  }

  @override
  Widget build(BuildContext context) {
    final candidatos = widget.incidente.candidatos ?? [];

    if (candidatos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('🏪 Seleccionar Taller'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apartment_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No hay talleres disponibles'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏪 Seleccionar Taller'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Se encontraron ${candidatos.length} taller(es) disponible(s) cercano(s) a tu ubicación',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Incidente #${widget.incidente.idIncidente}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Lista de talleres
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: candidatos.length,
              itemBuilder: (context, index) {
                final candidato = candidatos[index];
                final esSeleccionado =
                    tallerSeleccionado == candidato.idCandidato;
                final esPrimero = index == 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: esSeleccionado ? Colors.blue.shade50 : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: esSeleccionado
                          ? Colors.blue
                          : Colors.grey.shade200,
                      width: esSeleccionado ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado
                        Row(
                          children: [
                            // Posición
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: esPrimero
                                    ? Colors.green
                                    : Colors.grey.shade400,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info del taller
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          candidato.taller.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (esPrimero)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            '🏆 Recomendado',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (candidato.taller.direccion != null)
                                    Text(
                                      candidato.taller.direccion!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Detalles (distancia, score, teléfono)
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            if (candidato.distanciaKm != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${candidato.distanciaKm!.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            if (candidato.scoreTotal != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${candidato.scoreTotal!.toStringAsFixed(0)}% match',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (candidato.taller.telefono != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone,
                                      size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    candidato.taller.telefono!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Botones de acción
                        Row(
                          children: [
                            // Botón Contactar
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: cambiando
                                    ? null
                                    : () => _contactarTaller(
                                        candidato.taller),
                                icon: const Icon(Icons.phone, size: 18),
                                label: const Text('Contactar'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Botón Seleccionar
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: cambiando || esSeleccionado
                                    ? null
                                    : () =>
                                        _cambiarTaller(candidato.idCandidato),
                                icon: esSeleccionado
                                    ? const Icon(Icons.check, size: 18)
                                    : const Icon(Icons.done_outline, size: 18),
                                label: Text(
                                  esSeleccionado ? 'Seleccionado' : 'Seleccionar',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: esSeleccionado
                                      ? Colors.blue
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: cambiando ? null : _confirmarYCerrar,
        backgroundColor: Colors.green,
        label: const Text('Confirmar'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
