import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Instance singleton de la base drift, partagée dans toute l'app.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
