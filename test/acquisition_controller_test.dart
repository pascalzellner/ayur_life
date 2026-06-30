import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ayur_life/data/ble/ble_providers.dart';
import 'package:ayur_life/data/local/app_database.dart';
import 'package:ayur_life/data/local/local_providers.dart';

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
}
