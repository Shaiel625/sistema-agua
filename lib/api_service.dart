
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: reemplaza esta URL por la de TU backend una vez desplegado
  // en Render (Paso 3 del README). Ejemplo:
  // 'https://sistema-XXXX.onrender.com'
  static const String baseUrl = 'https://sistema-pchh.onrender.com';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  dynamic _decodificar(http.Response response) {
    final String contenido = utf8.decode(response.bodyBytes);
    if (contenido.trim().isEmpty) {
      return null;
    }
    return jsonDecode(contenido);
  }
  Exception _crearError(
      String accion,
      http.Response response,
      ) { return Exception( '$accion\n' 'Código HTTP: ${response.statusCode}\n' '${utf8.decode(response.bodyBytes)}',);
  }
  List<Map<String, dynamic>> _convertirLista(
      dynamic data,
      ) {
    if (data is! List) {
      return [];
    }
    return data
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }
  Map<String, dynamic> _convertirMapa(
      dynamic data,
      ) { if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  Future<Map<String, dynamic>> obtenerDatosDePython() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirMapa(
        _decodificar(response),
      );
    }
    throw _crearError(
      'No se pudo conectar con el servidor',
      response,
    );
  }
  Future<List<Map<String, dynamic>>>
  obtenerDispositivos() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/dispositivos/'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }
    throw _crearError(
      'No se pudieron cargar los dispositivos',
      response,
    );
  }
  Future<Map<String, dynamic>> registrarDispositivo({
    required String esp32Id,
    required String estado,
  }) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/dispositivos/'),
      headers: _headers,
      body: jsonEncode({
        'esp32_id': esp32Id,
        'estado': estado,
      }),
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return _convertirMapa(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudo registrar el dispositivo',
      response,
    );
  }
  Future<List<Map<String, dynamic>>>
  obtenerEdificios() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/edificios/'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudieron cargar los edificios',
      response,
    );
  }
  Future<List<Map<String, dynamic>>>
  obtenerTinacos() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/tinacos/'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }
    throw _crearError(
      'No se pudieron cargar los tinacos',
      response,
    );
  }
  Future<Map<String, dynamic>?> obtenerUltimaLectura(
      int tinacoId,
      ) async {
    final response = await http
        .get(
      Uri.parse(
        '$baseUrl/tinacos/$tinacoId/ultima-lectura',
      ),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final dynamic data = _decodificar(response);

      if (data is! Map) {
        return null;
      }
      final mapa = Map<String, dynamic>.from(data);

      if (mapa.containsKey('mensaje')) {
        return null;
      }
      return mapa;
    }

    if (response.statusCode == 404) {
      return null;
    }
    throw _crearError(
      'No se pudo obtener la última lectura',
      response,
    );
  }
  Future<List<Map<String, dynamic>>> obtenerHistorial(
      int tinacoId,
      ) async {
    final response = await http
        .get(
      Uri.parse(
        '$baseUrl/tinacos/$tinacoId/historial',
      ),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudo cargar el historial del tinaco',
      response,
    );
  }
  Future<List<Map<String, dynamic>>>
  obtenerLecturas() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/lecturas/'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudieron cargar las lecturas',
      response,
    );
  }

  Future<List<Map<String, dynamic>>>
  obtenerResumenTinacos() async {
    final tinacos = await obtenerTinacos();

    return Future.wait(
      tinacos.map((tinaco) async {
        final dynamic idValue = tinaco['id'];

        final int? tinacoId = idValue is int
            ? idValue
            : int.tryParse(idValue?.toString() ?? '');

        if (tinacoId == null) {
          return {
            ...tinaco,
            'porcentaje': 0.0,
            'litros': 0.0,
            'tiene_lectura': false,
          };
        }

        try {
          final lectura =
          await obtenerUltimaLectura(tinacoId);

          return {
            ...tinaco,
            'porcentaje':
            lectura?['porcentaje'] ?? 0.0,
            'litros': lectura?['litros'] ?? 0.0,
            'fecha_lectura': lectura?['fecha'],
            'tiene_lectura': lectura != null,
          };
        } catch (_) {
          return {
            ...tinaco,
            'porcentaje': 0.0,
            'litros': 0.0,
            'tiene_lectura': false,
          };
        }
      }),
    );
  }
  Future<List<Map<String, dynamic>>>
  obtenerDashboard() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/dashboard/'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudo cargar el dashboard',
      response,
    );
  }
  Future<Map<String, dynamic>>
  obtenerEstadisticas() async {
    final response = await http
        .get(
      Uri.parse(
        '$baseUrl/dashboard/estadisticas',
      ),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirMapa(
        _decodificar(response),
      );
    }
    throw _crearError(
      'No se pudieron cargar las estadísticas',
      response,
    );
  }
  Future<Map<String, dynamic>>
  obtenerResumenIncidencias() async {
    final response = await http
        .get(
      Uri.parse(
        '$baseUrl/dashboard/incidencias',
      ),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return _convertirMapa(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudo obtener el resumen de incidencias',
      response,
    );
  }

  Future<bool> actualizarEstadoDispositivo({
    required String esp32Id,
    required String nuevoEstado,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/dispositivos/$esp32Id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'estado': nuevoEstado,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error en API al actualizar estado: $e');
      return false;
    }
  }
  Future<List<Map<String, dynamic>>>
  obtenerTinacosCriticos() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/dashboard/criticos'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudieron cargar los tinacos críticos',
      response,
    );
  }
  Future<List<Map<String, dynamic>>>
  obtenerIncidencias() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/incidencias/'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }
    throw _crearError(
      'No se pudieron cargar las incidencias',
      response,
    );
  }
  Future<List<Map<String, dynamic>>>
  obtenerHistorialIncidencias() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/incidencias/historial'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }
    throw _crearError(
      'No se pudo cargar el historial de incidencias',
      response,
    );
  }

  Future<Map<String, dynamic>> obtenerIncidencia(
      int incidenciaId,
      ) async {
    final response = await http
        .get(
      Uri.parse(
        '$baseUrl/incidencias/$incidenciaId',
      ),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return _convertirMapa(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudo cargar la incidencia',
      response,
    );
  }
  Future<Map<String, dynamic>> crearIncidencia({
    required int tinacoId,
    required String tipo,
    String? descripcion,
    String prioridad = 'MEDIA',
    int? tiempoEstimadoMinutos,
  }) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/incidencias/'),
      headers: _headers,
      body: jsonEncode({
        'tinaco_id': tinacoId,
        'tipo': tipo,
        'descripcion': descripcion,
        'prioridad': prioridad,
        'tiempo_estimado_minutos':
        tiempoEstimadoMinutos,
      }),
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return _convertirMapa(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudo crear la incidencia',
      response,
    );
  }
  Future<List<Map<String, dynamic>>>
  obtenerAcciones() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/acciones/'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }
    throw _crearError(
      'No se pudieron cargar las acciones',
      response,
    );
  }
  Future<List<Map<String, dynamic>>>
  obtenerAccionesIncidencia(
      int incidenciaId,
      ) async {
    final response = await http
        .get(
      Uri.parse(
        '$baseUrl/acciones/incidencia/$incidenciaId',
      ),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudo cargar el historial de acciones',
      response,
    );
  }
  Future<List<Map<String, dynamic>>>
  obtenerMateriales() async {
    final response = await http
        .get(
      Uri.parse('$baseUrl/materiales/'),
      headers: _headers,
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return _convertirLista(
        _decodificar(response),
      );
    }

    throw _crearError(
      'No se pudieron cargar los materiales',
      response,
    );
  }
  Future<Map<String, dynamic>> iniciarIncidencia(
      int incidenciaId,
      ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/incidencias/$incidenciaId/iniciar',
      ),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        _decodificar(response),
      );
    }
    throw _crearError(
      'No se pudo iniciar la incidencia',
      response,
    );
  }
  Future<Map<String, dynamic>> finalizarIncidencia(
      int incidenciaId,
      ) async {
    final response = await http.post(
      Uri.parse(
        '$baseUrl/incidencias/$incidenciaId/finalizar',
      ),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        _decodificar(response),
      );
    }
    throw _crearError(
      'No se pudo finalizar la incidencia',
      response,
    );
  }
  Future<bool> actualizarEstadoTarea(int id, String nuevoEstado) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/alertas/$id/estado'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'estado': nuevoEstado,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error conectando con el backend: $e");
      return false;
    }
  }
  Future<void> asignarMaterial({
    required int incidenciaId,
    required int materialId,
    required int cantidad,
  }) async {
    final response = await http
        .post(
      Uri.parse('$baseUrl/materiales/asignar'),
      headers: _headers,
      body: jsonEncode({
        'incidencia_id': incidenciaId,
        'material_id': materialId,
        'cantidad': cantidad,
      }),
    )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw _crearError(
        'No se pudo asignar el material',
        response,
      );
    }

  }
}