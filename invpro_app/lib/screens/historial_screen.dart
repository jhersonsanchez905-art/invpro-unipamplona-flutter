import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/movimiento/movimiento_bloc.dart';
import '../blocs/movimiento/movimiento_event.dart';
import '../blocs/movimiento/movimiento_state.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  String? _tipoFilter;
  String? _fechaFilter;

  @override
  void initState() {
    super.initState();
    context.read<MovimientoBloc>().add(const LoadMovimientos());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de movimientos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                DropdownButton<String?>(
                  value: _tipoFilter,
                  hint: const Text('Todos los tipos'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                    DropdownMenuItem(value: 'salida', child: Text('Salida')),
                    DropdownMenuItem(value: 'ajuste', child: Text('Ajuste')),
                  ],
                  onChanged: (value) {
                    setState(() => _tipoFilter = value);
                    _refreshList();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _selectDateRange(context),
                  child: const Text('Rango de fechas'),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<MovimientoBloc, MovimientoState>(
              builder: (context, state) {
                if (state is MovimientoLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MovimientosLoaded) {
                  if (state.movimientos.isEmpty) {
                    return const Center(child: Text('No hay movimientos'));
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels >=
                          scrollInfo.metrics.maxScrollExtent - 200) {
                        context
                            .read<MovimientoBloc>()
                            .add(LoadMoreMovimientos());
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<MovimientoBloc>().add(
                              const LoadMovimientos());
                      },
                      child: ListView.builder(
                        itemCount: state.movimientos.length,
                        itemBuilder: (context, index) {
                          final m = state.movimientos[index];
                          Color chipColor;
                          switch (m.tipo) {
                            case 'entrada':
                              chipColor = Colors.green;
                              break;
                            case 'salida':
                              chipColor = Colors.red;
                              break;
                            default:
                              chipColor = Colors.blue;
                          }
                          return ListTile(
                            leading: Chip(
                              label: Text(m.tipoLabel),
                              backgroundColor:
                                  chipColor.withOpacity(0.2),
                            ),
                            title: Text(m.productoNombre),
                            subtitle: Text(m.nota),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${m.cantidad}'),
                                Text(m.createdAt.toString()),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                } else if (state is MovimientoError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        ElevatedButton(
                          onPressed: () => context
                              .read<MovimientoBloc>()
                              .add(const LoadMovimientos()),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: Text('Cargando...'));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _refreshList() {
    context
        .read<MovimientoBloc>()
        .add(LoadMovimientos(tipo: _tipoFilter));
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _fechaFilter =
          '${picked.start.toIso8601String()}/${picked.end.toIso8601String()}';
      _refreshList();
    }
  }
}
