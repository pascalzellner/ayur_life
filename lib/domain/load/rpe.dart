/// RPE (Rating of Perceived Exertion) — pur Dart, sans dépendance plateforme.
///
/// Échelle CR10 : 0 (aucun effort) → 10 (effort maximal).
/// RPE de comparaison : −2 (bien en dessous) → +2 (bien au-dessus de la norme).
library;

// ── Bornes ───────────────────────────────────────────────────────────────────

const int rpeMin = 0;
const int rpeMax = 10;
const int rpeCompMin = -2;
const int rpeCompMax = 2;

// ── Validation / contrainte ──────────────────────────────────────────────────

/// Contraint [v] au domaine CR10 [rpeMin, rpeMax]. Retourne null si [v] est null.
int? clamperRpe(int? v) => v?.clamp(rpeMin, rpeMax);

/// Contraint [v] au domaine de comparaison [rpeCompMin, rpeCompMax].
int? clamperRpeComp(int? v) => v?.clamp(rpeCompMin, rpeCompMax);

/// Valide que [v] est dans [rpeMin, rpeMax]. Lance une [ArgumentError] sinon.
int validateRpe(int v) {
  if (v < rpeMin || v > rpeMax) {
    throw ArgumentError.value(v, 'rpe', 'Hors plage CR10 [$rpeMin–$rpeMax]');
  }
  return v;
}

/// Valide que [v] est dans [rpeCompMin, rpeCompMax]. Lance une [ArgumentError] sinon.
int validateRpeComp(int v) {
  if (v < rpeCompMin || v > rpeCompMax) {
    throw ArgumentError.value(
        v, 'rpeComp', 'Hors plage comparaison [$rpeCompMin–$rpeCompMax]');
  }
  return v;
}

// ── Charge de Foster ─────────────────────────────────────────────────────────

/// Charge subjective de Foster : RPE physique × durée en minutes.
///
/// Exprimée en UA (unités arbitraires). Cohérente avec la définition Foster (1998).
/// [rpePhysical] doit être dans [rpeMin, rpeMax] ; [duree] doit être positive.
/// Retourne 0.0 si la durée est nulle ou négative.
double fosterLoad(int rpePhysical, Duration duree) {
  validateRpe(rpePhysical);
  final minutes = duree.inMinutes;
  if (minutes <= 0) return 0.0;
  return rpePhysical * minutes.toDouble();
}
