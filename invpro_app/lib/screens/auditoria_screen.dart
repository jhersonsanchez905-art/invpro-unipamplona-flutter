import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

class AuditoriaScreen extends StatelessWidget {
  const AuditoriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final esAuditor = authState is AuthAuthenticated &&
        authState.user.esAuditor;
    final esAdmin = authState is AuthAuthenticated &&
        authState.user.esAdmin;

    if (!esAuditor && !esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auditoria')),
        body: const Center(child: Text('No tienes permisos')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Auditoria')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Logs de auditoria',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Los registros de auditoria se almacenan automaticamente por cada accion en el sistema.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Endpoint de consulta proximamente disponible.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
