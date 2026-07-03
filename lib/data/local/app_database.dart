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
    ConsentLog,
    Profile,
    DailyEntries,
    HooperMackinnonEntries,
  ],
  daos: [
    SessionDao,
    IndicatorDao,
    RrDao,
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
  int get schemaVersion => 4;

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
    final totalBeats = rawRr.where((r) => !r.gap && r.rr > 0).length;

    // endedAt = dernier RR persisté → exclut le temps mort entre le crash et le
    // redémarrage. tMs = offset ms depuis startedAt (pas un timestamp epoch).
    // Cas limite (aucun RR) → startedAt : durée nulle, 0% légitime.
    final DateTime endedAt;
    if (rawRr.isNotEmpty) {
      endedAt = session.startedAt.add(Duration(milliseconds: rawRr.last.tMs));
    } else {
      endedAt = session.startedAt;
    }

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

    // TRIMP Banister (mode D) — calculé depuis les RR déjà en base.
    if (session.mode == 'D') {
      final p = await profileDao.getProfile(session.userId);
      final hrRest = p?.hrRest;
      final hrMax = p?.hrMax ??
          (p?.age != null ? estimateHrMaxTanaka(p!.age!) : null);
      if (hrRest != null && hrMax != null) {
        final samples =
            rawRr.map((r) => (tMs: r.tMs, rr: r.rr, gap: r.gap)).toList();
        final sessionDurationMs =
            endedAt.difference(session.startedAt).inMilliseconds;
        final trimp = computeTrimpBanisterFromRr(
          samples: samples,
          hrRest: hrRest,
          hrMax: hrMax,
          sex: p!.sex ?? 'M',
          sessionDurationMs: sessionDurationMs,
        );
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

  /// Purge les RrSamples antérieurs à [cutoff] en conservant les Indicators.
  /// À appeler au démarrage de l'app (exigence de rétention courte).
  Future<void> purgeRrSamples(DateTime cutoff) async {
    final oldSessionIds = await (select(sessions)
          ..where((s) => s.endedAt.isSmallerThanValue(cutoff)))
        .map((s) => s.id)
        .get();

    if (oldSessionIds.isEmpty) return;

    await (delete(rrSamples)
          ..where((rr) => rr.sessionId.isIn(oldSessionIds)))
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
