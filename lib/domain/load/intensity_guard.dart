/// Garde-fou Intensité — pur Dart, sans dépendance plateforme.
///
/// Référence : FC instantanée vs FC@SV1 (mesurée, mode B) ou plafond
/// Karvonen ~70 % FCR (estimation de repli). Provenance portée
/// explicitement avec chaque valeur (PD-6).
library;

import 'calibration.dart';

// ── Prérequis de démarrage ────────────────────────────────────────────────────

class SessionStartCheck {
  const SessionStartCheck({
    required this.ageMissing,
    required this.hrRestMissing,
    this.sexMissing = false,
  });

  final bool ageMissing;
  final bool hrRestMissing;

  /// Requis uniquement pour le mode D (calcul TRIMP Banister).
  final bool sexMissing;

  bool get allowed => !ageMissing && !hrRestMissing && !sexMissing;

  List<String> get missingFields => [
        if (ageMissing) 'âge',
        if (hrRestMissing) 'FC de repos',
        if (sexMissing) 'sexe',
      ];
}

SessionStartCheck checkSessionStart({
  int? age,
  int? hrRest,
  bool checkSex = false,
  String? sex,
}) =>
    SessionStartCheck(
      ageMissing: age == null,
      hrRestMissing: hrRest == null,
      sexMissing: checkSex && sex == null,
    );

// ── Référence d'intensité ─────────────────────────────────────────────────────

enum IntensityRefProvenance {
  measuredSv1,        // fcSv1 mesurée en mode B
  estimatedKarvonen,  // plafond Karvonen ~70 % FCR (repli)
}

class IntensityRef {
  const IntensityRef({required this.bpmRef, required this.provenance});

  final int bpmRef;
  final IntensityRefProvenance provenance;

  String get label => provenance == IntensityRefProvenance.measuredSv1
      ? 'FC@SV1 mesurée'
      : 'Karvonen ~70 % FCR';
}

/// Cascade : fcSv1 mesurée mode B → Karvonen 70 % FCR.
/// Retourne null si les données manquent pour tout repli.
IntensityRef? computeIntensityRef({
  required int? hrRest,
  required int? hrMax,
  required int? age,
  required int? fcSv1,
  required String? thresholdProvenance,
}) {
  if (fcSv1 != null &&
      thresholdProvenance == ThresholdProvenance.measuredModeB.name) {
    return IntensityRef(
      bpmRef: fcSv1,
      provenance: IntensityRefProvenance.measuredSv1,
    );
  }
  if (hrRest == null) return null;
  final resolvedMax =
      hrMax ?? (age != null ? estimateHrMaxTanaka(age) : null);
  if (resolvedMax == null) return null;
  final ceiling = estimateAerobicCeilingKarvonen(
    hrRest: hrRest,
    hrMax: resolvedMax,
  );
  if (ceiling == null) return null;
  return IntensityRef(
    bpmRef: ceiling,
    provenance: IntensityRefProvenance.estimatedKarvonen,
  );
}

// ── Validation saisie manuelle ────────────────────────────────────────────────

bool isHrRestManualValid(int bpm) => bpm >= 35 && bpm <= 100;
bool isHrMaxManualValid(int bpm) => bpm >= 120 && bpm <= 220;

// ── OverrunTracker ────────────────────────────────────────────────────────────

class OverrunConfig {
  const OverrunConfig({
    required this.firstAlertThresholdSec,
    required this.repeatIntervalSec,
  });

  final int firstAlertThresholdSec;
  final int repeatIntervalSec;

  /// Mode A : première alerte à 10 s, répétition toutes les 30 s.
  static const modeA = OverrunConfig(
    firstAlertThresholdSec: 10,
    repeatIntervalSec: 30,
  );

  /// Mode D : première alerte à 60 s, répétition toutes les 60 s.
  static const modeD = OverrunConfig(
    firstAlertThresholdSec: 60,
    repeatIntervalSec: 60,
  );
}

class OverrunEvent {
  const OverrunEvent({required this.isFirst});
  final bool isFirst;
}

/// Suit le dépassement continu de la FC de référence et génère des alertes.
///
/// Pur Dart, sans timer ni DateTime.now() interne — chaque échantillon
/// est passé avec son horodatage pour une testabilité totale.
class OverrunTracker {
  OverrunTracker({required this.config, required this.refBpm});

  final OverrunConfig config;
  final int refBpm;

  bool _isOver = false;
  DateTime? _overrunStartedAt;
  DateTime? _lastAlertAt;
  int _totalOverMs = 0;
  int _totalUnderMs = 0;
  DateTime? _lastSampleAt;

  bool get isOver => _isOver;

  int get continuousOverrunSeconds {
    if (!_isOver || _overrunStartedAt == null || _lastSampleAt == null) {
      return 0;
    }
    return _lastSampleAt!.difference(_overrunStartedAt!).inSeconds;
  }

  int get totalOverSeconds => _totalOverMs ~/ 1000;
  int get totalUnderSeconds => _totalUnderMs ~/ 1000;

  /// Traite un échantillon FC. Retourne [OverrunEvent] si une alerte
  /// doit être déclenchée, null sinon.
  OverrunEvent? add(int hrBpm, DateTime at) {
    // Accumuler le temps depuis le dernier échantillon dans l'état précédent.
    if (_lastSampleAt != null) {
      final elapsed =
          at.difference(_lastSampleAt!).inMilliseconds.clamp(0, 5000);
      if (_isOver) {
        _totalOverMs += elapsed;
      } else {
        _totalUnderMs += elapsed;
      }
    }
    _lastSampleAt = at;

    final nowOver = hrBpm > refBpm;
    if (nowOver != _isOver) {
      _isOver = nowOver;
      _overrunStartedAt = nowOver ? at : null;
      _lastAlertAt = null;
    }

    if (!_isOver || _overrunStartedAt == null) return null;

    final overSec = at.difference(_overrunStartedAt!).inSeconds;
    if (_lastAlertAt == null && overSec >= config.firstAlertThresholdSec) {
      _lastAlertAt = at;
      return const OverrunEvent(isFirst: true);
    }
    if (_lastAlertAt != null &&
        at.difference(_lastAlertAt!).inSeconds >= config.repeatIntervalSec) {
      _lastAlertAt = at;
      return const OverrunEvent(isFirst: false);
    }
    return null;
  }

  void reset() {
    _isOver = false;
    _overrunStartedAt = null;
    _lastAlertAt = null;
    _totalOverMs = 0;
    _totalUnderMs = 0;
    _lastSampleAt = null;
  }
}
