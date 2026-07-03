import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'session_dao.g.dart';

@DriftAccessor(tables: [Sessions])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  Future<int> insertSession(SessionsCompanion entry) =>
      into(sessions).insert(entry);

  Future<void> closeSession(int id, DateTime endedAt, double qualityRatio) =>
      (update(sessions)..where((s) => s.id.equals(id))).write(
        SessionsCompanion(
          endedAt: Value(endedAt),
          qualityRatio: Value(qualityRatio),
        ),
      );

  /// Enregistre le RPE physique CR10 (0–10) à la clôture d'une activité.
  Future<void> setRpePhysical(int id, int rpe) =>
      (update(sessions)..where((s) => s.id.equals(id))).write(
        SessionsCompanion(rpePhysical: Value(rpe)),
      );

  /// Stream réactif de toutes les sessions, du plus récent au plus ancien.
  Stream<List<Session>> watchAll() =>
      (select(sessions)..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .watch();

  Future<List<Session>> getAll() =>
      (select(sessions)..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
          .get();

  /// Sessions dont endedAt est NULL — considérées orphelines au redémarrage.
  Future<List<Session>> getOrphanSessions() =>
      (select(sessions)..where((s) => s.endedAt.isNull())).get();
}
