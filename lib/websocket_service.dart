import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

class WebSocketService {
  late WebSocketChannel _channel;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  WebSocketService() {
    _inicializarNotificaciones();
  }

  void _inicializarNotificaciones() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  void conectar(String urlBackend) {

    _channel = WebSocketChannel.connect(Uri.parse(urlBackend));

    _channel.stream.listen(
          (mensaje) {
        debugPrint('¡Alerta del ESP32 recibida!: $mensaje');
        _procesarAlerta(mensaje);
      },
      onDone: () => debugPrint('Conexión WebSocket cerrada'),
      onError: (error) => debugPrint('Error en WebSocket: $error'),
    );
  }

  void _procesarAlerta(String mensaje) async {
    try {
      final data = jsonDecode(mensaje);

      final String tipoAlerta = data['tipo'] ?? 'Alerta general';
      final String descripcion = data['descripcion'] ?? 'El sensor ESP32 ha detectado una anomalía.';
      final int tinacoId = int.tryParse(data['tinaco_id']?.toString() ?? '') ?? 1;
      _mostrarNotificacionPush('¡Atención: $tipoAlerta!', descripcion);

      await _apiService.crearIncidencia(
        tinacoId: tinacoId,
        tipo: tipoAlerta,
        descripcion: descripcion,
      );

      debugPrint('Incidencia registrada con éxito en la base de datos.');
    } catch (e) {
      debugPrint('Error al procesar la alerta: $e');
    }
  }

  Future<void> _mostrarNotificacionPush(String titulo, String cuerpo) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'canal_alertas_criticas',
      'Alertas Críticas',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      titulo,
      cuerpo,
      platformDetails,
    );
  }
  void desconectar() {
    _channel.sink.close();
  }
}