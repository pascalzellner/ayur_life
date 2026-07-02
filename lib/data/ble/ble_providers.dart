import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/user_id_service.dart';
import '../../domain/hrv/live_hrv_accumulator.dart';
import '../../domain/hrv/poincare.dart';
import '../../domain/load/calibration.dart';
import '../../domain/load/intensity_guard.dart';
import '../../domain/load/trimp.dart';
import '../foreground/foreground_service_manager.dart';
import '../local/app_database.dart';
import '../local/local_providers.dart';
import 'ble_heart_rate_repository.dart';
import 'heart_rate_parser.dart';

final bleRepositoryProvider = Provider<BleHeartRateRepository>(
  (ref) => BleHeartRateRepository(),
);

final adapterStateProvider = StreamProvider<BluetoothAdapterState>(
  (ref) => ref.watch(bleRepositoryProvider).adapterState,
);

final scanResultsProvider = StreamProvider.autoDispose<List<ScanResult>>(
  (ref) => ref.watch(bleRepositoryProvider).scanResults,
);

final isScanningProvider = StreamProvider.autoDispose<bool>(
  (ref) => ref.watch(bleRepositoryProvider).isScanning,
);

enum ConnStatus { idle, connecting, connected, reconnecting, error }

/// État affiché par l'écran de debug.
class AcquisitionState {
  final ConnStatus status;
  final String? deviceName;
  final int? batteryPercent;
  final int lastHr;
  final List<double> lastRrMs;
  final double rmssd;
  final double artifactRatio;
  final int beatsInWindow;
  final int totalBeats;
  final bool lastWasArtifact;
  final String? error;

  // ── Session ouverte ──────────────────────────────────────────────────────────
  /// true dès que startRecording a ouvert une session en base, false après
  /// stopRecording. Fiable pour tous les modes (A/C/D) — contrairement à
  /// isRecordingProvider qui ne couvre que le service de premier plan (A/D).
  final bool isSessionActive;

  // ── Garde-fou Intensité ──────────────────────────────────────────────────────
  final int? intensityRefBpm;
  final String? intensityRefLabel;
  final bool isOverRef;
  final int continuousOverrunSec;
  final int totalOverRefSec;
  final int totalUnderRefSec;

  const AcquisitionState({
    this.status = ConnStatus.idle,
    this.deviceName,
    this.batteryPercent,
    this.lastHr = 0,
    this.lastRrMs = const [],
    this.rmssd = double.nan,
    this.artifactRatio = 0.0,
    this.beatsInWindow = 0,
    this.totalBeats = 0,
    this.lastWasArtifact = false,
    this.error,
    this.isSessionActive = false,
    this.intensityRefBpm,
    this.intensityRefLabel,
    this.isOverRef = false,
    this.continuousOverrunSec = 0,
    this.totalOverRefSec = 0,
    this.totalUnderRefSec = 0,
  });

  AcquisitionState copyWith({
    ConnStatus? status,
    String? deviceName,
    int? batteryPercent,
    int? lastHr,
    List<double>? lastRrMs,
    double? rmssd,
    double? artifactRatio,
    int? beatsInWindow,
    int? totalBeats,
    bool? lastWasArtifact,
    String? error,
    bool? isSessionActive,
    // Champs intensité — non nullable passés avec ??
    bool? isOverRef,
    int? continuousOverrunSec,
    int? totalOverRefSec,
    int? totalUnderRefSec,
    // Champs nullable intensité — passés tels quels (permet null explicite)
    int? intensityRefBpm,
    String? intensityRefLabel,
    bool clearIntensityRef = false,
  }) {
    return AcquisitionState(
      status: status ?? this.status,
      deviceName: deviceName ?? this.deviceName,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      lastHr: lastHr ?? this.lastHr,
      lastRrMs: lastRrMs ?? this.lastRrMs,
      rmssd: rmssd ?? this.rmssd,
      artifactRatio: artifactRatio ?? this.artifactRatio,
      beatsInWindow: beatsInWindow ?? this.beatsInWindow,
      totalBeats: totalBeats ?? this.totalBeats,
      lastWasArtifact: lastWasArtifact ?? this.lastWasArtifact,
      error: error,
      isSessionActive: isSessionActive ?? this.isSessionActive,
      isOverRef: isOverRef ?? this.isOverRef,
      continuousOverrunSec: continuousOverrunSec ?? this.continuousOverrunSec,
      totalOverRefSec: totalOverRefSec ?? this.totalOverRefSec,
      totalUnderRefSec: totalUnderRefSec ?? this.totalUnderRefSec,
      intensityRefBpm:
          clearIntensityRef ? null : (intensityRefBpm ?? this.intensityRefBpm),
      intensityRefLabel: clearIntensityRef
          ? null
          : (intensityRefLabel ?? this.intensityRefLabel),
    );
  }
}

