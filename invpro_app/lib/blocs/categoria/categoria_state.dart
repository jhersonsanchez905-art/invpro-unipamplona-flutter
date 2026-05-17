import 'package:equatable/equatable.dart';
import '../../models/categoria_model.dart';

abstract class CategoriaState extends Equatable {}

class CategoriaInitial extends CategoriaState {
  @override
  List<Object?> get props => [];
}

class CategoriaLoading extends CategoriaState {
  @override
  List<Object?> get props => [];
}

class CategoriasLoaded extends CategoriaState {
  final List<CategoriaModel> categorias;
  CategoriasLoaded({required this.categorias});
  @override
  List<Object?> get props => [categorias];
}

class CategoriaCreated extends CategoriaState {
  @override
  List<Object?> get props => [];
}

class CategoriaUpdated extends CategoriaState {
  @override
  List<Object?> get props => [];
}

class CategoriaDeleted extends CategoriaState {
  @override
  List<Object?> get props => [];
}

class CategoriaError extends CategoriaState {
  final String message;
  CategoriaError({required this.message});
  @override
  List<Object?> get props => [message];
}
