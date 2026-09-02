import 'package:flutter/material.dart';
import 'api_service.dart';

class PruebaConexionScreen extends StatefulWidget {
  const PruebaConexionScreen({super.key});

  @override
  State<PruebaConexionScreen> createState() => _PruebaConexionScreenState();
}

class _PruebaConexionScreenState extends State<PruebaConexionScreen> {

  final ApiService _apiService = ApiService();


  late Future<Map<String, dynamic>> _datosDePython;

  @override
  void initState() {
    super.initState();

    _datosDePython = _apiService.obtenerDatosDePython();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Probando Conexión con Python'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _datosDePython,
        builder: (context, snapshot) {


          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }


          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  ' ¡Error de conexión!\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }


          else if (snapshot.hasData) {

            final datos = snapshot.data!;
            final textoMostrar = datos['mensaje'] ?? 'No se encontró la clave mensaje';

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    'Respuesta del Servidor:',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    textoMostrar,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Sin estado inicial'));
        },
      ),
    );
  }
}