import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/user_id_service.dart';
import '../../data/ble/ble_providers.dart';
import '../../data/foreground/foreground_service_manager.dart';
import '../../data/local/app_database.dart';
import '../../data/local/local_providers.dart';
import '../../domain/load/calibration.dart';
import '../../domain/load/rpe.dart';

class BleDebugScreen extends ConsumerStatefulWidget {
  const BleDebugScreen({super.key});

  @override
  ConsumerState<BleDebugScreen> createState() => _BleDebugScreenState();
}

class _BleDebugScreenState extends ConsumerState<BleDebugScreen> {
  static const _teal = Color(0xFF1B9AAA);
  static const _orange = Color(0xFFEE8B2C);

  // ── Profil ──────────────────────────────────────────────────────────────────
  final _ageCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  final _tailleCtrl = TextEditingController();
  final _fcReposCtrl = TextEditingController();
  final _fcMaxCtrl = TextEditingController();
  String _sexe = 'M';
  String _hrMaxSource = 'tanaka';
  bool _profilCharge = false;
  CalibrationResult? _calibration;

  // ── RPE ─────────────────────────────────────────────────────────────────────
  String? _userId;
  final _rpePhysCtrl = TextEditingController();    // CR10 session courante
  final _rpePsychoCtrl = TextEditingController();  // CR10 psychologique du jour
  final _rpeCompCtrl = TextEditingController();    // comparaison −2..+2

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _poidsCtrl.dispose();
    _tailleCtrl.dispose();
    _fcReposCtrl.dispose();
    _fcMaxCtrl.dispose();
    _rpePhysCtrl.dispose();
    _rpePsychoCtrl.dispose();
    _rpeCompCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerProfil() async {
    final userId = await UserIdService.userId;
    final db = ref.read(appDatabaseProvider);
    final p = await db.profileDao.getProfile(userId);
    if (!mounted) return;
    setState(() {
      _userId = userId;
      if (p != null) {
        _ageCtrl.text = p.age?.toString() ?? '';
        _poidsCtrl.text = p.weightKg?.toString() ?? '';
        _tailleCtrl.text = p.heightCm?.toString() ?? '';
        _fcReposCtrl.text = p.hrRest?.toString() ?? '';
        _fcMaxCtrl.text = p.hrMax?.toString() ?? '';
        _sexe = p.sex ?? 'M';
        _hrMaxSource = p.hrMaxSource ?? 'tanaka';
        _calibration = _calculerCalibration(p);
      }
      _profilCharge = true;
    });
  }

  CalibrationResult? _calculerCalibration(ProfileData p) {
    return computeZones(
      age: p.age,
      hrRest: p.hrRest,
      hrMax: p.hrMax,
      hrMaxSource: p.hrMaxSource,
      fcSv1: p.fcSv1,
      fcSv2: p.fcSv2,
      thresholdProvenance: p.thresholdProvenance,
    );
  }

