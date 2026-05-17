import 'package:equatable/equatable.dart';

abstract class MovimientoEvent extends Equatable {
  const MovimientoEvent();
  @override
  List<Object?> get props => [];
}

class LoadMovimientos extends MovimientoEvent {
  final int page;
  final String? tipo;
  final String? productoId;
  const LoadMovimientos({
    this.page = 1,
    this.tipo,
    this.productoId,
  });
  @override
  List<Object?> get props => [page, tipo, productoId];
}

class LoadMoreMovimientos extends MovimientoEvent {}

class RegistrarMovimiento extends MovimientoEvent {
  final String tipo;
  final String productoId;
  final double cantidad;
  final String nota;
  const RegistrarMovimiento({
    required this.tipo,
    required this.productoId,
    required this.cantidad,
    required this.nota,
  });
  @override
  List<Object?> get props => [tipo, productoId, cantidad, nota];
}
