import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../models/categoria_model.dart';
import '../../repositories/categoria_repository.dart';
import 'categoria_event.dart';
import 'categoria_state.dart';

class CategoriaBloc extends Bloc<CategoriaEvent, CategoriaState> {
  final CategoriaRepository _repository;

  CategoriaBloc({required CategoriaRepository repository})
      : _repository = repository,
        super(CategoriaInitial()) {
    on<LoadCategorias>(_onLoadCategorias);
    on<CreateCategoria>(_onCreateCategoria);
    on<UpdateCategoria>(_onUpdateCategoria);
    on<DeleteCategoria>(_onDeleteCategoria);
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

  Future<void> _onLoadCategorias(
      LoadCategorias event, Emitter<CategoriaState> emit) async {
    emit(CategoriaLoading());
    try {
      final result = await _repository.getCategorias();
      final List<dynamic> data = result['data']?['results'] ?? result['data'] ?? [];
      final categorias = data
          .map((json) => CategoriaModel.fromJson(json))
          .toList();
      emit(CategoriasLoaded(categorias: categorias));
    } catch (e) {
      emit(CategoriaError(message: _extractError(e)));
    }
  }

  Future<void> _onCreateCategoria(
      CreateCategoria event, Emitter<CategoriaState> emit) async {
    emit(CategoriaLoading());
    try {
      await _repository.createCategoria(event.data);
      emit(CategoriaCreated());
    } catch (e) {
      emit(CategoriaError(message: _extractError(e)));
    }
  }

  Future<void> _onUpdateCategoria(
      UpdateCategoria event, Emitter<CategoriaState> emit) async {
    emit(CategoriaLoading());
    try {
      await _repository.updateCategoria(event.id, event.data);
      emit(CategoriaUpdated());
    } catch (e) {
      emit(CategoriaError(message: _extractError(e)));
    }
  }

  Future<void> _onDeleteCategoria(
      DeleteCategoria event, Emitter<CategoriaState> emit) async {
    emit(CategoriaLoading());
    try {
      await _repository.deleteCategoria(event.id);
      emit(CategoriaDeleted());
    } catch (e) {
      emit(CategoriaError(message: _extractError(e)));
    }
  }
}
