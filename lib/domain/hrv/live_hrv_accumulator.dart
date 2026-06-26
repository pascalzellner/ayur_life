import 'dart:collection';
import 'dart:math' as math;

/// Accumulateur HRV "temps réel" : maintient une fenêtre glissante de RR
/// nettoyés et expose le RMSSD courant, la FC moyenne et le taux d'artefacts.
///
/// Pur Dart, sans dépendance : c'est du domaine, testable en isolation.
/// La détection d'artefact ici est volontairement simple (proxy live, 5 %
/// d'écart à la médiane locale). Le correcteur complet de M3 viendra ensuite.
class LiveHrvAccumulator {
  LiveHrvAccumulator({
    this.windowMs = 120000, // 2 minutes
    this.artifactThreshold = 0.2, // 20 %
    this.localWindow = 5,
  });

  /// Durée de la fenêtre glissante (ms).
  final int windowMs;

  /// Seuil d'écart relatif à la médiane locale au-delà duquel un RR est artefact.
  final double artifactThreshold;

  /// Demi-largeur de la fenêtre locale (en nombre de RR) pour la médiane.
  final int localWindow;

  final ListQueue<_Beat> _beats = ListQueue<_Beat>();

  int _totalReceived = 0;
  int _totalArtifacts = 0;

  // Bornes physiologiques absolues d'un intervalle RR (ms).
// En dehors, c'est impossible : on rejette sans même comparer.
static const double _rrMin = 300.0;   // > 200 bpm : impossible au repos
static const double _rrMax = 2000.0;  // < 30 bpm

/// Ajoute un RR (ms) horodaté. Renvoie true s'il a été marqué artefact.
bool addRr(double rrMs, {DateTime? at}) {
  final t = at ?? DateTime.now();
  _totalReceived++;

  // Étage 1 : plausibilité physiologique absolue.
  final implausible = rrMs < _rrMin || rrMs > _rrMax;
  // Étage 2 : écart à la médiane locale (seulement si plausible).
  final isArtifact = implausible || _isArtifact(rrMs);
  if (isArtifact) _totalArtifacts++;

  _beats.addLast(_Beat(t.millisecondsSinceEpoch, rrMs, isArtifact));
  _evict(t.millisecondsSinceEpoch);
  return isArtifact;
}

bool _isArtifact(double rrMs) {
  final recent = _beats
      .where((b) => !b.artifact)
      .map((b) => b.rrMs)
      .toList(growable: false);
  // Amorçage : tant qu'on n'a pas assez de battements sains, on ne juge pas
  // sur la médiane (on a déjà filtré l'implausible au-dessus).
  if (recent.length < 8) return false;
  final n = math.min(localWindow * 2, recent.length);
  final tail = recent.sublist(recent.length - n)..sort();
  final med = tail[tail.length ~/ 2];
  return (rrMs - med).abs() > artifactThreshold * med;
}

  void _evict(int nowMs) {
    while (_beats.isNotEmpty && nowMs - _beats.first.tMs > windowMs) {
      _beats.removeFirst();
    }
  }

  /// RR valides (non artefacts) de la fenêtre, dans l'ordre.
  List<double> get cleanRr =>
      _beats.where((b) => !b.artifact).map((b) => b.rrMs).toList(growable: false);

  /// RMSSD (ms) sur la fenêtre courante, ou NaN si insuffisant.
  double get rmssd {
    final rr = cleanRr;
    if (rr.length < 2) return double.nan;
    var sum = 0.0;
    for (var i = 1; i < rr.length; i++) {
      final d = rr[i] - rr[i - 1];
      sum += d * d;
    }
    return math.sqrt(sum / (rr.length - 1));
  }

  /// FC moyenne (bpm) déduite des RR de la fenêtre, ou NaN si vide.
  double get meanHr {
    final rr = cleanRr;
    if (rr.isEmpty) return double.nan;
    final meanRr = rr.reduce((a, b) => a + b) / rr.length;
    return 60000.0 / meanRr;
  }

  /// Taux d'artefacts cumulé depuis le début de la session.
  double get artifactRatio =>
      _totalReceived == 0 ? 0.0 : _totalArtifacts / _totalReceived;

  int get beatsInWindow => _beats.length;
  int get totalReceived => _totalReceived;

  void reset() {
    _beats.clear();
    _totalReceived = 0;
    _totalArtifacts = 0;
  }
}

class _Beat {
  final int tMs;
  final double rrMs;
  final bool artifact;
  const _Beat(this.tMs, this.rrMs, this.artifact);
}
