import 'dart:typed_data';

/// Échantillon décodé d'une trame Heart Rate Measurement (0x2A37).
class HeartRateSample {
  /// Fréquence cardiaque instantanée (battements/min).
  final int hr;

  /// Intervalles RR de la trame, en millisecondes (peut être vide).
  final List<double> rrMs;

  /// Horodatage de réception (rempli à la réception, pas par le capteur).
  final DateTime receivedAt;

  HeartRateSample({required this.hr, required this.rrMs, DateTime? receivedAt})
      : receivedAt = receivedAt ?? DateTime.now();

  bool get hasRr => rrMs.isNotEmpty;

  @override
  String toString() => 'HR=$hr bpm, RR=${rrMs.map((e) => e.toStringAsFixed(0)).toList()} ms';
}

/// Décode une trame Heart Rate Measurement (caractéristique 0x2A37).
///
/// Format (Bluetooth SIG) :
///  - octet 0 : flags
///      bit 0 : format de la FC (0 = 8 bits, 1 = 16 bits)
///      bit 3 : champ "Energy Expended" présent (2 octets à sauter)
///      bit 4 : intervalles RR présents
///  - FC : 1 ou 2 octets selon bit 0
///  - [Energy Expended] : 2 octets si bit 3
///  - RR : 0..n × 2 octets, little-endian, unité 1/1024 s
///
/// Les RR sont convertis en millisecondes (× 1000 / 1024).
HeartRateSample parseHeartRate(List<int> data) {
  if (data.isEmpty) {
    return HeartRateSample(hr: 0, rrMs: const []);
  }
  final bytes = Uint8List.fromList(data);
  final flags = bytes[0];
  final hr16 = (flags & 0x01) != 0; // bit 0
  final energyPresent = (flags & 0x08) != 0; // bit 3
  final rrPresent = (flags & 0x10) != 0; // bit 4

  var i = 1;
  int hr;
  if (hr16) {
    hr = bytes[i] | (bytes[i + 1] << 8);
    i += 2;
  } else {
    hr = bytes[i];
    i += 1;
  }

  if (energyPresent) {
    i += 2; // on ignore l'énergie dépensée en phase 1
  }

  final rr = <double>[];
  if (rrPresent) {
    while (i + 1 < bytes.length) {
      final raw = bytes[i] | (bytes[i + 1] << 8); // unité 1/1024 s
      rr.add(raw * 1000.0 / 1024.0); // → millisecondes
      i += 2;
    }
  }

  return HeartRateSample(hr: hr, rrMs: rr);
}
