// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityRatioMeta = const VerificationMeta(
    'qualityRatio',
  );
  @override
  late final GeneratedColumn<double> qualityRatio = GeneratedColumn<double>(
    'quality_ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _rpePhysicalMeta = const VerificationMeta(
    'rpePhysical',
  );
  @override
  late final GeneratedColumn<int> rpePhysical = GeneratedColumn<int>(
    'rpe_physical',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    mode,
    startedAt,
    endedAt,
    qualityRatio,
    rpePhysical,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('quality_ratio')) {
      context.handle(
        _qualityRatioMeta,
        qualityRatio.isAcceptableOrUnknown(
          data['quality_ratio']!,
          _qualityRatioMeta,
        ),
      );
    }
    if (data.containsKey('rpe_physical')) {
      context.handle(
        _rpePhysicalMeta,
        rpePhysical.isAcceptableOrUnknown(
          data['rpe_physical']!,
          _rpePhysicalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      qualityRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quality_ratio'],
      )!,
      rpePhysical: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rpe_physical'],
      ),
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String userId;

  /// 'A' | 'B' | 'C' | 'D'
  final String mode;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Taux de battements non-artefacts sur la session (0.0–1.0).
  final double qualityRatio;

  /// RPE physique CR10 (0–10) saisi à la clôture de l'activité (nullable).
  final int? rpePhysical;
  const Session({
    required this.id,
    required this.userId,
    required this.mode,
    required this.startedAt,
    this.endedAt,
    required this.qualityRatio,
    this.rpePhysical,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['mode'] = Variable<String>(mode);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['quality_ratio'] = Variable<double>(qualityRatio);
    if (!nullToAbsent || rpePhysical != null) {
      map['rpe_physical'] = Variable<int>(rpePhysical);
    }
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      mode: Value(mode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      qualityRatio: Value(qualityRatio),
      rpePhysical: rpePhysical == null && nullToAbsent
          ? const Value.absent()
          : Value(rpePhysical),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      mode: serializer.fromJson<String>(json['mode']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      qualityRatio: serializer.fromJson<double>(json['qualityRatio']),
      rpePhysical: serializer.fromJson<int?>(json['rpePhysical']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'mode': serializer.toJson<String>(mode),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'qualityRatio': serializer.toJson<double>(qualityRatio),
      'rpePhysical': serializer.toJson<int?>(rpePhysical),
    };
  }

  Session copyWith({
    int? id,
    String? userId,
    String? mode,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    double? qualityRatio,
    Value<int?> rpePhysical = const Value.absent(),
  }) => Session(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    mode: mode ?? this.mode,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    qualityRatio: qualityRatio ?? this.qualityRatio,
    rpePhysical: rpePhysical.present ? rpePhysical.value : this.rpePhysical,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      mode: data.mode.present ? data.mode.value : this.mode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      qualityRatio: data.qualityRatio.present
          ? data.qualityRatio.value
          : this.qualityRatio,
      rpePhysical: data.rpePhysical.present
          ? data.rpePhysical.value
          : this.rpePhysical,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('qualityRatio: $qualityRatio, ')
          ..write('rpePhysical: $rpePhysical')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    mode,
    startedAt,
    endedAt,
    qualityRatio,
    rpePhysical,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.mode == this.mode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.qualityRatio == this.qualityRatio &&
          other.rpePhysical == this.rpePhysical);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> mode;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<double> qualityRatio;
  final Value<int?> rpePhysical;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.mode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.qualityRatio = const Value.absent(),
    this.rpePhysical = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String mode,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.qualityRatio = const Value.absent(),
    this.rpePhysical = const Value.absent(),
  }) : userId = Value(userId),
       mode = Value(mode),
       startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? mode,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<double>? qualityRatio,
    Expression<int>? rpePhysical,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (mode != null) 'mode': mode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (qualityRatio != null) 'quality_ratio': qualityRatio,
      if (rpePhysical != null) 'rpe_physical': rpePhysical,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? mode,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<double>? qualityRatio,
    Value<int?>? rpePhysical,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      qualityRatio: qualityRatio ?? this.qualityRatio,
      rpePhysical: rpePhysical ?? this.rpePhysical,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (qualityRatio.present) {
      map['quality_ratio'] = Variable<double>(qualityRatio.value);
    }
    if (rpePhysical.present) {
      map['rpe_physical'] = Variable<int>(rpePhysical.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('qualityRatio: $qualityRatio, ')
          ..write('rpePhysical: $rpePhysical')
          ..write(')'))
        .toString();
  }
}

class $IndicatorsTable extends Indicators
    with TableInfo<$IndicatorsTable, Indicator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IndicatorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sessionId, kind, value, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'indicators';
  @override
  VerificationContext validateIntegrity(
    Insertable<Indicator> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Indicator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Indicator(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $IndicatorsTable createAlias(String alias) {
    return $IndicatorsTable(attachedDatabase, alias);
  }
}

class Indicator extends DataClass implements Insertable<Indicator> {
  final int id;
  final int sessionId;

  /// 'rmssd' | 'sdnn' | 'meanHr' | 'trimp' | 'sd1' | 'sd2' | 'artifactRatio'
  /// | 'totalBeats' — liste ouverte, stockée en texte pour évolutivité.
  final String kind;
  final double value;
  final DateTime at;
  const Indicator({
    required this.id,
    required this.sessionId,
    required this.kind,
    required this.value,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['kind'] = Variable<String>(kind);
    map['value'] = Variable<double>(value);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  IndicatorsCompanion toCompanion(bool nullToAbsent) {
    return IndicatorsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      kind: Value(kind),
      value: Value(value),
      at: Value(at),
    );
  }

  factory Indicator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Indicator(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      kind: serializer.fromJson<String>(json['kind']),
      value: serializer.fromJson<double>(json['value']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'kind': serializer.toJson<String>(kind),
      'value': serializer.toJson<double>(value),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  Indicator copyWith({
    int? id,
    int? sessionId,
    String? kind,
    double? value,
    DateTime? at,
  }) => Indicator(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    kind: kind ?? this.kind,
    value: value ?? this.value,
    at: at ?? this.at,
  );
  Indicator copyWithCompanion(IndicatorsCompanion data) {
    return Indicator(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Indicator(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, kind, value, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Indicator &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.kind == this.kind &&
          other.value == this.value &&
          other.at == this.at);
}

class IndicatorsCompanion extends UpdateCompanion<Indicator> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> kind;
  final Value<double> value;
  final Value<DateTime> at;
  const IndicatorsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.at = const Value.absent(),
  });
  IndicatorsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String kind,
    required double value,
    required DateTime at,
  }) : sessionId = Value(sessionId),
       kind = Value(kind),
       value = Value(value),
       at = Value(at);
  static Insertable<Indicator> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? kind,
    Expression<double>? value,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (at != null) 'at': at,
    });
  }

  IndicatorsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? kind,
    Value<double>? value,
    Value<DateTime>? at,
  }) {
    return IndicatorsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IndicatorsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $RrSamplesTable extends RrSamples
    with TableInfo<$RrSamplesTable, RrSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RrSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tMsMeta = const VerificationMeta('tMs');
  @override
  late final GeneratedColumn<int> tMs = GeneratedColumn<int>(
    't_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rrMeta = const VerificationMeta('rr');
  @override
  late final GeneratedColumn<double> rr = GeneratedColumn<double>(
    'rr',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gapMeta = const VerificationMeta('gap');
  @override
  late final GeneratedColumn<bool> gap = GeneratedColumn<bool>(
    'gap',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gap" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, tMs, rr, gap];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rr_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<RrSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('t_ms')) {
      context.handle(
        _tMsMeta,
        tMs.isAcceptableOrUnknown(data['t_ms']!, _tMsMeta),
      );
    } else if (isInserting) {
      context.missing(_tMsMeta);
    }
    if (data.containsKey('rr')) {
      context.handle(_rrMeta, rr.isAcceptableOrUnknown(data['rr']!, _rrMeta));
    } else if (isInserting) {
      context.missing(_rrMeta);
    }
    if (data.containsKey('gap')) {
      context.handle(
        _gapMeta,
        gap.isAcceptableOrUnknown(data['gap']!, _gapMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, tMs};
  @override
  RrSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RrSample(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      tMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}t_ms'],
      )!,
      rr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rr'],
      )!,
      gap: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gap'],
      )!,
    );
  }

  @override
  $RrSamplesTable createAlias(String alias) {
    return $RrSamplesTable(attachedDatabase, alias);
  }
}

class RrSample extends DataClass implements Insertable<RrSample> {
  final int sessionId;

  /// Offset en ms depuis Session.startedAt.
  final int tMs;
  final double rr;

