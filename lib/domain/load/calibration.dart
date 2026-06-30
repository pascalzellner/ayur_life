/// Calculs de calibration cardio — pur Dart, sans dépendance plateforme.
///
/// Toutes les fonctions portent la PROVENANCE avec le résultat :
/// on ne traite jamais une estimation Karvonen comme un seuil mesuré (PD-6).
library;

// ── Types de sortie ───────────────────────────────────────────────────────────

enum ThresholdProvenance {
  measuredModeB,      // FC@SV1/SV2 mesurée en mode B (DFA α1)
  estimatedKarvonen,  // plafond estimé ~70 % FCR
  manualLab,          // valeur saisie manuellement (test labo externe)
}

class HrZone {
  const HrZone({
    required this.label,
    required this.minBpm,
    required this.maxBpm,
    required this.provenance,
  });

  final String label;
  final int minBpm;
  final int maxBpm;
  final ThresholdProvenance provenance;

  @override
  String toString() =>
      '$label : $minBpm–$maxBpm bpm (${provenance.name})';
}

class CalibrationResult {
  const CalibrationResult({
    required this.aerobicCeiling,
    required this.aerobicCeilingProvenance,
    required this.zones,
  });

  /// Plafond aérobie en bpm (proxy SV1 avant mesure mode B).
  final int aerobicCeiling;
  final ThresholdProvenance aerobicCeilingProvenance;

  /// Zones dérivées (Z1 sous aérobie, Z2 supra-aérobie).
  final List<HrZone> zones;
}

// ── FCmax — formule Tanaka ────────────────────────────────────────────────────

/// FC maximale estimée par la formule Tanaka (2001) : 208 − 0,7 × âge.
/// Ne sert que si FCmax n'est pas mesurée.
int estimateHrMaxTanaka(int age) => (208 - 0.7 * age).round();

// ── Plafond aérobie — Karvonen ────────────────────────────────────────────────

/// Plafond aérobie estimé (~70 % de la FCR = FC de réserve).
/// FCR = FCmax − FCrepos.
/// Retourne null si les données manquent.
int? estimateAerobicCeilingKarvonen({
  required int hrRest,
  required int hrMax,
  double fraction = 0.70,
}) {
  if (hrRest <= 0 || hrMax <= hrRest) return null;
  final fcr = hrMax - hrRest;
  return (hrRest + fraction * fcr).round();
}

// ── Point d'entrée principal ──────────────────────────────────────────────────

/// Dérive les zones et le plafond aérobie depuis les données de profil.
///
/// Priorité : seuils mesurés mode B > estimation Karvonen.
/// La provenance suit toujours chaque valeur.
CalibrationResult? computeZones({
  required int? age,
  required int? hrRest,
  required int? hrMax,
  required String? hrMaxSource,
  required int? fcSv1,
  required int? fcSv2,
  required String? thresholdProvenance,
}) {
  // Résoudre FCmax
  int? resolvedHrMax = hrMax;
  if (resolvedHrMax == null && age != null) {
    resolvedHrMax = estimateHrMaxTanaka(age);
  }
  if (resolvedHrMax == null || hrRest == null) return null;

  // Choisir le plafond aérobie et sa provenance
  final int aerobicCeiling;
  final ThresholdProvenance ceilingProv;

  if (fcSv1 != null &&
      thresholdProvenance == ThresholdProvenance.measuredModeB.name) {
    aerobicCeiling = fcSv1;
    ceilingProv = ThresholdProvenance.measuredModeB;
  } else if (fcSv1 != null &&
      thresholdProvenance == ThresholdProvenance.manualLab.name) {
    aerobicCeiling = fcSv1;
    ceilingProv = ThresholdProvenance.manualLab;
  } else {
    final estimated = estimateAerobicCeilingKarvonen(
      hrRest: hrRest,
      hrMax: resolvedHrMax,
    );
    if (estimated == null) return null;
    aerobicCeiling = estimated;
    ceilingProv = ThresholdProvenance.estimatedKarvonen;
  }

  // Zones (simplifiées phase 1 : Z1 sous SV1, Z2 supra-SV1)
  final zones = [
    HrZone(
      label: 'Z1 — Aérobie léger',
      minBpm: hrRest,
      maxBpm: aerobicCeiling,
      provenance: ceilingProv,
    ),
    HrZone(
      label: 'Z2 — Supra-aérobie',
      minBpm: aerobicCeiling + 1,
      maxBpm: resolvedHrMax,
      provenance: ceilingProv,
    ),
  ];

  return CalibrationResult(
    aerobicCeiling: aerobicCeiling,
    aerobicCeilingProvenance: ceilingProv,
    zones: zones,
  );
}
