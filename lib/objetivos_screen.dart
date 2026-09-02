import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class ObjetivosScreen extends StatefulWidget {
  const ObjetivosScreen({super.key});

  @override
  State<ObjetivosScreen> createState() => _ObjetivosScreenState();
}

class _ObjetivosScreenState extends State<ObjetivosScreen> {
  List<Map<String, dynamic>> pendientes = [];
  List<Map<String, dynamic>> completadas = [];
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/incidencias/historial'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {

          pendientes = data.where((inc) {
            final estado = (inc['estado'] ?? '').toString().toUpperCase();
            return estado == 'ABIERTA' || estado == 'EN_PROCESO';
          }).map((e) => e as Map<String, dynamic>).toList();


          completadas = data.where((inc) {
            final estado = (inc['estado'] ?? '').toString().toUpperCase();
            return estado == 'RESUELTA' || estado == 'CERRADA';
          }).map((e) => e as Map<String, dynamic>).toList();

          cargando = false;
        });
      } else {
        throw Exception('El servidor no respondió correctamente.');
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = 'Error al cargar datos: $e';
      });
    }
  }

  int get totalTareas => pendientes.length + completadas.length;
  double get porcentajeCompletado =>
      totalTareas > 0 ? completadas.length / totalTareas : (cargando ? 0.0 : 1.0);
  int get tareasPendientes => pendientes.length;

  Future<void> cambiarEstadoIncidencia(Map<String, dynamic> incidencia) async {
    final estadoActual = (incidencia['estado'] ?? '').toString().toUpperCase();
    final esAbierta = estadoActual == 'ABIERTA';
    final nuevoEstado = esAbierta ? 'EN_PROCESO' : 'RESUELTA';

    final mensajeConfirmacion = esAbierta
        ? '¿Deseas ACEPTAR esta tarea y marcarla como EN PROCESO?'
        : '¿Deseas FINALIZAR esta tarea y marcarla como RESUELTA?';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(esAbierta ? 'Aceptar Tarea' : 'Finalizar Tarea'),
        content: Text(mensajeConfirmacion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/incidencias/${incidencia['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await cargarDatos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(esAbierta
                  ? 'Tarea aceptada (En Proceso)'
                  : 'Incidencia finalizada correctamente'),
              backgroundColor: esAbierta ? Colors.blue : const Color(0xCC67C656),
            ),
          );
        }
      } else {
        throw Exception('El servidor rechazó la actualización.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: cargarDatos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OBJETIVO DE MANTENIMIENTO',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(porcentajeCompletado * 100).toStringAsFixed(0)}% completo',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.green
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${completadas.length}/$totalTareas listas',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: porcentajeCompletado,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(
                            Colors.green),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tareasPendientes > 0
                          ? 'Quedan $tareasPendientes nodo(s) pendientes de atención'
                          : 'Todas las incidencias han sido resueltas',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),


              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Nodos Pendientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              pendientes.isEmpty
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Sin tareas pendientes 🎉',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
                  : Column(
                children: pendientes
                    .map((t) => _buildTareaPendiente(t))
                    .toList(),
              ),

              const SizedBox(height: 20),


              const Text('Tareas Completadas',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              completadas.isEmpty
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Aún no hay tareas finalizadas',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
                  : Column(
                children: completadas
                    .map((t) => _buildTareaCompletada(t))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTareaPendiente(Map<String, dynamic> incidencia) {
    final estadoTexto = (incidencia['estado'] ?? '').toString().toUpperCase();
    final tinacoId = incidencia['tinaco_id']?.toString() ?? 'Desconocido';
    final idRegistro = incidencia['id']?.toString() ?? '-';

    final bool enProceso = estadoTexto == 'EN_PROCESO';

    Color etiquetaColor = enProceso ? Colors.blue : Colors.red;
    String etiqueta = enProceso ? 'EN PROCESO' : 'PENDIENTE / ABIERTA';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: etiquetaColor, width: 4)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: etiquetaColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border:
                  Border.all(color: etiquetaColor.withValues(alpha: 0.3)),
                ),
                child: Text(etiqueta,
                    style: TextStyle(
                        fontSize: 10,
                        color: etiquetaColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Revisar Nodo $tinacoId',
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Incidencia ID: $idRegistro',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                !enProceso ? Icons.history_toggle_off : Icons.sync,
                size: 14,
                color: !enProceso ? Colors.redAccent : Colors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                'Estado Actual: $estadoTexto',
                style: TextStyle(
                  fontSize: 12,
                  color: !enProceso ? Colors.redAccent : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => cambiarEstadoIncidencia(incidencia),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                !enProceso ? 'ACEPTAR TAREA' : 'FINALIZAR TAREA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareaCompletada(Map<String, dynamic> incidencia) {
    final tinacoId = incidencia['tinaco_id']?.toString() ?? 'Desconocido';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
              color: Colors.green, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        ),
        title: Text('Incidencia Nodo $tinacoId',
            style:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: const Text('Resuelta / Operando',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ),
    );
  }
}