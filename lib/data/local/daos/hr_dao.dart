import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'hr_dao.g.dart';

@DriftAccessor(tables: [HrSamples])
class HrDao extends DatabaseAccessor<AppDatabase> with _$HrDaoMixin {
  HrDao(super.db);

  Future<void> insertBatch(List<HrSamplesCompanion> rows) =>
      batch((b) => b.insertAll(hrSamples, rows));

  Future<List<HrSample>> getForSession(int sessionId) =>
      (select(hrSamples)
            ..where((r) => r.sessionId.equals(sessionId))
            ..orderBy([(r) => OrderingTerm.asc(r.tMs)]))
          .get();
}
