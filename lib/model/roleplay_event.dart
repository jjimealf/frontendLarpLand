class RoleplayEvent {
  final int id;
  final String name;
  final String description;
  final String fechaInicio;
  final String fechaFin;
  bool isRegistered;

  RoleplayEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.fechaInicio,
    required this.fechaFin,
    this.isRegistered = false,
  });

  factory RoleplayEvent.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final name = _asString(json['nombre'] ?? json['name']);
    final description = _asString(json['descripcion'] ?? json['description']);
    final fechaInicio = _asString(json['fecha_inicio'] ?? json['fechaInicio']);
    final fechaFin = _asString(json['fecha_fin'] ?? json['fechaFin']);

    if (id == null ||
        name == null ||
        description == null ||
        fechaInicio == null ||
        fechaFin == null) {
      throw const FormatException('Fallo al cargar evento');
    }

    return RoleplayEvent(
      id: id,
      name: name,
      description: description,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }
}

int? _asInt(dynamic value) {
  return switch (value) {
    int v => v,
    num v => v.toInt(),
    String v => int.tryParse(v),
    _ => null,
  };
}

String? _asString(dynamic value) {
  return switch (value) {
    String v => v,
    num v => v.toString(),
    bool v => v.toString(),
    _ => null,
  };
}
