import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Instance singleton de la base drift, partagée dans toute l'app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Stream stable de toutes les sessions, du plus récent au plus ancien.
///
/// Défini ici comme StreamProvider (et non recréé dans chaque build()) pour
/// que le drift .watch() sous-jacent soit créé une seule fois et reste vivant
/// quelle que soit la fréquence des rebuilds UI — en particulier les rebuilds
/// déclenchés à chaque battement BLE via acquisitionProvider.
final sessionsHistoryProvider = StreamProvider<List<Session>>((ref) {
  return ref.watch(appDatabaseProvider).sessionDao.watchAll();
});

/// Stream stable des [limit] entrées journalières les plus récentes pour
/// l'utilisateur donné. Même motivation que [sessionsHistoryProvider].
final dailyEntriesHistoryProvider =
    StreamProvider.family<List<DailyEntry>, String>((ref, userId) {
  return ref.watch(appDatabaseProvider).dailyEntryDao.watchRecent(userId);
});
