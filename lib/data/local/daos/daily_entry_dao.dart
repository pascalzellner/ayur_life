import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'daily_entry_dao.g.dart';

@DriftAccessor(tables: [DailyEntries])
class DailyEntryDao extends DatabaseAccessor<AppDatabase>
    with _$DailyEntryDaoMixin {
  DailyEntryDao(super.db);

  /// Crée ou met à jour l'entrée du jour (upsert sur PK {userId, day}).
  Future<void> upsertEntry(DailyEntriesCompanion entry) =>
      into(dailyEntries).insertOnConflictUpdate(entry);

  /// Entrée pour un jour précis, null si inexistante.
  Future<DailyEntry?> forDay(String userId, DateTime day) =>
      (select(dailyEntries)
            ..where((e) => e.userId.equals(userId) & e.day.equals(day)))
          .getSingleOrNull();

  /// Stream des [limit] entrées les plus récentes (pour le read-back debug).
  Stream<List<DailyEntry>> watchRecent(String userId, {int limit = 7}) =>
      (select(dailyEntries)
            ..where((e) => e.userId.equals(userId))
            ..orderBy([(e) => OrderingTerm.desc(e.day)])
            ..limit(limit))
          .watch();
}