final acquisitionProvider =
    NotifierProvider<AcquisitionController, AcquisitionState>(
  AcquisitionController.new,
);

class AcquisitionController extends Notifier<AcquisitionState> {
  final LiveHrvAccumulator _hrv = LiveHrvAccumulator();

  BluetoothDevice? _device;
  StreamSubscription<HeartRateSample>? _sampleSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  bool _userWantsConnection = false;

  // ── Persistance ───────────────────────────────────────────────────────────
  int? _sessionId;
  DateTime? _sessionStartedAt;
  String _currentMode = 'D';
  final List<({int tMs, double rr, bool gap})> _pendingRr = [];
  Timer? _flushTimer;
  bool _needsGapMarker = false;

  // ── Garde-fou Intensité ───────────────────────────────────────────────────
  OverrunTracker? _overrunTracker;
  int? _fcSv2ForOpportunistic;
  bool _opportunisticCaptured = false;

  // ── TRIMP Banister (mode D) ───────────────────────────────────────────────
  int? _trimpHrRest;
  int? _trimpHrMax;
  String? _trimpSex;

  @override
  AcquisitionState build() {
    ref.onDispose(_cleanup);
    return const AcquisitionState();
  }

  BleHeartRateRepository get _repo => ref.read(bleRepositoryProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<void> connect(BluetoothDevice device) async {
    _userWantsConnection = true;
    _device = device;
    _hrv.reset();
    state = state.copyWith(
      status: ConnStatus.connecting,
      deviceName: device.platformName.isEmpty
          ? device.remoteId.str
          : device.platformName,
      error: null,
    );

    _connSub?.cancel();
    _connSub = device.connectionState.listen((s) async {
      if (s == BluetoothConnectionState.disconnected &&
          _userWantsConnection &&
          state.status == ConnStatus.connected) {
        state = state.copyWith(status: ConnStatus.reconnecting);
        if (_sessionId != null && _sessionStartedAt != null) {
          _needsGapMarker = true;
        }
        await _tryConnect(device);
      }
    });

    await _tryConnect(device);
  }

  Future<void> _tryConnect(BluetoothDevice device) async {
    if (!_userWantsConnection) return;
    try {
      final ch = await _repo.connectAndResolve(device);
      if (!_userWantsConnection) {
        try {
          await _repo.disconnect(device);
        } catch (_) {}
        return;
      }
      final battery = await _repo.readBattery(device);

      await _sampleSub?.cancel();
      _sampleSub = _repo.samples(ch).listen(_onSample, onError: (e) {
        _sampleSub?.cancel();
        _sampleSub = null;
        state = state.copyWith(status: ConnStatus.error, error: e.toString());
      });

      state = state.copyWith(
        status: ConnStatus.connected,
        batteryPercent: battery,
        error: null,
      );
    } catch (e) {
      try {
        await _repo.disconnect(device);
      } catch (_) {}
      state = state.copyWith(status: ConnStatus.error, error: e.toString());
    }
  }

  void _onSample(HeartRateSample sample) {
    var lastArtifact = false;
    for (final rr in sample.rrMs) {
      lastArtifact = _hrv.addRr(rr, at: sample.receivedAt);
    }

    // ── Garde-fou Intensité ──────────────────────────────────────────────────
    final event = _overrunTracker?.add(sample.hr, sample.receivedAt);
    if (event != null) _fireAlert();

    // Capture opportuniste hrMax en mode A (si fcSv2 connue et dépassée).
    if (_currentMode == 'A' &&
        !_opportunisticCaptured &&
        _fcSv2ForOpportunistic != null &&
        sample.hr > _fcSv2ForOpportunistic!) {
      _opportunisticCaptured = true;
      _captureHrMaxOpportunistic(sample.hr);
    }

    state = state.copyWith(
      lastHr: sample.hr,
      lastRrMs: sample.rrMs,
      rmssd: _hrv.rmssd,
      artifactRatio: _hrv.artifactRatio,
      beatsInWindow: _hrv.beatsInWindow,
      totalBeats: _hrv.totalReceived,
      lastWasArtifact: lastArtifact,
      isOverRef: _overrunTracker?.isOver ?? false,
      continuousOverrunSec: _overrunTracker?.continuousOverrunSeconds ?? 0,
      totalOverRefSec: _overrunTracker?.totalOverSeconds ?? 0,
      totalUnderRefSec: _overrunTracker?.totalUnderSeconds ?? 0,
    );

    ref.read(foregroundServiceManagerProvider).mettreAJourNotification(
          hr: sample.hr,
          rmssd: _hrv.rmssd,
        );

    // ── Accumulation RR pour la persistance ─────────────────────────────────
    if (_sessionId != null && _sessionStartedAt != null) {
      final tMs =
          sample.receivedAt.difference(_sessionStartedAt!).inMilliseconds;

      if (_needsGapMarker) {
        _pendingRr.add((tMs: tMs, rr: 0.0, gap: true));
        _needsGapMarker = false;
      }
      for (final rr in sample.rrMs) {
        _pendingRr.add((tMs: tMs, rr: rr, gap: false));
      }
    }
  }

  void _fireAlert() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    if (_currentMode == 'D') {
      final sec = _overrunTracker?.continuousOverrunSeconds ?? 0;
      ref.read(foregroundServiceManagerProvider).signalerAlerte(
            'FC au-dessus de la référence depuis ${sec}s',
          );
    }
  }

