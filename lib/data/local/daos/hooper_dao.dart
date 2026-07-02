import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'hooper_dao.g.dart';

@DriftAccessor(tables: [HooperMackinnonEntries])
class HooperDao extends DatabaseAccessor<AppDatabase>
    with _$HooperDaoMixin {
  HooperDao(super.db);

  Future<void> insertEntry(HooperMackinnonEntriesCompanion entry) =>
      into(hooperMackinnonEntries).insert(entry);

  Future<HooperMackinnonEntry?> forSession(int sessionId) =>
      (select(hooperMackinnonEntries)
            ..where((h) => h.sessionId.equals(sessionId)))
          .getSingleOrNull();

  /// Tous les scores Hooper d'un utilisateur, du plus récent au plus ancien.
  Future<List<HooperMackinnonEntry>> getAllByUser(String userId) =>
      (select(hooperMackinnonEntries)
            ..where((h) => h.userId.equals(userId))
            ..orderBy([(h) => OrderingTerm.desc(h.recordedAt)]))
          .get();
}
