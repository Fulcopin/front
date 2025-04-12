class Product {
  final String id;
  final String id_user;
  final String nombre;
  final String descripcion;
  final double peso;
  final double precio;
  final int cantidad;
  final String? link;
  final String? imagenUrl;
  final String? facturaUrl;
  final DateTime fechaCreacion;
  final Map<String, dynamic>? usuario;
  final String estado;
  Product({
    required this.id,
    required this.id_user,
    required this.nombre,
    required this.descripcion,
    required this.peso,
    required this.precio,
    required this.cantidad,
    this.link = '',
    this.imagenUrl = '',
    this.facturaUrl = '',
    required this.fechaCreacion,
     this.usuario,
     this.estado = 'No llegado',
  });

  bool get hasImage => imagenUrl != null && imagenUrl!.isNotEmpty;
  bool get hasInvoice => facturaUrl != null && facturaUrl!.isNotEmpty;
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      id_user: json['id_user'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      peso: double.parse(json['peso'].toString()),
      precio: double.parse(json['precio'].toString()),
      cantidad: int.parse(json['cantidad'].toString()),
      link: json['link'],
      imagenUrl: json['imagen_url'],
      facturaUrl: json['factura_url'],
      fechaCreacion: DateTime.parse(json['fecha_creacion'] ?? DateTime.now().toIso8601String()),
    );
  }
  Product copyWith({
    String? id,
    String? id_user,
    String? nombre,
    String? descripcion,
    double? peso,
    double? precio,
    int? cantidad,
    String? link,
    String? imagenUrl,
    String? facturaUrl,
    DateTime? fechaCreacion,
  }) {
    return Product(
      id: id ?? this.id,
      id_user: id_user ?? this.id_user,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      peso: peso ?? this.peso,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      link: link ?? this.link,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      facturaUrl: facturaUrl ?? this.facturaUrl,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}