import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthRegistered extends AuthState {
  final String userId;
  const AuthRegistered({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class AuthEmailVerified extends AuthState {}

class AuthLoginOTPSent extends AuthState {
  final String userId;
  const AuthLoginOTPSent({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthPasswordResetOTPSent extends AuthState {
  final String email;
  const AuthPasswordResetOTPSent({required this.email});
  @override
  List<Object?> get props => [email];
}

class AuthPasswordResetSuccess extends AuthState {}
class AuthOTPResent extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}
