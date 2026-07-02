import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'rr_dao.g.dart';

@DriftAccessor(tables: [RrSamples])
class RrDao extends DatabaseAccessor<AppDatabase> with _$RrDaoMixin {
  RrDao(super.db);

  /// Flush par lot : insère les RR en une seule transaction (ET-ACQ-04).
  Future<void> insertBatch(List<RrSamplesCompanion> rows) =>
      batch((b) => b.insertAll(rrSamples, rows));

  Future<int> countForSession(int sessionId) async {
    final count = countAll();
    final query = selectOnly(rrSamples)
      ..addColumns([count])
      ..where(rrSamples.sessionId.equals(sessionId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Tous les RR d'une session (incluant les lignes gap) triés par tMs.
  /// Utilisé pour le calcul TRIMP Banister en fin de session mode D.
  Future<List<RrSample>> getRrForTrimp(int sessionId) =>
      (select(rrSamples)
            ..where((r) => r.sessionId.equals(sessionId))
            ..orderBy([(r) => OrderingTerm.asc(r.tMs)]))
          .get();
}
