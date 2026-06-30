import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/user_id_service.dart';
import '../../domain/hrv/live_hrv_accumulator.dart';
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
  // (tMs depuis startedAt en ms, valeur rr en ms, estGap)
  final List<({int tMs, double rr, bool gap})> _pendingRr = [];
  Timer? _flushTimer;
  bool _needsGapMarker = false;

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
        // Marquer un gap BLE dans les RR si une session est en cours.
        if (_sessionId != null && _sessionStartedAt != null) {
          _needsGapMarker = true;
        }
        await _tryConnect(device);
      }
    });

    await _tryConnect(device);
  }

  Future<void> _tryConnect(BluetoothDevice device) async {
    // FIX B : si disconnect() a été appelé pendant qu'un async body _connSub
    // attendait ici, on ne rouvre pas de GATT.
    if (!_userWantsConnection) return;
    try {
      final ch = await _repo.connectAndResolve(device);
      // FIX B-2 : disconnect() peut avoir été appelé pendant connectAndResolve.
      // Le GATT est ouvert : le fermer immédiatement.
      if (!_userWantsConnection) {
        try {
          await _repo.disconnect(device);
        } catch (_) {}
        return;
      }
      final battery = await _repo.readBattery(device);

      await _sampleSub?.cancel();
      _sampleSub = _repo.samples(ch).listen(_onSample, onError: (e) {
        // FIX C : fermer la subscription sur erreur stream, pas seulement à _cleanup.
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
      // FIX A : libérer le GATT si device.connect() a réussi mais la suite a échoué.
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
    state = state.copyWith(
      lastHr: sample.hr,
      lastRrMs: sample.rrMs,
      rmssd: _hrv.rmssd,
      artifactRatio: _hrv.artifactRatio,
      beatsInWindow: _hrv.beatsInWindow,
      totalBeats: _hrv.totalReceived,
      lastWasArtifact: lastArtifact,
    );
    ref.read(foregroundServiceManagerProvider).mettreAJourNotification(
          hr: sample.hr,
          rmssd: _hrv.rmssd,
        );

    // ── Accumulation RR pour la persistance (additive, ne touche pas au flux) ─
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

  // ── API persistance ───────────────────────────────────────────────────────

  /// Ouvre une session en base et démarre le flush périodique des RR.
  Future<void> startRecording({String mode = 'D'}) async {
    if (_sessionId != null) return; // déjà en cours

    final userId = await UserIdService.userId;
    final now = DateTime.now();
    _sessionStartedAt = now;

    _sessionId = await _db.sessionDao.insertSession(
      SessionsCompanion(
        userId: Value(userId),
        mode: Value(mode),
        startedAt: Value(now),
      ),
    );

    _flushTimer = Timer.periodic(
      Duration(seconds: AppConstants.rrFlushIntervalSeconds),
      (_) => _flushPending(),
    );
  }

  /// Flush les RR en attente, écrit les indicateurs finaux, ferme la session.
  Future<void> stopRecording() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    _flushTimer?.cancel();
    _flushTimer = null;

    // Flush final des RR restants.
    await _flushPending();

    // Indicateurs de fin de session.
    final now = DateTime.now();
    final rmssd = _hrv.rmssd;
    final meanHr = _hrv.meanHr;
    final artifactRatio = _hrv.artifactRatio;
    final totalBeats = _hrv.totalReceived;

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
    ];

    if (indicators.isNotEmpty) {
      await _db.indicatorDao.insertAll(indicators);
    }

    final qualityRatio = (1.0 - artifactRatio).clamp(0.0, 1.0);
    await _db.sessionDao.closeSession(sessionId, now, qualityRatio);

    _sessionId = null;
    _sessionStartedAt = null;
    _pendingRr.clear();
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
    // FIX D : flush les RR en tampon AVANT d'annuler le timer (aucune perte de données).
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
