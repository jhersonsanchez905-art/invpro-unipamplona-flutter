import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    final userId = (extra is Map<String, dynamic>)
        ? extra['userId'] as String? ?? ''
        : '';
    final purpose = (extra is Map<String, dynamic>)
        ? extra['purpose'] as String? ?? ''
        : '';

    String message;
    if (purpose == 'verify_email') {
      message = 'Ingresa el código de 6 dígitos que enviamos a tu correo para verificar tu cuenta.';
    } else if (purpose == 'login') {
      message = 'Ingresa el código de 6 dígitos que enviamos a tu correo para iniciar sesión.';
    } else {
      message = 'Ingresa el código de 6 dígitos que recibiste.';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verificar código')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/dashboard');
          } else if (state is AuthEmailVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Correo verificado correctamente!')),
            );
            context.go('/login');
          } else if (state is AuthOTPResent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Código reenviado')),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Código OTP',
                    hintText: '000000',
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (!isLoading)
                  ElevatedButton(
                    onPressed: () {
                      final code = _otpController.text.trim();
                      if (code.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingresa 6 dígitos')),
                        );
                        return;
                      }
                      if (purpose == 'verify_email') {
                        context.read<AuthBloc>().add(
                              VerifyEmailRequested(userId: userId, code: code),
                            );
                      } else {
                        context.read<AuthBloc>().add(
                              VerifyLoginOTPRequested(userId: userId, code: code),
                        );
                      }
                    },
                    child: const Text('Verificar código'),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(
                          ResendOTPRequested(userId: userId, purpose: purpose),
                        );
                  },
                  child: const Text('Reenviar código'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
