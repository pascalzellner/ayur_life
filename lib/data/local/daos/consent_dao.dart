import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'consent_dao.g.dart';

/// ConsentLog est APPEND-ONLY : pas de update/delete exposés.
@DriftAccessor(tables: [ConsentLog])
class ConsentDao extends DatabaseAccessor<AppDatabase> with _$ConsentDaoMixin {
  ConsentDao(super.db);

  Future<int> insertConsent(ConsentLogCompanion entry) =>
      into(consentLog).insert(entry);

  Future<List<ConsentLogData>> allForUser(String userId) =>
      (select(consentLog)
            ..where((c) => c.userId.equals(userId))
            ..orderBy([(c) => OrderingTerm.desc(c.acceptedAt)]))
          .get();
}
