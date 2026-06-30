import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayur_life/data/local/app_database.dart';
import 'package:ayur_life/domain/load/calibration.dart';

AppDatabase _memDb() => AppDatabase(NativeDatabase.memory());

void main() {
  // ── Round-trip session + indicateurs + RR ────────────────────────────────
  group('Round-trip session + indicateurs + RR', () {
    test('insertion et lecture des trois couches', () async {
      final db = _memDb();
      addTearDown(db.close);
      final now = DateTime(2025, 6, 1, 8, 0);

      // Session
      final sid = await db.sessionDao.insertSession(
        SessionsCompanion.insert(
          userId: 'u1',
          mode: 'D',
          startedAt: now,
        ),
      );
      expect(sid, greaterThan(0));

      // Fermeture avec qualité 95 %
      await db.sessionDao.closeSession(
          sid, now.add(const Duration(minutes: 30)), 0.95);

      final sessions = await db.sessionDao.getAll();
      expect(sessions.length, 1);
      expect(sessions.first.endedAt, isNotNull);
      expect(sessions.first.qualityRatio, closeTo(0.95, 0.001));

      // Indicateurs
      final at = now.add(const Duration(minutes: 5));
      await db.indicatorDao.insertAll([
        IndicatorsCompanion.insert(
            sessionId: sid, kind: 'rmssd', value: 42.5, at: at),
        IndicatorsCompanion.insert(
            sessionId: sid, kind: 'meanHr', value: 72.0, at: at),
        IndicatorsCompanion.insert(
            sessionId: sid, kind: 'totalBeats', value: 2160.0, at: at),
      ]);

      final indicators = await db.indicatorDao.forSession(sid);
      expect(indicators.length, 3);
      expect(indicators.map((i) => i.kind),
          containsAll(['rmssd', 'meanHr', 'totalBeats']));
      final rmssd = indicators.firstWhere((i) => i.kind == 'rmssd');
      expect(rmssd.value, closeTo(42.5, 0.001));

      // RR samples
      await db.rrDao.insertBatch([
        RrSamplesCompanion.insert(sessionId: sid, tMs: 0, rr: 812.0),
        RrSamplesCompanion.insert(sessionId: sid, tMs: 812, rr: 798.0),
        RrSamplesCompanion.insert(sessionId: sid, tMs: 1610, rr: 821.0),
      ]);

      expect(await db.rrDao.countForSession(sid), 3);
    });

    test('watchAll émet la session insérée', () async {
      final db = _memDb();
      addTearDown(db.close);
      final now = DateTime(2025, 6, 2, 7, 0);

      await db.sessionDao.insertSession(
        SessionsCompanion.insert(userId: 'u1', mode: 'C', startedAt: now),
      );

      final list = await db.sessionDao.watchAll().first;
      expect(list.length, 1);
      expect(list.first.mode, 'C');
    });

    test('latestOf retourne le plus récent pour un kind', () async {
      final db = _memDb();
      addTearDown(db.close);
      final base = DateTime(2025, 6, 3, 6, 0);

      final sid = await db.sessionDao.insertSession(
        SessionsCompanion.insert(userId: 'u1', mode: 'C', startedAt: base),
      );
      await db.indicatorDao.insertAll([
        IndicatorsCompanion.insert(
            sessionId: sid, kind: 'rmssd', value: 38.0, at: base),
        IndicatorsCompanion.insert(
            sessionId: sid,
            kind: 'rmssd',
            value: 45.0,
            at: base.add(const Duration(hours: 1))),
      ]);

      final latest = await db.indicatorDao.latestOf('rmssd');
      expect(latest, isNotNull);
      expect(latest!.value, closeTo(45.0, 0.001));
    });
  });

  // ── Rétention : purge RR courte, Indicators longue ───────────────────────
  group('Rétention', () {
    test('purgeRrSamples supprime les anciens RR mais conserve les Indicators',
        () async {
      final db = _memDb();
      addTearDown(db.close);

      final old = DateTime(2025, 4, 1, 8, 0); // > 30 jours avant cutoff
      final recent = DateTime(2025, 6, 15, 8, 0); // < 30 jours
      final cutoff = DateTime(2025, 5, 15, 0, 0); // cutoff = 30 jours

      // Session ancienne (endedAt avant cutoff)
      final oldSid = await db.sessionDao.insertSession(
        SessionsCompanion.insert(
          userId: 'u1',
          mode: 'C',
          startedAt: old,
          endedAt: Value(old.add(const Duration(minutes: 5))),
        ),
      );
      await db.rrDao.insertBatch([
        RrSamplesCompanion.insert(sessionId: oldSid, tMs: 0, rr: 800.0),
        RrSamplesCompanion.insert(sessionId: oldSid, tMs: 800, rr: 810.0),
      ]);
      await db.indicatorDao.insertAll([
        IndicatorsCompanion.insert(
            sessionId: oldSid,
            kind: 'rmssd',
            value: 38.0,
            at: old.add(const Duration(minutes: 2))),
      ]);

      // Session récente (endedAt après cutoff)
      final recentSid = await db.sessionDao.insertSession(
        SessionsCompanion.insert(
          userId: 'u1',
          mode: 'C',
          startedAt: recent,
          endedAt: Value(recent.add(const Duration(minutes: 5))),
        ),
      );
      await db.rrDao.insertBatch([
        RrSamplesCompanion.insert(sessionId: recentSid, tMs: 0, rr: 820.0),
      ]);

      // Purge
      await db.purgeRrSamples(cutoff);

      // RR anciens supprimés, récents intacts
      expect(await db.rrDao.countForSession(oldSid), 0);
      expect(await db.rrDao.countForSession(recentSid), 1);

      // L'Indicator ancien est PRÉSERVÉ (rétention longue)
      final oldIndicators = await db.indicatorDao.forSession(oldSid);
      expect(oldIndicators.length, 1);
      expect(oldIndicators.first.value, closeTo(38.0, 0.001));

      // La session elle-même est préservée
      final allSessions = await db.sessionDao.getAll();
      expect(allSessions.length, 2);
    });

    test('purgeRrSamples ne touche pas aux sessions sans endedAt (en cours)',
        () async {
      final db = _memDb();
      addTearDown(db.close);

      // Session en cours : pas d'endedAt → doit survivre à la purge
      final sid = await db.sessionDao.insertSession(
        SessionsCompanion.insert(
          userId: 'u1',
          mode: 'A',
          startedAt: DateTime(2025, 1, 1),
        ),
      );
      await db.rrDao.insertBatch([
        RrSamplesCompanion.insert(sessionId: sid, tMs: 0, rr: 800.0),
      ]);

      await db.purgeRrSamples(DateTime.now());

      // RR intacts : la session en cours n'a pas d'endedAt < cutoff
      expect(await db.rrDao.countForSession(sid), 1);
    });
  });

  // ── Profil : aller-retour et provenance ──────────────────────────────────
  group('Profil', () {
    test('upsert crée le profil puis le met à jour sans doublon', () async {
      final db = _memDb();
      addTearDown(db.close);
      final now = DateTime(2025, 6, 1, 9, 0);

      // Création initiale
      await db.profileDao.upsertProfile(
        ProfileCompanion.insert(
          userId: 'u1',
          age: const Value(35),
          sex: const Value('M'),
          hrRest: const Value(55),
          hrMax: const Value(185),
          hrMaxSource: const Value('measured'),
          fcSv1: const Value(148),
          thresholdProvenance:
              Value(ThresholdProvenance.measuredModeB.name),
          updatedAt: now,
        ),
      );

      final p1 = await db.profileDao.getProfile('u1');
      expect(p1, isNotNull);
      expect(p1!.age, 35);
      expect(p1.fcSv1, 148);
      expect(p1.thresholdProvenance, ThresholdProvenance.measuredModeB.name);

      // Mise à jour : nouveau fcSv1
      await db.profileDao.upsertProfile(
        ProfileCompanion.insert(
          userId: 'u1',
          age: const Value(35),
          hrRest: const Value(55),
          hrMax: const Value(185),
          fcSv1: const Value(152),
          thresholdProvenance:
              Value(ThresholdProvenance.measuredModeB.name),
          updatedAt: now.add(const Duration(hours: 1)),
        ),
      );

      final p2 = await db.profileDao.getProfile('u1');
      expect(p2!.fcSv1, 152); // mis à jour
      // Toujours une seule ligne
      final count = await db.select(db.profile).get();
      expect(count.length, 1);
    });

    test('getProfile retourne null si aucun profil', () async {
      final db = _memDb();
      addTearDown(db.close);

      expect(await db.profileDao.getProfile('inconnu'), isNull);
    });

    test('provenance estimatedKarvonen est préservée fidèlement', () async {
      final db = _memDb();
      addTearDown(db.close);

      await db.profileDao.upsertProfile(
        ProfileCompanion.insert(
          userId: 'u2',
          hrRest: const Value(60),
          hrMax: const Value(190),
          aerobicCeiling: const Value(144),
          thresholdProvenance:
              Value(ThresholdProvenance.estimatedKarvonen.name),
          updatedAt: DateTime(2025, 6, 1),
        ),
      );

      final p = await db.profileDao.getProfile('u2');
      expect(p!.thresholdProvenance,
          ThresholdProvenance.estimatedKarvonen.name);
      expect(p.aerobicCeiling, 144);
    });
  });

  // ── Gap BLE : marqueur de discontinuité ─────────────────────────────────
  group('Gap BLE', () {
    test('countForSession inclut les lignes de gap', () async {
      final db = _memDb();
      addTearDown(db.close);
      final now = DateTime(2025, 6, 10, 10, 0);

      final sid = await db.sessionDao.insertSession(
        SessionsCompanion.insert(userId: 'u1', mode: 'A', startedAt: now),
      );

      await db.rrDao.insertBatch([
        RrSamplesCompanion.insert(sessionId: sid, tMs: 0, rr: 800.0),
        RrSamplesCompanion.insert(sessionId: sid, tMs: 800, rr: 790.0),
        // Gap suite à coupure BLE
        RrSamplesCompanion.insert(
            sessionId: sid, tMs: 1590, rr: 0.0, gap: const Value(true)),
        // Reprise
        RrSamplesCompanion.insert(sessionId: sid, tMs: 12000, rr: 805.0),
      ]);

      // 4 lignes au total, dont 1 gap
      expect(await db.rrDao.countForSession(sid), 4);
    });
  });

  // ── ConsentLog : append-only ─────────────────────────────────────────────
  group('ConsentLog', () {
    test('deux consentements distincts sont tous deux conservés', () async {
      final db = _memDb();
      addTearDown(db.close);
      final base = DateTime(2025, 5, 1);

      await db.consentDao.insertConsent(
        ConsentLogCompanion.insert(
          userId: 'u1',
          route: 'medical',
          acceptedAt: base,
          appVersion: '0.1.0',
          consentVersion: 'v1',
        ),
      );
      await db.consentDao.insertConsent(
        ConsentLogCompanion.insert(
          userId: 'u1',
          route: 'self_responsibility',
          acceptedAt: base.add(const Duration(days: 30)),
          appVersion: '0.1.1',
          consentVersion: 'v1',
        ),
      );

      final logs = await db.consentDao.allForUser('u1');
      expect(logs.length, 2);
    });
  });

  // ── rpePhysical sur Sessions ──────────────────────────────────────────────
  group('Sessions — rpePhysical', () {
    test('rpePhysical null par défaut', () async {
      final db = _memDb();
      addTearDown(db.close);

      final sid = await db.sessionDao.insertSession(
        SessionsCompanion.insert(
            userId: 'u1', mode: 'D', startedAt: DateTime(2025, 7, 1, 8)),
      );
      final sessions = await db.sessionDao.getAll();
      expect(sessions.first.id, sid);
      expect(sessions.first.rpePhysical, isNull);
    });

    test('setRpePhysical écrit et relit correctement', () async {
      final db = _memDb();
      addTearDown(db.close);

      final sid = await db.sessionDao.insertSession(
        SessionsCompanion.insert(
            userId: 'u1', mode: 'A', startedAt: DateTime(2025, 7, 2, 9)),
      );
      await db.sessionDao.setRpePhysical(sid, 7);

      final sessions = await db.sessionDao.getAll();
      expect(sessions.first.rpePhysical, 7);
    });

    test('rpePhysical = 0 est une valeur valide (pas null)', () async {
      final db = _memDb();
      addTearDown(db.close);

      final sid = await db.sessionDao.insertSession(
        SessionsCompanion.insert(
            userId: 'u1', mode: 'C', startedAt: DateTime(2025, 7, 3, 7)),
      );
      await db.sessionDao.setRpePhysical(sid, 0);

      final sessions = await db.sessionDao.getAll();
      expect(sessions.first.rpePhysical, 0);
    });

    test('rpePhysical = 10 (valeur max CR10) est stocké fidèlement', () async {
      final db = _memDb();
      addTearDown(db.close);

      final sid = await db.sessionDao.insertSession(
        SessionsCompanion.insert(
            userId: 'u1', mode: 'A', startedAt: DateTime(2025, 7, 4, 18)),
      );
      await db.sessionDao.setRpePhysical(sid, 10);

      final sessions = await db.sessionDao.getAll();
      expect(sessions.first.rpePhysical, 10);
    });
  });

  // ── DailyEntries ─────────────────────────────────────────────────────────
  group('DailyEntries', () {
    test('upsert crée une entrée pour le jour', () async {
      final db = _memDb();
      addTearDown(db.close);
      final jour = DateTime(2025, 7, 10);

      await db.dailyEntryDao.upsertEntry(
        DailyEntriesCompanion.insert(
          userId: 'u1',
          day: jour,
          rpePsychological: const Value(6),
          updatedAt: jour,
        ),
      );

      final entry = await db.dailyEntryDao.forDay('u1', jour);
      expect(entry, isNotNull);
      expect(entry!.rpePsychological, 6);
      expect(entry.rpeComparison, isNull);
    });

    test('re-upsert le même jour ne crée pas de doublon (PK {userId, day})',
        () async {
      final db = _memDb();
      addTearDown(db.close);
      final jour = DateTime(2025, 7, 11);

      // Premier upsert : RPE psycho seulement
      await db.dailyEntryDao.upsertEntry(
        DailyEntriesCompanion.insert(
          userId: 'u1',
          day: jour,
          rpePsychological: const Value(5),
          updatedAt: jour,
        ),
      );
      // Deuxième upsert : on ajoute le rpeComparison
      await db.dailyEntryDao.upsertEntry(
        DailyEntriesCompanion.insert(
          userId: 'u1',
          day: jour,
          rpePsychological: const Value(5),
          rpeComparison: const Value(1),
          updatedAt: jour.add(const Duration(hours: 2)),
        ),
      );

      // Toujours une seule ligne pour ce jour
      final all = await db.select(db.dailyEntries).get();
      expect(all.length, 1);

      final entry = await db.dailyEntryDao.forDay('u1', jour);
      expect(entry!.rpePsychological, 5);
      expect(entry.rpeComparison, 1); // valeur ajoutée
    });

    test('deux jours différents = deux lignes distinctes', () async {
      final db = _memDb();
      addTearDown(db.close);
      final j1 = DateTime(2025, 7, 12);
      final j2 = DateTime(2025, 7, 13);

      for (final jour in [j1, j2]) {
        await db.dailyEntryDao.upsertEntry(
          DailyEntriesCompanion.insert(
            userId: 'u1',
            day: jour,
            rpePsychological: const Value(4),
            updatedAt: jour,
          ),
        );
      }

      final all = await db.select(db.dailyEntries).get();
      expect(all.length, 2);
    });

    test('watchRecent émet les entrées triées du plus récent au plus ancien',
        () async {
      final db = _memDb();
      addTearDown(db.close);

      for (var i = 1; i <= 3; i++) {
        await db.dailyEntryDao.upsertEntry(
          DailyEntriesCompanion.insert(
            userId: 'u1',
            day: DateTime(2025, 7, i),
            rpePsychological: Value(i),
            updatedAt: DateTime(2025, 7, i),
          ),
        );
      }

      final entries = await db.dailyEntryDao.watchRecent('u1').first;
      expect(entries.length, 3);
      // Plus récent en premier
      expect(entries.first.day, DateTime(2025, 7, 3));
      expect(entries.last.day, DateTime(2025, 7, 1));
    });

    test('forDay retourne null si aucune entrée pour ce jour', () async {
      final db = _memDb();
      addTearDown(db.close);

      expect(await db.dailyEntryDao.forDay('u1', DateTime(2025, 7, 20)),
          isNull);
    });

    test('rpeComparison −2 et +2 sont stockés fidèlement', () async {
      final db = _memDb();
      addTearDown(db.close);

      await db.dailyEntryDao.upsertEntry(
        DailyEntriesCompanion.insert(
          userId: 'u1',
          day: DateTime(2025, 7, 21),
          rpeComparison: const Value(-2),
          updatedAt: DateTime(2025, 7, 21),
        ),
      );
      await db.dailyEntryDao.upsertEntry(
        DailyEntriesCompanion.insert(
          userId: 'u2',
          day: DateTime(2025, 7, 21),
          rpeComparison: const Value(2),
          updatedAt: DateTime(2025, 7, 21),
        ),
      );

      final e1 = await db.dailyEntryDao.forDay('u1', DateTime(2025, 7, 21));
      final e2 = await db.dailyEntryDao.forDay('u2', DateTime(2025, 7, 21));
      expect(e1!.rpeComparison, -2);
      expect(e2!.rpeComparison, 2);
    });
  });
}
