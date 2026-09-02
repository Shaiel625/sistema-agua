import 'package:flutter/material.dart';
import 'objetivos_screen.dart';
import 'analisis_screen.dart';
import 'panel_control_screen.dart';
import 'dispositivos_screen.dart';
import 'nodos_screen.dart';

void main() {
  runApp(const SistemaApp());
}

class SistemaApp extends StatelessWidget {
  const SistemaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D1C6F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        useMaterial3: true,
      ),
      home: const NavegacionPrincipal(),
      routes: {
        '/panel': (context) => const PanelControlScreen(),
        '/nodos': (context) => const NodosScreen(),
        '/dispositivos': (context) =>
        const DispositivosScreen(),
        '/objetivos': (context) => const ObjetivosScreen(),
        '/analisis': (context) => const AnalisisScreen(),
      },
    );
  }
}

class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() =>
      _NavegacionPrincipalState();
}

class _NavegacionPrincipalState
    extends State<NavegacionPrincipal> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = const [
    PanelControlScreen(),
    DispositivosScreen(),
    ObjetivosScreen(),
    AnalisisScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indiceActual,
        children: _pantallas,
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: _indiceActual,
        onDestinationSelected: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Panel de control',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Dispositivos',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Objetivos',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Análisis',
          ),
        ],
      ),
    );
  }
}