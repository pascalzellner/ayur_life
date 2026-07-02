import 'package:drift/drift.dart';

// ── Sessions ─────────────────────────────────────────────────────────────────

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();

  /// 'A' | 'B' | 'C' | 'D'
  TextColumn get mode => text()();

  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Taux de battements non-artefacts sur la session (0.0–1.0).
  RealColumn get qualityRatio => real().withDefault(const Constant(1.0))();

  /// RPE physique CR10 (0–10) saisi à la clôture de l'activité (nullable).
  IntColumn get rpePhysical => integer().nullable()();
}

// ── Indicators (rétention LONGUE) ────────────────────────────────────────────

class Indicators extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// 'rmssd' | 'sdnn' | 'meanHr' | 'trimp' | 'sd1' | 'sd2' | 'artifactRatio'
  /// | 'totalBeats' — liste ouverte, stockée en texte pour évolutivité.
  TextColumn get kind => text()();

  RealColumn get value => real()();
  DateTimeColumn get at => dateTime()();
}

// ── RrSamples (rétention COURTE) ─────────────────────────────────────────────

class RrSamples extends Table {
  // Pas de PK autoincrement : volume élevé, rowid SQLite suffit.
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// Offset en ms depuis Session.startedAt.
  IntColumn get tMs => integer()();

  RealColumn get rr => real()();

  /// true = segment de perte de liaison BLE (gap marqué, RR manquant).
  BoolColumn get gap => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {sessionId, tMs};
}

// ── ConsentLog (APPEND-ONLY) ──────────────────────────────────────────────────

class ConsentLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();

  /// 'medical' | 'self_responsibility'
  TextColumn get route => text()();

  DateTimeColumn get acceptedAt => dateTime()();
  TextColumn get appVersion => text()();
  TextColumn get consentVersion => text()();
}

// ── Profile (une ligne courante par userId) ───────────────────────────────────

class Profile extends Table {
  // userId est la clé : une seule ligne par utilisateur, upsert sur conflit.
  TextColumn get userId => text()();

  // Anthropométrie
  IntColumn get age => integer().nullable()();
  TextColumn get sex => text().nullable()(); // 'M' | 'F' | 'autre'
  RealColumn get weightKg => real().nullable()();
  RealColumn get heightCm => real().nullable()();

  // Fréquence cardiaque de référence
  IntColumn get hrRest => integer().nullable()();

  /// 'mode_c' | 'manual' — origine de la FC de repos courante.
  TextColumn get hrRestSource => text().nullable()();

  IntColumn get hrMax => integer().nullable()();

  /// 'measured' | 'tanaka' | 'manual'
  TextColumn get hrMaxSource => text().nullable()();

  // Seuils mesurés (mode B) — nullable tant que non mesurés
  IntColumn get fcSv1 => integer().nullable()();
  IntColumn get fcSv2 => integer().nullable()();

  /// 'measured_modeB' | 'estimated_karvonen' | 'manual_lab'
  TextColumn get thresholdProvenance => text().nullable()();

  /// Plafond aérobie estimé (~70 % FCR, proxy SV1 avant mesure mode B).
  IntColumn get aerobicCeiling => integer().nullable()();

  // Baseline HRV
  RealColumn get baselineRmssd => real().nullable()();
  DateTimeColumn get baselineUpdatedAt => dateTime().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

// ── HooperMackinnonEntries (une ligne par séance mode C) ─────────────────────

class HooperMackinnonEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text()();

  /// 4 items Hooper-Mackinnon, chacun noté 1–7 (1 = excellent, 7 = très mauvais).
  IntColumn get fatigue => integer()();    // fatigue générale
  IntColumn get stress => integer()();     // stress du matin
  IntColumn get doms => integer()();       // courbatures
  IntColumn get sleep => integer()();      // qualité du sommeil

  DateTimeColumn get recordedAt => dateTime()();
}

// ── DailyEntries (une ligne par userId × jour) ────────────────────────────────

class DailyEntries extends Table {
  TextColumn get userId => text()();

  /// Jour normalisé à minuit UTC : DateTime(année, mois, jour).
  DateTimeColumn get day => dateTime()();

  /// RPE psychologique CR10 (0–10) : ressenti global de la journée.
  IntColumn get rpePsychological => integer().nullable()();

  /// RPE de comparaison (−2..+2) : journée mode D estimée vs journées de référence.
  IntColumn get rpeComparison => integer().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId, day};
}
