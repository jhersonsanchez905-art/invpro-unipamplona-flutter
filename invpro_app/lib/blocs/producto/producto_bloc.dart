import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../models/producto_model.dart';
import '../../repositories/producto_repository.dart';
import 'producto_event.dart';
import 'producto_state.dart';

class ProductoBloc extends Bloc<ProductoEvent, ProductoState> {
  final ProductoRepository _repository;
  int _currentPage = 1;
  bool _hasMore = true;
  List<ProductoModel> _productos = [];

  ProductoBloc({required ProductoRepository repository})
      : _repository = repository,
        super(ProductoInitial()) {
    on<LoadProductos>(_onLoadProductos);
    on<LoadMoreProductos>(_onLoadMoreProductos);
    on<LoadProductoDetail>(_onLoadProductoDetail);
    on<CreateProducto>(_onCreateProducto);
    on<UpdateProducto>(_onUpdateProducto);
    on<DeleteProducto>(_onDeleteProducto);
    on<SearchProductos>(_onSearchProductos);
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

  Future<void> _onLoadProductos(
      LoadProductos event, Emitter<ProductoState> emit) async {
    emit(ProductoLoading());
    _currentPage = event.page;
    try {
      final result = await _repository.getProductos(
        page: _currentPage,
        search: event.search,
        categoriaId: event.categoriaId,
        tieneAlerta: event.tieneAlerta,
      );
      final List<dynamic> data = result['data']?['results'] ?? result['data'] ?? [];
      _productos = data
          .map((json) => ProductoModel.fromJson(json))
          .toList();
      _hasMore = result['data']?['next'] != null;
      emit(ProductosLoaded(
        productos: _productos,
        hasMore: _hasMore,
        page: _currentPage,
      ));
    } catch (e) {
      emit(ProductoError(message: _extractError(e)));
    }
  }

  Future<void> _onLoadMoreProductos(
      LoadMoreProductos event, Emitter<ProductoState> emit) async {
    if (!_hasMore) return;
    _currentPage++;
    try {
      final result =
          await _repository.getProductos(page: _currentPage);
      final List<dynamic> data = result['data']?['results'] ?? result['data'] ?? [];
      final newProductos = data
          .map((json) => ProductoModel.fromJson(json))
          .toList();
      _productos.addAll(newProductos);
      _hasMore = result['data']?['next'] != null;
      emit(ProductosLoaded(
        productos: _productos,
        hasMore: _hasMore,
        page: _currentPage,
      ));
    } catch (e) {
      emit(ProductoError(message: _extractError(e)));
    }
  }

  Future<void> _onLoadProductoDetail(
      LoadProductoDetail event, Emitter<ProductoState> emit) async {
    emit(ProductoLoading());
    try {
      final result = await _repository.getProducto(event.id);
      emit(ProductoDetailLoaded(
        producto: ProductoModel.fromJson(result['data']),
      ));
    } catch (e) {
      emit(ProductoError(message: _extractError(e)));
    }
  }

  Future<void> _onCreateProducto(
      CreateProducto event, Emitter<ProductoState> emit) async {
    emit(ProductoLoading());
    try {
      final result = await _repository.createProducto(event.data);
      emit(ProductoCreated(
        producto: ProductoModel.fromJson(result['data']),
      ));
    } catch (e) {
      emit(ProductoError(message: _extractError(e)));
    }
  }

  Future<void> _onUpdateProducto(
      UpdateProducto event, Emitter<ProductoState> emit) async {
    emit(ProductoLoading());
    try {
      await _repository.updateProducto(event.id, event.data);
      emit(ProductoUpdated());
    } catch (e) {
      emit(ProductoError(message: _extractError(e)));
    }
  }

  Future<void> _onDeleteProducto(
      DeleteProducto event, Emitter<ProductoState> emit) async {
    emit(ProductoLoading());
    try {
      await _repository.deleteProducto(event.id);
      emit(ProductoDeleted());
    } catch (e) {
      emit(ProductoError(message: _extractError(e)));
    }
  }

  Future<void> _onSearchProductos(
      SearchProductos event, Emitter<ProductoState> emit) async {
    emit(ProductoLoading());
    try {
      final result = await _repository.getProductos(
        search: event.query, page: 1);
      final List<dynamic> data = result['data']?['results'] ?? result['data'] ?? [];
      _productos = data
          .map((json) => ProductoModel.fromJson(json))
          .toList();
      _hasMore = result['data']?['next'] != null;
      _currentPage = 1;
      emit(ProductosLoaded(
        productos: _productos,
        hasMore: _hasMore,
        page: _currentPage,
      ));
    } catch (e) {
      emit(ProductoError(message: _extractError(e)));
    }
  }
}
