import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift/drift.dart' show Value;

import 'package:ayur_life/core/user_id_service.dart';
import 'package:ayur_life/data/ble/ble_providers.dart';
import 'package:ayur_life/data/local/app_database.dart';
import 'package:ayur_life/data/local/local_providers.dart';
import 'package:ayur_life/domain/load/intensity_guard.dart';

// NOTE : BleHeartRateRepository et ForegroundServiceManager ne sont jamais
// instanciés ici — les providers correspondants sont lazy et aucun chemin
// de test n'appelle connect() (BLE) ni _onSample() (notification).
// Les tests couvrent uniquement la couche DB + machine d'état du contrôleur.

AppDatabase _memDb() => AppDatabase(NativeDatabase.memory());

// Renvoie le répertoire temporaire système aux appels path_provider.
void _mockPathProvider() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    return Directory.systemTemp.path;
  });
}

// Upsert un profil minimal (âge + FC repos) pour satisfaire le garde-fou
// de démarrage dans startRecording(). Doit être appelé après _mockPathProvider.
Future<void> _upsertProfil(AppDatabase db) async {
  final userId = await UserIdService.userId;
  await db.profileDao.upsertProfile(ProfileCompanion(
    userId: Value(userId),
    age: const Value(35),
    hrRest: const Value(55),
    sex: const Value('M'),
    updatedAt: Value(DateTime.now()),
  ));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group("AcquisitionController — machine d'état", () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(_memDb()),
      ]);
    });

    tearDown(() async {
      final db = container.read(appDatabaseProvider);
      container.dispose();
      await db.close();
    });

    test('état initial : idle', () {
      final state = container.read(acquisitionProvider);
      expect(state.status, ConnStatus.idle);
    });

    test('disconnect() depuis idle reste idle sans lever', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.disconnect();
      expect(container.read(acquisitionProvider).status, ConnStatus.idle);
    });
  });

  group('AcquisitionController — cycle enregistrement DB', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUpAll(_mockPathProvider);

    setUp(() async {
      db = _memDb();
      container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ]);
      await _upsertProfil(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('startRecording crée une session ouverte en base', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.startRecording(mode: 'A');

      final sessions = await db.sessionDao.getAll();
      expect(sessions, hasLength(1));
      expect(sessions.first.mode, 'A');
      expect(sessions.first.endedAt, isNull); // session encore ouverte

      await ctrl.stopRecording();
    });

    test('stopRecording ferme la session et écrit les indicateurs finaux', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.startRecording(mode: 'C');
      await ctrl.stopRecording();

      final sessions = await db.sessionDao.getAll();
      expect(sessions, hasLength(1));
      expect(sessions.first.endedAt, isNotNull);

      // Indicateurs écrits même sans aucun échantillon BLE.
      final indics = await db.indicatorDao.forSession(sessions.first.id);
      expect(indics.where((i) => i.kind == 'artifactRatio'), hasLength(1));
      expect(indics.where((i) => i.kind == 'totalBeats'), hasLength(1));
    });

    test('stopRecording sans startRecording : no-op, aucune session créée', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.stopRecording();
      expect(await db.sessionDao.getAll(), isEmpty);
    });

    test('double startRecording : idempotent, une seule session en base', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.startRecording(mode: 'D');
      await ctrl.startRecording(mode: 'D');

      expect(await db.sessionDao.getAll(), hasLength(1));

      await ctrl.stopRecording();
    });

    // DEBUG (diagnostic endedAt NULL) : reproduit 4 cycles start/stop
    // consécutifs SANS connect()/disconnect() entre eux, comme dans le test
    // manuel rapporté. Si le bug est purement lié à l'état du contrôleur/DB
    // (et non au matériel BLE réel ou au service premier plan Android), il
    // doit apparaître ici.
    test(
        'DEBUG — 4 cycles start/stop consécutifs : tous les endedAt doivent être renseignés',
        () async {
      final ctrl = container.read(acquisitionProvider.notifier);

      for (var i = 0; i < 4; i++) {
        await ctrl.startRecording(mode: 'D');
        await ctrl.stopRecording();
      }

      final sessions = await db.sessionDao.getAll();
      expect(sessions, hasLength(4));
      for (final s in sessions) {
        expect(s.endedAt, isNotNull,
            reason: 'session id=${s.id} startedAt=${s.startedAt} '
                'a un endedAt NULL après cycle start/stop');
      }
    });

    // Régression FIX D : _cleanup() doit flush + annuler le timer même en
    // l'absence de stopRecording() explicite (ex. disconnect brutal).
    test('FIX D — disconnect sans stopRecording : pas de levée, session préservée', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.startRecording(mode: 'A');

      // Disconnect brutal (sans stopRecording) : _cleanup() flush les RR en
      // tampon (ici vide) et annule le timer.
      await ctrl.disconnect();

      // La session existe en base mais reste ouverte (pas de closeSession).
      final sessions = await db.sessionDao.getAll();
      expect(sessions, hasLength(1));
      expect(sessions.first.endedAt, isNull);

      // Le contrôleur est revenu à idle (FIX B : _userWantsConnection = false).
      expect(container.read(acquisitionProvider).status, ConnStatus.idle);
    });
  });

  group('AcquisitionController — Mode C (bypass prérequis)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUpAll(_mockPathProvider);

    setUp(() {
      db = _memDb();
      container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ]);
      // PAS de _upsertProfil : le mode C doit démarrer sans profil.
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('startRecording(mode:C) réussit sans profil (allowed=true)', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      final check = await ctrl.startRecording(mode: 'C');
      expect(check.allowed, isTrue);

      final sessions = await db.sessionDao.getAll();
      expect(sessions, hasLength(1));
      expect(sessions.first.mode, 'C');

      await ctrl.stopRecording();
    });

    test('startRecording(mode:A) sans profil est bloqué (hrRestMissing)', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      final check = await ctrl.startRecording(mode: 'A');
      expect(check.allowed, isFalse);
      expect(check.hrRestMissing, isTrue);

      // Aucune session ne doit être créée
      expect(await db.sessionDao.getAll(), isEmpty);
    });

    test('stopRecording mode C sans RR : écrit artifactRatio et totalBeats, pas sd1/sd2', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.startRecording(mode: 'C');
      await ctrl.stopRecording();

      final sessions = await db.sessionDao.getAll();
      final indics = await db.indicatorDao.forSession(sessions.first.id);
      final kinds = indics.map((i) => i.kind).toList();

      expect(kinds, contains('artifactRatio'));
      expect(kinds, contains('totalBeats'));
      // Pas de RR → sd1/sd2 sont NaN → non écrits
      expect(kinds, isNot(contains('sd1')));
      expect(kinds, isNot(contains('sd2')));
    });

    test('stopRecording mode C sans RR : hrRest du profil non mis à jour (meanHr NaN)', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.startRecording(mode: 'C');
      await ctrl.stopRecording();

      // Aucun profil ne doit exister (meanHr NaN → setHrRestFromModeC non appelé)
      final userId = await UserIdService.userId;
      expect(await db.profileDao.getProfile(userId), isNull);
    });

    test('clearIntensityRef après stopRecording mode C : état propre', () async {
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.startRecording(mode: 'C');
      await ctrl.stopRecording();

      final s = container.read(acquisitionProvider);
      expect(s.intensityRefBpm, isNull);
      expect(s.intensityRefLabel, isNull);
    });

    // ── Annulation Mode C ───────────────────────────────────────────────────

    test(
        'annulation phase mesure (T>60s) : stopRecording ferme la session '
        '— pas de session orpheline en base', () async {
      // Simule le tick T=60 : startRecording est appelé automatiquement.
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.startRecording(mode: 'C');

      // Simule l'appel de _annulerModeC qui appelle stopRecording()
      // de façon inconditionnelle (même si la phase UI est encore "stabilisant").
      await ctrl.stopRecording();

      final sessions = await db.sessionDao.getAll();
      expect(sessions, hasLength(1));
      expect(
        sessions.first.endedAt,
        isNotNull,
        reason: 'L\'annulation pendant la mesure doit fermer la session '
            '(endedAt non null) — aucune session orpheline tolérée.',
      );
    });

    test(
        'annulation phase stabilisation (T<60s) : stopRecording est un no-op '
        '— aucune session créée en base', () async {
      // Avant T=60s, startRecording n'a pas encore été appelé.
      // _annulerModeC appelle stopRecording() de façon inconditionnelle :
      // c'est un no-op explicite quand _sessionId == null.
      final ctrl = container.read(acquisitionProvider.notifier);
      await ctrl.stopRecording(); // no-op

      expect(
        await db.sessionDao.getAll(),
        isEmpty,
        reason: 'L\'annulation pendant la stabilisation ne doit rien écrire '
            'en base — stopRecording est un no-op si T<60s.',
      );
    });
  });

  group('AcquisitionController — isSessionActive', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUpAll(_mockPathProvider);

    setUp(() async {
      db = _memDb();
      container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ]);
      await _upsertProfil(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('false initialement', () {
      expect(container.read(acquisitionProvider).isSessionActive, isFalse);
    });

    test('true après startRecording, false après stopRecording', () async {
      final ctrl = container.read(acquisitionProvider.notifier);

      await ctrl.startRecording(mode: 'A');
      expect(container.read(acquisitionProvider).isSessionActive, isTrue);

      await ctrl.stopRecording();
      expect(container.read(acquisitionProvider).isSessionActive, isFalse);
    });

    test('false après startRecording bloqué (mode A sans profil)', () async {
      // Nouveau container sans profil
      final dbSansProfil = _memDb();
      final c = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(dbSansProfil),
      ]);
      addTearDown(() async {
        c.dispose();
        await dbSansProfil.close();
      });

      final ctrl = c.read(acquisitionProvider.notifier);
      final check = await ctrl.startRecording(mode: 'A');
      expect(check.allowed, isFalse);
      expect(c.read(acquisitionProvider).isSessionActive, isFalse);
    });

    test('true après startRecording(mode:C) sans profil', () async {
      final dbSansProfil = _memDb();
      final c = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(dbSansProfil),
      ]);
      addTearDown(() async {
        c.dispose();
        await dbSansProfil.close();
      });

      final ctrl = c.read(acquisitionProvider.notifier);
      await ctrl.startRecording(mode: 'C');
      expect(c.read(acquisitionProvider).isSessionActive, isTrue);

      await ctrl.stopRecording();
      expect(c.read(acquisitionProvider).isSessionActive, isFalse);
    });
  });

  group('AcquisitionController — prérequis mode D (sexe)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUpAll(_mockPathProvider);

    setUp(() {
      db = _memDb();
      container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('startRecording(mode:D) sans sexe dans profil est bloqué (sexMissing)', () async {
      final userId = await UserIdService.userId;
      await db.profileDao.upsertProfile(ProfileCompanion(
        userId: Value(userId),
        age: const Value(35),
        hrRest: const Value(55),
        // sex absent → sexMissing attendu
        updatedAt: Value(DateTime.now()),
      ));

      final ctrl = container.read(acquisitionProvider.notifier);
      final check = await ctrl.startRecording(mode: 'D');
      expect(check.allowed, isFalse);
      expect(check.sexMissing, isTrue);
      expect(check.missingFields, contains('sexe'));
      expect(await db.sessionDao.getAll(), isEmpty);
    });

    test('startRecording(mode:D) avec sexe dans profil réussit', () async {
      final userId = await UserIdService.userId;
      await db.profileDao.upsertProfile(ProfileCompanion(
        userId: Value(userId),
        age: const Value(35),
        hrRest: const Value(55),
        sex: const Value('M'),
        updatedAt: Value(DateTime.now()),
      ));

      final ctrl = container.read(acquisitionProvider.notifier);
      final check = await ctrl.startRecording(mode: 'D');
      expect(check.allowed, isTrue);
      expect(check.sexMissing, isFalse);
      await ctrl.stopRecording();
    });

    test('startRecording(mode:A) sans sexe : sex non requis (sexMissing=false)', () async {
      final userId = await UserIdService.userId;
      await db.profileDao.upsertProfile(ProfileCompanion(
        userId: Value(userId),
        age: const Value(35),
        hrRest: const Value(55),
        // sex absent intentionnellement
        updatedAt: Value(DateTime.now()),
      ));

      final ctrl = container.read(acquisitionProvider.notifier);
      final check = await ctrl.startRecording(mode: 'A');
      // Mode A ne vérifie pas le sexe
      expect(check.sexMissing, isFalse);
      expect(check.allowed, isTrue);
      await ctrl.stopRecording();
    });

    // Tests unitaires purs de checkSessionStart (domaine)
    test('checkSessionStart — sexMissing=false quand sex fourni', () {
      final check = checkSessionStart(
          age: 30, hrRest: 60, checkSex: true, sex: 'F');
      expect(check.sexMissing, isFalse);
      expect(check.allowed, isTrue);
    });

    test('checkSessionStart — sexMissing=true quand checkSex=true et sex=null', () {
      final check = checkSessionStart(
          age: 30, hrRest: 60, checkSex: true, sex: null);
      expect(check.sexMissing, isTrue);
      expect(check.allowed, isFalse);
      expect(check.missingFields, contains('sexe'));
    });

    test('checkSessionStart — sexMissing=false quand checkSex=false (mode A/C)', () {
      final check = checkSessionStart(age: 30, hrRest: 60);
      expect(check.sexMissing, isFalse);
    });
  });

  group('sessionsHistoryProvider — stream stable', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUpAll(_mockPathProvider);

    setUp(() async {
      db = _memDb();
      container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ]);
      await _upsertProfil(db);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    // Anti-régression : confirme que sessionsHistoryProvider expose un AsyncValue
    // stable et réactif — watchAll() ne doit être appelé qu'une seule fois par
    // la durée de vie du provider, pas à chaque lecture/rebuild. L'identité du
    // stream sous-jacent n'est pas accessible via l'API publique Riverpod ; on
    // teste donc la propriété fonctionnelle équivalente.
    test('stable et réactif : voit les nouvelles sessions sans réinitialisation', () async {
      final ctrl = container.read(acquisitionProvider.notifier);

      // Souscrire au provider et collecter les émissions.
      final emissions = <List<Session>>[];
      final sub = container.listen<AsyncValue<List<Session>>>(
        sessionsHistoryProvider,
        (_, next) {
          if (next.hasValue) emissions.add(next.requireValue);
        },
      );
      addTearDown(sub.close);

      // Émission initiale (liste vide).
      await Future<void>.delayed(Duration.zero);
      expect(emissions, isNotEmpty);
      expect(emissions.last, isEmpty);

      // Créer et fermer une session via le contrôleur (pas d'import Value nécessaire).
      await ctrl.startRecording(mode: 'D');
      await ctrl.stopRecording();

      // Drift propage la notification de changement de table.
      await Future<void>.delayed(Duration.zero);

      expect(emissions.last, hasLength(1),
          reason:
              'Le provider doit émettre la session fermée — '
              'preuve que watchAll() est toujours actif (stream non recréé).');

      // Deuxième lecture directe : le provider renvoie les données mises en
      // cache sans réinitialiser le stream (anti-régression du bug StreamBuilder).
      final cached = container.read(sessionsHistoryProvider);
      expect(cached.hasValue, isTrue);
      expect(cached.requireValue, hasLength(1));
    });

    test('_hrv.reset() en fin de stopRecording : 2 cycles complets ferment 2 sessions sans erreur', () async {
      // Sans _hrv.reset(), les cycles successifs partagent l'accumulateur HRV
      // (les indicateurs de session 2 incluaient les RR de session 1).
      // Ce test vérifie que le correctif ne casse pas le cycle start/stop et
      // que les deux sessions sont bien fermées (endedAt non null).
      final ctrl = container.read(acquisitionProvider.notifier);

      await ctrl.startRecording(mode: 'D');
      await ctrl.stopRecording();
      await ctrl.startRecording(mode: 'D');
      await ctrl.stopRecording();

      final sessions = await db.sessionDao.getAll();
      expect(sessions, hasLength(2));
      expect(sessions.every((s) => s.endedAt != null), isTrue,
          reason:
              'Les deux sessions doivent être fermées correctement après '
              '_hrv.reset() en fin de stopRecording().');
    });
  });
}
