import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../services/incidente_service.dart';
import '../models/evidencia.dart';

class SubirEvidenciaScreen extends StatefulWidget {
  final int idIncidente;

  const SubirEvidenciaScreen({super.key, required this.idIncidente});

  @override
  State<SubirEvidenciaScreen> createState() => _SubirEvidenciaScreenState();
}

class _SubirEvidenciaScreenState extends State<SubirEvidenciaScreen> {
  final incidenteService = IncidenteService();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  List<Evidencia> evidencias = [];
  bool cargando = true;
  bool subiendo = false;
  bool grabando = false;

  @override
  void initState() {
    super.initState();
    _cargarEvidencias();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _cargarEvidencias() async {
    final resultado =
        await incidenteService.listarEvidencias(widget.idIncidente);
    if (!mounted) return;
    if (resultado['success']) {
      setState(() {
        evidencias = resultado['evidencias'] as List<Evidencia>;
        cargando = false;
      });
    } else {
      setState(() => cargando = false);
    }
  }

  Future<void> _tomarFoto() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (foto == null) return;
    await _subir(File(foto.path), 1);
  }

  Future<void> _elegirGaleria() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (foto == null) return;
    await _subir(File(foto.path), 1);
  }

  Future<void> _toggleGrabacion() async {
    if (grabando) {
      final path = await _recorder.stop();
      setState(() => grabando = false);
      if (path != null) {
        await _subir(File(path), 2);
      }
    } else {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/evidencia_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(), path: path);
        setState(() => grabando = true);
      } else {
        _mostrarError('Permiso de micrófono denegado');
      }
    }
  }

  Future<void> _subir(File archivo, int tipo) async {
    setState(() => subiendo = true);

    final resultado = await incidenteService.subirEvidencia(
      idIncidente: widget.idIncidente,
      idTipoEvidencia: tipo,
      archivo: archivo,
    );

    if (!mounted) return;
    setState(() => subiendo = false);

    if (resultado['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Evidencia subida'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarEvidencias();
    } else {
      _mostrarError(resultado['error'] ?? 'Error al subir');
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ $msg'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('📎 Evidencias #${widget.idIncidente}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: subiendo ? null : _tomarFoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cámara'),
                ),
                ElevatedButton.icon(
                  onPressed: subiendo ? null : _elegirGaleria,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galería'),
                ),
                ElevatedButton.icon(
                  onPressed: subiendo ? null : _toggleGrabacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: grabando ? Colors.red : null,
                    foregroundColor: grabando ? Colors.white : null,
                  ),
                  icon: Icon(grabando ? Icons.stop : Icons.mic),
                  label: Text(grabando ? 'Detener' : 'Grabar audio'),
                ),
              ],
            ),
          ),
          if (subiendo)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Subiendo a Cloudinary...'),
                ],
              ),
            ),
          const Divider(),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : evidencias.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('No hay evidencias aún'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: evidencias.length,
                        itemBuilder: (ctx, i) {
                          final e = evidencias[i];
                          return Card(
                            child: ListTile(
                              leading: e.esImagen
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        e.urlArchivo,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : Icon(
                                      e.esAudio
                                          ? Icons.audiotrack
                                          : Icons.description,
                                      size: 40,
                                      color: Colors.red,
                                    ),
                              title: Text(e.getTipoNombre()),
                              subtitle: Text(
                                e.descripcionIa ?? 'Pendiente de análisis IA',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: e.esAudio
                                  ? IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed: () => _player
                                          .play(UrlSource(e.urlArchivo)),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
