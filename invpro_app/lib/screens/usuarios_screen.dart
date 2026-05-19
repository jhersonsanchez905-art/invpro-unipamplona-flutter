import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../repositories/usuarios_repository.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _repo = GetIt.I<UsuariosRepository>();
  List<dynamic> _usuarios = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar({String query = ''}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _repo.getUsuarios(
        search: query.isNotEmpty ? query : null,
      );
      setState(() {
        _usuarios = result['results'] as List<dynamic>? ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = 'No se pudo cargar la lista de usuarios.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final esAdmin = authState is AuthAuthenticated && authState.user.esAdmin;

    if (!esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Usuarios')),
        body: const Center(child: Text('No tienes permisos para ver esta sección.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargar(query: _searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _cargar();
                        },
                      )
                    : null,
              ),
              onSubmitted: (v) => _cargar(query: v),
              onChanged: (v) => setState(() {}),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cargar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_usuarios.isEmpty) {
      return const Center(child: Text('No hay usuarios registrados.'));
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        itemCount: _usuarios.length,
        itemBuilder: (context, i) {
          final u = _usuarios[i] as Map<String, dynamic>;
          final nombre =
              '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
          final rol = u['rol'] as String? ?? '';
          final activo = u['is_active'] as bool? ?? false;
          final verificado = u['email_verified'] as bool? ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    activo ? Colors.blue.shade100 : Colors.grey.shade200,
                child: Text(
                  (u['username'] as String? ?? '?')[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                nombre.isNotEmpty
                    ? nombre
                    : (u['username'] as String? ?? ''),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${u['email']}  ·  $rol',
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    verificado ? Icons.verified : Icons.cancel_outlined,
                    color: verificado ? Colors.green : Colors.orange,
                    size: 18,
                  ),
                  Text(
                    activo ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 11,
                      color: activo ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}