import 'package:flutter/material.dart';

import 'api_service.dart';

class PanelControlScreen extends StatefulWidget {
  const PanelControlScreen({super.key});

  @override
  State<PanelControlScreen> createState() =>
      _PanelControlScreenState();
}

class _PanelControlScreenState
    extends State<PanelControlScreen> {
  final ApiService _apiService = ApiService();

  late Future<Map<String, dynamic>> _datos;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    _datos = _obtenerDatos();
  }

  Future<Map<String, dynamic>> _obtenerDatos() async {
    final resultados = await Future.wait<dynamic>([
      _apiService.obtenerEstadisticas(),
      _apiService.obtenerIncidencias(),
      _apiService.obtenerDashboard(),
    ]);
    return {
      'estadisticas': resultados[0],
      'incidencias': resultados[1],
      'tinacos': resultados[2],
    };
  }

  Future<void> _actualizar() async {
    setState(_cargarDatos);
    await _datos;
  } int _entero(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
  double _numero(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
  String _estado(Map<String, dynamic> incidencia) {
    return incidencia['estado']
        ?.toString()
        .trim()
        .toUpperCase() ??
        'ABIERTA';
  }
  bool _esActiva(Map<String, dynamic> incidencia) {
    final estado = _estado(incidencia);
    return estado == 'ABIERTA' ||
        estado == 'EN_PROCESO';
  }
  Color _colorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'RESUELTA':
        return Colors.green;
      case 'EN_PROCESO':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }
  IconData _iconoTipo(String tipo) {
    final texto = tipo.toLowerCase();
    if (texto.contains('fuga')) {
      return Icons.water_damage_outlined;
    } if (texto.contains('nivel')) {
      return Icons.water_drop_outlined;
    } return Icons.warning_amber_rounded;
  }
  String _nombreTinaco(
      int tinacoId,
      List<Map<String, dynamic>> tinacos,
      ) {
    for (final tinaco in tinacos) {
      if (_entero(tinaco['tinaco_id']) ==
          tinacoId) {
        return tinaco['nombre']?.toString() ??
            'Tinaco $tinacoId';
      }
    }
    return 'Tinaco $tinacoId';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon( Icons.water_drop_outlined, color: Color(0xFF0D1C6F),), SizedBox(width: 5),
            Text('sistema', style: TextStyle(color: Color(0xFF0D1C6F), fontWeight: FontWeight.bold,),),],), actions: [
          IconButton(onPressed: () { setState(_cargarDatos);},
            icon: const Icon(Icons.refresh, color: Color(0xFF0D1C6F),),),],),
      body: FutureBuilder<Map<String, dynamic>>( future: _datos, builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center( child: CircularProgressIndicator(),);
          } if (snapshot.hasError) {
            return _buildError( snapshot.error.toString(),);
          }

          final datos = snapshot.data ?? {};
          final estadisticas =
              datos['estadisticas']
              as Map<String, dynamic>? ??
                  {};
          final incidencias =
              datos['incidencias']
              as List<Map<String, dynamic>>? ??
                  [];
          final tinacos =
              datos['tinacos']
              as List<Map<String, dynamic>>? ??
                  [];
          final incidenciasActivas = incidencias
              .where(_esActiva)
              .toList();
          incidenciasActivas.sort((a, b) {
            final aPrioridad =
                a['prioridad']?.toString() ?? '';
            final bPrioridad =
                b['prioridad']?.toString() ?? '';
            return bPrioridad.compareTo(aPrioridad);
          });
          final abiertas = _entero(
            estadisticas['incidencias_abiertas'],
          );
          final enProceso = _entero(
            estadisticas[
            'incidencias_en_proceso'],
          );
          final nivelPromedio = _numero(
            estadisticas['nivel_promedio'],
          );
          return RefreshIndicator(
            onRefresh: _actualizar,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text(
                  'Centro de alerta',
                  style: TextStyle(
                    color: Color(0xFF0D1C6F),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Sistema en tiempo real para alertas',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        label: 'CRÍTICO',
                        value: abiertas
                            .toString()
                            .padLeft(2, '0'),
                        subtitle: 'incidencias abiertas',
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        label: 'EN PROCESO',
                        value: enProceso
                            .toString()
                            .padLeft(2, '0'),
                        subtitle: 'tareas atendidas',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (incidenciasActivas.isEmpty)
                  const Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 55,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No hay alertas activas',
                            style: TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final incidencia
                  in incidenciasActivas)
                    _buildAlertCard(
                      incidencia: incidencia,
                      nombreTinaco: _nombreTinaco(
                        _entero(
                          incidencia['tinaco_id'],
                        ),
                        tinacos,
                      ),
                    ),

                const SizedBox(height: 8),

                Container(
                  height: 155,
                  decoration: BoxDecoration(
                    color: const Color(0xFF071624),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.end,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Monitoreo general de los tinacos',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Nivel promedio: '
                            '${nivelPromedio.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0D1C6F),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required Map<String, dynamic> incidencia,
    required String nombreTinaco,
  }) {
    final String tipo =
        incidencia['tipo']?.toString() ??
            'Incidencia';

    final String descripcion =
        incidencia['descripcion']?.toString() ??
            'Sin descripción';

    final String estado = _estado(incidencia);

    final String prioridad =
        incidencia['prioridad']?.toString() ??
            'MEDIA';

    final Color color = _colorEstado(estado);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Icon(
                _iconoTipo(tipo),
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    nombreTinaco,
                    style: const TextStyle(
                      color: Color(0xFF0D1C6F),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    tipo.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _buildChip(
                        estado.replaceAll('_', ' '),
                        color,
                      ),
                      _buildChip(
                        'PRIORIDAD $prioridad',
                        prioridad.toUpperCase() ==
                            'ALTA'
                            ? Colors.red
                            : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
      String texto,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Padding( padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off, color: Colors.red, size: 60,),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar el panel.\n$mensaje', textAlign: TextAlign.center,),
            const SizedBox(height: 18),
            ElevatedButton( onPressed: () { setState(_cargarDatos);}, child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}