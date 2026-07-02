/// Indicateurs de Poincaré SD1 / SD2 — pur Dart, sans dépendance plateforme.
///
/// SD1 mesure la variabilité à court terme (parasympathique, ≈ RMSSD/√2).
/// SD2 mesure la variabilité à long terme (sympathique + parasympathique).
library;

import 'dart:math' as math;

/// Écart-type population des intervalles RR (SDNN, ms).
/// Retourne NaN si la liste contient moins de 2 valeurs.
double computeSdnn(List<double> rr) {
  if (rr.length < 2) return double.nan;
  final mean = rr.reduce((a, b) => a + b) / rr.length;
  final variance =
      rr.fold(0.0, (s, v) => s + (v - mean) * (v - mean)) / rr.length;
  return math.sqrt(variance);
}

/// SD1 — variabilité à court terme (ms). Équivalent à RMSSD / √2.
/// Retourne NaN si rmssd est NaN.
double computeSd1(double rmssd) {
  if (rmssd.isNaN) return double.nan;
  return rmssd / math.sqrt(2);
}

/// SD2 — variabilité à long terme (ms).
/// Formule : √(2 × SDNN² − SD1²). Retourne NaN si les entrées sont invalides.
double computeSd2(double sdnn, double sd1) {
  if (sdnn.isNaN || sd1.isNaN) return double.nan;
  final sq = 2.0 * sdnn * sdnn - sd1 * sd1;
  return sq > 0 ? math.sqrt(sq) : double.nan;
}
