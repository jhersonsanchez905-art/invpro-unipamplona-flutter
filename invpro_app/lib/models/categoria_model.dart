class CategoriaModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String colorHex;
  final String prefijoSku;
  final bool isActive;
  final int productosCount;
  final DateTime? createdAt;

  const CategoriaModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.colorHex,
    required this.prefijoSku,
    required this.isActive,
    required this.productosCount,
    this.createdAt,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) =>
      CategoriaModel(
        id: json['id'],
        nombre: json['nombre'],
        descripcion: json['descripcion'] ?? '',
        colorHex: json['color_hex'] ?? '#6B7280',
        prefijoSku: json['prefijo_sku'] ?? '',
        isActive: json['is_active'] ?? true,
        productosCount: json['productos_count'] ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
      );
}
