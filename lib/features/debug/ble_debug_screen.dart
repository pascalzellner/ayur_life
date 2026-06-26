import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/ble/ble_providers.dart';
import '../../data/foreground/foreground_service_manager.dart';

/// Écran de debug : connecter un cardiofréquencemètre BLE (Polar H10,
/// Cardiosport…) et visualiser FC, RR, RMSSD et taux d'artefacts en direct.
/// Permet également de démarrer / arrêter un enregistrement long (service
/// de premier plan, écran éteint).
class BleDebugScreen extends ConsumerWidget {
  const BleDebugScreen({super.key});

  static const _teal = Color(0xFF1B9AAA);
  static const _orange = Color(0xFFEE8B2C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acq = ref.watch(acquisitionProvider);
    final adapter = ref.watch(adapterStateProvider).value;
    final bluetoothOn = adapter == BluetoothAdapterState.on;
    final connected = acq.status == ConnStatus.connected ||
        acq.status == ConnStatus.reconnecting;
    final enregistrement = ref.watch(isRecordingProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        title: const Text('Ayur Life — Debug capteur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!bluetoothOn)
              _banner('Active le Bluetooth pour scanner.', Colors.red.shade400),
            if (acq.status == ConnStatus.error && acq.error != null)
              _banner(acq.error!, Colors.red.shade400),
            if (enregistrement)
              _banner(
                '● Enregistrement actif — l\'acquisition continue écran éteint.',
                _teal,
              ),
            if (connected)
              Expanded(child: _livePanel(context, ref, acq, enregistrement))
            else
              Expanded(child: _scanPanel(ref, bluetoothOn)),
          ],
        ),
      ),
    );
  }

  Widget _banner(String text, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(text, style: TextStyle(color: color)),
      );

  // ---------- Scan ----------
  Widget _scanPanel(WidgetRef ref, bool bluetoothOn) {
    final results = ref.watch(scanResultsProvider).value ?? const [];
    final scanning = ref.watch(isScanningProvider).value ?? false;
    final repo = ref.read(bleRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _teal),
          onPressed: bluetoothOn
              ? () async {
                  await _ensurePermissions();
                  await repo.startScan();
                }
              : null,
          icon: Icon(scanning ? Icons.bluetooth_searching : Icons.search),
          label: Text(scanning ? 'Scan en cours…' : 'Scanner les capteurs'),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: results.isEmpty
              ? const Center(
                  child: Text('Aucun capteur. Humidifie la ceinture et scanne.'))
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = results[i];
                    final name = r.device.platformName.isNotEmpty
                        ? r.device.platformName
                        : '(sans nom)';
                    return ListTile(
                      leading: const Icon(Icons.favorite, color: _orange),
                      title: Text(name),
                      subtitle:
                          Text('${r.device.remoteId.str}  •  RSSI ${r.rssi}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => ref
                          .read(acquisitionProvider.notifier)
                          .connect(r.device),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------- Live ----------
  Widget _livePanel(
    BuildContext context,
    WidgetRef ref,
    AcquisitionState acq,
    bool enregistrement,
  ) {
    final rmssd = acq.rmssd.isNaN ? '—' : acq.rmssd.toStringAsFixed(1);
    final artifactPct = (acq.artifactRatio * 100).toStringAsFixed(1);
    final reconnecting = acq.status == ConnStatus.reconnecting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
                reconnecting
                    ? Icons.bluetooth_disabled
                    : Icons.bluetooth_connected,
                color: reconnecting ? _orange : _teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${acq.deviceName ?? "Capteur"}'
                '${acq.batteryPercent != null ? "  •  ${acq.batteryPercent}%" : ""}'
                '${reconnecting ? "  •  reconnexion…" : ""}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(acquisitionProvider.notifier).disconnect(),
              child: const Text('Déconnecter'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text('${acq.lastHr}',
                  style: const TextStyle(
                      fontSize: 72, fontWeight: FontWeight.bold, color: _teal)),
              const Text('bpm', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _metric('RMSSD', '$rmssd ms', _teal),
            _metric('Artefacts', '$artifactPct %',
                acq.artifactRatio > 0.05 ? Colors.red : _teal),
            _metric('Battements', '${acq.beatsInWindow}', _orange),
          ],
        ),
        const SizedBox(height: 16),

        // --- Boutons enregistrement long ---
        if (!enregistrement)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            icon: const Icon(Icons.fiber_manual_record),
            label: const Text('Démarrer enregistrement long'),
            onPressed: () => _demarrerEnregistrement(context, ref),
          )
        else
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.stop),
            label: const Text('Arrêter enregistrement'),
            onPressed: () =>
                ref.read(foregroundServiceManagerProvider).arreterEnregistrement(),
          ),

        const SizedBox(height: 20),
        const Text('Derniers RR (ms)',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (acq.lastRrMs.isEmpty)
              const Text('— pas de RR dans cette trame —',
                  style: TextStyle(color: Colors.grey))
            else
              for (final rr in acq.lastRrMs)
                Chip(
                  backgroundColor:
                      acq.lastWasArtifact ? Colors.red.shade50 : null,
                  label: Text(rr.toStringAsFixed(0)),
                ),
          ],
        ),
        const Spacer(),
        Text('Total battements reçus : ${acq.totalBeats}',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _metric(String label, String value, Color color) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

  Future<void> _demarrerEnregistrement(
      BuildContext context, WidgetRef ref) async {
    await _ensurePermissions();

    final manager = ref.read(foregroundServiceManagerProvider);

    // Vérifie l'exclusion d'optimisation batterie avant de démarrer.
    if (Platform.isAndroid && !await manager.ignoresBatterie) {
      if (!context.mounted) return;
      final confirme = await _dialogBatterie(context, manager);
      if (!confirme || !context.mounted) return;
    }

    final result = await manager.demarrerEnregistrement();
    if (!context.mounted) return;
    if (result is ServiceRequestFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur service : ${result.error}')),
      );
    }
  }

  /// Dialog expliquant pourquoi l'exclusion batterie est nécessaire,
  /// avec mention spécifique MIUI pour les Xiaomi.
  Future<bool> _dialogBatterie(
      BuildContext context, ForegroundServiceManager manager) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Optimisation batterie'),
        content: const Text(
          'Pour que l\'acquisition continue écran éteint, '
          'l\'app doit être exclue de l\'optimisation batterie.\n\n'
          'Sur Xiaomi / MIUI : après avoir accordé ci-dessous, '
          'va aussi dans Sécurité → Gestion des autorisations → '
          'Démarrage automatique et active l\'app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ouvrir les réglages'),
          ),
        ],
      ),
    );
    if (confirme == true) {
      await manager.ouvrirReglagesBatterie();
    }
    return confirme == true;
  }

  static Future<void> _ensurePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.notification,
    ].request();
  }
}
