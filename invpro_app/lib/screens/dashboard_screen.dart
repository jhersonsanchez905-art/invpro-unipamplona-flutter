import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/dashboard/dashboard_bloc.dart';
import '../blocs/dashboard/dashboard_event.dart';
import '../blocs/dashboard/dashboard_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardBloc>().add(LoadDashboard());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user =
        authState is AuthAuthenticated ? authState.user : null;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('InvPro'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
            ),
          ],
        ),
        drawer: _buildDrawerMenu(context, user),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is DashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<DashboardBloc>().add(LoadDashboard());
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            } else if (state is DashboardLoaded) {
              final data = state.data;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildKpiRow(data),
                    const SizedBox(height: 16),
                    Text(
                      'Ultimos movimientos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._buildMovimientosList(data),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildKpiRow(Map<String, dynamic> data) {
    final productos =
        (data['productos'] as List<dynamic>?) ?? [];
    final movimientos =
        (data['movimientos'] as List<dynamic>?) ?? [];

    final totalProductos = productos.length;
    final productosAlerta = productos.where((p) {
      return p is Map<String, dynamic> && p['tiene_alerta'] == true;
    }).length;

    final hoy = DateTime.now().toString().substring(0, 10);
    final movimientosHoy = movimientos.where((m) {
      return m is Map<String, dynamic> &&
          m['created_at'] != null &&
          m['created_at'].toString().startsWith(hoy);
    }).length;

    double valorInventario = 0;
    for (final p in productos) {
      if (p is Map<String, dynamic>) {
        final stock =
            (p['stock_actual'] as num?)?.toDouble() ?? 0;
        final precio =
            (p['precio_unitario'] as num?)?.toDouble() ?? 0;
        valorInventario += stock * precio;
      }
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildKpiCard('Total productos', totalProductos.toString()),
        _buildKpiCard('Con alerta', productosAlerta.toString()),
        _buildKpiCard('Mov. hoy', movimientosHoy.toString()),
        _buildKpiCard(
            'Valor inventario',
            '\$' + valorInventario.toStringAsFixed(2)),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMovimientosList(Map<String, dynamic> data) {
    final movimientos =
        (data['movimientos'] as List<dynamic>?) ?? [];
    final lastFive = movimientos.take(5).toList();

    if (lastFive.isEmpty) {
      return [const Text('No hay movimientos recientes')];
    }

    return lastFive.map((m) {
      if (m is Map<String, dynamic>) {
        return ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: Text(m['tipo']?.toString() ?? ''),
          subtitle: Text(m['producto']?['sku']?.toString() ?? ''),
          trailing: Text(m['cantidad']?.toString() ?? ''),
        );
      }
      return const ListTile();
    }).toList();
  }

  Widget _buildDrawerMenu(
      BuildContext context, dynamic user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration:
                BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('InvPro',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                if (user != null)
                  Text(user.email ?? '',
                      style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => context.go('/dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial'),
            onTap: () => context.go('/historial'),
          ),
          if (user != null && user.esAlmacenista)
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Movimientos'),
              onTap: () => context.go('/movimientos'),
            ),
          if (user != null && user.esAlmacenista)
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Productos'),
              onTap: () => context.go('/productos'),
            ),
          if (user != null && user.esAdmin)
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Categorias'),
              onTap: () => context.go('/categorias'),
            ),
          if (user != null && user.esAdmin)
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Usuarios'),
              onTap: () => context.go('/usuarios'),
            ),
          if (user != null && user.esAdmin)
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Auditoria'),
              onTap: () => context.go('/auditoria'),
            ),
          if (user != null && user.esAuditor)
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Reportes'),
              onTap: () => context.go('/reportes'),
            ),
        ],
      ),
    );
  }
}
