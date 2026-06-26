import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Point d'entrée du service de premier plan.
/// Doit être une fonction top-level et annoté vm:entry-point.
@pragma('vm:entry-point')
void foregroundServiceCallback() {
  FlutterForegroundTask.setTaskHandler(AyurTaskHandler());
}

/// Gardien minimaliste : maintient le processus Android vivant (type connectedDevice)
/// pour que la connexion BLE et l'accumulation HRV dans l'isolate principal continuent
/// écran éteint. Aucune logique métier ici.
class AyurTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
