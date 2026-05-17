import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../core/api_client.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _downloading = false;

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  Future<void> _downloadReport(String endpoint, {String? fechaInicio, String? fechaFin}) async {
    setState(() => _downloading = true);
    try {
      final apiClient = ApiClient();
      final queryParams = <String, dynamic>{};
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      final response = await apiClient.dio.get(
        endpoint,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
        options: Options(responseType: ResponseType.bytes),
      );

      final tempDir = Directory.systemTemp;
      final fileName = 'reporte_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.data as List<int>);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte descargado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e')),
        );
      }
    } finally {
      setState(() => _downloading = false);
    }
  }

  String get _fechaInicioStr =>
      _fechaInicio?.toIso8601String().substring(0, 10) ?? '';
  String get _fechaFinStr =>
      _fechaFin?.toIso8601String().substring(0, 10) ?? '';

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final esAuditor = authState is AuthAuthenticated &&
        authState.user.esAuditor;
    final esAdmin = authState is AuthAuthenticated &&
        authState.user.esAdmin;

    if (!esAuditor && !esAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reportes')),
        body: const Center(child: Text('No tienes permisos para ver reportes')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.inventory_2),
                      title: Text('Inventario actual'),
                      subtitle: Text('Reporte completo del inventario'),
                    ),
                    if (_downloading)
                      const Center(child: CircularProgressIndicator()),
                    if (!_downloading)
                      ElevatedButton(
                        onPressed: () =>
                            _downloadReport('/api/v1/reports/inventario/'),
                        child: const Text('Descargar PDF'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.swap_horiz),
                      title: Text('Movimientos'),
                      subtitle: Text('Movimientos por rango de fechas'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => _pickDate(context, true),
                            child: Text(_fechaInicio != null
                                ? _fechaInicioStr
                                : 'Fecha inicio'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: () => _pickDate(context, false),
                            child: Text(_fechaFin != null
                                ? _fechaFinStr
                                : 'Fecha fin'),
                          ),
                        ),
                      ],
                    ),
                    if (_downloading)
                      const Center(child: CircularProgressIndicator()),
                    if (!_downloading)
                      ElevatedButton(
                        onPressed: () {
                          if (_fechaInicio != null && _fechaFin != null) {
                            _downloadReport(
                              '/api/v1/reports/movimientos/',
                              fechaInicio: _fechaInicioStr,
                              fechaFin: _fechaFinStr,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Selecciona ambas fechas')),
                            );
                          }
                        },
                        child: const Text('Descargar PDF'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.category),
                      title: Text('Por categoria'),
                      subtitle: Text(
                          'Inventario agrupado por categoria'),
                    ),
                    if (_downloading)
                      const Center(child: CircularProgressIndicator()),
                    if (!_downloading)
                      ElevatedButton(
                        onPressed: () =>
                            _downloadReport('/api/v1/reports/categorias/'),
                        child: const Text('Descargar PDF'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
