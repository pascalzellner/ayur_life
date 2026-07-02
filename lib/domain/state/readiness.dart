/// Ligne de base HRV + Hooper-Mackinnon et classification Readiness.
///
/// Aucun seuil de littérature fixe — tout est individualisé par utilisateur.
/// Minimum 7 séances mode C avant que la ligne de base soit établie.
/// Vocabulaire non médical (EF-UX-03).
library;

import 'dart:math' as math;

// ── Ligne de base ─────────────────────────────────────────────────────────────

class BaselineStats {
  const BaselineStats({
    required this.mean,
    required this.stdDev,
    required this.count,
  });

  final double mean;
  final double stdDev;
  final int count;

  static const int minSessions = 7;

  bool get established => count >= minSessions;

  /// Seuil inférieur (RMSSD) : en dessous → déviation.
  double get lowerThreshold => mean - 2 * stdDev;

  /// Seuil supérieur (Hooper) : au-dessus → score élevé (état dégradé).
  double get upperThreshold => mean + 2 * stdDev;
}

/// Calcule la moyenne et l'écart-type population d'une série de valeurs.
/// Retourne null si la liste est vide.
BaselineStats? computeBaseline(List<double> values) {
  if (values.isEmpty) return null;
  final n = values.length;
  final mean = values.reduce((a, b) => a + b) / n;
  final variance =
      values.fold(0.0, (s, v) => s + (v - mean) * (v - mean)) / n;
  return BaselineStats(
    mean: mean,
    stdDev: math.sqrt(variance),
    count: n,
  );
}

// ── Score Hooper-Mackinnon ────────────────────────────────────────────────────

/// Score composite : somme des 4 items 1–7 (4 = très bon état, 28 = épuisement).
int computeHooperScore({
  required int fatigue,
  required int stress,
  required int doms,
  required int sleep,
}) =>
    fatigue + stress + doms + sleep;

// ── Classification croisée ────────────────────────────────────────────────────

enum ReadinessClassification {
  /// RMSSD normal + Hooper normal.
  noFatigue,

  /// RMSSD dévié + Hooper élevé (signaux concordants — fatigue marquée).
  markedFatigue,

  /// RMSSD dévié + Hooper normal (signal HRV seul).
  mixedHrvDown,

  /// RMSSD normal + Hooper élevé (signal subjectif seul).
  mixedHooperUp,

  /// Baseline non encore établie (< 7 séances) — résultat indicatif.
  indicative,
}

/// Texte affiché à l'utilisateur pour chaque classification.
/// Vocabulaire strictement non médical (EF-UX-03).
String readinessMessage(ReadinessClassification c) => switch (c) {
      ReadinessClassification.noFatigue => 'Pas de signe de fatigue.',
      ReadinessClassification.markedFatigue =>
        'Fatigue marquée — des signaux concordants indiquent une surcharge.',
      ReadinessClassification.mixedHrvDown =>
        'Signal mixte : ta variabilité s\'écarte de ta norme '
            'mais ton ressenti est bon — reste attentif.',
      ReadinessClassification.mixedHooperUp =>
        'Signal mixte : ton ressenti indique de la fatigue '
            'alors que ta variabilité est dans la norme — fie-toi à ton ressenti.',
      ReadinessClassification.indicative =>
        'Données en cours d\'accumulation '
            '(${BaselineStats.minSessions} séances nécessaires) — '
            'résultat indicatif uniquement.',
    };

/// Croise RMSSD du jour et score Hooper du jour avec leurs lignes de base.
///
/// - RMSSD dévié si inférieur à la limite basse (mean − 2σ).
/// - Hooper élevé si supérieur à la limite haute (mean + 2σ).
/// - Si l'une ou l'autre baseline n'est pas établie → [indicative].
ReadinessClassification classifyReadiness({
  required double rmssdToday,
  required BaselineStats? rmssdBaseline,
  required double hooperScoreToday,
  required BaselineStats? hooperBaseline,
}) {
  if (rmssdBaseline == null ||
      !rmssdBaseline.established ||
      hooperBaseline == null ||
      !hooperBaseline.established) {
    return ReadinessClassification.indicative;
  }

  final rmssdDeviated = rmssdToday < rmssdBaseline.lowerThreshold;
  final hooperElevated = hooperScoreToday > hooperBaseline.upperThreshold;

  if (!rmssdDeviated && !hooperElevated) return ReadinessClassification.noFatigue;
  if (rmssdDeviated && hooperElevated) return ReadinessClassification.markedFatigue;
  if (rmssdDeviated && !hooperElevated) return ReadinessClassification.mixedHrvDown;
  return ReadinessClassification.mixedHooperUp;
}
