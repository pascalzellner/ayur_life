import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/hrv/live_hrv_accumulator.dart';
import '../foreground/foreground_service_manager.dart';
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

  @override
  AcquisitionState build() {
    ref.onDispose(_cleanup);
    return const AcquisitionState();
  }

  BleHeartRateRepository get _repo => ref.read(bleRepositoryProvider);

  Future<void> connect(BluetoothDevice device) async {
    _userWantsConnection = true;
    _device = device;
    _hrv.reset();
    state = state.copyWith(
      status: ConnStatus.connecting,
      deviceName: device.platformName.isEmpty ? device.remoteId.str : device.platformName,
      error: null,
    );

    // Reconnexion automatique sur perte de liaison pendant la session.
    _connSub?.cancel();
    _connSub = device.connectionState.listen((s) async {
      if (s == BluetoothConnectionState.disconnected &&
          _userWantsConnection &&
          state.status == ConnStatus.connected) {
        state = state.copyWith(status: ConnStatus.reconnecting);
        await _tryConnect(device);
      }
    });

    await _tryConnect(device);
  }

  Future<void> _tryConnect(BluetoothDevice device) async {
    try {
      final ch = await _repo.connectAndResolve(device);
      final battery = await _repo.readBattery(device);

      await _sampleSub?.cancel();
      _sampleSub = _repo.samples(ch).listen(_onSample, onError: (e) {
        state = state.copyWith(status: ConnStatus.error, error: e.toString());
      });

      state = state.copyWith(
        status: ConnStatus.connected,
        batteryPercent: battery,
        error: null,
      );
    } catch (e) {
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
    // Mise à jour throttlée de la notification persistante (no-op si service arrêté).
    ref.read(foregroundServiceManagerProvider).mettreAJourNotification(
          hr: sample.hr,
          rmssd: _hrv.rmssd,
        );
  }

  Future<void> disconnect() async {
    _userWantsConnection = false;
    await _cleanup();
    state = const AcquisitionState(status: ConnStatus.idle);
  }

  Future<void> _cleanup() async {
    await _sampleSub?.cancel();
    await _connSub?.cancel();
    _sampleSub = null;
    _connSub = null;
    final d = _device;
    if (d != null) {
      try {
        await _repo.disconnect(d);
      } catch (_) {}
    }
  }
}
