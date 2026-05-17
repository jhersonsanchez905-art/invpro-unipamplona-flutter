import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository _repository;

  DashboardBloc({required DashboardRepository repository})
      : _repository = repository,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
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

  Future<void> _onLoadDashboard(
      LoadDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final result = await _repository.getDashboard();
      emit(DashboardLoaded(data: result['data'] ?? {}));
    } catch (e) {
      emit(DashboardError(message: _extractError(e)));
    }
  }

  Future<void> _onRefreshDashboard(
      RefreshDashboard event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    try {
      final result = await _repository.getDashboard();
      emit(DashboardLoaded(data: result['data'] ?? {}));
    } catch (e) {
      emit(DashboardError(message: _extractError(e)));
    }
  }
}
