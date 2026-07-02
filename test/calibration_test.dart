import 'package:flutter_test/flutter_test.dart';

import 'package:ayur_life/domain/load/calibration.dart';

void main() {
  // ── estimateAerobicCeilingKarvonen — arrondi ────────────────────────────────

  group('estimateAerobicCeilingKarvonen', () {
    // Cas de référence du rapport terrain : hrRest=74, hrMax=188, FCR=114.
    // 74 + 0,70 × 114 = 74 + 79,8 = 153,8.
    // Arrondi standard → 154 ; troncature entière → 153.
    // Ce test est discriminant : il échoue si .round() est remplacé par .toInt().
    test('hrRest=74, hrMax=188 → 154 (test discriminant arrondi vs troncature)', () {
      expect(
        estimateAerobicCeilingKarvonen(hrRest: 74, hrMax: 188),
        154,
        reason: 'round(153.8)=154 ; floor(153.8)=153 — le test détecte la troncature',
      );
    });

    test('valeur entière exacte : hrRest=60, hrMax=180 → 144', () {
      // 60 + 0,70 × 120 = 60 + 84,0 = 144,0 → 144 (round = floor ici)
      expect(estimateAerobicCeilingKarvonen(hrRest: 60, hrMax: 180), 144);
    });

    test('fraction personnalisée 0,50 sur le cas de référence → 131', () {
      // 74 + 0,50 × 114 = 74 + 57,0 = 131,0 → 131
      expect(
        estimateAerobicCeilingKarvonen(hrRest: 74, hrMax: 188, fraction: 0.50),
        131,
      );
    });

    test('hrMax ≤ hrRest → null (données invalides)', () {
      expect(estimateAerobicCeilingKarvonen(hrRest: 100, hrMax: 80), isNull);
      expect(estimateAerobicCeilingKarvonen(hrRest: 100, hrMax: 100), isNull);
    });

    test('hrRest ≤ 0 → null (données invalides)', () {
      expect(estimateAerobicCeilingKarvonen(hrRest: 0, hrMax: 180), isNull);
    });
  });

  // ── computeZones — chemin Karvonen 5 zones ──────────────────────────────────

  group('computeZones — Karvonen 5 zones (hrRest=74, hrMax=188)', () {
    // FCR = 188 − 74 = 114
    // 50 % = 74 + 57,0 = 131,0  → 131
    // 60 % = 74 + 68,4 = 142,4  → 142 (Z1 max)
    // 70 % = 74 + 79,8 = 153,8  → 154 (Z2 max = aerobicCeiling)  ← discriminant
    // 80 % = 74 + 91,2 = 165,2  → 165 (Z3 max)
    // 90 % = 74 + 102,6 = 176,6 → 177 (Z4 max)
    // 100 % = 188 (hrMax, Z5 max)

    late CalibrationResult calib;

    setUp(() {
      calib = computeZones(
        age: null,
        hrRest: 74,
        hrMax: 188,
        hrMaxSource: 'manual',
        fcSv1: null,
        fcSv2: null,
        thresholdProvenance: null,
      )!;
    });

    test('produit exactement 5 zones', () {
      expect(calib.zones, hasLength(5));
    });

    test('aerobicCeiling = 154 (test discriminant arrondi vs troncature)', () {
      expect(calib.aerobicCeiling, 154,
          reason: 'round(153.8)=154 ; floor(153.8)=153 — vérifie le non-tronquage');
    });

    test('aerobicCeiling == borne haute de Z2 (invariant garde-fou)', () {
      // Le garde-fou Intensité utilise aerobicCeiling comme seuil de référence.
      // Il doit être identique à la borne Z2 — toute divergence serait incohérente.
      expect(calib.zones[1].maxBpm, calib.aerobicCeiling);
    });

    test('provenance estimatedKarvonen', () {
      expect(calib.aerobicCeilingProvenance, ThresholdProvenance.estimatedKarvonen);
      for (final z in calib.zones) {
        expect(z.provenance, ThresholdProvenance.estimatedKarvonen);
      }
    });

    test('Z1 — Récupération : 131–142', () {
      final z = calib.zones[0];
      expect(z.minBpm, 131);
      expect(z.maxBpm, 142);
      expect(z.label, contains('Z1'));
    });

    test('Z2 — Endurance fondamentale : 143–154', () {
      final z = calib.zones[1];
      expect(z.minBpm, 143);
      expect(z.maxBpm, 154);
      expect(z.label, contains('Z2'));
    });

    test('Z3 — Tempo : 155–165', () {
      final z = calib.zones[2];
      expect(z.minBpm, 155);
      expect(z.maxBpm, 165);
      expect(z.label, contains('Z3'));
    });

    test('Z4 — Seuil anaérobie : 166–177', () {
      final z = calib.zones[3];
      expect(z.minBpm, 166);
      expect(z.maxBpm, 177);
      expect(z.label, contains('Z4'));
    });

    test('Z5 — VO2max : 178–188', () {
      final z = calib.zones[4];
      expect(z.minBpm, 178);
      expect(z.maxBpm, 188); // = hrMax
      expect(z.label, contains('Z5'));
    });

    test('zones contiguës : pas de gap ni de chevauchement', () {
      for (var i = 0; i < calib.zones.length - 1; i++) {
        expect(
          calib.zones[i + 1].minBpm,
          calib.zones[i].maxBpm + 1,
          reason: 'Z${i + 2} doit démarrer à Z${i + 1}.maxBpm + 1',
        );
      }
    });

    test('Z5.maxBpm == hrMax', () {
      expect(calib.zones.last.maxBpm, 188);
    });
  });

  group('computeZones — Karvonen avec Tanaka (age seul)', () {
    test('age=40, hrRest=60 → Tanaka hrMax=180, aerobicCeiling=144', () {
      // 208 − 0,7×40 = 180 ; 60 + 0,7×120 = 144
      final calib = computeZones(
        age: 40,
        hrRest: 60,
        hrMax: null,
        hrMaxSource: null,
        fcSv1: null,
        fcSv2: null,
        thresholdProvenance: null,
      )!;
      expect(calib.aerobicCeiling, 144);
      expect(calib.zones, hasLength(5));
      expect(calib.zones[4].maxBpm, 180); // Z5 max = Tanaka hrMax
    });
  });

  group('computeZones — chemin SV1 mesuré (mode B) : 2 zones', () {
    test('aerobicCeiling = fcSv1, 2 zones autour du seuil', () {
      final calib = computeZones(
        age: null,
        hrRest: 60,
        hrMax: 185,
        hrMaxSource: 'measured',
        fcSv1: 155,
        fcSv2: 175,
        thresholdProvenance: ThresholdProvenance.measuredModeB.name,
      )!;

      expect(calib.aerobicCeiling, 155);
      expect(calib.aerobicCeilingProvenance, ThresholdProvenance.measuredModeB);
      expect(calib.zones, hasLength(2));
      expect(calib.zones[0].minBpm, 60);   // hrRest
      expect(calib.zones[0].maxBpm, 155);  // fcSv1
      expect(calib.zones[1].minBpm, 156);
      expect(calib.zones[1].maxBpm, 185);  // hrMax
    });
  });

  group('computeZones — données insuffisantes → null', () {
    test('hrRest manquant → null', () {
      expect(
        computeZones(
          age: null, hrRest: null, hrMax: 180,
          hrMaxSource: null, fcSv1: null, fcSv2: null, thresholdProvenance: null,
        ),
        isNull,
      );
    });

    test('hrMax et age absents → null', () {
      expect(
        computeZones(
          age: null, hrRest: 60, hrMax: null,
          hrMaxSource: null, fcSv1: null, fcSv2: null, thresholdProvenance: null,
        ),
        isNull,
      );
    });
  });
}
