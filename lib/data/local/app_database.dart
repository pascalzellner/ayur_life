import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/load/calibration.dart' show estimateHrMaxTanaka;
import '../../domain/load/trimp.dart';
import 'daos/consent_dao.dart';
import 'daos/daily_entry_dao.dart';
import 'daos/hooper_dao.dart';
import 'daos/hr_dao.dart';
import 'daos/indicator_dao.dart';
import 'daos/profile_dao.dart';
import 'daos/rr_dao.dart';
import 'daos/session_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Sessions,
    Indicators,
    RrSamples,
    HrSamples,
    ConsentLog,
    Profile,
    DailyEntries,
    HooperMackinnonEntries,
  ],
  daos: [
    SessionDao,
    IndicatorDao,
    RrDao,
    HrDao,
    ProfileDao,
    ConsentDao,
    DailyEntryDao,
    HooperDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(
                sessions, sessions.rpePhysical as GeneratedColumn<Object>);
            await m.createTable(dailyEntries);
          }
          if (from < 3) {
            await m.addColumn(
                profile, profile.hrRestSource as GeneratedColumn<Object>);
          }
          if (from < 4) {
            await m.createTable(hooperMackinnonEntries);
          }
          if (from < 5) {
            await m.createTable(hrSamples);
          }
        },
        beforeOpen: (details) async {
          // Clôturer les sessions orphelines (endedAt IS NULL) laissées par
          // un kill du process inattendu — avant tout autre traitement.
          await closeOrphanSessions();
        },
      );

  /// Détecte et clôture toutes les sessions dont [endedAt] est NULL.
  ///
  /// Appelé automatiquement dans [beforeOpen] : toute session encore ouverte
  /// au démarrage est par construction orpheline (le process Dart qui l'a
  /// créée n'existe plus). Les indicateurs sont calculés depuis les données
  /// déjà persistées ; un marqueur [shutdown_recovery] distingue ce cas de
  /// l'arrêt manuel et de l'échec de reconnexion BLE.
  Future<void> closeOrphanSessions() async {
    final orphans = await sessionDao.getOrphanSessions();
    if (orphans.isEmpty) return;

    final closeAt = DateTime.now();
    for (final session in orphans) {
      await transaction(() => _recoverOrphanSession(session, closeAt));
    }
  }

  Future<void> _recoverOrphanSession(Session session, DateTime closeAt) async {
    final rawRr = await rrDao.getRrForTrimp(session.id);
    final rawHr = await hrDao.getForSession(session.id);
    final totalBeats = rawRr.where((r) => !r.gap && r.rr > 0).length;

    // endedAt = max(dernier RR, dernier HR) → exclut le temps mort entre crash
    // et redémarrage. tMs = offset ms depuis startedAt (référentiel relatif).
    // Cas limite (aucune donnée) → startedAt : durée nulle, 0% légitime.
    int maxTMs = rawRr.isNotEmpty ? rawRr.last.tMs : 0;
    if (rawHr.isNotEmpty && rawHr.last.tMs > maxTMs) {
      maxTMs = rawHr.last.tMs;
    }
    final DateTime endedAt = maxTMs > 0
        ? session.startedAt.add(Duration(milliseconds: maxTMs))
        : session.startedAt;

    final indicators = <IndicatorsCompanion>[
      IndicatorsCompanion(
        sessionId: Value(session.id),
        kind: const Value('totalBeats'),
        value: Value(totalBeats.toDouble()),
        at: Value(closeAt),
      ),
      // Marqueur de provenance — distingue arrêt manuel et échec BLE.
      IndicatorsCompanion(
        sessionId: Value(session.id),
        kind: const Value('shutdown_recovery'),
        value: const Value(1.0),
        at: Value(closeAt),
      ),
    ];

    // TRIMP Banister (modes A et D) : HR si disponible, fallback RR sinon.
    if (session.mode == 'D' || session.mode == 'A') {
      final p = await profileDao.getProfile(session.userId);
      final hrRest = p?.hrRest;
      final hrMax =
          p?.hrMax ?? (p?.age != null ? estimateHrMaxTanaka(p!.age!) : null);
      if (hrRest != null && hrMax != null) {
        final sex = p?.sex ?? 'M';
        final sessionDurationMs =
            endedAt.difference(session.startedAt).inMilliseconds;
        final TrimpResult trimp;
        if (rawHr.isNotEmpty) {
          // Méthode principale : FC brute, non biaisée par les artefacts RR.
          trimp = computeTrimpBanisterFromHr(
            samples: rawHr.map((r) => (tMs: r.tMs, hr: r.hr)).toList(),
            hrRest: hrRest,
            hrMax: hrMax,
            sex: sex,
            sessionDurationMs: sessionDurationMs,
          );
        } else {
          // Fallback RR : sessions antérieures à l'introduction de HrSamples.
          trimp = computeTrimpBanisterFromRr(
            samples: rawRr.map((r) => (tMs: r.tMs, rr: r.rr, gap: r.gap)).toList(),
            hrRest: hrRest,
            hrMax: hrMax,
            sex: sex,
            sessionDurationMs: sessionDurationMs,
          );
        }
        indicators.addAll([
          IndicatorsCompanion(
            sessionId: Value(session.id),
            kind: const Value('trimp_banister'),
            value: Value(trimp.trimpTotal),
            at: Value(closeAt),
          ),
          IndicatorsCompanion(
            sessionId: Value(session.id),
            kind: const Value('data_coverage_ratio'),
            value: Value(trimp.dataCoverageRatio),
            at: Value(closeAt),
          ),
        ]);
      }
    }

    await indicatorDao.insertAll(indicators);
    // qualityRatio = 0.0 : état HRV in-memory perdu lors du kill, ratio inconnu.
    await sessionDao.closeSession(session.id, endedAt, 0.0);
  }

  /// Purge les données à rétention courte (RrSamples + HrSamples) antérieures
  /// à [cutoff] en conservant les Indicators.
  Future<void> purgeRrSamples(DateTime cutoff) async {
    final oldSessionIds = await (select(sessions)
          ..where((s) => s.endedAt.isSmallerThanValue(cutoff)))
        .map((s) => s.id)
        .get();

    if (oldSessionIds.isEmpty) return;

    await (delete(rrSamples)
          ..where((rr) => rr.sessionId.isIn(oldSessionIds)))
        .go();
    await (delete(hrSamples)
          ..where((r) => r.sessionId.isIn(oldSessionIds)))
        .go();
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dir.path, 'ayur_life.db'));
    return NativeDatabase.createInBackground(dbFile);
  });
}
