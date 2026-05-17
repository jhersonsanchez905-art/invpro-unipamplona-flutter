import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String passwordConfirm;
  final String firstName;
  final String lastName;
  const RegisterRequested({
    required this.username,
    required this.email,
    required this.password,
    required this.passwordConfirm,
    this.firstName = '',
    this.lastName = '',
  });
  @override
  List<Object?> get props =>
      [username, email, password, passwordConfirm, firstName, lastName];
}

class VerifyEmailRequested extends AuthEvent {
  final String userId;
  final String code;
  const VerifyEmailRequested({required this.userId, required this.code});
  @override
  List<Object?> get props => [userId, code];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class VerifyLoginOTPRequested extends AuthEvent {
  final String userId;
  final String code;
  const VerifyLoginOTPRequested({required this.userId, required this.code});
  @override
  List<Object?> get props => [userId, code];
}

class ResendOTPRequested extends AuthEvent {
  final String userId;
  final String purpose;
  const ResendOTPRequested({required this.userId, required this.purpose});
  @override
  List<Object?> get props => [userId, purpose];
}

class PasswordResetRequested extends AuthEvent {
  final String email;
  const PasswordResetRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

class PasswordResetConfirmed extends AuthEvent {
  final String email;
  final String code;
  final String newPassword;
  final String newPasswordConfirm;
  const PasswordResetConfirmed({
    required this.email,
    required this.code,
    required this.newPassword,
    required this.newPasswordConfirm,
  });
  @override
  List<Object?> get props => [email, code, newPassword, newPasswordConfirm];
}

class LogoutRequested extends AuthEvent {}