  void _captureHrMaxOpportunistic(int hrMax) async {
    try {
      final userId = await UserIdService.userId;
      await _db.profileDao.upsertProfile(ProfileCompanion(
        userId: Value(userId),
        hrMax: Value(hrMax),
        hrMaxSource: const Value('measured'),
        updatedAt: Value(DateTime.now()),
      ));
    } catch (_) {}
  }

  // ── API persistance ───────────────────────────────────────────────────────

  /// Vérifie les prérequis (âge + FC repos) et ouvre une session.
  /// Retourne le résultat de la vérification — si [SessionStartCheck.allowed]
  /// est false, aucune session n'est créée.
  Future<SessionStartCheck> startRecording({String mode = 'D'}) async {
    if (_sessionId != null) {
      return const SessionStartCheck(ageMissing: false, hrRestMissing: false);
    }

    final userId = await UserIdService.userId;
    final profile = await _db.profileDao.getProfile(userId);

    // Mode C : établit hrRest par définition → pas de prérequis bloquants.
    if (mode != 'C') {
      final check = checkSessionStart(
        age: profile?.age,
        hrRest: profile?.hrRest,
        checkSex: mode == 'D',
        sex: profile?.sex,
      );
      if (!check.allowed) return check;
    }

    _currentMode = mode;

    // Paramètres TRIMP Banister (mode D uniquement ; calculés ici pendant que
    // le profil est déjà chargé, réutilisés dans stopRecording).
    if (mode == 'D') {
      _trimpHrRest = profile?.hrRest;
      _trimpHrMax = profile?.hrMax ??
          (profile?.age != null ? estimateHrMaxTanaka(profile!.age!) : null);
      _trimpSex = profile?.sex ?? 'M';
    } else {
      _trimpHrRest = null;
      _trimpHrMax = null;
      _trimpSex = null;
    }

    // Tracker d'intensité (modes A/D uniquement ; mode C = repos, pas de garde-fou).
    IntensityRef? intensityRef;
    if (mode == 'A' || mode == 'D') {
      intensityRef = computeIntensityRef(
        hrRest: profile?.hrRest,
        hrMax: profile?.hrMax,
        age: profile?.age,
        fcSv1: profile?.fcSv1,
        thresholdProvenance: profile?.thresholdProvenance,
      );
      if (intensityRef != null) {
        final config = mode == 'A' ? OverrunConfig.modeA : OverrunConfig.modeD;
        _overrunTracker =
            OverrunTracker(config: config, refBpm: intensityRef.bpmRef);
      } else {
        _overrunTracker = null;
      }
    } else {
      _overrunTracker = null;
    }

    // Capture opportuniste (mode A uniquement, si SV2 connue).
    _fcSv2ForOpportunistic = mode == 'A' ? profile?.fcSv2 : null;
    _opportunisticCaptured = false;

    final now = DateTime.now();
    _sessionStartedAt = now;
    _sessionId = await _db.sessionDao.insertSession(
      SessionsCompanion(
        userId: Value(userId),
        mode: Value(mode),
        startedAt: Value(now),
      ),
    );

    state = state.copyWith(
      isSessionActive: true,
      intensityRefBpm: intensityRef?.bpmRef,
      intensityRefLabel: intensityRef?.label,
      clearIntensityRef: intensityRef == null,
      isOverRef: false,
      continuousOverrunSec: 0,
      totalOverRefSec: 0,
      totalUnderRefSec: 0,
    );

    _flushTimer = Timer.periodic(
      Duration(seconds: AppConstants.rrFlushIntervalSeconds),
      (_) => _flushPending(),
    );

    return const SessionStartCheck(ageMissing: false, hrRestMissing: false);
  }

