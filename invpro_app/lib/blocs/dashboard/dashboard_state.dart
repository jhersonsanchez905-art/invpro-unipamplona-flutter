import 'package:equatable/equatable.dart';

abstract class DashboardState extends Equatable {}

class DashboardInitial extends DashboardState {
  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {
  @override
  List<Object?> get props => [];
}

class DashboardLoaded extends DashboardState {
  final Map<String, dynamic> data;
  DashboardLoaded({required this.data});
  @override
  List<Object?> get props => [data];
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError({required this.message});
  @override
  List<Object?> get props => [message];
}
