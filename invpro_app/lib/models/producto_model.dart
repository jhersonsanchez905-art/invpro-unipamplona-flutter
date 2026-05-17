class ProductoModel {
  final String id;
  final String nombre;
  final String sku;
  final String descripcion;
  final String categoriaId;
  final double stockActual;
  final double stockMinimo;
  final double precioUnitario;
  final bool tieneAlerta;
  final bool isActive;
  final DateTime? createdAt;

  const ProductoModel({
    required this.id,
    required this.nombre,
    required this.sku,
    required this.descripcion,
    required this.categoriaId,
    required this.stockActual,
    required this.stockMinimo,
    required this.precioUnitario,
    required this.tieneAlerta,
    required this.isActive,
    this.createdAt,
  });

  factory ProductoModel.fromJson(Map<String, dynamic> json) => ProductoModel(
    id: json['id'],
    nombre: json['nombre'],
    sku: json['sku'] ?? '',
    descripcion: json['descripcion'] ?? '',
    categoriaId: json['categoria_id'] ?? '',
    stockActual: double.tryParse(json['stock_actual'].toString()) ?? 0,
    stockMinimo: double.tryParse(json['stock_minimo'].toString()) ?? 0,
    precioUnitario:
        double.tryParse(json['precio_unitario'].toString()) ?? 0,
    tieneAlerta: json['tiene_alerta'] ?? false,
    isActive: json['is_active'] ?? true,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : null,
  );
}
