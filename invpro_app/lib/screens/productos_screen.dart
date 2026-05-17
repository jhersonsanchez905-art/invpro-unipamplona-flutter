import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/producto/producto_bloc.dart';
import '../blocs/producto/producto_event.dart';
import '../blocs/producto/producto_state.dart';
import '../blocs/categoria/categoria_bloc.dart';
import '../blocs/categoria/categoria_event.dart';
import '../blocs/categoria/categoria_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProductoBloc>().add(const LoadProductos());
    context.read<CategoriaBloc>().add(const LoadCategorias());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final esAlmacenista = user?.esAlmacenista ?? false;
    final esAdmin = user?.esAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar productos...',
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  context.read<ProductoBloc>().add(
                        SearchProductos(query: value),
                      );
                },
              )
            : const Text('Productos'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_searching) {
                  _searching = false;
                  _searchController.clear();
                } else {
                  _searching = true;
                }
              });
            },
          ),
          if (esAlmacenista)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showProductoForm(context),
            ),
        ],
      ),
      body: BlocBuilder<ProductoBloc, ProductoState>(
        builder: (context, state) {
          if (state is ProductoLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ProductosLoaded) {
            if (state.productos.isEmpty) {
              return const Center(child: Text('No hay productos'));
            }
            return ListView.builder(
              itemCount: state.productos.length,
              itemBuilder: (context, index) {
                final producto = state.productos[index];
                return ListTile(
                  title: Text(producto.nombre),
                  subtitle: Text('SKU: ${producto.sku}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Stock: ${producto.stockActual}'),
                      if (esAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, producto.id),
                        ),
                    ],
                  ),
                  onTap: () => _showProductoDetail(context, producto),
                  onLongPress: () {
                    if (esAlmacenista) _showProductoForm(context, producto.id);
                  },
                );
              },
            );
          } else if (state is ProductoError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  ElevatedButton(
                    onPressed: () => context.read<ProductoBloc>().add(
                        const LoadProductos()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Cargando productos...'));
        },
      ),
    );
  }

  void _showProductoForm(BuildContext context, [String? id]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProductoFormSheet(id: id),
    );
  }

  void _showProductoDetail(BuildContext context, dynamic producto) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(producto.nombre),
            subtitle: Text('SKU: ${producto.sku}'),
          ),
          ListTile(
            title: const Text('Stock actual'),
            trailing: Text('${producto.stockActual}'),
          ),
          ListTile(
            title: const Text('Precio unitario'),
            trailing: Text('\$${producto.precioUnitario}'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('Seguro que deseas eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductoBloc>().add(DeleteProducto(id: id));
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ProductoFormSheet extends StatefulWidget {
  final String? id;
  const ProductoFormSheet({super.key, this.id});

  @override
  State<ProductoFormSheet> createState() => _ProductoFormSheetState();
}

class _ProductoFormSheetState extends State<ProductoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _stockController = TextEditingController();
  final _precioController = TextEditingController();
  String? _selectedCategoriaId;

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
            Text(widget.id == null ? 'Nuevo Producto' : 'Editar Producto',
                style: Theme.of(context).textTheme.titleLarge),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Obligatorio' : null,
            ),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripcion'),
            ),
            BlocBuilder<CategoriaBloc, CategoriaState>(
              builder: (context, state) {
                if (state is CategoriasLoaded) {
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoriaId,
                    decoration:
                        const InputDecoration(labelText: 'Categoria'),
                    items: state.categorias.map((c) =>
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nombre),
                        )).toList(),
                    onChanged: (v) => _selectedCategoriaId = v,
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock minimo'),
            ),
            TextFormField(
              controller: _precioController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Precio unitario'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final data = {
                    'nombre': _nombreController.text,
                    'descripcion': _descripcionController.text,
                    'categoria_id': _selectedCategoriaId ?? '',
                    'stock_minimo': _stockController.text,
                    'precio_unitario': _precioController.text,
                  };
                  if (widget.id == null) {
                    context.read<ProductoBloc>().add(
                        CreateProducto(data: data));
                  } else {
                    context.read<ProductoBloc>().add(
                        UpdateProducto(id: widget.id!, data: data));
                  }
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
