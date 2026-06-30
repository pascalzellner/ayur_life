import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

/// Point unique de génération et de lecture du userId local.
///
/// En phase 1, l'identité est un UUID v4 généré localement au premier lancement
/// et persisté dans un fichier texte simple. Quand Supabase arrivera (phase 2),
/// remplacer l'implémentation ici : toutes les tables drift portent déjà le
/// même userId, donc la migration cloud se fera sans réécriture.
class UserIdService {
  static const _filename = '.ayur_user_id';

  static String? _cached;

  static Future<String> get userId async {
    if (_cached != null) return _cached!;

    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_filename');

    if (await file.exists()) {
      _cached = (await file.readAsString()).trim();
    } else {
      _cached = _generateUuidV4();
      await file.writeAsString(_cached!);
    }
    return _cached!;
  }

  static String _generateUuidV4() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant RFC 4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
