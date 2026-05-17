import 'package:equatable/equatable.dart';
import '../../models/producto_model.dart';

abstract class ProductoEvent extends Equatable {
  const ProductoEvent();
  @override
  List<Object?> get props => [];
}

class LoadProductos extends ProductoEvent {
  final int page;
  final String? search;
  final String? categoriaId;
  final bool? tieneAlerta;
  const LoadProductos({
    this.page = 1,
    this.search,
    this.categoriaId,
    this.tieneAlerta,
  });
  @override
  List<Object?> get props =>
      [page, search, categoriaId, tieneAlerta];
}

class LoadMoreProductos extends ProductoEvent {}

class LoadProductoDetail extends ProductoEvent {
  final String id;
  const LoadProductoDetail({required this.id});
  @override
  List<Object?> get props => [id];
}

class CreateProducto extends ProductoEvent {
  final Map<String, dynamic> data;
  const CreateProducto({required this.data});
  @override
  List<Object?> get props => [data];
}

class UpdateProducto extends ProductoEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateProducto({required this.id, required this.data});
  @override
  List<Object?> get props => [id, data];
}

class DeleteProducto extends ProductoEvent {
  final String id;
  const DeleteProducto({required this.id});
  @override
  List<Object?> get props => [id];
}

class SearchProductos extends ProductoEvent {
  final String query;
  const SearchProductos({required this.query});
  @override
  List<Object?> get props => [query];
}
