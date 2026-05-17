class MovimientoModel {
  final String id;
  final String tipo;
  final String productoSku;
  final String productoNombre;
  final double cantidad;
  final String nota;
  final String usuarioUsername;
  final DateTime createdAt;

  const MovimientoModel({
    required this.id,
    required this.tipo,
    required this.productoSku,
    required this.productoNombre,
    required this.cantidad,
    required this.nota,
    required this.usuarioUsername,
    required this.createdAt,
  });

  factory MovimientoModel.fromJson(Map<String, dynamic> json) =>
      MovimientoModel(
        id: json['id'],
        tipo: json['tipo'],
        productoSku: json['producto']?['sku'] ?? '',
        productoNombre: json['producto']?['nombre'] ?? '',
        cantidad: double.tryParse(json['cantidad'].toString()) ?? 0,
        nota: json['nota'] ?? '',
        usuarioUsername: json['usuario']?['username'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
      );

  String get tipoLabel {
    switch (tipo) {
      case 'entrada': return 'Entrada';
      case 'salida': return 'Salida';
      case 'ajuste': return 'Ajuste';
      default: return tipo;
    }
  }
}
