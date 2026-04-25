import 'package:intl/intl.dart';
import 'candidato_asignacion.dart';

/// Respuesta del servidor al crear incidencia
class IncidenteResponse {
  final int idIncidente;
  final int idUsuario;
  final int idVehiculo;
  final int? idCategoria;
  final int? idPrioridad;
  final int idEstado;
  final String? descripcionUsuario;
  final double latitud;
  final double longitud;
  final DateTime createdAt;

  IncidenteResponse({
    required this.idIncidente,
    required this.idUsuario,
    required this.idVehiculo,
    this.idCategoria,
    this.idPrioridad,
    required this.idEstado,
    this.descripcionUsuario,
    required this.latitud,
    required this.longitud,
    required this.createdAt,
  });

  factory IncidenteResponse.fromJson(Map<String, dynamic> json) {
    return IncidenteResponse(
      idIncidente: json['id_incidente'] ?? 0,
      idUsuario: json['id_usuario'] ?? 0,
      idVehiculo: json['id_vehiculo'] ?? 0,
      idCategoria: json['id_categoria'],
      idPrioridad: json['id_prioridad'],
      idEstado: json['id_estado'] ?? 1,
      descripcionUsuario: json['descripcion_usuario'],
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String getEstadoNombre() {
    const estados = {
      1: '⏳ Pendiente',
      2: '⚙️ En Proceso',
      3: '✅ Atendido',
      4: '❌ Cancelado',
    };
    return estados[idEstado] ?? 'Desconocido';
  }

  String getUbicacion() =>
      '${latitud.toStringAsFixed(4)}, ${longitud.toStringAsFixed(4)}';

  String getFechaFormato() {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }
}

/// Incidencia con datos completos (desde listado)
class IncidenteDetalle {
  final int idIncidente;
  final int idUsuario;
  final int idVehiculo;
  final int idEstado;
  final int? idCategoria;
  final int? idPrioridad;
  final String? descripcionUsuario;
  final double latitud;
  final double longitud;
  final String? resumenIa;
  final double? clasificacionIaConfianza;
  final bool requiereRevisionManual;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? vehiculo;
  final Map<String, dynamic>? estado;
  final Map<String, dynamic>? categoria;
  final Map<String, dynamic>? prioridad;
  final List<CandidatoAsignacion>? candidatos;
  final List<Asignacion>? asignaciones;

  IncidenteDetalle({
    required this.idIncidente,
    required this.idUsuario,
    required this.idVehiculo,
    required this.idEstado,
    this.idCategoria,
    this.idPrioridad,
    this.descripcionUsuario,
    required this.latitud,
    required this.longitud,
    this.resumenIa,
    this.clasificacionIaConfianza,
    this.requiereRevisionManual = false,
    required this.createdAt,
    required this.updatedAt,
    this.vehiculo,
    this.estado,
    this.categoria,
    this.prioridad,
    this.candidatos,
    this.asignaciones,
  });

  factory IncidenteDetalle.fromJson(Map<String, dynamic> json) {
    return IncidenteDetalle(
      idIncidente: json['id_incidente'] ?? 0,
      idUsuario: json['id_usuario'] ?? 0,
      idVehiculo: json['id_vehiculo'] ?? 0,
      idEstado: json['estado']?['id_estado'] ?? json['id_estado'] ?? 1,
      idCategoria: json['id_categoria'],
      idPrioridad: json['id_prioridad'],
      descripcionUsuario: json['descripcion_usuario'],
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      resumenIa: json['resumen_ia'],
      clasificacionIaConfianza:
          (json['clasificacion_ia_confianza'] as num?)?.toDouble(),
      requiereRevisionManual: json['requiere_revision_manual'] ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
        (json['updated_at'] ?? json['created_at']) as String,
      ),
      vehiculo: json['vehiculo'],
      estado: json['estado'],
      categoria: json['categoria'],
      prioridad: json['prioridad'],
      candidatos: (json['candidatos'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((c) => CandidatoAsignacion.fromJson(c))
          .toList(),
      asignaciones: (json['asignaciones'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((a) => Asignacion.fromJson(a))
          .toList(),
    );
  }

  String getEstadoNombre() {
    const estados = {
      1: '⏳ Pendiente',
      2: '⚙️ En Proceso',
      3: '✅ Atendido',
      4: '❌ Cancelado',
    };
    return estados[idEstado] ?? 'Desconocido';
  }

  String getPlaca() => vehiculo?['placa'] ?? 'N/A';
  String getMarca() => vehiculo?['marca'] ?? 'N/A';
  String getCategoriaNombre() => categoria?['nombre'] ?? '🤖 Por asignar';
  String getUbicacion() =>
      '${latitud.toStringAsFixed(4)}, ${longitud.toStringAsFixed(4)}';

  String getFechaFormato() {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  String getNivelPrioridad() {
    final nivel = prioridad?['nivel']?.toString().toUpperCase() ?? 'N/A';
    if (nivel == 'CRITICA') return '🔴 CRÍTICA';
    if (nivel == 'ALTA') return '🟠 ALTA';
    if (nivel == 'MEDIA') return '🟡 MEDIA';
    if (nivel == 'BAJA') return '🟢 BAJA';
    return '🤖 $nivel';
  }
}
