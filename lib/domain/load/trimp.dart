/// TRIMP Banister — pur Dart, sans dépendance plateforme.
///
/// Formule (Banister 1991) :
///   ΔHR_ratio = (FC_segment − FCrepos) / (FCmax − FCrepos)
///   TRIMP_seg  = durée_min × ΔHR_ratio × k × e^(1.92 × ΔHR_ratio)
///
/// k = 0,64 (homme / 'autre') | 1,67 (femme).
/// 'autre' → coeff masculin (0,64) : borne basse conservative.
///
/// Calcul par segments d'1 minute depuis les intervalles RR pour capturer
/// l'amplification exponentielle des efforts intenses (un calcul sur la FC
/// moyenne globale sous-estimerait significativement la charge des pics).
library;

import 'dart:math' as math;

class TrimpResult {
  const TrimpResult({
    required this.trimpTotal,
    required this.dataCoverageRatio,
  });

  /// Charge d'entraînement cumulée en unités arbitraires (UA).
  final double trimpTotal;

  /// Fraction [0.0–1.0] de la durée totale couverte par des données valides.
  /// 1.0 = couverture complète ; 0.8 = 20 % de coupures capteur.
  final double dataCoverageRatio;
}

/// TRIMP Banister pour un segment de durée fixée.
///
/// Retourne 0 si [durationMin] ≤ 0, si FCmax ≤ FCrepos, ou si FC ≤ FCrepos.
double computeTrimpBanisterSegment({
  required double durationMin,
  required double hrSegment,
  required int hrRest,
  required int hrMax,
  required String sex,
}) {
  if (durationMin <= 0) return 0.0;
  if (hrMax <= hrRest) return 0.0;
  final ratio = (hrSegment - hrRest) / (hrMax - hrRest);
  if (ratio <= 0) return 0.0;
  final k = (sex == 'F') ? 1.67 : 0.64;
  return durationMin * ratio * k * math.exp(1.92 * ratio);
}

/// TRIMP Banister d'une session complète depuis les intervalles RR bruts.
///
/// Stratégie :
/// - Regrouper les RR valides (non [gap], rr > 0) par minute ([tMs] ÷ 60 000).
/// - Dériver la FC de chaque minute : 60 000 / mean(RR).
/// - Appliquer la formule Banister par segment d'1 minute.
/// - Segments marqués [gap] exclus du calcul mais comptés dans la durée totale
///   pour produire un [dataCoverageRatio] honnête (PD-6).
///
/// [samples] : triés par [tMs] ascendant.
/// [sessionDurationMs] : de startedAt à endedAt.
TrimpResult computeTrimpBanisterFromRr({
  required List<({int tMs, double rr, bool gap})> samples,
  required int hrRest,
  required int hrMax,
  required String sex,
  required int sessionDurationMs,
}) {
  if (sessionDurationMs <= 0) {
    return const TrimpResult(trimpTotal: 0.0, dataCoverageRatio: 0.0);
  }

  // Regrouper les RR valides par minute.
  final Map<int, List<double>> buckets = {};
  for (final s in samples) {
    if (!s.gap && s.rr > 0) {
      final minute = s.tMs ~/ 60000;
      buckets.putIfAbsent(minute, () => []).add(s.rr);
    }
  }

  // Sommer les TRIMP par segment.
  var trimpTotal = 0.0;
  for (final rrs in buckets.values) {
    final meanRr = rrs.reduce((a, b) => a + b) / rrs.length;
    if (meanRr <= 0) continue;
    final hr = 60000 / meanRr;
    trimpTotal += computeTrimpBanisterSegment(
      durationMin: 1.0,
      hrSegment: hr,
      hrRest: hrRest,
      hrMax: hrMax,
      sex: sex,
    );
  }

  // Couverture : minutes avec données / minutes totales attendues.
  final totalMinutes = (sessionDurationMs / 60000).ceil();
  final coverageRatio = totalMinutes > 0
      ? (buckets.length / totalMinutes).clamp(0.0, 1.0)
      : 0.0;

  return TrimpResult(trimpTotal: trimpTotal, dataCoverageRatio: coverageRatio);
}

/// TRIMP Banister d'une session depuis les mesures de FC brute (champ hr BLE).
///
/// Avantage vs [computeTrimpBanisterFromRr] : la FC est décodée directement de
/// chaque trame BLE, même lorsque les RR sont absents ou bruités (mouvement).
/// Le biais lié aux artefacts moteurs est ainsi éliminé.
///
/// Stratégie :
/// - Regrouper les FC valides (hr > 0) par minute ([tMs] ÷ 60 000).
/// - Calculer la FC moyenne de chaque minute.
/// - Appliquer la formule Banister par segment d'1 minute.
/// - Minutes sans données BLE (gap ≥ 1 min) exclues du TRIMP mais comptées
///   dans la durée totale → [dataCoverageRatio] honnête.
///
/// [samples] : triés par [tMs] ascendant.
/// [sessionDurationMs] : de startedAt à endedAt.
TrimpResult computeTrimpBanisterFromHr({
  required List<({int tMs, int hr})> samples,
  required int hrRest,
  required int hrMax,
  required String sex,
  required int sessionDurationMs,
}) {
  if (sessionDurationMs <= 0) {
    return const TrimpResult(trimpTotal: 0.0, dataCoverageRatio: 0.0);
  }

  final Map<int, List<int>> buckets = {};
  for (final s in samples) {
    if (s.hr > 0) {
      final minute = s.tMs ~/ 60000;
      buckets.putIfAbsent(minute, () => []).add(s.hr);
    }
  }

  var trimpTotal = 0.0;
  for (final hrs in buckets.values) {
    final meanHr = hrs.reduce((a, b) => a + b) / hrs.length;
    trimpTotal += computeTrimpBanisterSegment(
      durationMin: 1.0,
      hrSegment: meanHr,
      hrRest: hrRest,
      hrMax: hrMax,
      sex: sex,
    );
  }

  final totalMinutes = (sessionDurationMs / 60000).ceil();
  final coverageRatio = totalMinutes > 0
      ? (buckets.length / totalMinutes).clamp(0.0, 1.0)
      : 0.0;

  return TrimpResult(trimpTotal: trimpTotal, dataCoverageRatio: coverageRatio);
}
