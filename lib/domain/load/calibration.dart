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

// ── Zones Karvonen complètes (5 zones) ───────────────────────────────────────

/// Calcule les 5 zones Karvonen depuis les paramètres cardiaques.
///
/// Toutes les bornes utilisent [.round()] — jamais de troncature entière.
/// La borne haute de Z2 est identique à [aerobicCeiling] (garde-fou Intensité).
///
/// Zone | Plage FCR | Description
/// ---- | --------- | -----------
/// Z1   | 50–60 %   | Récupération
/// Z2   | 60–70 %   | Endurance fondamentale ← plafond aérobie (garde-fou)
/// Z3   | 70–80 %   | Tempo
/// Z4   | 80–90 %   | Seuil anaérobie
/// Z5   | 90–100 %  | VO2max
List<HrZone> _karvonenZones(int hrRest, int hrMax, ThresholdProvenance prov) {
  final fcr = hrMax - hrRest;
  int b(double f) => (hrRest + f * fcr).round();

  final z1Max = b(0.60);
  final z2Max = b(0.70); // = aerobicCeiling
  final z3Max = b(0.80);
  final z4Max = b(0.90);

  return [
    HrZone(label: 'Z1 — Récupération',          minBpm: b(0.50),  maxBpm: z1Max, provenance: prov),
    HrZone(label: 'Z2 — Endurance fondamentale', minBpm: z1Max + 1, maxBpm: z2Max, provenance: prov),
    HrZone(label: 'Z3 — Tempo',                 minBpm: z2Max + 1, maxBpm: z3Max, provenance: prov),
    HrZone(label: 'Z4 — Seuil anaérobie',       minBpm: z3Max + 1, maxBpm: z4Max, provenance: prov),
    HrZone(label: 'Z5 — VO2max',                minBpm: z4Max + 1, maxBpm: hrMax, provenance: prov),
  ];
}

// ── Point d'entrée principal ──────────────────────────────────────────────────

/// Dérive les zones et le plafond aérobie depuis les données de profil.
///
/// Priorité : seuils mesurés mode B > estimation Karvonen.
/// La provenance suit toujours chaque valeur.
///
/// Chemin Karvonen : 5 zones complètes (Z1–Z5).
/// Chemin SV1 mesuré : 2 zones (sous-SV1 / supra-SV1).
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

  // Karvonen estimé → 5 zones complètes.
  // Seuil mesuré (mode B / lab) → 2 zones autour du seuil physiologique.
  final List<HrZone> zones;
  if (ceilingProv == ThresholdProvenance.estimatedKarvonen) {
    zones = _karvonenZones(hrRest, resolvedHrMax, ceilingProv);
  } else {
    zones = [
      HrZone(label: 'Z1 — Sous SV1 (aérobie)',  minBpm: hrRest,             maxBpm: aerobicCeiling,    provenance: ceilingProv),
      HrZone(label: 'Z2 — Supra-SV1',           minBpm: aerobicCeiling + 1, maxBpm: resolvedHrMax,     provenance: ceilingProv),
    ];
  }

  return CalibrationResult(
    aerobicCeiling: aerobicCeiling,
    aerobicCeilingProvenance: ceilingProv,
    zones: zones,
  );
}
