class Product {
  final int id;
  final String nombre;
  final String descripcion;
  final String precio;
  final String imagen;
  final int cantidad;
  final String valoracionTotal;
  final String categoria;
  int cantidadCarrito;

  Product({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagen,
    required this.cantidad,
    required this.valoracionTotal,
    required this.categoria,
    this.cantidadCarrito = 1,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final nombre = _asString(json['nombre']);
    final descripcion = _asString(json['descripcion']);
    final precio = _asString(json['precio']);
    final imagen = _asString(json['imagen']);
    final cantidad = _asInt(json['cantidad']);
    final valoracionTotal = _asString(json['valoracion_total']);
    final categoria = _asString(json['categoria']);

    if (id == null ||
        nombre == null ||
        descripcion == null ||
        precio == null ||
        imagen == null ||
        cantidad == null ||
        valoracionTotal == null ||
        categoria == null) {
      throw const FormatException('Fallo al cargar producto');
    }

    return Product(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      precio: precio,
      imagen: imagen,
      cantidad: cantidad,
      valoracionTotal: valoracionTotal,
      categoria: categoria,
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
