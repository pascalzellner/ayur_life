import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [Profile])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  /// Lecture du profil courant (null si jamais renseigné).
  Future<ProfileData?> getProfile(String userId) =>
      (select(profile)..where((p) => p.userId.equals(userId)))
          .getSingleOrNull();

  /// Upsert : crée ou remplace la ligne courante du profil.
  Future<void> upsertProfile(ProfileCompanion entry) =>
      into(profile).insertOnConflictUpdate(entry);

  /// Enregistre la FC de repos issue d'une séance mode C (provenance traçée).
  Future<void> setHrRestFromModeC(String userId, int hrRest) =>
      upsertProfile(ProfileCompanion(
        userId: Value(userId),
        hrRest: Value(hrRest),
        hrRestSource: const Value('mode_c'),
        updatedAt: Value(DateTime.now()),
      ));
}
