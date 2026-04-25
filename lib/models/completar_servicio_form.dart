class CompletarServicioForm {
  final double? costoEstimado;
  final String? resumenTrabajo;

  const CompletarServicioForm({
    this.costoEstimado,
    this.resumenTrabajo,
  });

  bool get isValid {
    return (costoEstimado != null && costoEstimado! > 0) ||
        (resumenTrabajo != null && resumenTrabajo!.trim().isNotEmpty);
  }
}
