import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/movimiento/movimiento_bloc.dart';
import '../blocs/movimiento/movimiento_event.dart';
import '../blocs/movimiento/movimiento_state.dart';
import '../blocs/producto/producto_bloc.dart';
import '../blocs/producto/producto_event.dart';
import '../blocs/producto/producto_state.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  String? _tipoFilter;

  @override
  void initState() {
    super.initState();
    context.read<MovimientoBloc>().add(const LoadMovimientos());
    context.read<ProductoBloc>().add(const LoadProductos());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRegistrarForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Filtrar:'),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _tipoFilter,
                  hint: const Text('Todos'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                    DropdownMenuItem(value: 'salida', child: Text('Salida')),
                    DropdownMenuItem(value: 'ajuste', child: Text('Ajuste')),
                  ],
                  onChanged: (value) {
                    setState(() => _tipoFilter = value);
                    context.read<MovimientoBloc>().add(
                          LoadMovimientos(tipo: value),
                        );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<MovimientoBloc, MovimientoState>(
              listener: (context, state) {
                if (state is MovimientoRegistrado) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Movimiento registrado')),
                  );
                  context.read<MovimientoBloc>().add(const LoadMovimientos());
                }
              },
              builder: (context, state) {
                if (state is MovimientoLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MovimientosLoaded) {
                  if (state.movimientos.isEmpty) {
                    return const Center(child: Text('No hay movimientos'));
                  }
                  return ListView.builder(
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
                          backgroundColor: chipColor.withOpacity(0.2),
                        ),
                        title: Text(m.productoNombre),
                        subtitle: Text('SKU: ${m.productoSku}'),
                        trailing: Text('${m.cantidad}'),
                      );
                    },
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

  void _showRegistrarForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const RegistroMovimientoSheet(),
    );
  }
}

class RegistroMovimientoSheet extends StatefulWidget {
  const RegistroMovimientoSheet({super.key});

  @override
  State<RegistroMovimientoSheet> createState() =>
      _RegistroMovimientoSheetState();
}

class _RegistroMovimientoSheetState extends State<RegistroMovimientoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _notaController = TextEditingController();
  String? _tipo;
  String? _productoId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Registrar Movimiento',
                style: Theme.of(context).textTheme.titleLarge),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                DropdownMenuItem(value: 'salida', child: Text('Salida')),
                DropdownMenuItem(value: 'ajuste', child: Text('Ajuste')),
              ],
              onChanged: (v) => _tipo = v,
              validator: (v) => v == null ? 'Selecciona un tipo' : null,
            ),
            BlocBuilder<ProductoBloc, ProductoState>(
              builder: (context, state) {
                if (state is ProductosLoaded) {
                  return DropdownButtonFormField<String>(
                    value: _productoId,
                    decoration:
                        const InputDecoration(labelText: 'Producto'),
                    items: state.productos
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.nombre),
                            ))
                        .toList(),
                    onChanged: (v) => _productoId = v,
                    validator: (v) =>
                        v == null ? 'Selecciona un producto' : null,
                  );
                }
                return const LinearProgressIndicator();
              },
            ),
            TextFormField(
              controller: _cantidadController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: const InputDecoration(labelText: 'Cantidad'),
              validator: (v) => v == null || v.isEmpty
                  ? 'Ingresa la cantidad'
                  : null,
            ),
            TextFormField(
              controller: _notaController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Nota'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<MovimientoBloc>().add(
                        RegistrarMovimiento(
                          tipo: _tipo!,
                          productoId: _productoId!,
                          cantidad: double.parse(_cantidadController.text),
                          nota: _notaController.text,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
