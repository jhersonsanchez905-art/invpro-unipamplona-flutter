import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../models/movimiento_model.dart';
import '../../repositories/movimiento_repository.dart';
import 'movimiento_event.dart';
import 'movimiento_state.dart';

class MovimientoBloc extends Bloc<MovimientoEvent, MovimientoState> {
  final MovimientoRepository _repository;
  int _currentPage = 1;
  bool _hasMore = true;
  List<MovimientoModel> _movimientos = [];

  MovimientoBloc({required MovimientoRepository repository})
      : _repository = repository,
        super(MovimientoInitial()) {
    on<LoadMovimientos>(_onLoadMovimientos);
    on<LoadMoreMovimientos>(_onLoadMoreMovimientos);
    on<RegistrarMovimiento>(_onRegistrarMovimiento);
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['error'] != null) {
        return data['error']['message'] ?? 'Error desconocido';
      }
    }
    return 'Error de conexión. Verifica tu internet.';
  }

  Future<void> _onLoadMovimientos(
      LoadMovimientos event, Emitter<MovimientoState> emit) async {
    emit(MovimientoLoading());
    _currentPage = event.page;
    try {
      final result = await _repository.getMovimientos(
        page: _currentPage,
        tipo: event.tipo,
        productoId: event.productoId,
      );
      final List<dynamic> data =
          result['data']?['results'] ?? result['data'] ?? [];
      _movimientos = data
          .map((json) => MovimientoModel.fromJson(json))
          .toList();
      _hasMore = result['data']?['next'] != null;
      emit(MovimientosLoaded(
        movimientos: _movimientos,
        hasMore: _hasMore,
      ));
    } catch (e) {
      emit(MovimientoError(message: _extractError(e)));
    }
  }

  Future<void> _onLoadMoreMovimientos(
      LoadMoreMovimientos event, Emitter<MovimientoState> emit) async {
    if (!_hasMore) return;
    _currentPage++;
    try {
      final result =
          await _repository.getMovimientos(page: _currentPage);
      final List<dynamic> data =
          result['data']?['results'] ?? result['data'] ?? [];
      final newMovimientos = data
          .map((json) => MovimientoModel.fromJson(json))
          .toList();
      _movimientos.addAll(newMovimientos);
      _hasMore = result['data']?['next'] != null;
      emit(MovimientosLoaded(
        movimientos: _movimientos,
        hasMore: _hasMore,
      ));
    } catch (e) {
      emit(MovimientoError(message: _extractError(e)));
    }
  }

  Future<void> _onRegistrarMovimiento(
      RegistrarMovimiento event, Emitter<MovimientoState> emit) async {
    emit(MovimientoLoading());
    try {
      final result = await _repository.createMovimiento({
        'tipo': event.tipo,
        'producto_id': event.productoId,
        'cantidad': event.cantidad,
        'nota': event.nota,
      });
      emit(MovimientoRegistrado(
        movimiento: MovimientoModel.fromJson(result['data']),
      ));
    } catch (e) {
      emit(MovimientoError(message: _extractError(e)));
    }
  }
}
