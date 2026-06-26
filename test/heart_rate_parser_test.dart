import 'package:flutter_test/flutter_test.dart';
import 'package:ayur_life/data/ble/heart_rate_parser.dart';

void main() {
  group('parseHeartRate — décodage trame 0x2A37', () {
    test('FC 8 bits, sans RR', () {
      // flags=0x00 (FC 8 bits, pas d'énergie, pas de RR), FC=60
      final s = parseHeartRate([0x00, 60]);
      expect(s.hr, 60);
      expect(s.rrMs, isEmpty);
      expect(s.hasRr, isFalse);
    });

    test('FC 8 bits, un RR (conversion 1/1024 s → ms)', () {
      // flags=0x10 (RR présents), FC=60, RR brut=1024 (0x0400, little-endian)
      final s = parseHeartRate([0x10, 60, 0x00, 0x04]);
      expect(s.hr, 60);
      expect(s.rrMs, hasLength(1));
      expect(s.rrMs.first, closeTo(1000.0, 0.001)); // 1024/1024 s = 1000 ms
    });

    test('Plusieurs RR dans une même trame', () {
      // RR bruts 1024 (→1000 ms) et 512 (0x0200 → 500 ms)
      final s = parseHeartRate([0x10, 60, 0x00, 0x04, 0x00, 0x02]);
      expect(s.rrMs, hasLength(2));
      expect(s.rrMs[0], closeTo(1000.0, 0.001));
      expect(s.rrMs[1], closeTo(500.0, 0.001));
    });

    test('FC sur 16 bits (bit 0 du flag)', () {
      // flags=0x01 (FC 16 bits), FC=300 (0x012C → octets 0x2C,0x01)
      final s = parseHeartRate([0x01, 0x2C, 0x01]);
      expect(s.hr, 300);
      expect(s.rrMs, isEmpty);
    });

    test('Champ Energy Expended présent (bit 3) → 2 octets sautés', () {
      // flags=0x18 (énergie + RR), FC=60, énergie=[0xAA,0xBB], RR brut=1024
      final s = parseHeartRate([0x18, 60, 0xAA, 0xBB, 0x00, 0x04]);
      expect(s.hr, 60);
      expect(s.rrMs, hasLength(1));
      expect(s.rrMs.first, closeTo(1000.0, 0.001));
    });

    test('RR brut non rond (976,56 ms pour 1000/1024 s)', () {
      // RR brut=1000 (0x03E8 → octets 0xE8,0x03)
      final s = parseHeartRate([0x10, 60, 0xE8, 0x03]);
      expect(s.rrMs.first, closeTo(976.5625, 0.001));
    });

    test('Trame vide → valeurs neutres', () {
      final s = parseHeartRate([]);
      expect(s.hr, 0);
      expect(s.rrMs, isEmpty);
    });
  });
}
