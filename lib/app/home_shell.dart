import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../shared/services/analytics_service.dart';
import '../shared/widgets/bottom_nav_bar.dart';

/// Contenedor de la app: barra inferior y las cinco pestañas en un
/// [IndexedStack] (no se destruyen al cambiar de pestaña).
///
/// Cada encargado reemplaza SOLO el placeholder de su pestaña por su pantalla
/// (y agrega su import). Cada cambio de pestaña registra la vista en Analytics.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HomeTab _tab = HomeTab.dashboard;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<AnalyticsService>().logScreen(_tab.screenName));
  }

  void _selectTab(HomeTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    context.read<AnalyticsService>().logScreen(tab.screenName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab.index,
          children: const [
            // ── Gisi: DashboardScreen ──
            _Placeholder('Pantalla de Gisi (Tareas)'),
            // ── Alex M.: PomodoroScreen ──
            _Placeholder('Pantalla de Alex M. (Pomodoro)'),
            // ── Nehemías: NewTaskScreen ──
            _Placeholder('Pantalla de Nehemías (Nueva tarea)'),
            // ── Alex: CameraScreen ──
            _Placeholder('Pantalla de Alex (Cámara)'),
            // ── Armando: FeedScreen ──
            _Placeholder('Pantalla de Armando (Feed)'),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(selected: _tab, onSelected: _selectTab),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}
