import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/categoria/categoria_bloc.dart';
import '../blocs/categoria/categoria_event.dart';
import '../blocs/categoria/categoria_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoriaBloc>().add(const LoadCategorias());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final esAdmin =
        authState is AuthAuthenticated && authState.user.esAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context),
          ),
        ],
      ),
      body: BlocBuilder<CategoriaBloc, CategoriaState>(
        builder: (context, state) {
          if (state is CategoriaLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CategoriasLoaded) {
            return ListView.builder(
              itemCount: state.categorias.length,
              itemBuilder: (context, index) {
                final cat = state.categorias[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF'))),
                  ),
                  title: Text(cat.nombre),
                  subtitle: Text('Productos: ${cat.productosCount}'),
                  trailing: esAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showForm(context, cat.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () =>
                                  _confirmDelete(context, cat.id),
                            ),
                          ],
                        )
                      : null,
                );
              },
            );
          } else if (state is CategoriaError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<CategoriaBloc>().add(LoadCategorias()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Cargando...'));
        },
      ),
    );
  }

  void _showForm(BuildContext context, [String? id]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CategoriaFormSheet(id: id),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoria'),
        content: const Text('Seguro que deseas eliminar esta categoria?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<CategoriaBloc>().add(DeleteCategoria(id: id));
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class CategoriaFormSheet extends StatefulWidget {
  final String? id;
  const CategoriaFormSheet({super.key, this.id});

  @override
  State<CategoriaFormSheet> createState() => _CategoriaFormSheetState();
}

class _CategoriaFormSheetState extends State<CategoriaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _colorHex = '#AD3333';

  final List<String> _presetColors = [
    '#AD3333', '#3B82F6', '#10B981', '#F59E0B',
    '#8B5CF6', '#EC4899', '#06B6D4', '#6B7280',
  ];

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
            Text(
              widget.id == null ? 'Nueva Categoria' : 'Editar Categoria',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v == null || v.isEmpty ? 'Obligatorio' : null,
            ),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripcion'),
            ),
            const SizedBox(height: 16),
            const Text('Color:'),
            Wrap(
              spacing: 8,
              children: _presetColors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                          color.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: _colorHex == color
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final data = {
                    'nombre': _nombreController.text,
                    'descripcion': _descripcionController.text,
                    'color_hex': _colorHex,
                    'prefijo_sku': '',
                  };
                  final bloc = context.read<CategoriaBloc>();
                  if (widget.id == null) {
                    bloc.add(CreateCategoria(data: data));
                  } else {
                    bloc.add(UpdateCategoria(id: widget.id!, data: data));
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
