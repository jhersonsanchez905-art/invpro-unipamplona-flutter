import 'package:equatable/equatable.dart';
import '../../models/movimiento_model.dart';

abstract class MovimientoState extends Equatable {}

class MovimientoInitial extends MovimientoState {
  @override
  List<Object?> get props => [];
}

class MovimientoLoading extends MovimientoState {
  @override
  List<Object?> get props => [];
}

class MovimientosLoaded extends MovimientoState {
  final List<MovimientoModel> movimientos;
  final bool hasMore;
  MovimientosLoaded({
    required this.movimientos,
    required this.hasMore,
  });
  @override
  List<Object?> get props => [movimientos, hasMore];
}

class MovimientoRegistrado extends MovimientoState {
  final MovimientoModel movimiento;
  MovimientoRegistrado({required this.movimiento});
  @override
  List<Object?> get props => [movimiento];
}

class MovimientoError extends MovimientoState {
  final String message;
  MovimientoError({required this.message});
  @override
  List<Object?> get props => [message];
}
