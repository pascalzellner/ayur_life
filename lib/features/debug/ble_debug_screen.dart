import 'dart:async';
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
import '../../domain/load/intensity_guard.dart';
import '../../domain/load/rpe.dart';
import '../../domain/state/readiness.dart';

// Phases du protocole Mode C (readiness du matin).
enum _ModeCPhase { stabilisant, mesurant, questionnaire, resultat }

class BleDebugScreen extends ConsumerStatefulWidget {
  const BleDebugScreen({super.key});

  @override
  ConsumerState<BleDebugScreen> createState() => _BleDebugScreenState();
}

class _BleDebugScreenState extends ConsumerState<BleDebugScreen> {
  static const _teal = Color(0xFF1B9AAA);
  static const _orange = Color(0xFFEE8B2C);

  // Durées protocole (s)
  static const int _stabS = 60;
  static const int _mesureS = 120;
  static const int _totalS = _stabS + _mesureS; // 180

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

  // ── Mode session (A = activité sportive, C = readiness, D = journée pro) ───
  String _modeSession = 'D';

  // ── Résumé post-session D (TRIMP + couverture) ───────────────────────────────
  String? _dernierSummaireD;

  // ── RPE ─────────────────────────────────────────────────────────────────────
  String? _userId;
  final _rpePhysCtrl = TextEditingController();
  final _rpePsychoCtrl = TextEditingController();
  final _rpeCompCtrl = TextEditingController();

