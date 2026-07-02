import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'indicator_dao.g.dart';

@DriftAccessor(tables: [Indicators, Sessions])
class IndicatorDao extends DatabaseAccessor<AppDatabase>
    with _$IndicatorDaoMixin {
  IndicatorDao(super.db);

  Future<void> insertAll(List<IndicatorsCompanion> rows) =>
      batch((b) => b.insertAll(indicators, rows));

  /// Tous les indicateurs d'une session (lecture directe, pas de stream
  /// nécessaire ici — les sessions passées ne changent plus).
  Future<List<Indicator>> forSession(int sessionId) =>
      (select(indicators)..where((i) => i.sessionId.equals(sessionId))).get();

  /// Dernier indicateur d'un kind donné, toutes sessions confondues.
  Future<Indicator?> latestOf(String kind) =>
      (select(indicators)
            ..where((i) => i.kind.equals(kind))
            ..orderBy([(i) => OrderingTerm.desc(i.at)])
            ..limit(1))
          .getSingleOrNull();

  /// RMSSD de toutes les séances mode C d'un utilisateur,
  /// des plus anciennes aux plus récentes — pour le calcul de la ligne de base.
  /// Ne mélange jamais les modes (conditions de mesure différentes).
  Future<List<double>> getRmssdForModeC(String userId) async {
    final query = select(indicators).join([
      innerJoin(sessions, sessions.id.equalsExp(indicators.sessionId)),
    ])
      ..where(sessions.userId.equals(userId))
      ..where(sessions.mode.equals('C'))
      ..where(indicators.kind.equals('rmssd'))
      ..orderBy([OrderingTerm.asc(indicators.at)]);

    final rows = await query.get();
    return rows.map((r) => r.read(indicators.value)!).toList();
  }
}
