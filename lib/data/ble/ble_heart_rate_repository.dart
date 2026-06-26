import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'heart_rate_parser.dart';

/// Accès au capteur cardiaque BLE via le Heart Rate Service standard (0x180D).
///
/// PD-1 (CDCF) : seule source de vérité. On filtre le scan sur 0x180D,
/// on souscrit à la caractéristique de mesure 0x2A37, on décode FC + RR.
class BleHeartRateRepository {
  // UUID courts du profil Heart Rate (Bluetooth SIG).
  static final Guid hrService = Guid('180D');
  static final Guid hrMeasurement = Guid('2A37');
  static final Guid batteryService = Guid('180F');
  static final Guid batteryLevel = Guid('2A19');

  /// Résultats de scan (capteurs exposant le Heart Rate Service).
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.onScanResults;

  /// État de l'adaptateur Bluetooth du téléphone.
  Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;

  /// Scan en cours ?
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  Future<void> startScan() async {
    if (FlutterBluePlus.isScanningNow) return;
    await FlutterBluePlus.startScan(
      withServices: [hrService],
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> stopScan() async {
    if (FlutterBluePlus.isScanningNow) {
      await FlutterBluePlus.stopScan();
    }
  }

  /// Connecte le capteur, découvre les services et renvoie la caractéristique
  /// de mesure cardiaque, prête à notifier (setNotifyValue déjà activé).
  Future<BluetoothCharacteristic> connectAndResolve(
    BluetoothDevice device,
  ) async {
    await stopScan();
    await device.connect(
      timeout: const Duration(seconds: 20),
      license: License.commercial,
  );

    final services = await device.discoverServices();
    final hrSvc = services.firstWhere(
      (s) => _matches(s.uuid, '180d'),
      orElse: () => throw const HeartRateUnavailable(
          'Le capteur n\'expose pas le Heart Rate Service (0x180D).'),
    );
    final ch = hrSvc.characteristics.firstWhere(
      (c) => _matches(c.uuid, '2a37'),
      orElse: () => throw const HeartRateUnavailable(
          'Caractéristique de mesure cardiaque (0x2A37) introuvable.'),
    );

    await ch.setNotifyValue(true);
    return ch;
  }

  /// Flux de samples décodés à partir d'une caractéristique notifiante.
  Stream<HeartRateSample> samples(BluetoothCharacteristic ch) =>
      ch.onValueReceived.map(parseHeartRate);

  /// Lecture ponctuelle du niveau de batterie (si le capteur l'expose).
  Future<int?> readBattery(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      final svc = services.firstWhere((s) => _matches(s.uuid, '180f'));
      final ch = svc.characteristics.firstWhere((c) => _matches(c.uuid, '2a19'));
      final value = await ch.read();
      return value.isNotEmpty ? value.first : null;
    } catch (_) {
      return null; // service batterie optionnel
    }
  }

  Future<void> disconnect(BluetoothDevice device) => device.disconnect();

  /// Comparaison tolérante : les UUID découverts peuvent être en 128 bits.
  static bool _matches(Guid g, String hex16) =>
      g.toString().toLowerCase().replaceAll('-', '').contains(hex16.toLowerCase());
}

class HeartRateUnavailable implements Exception {
  final String message;
  const HeartRateUnavailable(this.message);
  @override
  String toString() => 'HeartRateUnavailable: $message';
}
