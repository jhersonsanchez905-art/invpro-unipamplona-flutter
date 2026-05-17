import 'package:equatable/equatable.dart';

abstract class CategoriaEvent extends Equatable {
  const CategoriaEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategorias extends CategoriaEvent {}

class CreateCategoria extends CategoriaEvent {
  final Map<String, dynamic> data;
  const CreateCategoria({required this.data});
  @override
  List<Object?> get props => [data];
}

class UpdateCategoria extends CategoriaEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateCategoria({required this.id, required this.data});
  @override
  List<Object?> get props => [id, data];
}

class DeleteCategoria extends CategoriaEvent {
  final String id;
  const DeleteCategoria({required this.id});
  @override
  List<Object?> get props => [id];
}
