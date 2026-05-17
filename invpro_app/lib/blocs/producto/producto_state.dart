import 'package:equatable/equatable.dart';
import '../../models/producto_model.dart';

abstract class ProductoState extends Equatable {}

class ProductoInitial extends ProductoState {
  @override
  List<Object?> get props => [];
}

class ProductoLoading extends ProductoState {
  @override
  List<Object?> get props => [];
}

class ProductosLoaded extends ProductoState {
  final List<ProductoModel> productos;
  final bool hasMore;
  final int page;
  ProductosLoaded({
    required this.productos,
    required this.hasMore,
    required this.page,
  });
  @override
  List<Object?> get props => [productos, hasMore, page];
}

class ProductoDetailLoaded extends ProductoState {
  final ProductoModel producto;
  ProductoDetailLoaded({required this.producto});
  @override
  List<Object?> get props => [producto];
}

class ProductoCreated extends ProductoState {
  final ProductoModel producto;
  ProductoCreated({required this.producto});
  @override
  List<Object?> get props => [producto];
}

class ProductoUpdated extends ProductoState {
  @override
  List<Object?> get props => [];
}

class ProductoDeleted extends ProductoState {
  @override
  List<Object?> get props => [];
}

class ProductoError extends ProductoState {
  final String message;
  ProductoError({required this.message});
  @override
  List<Object?> get props => [message];
}