  /// true = segment de perte de liaison BLE (gap marqué, RR manquant).
  final bool gap;
  const RrSample({
    required this.sessionId,
    required this.tMs,
    required this.rr,
    required this.gap,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['t_ms'] = Variable<int>(tMs);
    map['rr'] = Variable<double>(rr);
    map['gap'] = Variable<bool>(gap);
    return map;
  }

  RrSamplesCompanion toCompanion(bool nullToAbsent) {
    return RrSamplesCompanion(
      sessionId: Value(sessionId),
      tMs: Value(tMs),
      rr: Value(rr),
      gap: Value(gap),
    );
  }

  factory RrSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RrSample(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      tMs: serializer.fromJson<int>(json['tMs']),
      rr: serializer.fromJson<double>(json['rr']),
      gap: serializer.fromJson<bool>(json['gap']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'tMs': serializer.toJson<int>(tMs),
      'rr': serializer.toJson<double>(rr),
      'gap': serializer.toJson<bool>(gap),
    };
  }

  RrSample copyWith({int? sessionId, int? tMs, double? rr, bool? gap}) =>
      RrSample(
        sessionId: sessionId ?? this.sessionId,
        tMs: tMs ?? this.tMs,
        rr: rr ?? this.rr,
        gap: gap ?? this.gap,
      );
  RrSample copyWithCompanion(RrSamplesCompanion data) {
    return RrSample(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      tMs: data.tMs.present ? data.tMs.value : this.tMs,
      rr: data.rr.present ? data.rr.value : this.rr,
      gap: data.gap.present ? data.gap.value : this.gap,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RrSample(')
          ..write('sessionId: $sessionId, ')
          ..write('tMs: $tMs, ')
          ..write('rr: $rr, ')
          ..write('gap: $gap')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, tMs, rr, gap);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RrSample &&
          other.sessionId == this.sessionId &&
          other.tMs == this.tMs &&
          other.rr == this.rr &&
          other.gap == this.gap);
}

class RrSamplesCompanion extends UpdateCompanion<RrSample> {
  final Value<int> sessionId;
  final Value<int> tMs;
  final Value<double> rr;
  final Value<bool> gap;
  final Value<int> rowid;
  const RrSamplesCompanion({
    this.sessionId = const Value.absent(),
    this.tMs = const Value.absent(),
    this.rr = const Value.absent(),
    this.gap = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RrSamplesCompanion.insert({
    required int sessionId,
    required int tMs,
    required double rr,
    this.gap = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       tMs = Value(tMs),
       rr = Value(rr);
  static Insertable<RrSample> custom({
    Expression<int>? sessionId,
    Expression<int>? tMs,
    Expression<double>? rr,
    Expression<bool>? gap,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (tMs != null) 't_ms': tMs,
      if (rr != null) 'rr': rr,
      if (gap != null) 'gap': gap,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RrSamplesCompanion copyWith({
    Value<int>? sessionId,
    Value<int>? tMs,
    Value<double>? rr,
    Value<bool>? gap,
    Value<int>? rowid,
  }) {
    return RrSamplesCompanion(
      sessionId: sessionId ?? this.sessionId,
      tMs: tMs ?? this.tMs,
      rr: rr ?? this.rr,
      gap: gap ?? this.gap,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (tMs.present) {
      map['t_ms'] = Variable<int>(tMs.value);
    }
    if (rr.present) {
      map['rr'] = Variable<double>(rr.value);
    }
    if (gap.present) {
      map['gap'] = Variable<bool>(gap.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RrSamplesCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('tMs: $tMs, ')
          ..write('rr: $rr, ')
          ..write('gap: $gap, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsentLogTable extends ConsentLog
    with TableInfo<$ConsentLogTable, ConsentLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsentLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeMeta = const VerificationMeta('route');
  @override
  late final GeneratedColumn<String> route = GeneratedColumn<String>(
    'route',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acceptedAtMeta = const VerificationMeta(
    'acceptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> acceptedAt = GeneratedColumn<DateTime>(
    'accepted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consentVersionMeta = const VerificationMeta(
    'consentVersion',
  );
  @override
  late final GeneratedColumn<String> consentVersion = GeneratedColumn<String>(
    'consent_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    route,
    acceptedAt,
    appVersion,
    consentVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consent_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConsentLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('route')) {
      context.handle(
        _routeMeta,
        route.isAcceptableOrUnknown(data['route']!, _routeMeta),
      );
    } else if (isInserting) {
      context.missing(_routeMeta);
    }
    if (data.containsKey('accepted_at')) {
      context.handle(
        _acceptedAtMeta,
        acceptedAt.isAcceptableOrUnknown(data['accepted_at']!, _acceptedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_acceptedAtMeta);
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_appVersionMeta);
    }
    if (data.containsKey('consent_version')) {
      context.handle(
        _consentVersionMeta,
        consentVersion.isAcceptableOrUnknown(
          data['consent_version']!,
          _consentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConsentLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsentLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      route: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route'],
      )!,
      acceptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}accepted_at'],
      )!,
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      )!,
      consentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consent_version'],
      )!,
    );
  }

  @override
  $ConsentLogTable createAlias(String alias) {
    return $ConsentLogTable(attachedDatabase, alias);
  }
}

class ConsentLogData extends DataClass implements Insertable<ConsentLogData> {
  final int id;
  final String userId;

  /// 'medical' | 'self_responsibility'
  final String route;
  final DateTime acceptedAt;
  final String appVersion;
  final String consentVersion;
  const ConsentLogData({
    required this.id,
    required this.userId,
    required this.route,
    required this.acceptedAt,
    required this.appVersion,
    required this.consentVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['route'] = Variable<String>(route);
    map['accepted_at'] = Variable<DateTime>(acceptedAt);
    map['app_version'] = Variable<String>(appVersion);
    map['consent_version'] = Variable<String>(consentVersion);
    return map;
  }

  ConsentLogCompanion toCompanion(bool nullToAbsent) {
    return ConsentLogCompanion(
      id: Value(id),
      userId: Value(userId),
      route: Value(route),
      acceptedAt: Value(acceptedAt),
      appVersion: Value(appVersion),
      consentVersion: Value(consentVersion),
    );
  }

  factory ConsentLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsentLogData(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      route: serializer.fromJson<String>(json['route']),
      acceptedAt: serializer.fromJson<DateTime>(json['acceptedAt']),
      appVersion: serializer.fromJson<String>(json['appVersion']),
      consentVersion: serializer.fromJson<String>(json['consentVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'route': serializer.toJson<String>(route),
      'acceptedAt': serializer.toJson<DateTime>(acceptedAt),
      'appVersion': serializer.toJson<String>(appVersion),
      'consentVersion': serializer.toJson<String>(consentVersion),
    };
  }

  ConsentLogData copyWith({
    int? id,
    String? userId,
    String? route,
    DateTime? acceptedAt,
    String? appVersion,
    String? consentVersion,
  }) => ConsentLogData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    route: route ?? this.route,
    acceptedAt: acceptedAt ?? this.acceptedAt,
    appVersion: appVersion ?? this.appVersion,
    consentVersion: consentVersion ?? this.consentVersion,
  );
  ConsentLogData copyWithCompanion(ConsentLogCompanion data) {
    return ConsentLogData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      route: data.route.present ? data.route.value : this.route,
      acceptedAt: data.acceptedAt.present
          ? data.acceptedAt.value
          : this.acceptedAt,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
      consentVersion: data.consentVersion.present
          ? data.consentVersion.value
          : this.consentVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsentLogData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('route: $route, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('appVersion: $appVersion, ')
          ..write('consentVersion: $consentVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, route, acceptedAt, appVersion, consentVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsentLogData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.route == this.route &&
          other.acceptedAt == this.acceptedAt &&
          other.appVersion == this.appVersion &&
          other.consentVersion == this.consentVersion);
}

class ConsentLogCompanion extends UpdateCompanion<ConsentLogData> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> route;
  final Value<DateTime> acceptedAt;
  final Value<String> appVersion;
  final Value<String> consentVersion;
  const ConsentLogCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.route = const Value.absent(),
    this.acceptedAt = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.consentVersion = const Value.absent(),
  });
  ConsentLogCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String route,
    required DateTime acceptedAt,
    required String appVersion,
    required String consentVersion,
  }) : userId = Value(userId),
       route = Value(route),
       acceptedAt = Value(acceptedAt),
       appVersion = Value(appVersion),
       consentVersion = Value(consentVersion);
  static Insertable<ConsentLogData> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? route,
    Expression<DateTime>? acceptedAt,
    Expression<String>? appVersion,
    Expression<String>? consentVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (route != null) 'route': route,
      if (acceptedAt != null) 'accepted_at': acceptedAt,
      if (appVersion != null) 'app_version': appVersion,
      if (consentVersion != null) 'consent_version': consentVersion,
    });
  }

  ConsentLogCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? route,
    Value<DateTime>? acceptedAt,
    Value<String>? appVersion,
    Value<String>? consentVersion,
  }) {
    return ConsentLogCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      route: route ?? this.route,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      appVersion: appVersion ?? this.appVersion,
      consentVersion: consentVersion ?? this.consentVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (route.present) {
      map['route'] = Variable<String>(route.value);
    }
    if (acceptedAt.present) {
      map['accepted_at'] = Variable<DateTime>(acceptedAt.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (consentVersion.present) {
      map['consent_version'] = Variable<String>(consentVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentLogCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('route: $route, ')
          ..write('acceptedAt: $acceptedAt, ')
          ..write('appVersion: $appVersion, ')
          ..write('consentVersion: $consentVersion')
          ..write(')'))
        .toString();
  }
}

class $ProfileTable extends Profile with TableInfo<$ProfileTable, ProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ageMeta = const VerificationMeta('age');
  @override
  late final GeneratedColumn<int> age = GeneratedColumn<int>(
    'age',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrRestMeta = const VerificationMeta('hrRest');
  @override
  late final GeneratedColumn<int> hrRest = GeneratedColumn<int>(
    'hr_rest',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrRestSourceMeta = const VerificationMeta(
    'hrRestSource',
  );
  @override
  late final GeneratedColumn<String> hrRestSource = GeneratedColumn<String>(
    'hr_rest_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrMaxMeta = const VerificationMeta('hrMax');
  @override
  late final GeneratedColumn<int> hrMax = GeneratedColumn<int>(
    'hr_max',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrMaxSourceMeta = const VerificationMeta(
    'hrMaxSource',
  );
  @override
  late final GeneratedColumn<String> hrMaxSource = GeneratedColumn<String>(
    'hr_max_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fcSv1Meta = const VerificationMeta('fcSv1');
  @override
  late final GeneratedColumn<int> fcSv1 = GeneratedColumn<int>(
    'fc_sv1',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fcSv2Meta = const VerificationMeta('fcSv2');
  @override
  late final GeneratedColumn<int> fcSv2 = GeneratedColumn<int>(
    'fc_sv2',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thresholdProvenanceMeta =
      const VerificationMeta('thresholdProvenance');
  @override
  late final GeneratedColumn<String> thresholdProvenance =
      GeneratedColumn<String>(
        'threshold_provenance',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _aerobicCeilingMeta = const VerificationMeta(
    'aerobicCeiling',
  );
  @override
  late final GeneratedColumn<int> aerobicCeiling = GeneratedColumn<int>(
    'aerobic_ceiling',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baselineRmssdMeta = const VerificationMeta(
    'baselineRmssd',
  );
  @override
  late final GeneratedColumn<double> baselineRmssd = GeneratedColumn<double>(
    'baseline_rmssd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baselineUpdatedAtMeta = const VerificationMeta(
    'baselineUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> baselineUpdatedAt =
      GeneratedColumn<DateTime>(
        'baseline_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    age,
    sex,
    weightKg,
    heightCm,
    hrRest,
    hrRestSource,
    hrMax,
    hrMaxSource,
    fcSv1,
    fcSv2,
    thresholdProvenance,
    aerobicCeiling,
    baselineRmssd,
    baselineUpdatedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('hr_rest')) {
      context.handle(
        _hrRestMeta,
        hrRest.isAcceptableOrUnknown(data['hr_rest']!, _hrRestMeta),
      );
    }
    if (data.containsKey('hr_rest_source')) {
      context.handle(
        _hrRestSourceMeta,
        hrRestSource.isAcceptableOrUnknown(
          data['hr_rest_source']!,
          _hrRestSourceMeta,
        ),
      );
    }
    if (data.containsKey('hr_max')) {
      context.handle(
        _hrMaxMeta,
        hrMax.isAcceptableOrUnknown(data['hr_max']!, _hrMaxMeta),
      );
    }
    if (data.containsKey('hr_max_source')) {
      context.handle(
        _hrMaxSourceMeta,
        hrMaxSource.isAcceptableOrUnknown(
          data['hr_max_source']!,
          _hrMaxSourceMeta,
        ),
      );
    }
    if (data.containsKey('fc_sv1')) {
      context.handle(
        _fcSv1Meta,
        fcSv1.isAcceptableOrUnknown(data['fc_sv1']!, _fcSv1Meta),
      );
    }
    if (data.containsKey('fc_sv2')) {
      context.handle(
        _fcSv2Meta,
        fcSv2.isAcceptableOrUnknown(data['fc_sv2']!, _fcSv2Meta),
      );
    }
    if (data.containsKey('threshold_provenance')) {
      context.handle(
        _thresholdProvenanceMeta,
        thresholdProvenance.isAcceptableOrUnknown(
          data['threshold_provenance']!,
          _thresholdProvenanceMeta,
        ),
      );
    }
    if (data.containsKey('aerobic_ceiling')) {
      context.handle(
        _aerobicCeilingMeta,
        aerobicCeiling.isAcceptableOrUnknown(
          data['aerobic_ceiling']!,
          _aerobicCeilingMeta,
        ),
      );
    }
    if (data.containsKey('baseline_rmssd')) {
      context.handle(
        _baselineRmssdMeta,
        baselineRmssd.isAcceptableOrUnknown(
          data['baseline_rmssd']!,
          _baselineRmssdMeta,
        ),
      );
    }
    if (data.containsKey('baseline_updated_at')) {
      context.handle(
        _baselineUpdatedAtMeta,
        baselineUpdatedAt.isAcceptableOrUnknown(
          data['baseline_updated_at']!,
          _baselineUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  ProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      age: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}age'],
      ),
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      hrRest: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_rest'],
      ),
      hrRestSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hr_rest_source'],
      ),
      hrMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hr_max'],
      ),
      hrMaxSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hr_max_source'],
      ),
      fcSv1: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fc_sv1'],
      ),
      fcSv2: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fc_sv2'],
      ),
      thresholdProvenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}threshold_provenance'],
      ),
      aerobicCeiling: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aerobic_ceiling'],
      ),
      baselineRmssd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}baseline_rmssd'],
      ),
      baselineUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}baseline_updated_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfileTable createAlias(String alias) {
    return $ProfileTable(attachedDatabase, alias);
  }
}

class ProfileData extends DataClass implements Insertable<ProfileData> {
  final String userId;
  final int? age;
  final String? sex;
  final double? weightKg;
  final double? heightCm;
  final int? hrRest;

  /// 'mode_c' | 'manual' — origine de la FC de repos courante.
  final String? hrRestSource;
  final int? hrMax;

  /// 'measured' | 'tanaka' | 'manual'
  final String? hrMaxSource;
  final int? fcSv1;
  final int? fcSv2;

  /// 'measured_modeB' | 'estimated_karvonen' | 'manual_lab'
  final String? thresholdProvenance;

  /// Plafond aérobie estimé (~70 % FCR, proxy SV1 avant mesure mode B).
  final int? aerobicCeiling;
  final double? baselineRmssd;
  final DateTime? baselineUpdatedAt;
  final DateTime updatedAt;
  const ProfileData({
    required this.userId,
    this.age,
    this.sex,
    this.weightKg,
    this.heightCm,
    this.hrRest,
    this.hrRestSource,
    this.hrMax,
    this.hrMaxSource,
    this.fcSv1,
    this.fcSv2,
    this.thresholdProvenance,
    this.aerobicCeiling,
    this.baselineRmssd,
    this.baselineUpdatedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || age != null) {
      map['age'] = Variable<int>(age);
    }
    if (!nullToAbsent || sex != null) {
      map['sex'] = Variable<String>(sex);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || hrRest != null) {
      map['hr_rest'] = Variable<int>(hrRest);
    }
    if (!nullToAbsent || hrRestSource != null) {
      map['hr_rest_source'] = Variable<String>(hrRestSource);
    }
    if (!nullToAbsent || hrMax != null) {
      map['hr_max'] = Variable<int>(hrMax);
    }
    if (!nullToAbsent || hrMaxSource != null) {
      map['hr_max_source'] = Variable<String>(hrMaxSource);
    }
    if (!nullToAbsent || fcSv1 != null) {
      map['fc_sv1'] = Variable<int>(fcSv1);
    }
    if (!nullToAbsent || fcSv2 != null) {
      map['fc_sv2'] = Variable<int>(fcSv2);
    }
    if (!nullToAbsent || thresholdProvenance != null) {
      map['threshold_provenance'] = Variable<String>(thresholdProvenance);
    }
    if (!nullToAbsent || aerobicCeiling != null) {
      map['aerobic_ceiling'] = Variable<int>(aerobicCeiling);
    }
    if (!nullToAbsent || baselineRmssd != null) {
      map['baseline_rmssd'] = Variable<double>(baselineRmssd);
    }
    if (!nullToAbsent || baselineUpdatedAt != null) {
      map['baseline_updated_at'] = Variable<DateTime>(baselineUpdatedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProfileCompanion toCompanion(bool nullToAbsent) {
    return ProfileCompanion(
      userId: Value(userId),
      age: age == null && nullToAbsent ? const Value.absent() : Value(age),
      sex: sex == null && nullToAbsent ? const Value.absent() : Value(sex),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      hrRest: hrRest == null && nullToAbsent
          ? const Value.absent()
          : Value(hrRest),
      hrRestSource: hrRestSource == null && nullToAbsent
          ? const Value.absent()
          : Value(hrRestSource),
      hrMax: hrMax == null && nullToAbsent
          ? const Value.absent()
          : Value(hrMax),
      hrMaxSource: hrMaxSource == null && nullToAbsent
          ? const Value.absent()
          : Value(hrMaxSource),
      fcSv1: fcSv1 == null && nullToAbsent
          ? const Value.absent()
          : Value(fcSv1),
      fcSv2: fcSv2 == null && nullToAbsent
          ? const Value.absent()
          : Value(fcSv2),
      thresholdProvenance: thresholdProvenance == null && nullToAbsent
          ? const Value.absent()
          : Value(thresholdProvenance),
      aerobicCeiling: aerobicCeiling == null && nullToAbsent
          ? const Value.absent()
          : Value(aerobicCeiling),
      baselineRmssd: baselineRmssd == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineRmssd),
      baselineUpdatedAt: baselineUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(baselineUpdatedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileData(
      userId: serializer.fromJson<String>(json['userId']),
      age: serializer.fromJson<int?>(json['age']),
      sex: serializer.fromJson<String?>(json['sex']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      hrRest: serializer.fromJson<int?>(json['hrRest']),
      hrRestSource: serializer.fromJson<String?>(json['hrRestSource']),
      hrMax: serializer.fromJson<int?>(json['hrMax']),
      hrMaxSource: serializer.fromJson<String?>(json['hrMaxSource']),
      fcSv1: serializer.fromJson<int?>(json['fcSv1']),
      fcSv2: serializer.fromJson<int?>(json['fcSv2']),
      thresholdProvenance: serializer.fromJson<String?>(
        json['thresholdProvenance'],
      ),
      aerobicCeiling: serializer.fromJson<int?>(json['aerobicCeiling']),
      baselineRmssd: serializer.fromJson<double?>(json['baselineRmssd']),
      baselineUpdatedAt: serializer.fromJson<DateTime?>(
        json['baselineUpdatedAt'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'age': serializer.toJson<int?>(age),
      'sex': serializer.toJson<String?>(sex),
      'weightKg': serializer.toJson<double?>(weightKg),
      'heightCm': serializer.toJson<double?>(heightCm),
      'hrRest': serializer.toJson<int?>(hrRest),
      'hrRestSource': serializer.toJson<String?>(hrRestSource),
      'hrMax': serializer.toJson<int?>(hrMax),
      'hrMaxSource': serializer.toJson<String?>(hrMaxSource),
      'fcSv1': serializer.toJson<int?>(fcSv1),
      'fcSv2': serializer.toJson<int?>(fcSv2),
      'thresholdProvenance': serializer.toJson<String?>(thresholdProvenance),
      'aerobicCeiling': serializer.toJson<int?>(aerobicCeiling),
      'baselineRmssd': serializer.toJson<double?>(baselineRmssd),
      'baselineUpdatedAt': serializer.toJson<DateTime?>(baselineUpdatedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProfileData copyWith({
    String? userId,
    Value<int?> age = const Value.absent(),
    Value<String?> sex = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    Value<int?> hrRest = const Value.absent(),
    Value<String?> hrRestSource = const Value.absent(),
    Value<int?> hrMax = const Value.absent(),
    Value<String?> hrMaxSource = const Value.absent(),
    Value<int?> fcSv1 = const Value.absent(),
    Value<int?> fcSv2 = const Value.absent(),
    Value<String?> thresholdProvenance = const Value.absent(),
    Value<int?> aerobicCeiling = const Value.absent(),
    Value<double?> baselineRmssd = const Value.absent(),
    Value<DateTime?> baselineUpdatedAt = const Value.absent(),
    DateTime? updatedAt,
  }) => ProfileData(
    userId: userId ?? this.userId,
    age: age.present ? age.value : this.age,
    sex: sex.present ? sex.value : this.sex,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    hrRest: hrRest.present ? hrRest.value : this.hrRest,
    hrRestSource: hrRestSource.present ? hrRestSource.value : this.hrRestSource,
    hrMax: hrMax.present ? hrMax.value : this.hrMax,
    hrMaxSource: hrMaxSource.present ? hrMaxSource.value : this.hrMaxSource,
    fcSv1: fcSv1.present ? fcSv1.value : this.fcSv1,
    fcSv2: fcSv2.present ? fcSv2.value : this.fcSv2,
    thresholdProvenance: thresholdProvenance.present
        ? thresholdProvenance.value
        : this.thresholdProvenance,
    aerobicCeiling: aerobicCeiling.present
        ? aerobicCeiling.value
        : this.aerobicCeiling,
    baselineRmssd: baselineRmssd.present
        ? baselineRmssd.value
        : this.baselineRmssd,
    baselineUpdatedAt: baselineUpdatedAt.present
        ? baselineUpdatedAt.value
        : this.baselineUpdatedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfileData copyWithCompanion(ProfileCompanion data) {
    return ProfileData(
      userId: data.userId.present ? data.userId.value : this.userId,
      age: data.age.present ? data.age.value : this.age,
      sex: data.sex.present ? data.sex.value : this.sex,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      hrRest: data.hrRest.present ? data.hrRest.value : this.hrRest,
      hrRestSource: data.hrRestSource.present
          ? data.hrRestSource.value
          : this.hrRestSource,
      hrMax: data.hrMax.present ? data.hrMax.value : this.hrMax,
      hrMaxSource: data.hrMaxSource.present
          ? data.hrMaxSource.value
          : this.hrMaxSource,
      fcSv1: data.fcSv1.present ? data.fcSv1.value : this.fcSv1,
      fcSv2: data.fcSv2.present ? data.fcSv2.value : this.fcSv2,
      thresholdProvenance: data.thresholdProvenance.present
          ? data.thresholdProvenance.value
          : this.thresholdProvenance,
      aerobicCeiling: data.aerobicCeiling.present
          ? data.aerobicCeiling.value
          : this.aerobicCeiling,
      baselineRmssd: data.baselineRmssd.present
          ? data.baselineRmssd.value
          : this.baselineRmssd,
      baselineUpdatedAt: data.baselineUpdatedAt.present
          ? data.baselineUpdatedAt.value
          : this.baselineUpdatedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileData(')
          ..write('userId: $userId, ')
          ..write('age: $age, ')
          ..write('sex: $sex, ')
          ..write('weightKg: $weightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('hrRest: $hrRest, ')
          ..write('hrRestSource: $hrRestSource, ')
          ..write('hrMax: $hrMax, ')
          ..write('hrMaxSource: $hrMaxSource, ')
          ..write('fcSv1: $fcSv1, ')
          ..write('fcSv2: $fcSv2, ')
          ..write('thresholdProvenance: $thresholdProvenance, ')
          ..write('aerobicCeiling: $aerobicCeiling, ')
          ..write('baselineRmssd: $baselineRmssd, ')
          ..write('baselineUpdatedAt: $baselineUpdatedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    age,
    sex,
    weightKg,
    heightCm,
    hrRest,
    hrRestSource,
    hrMax,
    hrMaxSource,
    fcSv1,
    fcSv2,
    thresholdProvenance,
    aerobicCeiling,
    baselineRmssd,
    baselineUpdatedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileData &&
          other.userId == this.userId &&
          other.age == this.age &&
          other.sex == this.sex &&
          other.weightKg == this.weightKg &&
          other.heightCm == this.heightCm &&
          other.hrRest == this.hrRest &&
          other.hrRestSource == this.hrRestSource &&
          other.hrMax == this.hrMax &&
          other.hrMaxSource == this.hrMaxSource &&
          other.fcSv1 == this.fcSv1 &&
          other.fcSv2 == this.fcSv2 &&
          other.thresholdProvenance == this.thresholdProvenance &&
          other.aerobicCeiling == this.aerobicCeiling &&
          other.baselineRmssd == this.baselineRmssd &&
          other.baselineUpdatedAt == this.baselineUpdatedAt &&
          other.updatedAt == this.updatedAt);
}

class ProfileCompanion extends UpdateCompanion<ProfileData> {
  final Value<String> userId;
  final Value<int?> age;
  final Value<String?> sex;
  final Value<double?> weightKg;
  final Value<double?> heightCm;
  final Value<int?> hrRest;
  final Value<String?> hrRestSource;
  final Value<int?> hrMax;
  final Value<String?> hrMaxSource;
  final Value<int?> fcSv1;
  final Value<int?> fcSv2;
  final Value<String?> thresholdProvenance;
  final Value<int?> aerobicCeiling;
  final Value<double?> baselineRmssd;
  final Value<DateTime?> baselineUpdatedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProfileCompanion({
    this.userId = const Value.absent(),
    this.age = const Value.absent(),
    this.sex = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.hrRest = const Value.absent(),
    this.hrRestSource = const Value.absent(),
    this.hrMax = const Value.absent(),
    this.hrMaxSource = const Value.absent(),
    this.fcSv1 = const Value.absent(),
    this.fcSv2 = const Value.absent(),
    this.thresholdProvenance = const Value.absent(),
    this.aerobicCeiling = const Value.absent(),
    this.baselineRmssd = const Value.absent(),
    this.baselineUpdatedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileCompanion.insert({
    required String userId,
    this.age = const Value.absent(),
    this.sex = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.hrRest = const Value.absent(),
    this.hrRestSource = const Value.absent(),
    this.hrMax = const Value.absent(),
    this.hrMaxSource = const Value.absent(),
    this.fcSv1 = const Value.absent(),
    this.fcSv2 = const Value.absent(),
    this.thresholdProvenance = const Value.absent(),
    this.aerobicCeiling = const Value.absent(),
    this.baselineRmssd = const Value.absent(),
    this.baselineUpdatedAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileData> custom({
    Expression<String>? userId,
    Expression<int>? age,
    Expression<String>? sex,
    Expression<double>? weightKg,
    Expression<double>? heightCm,
    Expression<int>? hrRest,
    Expression<String>? hrRestSource,
    Expression<int>? hrMax,
    Expression<String>? hrMaxSource,
    Expression<int>? fcSv1,
    Expression<int>? fcSv2,
    Expression<String>? thresholdProvenance,
    Expression<int>? aerobicCeiling,
    Expression<double>? baselineRmssd,
    Expression<DateTime>? baselineUpdatedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (age != null) 'age': age,
      if (sex != null) 'sex': sex,
      if (weightKg != null) 'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
      if (hrRest != null) 'hr_rest': hrRest,
      if (hrRestSource != null) 'hr_rest_source': hrRestSource,
      if (hrMax != null) 'hr_max': hrMax,
      if (hrMaxSource != null) 'hr_max_source': hrMaxSource,
      if (fcSv1 != null) 'fc_sv1': fcSv1,
      if (fcSv2 != null) 'fc_sv2': fcSv2,
      if (thresholdProvenance != null)
        'threshold_provenance': thresholdProvenance,
      if (aerobicCeiling != null) 'aerobic_ceiling': aerobicCeiling,
      if (baselineRmssd != null) 'baseline_rmssd': baselineRmssd,
      if (baselineUpdatedAt != null) 'baseline_updated_at': baselineUpdatedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileCompanion copyWith({
    Value<String>? userId,
    Value<int?>? age,
    Value<String?>? sex,
    Value<double?>? weightKg,
    Value<double?>? heightCm,
    Value<int?>? hrRest,
    Value<String?>? hrRestSource,
    Value<int?>? hrMax,
    Value<String?>? hrMaxSource,
    Value<int?>? fcSv1,
    Value<int?>? fcSv2,
    Value<String?>? thresholdProvenance,
    Value<int?>? aerobicCeiling,
    Value<double?>? baselineRmssd,
    Value<DateTime?>? baselineUpdatedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfileCompanion(
      userId: userId ?? this.userId,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      hrRest: hrRest ?? this.hrRest,
      hrRestSource: hrRestSource ?? this.hrRestSource,
      hrMax: hrMax ?? this.hrMax,
      hrMaxSource: hrMaxSource ?? this.hrMaxSource,
      fcSv1: fcSv1 ?? this.fcSv1,
      fcSv2: fcSv2 ?? this.fcSv2,
      thresholdProvenance: thresholdProvenance ?? this.thresholdProvenance,
      aerobicCeiling: aerobicCeiling ?? this.aerobicCeiling,
      baselineRmssd: baselineRmssd ?? this.baselineRmssd,
      baselineUpdatedAt: baselineUpdatedAt ?? this.baselineUpdatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (age.present) {
      map['age'] = Variable<int>(age.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (hrRest.present) {
      map['hr_rest'] = Variable<int>(hrRest.value);
    }
    if (hrRestSource.present) {
      map['hr_rest_source'] = Variable<String>(hrRestSource.value);
    }
    if (hrMax.present) {
      map['hr_max'] = Variable<int>(hrMax.value);
    }
    if (hrMaxSource.present) {
      map['hr_max_source'] = Variable<String>(hrMaxSource.value);
    }
    if (fcSv1.present) {
      map['fc_sv1'] = Variable<int>(fcSv1.value);
    }
    if (fcSv2.present) {
      map['fc_sv2'] = Variable<int>(fcSv2.value);
    }
    if (thresholdProvenance.present) {
      map['threshold_provenance'] = Variable<String>(thresholdProvenance.value);
    }
    if (aerobicCeiling.present) {
      map['aerobic_ceiling'] = Variable<int>(aerobicCeiling.value);
    }
    if (baselineRmssd.present) {
      map['baseline_rmssd'] = Variable<double>(baselineRmssd.value);
    }
    if (baselineUpdatedAt.present) {
      map['baseline_updated_at'] = Variable<DateTime>(baselineUpdatedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileCompanion(')
          ..write('userId: $userId, ')
          ..write('age: $age, ')
          ..write('sex: $sex, ')
          ..write('weightKg: $weightKg, ')
          ..write('heightCm: $heightCm, ')
          ..write('hrRest: $hrRest, ')
          ..write('hrRestSource: $hrRestSource, ')
          ..write('hrMax: $hrMax, ')
          ..write('hrMaxSource: $hrMaxSource, ')
          ..write('fcSv1: $fcSv1, ')
          ..write('fcSv2: $fcSv2, ')
          ..write('thresholdProvenance: $thresholdProvenance, ')
          ..write('aerobicCeiling: $aerobicCeiling, ')
          ..write('baselineRmssd: $baselineRmssd, ')
          ..write('baselineUpdatedAt: $baselineUpdatedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyEntriesTable extends DailyEntries
    with TableInfo<$DailyEntriesTable, DailyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rpePsychologicalMeta = const VerificationMeta(
    'rpePsychological',
  );
  @override
  late final GeneratedColumn<int> rpePsychological = GeneratedColumn<int>(
    'rpe_psychological',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpeComparisonMeta = const VerificationMeta(
    'rpeComparison',
  );
  @override
  late final GeneratedColumn<int> rpeComparison = GeneratedColumn<int>(
    'rpe_comparison',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    day,
    rpePsychological,
    rpeComparison,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('rpe_psychological')) {
      context.handle(
        _rpePsychologicalMeta,
        rpePsychological.isAcceptableOrUnknown(
          data['rpe_psychological']!,
          _rpePsychologicalMeta,
        ),
      );
    }
    if (data.containsKey('rpe_comparison')) {
      context.handle(
        _rpeComparisonMeta,
        rpeComparison.isAcceptableOrUnknown(
          data['rpe_comparison']!,
          _rpeComparisonMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, day};
  @override
  DailyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyEntry(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      rpePsychological: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rpe_psychological'],
      ),
      rpeComparison: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rpe_comparison'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DailyEntriesTable createAlias(String alias) {
    return $DailyEntriesTable(attachedDatabase, alias);
  }
}

class DailyEntry extends DataClass implements Insertable<DailyEntry> {
  final String userId;

  /// Jour normalisé à minuit UTC : DateTime(année, mois, jour).
  final DateTime day;

  /// RPE psychologique CR10 (0–10) : ressenti global de la journée.
  final int? rpePsychological;

  /// RPE de comparaison (−2..+2) : journée mode D estimée vs journées de référence.
  final int? rpeComparison;
  final DateTime updatedAt;
  const DailyEntry({
    required this.userId,
    required this.day,
    this.rpePsychological,
    this.rpeComparison,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['day'] = Variable<DateTime>(day);
    if (!nullToAbsent || rpePsychological != null) {
      map['rpe_psychological'] = Variable<int>(rpePsychological);
    }
    if (!nullToAbsent || rpeComparison != null) {
      map['rpe_comparison'] = Variable<int>(rpeComparison);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyEntriesCompanion toCompanion(bool nullToAbsent) {
    return DailyEntriesCompanion(
      userId: Value(userId),
      day: Value(day),
      rpePsychological: rpePsychological == null && nullToAbsent
          ? const Value.absent()
          : Value(rpePsychological),
      rpeComparison: rpeComparison == null && nullToAbsent
          ? const Value.absent()
          : Value(rpeComparison),
      updatedAt: Value(updatedAt),
    );
  }

  factory DailyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyEntry(
      userId: serializer.fromJson<String>(json['userId']),
      day: serializer.fromJson<DateTime>(json['day']),
      rpePsychological: serializer.fromJson<int?>(json['rpePsychological']),
      rpeComparison: serializer.fromJson<int?>(json['rpeComparison']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'day': serializer.toJson<DateTime>(day),
      'rpePsychological': serializer.toJson<int?>(rpePsychological),
      'rpeComparison': serializer.toJson<int?>(rpeComparison),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DailyEntry copyWith({
    String? userId,
    DateTime? day,
    Value<int?> rpePsychological = const Value.absent(),
    Value<int?> rpeComparison = const Value.absent(),
    DateTime? updatedAt,
  }) => DailyEntry(
    userId: userId ?? this.userId,
    day: day ?? this.day,
    rpePsychological: rpePsychological.present
        ? rpePsychological.value
        : this.rpePsychological,
    rpeComparison: rpeComparison.present
        ? rpeComparison.value
        : this.rpeComparison,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DailyEntry copyWithCompanion(DailyEntriesCompanion data) {
    return DailyEntry(
      userId: data.userId.present ? data.userId.value : this.userId,
      day: data.day.present ? data.day.value : this.day,
      rpePsychological: data.rpePsychological.present
          ? data.rpePsychological.value
          : this.rpePsychological,
      rpeComparison: data.rpeComparison.present
          ? data.rpeComparison.value
          : this.rpeComparison,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyEntry(')
          ..write('userId: $userId, ')
          ..write('day: $day, ')
          ..write('rpePsychological: $rpePsychological, ')
          ..write('rpeComparison: $rpeComparison, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, day, rpePsychological, rpeComparison, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyEntry &&
          other.userId == this.userId &&
          other.day == this.day &&
          other.rpePsychological == this.rpePsychological &&
          other.rpeComparison == this.rpeComparison &&
          other.updatedAt == this.updatedAt);
}

class DailyEntriesCompanion extends UpdateCompanion<DailyEntry> {
  final Value<String> userId;
  final Value<DateTime> day;
  final Value<int?> rpePsychological;
  final Value<int?> rpeComparison;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DailyEntriesCompanion({
    this.userId = const Value.absent(),
    this.day = const Value.absent(),
    this.rpePsychological = const Value.absent(),
    this.rpeComparison = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyEntriesCompanion.insert({
    required String userId,
    required DateTime day,
    this.rpePsychological = const Value.absent(),
    this.rpeComparison = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       day = Value(day),
       updatedAt = Value(updatedAt);
  static Insertable<DailyEntry> custom({
    Expression<String>? userId,
    Expression<DateTime>? day,
    Expression<int>? rpePsychological,
    Expression<int>? rpeComparison,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (day != null) 'day': day,
      if (rpePsychological != null) 'rpe_psychological': rpePsychological,
      if (rpeComparison != null) 'rpe_comparison': rpeComparison,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyEntriesCompanion copyWith({
    Value<String>? userId,
    Value<DateTime>? day,
    Value<int?>? rpePsychological,
    Value<int?>? rpeComparison,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DailyEntriesCompanion(
      userId: userId ?? this.userId,
      day: day ?? this.day,
      rpePsychological: rpePsychological ?? this.rpePsychological,
      rpeComparison: rpeComparison ?? this.rpeComparison,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (rpePsychological.present) {
      map['rpe_psychological'] = Variable<int>(rpePsychological.value);
    }
    if (rpeComparison.present) {
      map['rpe_comparison'] = Variable<int>(rpeComparison.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyEntriesCompanion(')
          ..write('userId: $userId, ')
          ..write('day: $day, ')
          ..write('rpePsychological: $rpePsychological, ')
          ..write('rpeComparison: $rpeComparison, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HooperMackinnonEntriesTable extends HooperMackinnonEntries
    with TableInfo<$HooperMackinnonEntriesTable, HooperMackinnonEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HooperMackinnonEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fatigueMeta = const VerificationMeta(
    'fatigue',
  );
  @override
  late final GeneratedColumn<int> fatigue = GeneratedColumn<int>(
    'fatigue',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stressMeta = const VerificationMeta('stress');
  @override
  late final GeneratedColumn<int> stress = GeneratedColumn<int>(
    'stress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _domsMeta = const VerificationMeta('doms');
  @override
  late final GeneratedColumn<int> doms = GeneratedColumn<int>(
    'doms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sleepMeta = const VerificationMeta('sleep');
  @override
  late final GeneratedColumn<int> sleep = GeneratedColumn<int>(
    'sleep',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    userId,
    fatigue,
    stress,
    doms,
    sleep,
    recordedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hooper_mackinnon_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<HooperMackinnonEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('fatigue')) {
      context.handle(
        _fatigueMeta,
        fatigue.isAcceptableOrUnknown(data['fatigue']!, _fatigueMeta),
      );
    } else if (isInserting) {
      context.missing(_fatigueMeta);
    }
    if (data.containsKey('stress')) {
      context.handle(
        _stressMeta,
        stress.isAcceptableOrUnknown(data['stress']!, _stressMeta),
      );
    } else if (isInserting) {
      context.missing(_stressMeta);
    }
    if (data.containsKey('doms')) {
      context.handle(
        _domsMeta,
        doms.isAcceptableOrUnknown(data['doms']!, _domsMeta),
      );
    } else if (isInserting) {
      context.missing(_domsMeta);
    }
    if (data.containsKey('sleep')) {
      context.handle(
        _sleepMeta,
        sleep.isAcceptableOrUnknown(data['sleep']!, _sleepMeta),
      );
    } else if (isInserting) {
      context.missing(_sleepMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HooperMackinnonEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HooperMackinnonEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      fatigue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fatigue'],
      )!,
      stress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stress'],
      )!,
      doms: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}doms'],
      )!,
      sleep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $HooperMackinnonEntriesTable createAlias(String alias) {
    return $HooperMackinnonEntriesTable(attachedDatabase, alias);
  }
}

class HooperMackinnonEntry extends DataClass
    implements Insertable<HooperMackinnonEntry> {
  final int id;
  final int sessionId;
  final String userId;

  /// 4 items Hooper-Mackinnon, chacun noté 1–7 (1 = excellent, 7 = très mauvais).
  final int fatigue;
  final int stress;
  final int doms;
  final int sleep;
  final DateTime recordedAt;
  const HooperMackinnonEntry({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.fatigue,
    required this.stress,
    required this.doms,
    required this.sleep,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['user_id'] = Variable<String>(userId);
    map['fatigue'] = Variable<int>(fatigue);
    map['stress'] = Variable<int>(stress);
    map['doms'] = Variable<int>(doms);
    map['sleep'] = Variable<int>(sleep);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  HooperMackinnonEntriesCompanion toCompanion(bool nullToAbsent) {
    return HooperMackinnonEntriesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      userId: Value(userId),
      fatigue: Value(fatigue),
      stress: Value(stress),
      doms: Value(doms),
      sleep: Value(sleep),
      recordedAt: Value(recordedAt),
    );
  }

  factory HooperMackinnonEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HooperMackinnonEntry(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      userId: serializer.fromJson<String>(json['userId']),
      fatigue: serializer.fromJson<int>(json['fatigue']),
      stress: serializer.fromJson<int>(json['stress']),
      doms: serializer.fromJson<int>(json['doms']),
      sleep: serializer.fromJson<int>(json['sleep']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'userId': serializer.toJson<String>(userId),
      'fatigue': serializer.toJson<int>(fatigue),
      'stress': serializer.toJson<int>(stress),
      'doms': serializer.toJson<int>(doms),
      'sleep': serializer.toJson<int>(sleep),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  HooperMackinnonEntry copyWith({
    int? id,
    int? sessionId,
    String? userId,
    int? fatigue,
    int? stress,
    int? doms,
    int? sleep,
    DateTime? recordedAt,
  }) => HooperMackinnonEntry(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    userId: userId ?? this.userId,
    fatigue: fatigue ?? this.fatigue,
    stress: stress ?? this.stress,
    doms: doms ?? this.doms,
    sleep: sleep ?? this.sleep,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  HooperMackinnonEntry copyWithCompanion(HooperMackinnonEntriesCompanion data) {
    return HooperMackinnonEntry(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      userId: data.userId.present ? data.userId.value : this.userId,
      fatigue: data.fatigue.present ? data.fatigue.value : this.fatigue,
      stress: data.stress.present ? data.stress.value : this.stress,
      doms: data.doms.present ? data.doms.value : this.doms,
      sleep: data.sleep.present ? data.sleep.value : this.sleep,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HooperMackinnonEntry(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('userId: $userId, ')
          ..write('fatigue: $fatigue, ')
          ..write('stress: $stress, ')
          ..write('doms: $doms, ')
          ..write('sleep: $sleep, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    userId,
    fatigue,
    stress,
    doms,
    sleep,
    recordedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HooperMackinnonEntry &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.userId == this.userId &&
          other.fatigue == this.fatigue &&
          other.stress == this.stress &&
          other.doms == this.doms &&
          other.sleep == this.sleep &&
          other.recordedAt == this.recordedAt);
}

class HooperMackinnonEntriesCompanion
    extends UpdateCompanion<HooperMackinnonEntry> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String> userId;
  final Value<int> fatigue;
  final Value<int> stress;
  final Value<int> doms;
  final Value<int> sleep;
  final Value<DateTime> recordedAt;
  const HooperMackinnonEntriesCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.userId = const Value.absent(),
    this.fatigue = const Value.absent(),
    this.stress = const Value.absent(),
    this.doms = const Value.absent(),
    this.sleep = const Value.absent(),
    this.recordedAt = const Value.absent(),
  });
  HooperMackinnonEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required String userId,
    required int fatigue,
    required int stress,
    required int doms,
    required int sleep,
    required DateTime recordedAt,
  }) : sessionId = Value(sessionId),
       userId = Value(userId),
       fatigue = Value(fatigue),
       stress = Value(stress),
       doms = Value(doms),
       sleep = Value(sleep),
       recordedAt = Value(recordedAt);
  static Insertable<HooperMackinnonEntry> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? userId,
    Expression<int>? fatigue,
    Expression<int>? stress,
    Expression<int>? doms,
    Expression<int>? sleep,
    Expression<DateTime>? recordedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (userId != null) 'user_id': userId,
      if (fatigue != null) 'fatigue': fatigue,
      if (stress != null) 'stress': stress,
      if (doms != null) 'doms': doms,
      if (sleep != null) 'sleep': sleep,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  HooperMackinnonEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String>? userId,
    Value<int>? fatigue,
    Value<int>? stress,
    Value<int>? doms,
    Value<int>? sleep,
    Value<DateTime>? recordedAt,
  }) {
    return HooperMackinnonEntriesCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      fatigue: fatigue ?? this.fatigue,
      stress: stress ?? this.stress,
      doms: doms ?? this.doms,
      sleep: sleep ?? this.sleep,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (fatigue.present) {
      map['fatigue'] = Variable<int>(fatigue.value);
    }
    if (stress.present) {
      map['stress'] = Variable<int>(stress.value);
    }
    if (doms.present) {
      map['doms'] = Variable<int>(doms.value);
    }
    if (sleep.present) {
      map['sleep'] = Variable<int>(sleep.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HooperMackinnonEntriesCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('userId: $userId, ')
          ..write('fatigue: $fatigue, ')
          ..write('stress: $stress, ')
          ..write('doms: $doms, ')
          ..write('sleep: $sleep, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $IndicatorsTable indicators = $IndicatorsTable(this);
  late final $RrSamplesTable rrSamples = $RrSamplesTable(this);
  late final $ConsentLogTable consentLog = $ConsentLogTable(this);
  late final $ProfileTable profile = $ProfileTable(this);
  late final $DailyEntriesTable dailyEntries = $DailyEntriesTable(this);
  late final $HooperMackinnonEntriesTable hooperMackinnonEntries =
      $HooperMackinnonEntriesTable(this);
  late final SessionDao sessionDao = SessionDao(this as AppDatabase);
  late final IndicatorDao indicatorDao = IndicatorDao(this as AppDatabase);
  late final RrDao rrDao = RrDao(this as AppDatabase);
  late final ProfileDao profileDao = ProfileDao(this as AppDatabase);
  late final ConsentDao consentDao = ConsentDao(this as AppDatabase);
  late final DailyEntryDao dailyEntryDao = DailyEntryDao(this as AppDatabase);
  late final HooperDao hooperDao = HooperDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    indicators,
    rrSamples,
    consentLog,
    profile,
    dailyEntries,
    hooperMackinnonEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('indicators', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rr_samples', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('hooper_mackinnon_entries', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required String userId,
      required String mode,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<double> qualityRatio,
      Value<int?> rpePhysical,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> mode,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<double> qualityRatio,
      Value<int?> rpePhysical,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IndicatorsTable, List<Indicator>>
  _indicatorsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.indicators,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.indicators.sessionId),
  );

  $$IndicatorsTableProcessedTableManager get indicatorsRefs {
    final manager = $$IndicatorsTableTableManager(
      $_db,
      $_db.indicators,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_indicatorsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RrSamplesTable, List<RrSample>>
  _rrSamplesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rrSamples,
    aliasName: $_aliasNameGenerator(db.sessions.id, db.rrSamples.sessionId),
  );

  $$RrSamplesTableProcessedTableManager get rrSamplesRefs {
    final manager = $$RrSamplesTableTableManager(
      $_db,
      $_db.rrSamples,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_rrSamplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $HooperMackinnonEntriesTable,
    List<HooperMackinnonEntry>
  >
  _hooperMackinnonEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.hooperMackinnonEntries,
        aliasName: $_aliasNameGenerator(
          db.sessions.id,
          db.hooperMackinnonEntries.sessionId,
        ),
      );

  $$HooperMackinnonEntriesTableProcessedTableManager
  get hooperMackinnonEntriesRefs {
    final manager = $$HooperMackinnonEntriesTableTableManager(
      $_db,
      $_db.hooperMackinnonEntries,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _hooperMackinnonEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qualityRatio => $composableBuilder(
    column: $table.qualityRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rpePhysical => $composableBuilder(
    column: $table.rpePhysical,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> indicatorsRefs(
    Expression<bool> Function($$IndicatorsTableFilterComposer f) f,
  ) {
    final $$IndicatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.indicators,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IndicatorsTableFilterComposer(
            $db: $db,
            $table: $db.indicators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rrSamplesRefs(
    Expression<bool> Function($$RrSamplesTableFilterComposer f) f,
  ) {
    final $$RrSamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rrSamples,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RrSamplesTableFilterComposer(
            $db: $db,
            $table: $db.rrSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> hooperMackinnonEntriesRefs(
    Expression<bool> Function($$HooperMackinnonEntriesTableFilterComposer f) f,
  ) {
    final $$HooperMackinnonEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.hooperMackinnonEntries,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$HooperMackinnonEntriesTableFilterComposer(
                $db: $db,
                $table: $db.hooperMackinnonEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qualityRatio => $composableBuilder(
    column: $table.qualityRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rpePhysical => $composableBuilder(
    column: $table.rpePhysical,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<double> get qualityRatio => $composableBuilder(
    column: $table.qualityRatio,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rpePhysical => $composableBuilder(
    column: $table.rpePhysical,
    builder: (column) => column,
  );

  Expression<T> indicatorsRefs<T extends Object>(
    Expression<T> Function($$IndicatorsTableAnnotationComposer a) f,
  ) {
    final $$IndicatorsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.indicators,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IndicatorsTableAnnotationComposer(
            $db: $db,
            $table: $db.indicators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rrSamplesRefs<T extends Object>(
    Expression<T> Function($$RrSamplesTableAnnotationComposer a) f,
  ) {
    final $$RrSamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rrSamples,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RrSamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.rrSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> hooperMackinnonEntriesRefs<T extends Object>(
    Expression<T> Function($$HooperMackinnonEntriesTableAnnotationComposer a) f,
  ) {
    final $$HooperMackinnonEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.hooperMackinnonEntries,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$HooperMackinnonEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.hooperMackinnonEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({
            bool indicatorsRefs,
            bool rrSamplesRefs,
            bool hooperMackinnonEntriesRefs,
          })
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double> qualityRatio = const Value.absent(),
                Value<int?> rpePhysical = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                userId: userId,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                qualityRatio: qualityRatio,
                rpePhysical: rpePhysical,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String mode,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<double> qualityRatio = const Value.absent(),
                Value<int?> rpePhysical = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                userId: userId,
                mode: mode,
                startedAt: startedAt,
                endedAt: endedAt,
                qualityRatio: qualityRatio,
                rpePhysical: rpePhysical,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                indicatorsRefs = false,
                rrSamplesRefs = false,
                hooperMackinnonEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (indicatorsRefs) db.indicators,
                    if (rrSamplesRefs) db.rrSamples,
                    if (hooperMackinnonEntriesRefs) db.hooperMackinnonEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (indicatorsRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          Indicator
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._indicatorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).indicatorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (rrSamplesRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          RrSample
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._rrSamplesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).rrSamplesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (hooperMackinnonEntriesRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          HooperMackinnonEntry
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._hooperMackinnonEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).hooperMackinnonEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({
        bool indicatorsRefs,
        bool rrSamplesRefs,
        bool hooperMackinnonEntriesRefs,
      })
    >;
typedef $$IndicatorsTableCreateCompanionBuilder =
    IndicatorsCompanion Function({
      Value<int> id,
      required int sessionId,
      required String kind,
      required double value,
      required DateTime at,
    });
typedef $$IndicatorsTableUpdateCompanionBuilder =
    IndicatorsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> kind,
      Value<double> value,
      Value<DateTime> at,
    });

final class $$IndicatorsTableReferences
    extends BaseReferences<_$AppDatabase, $IndicatorsTable, Indicator> {
  $$IndicatorsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.indicators.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IndicatorsTableFilterComposer
    extends Composer<_$AppDatabase, $IndicatorsTable> {
  $$IndicatorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IndicatorsTableOrderingComposer
    extends Composer<_$AppDatabase, $IndicatorsTable> {
  $$IndicatorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IndicatorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IndicatorsTable> {
  $$IndicatorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IndicatorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IndicatorsTable,
          Indicator,
          $$IndicatorsTableFilterComposer,
          $$IndicatorsTableOrderingComposer,
          $$IndicatorsTableAnnotationComposer,
          $$IndicatorsTableCreateCompanionBuilder,
          $$IndicatorsTableUpdateCompanionBuilder,
          (Indicator, $$IndicatorsTableReferences),
          Indicator,
          PrefetchHooks Function({bool sessionId})
        > {
  $$IndicatorsTableTableManager(_$AppDatabase db, $IndicatorsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IndicatorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IndicatorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IndicatorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => IndicatorsCompanion(
                id: id,
                sessionId: sessionId,
                kind: kind,
                value: value,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String kind,
                required double value,
                required DateTime at,
              }) => IndicatorsCompanion.insert(
                id: id,
                sessionId: sessionId,
                kind: kind,
                value: value,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IndicatorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$IndicatorsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$IndicatorsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IndicatorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IndicatorsTable,
      Indicator,
      $$IndicatorsTableFilterComposer,
      $$IndicatorsTableOrderingComposer,
      $$IndicatorsTableAnnotationComposer,
      $$IndicatorsTableCreateCompanionBuilder,
      $$IndicatorsTableUpdateCompanionBuilder,
      (Indicator, $$IndicatorsTableReferences),
      Indicator,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$RrSamplesTableCreateCompanionBuilder =
    RrSamplesCompanion Function({
      required int sessionId,
      required int tMs,
      required double rr,
      Value<bool> gap,
      Value<int> rowid,
    });
typedef $$RrSamplesTableUpdateCompanionBuilder =
    RrSamplesCompanion Function({
      Value<int> sessionId,
      Value<int> tMs,
      Value<double> rr,
      Value<bool> gap,
      Value<int> rowid,
    });

final class $$RrSamplesTableReferences
    extends BaseReferences<_$AppDatabase, $RrSamplesTable, RrSample> {
  $$RrSamplesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.rrSamples.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RrSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $RrSamplesTable> {
  $$RrSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rr => $composableBuilder(
    column: $table.rr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get gap => $composableBuilder(
    column: $table.gap,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RrSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $RrSamplesTable> {
  $$RrSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tMs => $composableBuilder(
    column: $table.tMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rr => $composableBuilder(
    column: $table.rr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get gap => $composableBuilder(
    column: $table.gap,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RrSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RrSamplesTable> {
  $$RrSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tMs =>
      $composableBuilder(column: $table.tMs, builder: (column) => column);

  GeneratedColumn<double> get rr =>
      $composableBuilder(column: $table.rr, builder: (column) => column);

  GeneratedColumn<bool> get gap =>
      $composableBuilder(column: $table.gap, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RrSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RrSamplesTable,
          RrSample,
          $$RrSamplesTableFilterComposer,
          $$RrSamplesTableOrderingComposer,
          $$RrSamplesTableAnnotationComposer,
          $$RrSamplesTableCreateCompanionBuilder,
          $$RrSamplesTableUpdateCompanionBuilder,
          (RrSample, $$RrSamplesTableReferences),
          RrSample,
          PrefetchHooks Function({bool sessionId})
        > {
  $$RrSamplesTableTableManager(_$AppDatabase db, $RrSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RrSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RrSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RrSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<int> tMs = const Value.absent(),
                Value<double> rr = const Value.absent(),
                Value<bool> gap = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RrSamplesCompanion(
                sessionId: sessionId,
                tMs: tMs,
                rr: rr,
                gap: gap,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required int tMs,
                required double rr,
                Value<bool> gap = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RrSamplesCompanion.insert(
                sessionId: sessionId,
                tMs: tMs,
                rr: rr,
                gap: gap,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RrSamplesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$RrSamplesTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$RrSamplesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RrSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RrSamplesTable,
      RrSample,
      $$RrSamplesTableFilterComposer,
      $$RrSamplesTableOrderingComposer,
      $$RrSamplesTableAnnotationComposer,
      $$RrSamplesTableCreateCompanionBuilder,
      $$RrSamplesTableUpdateCompanionBuilder,
      (RrSample, $$RrSamplesTableReferences),
      RrSample,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$ConsentLogTableCreateCompanionBuilder =
    ConsentLogCompanion Function({
      Value<int> id,
      required String userId,
      required String route,
      required DateTime acceptedAt,
      required String appVersion,
      required String consentVersion,
    });
typedef $$ConsentLogTableUpdateCompanionBuilder =
    ConsentLogCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> route,
      Value<DateTime> acceptedAt,
      Value<String> appVersion,
      Value<String> consentVersion,
    });

class $$ConsentLogTableFilterComposer
    extends Composer<_$AppDatabase, $ConsentLogTable> {
  $$ConsentLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get route => $composableBuilder(
    column: $table.route,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consentVersion => $composableBuilder(
    column: $table.consentVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConsentLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsentLogTable> {
  $$ConsentLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get route => $composableBuilder(
    column: $table.route,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consentVersion => $composableBuilder(
    column: $table.consentVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConsentLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsentLogTable> {
  $$ConsentLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get route =>
      $composableBuilder(column: $table.route, builder: (column) => column);

  GeneratedColumn<DateTime> get acceptedAt => $composableBuilder(
    column: $table.acceptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get consentVersion => $composableBuilder(
    column: $table.consentVersion,
    builder: (column) => column,
  );
}

class $$ConsentLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConsentLogTable,
          ConsentLogData,
          $$ConsentLogTableFilterComposer,
          $$ConsentLogTableOrderingComposer,
          $$ConsentLogTableAnnotationComposer,
          $$ConsentLogTableCreateCompanionBuilder,
          $$ConsentLogTableUpdateCompanionBuilder,
          (
            ConsentLogData,
            BaseReferences<_$AppDatabase, $ConsentLogTable, ConsentLogData>,
          ),
          ConsentLogData,
          PrefetchHooks Function()
        > {
  $$ConsentLogTableTableManager(_$AppDatabase db, $ConsentLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsentLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsentLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsentLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> route = const Value.absent(),
                Value<DateTime> acceptedAt = const Value.absent(),
                Value<String> appVersion = const Value.absent(),
                Value<String> consentVersion = const Value.absent(),
              }) => ConsentLogCompanion(
                id: id,
                userId: userId,
                route: route,
                acceptedAt: acceptedAt,
                appVersion: appVersion,
                consentVersion: consentVersion,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String route,
                required DateTime acceptedAt,
                required String appVersion,
                required String consentVersion,
              }) => ConsentLogCompanion.insert(
                id: id,
                userId: userId,
                route: route,
                acceptedAt: acceptedAt,
                appVersion: appVersion,
                consentVersion: consentVersion,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConsentLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConsentLogTable,
      ConsentLogData,
      $$ConsentLogTableFilterComposer,
      $$ConsentLogTableOrderingComposer,
      $$ConsentLogTableAnnotationComposer,
      $$ConsentLogTableCreateCompanionBuilder,
      $$ConsentLogTableUpdateCompanionBuilder,
      (
        ConsentLogData,
        BaseReferences<_$AppDatabase, $ConsentLogTable, ConsentLogData>,
      ),
      ConsentLogData,
      PrefetchHooks Function()
    >;
typedef $$ProfileTableCreateCompanionBuilder =
    ProfileCompanion Function({
      required String userId,
      Value<int?> age,
      Value<String?> sex,
      Value<double?> weightKg,
      Value<double?> heightCm,
      Value<int?> hrRest,
      Value<String?> hrRestSource,
      Value<int?> hrMax,
      Value<String?> hrMaxSource,
      Value<int?> fcSv1,
      Value<int?> fcSv2,
      Value<String?> thresholdProvenance,
      Value<int?> aerobicCeiling,
      Value<double?> baselineRmssd,
      Value<DateTime?> baselineUpdatedAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProfileTableUpdateCompanionBuilder =
    ProfileCompanion Function({
      Value<String> userId,
      Value<int?> age,
      Value<String?> sex,
      Value<double?> weightKg,
      Value<double?> heightCm,
      Value<int?> hrRest,
      Value<String?> hrRestSource,
      Value<int?> hrMax,
      Value<String?> hrMaxSource,
      Value<int?> fcSv1,
      Value<int?> fcSv2,
      Value<String?> thresholdProvenance,
      Value<int?> aerobicCeiling,
      Value<double?> baselineRmssd,
      Value<DateTime?> baselineUpdatedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProfileTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileTable> {
  $$ProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrRest => $composableBuilder(
    column: $table.hrRest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hrRestSource => $composableBuilder(
    column: $table.hrRestSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hrMax => $composableBuilder(
    column: $table.hrMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hrMaxSource => $composableBuilder(
    column: $table.hrMaxSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fcSv1 => $composableBuilder(
    column: $table.fcSv1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fcSv2 => $composableBuilder(
    column: $table.fcSv2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thresholdProvenance => $composableBuilder(
    column: $table.thresholdProvenance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aerobicCeiling => $composableBuilder(
    column: $table.aerobicCeiling,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baselineRmssd => $composableBuilder(
    column: $table.baselineRmssd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get baselineUpdatedAt => $composableBuilder(
    column: $table.baselineUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileTable> {
  $$ProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrRest => $composableBuilder(
    column: $table.hrRest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hrRestSource => $composableBuilder(
    column: $table.hrRestSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hrMax => $composableBuilder(
    column: $table.hrMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hrMaxSource => $composableBuilder(
    column: $table.hrMaxSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fcSv1 => $composableBuilder(
    column: $table.fcSv1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fcSv2 => $composableBuilder(
    column: $table.fcSv2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thresholdProvenance => $composableBuilder(
    column: $table.thresholdProvenance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aerobicCeiling => $composableBuilder(
    column: $table.aerobicCeiling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baselineRmssd => $composableBuilder(
    column: $table.baselineRmssd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get baselineUpdatedAt => $composableBuilder(
    column: $table.baselineUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileTable> {
  $$ProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<int> get hrRest =>
      $composableBuilder(column: $table.hrRest, builder: (column) => column);

  GeneratedColumn<String> get hrRestSource => $composableBuilder(
    column: $table.hrRestSource,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hrMax =>
      $composableBuilder(column: $table.hrMax, builder: (column) => column);

  GeneratedColumn<String> get hrMaxSource => $composableBuilder(
    column: $table.hrMaxSource,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fcSv1 =>
      $composableBuilder(column: $table.fcSv1, builder: (column) => column);

  GeneratedColumn<int> get fcSv2 =>
      $composableBuilder(column: $table.fcSv2, builder: (column) => column);

  GeneratedColumn<String> get thresholdProvenance => $composableBuilder(
    column: $table.thresholdProvenance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get aerobicCeiling => $composableBuilder(
    column: $table.aerobicCeiling,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baselineRmssd => $composableBuilder(
    column: $table.baselineRmssd,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get baselineUpdatedAt => $composableBuilder(
    column: $table.baselineUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileTable,
          ProfileData,
          $$ProfileTableFilterComposer,
          $$ProfileTableOrderingComposer,
          $$ProfileTableAnnotationComposer,
          $$ProfileTableCreateCompanionBuilder,
          $$ProfileTableUpdateCompanionBuilder,
          (
            ProfileData,
            BaseReferences<_$AppDatabase, $ProfileTable, ProfileData>,
          ),
          ProfileData,
          PrefetchHooks Function()
        > {
  $$ProfileTableTableManager(_$AppDatabase db, $ProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<int?> age = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<int?> hrRest = const Value.absent(),
                Value<String?> hrRestSource = const Value.absent(),
                Value<int?> hrMax = const Value.absent(),
                Value<String?> hrMaxSource = const Value.absent(),
                Value<int?> fcSv1 = const Value.absent(),
                Value<int?> fcSv2 = const Value.absent(),
                Value<String?> thresholdProvenance = const Value.absent(),
                Value<int?> aerobicCeiling = const Value.absent(),
                Value<double?> baselineRmssd = const Value.absent(),
                Value<DateTime?> baselineUpdatedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileCompanion(
                userId: userId,
                age: age,
                sex: sex,
                weightKg: weightKg,
                heightCm: heightCm,
                hrRest: hrRest,
                hrRestSource: hrRestSource,
                hrMax: hrMax,
                hrMaxSource: hrMaxSource,
                fcSv1: fcSv1,
                fcSv2: fcSv2,
                thresholdProvenance: thresholdProvenance,
                aerobicCeiling: aerobicCeiling,
                baselineRmssd: baselineRmssd,
                baselineUpdatedAt: baselineUpdatedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<int?> age = const Value.absent(),
                Value<String?> sex = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<int?> hrRest = const Value.absent(),
                Value<String?> hrRestSource = const Value.absent(),
                Value<int?> hrMax = const Value.absent(),
                Value<String?> hrMaxSource = const Value.absent(),
                Value<int?> fcSv1 = const Value.absent(),
                Value<int?> fcSv2 = const Value.absent(),
                Value<String?> thresholdProvenance = const Value.absent(),
                Value<int?> aerobicCeiling = const Value.absent(),
                Value<double?> baselineRmssd = const Value.absent(),
                Value<DateTime?> baselineUpdatedAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProfileCompanion.insert(
                userId: userId,
                age: age,
                sex: sex,
                weightKg: weightKg,
                heightCm: heightCm,
                hrRest: hrRest,
                hrRestSource: hrRestSource,
                hrMax: hrMax,
                hrMaxSource: hrMaxSource,
                fcSv1: fcSv1,
                fcSv2: fcSv2,
                thresholdProvenance: thresholdProvenance,
                aerobicCeiling: aerobicCeiling,
                baselineRmssd: baselineRmssd,
                baselineUpdatedAt: baselineUpdatedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileTable,
      ProfileData,
      $$ProfileTableFilterComposer,
      $$ProfileTableOrderingComposer,
      $$ProfileTableAnnotationComposer,
      $$ProfileTableCreateCompanionBuilder,
      $$ProfileTableUpdateCompanionBuilder,
      (ProfileData, BaseReferences<_$AppDatabase, $ProfileTable, ProfileData>),
      ProfileData,
      PrefetchHooks Function()
    >;
typedef $$DailyEntriesTableCreateCompanionBuilder =
    DailyEntriesCompanion Function({
      required String userId,
      required DateTime day,
      Value<int?> rpePsychological,
      Value<int?> rpeComparison,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DailyEntriesTableUpdateCompanionBuilder =
    DailyEntriesCompanion Function({
      Value<String> userId,
      Value<DateTime> day,
      Value<int?> rpePsychological,
      Value<int?> rpeComparison,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DailyEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyEntriesTable> {
  $$DailyEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rpePsychological => $composableBuilder(
    column: $table.rpePsychological,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rpeComparison => $composableBuilder(
    column: $table.rpeComparison,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyEntriesTable> {
  $$DailyEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rpePsychological => $composableBuilder(
    column: $table.rpePsychological,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rpeComparison => $composableBuilder(
    column: $table.rpeComparison,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyEntriesTable> {
  $$DailyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get rpePsychological => $composableBuilder(
    column: $table.rpePsychological,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rpeComparison => $composableBuilder(
    column: $table.rpeComparison,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DailyEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyEntriesTable,
          DailyEntry,
          $$DailyEntriesTableFilterComposer,
          $$DailyEntriesTableOrderingComposer,
          $$DailyEntriesTableAnnotationComposer,
          $$DailyEntriesTableCreateCompanionBuilder,
          $$DailyEntriesTableUpdateCompanionBuilder,
          (
            DailyEntry,
            BaseReferences<_$AppDatabase, $DailyEntriesTable, DailyEntry>,
          ),
          DailyEntry,
          PrefetchHooks Function()
        > {
  $$DailyEntriesTableTableManager(_$AppDatabase db, $DailyEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int?> rpePsychological = const Value.absent(),
                Value<int?> rpeComparison = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyEntriesCompanion(
                userId: userId,
                day: day,
                rpePsychological: rpePsychological,
                rpeComparison: rpeComparison,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required DateTime day,
                Value<int?> rpePsychological = const Value.absent(),
                Value<int?> rpeComparison = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyEntriesCompanion.insert(
                userId: userId,
                day: day,
                rpePsychological: rpePsychological,
                rpeComparison: rpeComparison,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyEntriesTable,
      DailyEntry,
      $$DailyEntriesTableFilterComposer,
      $$DailyEntriesTableOrderingComposer,
      $$DailyEntriesTableAnnotationComposer,
      $$DailyEntriesTableCreateCompanionBuilder,
      $$DailyEntriesTableUpdateCompanionBuilder,
      (
        DailyEntry,
        BaseReferences<_$AppDatabase, $DailyEntriesTable, DailyEntry>,
      ),
      DailyEntry,
      PrefetchHooks Function()
    >;
typedef $$HooperMackinnonEntriesTableCreateCompanionBuilder =
    HooperMackinnonEntriesCompanion Function({
      Value<int> id,
      required int sessionId,
      required String userId,
      required int fatigue,
      required int stress,
      required int doms,
      required int sleep,
      required DateTime recordedAt,
    });
typedef $$HooperMackinnonEntriesTableUpdateCompanionBuilder =
    HooperMackinnonEntriesCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String> userId,
      Value<int> fatigue,
      Value<int> stress,
      Value<int> doms,
      Value<int> sleep,
      Value<DateTime> recordedAt,
    });

final class $$HooperMackinnonEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $HooperMackinnonEntriesTable,
          HooperMackinnonEntry
        > {
  $$HooperMackinnonEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(
          db.hooperMackinnonEntries.sessionId,
          db.sessions.id,
        ),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HooperMackinnonEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HooperMackinnonEntriesTable> {
  $$HooperMackinnonEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fatigue => $composableBuilder(
    column: $table.fatigue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stress => $composableBuilder(
    column: $table.stress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get doms => $composableBuilder(
    column: $table.doms,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleep => $composableBuilder(
    column: $table.sleep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HooperMackinnonEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HooperMackinnonEntriesTable> {
  $$HooperMackinnonEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fatigue => $composableBuilder(
    column: $table.fatigue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stress => $composableBuilder(
    column: $table.stress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get doms => $composableBuilder(
    column: $table.doms,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleep => $composableBuilder(
    column: $table.sleep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HooperMackinnonEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HooperMackinnonEntriesTable> {
  $$HooperMackinnonEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get fatigue =>
      $composableBuilder(column: $table.fatigue, builder: (column) => column);

  GeneratedColumn<int> get stress =>
      $composableBuilder(column: $table.stress, builder: (column) => column);

  GeneratedColumn<int> get doms =>
      $composableBuilder(column: $table.doms, builder: (column) => column);

  GeneratedColumn<int> get sleep =>
      $composableBuilder(column: $table.sleep, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HooperMackinnonEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HooperMackinnonEntriesTable,
          HooperMackinnonEntry,
          $$HooperMackinnonEntriesTableFilterComposer,
          $$HooperMackinnonEntriesTableOrderingComposer,
          $$HooperMackinnonEntriesTableAnnotationComposer,
          $$HooperMackinnonEntriesTableCreateCompanionBuilder,
          $$HooperMackinnonEntriesTableUpdateCompanionBuilder,
          (HooperMackinnonEntry, $$HooperMackinnonEntriesTableReferences),
          HooperMackinnonEntry,
          PrefetchHooks Function({bool sessionId})
        > {
  $$HooperMackinnonEntriesTableTableManager(
    _$AppDatabase db,
    $HooperMackinnonEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HooperMackinnonEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$HooperMackinnonEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$HooperMackinnonEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> fatigue = const Value.absent(),
                Value<int> stress = const Value.absent(),
                Value<int> doms = const Value.absent(),
                Value<int> sleep = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
              }) => HooperMackinnonEntriesCompanion(
                id: id,
                sessionId: sessionId,
                userId: userId,
                fatigue: fatigue,
                stress: stress,
                doms: doms,
                sleep: sleep,
                recordedAt: recordedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required String userId,
                required int fatigue,
                required int stress,
                required int doms,
                required int sleep,
                required DateTime recordedAt,
              }) => HooperMackinnonEntriesCompanion.insert(
                id: id,
                sessionId: sessionId,
                userId: userId,
                fatigue: fatigue,
                stress: stress,
                doms: doms,
                sleep: sleep,
                recordedAt: recordedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HooperMackinnonEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$HooperMackinnonEntriesTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$HooperMackinnonEntriesTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HooperMackinnonEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HooperMackinnonEntriesTable,
      HooperMackinnonEntry,
      $$HooperMackinnonEntriesTableFilterComposer,
      $$HooperMackinnonEntriesTableOrderingComposer,
      $$HooperMackinnonEntriesTableAnnotationComposer,
      $$HooperMackinnonEntriesTableCreateCompanionBuilder,
      $$HooperMackinnonEntriesTableUpdateCompanionBuilder,
      (HooperMackinnonEntry, $$HooperMackinnonEntriesTableReferences),
      HooperMackinnonEntry,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$IndicatorsTableTableManager get indicators =>
      $$IndicatorsTableTableManager(_db, _db.indicators);
  $$RrSamplesTableTableManager get rrSamples =>
      $$RrSamplesTableTableManager(_db, _db.rrSamples);
  $$ConsentLogTableTableManager get consentLog =>
      $$ConsentLogTableTableManager(_db, _db.consentLog);
  $$ProfileTableTableManager get profile =>
      $$ProfileTableTableManager(_db, _db.profile);
  $$DailyEntriesTableTableManager get dailyEntries =>
      $$DailyEntriesTableTableManager(_db, _db.dailyEntries);
  $$HooperMackinnonEntriesTableTableManager get hooperMackinnonEntries =>
      $$HooperMackinnonEntriesTableTableManager(
        _db,
        _db.hooperMackinnonEntries,
      );
}
