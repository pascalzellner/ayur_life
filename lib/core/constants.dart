/// Constantes configurables de l'application.
///
/// Les valeurs de rétention sont provisoires — à chiffrer avec les données
/// terrain (taille moyenne d'une session, fréquence d'utilisation).
library;

class AppConstants {
  AppConstants._();

  // ── Rétention ──────────────────────────────────────────────────────────────

  /// Durée maximale de conservation des échantillons RR bruts (rétention courte).
  /// Au-delà, purgeRrSamples() supprime les lignes.
  static const rrRetentionDays = 30;

  /// Durée de conservation des indicateurs agrégés (rétention longue).
  /// Null = pas de purge automatique en phase 1.
  static const indicatorRetentionDays = null; // longue — à définir phase 2

  // ── Flush des RR pendant la session ────────────────────────────────────────

  /// Intervalle entre deux flush des RR bruts en base (exigence ET-ACQ-04).
  static const rrFlushIntervalSeconds = 30;

  // ── Fenêtre HRV ────────────────────────────────────────────────────────────

  /// Fenêtre glissante RMSSD (ms).
  static const hrvWindowMs = 120000; // 2 min
}
