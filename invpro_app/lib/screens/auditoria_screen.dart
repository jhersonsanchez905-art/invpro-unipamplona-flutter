import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../repositories/auditoria_repository.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final _repo = GetIt.I<AuditoriaRepository>();
  List<dynamic> _logs = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String? _filtroAccion;

  @override
  void initState() {
    super.initState();
    _cargarLogs();
  }

  Future<void> _cargarLogs({bool reset = false}) async {
    if (reset) {
      setState(() { _page = 1; _logs = []; _hasMore = true; });
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _repo.getLogs(
        page: _page,
        action: _filtroAccion,
      );
      final data = result['results'] as List<dynamic>? ?? [];
      setState(() {
        _logs = reset ? data : [..._logs, ...data];
        _hasMore = result['next'] != null;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'No se pudieron cargar los logs.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final esAutorizado = authState is AuthAuthenticated &&
        (authState.user.esAuditor || authState.user.esAdmin);

    if (!esAutorizado) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auditoría')),
        body: const Center(child: Text('No tienes permisos para ver esta sección.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs de auditoría'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () => _cargarLogs(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text('Acción:'),
          const SizedBox(width: 8),
          DropdownButton<String?>(
            value: _filtroAccion,
            hint: const Text('Todas'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todas')),
              DropdownMenuItem(value: 'create', child: Text('Creación')),
              DropdownMenuItem(value: 'update', child: Text('Actualización')),
              DropdownMenuItem(value: 'delete', child: Text('Eliminación')),
            ],
            onChanged: (v) {
              setState(() => _filtroAccion = v);
              _cargarLogs(reset: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _cargarLogs(reset: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_logs.isEmpty) {
      return const Center(child: Text('No hay registros de auditoría.'));
    }

    return RefreshIndicator(
      onRefresh: () => _cargarLogs(reset: true),
      child: ListView.builder(
        itemCount: _logs.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _logs.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ElevatedButton(
                  onPressed: () { _page++; _cargarLogs(); },
                  child: const Text('Cargar más'),
                ),
              ),
            );
          }
          return _buildLogTile(_logs[index] as Map<String, dynamic>);
        },
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
    final action = log['action'] as String? ?? '';
    final entity = log['entity'] as String? ?? '';
    final usuario = log['usuario'] as String? ?? 'Sistema';
    final httpStatus = log['http_status'] as int?;
    final createdAt = log['created_at'] as String? ?? '';
    final fecha = createdAt.length >= 16
        ? createdAt.substring(0, 16).replaceAll('T', ' ')
        : createdAt;

    final IconData icon;
    final Color color;
    switch (action) {
      case 'create':
        icon = Icons.add_circle_outline;
        color = Colors.green;
        break;
      case 'update':
        icon = Icons.edit_outlined;
        color = Colors.orange;
        break;
      case 'delete':
        icon = Icons.delete_outline;
        color = Colors.red;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          '$action — $entity',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Usuario: $usuario · $fecha'),
        trailing: httpStatus != null
            ? Chip(
                label: Text('$httpStatus'),
                backgroundColor: (httpStatus >= 200 && httpStatus < 300)
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                padding: EdgeInsets.zero,
              )
            : null,
      ),
    );
  }
}