  /// Flush les RR, écrit les indicateurs finaux (dont temps intensité), ferme la session.
  Future<void> stopRecording() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    final modeAtStop = _currentMode;

    _flushTimer?.cancel();
    _flushTimer = null;

    // Capturer les valeurs avant reset.
    final overRefSec = _overrunTracker?.totalOverSeconds ?? 0;
    final underRefSec = _overrunTracker?.totalUnderSeconds ?? 0;

    // ── Étape 1 : flush final ────────────────────────────────────────────────
    try {
      await _flushPending();
    } catch (_) {}

    // ── Étape 2 : indicateurs ────────────────────────────────────────────────
    final now = DateTime.now();
    final rmssd = _hrv.rmssd;
    final meanHr = _hrv.meanHr;
    final artifactRatio = _hrv.artifactRatio;
    final totalBeats = _hrv.totalReceived;
    // Poincaré (mode C uniquement — mesure au repos stabilisé).
    final cleanRr = (modeAtStop == 'C') ? _hrv.cleanRr : const <double>[];
    final sdnn = computeSdnn(cleanRr);
    final sd1 = computeSd1(rmssd);
    final sd2 = computeSd2(sdnn, sd1);

    try {
      final indicators = <IndicatorsCompanion>[
        if (!rmssd.isNaN)
          IndicatorsCompanion(
            sessionId: Value(sessionId),
            kind: const Value('rmssd'),
            value: Value(rmssd),
            at: Value(now),
          ),
        if (!meanHr.isNaN)
          IndicatorsCompanion(
            sessionId: Value(sessionId),
            kind: const Value('meanHr'),
            value: Value(meanHr),
            at: Value(now),
          ),
        IndicatorsCompanion(
          sessionId: Value(sessionId),
          kind: const Value('artifactRatio'),
          value: Value(artifactRatio),
          at: Value(now),
        ),
        IndicatorsCompanion(
          sessionId: Value(sessionId),
          kind: const Value('totalBeats'),
          value: Value(totalBeats.toDouble()),
          at: Value(now),
        ),
        if (_overrunTracker != null) ...[
          IndicatorsCompanion(
            sessionId: Value(sessionId),
            kind: const Value('overRefSec'),
            value: Value(overRefSec.toDouble()),
            at: Value(now),
          ),
          IndicatorsCompanion(
            sessionId: Value(sessionId),
            kind: const Value('underRefSec'),
            value: Value(underRefSec.toDouble()),
            at: Value(now),
          ),
        ],
        // Poincaré — réservé au mode C (repos stabilisé, signal propre).
        if (modeAtStop == 'C') ...[
          if (!sd1.isNaN)
            IndicatorsCompanion(
              sessionId: Value(sessionId),
              kind: const Value('sd1'),
              value: Value(sd1),
              at: Value(now),
            ),
          if (!sd2.isNaN)
            IndicatorsCompanion(
              sessionId: Value(sessionId),
              kind: const Value('sd2'),
              value: Value(sd2),
              at: Value(now),
            ),
        ],
      ];

      // TRIMP Banister (mode D) — calculé depuis les RR déjà flushés en base.
      if (modeAtStop == 'D' &&
          _trimpHrRest != null &&
          _trimpHrMax != null &&
          _sessionStartedAt != null) {
        final rawRr = await _db.rrDao.getRrForTrimp(sessionId);
        final samples =
            rawRr.map((r) => (tMs: r.tMs, rr: r.rr, gap: r.gap)).toList();
        final sessionDurationMs =
            now.difference(_sessionStartedAt!).inMilliseconds;
        final trimp = computeTrimpBanisterFromRr(
          samples: samples,
          hrRest: _trimpHrRest!,
          hrMax: _trimpHrMax!,
          sex: _trimpSex ?? 'M',
          sessionDurationMs: sessionDurationMs,
        );
        indicators.addAll([
          IndicatorsCompanion(
            sessionId: Value(sessionId),
            kind: const Value('trimp_banister'),
            value: Value(trimp.trimpTotal),
            at: Value(now),
          ),
          IndicatorsCompanion(
            sessionId: Value(sessionId),
            kind: const Value('data_coverage_ratio'),
            value: Value(trimp.dataCoverageRatio),
            at: Value(now),
          ),
        ]);
      }

      if (indicators.isNotEmpty) {
        await _db.indicatorDao.insertAll(indicators);
      }
    } catch (_) {}

