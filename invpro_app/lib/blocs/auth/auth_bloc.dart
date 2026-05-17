import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<RegisterRequested>(_onRegisterRequested);
    on<VerifyEmailRequested>(_onVerifyEmailRequested);
    on<LoginRequested>(_onLoginRequested);
    on<VerifyLoginOTPRequested>(_onVerifyLoginOTPRequested);
    on<ResendOTPRequested>(_onResendOTPRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<PasswordResetConfirmed>(_onPasswordResetConfirmed);
    on<LogoutRequested>(_onLogoutRequested);
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

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event, Emitter<AuthState> emit) async {
    final loggedIn = await _repository.isLoggedIn();
    if (loggedIn) {
      final user = await _repository.getMe();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _repository.register(
        username: event.username,
        email: event.email,
        password: event.password,
        passwordConfirm: event.passwordConfirm,
        firstName: event.firstName,
        lastName: event.lastName,
      );
      if (result['success'] == true) {
        emit(AuthRegistered(userId: result['data']['user_id']));
      } else {
        emit(AuthError(message: result['error']['message']));
      }
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> _onVerifyEmailRequested(
    VerifyEmailRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _repository.verifyEmail(
        userId: event.userId, code: event.code);
      if (result['success'] == true) {
        emit(AuthEmailVerified());
      } else {
        emit(AuthError(message: result['error']['message']));
      }
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _repository.login(
        email: event.email, password: event.password);
      if (result['success'] == true) {
        emit(AuthLoginOTPSent(userId: result['data']['user_id']));
      } else {
        emit(AuthError(message: result['error']['message']));
      }
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> _onVerifyLoginOTPRequested(
    VerifyLoginOTPRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _repository.verifyOtp(
        userId: event.userId, code: event.code);
      if (result['success'] == true) {
        final user = await _repository.getMe();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthError(message: 'No se pudo obtener la información del usuario.'));
        }
      } else {
        emit(AuthError(message: result['error']['message']));
      }
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> _onResendOTPRequested(
    ResendOTPRequested event, Emitter<AuthState> emit) async {
    try {
      await _repository.resendOtp(
        userId: event.userId, purpose: event.purpose);
      emit(AuthOTPResent());
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _repository.requestPasswordReset(email: event.email);
      emit(AuthPasswordResetOTPSent(email: event.email));
    } catch (e) {
      emit(AuthPasswordResetOTPSent(email: event.email));
    }
  }

  Future<void> _onPasswordResetConfirmed(
    PasswordResetConfirmed event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final result = await _repository.confirmPasswordReset(
        email: event.email,
        code: event.code,
        newPassword: event.newPassword,
        newPasswordConfirm: event.newPasswordConfirm,
      );
      if (result['success'] == true) {
        emit(AuthPasswordResetSuccess());
      } else {
        emit(AuthError(message: result['error']['message']));
      }
    } catch (e) {
      emit(AuthError(message: _extractError(e)));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(AuthUnauthenticated());
  }
}