  // ── Mode C — protocole readiness du matin ───────────────────────────────────
  _ModeCPhase? _modeCPhase;
  int _modeCElapsedSec = 0;
  Timer? _modeCTimer;
  int? _modeCSessionId;
  double _modeCRmssd = double.nan;
  double _modeCMeanHr = double.nan;
  double _modeCSd1 = double.nan;
  double _modeCSd2 = double.nan;
  int _hooperFatigue = 4;
  int _hooperStress = 4;
  int _hooperDoms = 4;
  int _hooperSleep = 4;
  String _modeCReadinessMsg = '';
  int _modeCSessionCount = 0;

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  @override
  void dispose() {
    _modeCTimer?.cancel();
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
    final fcRepos = int.tryParse(_fcReposCtrl.text.trim());
    final fcMax = int.tryParse(_fcMaxCtrl.text.trim());

    if (fcRepos != null && !isHrRestManualValid(fcRepos)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('FC de repos hors plage 35–100 bpm — valeur rejetée.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (fcMax != null && !isHrMaxManualValid(fcMax)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('FC max hors plage 120–220 bpm — valeur rejetée.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (fcRepos != null || fcMax != null) {
      if (!mounted) return;
      final confirme = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Valeur non mesurée'),
          content: const Text(
            'Ces valeurs ne sont pas issues d\'une mesure clinique. '
            'Elles seront utilisées comme estimation de repli pour le '
            'garde-fou Intensité.\n\nConfirmez-vous la saisie ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
      if (confirme != true || !mounted) return;
    }

    final userId = await UserIdService.userId;
    final db = ref.read(appDatabaseProvider);

    final age = int.tryParse(_ageCtrl.text.trim());
    final poids = double.tryParse(_poidsCtrl.text.trim());
    final taille = double.tryParse(_tailleCtrl.text.trim());

    int? fcMaxResolu = fcMax;
    String srcResolu = fcMax != null ? 'manual' : _hrMaxSource;
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
      hrRestSource: Value(fcRepos != null ? 'manual' : null),
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
          if (enregistrement && _modeCPhase == null)
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
    final hrColor = (enregistrement && acq.isOverRef) ? Colors.red : _teal;

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

        // Garde-fou (modes A/D uniquement)
        if (enregistrement &&
            acq.intensityRefBpm != null &&
            _modeCPhase == null) ...[
          _intensitePanel(acq),
          const SizedBox(height: 8),
        ],

        // FC instantanée (toujours visible quand connecté)
        Center(
          child: Column(
            children: [
              Text('${acq.lastHr}',
                  style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: hrColor)),
              const Text('bpm', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Métriques HRV (masquées pendant la stabilisation mode C)
        if (_modeCPhase != _ModeCPhase.stabilisant) ...[
          Row(
            children: [
              _metric('RMSSD', '$rmssd ms', _teal),
              _metric('Artefacts', '$artifactPct %',
                  acq.artifactRatio > 0.05 ? Colors.red : _teal),
              _metric('Battements', '${acq.beatsInWindow}', _orange),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Panneau principal : Mode C OU commandes normales
        if (_modeCPhase != null)
          Expanded(
            child: SafeArea(
              top: false, // l'AppBar gère déjà le haut
              child: _modeCPanel(_modeCPhase!, acq),
            ),
          )
        else if (!enregistrement) ...[
          if (_dernierSummaireD != null) ...[
            _banner(_dernierSummaireD!, _teal),
          ],
          // Sélecteur de mode
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              const Text('Mode : ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('A — Activité'),
                selected: _modeSession == 'A',
                onSelected: (_) => setState(() => _modeSession = 'A'),
                selectedColor: _orange.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('C — Readiness'),
                selected: _modeSession == 'C',
                onSelected: (_) => setState(() => _modeSession = 'C'),
                selectedColor: _teal.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('D — Journée pro'),
                selected: _modeSession == 'D',
                onSelected: (_) => setState(() => _modeSession = 'D'),
                selectedColor: _teal.withValues(alpha: 0.2),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: _modeSession == 'C' ? _teal : _orange),
            icon: Icon(_modeSession == 'C'
                ? Icons.bedtime_outlined
                : Icons.fiber_manual_record),
            label: Text(_modeSession == 'C'
                ? 'Démarrer readiness du matin'
                : 'Démarrer enregistrement'),
            onPressed: _modeSession == 'C'
                ? _demarrerModeC
                : _demarrerEnregistrement,
          ),
        ] else ...[
          _champNum(
            'RPE physique CR10 (0–10) — à saisir avant d\'arrêter',
            _rpePhysCtrl,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.stop),
            label: const Text('Arrêter enregistrement'),
            onPressed: _arreterEnregistrement,
          ),
        ],

        if (_modeCPhase == null)
          Expanded(
            child: SafeArea(
              top: false, // l'AppBar gère déjà le haut
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════ MODE C ═══════════════════════════════════

  void _demarrerModeC() {
    _modeCTimer?.cancel();
    setState(() {
      _modeCPhase = _ModeCPhase.stabilisant;
      _modeCElapsedSec = 0;
      _modeCSessionId = null;
      _modeCRmssd = double.nan;
      _modeCMeanHr = double.nan;
      _modeCSd1 = double.nan;
      _modeCSd2 = double.nan;
      _hooperFatigue = 4;
      _hooperStress = 4;
      _hooperDoms = 4;
      _hooperSleep = 4;
      _modeCReadinessMsg = '';
      _modeCSessionCount = 0;
    });
    _modeCTimer = Timer.periodic(const Duration(seconds: 1), _modeCTick);
  }

  void _modeCTick(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    setState(() => _modeCElapsedSec++);

    if (_modeCElapsedSec == _stabS) {
      // Fin de stabilisation → démarrer l'enregistrement
      _initialiserMesure();
    } else if (_modeCElapsedSec >= _totalS) {
      // Fin des 2 min de mesure
      t.cancel();
      _modeCTimer = null;
      _finirMesureModeC();
    }
  }

  Future<void> _initialiserMesure() async {
    await ref.read(acquisitionProvider.notifier).startRecording(mode: 'C');
    if (!mounted) return;

    // Retrouver l'id de la session ouverte (mode C, sans endedAt)
    final db = ref.read(appDatabaseProvider);
    final sessions = await db.sessionDao.getAll();
    final open = sessions
        .where((s) => s.endedAt == null && s.mode == 'C')
        .firstOrNull;

    if (!mounted) return;
    setState(() {
      _modeCSessionId = open?.id;
      _modeCPhase = _ModeCPhase.mesurant;
    });
  }

  Future<void> _finirMesureModeC() async {
    await ref.read(acquisitionProvider.notifier).stopRecording();
    if (!mounted) return;

    // Lire les indicateurs écrits par stopRecording
    final db = ref.read(appDatabaseProvider);
    final sid = _modeCSessionId;
    if (sid != null) {
      final indics = await db.indicatorDao.forSession(sid);
      double find(String kind) {
        for (final i in indics) {
          if (i.kind == kind) return i.value;
        }
        return double.nan;
      }

      _modeCRmssd = find('rmssd');
      _modeCMeanHr = find('meanHr');
      _modeCSd1 = find('sd1');
      _modeCSd2 = find('sd2');
    }

    if (!mounted) return;
    setState(() => _modeCPhase = _ModeCPhase.questionnaire);
  }

  Future<void> _annulerModeC() async {
    _modeCTimer?.cancel();
    _modeCTimer = null;
    // Appel systématique : no-op si aucune session n'est ouverte (phase
    // stabilisant, T<60s), ferme proprement si une session est en cours.
    // Couvre aussi la fenêtre de chevauchement entre le tick T=60 et le
    // retour du setState de _initialiserMesure (phase encore stabilisant
    // mais startRecording déjà appelé).
    await ref.read(acquisitionProvider.notifier).stopRecording();
    if (!mounted) return;
    setState(() {
      _modeCPhase = null;
      _modeCElapsedSec = 0;
      _modeCSessionId = null;
    });
  }

  Future<void> _soumettreHooper() async {
    final userId = _userId;
    final sid = _modeCSessionId;
    if (userId == null || sid == null) {
      // Cas dégradé : pas d'id de session (mesure BLE interrompue), on saute.
      if (mounted) setState(() => _modeCPhase = _ModeCPhase.resultat);
      return;
    }

    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();

    // Persister l'entrée Hooper liée à la session
    await db.hooperDao.insertEntry(HooperMackinnonEntriesCompanion.insert(
      sessionId: sid,
      userId: userId,
      fatigue: _hooperFatigue,
      stress: _hooperStress,
      doms: _hooperDoms,
      sleep: _hooperSleep,
      recordedAt: now,
    ));

    // Récupérer l'historique pour les lignes de base
    final allRmssd = await db.indicatorDao.getRmssdForModeC(userId);
    final allHooper = await db.hooperDao.getAllByUser(userId);
    final hooperScores = allHooper
        .map((h) => (h.fatigue + h.stress + h.doms + h.sleep).toDouble())
        .toList();

    final rmssdBaseline = computeBaseline(allRmssd);
    final hooperBaseline = computeBaseline(hooperScores);

    final hooperTotal = computeHooperScore(
      fatigue: _hooperFatigue,
      stress: _hooperStress,
      doms: _hooperDoms,
      sleep: _hooperSleep,
    );

    final classification = classifyReadiness(
      rmssdToday: _modeCRmssd,
      rmssdBaseline: rmssdBaseline,
      hooperScoreToday: hooperTotal.toDouble(),
      hooperBaseline: hooperBaseline,
    );

    // Message adapté : si indicative, injecter le compteur réel.
    final count = allRmssd.length; // inclut la séance du jour
    final msg = classification == ReadinessClassification.indicative
        ? 'Données en cours d\'accumulation ($count/${BaselineStats.minSessions} séances) '
            '— les résultats seront comparatifs à partir de la séance ${BaselineStats.minSessions}.'
        : readinessMessage(classification);

    if (!mounted) return;
    setState(() {
      _modeCSessionCount = count;
      _modeCReadinessMsg = msg;
      _modeCPhase = _ModeCPhase.resultat;
    });
  }

  // ── Panneaux Mode C ───────────────────────────────────────────────────────

  Widget _modeCPanel(_ModeCPhase phase, AcquisitionState acq) {
    return switch (phase) {
      _ModeCPhase.stabilisant => _phaseStabilisant(),
      _ModeCPhase.mesurant => _phaseMesurant(acq),
      _ModeCPhase.questionnaire => _phaseQuestionnaire(),
      _ModeCPhase.resultat => _phaseResultat(),
    };
  }

  Widget _phaseStabilisant() {
    final remaining = _stabS - _modeCElapsedSec;
    final progress = _modeCElapsedSec / _stabS;

    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'Stabilisation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reste immobile, respire calmement.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  color: _teal.withValues(alpha: 0.6),
                  backgroundColor: Colors.grey.shade200,
                ),
                Text(
                  '${remaining}s',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La mesure démarrera dans ${remaining}s',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _annulerModeC,
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _phaseMesurant(AcquisitionState acq) {
    final elapsed = _modeCElapsedSec - _stabS; // secondes écoulées depuis la mesure
    final remaining = _mesureS - elapsed;
    final progress = elapsed / _mesureS;

    return SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'Mesure en cours',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Reste immobile. L\'app enregistre ta variabilité.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  color: _teal,
                  backgroundColor: Colors.grey.shade200,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${remaining}s',
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const Text('restantes',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Signal de qualité indicatif (sans valeur numérique brute)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  acq.artifactRatio > 0.3
                      ? Icons.signal_cellular_alt_1_bar
                      : acq.artifactRatio > 0.1
                          ? Icons.signal_cellular_alt_2_bar
                          : Icons.signal_cellular_alt,
                  color: acq.artifactRatio > 0.3
                      ? Colors.orange
                      : _teal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  acq.artifactRatio > 0.3
                      ? 'Signal bruité — reste immobile'
                      : 'Signal correct',
                  style: TextStyle(
                    color: acq.artifactRatio > 0.3
                        ? Colors.orange.shade800
                        : _teal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: _annulerModeC,
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _phaseQuestionnaire() {
    final hooperTotal = _hooperFatigue + _hooperStress + _hooperDoms + _hooperSleep;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Comment tu te sens ce matin ?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            '1 = Excellent  ·  7 = Très mauvais',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _hooperSlider(
            'Fatigue générale',
            _hooperFatigue,
            (v) => setState(() => _hooperFatigue = v),
          ),
          _hooperSlider(
            'Stress du matin',
            _hooperStress,
            (v) => setState(() => _hooperStress = v),
          ),
          _hooperSlider(
            'Courbatures',
            _hooperDoms,
            (v) => setState(() => _hooperDoms = v),
          ),
          _hooperSlider(
            'Qualité du sommeil',
            _hooperSleep,
            (v) => setState(() => _hooperSleep = v),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Score total',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '$hooperTotal / 28',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: hooperTotal > 20 ? Colors.red : _teal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _teal),
            onPressed: _soumettreHooper,
            child: const Text('Valider et voir le résultat'),
          ),
        ],
      ),
    );
  }

  Widget _phaseResultat() {
    final rmssdStr = _modeCRmssd.isNaN
        ? '—'
        : '${_modeCRmssd.toStringAsFixed(1)} ms';
    final hrRestStr = _modeCMeanHr.isNaN
        ? '—'
        : '${_modeCMeanHr.round()} bpm';
    final sd1Str = _modeCSd1.isNaN ? '—' : _modeCSd1.toStringAsFixed(1);
    final sd2Str = _modeCSd2.isNaN ? '—' : _modeCSd2.toStringAsFixed(1);
    final hooperTotal = _hooperFatigue + _hooperStress + _hooperDoms + _hooperSleep;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Résultat du matin',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Bloc HRV
          _resultCard(
            title: 'Variabilité cardiaque',
            color: _teal,
            children: [
              _resultRow('RMSSD', rmssdStr),
              _resultRow('FC repos mesurée', hrRestStr),
              if (!_modeCSd1.isNaN) _resultRow('SD1 (Poincaré)', '$sd1Str ms'),
              if (!_modeCSd2.isNaN) _resultRow('SD2 (Poincaré)', '$sd2Str ms'),
            ],
          ),
          const SizedBox(height: 12),

          // Bloc Hooper
          _resultCard(
            title: 'Ressenti du matin (Hooper)',
            color: _orange,
            children: [
              _resultRow('Fatigue', '$_hooperFatigue/7'),
              _resultRow('Stress', '$_hooperStress/7'),
              _resultRow('Courbatures', '$_hooperDoms/7'),
              _resultRow('Sommeil', '$_hooperSleep/7'),
              const Divider(height: 16),
              _resultRow('Score total', '$hooperTotal/28',
                  bold: true,
                  valueColor: hooperTotal > 20 ? Colors.red : _orange),
            ],
          ),
          const SizedBox(height: 12),

          // Bloc classification
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _teal.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _teal.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights, size: 18, color: _teal),
                    const SizedBox(width: 6),
                    const Text('Lecture du jour',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _teal)),
                    const Spacer(),
                    // Progression vers la ligne de base (honnêteté PD-6)
                    if (_modeCSessionCount < BaselineStats.minSessions)
                      _badge(
                        '$_modeCSessionCount/${BaselineStats.minSessions} séances',
                        Colors.grey.shade600,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_modeCReadinessMsg,
                    style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _teal),
            onPressed: () => setState(() {
              _modeCPhase = null;
              _modeSession = 'C'; // prêt pour la prochaine séance
            }),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  Widget _resultCard({
    required String title,
    required Color color,
    required List<Widget> children,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  Widget _resultRow(String label, String value,
      {bool bold = false, Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ],
        ),
      );

  Widget _hooperSlider(
    String label,
    int value,
    ValueChanged<int> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text('$value / 7',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _teal)),
              ],
            ),
            Row(
              children: [
                const Text('1', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 7,
                    divisions: 6,
                    value: value.toDouble(),
                    activeColor: value >= 6 ? _orange : _teal,
                    onChanged: (v) => onChanged(v.round()),
                  ),
                ),
                const Text('7', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      );

  // ══════════════════════════ PANEL INTENSITÉ (modes A/D) ═══════════════════

  Widget _intensitePanel(AcquisitionState acq) {
    final refBpm = acq.intensityRefBpm!;
    final label = acq.intensityRefLabel ?? '';
    final overrun = acq.isOverRef;
    final sec = acq.continuousOverrunSec;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: overrun ? Colors.red.shade50 : _teal.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: overrun ? Colors.red.shade300 : _teal.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            overrun ? Icons.warning_amber_rounded : Icons.speed,
            color: overrun ? Colors.red : _teal,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Référence : $refBpm bpm  ($label)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: overrun ? Colors.red.shade700 : _teal,
                  ),
                ),
                if (overrun)
                  Text(
                    'Dépassement : ${sec}s continus',
                    style:
                        TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Hors zone : ${acq.totalOverRefSec}s',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
              Text(
                'En zone : ${acq.totalUnderRefSec}s',
                style: TextStyle(fontSize: 11, color: Colors.green.shade700),
              ),
            ],
          ),
        ],
      ),
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

    final check = await ref
        .read(acquisitionProvider.notifier)
        .startRecording(mode: _modeSession);

    if (!mounted) return;

    if (!check.allowed) {
      await _dialogProfilIncomplet(check.missingFields);
      return;
    }

    final result = await manager.demarrerEnregistrement();

    if (!mounted) return;
    if (result is ServiceRequestFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur service : ${result.error}')),
      );
    }
  }

  Future<void> _dialogProfilIncomplet(List<String> champs) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profil incomplet'),
        content: Text(
          'Pour démarrer le garde-fou Intensité, complète d\'abord '
          'ces champs dans l\'onglet Profil :\n\n'
          '${champs.map((c) => '• $c').join('\n')}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _arreterEnregistrement() async {
    final db = ref.read(appDatabaseProvider);

    try {
      await ref.read(foregroundServiceManagerProvider).arreterEnregistrement();
    } catch (_) {}

    await ref.read(acquisitionProvider.notifier).stopRecording();

    final rpeVal = int.tryParse(_rpePhysCtrl.text.trim());
    if (rpeVal != null) {
      final sessions = await db.sessionDao.getAll();
      if (sessions.isNotEmpty) {
        final rpe = clamperRpe(rpeVal) ?? rpeVal;
        await db.sessionDao.setRpePhysical(sessions.first.id, rpe);
      }
      _rpePhysCtrl.clear();
    }

    if (mounted) _afficherSummaireD();
  }

  Future<void> _afficherSummaireD() async {
    final db = ref.read(appDatabaseProvider);
    final sessions = await db.sessionDao.getAll();
    final lastD = sessions
        .where((s) => s.mode == 'D' && s.endedAt != null)
        .firstOrNull;
    if (lastD == null || !mounted) return;

    final indics = await db.indicatorDao.forSession(lastD.id);
    final trimp =
        indics.where((i) => i.kind == 'trimp_banister').firstOrNull?.value;
    final coverage =
        indics.where((i) => i.kind == 'data_coverage_ratio').firstOrNull?.value;

    if (trimp == null || !mounted) return;

    final pct = coverage != null ? (coverage * 100).round() : 100;
    setState(() {
      _dernierSummaireD = (coverage != null && pct < 100)
          ? 'TRIMP Banister : ${trimp.toStringAsFixed(1)} UA — '
              'calculé sur $pct% de la séance (${ (100 - pct)}% coupures capteur).'
          : 'TRIMP Banister : ${trimp.toStringAsFixed(1)} UA — couverture complète.';
    });
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
    final sessionActive = ref.watch(acquisitionProvider).isSessionActive;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          if (sessionActive)
            _banner(
              'Séance en cours — modification impossible.',
              Colors.orange.shade700,
            ),
          Row(children: [
            Expanded(
                child: _champNum('FC repos (bpm)', _fcReposCtrl,
                    enabled: !sessionActive)),
            const SizedBox(width: 12),
            Expanded(
                child: _champNum('FC max (bpm)', _fcMaxCtrl,
                    enabled: !sessionActive)),
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
            Expanded(child: _champNum('RPE psycho (0–10)', _rpePsychoCtrl)),
            const SizedBox(width: 12),
            Expanded(
                child: _champNumSigne('Comparaison (−2..+2)', _rpeCompCtrl)),
          ]),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            onPressed: _userId != null ? _sauvegarderRpeJour : null,
            child: const Text('Sauvegarder RPE du jour'),
          ),

          const SizedBox(height: 20),
          if (_userId != null) _dailyEntriesReadBack(_userId!),
        ],
      ),
    );
  }

  Widget _dailyEntriesReadBack(String userId) {
    return ref.watch(dailyEntriesHistoryProvider(userId)).when(
      loading: () => const Text(
        'Aucune entrée journalière.',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (entries) {
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
          {bool decimal = false, bool enabled = true}) =>
      TextField(
        controller: ctrl,
        enabled: enabled,
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
              child: z.maxBpm == calib.aerobicCeiling
                  ? Text.rich(TextSpan(children: [
                      TextSpan(
                        text: '${z.label} : ${z.minBpm}–${z.maxBpm} bpm',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: _teal),
                      ),
                      const TextSpan(
                        text: '  ← garde-fou actif',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ]))
                  : Text('${z.label} : ${z.minBpm}–${z.maxBpm} bpm'),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════ ONGLET HISTORIQUE ════════════════════════

  Widget _historiqueTab() {
    final db = ref.read(appDatabaseProvider);
    return ref.watch(sessionsHistoryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (sessions) {
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
          padding: EdgeInsets.fromLTRB(
            12, 12, 12, 12 + MediaQuery.of(context).padding.bottom,
          ),
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
                          style: const TextStyle(fontWeight: FontWeight.w600)),
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
