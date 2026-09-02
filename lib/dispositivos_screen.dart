import 'package:flutter/material.dart';
import 'api_service.dart';
import 'nodos_screen.dart';

class DispositivosScreen extends StatefulWidget {
  const DispositivosScreen({super.key});

  @override
  State<DispositivosScreen> createState() =>
      _DispositivosScreenState();
}

class _DispositivosScreenState extends State<DispositivosScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late Future<List<Map<String, dynamic>>> _dispositivos;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  final TransformationController _mapController =
  TransformationController();

  final List<Map<String, dynamic>> _edificios = [
    {'nombre': 'EDIF1', 'x': 0.52, 'y': 0.07},
    {'nombre': 'EDIF2', 'x': 0.70, 'y': 0.17},
    {'nombre': 'EDIF3', 'x': 0.90, 'y': 0.38},
    {'nombre': 'EDIF4', 'x': 0.60, 'y': 0.31},
    {'nombre': 'EDIF5', 'x': 0.43, 'y': 0.26},
    {'nombre': 'EDIF6', 'x': 0.25, 'y': 0.34},
    {'nombre': 'EDIF7', 'x': 0.03, 'y': 0.20},
    {'nombre': 'EDIF8', 'x': 0.24, 'y': 0.48},
    {'nombre': 'EDIF9', 'x': 0.34, 'y': 0.60},
    {'nombre': 'EDIF10', 'x': 0.46, 'y': 0.48, 'administracion': true},
    {'nombre': 'EDIF11', 'x': 0.70, 'y': 0.60},
    {'nombre': 'EDIF12', 'x': 0.54, 'y': 0.72},
    {'nombre': 'EDIF13', 'x': 0.13, 'y': 0.65},
    {'nombre': 'EDIF14', 'x': 0.31, 'y': 0.84},
    {'nombre': 'EDIF15', 'x': 0.03, 'y': 0.43},
    {'nombre': 'EDIF16', 'x': 0.78, 'y': 0.88},
    {'nombre': 'EDIF17', 'x': 0.45, 'y': 0.88},
    {'nombre': 'EDIF18', 'x': 0.94, 'y': 0.63},
    {'nombre': 'EDIF19', 'x': 0.07, 'y': 0.90},
    {'nombre': 'EDIF20', 'x': 0.62, 'y': 0.90},
  ];

  @override
  void initState() {
    super.initState();
    _dispositivos = _apiService.obtenerDispositivos();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _pulseAnimation = Tween<double>(begin: 0.90, end: 1.16).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _recargarDispositivos() {
    setState(() {
      _dispositivos = _apiService.obtenerDispositivos();
    });
  }

  Future<void> _actualizarDispositivos() async {
    _recargarDispositivos();
    await _dispositivos;
  }

  Future<void> _abrirRegistroNodo() async {
    final bool? guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const NodosScreen()),
    );
    if (guardado == true && mounted) {
      _recargarDispositivos();
    }
  }

  Color _colorEstado(String estado) {
    final value = estado.toLowerCase();
    if (value.contains('alerta') || value.contains('fuga')) {
      return const Color(0xFFD91E2E);
    }
    if (value.contains('activo') || value.contains('saludable')) {
      return const Color(0xFF23B26D);
    }
    return const Color(0xFF9A9AA0);
  }

  IconData _iconoEstado(String estado) {
    final value = estado.toLowerCase();
    if (value.contains('alerta') || value.contains('fuga')) {
      return Icons.warning_amber_rounded;
    }
    if (value.contains('activo') || value.contains('saludable')) {
      return Icons.sensors;
    }
    return Icons.signal_wifi_connected_no_internet_4;
  }

  String _textoEstado(String estado) {
    final value = estado.toLowerCase();
    if (value.contains('alerta') || value.contains('fuga')) {
      return 'ALERTA';
    }
    if (value.contains('activo') || value.contains('saludable')) {
      return 'SALUDABLE';
    }
    return 'SIN SEÑAL';
  }

  Map<String, dynamic>? _dispositivoPorEdificio(
      List<Map<String, dynamic>> dispositivos, int edificioIndex) {
    if (edificioIndex >= dispositivos.length) return null;
    return dispositivos[edificioIndex];
  }

  Future<bool?> _mostrarConfirmacion({
    required String titulo,
    required String mensaje,
    required Color colorBoton,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1C6F),
            ),
          ),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorBoton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('CONFIRMAR'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarInformacionEdificio({
    required String edificio,
    required Map<String, dynamic>? dispositivo,
  }) {
    final String estado = dispositivo?['estado']?.toString() ?? 'sin nodo';
    final String idNodo = dispositivo?['esp32_id']?.toString() ?? 'No asignado';
    final bool esCritico = _esCritico(estado);
    final Color color = dispositivo == null ? Colors.grey : _colorEstado(estado);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(
                      dispositivo == null ? Icons.location_city : _iconoEstado(estado),
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      edificio,
                      style: const TextStyle(
                        color: Color(0xFF0D1C6F),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _infoRow('ID del nodo', idNodo),
              const Divider(),
              _infoRow(
                'Estado',
                dispositivo == null ? 'SIN NODO ASIGNADO' : _textoEstado(estado),
                valueColor: color,
              ),
              const SizedBox(height: 20),

              if (dispositivo == null) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _abrirRegistroNodo();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1C6F),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('ASIGNAR NODO'),
                ),
              ] else if (esCritico) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    final bool? aceptar = await _mostrarConfirmacion(
                      titulo: '¿Iniciar Reparación/Atención?',
                      mensaje: 'El estado del nodo cambiará a "En proceso".',
                      colorBoton: const Color(0xFFE67E22),
                    );
                    if (aceptar == true && mounted) {
                      Navigator.pop(context);
                      final bool exito = await _apiService.actualizarEstadoDispositivo(
                        esp32Id: idNodo,
                        nuevoEstado: 'en proceso',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              exito
                                  ? ' Estado actualizado a "En proceso"'
                                  : ' No se pudo actualizar el estado en el servidor.',
                            ),
                            backgroundColor: exito ? const Color(0xFFE67E22) : Colors.red,
                          ),
                        );
                      }
                      _recargarDispositivos();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E22),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.build_outlined),
                  label: const Text('ATENDER / INICIAR TAREA'),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final bool? aceptar = await _mostrarConfirmacion(
                      titulo: '¿Resolver Incidencia?',
                      mensaje: 'Se confirmará que la anomalía fue reparada con éxito.',
                      colorBoton: const Color(0xFF23B26D),
                    );
                    if (aceptar == true && mounted) {
                      Navigator.pop(context);
                      final bool exito = await _apiService.actualizarEstadoDispositivo(
                        esp32Id: idNodo,
                        nuevoEstado: 'saludable',
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              exito
                                  ? ' Incidencia resuelta. Nodo en estado Saludable.'
                                  : ' Ocurrió un error al actualizar en el servidor.',
                            ),
                            backgroundColor: exito ? const Color(0xFF23B26D) : Colors.red,
                          ),
                        );
                      }
                      _recargarDispositivos();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF23B26D),
                    side: const BorderSide(color: Color(0xFF23B26D), width: 1.5),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('MARCAR COMO RESUELTO / OK'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF0D1C6F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _restablecerMapa() {
    _mapController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.water_drop_outlined, color: Color(0xFF0D1C6F)),
            SizedBox(width: 5),
            Text(
              'sistema',
              style: TextStyle(
                color: Color(0xFF0D1C6F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _recargarDispositivos,
            icon: const Icon(Icons.refresh, color: Color(0xFF0D1C6F)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirRegistroNodo,
        backgroundColor: const Color(0xFF0D1C6F),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _actualizarDispositivos,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _dispositivos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _errorWidget(snapshot.error.toString());
            }
            final dispositivos = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                _buildMapa(dispositivos),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Nodos Inteligentes',
                          style: TextStyle(
                            color: Color(0xFF0D1C6F),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _restablecerMapa,
                        icon: const Icon(Icons.center_focus_strong),
                        tooltip: 'Centrar mapa',
                      ),
                    ],
                  ),
                ),
                _buildLeyenda(),
                const SizedBox(height: 10),
                if (dispositivos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Text(
                          'No hay nodos registrados.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < dispositivos.length; i++)
                    _buildTarjetaNodo(dispositivos[i], i),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapa(List<Map<String, dynamic>> dispositivos) {
    return Container(
      height: 430,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InteractiveViewer(
            transformationController: _mapController,
            minScale: 0.5,
            maxScale: 3,
            boundaryMargin: const EdgeInsets.all(80),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                return SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _CampusBackgroundPainter()),
                      ),
                      Positioned(
                        left: width * 0.10,
                        top: height * 0.03,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NODOS DE SANITARIOS',
                            style: TextStyle(
                              color: Color(0xFF3869C8),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      for (int i = 0; i < _edificios.length; i++)
                        Positioned(
                          left: width * (_edificios[i]['x'] as double),
                          top: height * (_edificios[i]['y'] as double),
                          child: _buildEdificioAnimado(
                            edificio: _edificios[i],
                            dispositivo: _dispositivoPorEdificio(dispositivos, i),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.zoom_in, size: 16, color: Color(0xFF0D1C6F)),
                  SizedBox(width: 4),
                  Text('Pellizca para acercar', style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEdificioAnimado({
    required Map<String, dynamic> edificio,
    required Map<String, dynamic>? dispositivo,
  }) {
    final bool administracion = edificio['administracion'] == true;
    final String estado = dispositivo?['estado']?.toString() ?? 'sin nodo';
    final Color color = administracion
        ? Colors.grey.shade700
        : dispositivo == null
        ? const Color(0xFF4774C8)
        : _colorEstado(estado);

    return GestureDetector(
      onTap: () {
        _mostrarInformacionEdificio(
          edificio: edificio['nombre'] as String,
          dispositivo: dispositivo,
        );
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final bool tieneAlerta =
              dispositivo != null && color == const Color(0xFFD91E2E);
          return Transform.scale(
            scale: tieneAlerta ? _pulseAnimation.value : 1,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: administracion ? 105 : 66,
          height: administracion ? 48 : 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: dispositivo == null ? 3 : 10,
                spreadRadius: dispositivo == null ? 0 : 1,
              ),
            ],
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                administracion ? 'EDIF 10\nADMINISTRACIÓN' : edificio['nombre'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (dispositivo != null)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color, blurRadius: 5),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeyenda() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: const [
          _LegendItem(color: Color(0xFF23B26D), text: 'Activo'),
          _LegendItem(color: Color(0xFFD91E2E), text: 'Alerta'),
          _LegendItem(color: Color(0xFF9A9AA0), text: 'Sin señal'),
          _LegendItem(color: Color(0xFF4774C8), text: 'Sin nodo'),
        ],
      ),
    );
  }

  bool _esCritico(String estado) {
    final value = estado.toLowerCase();
    return value.contains('alerta') ||
        value.contains('fuga') ||
        value.contains('desbordamiento') ||
        value.contains('bajo nivel');
  }


  Widget _buildTarjetaNodo(Map<String, dynamic> dispositivo, int index) {
    final String id = dispositivo['id']?.toString() ?? '-';
    final String esp32Id = dispositivo['esp32_id']?.toString() ?? 'SIN ID';
    final String estado = dispositivo['estado']?.toString() ?? 'sin señal';
    final String edificio = dispositivo['nombre'] ?? 'Edificio no asignado';
    final String ubicacion = dispositivo['ubicacion'] ?? 'Ubicación no asignada';

    final bool esCritico = _esCritico(estado);
    final Color color = _colorEstado(estado);
    final Color colorFondo = esCritico ? const Color(0xFFFFF2F3) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color,
          width: esCritico ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: esCritico ? 0.25 : 0.04),
            blurRadius: esCritico ? 14 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _mostrarInformacionEdificio(
            edificio: edificio,
            dispositivo: dispositivo,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (esCritico) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD91E2E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'CRÍTICO - REQUIERE ATENCIÓN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(_iconoEstado(estado), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esp32Id,
                          style: TextStyle(
                            color: esCritico ? const Color(0xFF7A000A) : const Color(0xFF0D1C6F),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$edificio - $ubicacion • ID registro: $id',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _textoEstado(estado),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _errorWidget(String error) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off, color: Colors.red, size: 65),
        const SizedBox(height: 15),
        Text('No se pudieron cargar los nodos.\n$error', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: _recargarDispositivos, child: const Text('Reintentar')),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

class _CampusBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = const Color(0xFFF0F2F8)..strokeWidth = 1;
    const double step = 35;
    for (double x = 0; x < size.width; x += step) canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    for (double y = 0; y < size.height; y += step) canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    final routePaint = Paint()..color = const Color(0xFFDCE4F5)..strokeWidth = 3..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.07, size.height * 0.50)
      ..quadraticBezierTo(size.width * 0.40, size.height * 0.42, size.width * 0.55, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.70, size.height * 0.72, size.width * 0.94, size.height * 0.58);
    canvas.drawPath(path, routePaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}