    // ── Étape 3 : clôture ───────────────────────────────────────────────────
    try {
      final qualityRatio = (1.0 - artifactRatio).clamp(0.0, 1.0);
      await _db.sessionDao.closeSession(sessionId, now, qualityRatio);
    } catch (_) {}

    // ── Étape 4 : FC repos issue du mode C ──────────────────────────────────
    if (modeAtStop == 'C' && !meanHr.isNaN) {
      try {
        final userId = await UserIdService.userId;
        await _db.profileDao.setHrRestFromModeC(userId, meanHr.round());
      } catch (_) {}
    }

    _sessionId = null;
    _sessionStartedAt = null;
    _pendingRr.clear();
    _hrv.reset();
    _overrunTracker?.reset();
    _overrunTracker = null;
    _trimpHrRest = null;
    _trimpHrMax = null;
    _trimpSex = null;

    state = state.copyWith(
      isSessionActive: false,
      clearIntensityRef: true,
      isOverRef: false,
      continuousOverrunSec: 0,
      totalOverRefSec: 0,
      totalUnderRefSec: 0,
    );
  }

  Future<void> _flushPending() async {
    final sessionId = _sessionId;
    if (sessionId == null || _pendingRr.isEmpty) return;

    final toWrite = List.of(_pendingRr);
    _pendingRr.clear();

    final rows = toWrite
        .map((e) => RrSamplesCompanion(
              sessionId: Value(sessionId),
              tMs: Value(e.tMs),
              rr: Value(e.rr),
              gap: Value(e.gap),
            ))
        .toList();

    await _db.rrDao.insertBatch(rows);
  }

  Future<void> disconnect() async {
    _userWantsConnection = false;
    await _cleanup();
    state = const AcquisitionState(status: ConnStatus.idle);
  }

  Future<void> _cleanup() async {
    await _flushPending();
    _flushTimer?.cancel();
    _flushTimer = null;

    await _sampleSub?.cancel();
    await _connSub?.cancel();
    _sampleSub = null;
    _connSub = null;
    final d = _device;
    _device = null;
    if (d != null) {
      try {
        await _repo.disconnect(d);
      } catch (_) {}
    }
  }
}
