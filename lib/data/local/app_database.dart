import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
      );

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
