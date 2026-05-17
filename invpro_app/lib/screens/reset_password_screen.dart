import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  bool _showCodeStep = false;
  String _email = '';
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetOTPSent) {
            setState(() {
              _showCodeStep = true;
              _email = state.email;
            });
          } else if (state is AuthPasswordResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contraseña restablecida. Inicia sesión.')),
            );
            context.go('/login');
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
            child: _showCodeStep
                ? _buildCodeStep(context, isLoading)
                : _buildEmailStep(context, isLoading),
          );
        },
      ),
    );
  }

  Widget _buildEmailStep(BuildContext context, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
        ),
        const SizedBox(height: 24),
        if (isLoading)
          const Center(child: CircularProgressIndicator()),
        if (!isLoading)
          ElevatedButton(
            onPressed: () {
              final email = _emailController.text.trim();
              if (email.isEmpty) return;
              context.read<AuthBloc>().add(
                    PasswordResetRequested(email: email),
                  );
            },
            child: const Text('Enviar código'),
          ),
      ],
    );
  }

  Widget _buildCodeStep(BuildContext context, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nueva contraseña'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
        ),
        const SizedBox(height: 24),
        if (isLoading)
          const Center(child: CircularProgressIndicator()),
        if (!isLoading)
          ElevatedButton(
            onPressed: () {
              final code = _codeController.text.trim();
              final newPassword = _passwordController.text;
              final confirm = _confirmPasswordController.text;
              if (code.isEmpty || newPassword.isEmpty || confirm.isEmpty) return;
              if (newPassword != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Las contraseñas no coinciden')),
                );
                return;
              }
              context.read<AuthBloc>().add(
                    PasswordResetConfirmed(
                      email: _email,
                      code: code,
                      newPassword: newPassword,
                      newPasswordConfirm: confirm,
                    ),
                  );
            },
            child: const Text('Restablecer contraseña'),
          ),
      ],
    );
  }
}
