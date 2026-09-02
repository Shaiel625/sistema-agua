import 'package:flutter/material.dart';

import 'api_service.dart';

class NodosScreen extends StatefulWidget {
  const NodosScreen({super.key});

  @override
  State<NodosScreen> createState() =>
      _NodosScreenState();
}

class _NodosScreenState extends State<NodosScreen> {
  final _formKey = GlobalKey<FormState>();

  final _idController = TextEditingController();
  final _nombreController = TextEditingController();

  final ApiService _apiService = ApiService();

  String _estadoSeleccionado = 'activo';
  bool _estaCargando = false;

  @override
  void dispose() {
    _idController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardarNodoEnPython() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _estaCargando = true;
    });

    try {
      await _apiService.registrarDispositivo(
        esp32Id: _idController.text.trim(),
        estado: _estadoSeleccionado,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            ' Nodo registrado correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ' Error al registrar el nodo:\n$e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _estaCargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Registrar Nodo',
          style: TextStyle(
            color: Color(0xFF0D1C6F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'Alta de Dispositivo Inteligente',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1C6F),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText:
                  'ID del Nodo (Ej: ESP32-001)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Por favor ingresa el ID';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText:
                  'Nombre / Ubicación (Ej: TINACO ED4)',
                  border: OutlineInputBorder(),
                  helperText:
                  'Se conserva en el diseño. El backend todavía no guarda este campo.',
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Por favor ingresa la ubicación';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _estadoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Estado Inicial',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'activo',
                    child: Text('ACTIVO'),
                  ),
                  DropdownMenuItem(
                    value: 'alerta',
                    child: Text('ALERTA'),
                  ),
                  DropdownMenuItem(
                    value: 'sin señal',
                    child: Text('SIN SEÑAL'),
                  ),
                ],
                onChanged: (nuevoEstado) {
                  if (nuevoEstado == null) return;

                  setState(() {
                    _estadoSeleccionado =
                        nuevoEstado;
                  });
                },
              ),

              const SizedBox(height: 32),

              _estaCargando
                  ? const Center(
                child:
                CircularProgressIndicator(
                  color: Color(0xFF0D1C6F),
                ),
              )
                  : ElevatedButton(
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(
                    0xFF0D1C6F,
                  ),
                  minimumSize:
                  const Size(
                    double.infinity,
                    50,
                  ),
                ),
                onPressed:
                _guardarNodoEnPython,
                child: const Text(
                  'GUARDAR NODO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}