  Future<void> _sauvegarderProfil() async {
    final userId = await UserIdService.userId;
    final db = ref.read(appDatabaseProvider);

    final age = int.tryParse(_ageCtrl.text.trim());
    final poids = double.tryParse(_poidsCtrl.text.trim());
    final taille = double.tryParse(_tailleCtrl.text.trim());
    final fcRepos = int.tryParse(_fcReposCtrl.text.trim());
    final fcMax = int.tryParse(_fcMaxCtrl.text.trim());

    int? fcMaxResolu = fcMax;
    String srcResolu = _hrMaxSource;
    if (fcMaxResolu == null && age != null) {
      fcMaxResolu = estimateHrMaxTanaka(age);
      srcResolu = 'tanaka';
    }

    await db.profileDao.upsertProfile(ProfileCompanion(
      userId: Value(userId),
      age: Value(age),
      sex: Value(_sexe),
      weightKg: Value(poids),
      heightCm: Value(taille),
      hrRest: Value(fcRepos),
      hrMax: Value(fcMaxResolu),
      hrMaxSource: Value(srcResolu),
      updatedAt: Value(DateTime.now()),
    ));

    final calib = computeZones(
      age: age,
      hrRest: fcRepos,
      hrMax: fcMaxResolu,
      hrMaxSource: srcResolu,
      fcSv1: null,
      fcSv2: null,
      thresholdProvenance: null,
    );

    if (!mounted) return;
    setState(() => _calibration = calib);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil sauvegardé.')),
    );
  }

  Future<void> _sauvegarderRpeJour() async {
    final userId = _userId;
    if (userId == null) return;
    final db = ref.read(appDatabaseProvider);

    final psycho = clamperRpe(int.tryParse(_rpePsychoCtrl.text.trim()));
    final comp = clamperRpeComp(int.tryParse(_rpeCompCtrl.text.trim()));
    final jour = _normaliseMidnight(DateTime.now());

    await db.dailyEntryDao.upsertEntry(DailyEntriesCompanion.insert(
      userId: userId,
      day: jour,
      rpePsychological: Value(psycho),
      rpeComparison: Value(comp),
      updatedAt: DateTime.now(),
    ));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('RPE du jour sauvegardé.')),
    );
  }

  // ── Build principal ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          title: const Text('Ayur Life — Debug'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: 'Capteur'),
              Tab(icon: Icon(Icons.person), text: 'Profil'),
              Tab(icon: Icon(Icons.history), text: 'Historique'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _capteurTab(),
            _profilTab(),
            _historiqueTab(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════ ONGLET CAPTEUR ═══════════════════════════

  Widget _capteurTab() {
    final acq = ref.watch(acquisitionProvider);
    final adapter = ref.watch(adapterStateProvider).value;
    final bluetoothOn = adapter == BluetoothAdapterState.on;
    final connected = acq.status == ConnStatus.connected ||
        acq.status == ConnStatus.reconnecting;
    final enregistrement = ref.watch(isRecordingProvider);

    return Padding(
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
              '● Enregistrement actif — acquisition continue écran éteint.',
              _teal,
            ),
          if (connected)
            Expanded(child: _livePanel(acq, enregistrement))
          else
            Expanded(child: _scanPanel(bluetoothOn)),
        ],
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

  Widget _scanPanel(bool bluetoothOn) {
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
                  child: Text(
                      'Aucun capteur. Humidifie la ceinture et scanne.'))
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = results[i];
                    final name = r.device.platformName.isNotEmpty
                        ? r.device.platformName
                        : '(sans nom)';
                    return ListTile(
                      leading: const Icon(Icons.favorite, color: _orange),
                      title: Text(name),
                      subtitle: Text(
                          '${r.device.remoteId.str}  •  RSSI ${r.rssi}'),
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

  Widget _livePanel(AcquisitionState acq, bool enregistrement) {
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
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: _teal)),
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
        if (!enregistrement)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            icon: const Icon(Icons.fiber_manual_record),
            label: const Text('Démarrer enregistrement long'),
            onPressed: () => _demarrerEnregistrement(),
          )
        else ...[
          // Saisie RPE physique avant l'arrêt
          _champNum(
            'RPE physique CR10 (0–10) — à saisir avant d\'arrêter',
            _rpePhysCtrl,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.stop),
            label: const Text('Arrêter enregistrement'),
            onPressed: () => _arreterEnregistrement(),
          ),
        ],
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

  Future<void> _demarrerEnregistrement() async {
    await _ensurePermissions();
    final manager = ref.read(foregroundServiceManagerProvider);

    if (Platform.isAndroid && !await manager.ignoresBatterie) {
      if (!mounted) return;
      final confirme = await _dialogBatterie(manager);
      if (!confirme || !mounted) return;
    }

    await ref.read(acquisitionProvider.notifier).startRecording();
    final result = await manager.demarrerEnregistrement();

    if (!mounted) return;
    if (result is ServiceRequestFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur service : ${result.error}')),
      );
    }
  }

  Future<void> _arreterEnregistrement() async {
    final db = ref.read(appDatabaseProvider);
    await ref.read(foregroundServiceManagerProvider).arreterEnregistrement();
    await ref.read(acquisitionProvider.notifier).stopRecording();

    // Enregistrer le RPE physique saisi si valide
    final rpeVal = int.tryParse(_rpePhysCtrl.text.trim());
    if (rpeVal != null) {
      final sessions = await db.sessionDao.getAll();
      if (sessions.isNotEmpty) {
        final rpe = clamperRpe(rpeVal) ?? rpeVal;
        await db.sessionDao.setRpePhysical(sessions.first.id, rpe);
      }
      _rpePhysCtrl.clear();
    }
  }

  Future<bool> _dialogBatterie(ForegroundServiceManager manager) async {
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
    if (confirme == true) await manager.ouvrirReglagesBatterie();
    return confirme == true;
  }

  static Future<void> _ensurePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.notification,
    ].request();
  }

  // ═══════════════════════════════ ONGLET PROFIL ════════════════════════════

  Widget _profilTab() {
    if (!_profilCharge) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Profil physiologique ──────────────────────────────────────────
          const Text('Profil & calibration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _champNum('Âge (ans)', _ageCtrl)),
            const SizedBox(width: 12),
            Expanded(
                child: _champNum('Poids (kg)', _poidsCtrl, decimal: true)),
            const SizedBox(width: 12),
            Expanded(
                child: _champNum('Taille (cm)', _tailleCtrl, decimal: true)),
          ]),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
                labelText: 'Sexe', border: OutlineInputBorder()),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sexe,
                isDense: true,
                onChanged: (v) => setState(() => _sexe = v!),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculin')),
                  DropdownMenuItem(value: 'F', child: Text('Féminin')),
                  DropdownMenuItem(value: 'autre', child: Text('Autre')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _champNum('FC repos (bpm)', _fcReposCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _champNum('FC max (bpm)', _fcMaxCtrl)),
          ]),
          const SizedBox(height: 8),
          Text(
            'Laisse FC max vide : sera estimée par Tanaka (208 − 0,7 × âge).',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _teal),
            onPressed: _sauvegarderProfil,
            child: const Text('Sauvegarder le profil'),
          ),
          if (_calibration != null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            _calibrationCard(_calibration!),
          ],

          // ── RPE du jour ───────────────────────────────────────────────────
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 8),
          const Text('RPE du jour',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'RPE psychologique CR10 (0–10) et comparaison (−2..+2) pour '
            'journées mode D sans ceinture.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _champNum(
              'RPE psycho (0–10)',
              _rpePsychoCtrl,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _champNumSigne(
              'Comparaison (−2..+2)',
              _rpeCompCtrl,
            )),
          ]),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            onPressed: _userId != null ? _sauvegarderRpeJour : null,
            child: const Text('Sauvegarder RPE du jour'),
          ),

          // ── Read-back entrées journalières ────────────────────────────────
          const SizedBox(height: 20),
          if (_userId != null) _dailyEntriesReadBack(_userId!),
        ],
      ),
    );
  }

  Widget _dailyEntriesReadBack(String userId) {
    final db = ref.watch(appDatabaseProvider);
    return StreamBuilder<List<DailyEntry>>(
      stream: db.dailyEntryDao.watchRecent(userId),
      builder: (context, snap) {
        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return const Text(
            'Aucune entrée journalière.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dernières entrées journalières',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Text(_formatJour(e.day),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                    if (e.rpePsychological != null)
                      _badge('Psycho ${e.rpePsychological}', _teal),
                    if (e.rpeComparison != null) ...[
                      const SizedBox(width: 6),
                      _badge(
                          'Comp ${e.rpeComparison! >= 0 ? "+" : ""}${e.rpeComparison}',
                          _orange),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _champNum(String label, TextEditingController ctrl,
          {bool decimal = false}) =>
      TextField(
        controller: ctrl,
        keyboardType:
            TextInputType.numberWithOptions(decimal: decimal, signed: false),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              decimal ? RegExp(r'[\d.]') : RegExp(r'\d')),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );

  Widget _champNumSigne(String label, TextEditingController ctrl) => TextField(
        controller: ctrl,
        keyboardType:
            const TextInputType.numberWithOptions(signed: true, decimal: false),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );

  Widget _calibrationCard(CalibrationResult calib) {
    final provLabel =
        calib.aerobicCeilingProvenance == ThresholdProvenance.measuredModeB
            ? 'mesuré (mode B)'
            : calib.aerobicCeilingProvenance == ThresholdProvenance.manualLab
                ? 'labo manuel'
                : 'estimé (Karvonen ~70 % FCR)';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _teal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plafond aérobie : ${calib.aerobicCeiling} bpm  ($provLabel)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final z in calib.zones)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${z.label} : ${z.minBpm}–${z.maxBpm} bpm'),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════ ONGLET HISTORIQUE ════════════════════════

  Widget _historiqueTab() {
    final db = ref.watch(appDatabaseProvider);
    return StreamBuilder<List<Session>>(
      stream: db.sessionDao.watchAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final sessions = snap.data ?? [];
        if (sessions.isEmpty) {
          return const Center(
            child: Text(
              'Aucune session enregistrée.\nDémarre un enregistrement '
              'depuis l\'onglet Capteur.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sessions.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _sessionTile(sessions[i], db),
        );
      },
    );
  }

  Widget _sessionTile(Session s, AppDatabase db) {
    final debut = _formatDate(s.startedAt);
    final fin = s.endedAt;
    final duree = fin?.difference(s.startedAt);
    final dureeStr = duree != null ? _formatDuree(duree) : 'en cours…';
    final qualite = '${(s.qualityRatio * 100).toStringAsFixed(0)} % qualité';

    // Foster : RPE × durée (uniquement si les deux sont disponibles)
    String fosterStr = '';
    if (s.rpePhysical != null && duree != null) {
      final charge = fosterLoad(s.rpePhysical!, duree);
      fosterStr = '  •  Foster ${charge.toStringAsFixed(0)} UA';
    }
    final rpeStr = s.rpePhysical != null ? '  •  RPE ${s.rpePhysical}' : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _teal.withValues(alpha: 0.15),
        child: Text(s.mode,
            style: const TextStyle(color: _teal, fontWeight: FontWeight.bold)),
      ),
      title: Text(debut),
      subtitle: Text('$dureeStr  •  $qualite$rpeStr$fosterStr'),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => _afficherIndicateurs(s, db),
    );
  }

  Future<void> _afficherIndicateurs(Session s, AppDatabase db) async {
    final indicateurs = await db.indicatorDao.forSession(s.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session mode ${s.mode} — ${_formatDate(s.startedAt)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (indicateurs.isEmpty)
              const Text('Aucun indicateur enregistré.')
            else
              for (final ind in indicateurs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ind.kind),
                      Text(ind.value.toStringAsFixed(2),
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );

  static DateTime _normaliseMidnight(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  static String _formatJour(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';

  static String _formatDuree(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h $m min' : '$m min $s s';
  }
}
