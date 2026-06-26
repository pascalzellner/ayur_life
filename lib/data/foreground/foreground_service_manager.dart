import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'foreground_service.dart';

// ---------------------------------------------------------------------------
// Provider d'état : enregistrement long en cours ?
// ---------------------------------------------------------------------------

class RecordingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void mettreAJour(bool valeur) => state = valeur;
}

final isRecordingProvider = NotifierProvider<RecordingNotifier, bool>(
  RecordingNotifier.new,
);

// ---------------------------------------------------------------------------
// Provider gestionnaire du service de premier plan
// ---------------------------------------------------------------------------

final foregroundServiceManagerProvider = Provider<ForegroundServiceManager>(
  (ref) => ForegroundServiceManager(ref),
);

class ForegroundServiceManager {
  ForegroundServiceManager(this._ref) {
    _init();
    // Synchronise l'état au démarrage (reprise après hot-restart ou redémarrage OS).
    FlutterForegroundTask.isRunningService.then(
      (actif) => _ref.read(isRecordingProvider.notifier).mettreAJour(actif),
    );
  }

  final Ref _ref;
  DateTime? _derniereMiseAJourNotif;

  void _init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'ayur_life_acquisition',
        channelName: 'Enregistrement Ayur Life',
        channelDescription:
            "Active pendant l'acquisition longue du capteur cardiaque.",
        channelImportance: NotificationChannelImportance.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
        allowAutoRestart: true,
      ),
    );
  }

  Future<bool> get ignoresBatterie =>
      FlutterForegroundTask.isIgnoringBatteryOptimizations;

  /// Demande l'exclusion d'optimisation batterie via le dialogue système Android.
  Future<bool> demanderExclusionBatterie() async {
    if (!Platform.isAndroid) {
      return true;
    }
    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      return true;
    }
    return FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  /// Ouvre les réglages batterie Android (utile pour MIUI qui a sa propre surcouche).
  Future<bool> ouvrirReglagesBatterie() =>
      FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();

  Future<ServiceRequestResult> demarrerEnregistrement() async {
    final result = await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.connectedDevice],
      serviceId: 1001,
      notificationTitle: 'Ayur Life — Enregistrement actif',
      notificationText: 'Connexion au capteur…',
      callback: foregroundServiceCallback,
    );
    if (result is ServiceRequestSuccess) {
      _ref.read(isRecordingProvider.notifier).mettreAJour(true);
    }
    return result;
  }

  Future<ServiceRequestResult> arreterEnregistrement() async {
    final result = await FlutterForegroundTask.stopService();
    _ref.read(isRecordingProvider.notifier).mettreAJour(false);
    return result;
  }

  /// Met à jour la notification avec la FC et le RMSSD en direct, cadencé à 3 s max
  /// pour éviter de saturer le binder Android à chaque battement.
  void mettreAJourNotification({required int hr, required double rmssd}) {
    if (!_ref.read(isRecordingProvider)) {
      return;
    }
    final maintenant = DateTime.now();
    final derniere = _derniereMiseAJourNotif;
    if (derniere != null &&
        maintenant.difference(derniere).inSeconds < 3) {
      return;
    }
    _derniereMiseAJourNotif = maintenant;
    final rmssdStr = rmssd.isNaN ? '—' : rmssd.toStringAsFixed(1);
    FlutterForegroundTask.updateService(
      notificationTitle: 'Ayur Life — Enregistrement actif',
      notificationText: '$hr bpm  •  RMSSD $rmssdStr ms',
    );
  }
}
