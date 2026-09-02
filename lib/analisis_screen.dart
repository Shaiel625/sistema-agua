import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Incidencia {
  final int id;
  final int tinacoId;
  final String tipo;
  final String? descripcion;
  final String estado;
  final String prioridad;
  final int? tiempoEstimadoMinutos;
  final DateTime fechaCreacion;
  final int? tiempoRealMinutos;

  Incidencia({
    required this.id,
    required this.tinacoId,
    required this.tipo,
    this.descripcion,
    required this.estado,
    required this.prioridad,
    this.tiempoEstimadoMinutos,
    required this.fechaCreacion,
    this.tiempoRealMinutos,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    return Incidencia(
      id: json['id'],
      tinacoId: json['tinaco_id'],
      tipo: json['tipo'],
      descripcion: json['descripcion'],
      estado: json['estado'],
      prioridad: json['prioridad'],
      tiempoEstimadoMinutos: json['tiempo_estimado_minutos'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      tiempoRealMinutos: json['tiempo_real_minutos'],
    );
  }
}

class Dispositivo {
  final int id;
  final String esp32Id;
  final String estado;

  Dispositivo({
    required this.id,
    required this.esp32Id,
    required this.estado,
  });

  factory Dispositivo.fromJson(Map<String, dynamic> json) {
    return Dispositivo(
      id: json['id'],
      esp32Id: json['esp32_id'],
      estado: json['estado'],
    );
  }
}

class NodoDashboard {
  final int tinacoId;
  final String nombre;
  final int capacidadLitros;
  final double porcentaje;
  final double litros;
  int numFallas;

  NodoDashboard({
    required this.tinacoId,
    required this.nombre,
    required this.capacidadLitros,
    required this.porcentaje,
    required this.litros,
    this.numFallas = 0,
  });

  factory NodoDashboard.fromJson(Map<String, dynamic> json) {
    return NodoDashboard(
      tinacoId: json['tinaco_id'],
      nombre: json['nombre'],
      capacidadLitros: json['capacidad_litros'],
      porcentaje: (json['porcentaje'] as num).toDouble(),
      litros: (json['litros'] as num).toDouble(),
    );
  }
}

class AnalisisScreen extends StatefulWidget {
  const AnalisisScreen({super.key});

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> {
  List<NodoDashboard> dashboard = [];
  List<Incidencia> incidencias = [];
  List<Dispositivo> dispositivos = [];
  double tiempoPromedioAtencion = 0;
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('${ApiService.baseUrl}/dashboard/')),
        http.get(Uri.parse('${ApiService.baseUrl}/incidencias/historial')),
        http.get(Uri.parse('${ApiService.baseUrl}/dispositivos/')),
        http.get(Uri.parse('${ApiService.baseUrl}/dashboard/estadisticas')),
      ]);

      final dashboardData =
      jsonDecode(utf8.decode(responses[0].bodyBytes)) as List;
      final incidenciasData =
      jsonDecode(utf8.decode(responses[1].bodyBytes)) as List;
      final dispositivosData =
      jsonDecode(utf8.decode(responses[2].bodyBytes)) as List;
      final estadisticas = jsonDecode(utf8.decode(responses[3].bodyBytes));

      final dashboardList =
      dashboardData.map((e) => NodoDashboard.fromJson(e)).toList();
      final incidenciasList =
      incidenciasData.map((e) => Incidencia.fromJson(e)).toList();
      final dispositivosList =
      dispositivosData.map((e) => Dispositivo.fromJson(e)).toList();

      for (var nodo in dashboardList) {
        nodo.numFallas =
            incidenciasList.where((i) => i.tinacoId == nodo.tinacoId).length;
      }

      setState(() {
        dashboard = dashboardList;
        incidencias = incidenciasList;
        dispositivos = dispositivosList;
        tiempoPromedioAtencion =
            (estadisticas['tiempo_promedio_atencion'] as num).toDouble();
        cargando = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        cargando = false;
        error = 'Error al cargar datos: $e';
      });
    }
  }

  Future<void> descargarReporte() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('REPORTE DE INCIDENCIAS');
      buffer.writeln(
          'Generado: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
      buffer.writeln('');
      buffer.writeln('FECHA,NODO,TIPO,ESTADO');

      for (final inc in incidencias) {
        final nodo = dashboard.firstWhere(
              (d) => d.tinacoId == inc.tinacoId,
          orElse: () => NodoDashboard(
              tinacoId: 0,
              nombre: 'Desconocido',
              capacidadLitros: 0,
              porcentaje: 0,
              litros: 0),
        );
        buffer.writeln(
          '${inc.fechaCreacion.day}/${inc.fechaCreacion.month}/${inc.fechaCreacion.year},'
              '${nodo.nombre},'
              '${inc.tipo},'
              '${inc.estado}',
        );
      }

      final dir = await getTemporaryDirectory();
      final archivo = File('${dir.path}/reporte_incidencias.csv');
      await archivo.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(archivo.path)],
        text: 'Reporte de incidencias del sistema de agua',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al generar reporte: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void verHistorialCompleto() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistorialIncidencias(
            incidencias: incidencias, dashboard: dashboard),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue),
            SizedBox(width: 8),
            Text('Sistema de agua',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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
              onPressed: () {
                setState(() {
                  cargando = true;
                  error = null;
                });
                cargarDatos();
              },
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
              const Text('Puntos Críticos',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Análisis de fallas y nodos',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 16),


              Container(
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Frecuencia de Incidencias',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...dashboard.map((nodo) {
                      int numFallas = nodo.numFallas;
                      int maxFallas = dashboard.isEmpty
                          ? 0
                          : dashboard
                          .map((n) => n.numFallas)
                          .fold(0, (a, b) => a > b ? a : b);

                      double porcentajeBarra = maxFallas > 0
                          ? (numFallas / maxFallas).clamp(0.0, 1.0)
                          : 0.0;
                      bool critico = numFallas >= 10;

                      String etiqueta = numFallas >= 10
                          ? 'INTENSIDAD CRÍTICA'
                          : numFallas >= 6
                          ? 'ALTA FRECUENCIA'
                          : numFallas >= 2
                          ? 'MÓDICO'
                          : '';

                      Color color = numFallas >= 10
                          ? Colors.red
                          : numFallas >= 6
                          ? Colors.blue
                          : Colors.cyan;

                      return Column(
                        children: [
                          _buildNodoFila(
                              nodo.nombre,
                              '$numFallas incidencias',
                              color,
                              porcentajeBarra,
                              etiqueta,
                              critico),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: descargarReporte,
                        child: const Text(
                            'Descargar reporte completo',
                            style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),


              Row(
                children: [
                  Expanded(
                    child: Container(
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
                          const Text('Tiempo de solución',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            tiempoPromedioAtencion > 0
                                ? '${tiempoPromedioAtencion.toStringAsFixed(0)} min'
                                : 'sin datos',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text('promedio de atención',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
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
                          const Text('Incidencias',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('${incidencias.length}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('registrada(s)',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Incidentes recientes',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 450,
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                SizedBox(
                                    width: 60,
                                    child: Text('FECHA',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            fontWeight:
                                            FontWeight.bold))),
                                SizedBox(width: 8),
                                SizedBox(
                                    width: 100,
                                    child: Text('NODO',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            fontWeight:
                                            FontWeight.bold))),
                                SizedBox(width: 8),
                                SizedBox(
                                    width: 130,
                                    child: Text('TIPO',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            fontWeight:
                                            FontWeight.bold))),
                                SizedBox(width: 8),
                                SizedBox(
                                    width: 110,
                                    child: Text('ESTADO',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                            fontWeight:
                                            FontWeight.bold))),
                              ],
                            ),
                            const Divider(),
                            ...incidencias.take(5).map((inc) {
                              final nodo = dashboard.firstWhere(
                                    (d) => d.tinacoId == inc.tinacoId,
                                orElse: () => NodoDashboard(
                                    tinacoId: 0,
                                    nombre: 'N/A',
                                    capacidadLitros: 0,
                                    porcentaje: 0,
                                    litros: 0),
                              );
                              return _buildFilaIncidente(
                                fecha:
                                '${inc.fechaCreacion.day}/${inc.fechaCreacion.month}',
                                nodo: nodo.nombre,
                                tipo: inc.tipo,
                                estado: inc.estado == 'EN_PROCESO'
                                    ? 'EN PROCESO'
                                    : inc.estado,
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: verHistorialCompleto,
                        child: const Text('VER HISTORIAL COMPLETO',
                            style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),


              ...dispositivos
                  .where((d) => d.estado != 'activo')
                  .map((d) => Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'REVISAR NODO ${d.esp32Id} POSIBLE FALLA CONEXIÓN',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodoFila(String nombre, String dato, Color color,
      double porcentaje, String etiqueta, bool critico) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(nombre, style: const TextStyle(fontSize: 13)),
            Text(dato,
                style: TextStyle(
                    fontSize: 13,
                    color: critico ? Colors.red : Colors.black,
                    fontWeight:
                    critico ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
                height: 24,
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4))),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: porcentaje,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  child: etiqueta.isNotEmpty
                      ? Text(etiqueta,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFilaIncidente({
    required String fecha,
    required String nodo,
    required String tipo,
    required String estado,
  }) {
    final estadoFinal = estado.toUpperCase().replaceAll('_', ' ').trim();
    Color estadoColor = estadoFinal == 'ABIERTA'
        ? Colors.red
        : estadoFinal == 'EN PROCESO'
        ? Colors.blue
        : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 60, child: Text(fecha, style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 8),
          SizedBox(
              width: 100,
              child: Text(nodo,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          SizedBox(
              width: 130,
              child: Text(tipo,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          SizedBox(
              width: 110,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildChip(estado, estadoColor))),
        ],
      ),
    );
  }
}

class HistorialIncidencias extends StatelessWidget {
  final List<Incidencia> incidencias;
  final List<NodoDashboard> dashboard;

  const HistorialIncidencias({
    super.key,
    required this.incidencias,
    required this.dashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Historial completo',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
        ),
      ),
      body: incidencias.isEmpty
          ? const Center(
          child: Text('Sin incidencias registradas',
              style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: incidencias.length,
        itemBuilder: (_, index) {
          final inc = incidencias[index];
          final nodo = dashboard.firstWhere(
                (d) => d.tinacoId == inc.tinacoId,
            orElse: () => NodoDashboard(
                tinacoId: 0,
                nombre: 'N/A',
                capacidadLitros: 0,
                porcentaje: 0,
                litros: 0),
          );
          final estadoColor = inc.estado == 'ABIERTA'
              ? Colors.red
              : inc.estado == 'EN_PROCESO'
              ? Colors.blue
              : Colors.green;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${inc.fechaCreacion.day}/${inc.fechaCreacion.month}/${inc.fechaCreacion.year}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: estadoColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        inc.estado.replaceAll('_', ' '),
                        style: TextStyle(
                            fontSize: 10,
                            color: estadoColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(nodo.nombre,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                Text(inc.tipo,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                if (inc.descripcion != null &&
                    inc.descripcion!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(inc.descripcion!,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}