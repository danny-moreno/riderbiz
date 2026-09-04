// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riderbiz_database.dart';

// ignore_for_file: type=lint
class $LogisticsOperatorsTable extends LogisticsOperators
    with TableInfo<$LogisticsOperatorsTable, LogisticsOperator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogisticsOperatorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'logistics_operators';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogisticsOperator> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogisticsOperator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogisticsOperator(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $LogisticsOperatorsTable createAlias(String alias) {
    return $LogisticsOperatorsTable(attachedDatabase, alias);
  }
}

class LogisticsOperator extends DataClass
    implements Insertable<LogisticsOperator> {
  final String id;
  final String name;
  final DateTime createdAt;
  final bool isActive;
  const LogisticsOperator({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  LogisticsOperatorsCompanion toCompanion(bool nullToAbsent) {
    return LogisticsOperatorsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      isActive: Value(isActive),
    );
  }

  factory LogisticsOperator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogisticsOperator(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  LogisticsOperator copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    bool? isActive,
  }) => LogisticsOperator(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    isActive: isActive ?? this.isActive,
  );
  LogisticsOperator copyWithCompanion(LogisticsOperatorsCompanion data) {
    return LogisticsOperator(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogisticsOperator(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogisticsOperator &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.isActive == this.isActive);
}

class LogisticsOperatorsCompanion extends UpdateCompanion<LogisticsOperator> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<bool> isActive;
  final Value<int> rowid;
  const LogisticsOperatorsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LogisticsOperatorsCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<LogisticsOperator> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LogisticsOperatorsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return LogisticsOperatorsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogisticsOperatorsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperatorTariffsTable extends OperatorTariffs
    with TableInfo<$OperatorTariffsTable, OperatorTariff> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperatorTariffsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operatorIdMeta = const VerificationMeta(
    'operatorId',
  );
  @override
  late final GeneratedColumn<String> operatorId = GeneratedColumn<String>(
    'operator_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES logistics_operators (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMinorMeta = const VerificationMeta(
    'unitPriceMinor',
  );
  @override
  late final GeneratedColumn<int> unitPriceMinor = GeneratedColumn<int>(
    'unit_price_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (unit_price_minor >= 0)',
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validFromMeta = const VerificationMeta(
    'validFrom',
  );
  @override
  late final GeneratedColumn<DateTime> validFrom = GeneratedColumn<DateTime>(
    'valid_from',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _validUntilMeta = const VerificationMeta(
    'validUntil',
  );
  @override
  late final GeneratedColumn<DateTime> validUntil = GeneratedColumn<DateTime>(
    'valid_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operatorId,
    version,
    unitPriceMinor,
    currency,
    validFrom,
    validUntil,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operator_tariffs';
  @override
  VerificationContext validateIntegrity(
    Insertable<OperatorTariff> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operator_id')) {
      context.handle(
        _operatorIdMeta,
        operatorId.isAcceptableOrUnknown(data['operator_id']!, _operatorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_operatorIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('unit_price_minor')) {
      context.handle(
        _unitPriceMinorMeta,
        unitPriceMinor.isAcceptableOrUnknown(
          data['unit_price_minor']!,
          _unitPriceMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('valid_from')) {
      context.handle(
        _validFromMeta,
        validFrom.isAcceptableOrUnknown(data['valid_from']!, _validFromMeta),
      );
    } else if (isInserting) {
      context.missing(_validFromMeta);
    }
    if (data.containsKey('valid_until')) {
      context.handle(
        _validUntilMeta,
        validUntil.isAcceptableOrUnknown(data['valid_until']!, _validUntilMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {operatorId, version},
  ];
  @override
  OperatorTariff map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OperatorTariff(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      operatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      unitPriceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_minor'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      validFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_from'],
      )!,
      validUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valid_until'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OperatorTariffsTable createAlias(String alias) {
    return $OperatorTariffsTable(attachedDatabase, alias);
  }
}

class OperatorTariff extends DataClass implements Insertable<OperatorTariff> {
  final String id;
  final String operatorId;
  final int version;
  final int unitPriceMinor;
  final String currency;
  final DateTime validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final DateTime createdAt;
  const OperatorTariff({
    required this.id,
    required this.operatorId,
    required this.version,
    required this.unitPriceMinor,
    required this.currency,
    required this.validFrom,
    this.validUntil,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operator_id'] = Variable<String>(operatorId);
    map['version'] = Variable<int>(version);
    map['unit_price_minor'] = Variable<int>(unitPriceMinor);
    map['currency'] = Variable<String>(currency);
    map['valid_from'] = Variable<DateTime>(validFrom);
    if (!nullToAbsent || validUntil != null) {
      map['valid_until'] = Variable<DateTime>(validUntil);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OperatorTariffsCompanion toCompanion(bool nullToAbsent) {
    return OperatorTariffsCompanion(
      id: Value(id),
      operatorId: Value(operatorId),
      version: Value(version),
      unitPriceMinor: Value(unitPriceMinor),
      currency: Value(currency),
      validFrom: Value(validFrom),
      validUntil: validUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(validUntil),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory OperatorTariff.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OperatorTariff(
      id: serializer.fromJson<String>(json['id']),
      operatorId: serializer.fromJson<String>(json['operatorId']),
      version: serializer.fromJson<int>(json['version']),
      unitPriceMinor: serializer.fromJson<int>(json['unitPriceMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      validFrom: serializer.fromJson<DateTime>(json['validFrom']),
      validUntil: serializer.fromJson<DateTime?>(json['validUntil']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operatorId': serializer.toJson<String>(operatorId),
      'version': serializer.toJson<int>(version),
      'unitPriceMinor': serializer.toJson<int>(unitPriceMinor),
      'currency': serializer.toJson<String>(currency),
      'validFrom': serializer.toJson<DateTime>(validFrom),
      'validUntil': serializer.toJson<DateTime?>(validUntil),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OperatorTariff copyWith({
    String? id,
    String? operatorId,
    int? version,
    int? unitPriceMinor,
    String? currency,
    DateTime? validFrom,
    Value<DateTime?> validUntil = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
  }) => OperatorTariff(
    id: id ?? this.id,
    operatorId: operatorId ?? this.operatorId,
    version: version ?? this.version,
    unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
    currency: currency ?? this.currency,
    validFrom: validFrom ?? this.validFrom,
    validUntil: validUntil.present ? validUntil.value : this.validUntil,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  OperatorTariff copyWithCompanion(OperatorTariffsCompanion data) {
    return OperatorTariff(
      id: data.id.present ? data.id.value : this.id,
      operatorId: data.operatorId.present
          ? data.operatorId.value
          : this.operatorId,
      version: data.version.present ? data.version.value : this.version,
      unitPriceMinor: data.unitPriceMinor.present
          ? data.unitPriceMinor.value
          : this.unitPriceMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      validFrom: data.validFrom.present ? data.validFrom.value : this.validFrom,
      validUntil: data.validUntil.present
          ? data.validUntil.value
          : this.validUntil,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OperatorTariff(')
          ..write('id: $id, ')
          ..write('operatorId: $operatorId, ')
          ..write('version: $version, ')
          ..write('unitPriceMinor: $unitPriceMinor, ')
          ..write('currency: $currency, ')
          ..write('validFrom: $validFrom, ')
          ..write('validUntil: $validUntil, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operatorId,
    version,
    unitPriceMinor,
    currency,
    validFrom,
    validUntil,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OperatorTariff &&
          other.id == this.id &&
          other.operatorId == this.operatorId &&
          other.version == this.version &&
          other.unitPriceMinor == this.unitPriceMinor &&
          other.currency == this.currency &&
          other.validFrom == this.validFrom &&
          other.validUntil == this.validUntil &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class OperatorTariffsCompanion extends UpdateCompanion<OperatorTariff> {
  final Value<String> id;
  final Value<String> operatorId;
  final Value<int> version;
  final Value<int> unitPriceMinor;
  final Value<String> currency;
  final Value<DateTime> validFrom;
  final Value<DateTime?> validUntil;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OperatorTariffsCompanion({
    this.id = const Value.absent(),
    this.operatorId = const Value.absent(),
    this.version = const Value.absent(),
    this.unitPriceMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.validFrom = const Value.absent(),
    this.validUntil = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OperatorTariffsCompanion.insert({
    required String id,
    required String operatorId,
    required int version,
    required int unitPriceMinor,
    required String currency,
    required DateTime validFrom,
    this.validUntil = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       operatorId = Value(operatorId),
       version = Value(version),
       unitPriceMinor = Value(unitPriceMinor),
       currency = Value(currency),
       validFrom = Value(validFrom),
       createdAt = Value(createdAt);
  static Insertable<OperatorTariff> custom({
    Expression<String>? id,
    Expression<String>? operatorId,
    Expression<int>? version,
    Expression<int>? unitPriceMinor,
    Expression<String>? currency,
    Expression<DateTime>? validFrom,
    Expression<DateTime>? validUntil,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operatorId != null) 'operator_id': operatorId,
      if (version != null) 'version': version,
      if (unitPriceMinor != null) 'unit_price_minor': unitPriceMinor,
      if (currency != null) 'currency': currency,
      if (validFrom != null) 'valid_from': validFrom,
      if (validUntil != null) 'valid_until': validUntil,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OperatorTariffsCompanion copyWith({
    Value<String>? id,
    Value<String>? operatorId,
    Value<int>? version,
    Value<int>? unitPriceMinor,
    Value<String>? currency,
    Value<DateTime>? validFrom,
    Value<DateTime?>? validUntil,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return OperatorTariffsCompanion(
      id: id ?? this.id,
      operatorId: operatorId ?? this.operatorId,
      version: version ?? this.version,
      unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
      currency: currency ?? this.currency,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operatorId.present) {
      map['operator_id'] = Variable<String>(operatorId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (unitPriceMinor.present) {
      map['unit_price_minor'] = Variable<int>(unitPriceMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (validFrom.present) {
      map['valid_from'] = Variable<DateTime>(validFrom.value);
    }
    if (validUntil.present) {
      map['valid_until'] = Variable<DateTime>(validUntil.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperatorTariffsCompanion(')
          ..write('id: $id, ')
          ..write('operatorId: $operatorId, ')
          ..write('version: $version, ')
          ..write('unitPriceMinor: $unitPriceMinor, ')
          ..write('currency: $currency, ')
          ..write('validFrom: $validFrom, ')
          ..write('validUntil: $validUntil, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OperatorLabelProfilesTable extends OperatorLabelProfiles
    with TableInfo<$OperatorLabelProfilesTable, OperatorLabelProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OperatorLabelProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operatorIdMeta = const VerificationMeta(
    'operatorId',
  );
  @override
  late final GeneratedColumn<String> operatorId = GeneratedColumn<String>(
    'operator_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES logistics_operators (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _markerMeta = const VerificationMeta('marker');
  @override
  late final GeneratedColumn<String> marker = GeneratedColumn<String>(
    'marker',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operatorId,
    marker,
    priority,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operator_label_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<OperatorLabelProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operator_id')) {
      context.handle(
        _operatorIdMeta,
        operatorId.isAcceptableOrUnknown(data['operator_id']!, _operatorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_operatorIdMeta);
    }
    if (data.containsKey('marker')) {
      context.handle(
        _markerMeta,
        marker.isAcceptableOrUnknown(data['marker']!, _markerMeta),
      );
    } else if (isInserting) {
      context.missing(_markerMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OperatorLabelProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OperatorLabelProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      operatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_id'],
      )!,
      marker: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}marker'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OperatorLabelProfilesTable createAlias(String alias) {
    return $OperatorLabelProfilesTable(attachedDatabase, alias);
  }
}

class OperatorLabelProfile extends DataClass
    implements Insertable<OperatorLabelProfile> {
  final String id;
  final String operatorId;
  final String marker;
  final int priority;
  final bool isActive;
  final DateTime createdAt;
  const OperatorLabelProfile({
    required this.id,
    required this.operatorId,
    required this.marker,
    required this.priority,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operator_id'] = Variable<String>(operatorId);
    map['marker'] = Variable<String>(marker);
    map['priority'] = Variable<int>(priority);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OperatorLabelProfilesCompanion toCompanion(bool nullToAbsent) {
    return OperatorLabelProfilesCompanion(
      id: Value(id),
      operatorId: Value(operatorId),
      marker: Value(marker),
      priority: Value(priority),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory OperatorLabelProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OperatorLabelProfile(
      id: serializer.fromJson<String>(json['id']),
      operatorId: serializer.fromJson<String>(json['operatorId']),
      marker: serializer.fromJson<String>(json['marker']),
      priority: serializer.fromJson<int>(json['priority']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operatorId': serializer.toJson<String>(operatorId),
      'marker': serializer.toJson<String>(marker),
      'priority': serializer.toJson<int>(priority),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OperatorLabelProfile copyWith({
    String? id,
    String? operatorId,
    String? marker,
    int? priority,
    bool? isActive,
    DateTime? createdAt,
  }) => OperatorLabelProfile(
    id: id ?? this.id,
    operatorId: operatorId ?? this.operatorId,
    marker: marker ?? this.marker,
    priority: priority ?? this.priority,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  OperatorLabelProfile copyWithCompanion(OperatorLabelProfilesCompanion data) {
    return OperatorLabelProfile(
      id: data.id.present ? data.id.value : this.id,
      operatorId: data.operatorId.present
          ? data.operatorId.value
          : this.operatorId,
      marker: data.marker.present ? data.marker.value : this.marker,
      priority: data.priority.present ? data.priority.value : this.priority,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OperatorLabelProfile(')
          ..write('id: $id, ')
          ..write('operatorId: $operatorId, ')
          ..write('marker: $marker, ')
          ..write('priority: $priority, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, operatorId, marker, priority, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OperatorLabelProfile &&
          other.id == this.id &&
          other.operatorId == this.operatorId &&
          other.marker == this.marker &&
          other.priority == this.priority &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class OperatorLabelProfilesCompanion
    extends UpdateCompanion<OperatorLabelProfile> {
  final Value<String> id;
  final Value<String> operatorId;
  final Value<String> marker;
  final Value<int> priority;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OperatorLabelProfilesCompanion({
    this.id = const Value.absent(),
    this.operatorId = const Value.absent(),
    this.marker = const Value.absent(),
    this.priority = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OperatorLabelProfilesCompanion.insert({
    required String id,
    required String operatorId,
    required String marker,
    this.priority = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       operatorId = Value(operatorId),
       marker = Value(marker),
       createdAt = Value(createdAt);
  static Insertable<OperatorLabelProfile> custom({
    Expression<String>? id,
    Expression<String>? operatorId,
    Expression<String>? marker,
    Expression<int>? priority,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operatorId != null) 'operator_id': operatorId,
      if (marker != null) 'marker': marker,
      if (priority != null) 'priority': priority,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OperatorLabelProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? operatorId,
    Value<String>? marker,
    Value<int>? priority,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return OperatorLabelProfilesCompanion(
      id: id ?? this.id,
      operatorId: operatorId ?? this.operatorId,
      marker: marker ?? this.marker,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operatorId.present) {
      map['operator_id'] = Variable<String>(operatorId.value);
    }
    if (marker.present) {
      map['marker'] = Variable<String>(marker.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperatorLabelProfilesCompanion(')
          ..write('id: $id, ')
          ..write('operatorId: $operatorId, ')
          ..write('marker: $marker, ')
          ..write('priority: $priority, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeliveryRunsTable extends DeliveryRuns
    with TableInfo<$DeliveryRunsTable, DeliveryRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliveryRunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operatorIdMeta = const VerificationMeta(
    'operatorId',
  );
  @override
  late final GeneratedColumn<String> operatorId = GeneratedColumn<String>(
    'operator_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES logistics_operators (id) ON DELETE RESTRICT',
    ),
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
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, operatorId, startedAt, finishedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeliveryRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operator_id')) {
      context.handle(
        _operatorIdMeta,
        operatorId.isAcceptableOrUnknown(data['operator_id']!, _operatorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_operatorIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeliveryRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryRun(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      operatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operator_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
    );
  }

  @override
  $DeliveryRunsTable createAlias(String alias) {
    return $DeliveryRunsTable(attachedDatabase, alias);
  }
}

class DeliveryRun extends DataClass implements Insertable<DeliveryRun> {
  final String id;
  final String operatorId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  const DeliveryRun({
    required this.id,
    required this.operatorId,
    required this.startedAt,
    this.finishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operator_id'] = Variable<String>(operatorId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    return map;
  }

  DeliveryRunsCompanion toCompanion(bool nullToAbsent) {
    return DeliveryRunsCompanion(
      id: Value(id),
      operatorId: Value(operatorId),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
    );
  }

  factory DeliveryRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryRun(
      id: serializer.fromJson<String>(json['id']),
      operatorId: serializer.fromJson<String>(json['operatorId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operatorId': serializer.toJson<String>(operatorId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
    };
  }

  DeliveryRun copyWith({
    String? id,
    String? operatorId,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
  }) => DeliveryRun(
    id: id ?? this.id,
    operatorId: operatorId ?? this.operatorId,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
  );
  DeliveryRun copyWithCompanion(DeliveryRunsCompanion data) {
    return DeliveryRun(
      id: data.id.present ? data.id.value : this.id,
      operatorId: data.operatorId.present
          ? data.operatorId.value
          : this.operatorId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryRun(')
          ..write('id: $id, ')
          ..write('operatorId: $operatorId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, operatorId, startedAt, finishedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryRun &&
          other.id == this.id &&
          other.operatorId == this.operatorId &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt);
}

class DeliveryRunsCompanion extends UpdateCompanion<DeliveryRun> {
  final Value<String> id;
  final Value<String> operatorId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> rowid;
  const DeliveryRunsCompanion({
    this.id = const Value.absent(),
    this.operatorId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeliveryRunsCompanion.insert({
    required String id,
    required String operatorId,
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       operatorId = Value(operatorId),
       startedAt = Value(startedAt);
  static Insertable<DeliveryRun> custom({
    Expression<String>? id,
    Expression<String>? operatorId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operatorId != null) 'operator_id': operatorId,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeliveryRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? operatorId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? rowid,
  }) {
    return DeliveryRunsCompanion(
      id: id ?? this.id,
      operatorId: operatorId ?? this.operatorId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operatorId.present) {
      map['operator_id'] = Variable<String>(operatorId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryRunsCompanion(')
          ..write('id: $id, ')
          ..write('operatorId: $operatorId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyntheticPackagesTable extends SyntheticPackages
    with TableInfo<$SyntheticPackagesTable, SyntheticPackage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyntheticPackagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveryRunIdMeta = const VerificationMeta(
    'deliveryRunId',
  );
  @override
  late final GeneratedColumn<String> deliveryRunId = GeneratedColumn<String>(
    'delivery_run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES delivery_runs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'pending\' CHECK (status IN (\'pending\', \'delivered\', \'failed\'))',
    defaultValue: const CustomExpression('\'pending\''),
  );
  static const VerificationMeta _externalReferenceMeta = const VerificationMeta(
    'externalReference',
  );
  @override
  late final GeneratedColumn<String> externalReference =
      GeneratedColumn<String>(
        'external_reference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _identifiedOperatorIdMeta =
      const VerificationMeta('identifiedOperatorId');
  @override
  late final GeneratedColumn<String> identifiedOperatorId =
      GeneratedColumn<String>(
        'identified_operator_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES logistics_operators (id) ON DELETE RESTRICT',
        ),
      );
  static const VerificationMeta _identificationStatusMeta =
      const VerificationMeta('identificationStatus');
  @override
  late final GeneratedColumn<String> identificationStatus =
      GeneratedColumn<String>(
        'identification_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT \'unknown\' CHECK (identification_status IN (\'identified\', \'low_confidence\', \'unknown\', \'manual\'))',
        defaultValue: const CustomExpression('\'unknown\''),
      );
  static const VerificationMeta _identificationConfidenceMeta =
      const VerificationMeta('identificationConfidence');
  @override
  late final GeneratedColumn<double> identificationConfidence =
      GeneratedColumn<double>(
        'identification_confidence',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _tariffIdMeta = const VerificationMeta(
    'tariffId',
  );
  @override
  late final GeneratedColumn<String> tariffId = GeneratedColumn<String>(
    'tariff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES operator_tariffs (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _tariffVersionSnapshotMeta =
      const VerificationMeta('tariffVersionSnapshot');
  @override
  late final GeneratedColumn<int> tariffVersionSnapshot = GeneratedColumn<int>(
    'tariff_version_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPriceMinorSnapshotMeta =
      const VerificationMeta('unitPriceMinorSnapshot');
  @override
  late final GeneratedColumn<int> unitPriceMinorSnapshot = GeneratedColumn<int>(
    'unit_price_minor_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencySnapshotMeta = const VerificationMeta(
    'currencySnapshot',
  );
  @override
  late final GeneratedColumn<String> currencySnapshot = GeneratedColumn<String>(
    'currency_snapshot',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 3,
      maxTextLength: 3,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deliveredAtMeta = const VerificationMeta(
    'deliveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> deliveredAt = GeneratedColumn<DateTime>(
    'delivered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
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
  static const VerificationMeta _needsSyncMeta = const VerificationMeta(
    'needsSync',
  );
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
    'needs_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deliveryRunId,
    status,
    externalReference,
    identifiedOperatorId,
    identificationStatus,
    identificationConfidence,
    tariffId,
    tariffVersionSnapshot,
    unitPriceMinorSnapshot,
    currencySnapshot,
    deliveredAt,
    createdAt,
    updatedAt,
    needsSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'synthetic_packages';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyntheticPackage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('delivery_run_id')) {
      context.handle(
        _deliveryRunIdMeta,
        deliveryRunId.isAcceptableOrUnknown(
          data['delivery_run_id']!,
          _deliveryRunIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deliveryRunIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('external_reference')) {
      context.handle(
        _externalReferenceMeta,
        externalReference.isAcceptableOrUnknown(
          data['external_reference']!,
          _externalReferenceMeta,
        ),
      );
    }
    if (data.containsKey('identified_operator_id')) {
      context.handle(
        _identifiedOperatorIdMeta,
        identifiedOperatorId.isAcceptableOrUnknown(
          data['identified_operator_id']!,
          _identifiedOperatorIdMeta,
        ),
      );
    }
    if (data.containsKey('identification_status')) {
      context.handle(
        _identificationStatusMeta,
        identificationStatus.isAcceptableOrUnknown(
          data['identification_status']!,
          _identificationStatusMeta,
        ),
      );
    }
    if (data.containsKey('identification_confidence')) {
      context.handle(
        _identificationConfidenceMeta,
        identificationConfidence.isAcceptableOrUnknown(
          data['identification_confidence']!,
          _identificationConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('tariff_id')) {
      context.handle(
        _tariffIdMeta,
        tariffId.isAcceptableOrUnknown(data['tariff_id']!, _tariffIdMeta),
      );
    }
    if (data.containsKey('tariff_version_snapshot')) {
      context.handle(
        _tariffVersionSnapshotMeta,
        tariffVersionSnapshot.isAcceptableOrUnknown(
          data['tariff_version_snapshot']!,
          _tariffVersionSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('unit_price_minor_snapshot')) {
      context.handle(
        _unitPriceMinorSnapshotMeta,
        unitPriceMinorSnapshot.isAcceptableOrUnknown(
          data['unit_price_minor_snapshot']!,
          _unitPriceMinorSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('currency_snapshot')) {
      context.handle(
        _currencySnapshotMeta,
        currencySnapshot.isAcceptableOrUnknown(
          data['currency_snapshot']!,
          _currencySnapshotMeta,
        ),
      );
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
        _deliveredAtMeta,
        deliveredAt.isAcceptableOrUnknown(
          data['delivered_at']!,
          _deliveredAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('needs_sync')) {
      context.handle(
        _needsSyncMeta,
        needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyntheticPackage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyntheticPackage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deliveryRunId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delivery_run_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      externalReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_reference'],
      ),
      identifiedOperatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identified_operator_id'],
      ),
      identificationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identification_status'],
      )!,
      identificationConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}identification_confidence'],
      ),
      tariffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tariff_id'],
      ),
      tariffVersionSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tariff_version_snapshot'],
      ),
      unitPriceMinorSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_minor_snapshot'],
      ),
      currencySnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_snapshot'],
      ),
      deliveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}delivered_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      needsSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_sync'],
      )!,
    );
  }

  @override
  $SyntheticPackagesTable createAlias(String alias) {
    return $SyntheticPackagesTable(attachedDatabase, alias);
  }
}

class SyntheticPackage extends DataClass
    implements Insertable<SyntheticPackage> {
  final String id;
  final String deliveryRunId;
  final String status;
  final String? externalReference;
  final String? identifiedOperatorId;
  final String identificationStatus;
  final double? identificationConfidence;
  final String? tariffId;
  final int? tariffVersionSnapshot;
  final int? unitPriceMinorSnapshot;
  final String? currencySnapshot;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;
  const SyntheticPackage({
    required this.id,
    required this.deliveryRunId,
    required this.status,
    this.externalReference,
    this.identifiedOperatorId,
    required this.identificationStatus,
    this.identificationConfidence,
    this.tariffId,
    this.tariffVersionSnapshot,
    this.unitPriceMinorSnapshot,
    this.currencySnapshot,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['delivery_run_id'] = Variable<String>(deliveryRunId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || externalReference != null) {
      map['external_reference'] = Variable<String>(externalReference);
    }
    if (!nullToAbsent || identifiedOperatorId != null) {
      map['identified_operator_id'] = Variable<String>(identifiedOperatorId);
    }
    map['identification_status'] = Variable<String>(identificationStatus);
    if (!nullToAbsent || identificationConfidence != null) {
      map['identification_confidence'] = Variable<double>(
        identificationConfidence,
      );
    }
    if (!nullToAbsent || tariffId != null) {
      map['tariff_id'] = Variable<String>(tariffId);
    }
    if (!nullToAbsent || tariffVersionSnapshot != null) {
      map['tariff_version_snapshot'] = Variable<int>(tariffVersionSnapshot);
    }
    if (!nullToAbsent || unitPriceMinorSnapshot != null) {
      map['unit_price_minor_snapshot'] = Variable<int>(unitPriceMinorSnapshot);
    }
    if (!nullToAbsent || currencySnapshot != null) {
      map['currency_snapshot'] = Variable<String>(currencySnapshot);
    }
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  SyntheticPackagesCompanion toCompanion(bool nullToAbsent) {
    return SyntheticPackagesCompanion(
      id: Value(id),
      deliveryRunId: Value(deliveryRunId),
      status: Value(status),
      externalReference: externalReference == null && nullToAbsent
          ? const Value.absent()
          : Value(externalReference),
      identifiedOperatorId: identifiedOperatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(identifiedOperatorId),
      identificationStatus: Value(identificationStatus),
      identificationConfidence: identificationConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(identificationConfidence),
      tariffId: tariffId == null && nullToAbsent
          ? const Value.absent()
          : Value(tariffId),
      tariffVersionSnapshot: tariffVersionSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(tariffVersionSnapshot),
      unitPriceMinorSnapshot: unitPriceMinorSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPriceMinorSnapshot),
      currencySnapshot: currencySnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(currencySnapshot),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      needsSync: Value(needsSync),
    );
  }

  factory SyntheticPackage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyntheticPackage(
      id: serializer.fromJson<String>(json['id']),
      deliveryRunId: serializer.fromJson<String>(json['deliveryRunId']),
      status: serializer.fromJson<String>(json['status']),
      externalReference: serializer.fromJson<String?>(
        json['externalReference'],
      ),
      identifiedOperatorId: serializer.fromJson<String?>(
        json['identifiedOperatorId'],
      ),
      identificationStatus: serializer.fromJson<String>(
        json['identificationStatus'],
      ),
      identificationConfidence: serializer.fromJson<double?>(
        json['identificationConfidence'],
      ),
      tariffId: serializer.fromJson<String?>(json['tariffId']),
      tariffVersionSnapshot: serializer.fromJson<int?>(
        json['tariffVersionSnapshot'],
      ),
      unitPriceMinorSnapshot: serializer.fromJson<int?>(
        json['unitPriceMinorSnapshot'],
      ),
      currencySnapshot: serializer.fromJson<String?>(json['currencySnapshot']),
      deliveredAt: serializer.fromJson<DateTime?>(json['deliveredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deliveryRunId': serializer.toJson<String>(deliveryRunId),
      'status': serializer.toJson<String>(status),
      'externalReference': serializer.toJson<String?>(externalReference),
      'identifiedOperatorId': serializer.toJson<String?>(identifiedOperatorId),
      'identificationStatus': serializer.toJson<String>(identificationStatus),
      'identificationConfidence': serializer.toJson<double?>(
        identificationConfidence,
      ),
      'tariffId': serializer.toJson<String?>(tariffId),
      'tariffVersionSnapshot': serializer.toJson<int?>(tariffVersionSnapshot),
      'unitPriceMinorSnapshot': serializer.toJson<int?>(unitPriceMinorSnapshot),
      'currencySnapshot': serializer.toJson<String?>(currencySnapshot),
      'deliveredAt': serializer.toJson<DateTime?>(deliveredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  SyntheticPackage copyWith({
    String? id,
    String? deliveryRunId,
    String? status,
    Value<String?> externalReference = const Value.absent(),
    Value<String?> identifiedOperatorId = const Value.absent(),
    String? identificationStatus,
    Value<double?> identificationConfidence = const Value.absent(),
    Value<String?> tariffId = const Value.absent(),
    Value<int?> tariffVersionSnapshot = const Value.absent(),
    Value<int?> unitPriceMinorSnapshot = const Value.absent(),
    Value<String?> currencySnapshot = const Value.absent(),
    Value<DateTime?> deliveredAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
  }) => SyntheticPackage(
    id: id ?? this.id,
    deliveryRunId: deliveryRunId ?? this.deliveryRunId,
    status: status ?? this.status,
    externalReference: externalReference.present
        ? externalReference.value
        : this.externalReference,
    identifiedOperatorId: identifiedOperatorId.present
        ? identifiedOperatorId.value
        : this.identifiedOperatorId,
    identificationStatus: identificationStatus ?? this.identificationStatus,
    identificationConfidence: identificationConfidence.present
        ? identificationConfidence.value
        : this.identificationConfidence,
    tariffId: tariffId.present ? tariffId.value : this.tariffId,
    tariffVersionSnapshot: tariffVersionSnapshot.present
        ? tariffVersionSnapshot.value
        : this.tariffVersionSnapshot,
    unitPriceMinorSnapshot: unitPriceMinorSnapshot.present
        ? unitPriceMinorSnapshot.value
        : this.unitPriceMinorSnapshot,
    currencySnapshot: currencySnapshot.present
        ? currencySnapshot.value
        : this.currencySnapshot,
    deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    needsSync: needsSync ?? this.needsSync,
  );
  SyntheticPackage copyWithCompanion(SyntheticPackagesCompanion data) {
    return SyntheticPackage(
      id: data.id.present ? data.id.value : this.id,
      deliveryRunId: data.deliveryRunId.present
          ? data.deliveryRunId.value
          : this.deliveryRunId,
      status: data.status.present ? data.status.value : this.status,
      externalReference: data.externalReference.present
          ? data.externalReference.value
          : this.externalReference,
      identifiedOperatorId: data.identifiedOperatorId.present
          ? data.identifiedOperatorId.value
          : this.identifiedOperatorId,
      identificationStatus: data.identificationStatus.present
          ? data.identificationStatus.value
          : this.identificationStatus,
      identificationConfidence: data.identificationConfidence.present
          ? data.identificationConfidence.value
          : this.identificationConfidence,
      tariffId: data.tariffId.present ? data.tariffId.value : this.tariffId,
      tariffVersionSnapshot: data.tariffVersionSnapshot.present
          ? data.tariffVersionSnapshot.value
          : this.tariffVersionSnapshot,
      unitPriceMinorSnapshot: data.unitPriceMinorSnapshot.present
          ? data.unitPriceMinorSnapshot.value
          : this.unitPriceMinorSnapshot,
      currencySnapshot: data.currencySnapshot.present
          ? data.currencySnapshot.value
          : this.currencySnapshot,
      deliveredAt: data.deliveredAt.present
          ? data.deliveredAt.value
          : this.deliveredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyntheticPackage(')
          ..write('id: $id, ')
          ..write('deliveryRunId: $deliveryRunId, ')
          ..write('status: $status, ')
          ..write('externalReference: $externalReference, ')
          ..write('identifiedOperatorId: $identifiedOperatorId, ')
          ..write('identificationStatus: $identificationStatus, ')
          ..write('identificationConfidence: $identificationConfidence, ')
          ..write('tariffId: $tariffId, ')
          ..write('tariffVersionSnapshot: $tariffVersionSnapshot, ')
          ..write('unitPriceMinorSnapshot: $unitPriceMinorSnapshot, ')
          ..write('currencySnapshot: $currencySnapshot, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deliveryRunId,
    status,
    externalReference,
    identifiedOperatorId,
    identificationStatus,
    identificationConfidence,
    tariffId,
    tariffVersionSnapshot,
    unitPriceMinorSnapshot,
    currencySnapshot,
    deliveredAt,
    createdAt,
    updatedAt,
    needsSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyntheticPackage &&
          other.id == this.id &&
          other.deliveryRunId == this.deliveryRunId &&
          other.status == this.status &&
          other.externalReference == this.externalReference &&
          other.identifiedOperatorId == this.identifiedOperatorId &&
          other.identificationStatus == this.identificationStatus &&
          other.identificationConfidence == this.identificationConfidence &&
          other.tariffId == this.tariffId &&
          other.tariffVersionSnapshot == this.tariffVersionSnapshot &&
          other.unitPriceMinorSnapshot == this.unitPriceMinorSnapshot &&
          other.currencySnapshot == this.currencySnapshot &&
          other.deliveredAt == this.deliveredAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.needsSync == this.needsSync);
}

class SyntheticPackagesCompanion extends UpdateCompanion<SyntheticPackage> {
  final Value<String> id;
  final Value<String> deliveryRunId;
  final Value<String> status;
  final Value<String?> externalReference;
  final Value<String?> identifiedOperatorId;
  final Value<String> identificationStatus;
  final Value<double?> identificationConfidence;
  final Value<String?> tariffId;
  final Value<int?> tariffVersionSnapshot;
  final Value<int?> unitPriceMinorSnapshot;
  final Value<String?> currencySnapshot;
  final Value<DateTime?> deliveredAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> needsSync;
  final Value<int> rowid;
  const SyntheticPackagesCompanion({
    this.id = const Value.absent(),
    this.deliveryRunId = const Value.absent(),
    this.status = const Value.absent(),
    this.externalReference = const Value.absent(),
    this.identifiedOperatorId = const Value.absent(),
    this.identificationStatus = const Value.absent(),
    this.identificationConfidence = const Value.absent(),
    this.tariffId = const Value.absent(),
    this.tariffVersionSnapshot = const Value.absent(),
    this.unitPriceMinorSnapshot = const Value.absent(),
    this.currencySnapshot = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyntheticPackagesCompanion.insert({
    required String id,
    required String deliveryRunId,
    this.status = const Value.absent(),
    this.externalReference = const Value.absent(),
    this.identifiedOperatorId = const Value.absent(),
    this.identificationStatus = const Value.absent(),
    this.identificationConfidence = const Value.absent(),
    this.tariffId = const Value.absent(),
    this.tariffVersionSnapshot = const Value.absent(),
    this.unitPriceMinorSnapshot = const Value.absent(),
    this.currencySnapshot = const Value.absent(),
    this.deliveredAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deliveryRunId = Value(deliveryRunId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SyntheticPackage> custom({
    Expression<String>? id,
    Expression<String>? deliveryRunId,
    Expression<String>? status,
    Expression<String>? externalReference,
    Expression<String>? identifiedOperatorId,
    Expression<String>? identificationStatus,
    Expression<double>? identificationConfidence,
    Expression<String>? tariffId,
    Expression<int>? tariffVersionSnapshot,
    Expression<int>? unitPriceMinorSnapshot,
    Expression<String>? currencySnapshot,
    Expression<DateTime>? deliveredAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? needsSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deliveryRunId != null) 'delivery_run_id': deliveryRunId,
      if (status != null) 'status': status,
      if (externalReference != null) 'external_reference': externalReference,
      if (identifiedOperatorId != null)
        'identified_operator_id': identifiedOperatorId,
      if (identificationStatus != null)
        'identification_status': identificationStatus,
      if (identificationConfidence != null)
        'identification_confidence': identificationConfidence,
      if (tariffId != null) 'tariff_id': tariffId,
      if (tariffVersionSnapshot != null)
        'tariff_version_snapshot': tariffVersionSnapshot,
      if (unitPriceMinorSnapshot != null)
        'unit_price_minor_snapshot': unitPriceMinorSnapshot,
      if (currencySnapshot != null) 'currency_snapshot': currencySnapshot,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyntheticPackagesCompanion copyWith({
    Value<String>? id,
    Value<String>? deliveryRunId,
    Value<String>? status,
    Value<String?>? externalReference,
    Value<String?>? identifiedOperatorId,
    Value<String>? identificationStatus,
    Value<double?>? identificationConfidence,
    Value<String?>? tariffId,
    Value<int?>? tariffVersionSnapshot,
    Value<int?>? unitPriceMinorSnapshot,
    Value<String?>? currencySnapshot,
    Value<DateTime?>? deliveredAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? needsSync,
    Value<int>? rowid,
  }) {
    return SyntheticPackagesCompanion(
      id: id ?? this.id,
      deliveryRunId: deliveryRunId ?? this.deliveryRunId,
      status: status ?? this.status,
      externalReference: externalReference ?? this.externalReference,
      identifiedOperatorId: identifiedOperatorId ?? this.identifiedOperatorId,
      identificationStatus: identificationStatus ?? this.identificationStatus,
      identificationConfidence:
          identificationConfidence ?? this.identificationConfidence,
      tariffId: tariffId ?? this.tariffId,
      tariffVersionSnapshot:
          tariffVersionSnapshot ?? this.tariffVersionSnapshot,
      unitPriceMinorSnapshot:
          unitPriceMinorSnapshot ?? this.unitPriceMinorSnapshot,
      currencySnapshot: currencySnapshot ?? this.currencySnapshot,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deliveryRunId.present) {
      map['delivery_run_id'] = Variable<String>(deliveryRunId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (externalReference.present) {
      map['external_reference'] = Variable<String>(externalReference.value);
    }
    if (identifiedOperatorId.present) {
      map['identified_operator_id'] = Variable<String>(
        identifiedOperatorId.value,
      );
    }
    if (identificationStatus.present) {
      map['identification_status'] = Variable<String>(
        identificationStatus.value,
      );
    }
    if (identificationConfidence.present) {
      map['identification_confidence'] = Variable<double>(
        identificationConfidence.value,
      );
    }
    if (tariffId.present) {
      map['tariff_id'] = Variable<String>(tariffId.value);
    }
    if (tariffVersionSnapshot.present) {
      map['tariff_version_snapshot'] = Variable<int>(
        tariffVersionSnapshot.value,
      );
    }
    if (unitPriceMinorSnapshot.present) {
      map['unit_price_minor_snapshot'] = Variable<int>(
        unitPriceMinorSnapshot.value,
      );
    }
    if (currencySnapshot.present) {
      map['currency_snapshot'] = Variable<String>(currencySnapshot.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyntheticPackagesCompanion(')
          ..write('id: $id, ')
          ..write('deliveryRunId: $deliveryRunId, ')
          ..write('status: $status, ')
          ..write('externalReference: $externalReference, ')
          ..write('identifiedOperatorId: $identifiedOperatorId, ')
          ..write('identificationStatus: $identificationStatus, ')
          ..write('identificationConfidence: $identificationConfidence, ')
          ..write('tariffId: $tariffId, ')
          ..write('tariffVersionSnapshot: $tariffVersionSnapshot, ')
          ..write('unitPriceMinorSnapshot: $unitPriceMinorSnapshot, ')
          ..write('currencySnapshot: $currencySnapshot, ')
          ..write('deliveredAt: $deliveredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeliveryEventsTable extends DeliveryEvents
    with TableInfo<$DeliveryEventsTable, DeliveryEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeliveryEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageIdMeta = const VerificationMeta(
    'packageId',
  );
  @override
  late final GeneratedColumn<String> packageId = GeneratedColumn<String>(
    'package_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES synthetic_packages (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needsSyncMeta = const VerificationMeta(
    'needsSync',
  );
  @override
  late final GeneratedColumn<bool> needsSync = GeneratedColumn<bool>(
    'needs_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packageId,
    eventType,
    occurredAt,
    needsSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeliveryEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('package_id')) {
      context.handle(
        _packageIdMeta,
        packageId.isAcceptableOrUnknown(data['package_id']!, _packageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_packageIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('needs_sync')) {
      context.handle(
        _needsSyncMeta,
        needsSync.isAcceptableOrUnknown(data['needs_sync']!, _needsSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeliveryEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      packageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      needsSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_sync'],
      )!,
    );
  }

  @override
  $DeliveryEventsTable createAlias(String alias) {
    return $DeliveryEventsTable(attachedDatabase, alias);
  }
}

class DeliveryEvent extends DataClass implements Insertable<DeliveryEvent> {
  final String id;
  final String packageId;
  final String eventType;
  final DateTime occurredAt;
  final bool needsSync;
  const DeliveryEvent({
    required this.id,
    required this.packageId,
    required this.eventType,
    required this.occurredAt,
    required this.needsSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['package_id'] = Variable<String>(packageId);
    map['event_type'] = Variable<String>(eventType);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['needs_sync'] = Variable<bool>(needsSync);
    return map;
  }

  DeliveryEventsCompanion toCompanion(bool nullToAbsent) {
    return DeliveryEventsCompanion(
      id: Value(id),
      packageId: Value(packageId),
      eventType: Value(eventType),
      occurredAt: Value(occurredAt),
      needsSync: Value(needsSync),
    );
  }

  factory DeliveryEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryEvent(
      id: serializer.fromJson<String>(json['id']),
      packageId: serializer.fromJson<String>(json['packageId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      needsSync: serializer.fromJson<bool>(json['needsSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'packageId': serializer.toJson<String>(packageId),
      'eventType': serializer.toJson<String>(eventType),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'needsSync': serializer.toJson<bool>(needsSync),
    };
  }

  DeliveryEvent copyWith({
    String? id,
    String? packageId,
    String? eventType,
    DateTime? occurredAt,
    bool? needsSync,
  }) => DeliveryEvent(
    id: id ?? this.id,
    packageId: packageId ?? this.packageId,
    eventType: eventType ?? this.eventType,
    occurredAt: occurredAt ?? this.occurredAt,
    needsSync: needsSync ?? this.needsSync,
  );
  DeliveryEvent copyWithCompanion(DeliveryEventsCompanion data) {
    return DeliveryEvent(
      id: data.id.present ? data.id.value : this.id,
      packageId: data.packageId.present ? data.packageId.value : this.packageId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      needsSync: data.needsSync.present ? data.needsSync.value : this.needsSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryEvent(')
          ..write('id: $id, ')
          ..write('packageId: $packageId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('needsSync: $needsSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, packageId, eventType, occurredAt, needsSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryEvent &&
          other.id == this.id &&
          other.packageId == this.packageId &&
          other.eventType == this.eventType &&
          other.occurredAt == this.occurredAt &&
          other.needsSync == this.needsSync);
}

class DeliveryEventsCompanion extends UpdateCompanion<DeliveryEvent> {
  final Value<String> id;
  final Value<String> packageId;
  final Value<String> eventType;
  final Value<DateTime> occurredAt;
  final Value<bool> needsSync;
  final Value<int> rowid;
  const DeliveryEventsCompanion({
    this.id = const Value.absent(),
    this.packageId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeliveryEventsCompanion.insert({
    required String id,
    required String packageId,
    required String eventType,
    required DateTime occurredAt,
    this.needsSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       packageId = Value(packageId),
       eventType = Value(eventType),
       occurredAt = Value(occurredAt);
  static Insertable<DeliveryEvent> custom({
    Expression<String>? id,
    Expression<String>? packageId,
    Expression<String>? eventType,
    Expression<DateTime>? occurredAt,
    Expression<bool>? needsSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageId != null) 'package_id': packageId,
      if (eventType != null) 'event_type': eventType,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (needsSync != null) 'needs_sync': needsSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeliveryEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? packageId,
    Value<String>? eventType,
    Value<DateTime>? occurredAt,
    Value<bool>? needsSync,
    Value<int>? rowid,
  }) {
    return DeliveryEventsCompanion(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      eventType: eventType ?? this.eventType,
      occurredAt: occurredAt ?? this.occurredAt,
      needsSync: needsSync ?? this.needsSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (packageId.present) {
      map['package_id'] = Variable<String>(packageId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (needsSync.present) {
      map['needs_sync'] = Variable<bool>(needsSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryEventsCompanion(')
          ..write('id: $id, ')
          ..write('packageId: $packageId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('needsSync: $needsSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RiderBizDatabase extends GeneratedDatabase {
  _$RiderBizDatabase(QueryExecutor e) : super(e);
  $RiderBizDatabaseManager get managers => $RiderBizDatabaseManager(this);
  late final $LogisticsOperatorsTable logisticsOperators =
      $LogisticsOperatorsTable(this);
  late final $OperatorTariffsTable operatorTariffs = $OperatorTariffsTable(
    this,
  );
  late final $OperatorLabelProfilesTable operatorLabelProfiles =
      $OperatorLabelProfilesTable(this);
  late final $DeliveryRunsTable deliveryRuns = $DeliveryRunsTable(this);
  late final $SyntheticPackagesTable syntheticPackages =
      $SyntheticPackagesTable(this);
  late final $DeliveryEventsTable deliveryEvents = $DeliveryEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    logisticsOperators,
    operatorTariffs,
    operatorLabelProfiles,
    deliveryRuns,
    syntheticPackages,
    deliveryEvents,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'logistics_operators',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('operator_label_profiles', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'delivery_runs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('synthetic_packages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'synthetic_packages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('delivery_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LogisticsOperatorsTableCreateCompanionBuilder =
    LogisticsOperatorsCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$LogisticsOperatorsTableUpdateCompanionBuilder =
    LogisticsOperatorsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$LogisticsOperatorsTableReferences
    extends
        BaseReferences<
          _$RiderBizDatabase,
          $LogisticsOperatorsTable,
          LogisticsOperator
        > {
  $$LogisticsOperatorsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$OperatorTariffsTable, List<OperatorTariff>>
  _operatorTariffsRefsTable(_$RiderBizDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.operatorTariffs,
        aliasName: 'logistics_operators__id__operator_tariffs__operator_id',
      );

  $$OperatorTariffsTableProcessedTableManager get operatorTariffsRefs {
    final manager = $$OperatorTariffsTableTableManager(
      $_db,
      $_db.operatorTariffs,
    ).filter((f) => f.operatorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _operatorTariffsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $OperatorLabelProfilesTable,
    List<OperatorLabelProfile>
  >
  _operatorLabelProfilesRefsTable(_$RiderBizDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.operatorLabelProfiles,
        aliasName:
            'logistics_operators__id__operator_label_profiles__operator_id',
      );

  $$OperatorLabelProfilesTableProcessedTableManager
  get operatorLabelProfilesRefs {
    final manager = $$OperatorLabelProfilesTableTableManager(
      $_db,
      $_db.operatorLabelProfiles,
    ).filter((f) => f.operatorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _operatorLabelProfilesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DeliveryRunsTable, List<DeliveryRun>>
  _deliveryRunsRefsTable(_$RiderBizDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.deliveryRuns,
        aliasName: 'logistics_operators__id__delivery_runs__operator_id',
      );

  $$DeliveryRunsTableProcessedTableManager get deliveryRunsRefs {
    final manager = $$DeliveryRunsTableTableManager(
      $_db,
      $_db.deliveryRuns,
    ).filter((f) => f.operatorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_deliveryRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SyntheticPackagesTable, List<SyntheticPackage>>
  _syntheticPackagesRefsTable(
    _$RiderBizDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.syntheticPackages,
    aliasName:
        'logistics_operators__id__synthetic_packages__identified_operator_id',
  );

  $$SyntheticPackagesTableProcessedTableManager get syntheticPackagesRefs {
    final manager =
        $$SyntheticPackagesTableTableManager(
          $_db,
          $_db.syntheticPackages,
        ).filter(
          (f) =>
              f.identifiedOperatorId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _syntheticPackagesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LogisticsOperatorsTableFilterComposer
    extends Composer<_$RiderBizDatabase, $LogisticsOperatorsTable> {
  $$LogisticsOperatorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> operatorTariffsRefs(
    Expression<bool> Function($$OperatorTariffsTableFilterComposer f) f,
  ) {
    final $$OperatorTariffsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.operatorTariffs,
      getReferencedColumn: (t) => t.operatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperatorTariffsTableFilterComposer(
            $db: $db,
            $table: $db.operatorTariffs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> operatorLabelProfilesRefs(
    Expression<bool> Function($$OperatorLabelProfilesTableFilterComposer f) f,
  ) {
    final $$OperatorLabelProfilesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.operatorLabelProfiles,
          getReferencedColumn: (t) => t.operatorId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OperatorLabelProfilesTableFilterComposer(
                $db: $db,
                $table: $db.operatorLabelProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> deliveryRunsRefs(
    Expression<bool> Function($$DeliveryRunsTableFilterComposer f) f,
  ) {
    final $$DeliveryRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deliveryRuns,
      getReferencedColumn: (t) => t.operatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeliveryRunsTableFilterComposer(
            $db: $db,
            $table: $db.deliveryRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> syntheticPackagesRefs(
    Expression<bool> Function($$SyntheticPackagesTableFilterComposer f) f,
  ) {
    final $$SyntheticPackagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syntheticPackages,
      getReferencedColumn: (t) => t.identifiedOperatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyntheticPackagesTableFilterComposer(
            $db: $db,
            $table: $db.syntheticPackages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LogisticsOperatorsTableOrderingComposer
    extends Composer<_$RiderBizDatabase, $LogisticsOperatorsTable> {
  $$LogisticsOperatorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LogisticsOperatorsTableAnnotationComposer
    extends Composer<_$RiderBizDatabase, $LogisticsOperatorsTable> {
  $$LogisticsOperatorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> operatorTariffsRefs<T extends Object>(
    Expression<T> Function($$OperatorTariffsTableAnnotationComposer a) f,
  ) {
    final $$OperatorTariffsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.operatorTariffs,
      getReferencedColumn: (t) => t.operatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperatorTariffsTableAnnotationComposer(
            $db: $db,
            $table: $db.operatorTariffs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> operatorLabelProfilesRefs<T extends Object>(
    Expression<T> Function($$OperatorLabelProfilesTableAnnotationComposer a) f,
  ) {
    final $$OperatorLabelProfilesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.operatorLabelProfiles,
          getReferencedColumn: (t) => t.operatorId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$OperatorLabelProfilesTableAnnotationComposer(
                $db: $db,
                $table: $db.operatorLabelProfiles,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> deliveryRunsRefs<T extends Object>(
    Expression<T> Function($$DeliveryRunsTableAnnotationComposer a) f,
  ) {
    final $$DeliveryRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deliveryRuns,
      getReferencedColumn: (t) => t.operatorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeliveryRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.deliveryRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> syntheticPackagesRefs<T extends Object>(
    Expression<T> Function($$SyntheticPackagesTableAnnotationComposer a) f,
  ) {
    final $$SyntheticPackagesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.syntheticPackages,
          getReferencedColumn: (t) => t.identifiedOperatorId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyntheticPackagesTableAnnotationComposer(
                $db: $db,
                $table: $db.syntheticPackages,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$LogisticsOperatorsTableTableManager
    extends
        RootTableManager<
          _$RiderBizDatabase,
          $LogisticsOperatorsTable,
          LogisticsOperator,
          $$LogisticsOperatorsTableFilterComposer,
          $$LogisticsOperatorsTableOrderingComposer,
          $$LogisticsOperatorsTableAnnotationComposer,
          $$LogisticsOperatorsTableCreateCompanionBuilder,
          $$LogisticsOperatorsTableUpdateCompanionBuilder,
          (LogisticsOperator, $$LogisticsOperatorsTableReferences),
          LogisticsOperator,
          PrefetchHooks Function({
            bool operatorTariffsRefs,
            bool operatorLabelProfilesRefs,
            bool deliveryRunsRefs,
            bool syntheticPackagesRefs,
          })
        > {
  $$LogisticsOperatorsTableTableManager(
    _$RiderBizDatabase db,
    $LogisticsOperatorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogisticsOperatorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogisticsOperatorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogisticsOperatorsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogisticsOperatorsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogisticsOperatorsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LogisticsOperatorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                operatorTariffsRefs = false,
                operatorLabelProfilesRefs = false,
                deliveryRunsRefs = false,
                syntheticPackagesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (operatorTariffsRefs) db.operatorTariffs,
                    if (operatorLabelProfilesRefs) db.operatorLabelProfiles,
                    if (deliveryRunsRefs) db.deliveryRuns,
                    if (syntheticPackagesRefs) db.syntheticPackages,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (operatorTariffsRefs)
                        await $_getPrefetchedData<
                          LogisticsOperator,
                          $LogisticsOperatorsTable,
                          OperatorTariff
                        >(
                          currentTable: table,
                          referencedTable: $$LogisticsOperatorsTableReferences
                              ._operatorTariffsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LogisticsOperatorsTableReferences(
                                db,
                                table,
                                p0,
                              ).operatorTariffsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.operatorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (operatorLabelProfilesRefs)
                        await $_getPrefetchedData<
                          LogisticsOperator,
                          $LogisticsOperatorsTable,
                          OperatorLabelProfile
                        >(
                          currentTable: table,
                          referencedTable: $$LogisticsOperatorsTableReferences
                              ._operatorLabelProfilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LogisticsOperatorsTableReferences(
                                db,
                                table,
                                p0,
                              ).operatorLabelProfilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.operatorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (deliveryRunsRefs)
                        await $_getPrefetchedData<
                          LogisticsOperator,
                          $LogisticsOperatorsTable,
                          DeliveryRun
                        >(
                          currentTable: table,
                          referencedTable: $$LogisticsOperatorsTableReferences
                              ._deliveryRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LogisticsOperatorsTableReferences(
                                db,
                                table,
                                p0,
                              ).deliveryRunsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.operatorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (syntheticPackagesRefs)
                        await $_getPrefetchedData<
                          LogisticsOperator,
                          $LogisticsOperatorsTable,
                          SyntheticPackage
                        >(
                          currentTable: table,
                          referencedTable: $$LogisticsOperatorsTableReferences
                              ._syntheticPackagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LogisticsOperatorsTableReferences(
                                db,
                                table,
                                p0,
                              ).syntheticPackagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.identifiedOperatorId == item.id,
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

typedef $$LogisticsOperatorsTableProcessedTableManager =
    ProcessedTableManager<
      _$RiderBizDatabase,
      $LogisticsOperatorsTable,
      LogisticsOperator,
      $$LogisticsOperatorsTableFilterComposer,
      $$LogisticsOperatorsTableOrderingComposer,
      $$LogisticsOperatorsTableAnnotationComposer,
      $$LogisticsOperatorsTableCreateCompanionBuilder,
      $$LogisticsOperatorsTableUpdateCompanionBuilder,
      (LogisticsOperator, $$LogisticsOperatorsTableReferences),
      LogisticsOperator,
      PrefetchHooks Function({
        bool operatorTariffsRefs,
        bool operatorLabelProfilesRefs,
        bool deliveryRunsRefs,
        bool syntheticPackagesRefs,
      })
    >;
typedef $$OperatorTariffsTableCreateCompanionBuilder =
    OperatorTariffsCompanion Function({
      required String id,
      required String operatorId,
      required int version,
      required int unitPriceMinor,
      required String currency,
      required DateTime validFrom,
      Value<DateTime?> validUntil,
      Value<bool> isActive,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$OperatorTariffsTableUpdateCompanionBuilder =
    OperatorTariffsCompanion Function({
      Value<String> id,
      Value<String> operatorId,
      Value<int> version,
      Value<int> unitPriceMinor,
      Value<String> currency,
      Value<DateTime> validFrom,
      Value<DateTime?> validUntil,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$OperatorTariffsTableReferences
    extends
        BaseReferences<
          _$RiderBizDatabase,
          $OperatorTariffsTable,
          OperatorTariff
        > {
  $$OperatorTariffsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LogisticsOperatorsTable _operatorIdTable(_$RiderBizDatabase db) => db
      .logisticsOperators
      .createAlias('operator_tariffs__operator_id__logistics_operators__id');

  $$LogisticsOperatorsTableProcessedTableManager get operatorId {
    final $_column = $_itemColumn<String>('operator_id')!;

    final manager = $$LogisticsOperatorsTableTableManager(
      $_db,
      $_db.logisticsOperators,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_operatorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SyntheticPackagesTable, List<SyntheticPackage>>
  _syntheticPackagesRefsTable(_$RiderBizDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syntheticPackages,
        aliasName: 'operator_tariffs__id__synthetic_packages__tariff_id',
      );

  $$SyntheticPackagesTableProcessedTableManager get syntheticPackagesRefs {
    final manager = $$SyntheticPackagesTableTableManager(
      $_db,
      $_db.syntheticPackages,
    ).filter((f) => f.tariffId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syntheticPackagesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OperatorTariffsTableFilterComposer
    extends Composer<_$RiderBizDatabase, $OperatorTariffsTable> {
  $$OperatorTariffsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceMinor => $composableBuilder(
    column: $table.unitPriceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LogisticsOperatorsTableFilterComposer get operatorId {
    final $$LogisticsOperatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operatorId,
      referencedTable: $db.logisticsOperators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogisticsOperatorsTableFilterComposer(
            $db: $db,
            $table: $db.logisticsOperators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> syntheticPackagesRefs(
    Expression<bool> Function($$SyntheticPackagesTableFilterComposer f) f,
  ) {
    final $$SyntheticPackagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syntheticPackages,
      getReferencedColumn: (t) => t.tariffId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyntheticPackagesTableFilterComposer(
            $db: $db,
            $table: $db.syntheticPackages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OperatorTariffsTableOrderingComposer
    extends Composer<_$RiderBizDatabase, $OperatorTariffsTable> {
  $$OperatorTariffsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceMinor => $composableBuilder(
    column: $table.unitPriceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validFrom => $composableBuilder(
    column: $table.validFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LogisticsOperatorsTableOrderingComposer get operatorId {
    final $$LogisticsOperatorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operatorId,
      referencedTable: $db.logisticsOperators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogisticsOperatorsTableOrderingComposer(
            $db: $db,
            $table: $db.logisticsOperators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OperatorTariffsTableAnnotationComposer
    extends Composer<_$RiderBizDatabase, $OperatorTariffsTable> {
  $$OperatorTariffsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get unitPriceMinor => $composableBuilder(
    column: $table.unitPriceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get validFrom =>
      $composableBuilder(column: $table.validFrom, builder: (column) => column);

  GeneratedColumn<DateTime> get validUntil => $composableBuilder(
    column: $table.validUntil,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LogisticsOperatorsTableAnnotationComposer get operatorId {
    final $$LogisticsOperatorsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.operatorId,
          referencedTable: $db.logisticsOperators,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LogisticsOperatorsTableAnnotationComposer(
                $db: $db,
                $table: $db.logisticsOperators,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> syntheticPackagesRefs<T extends Object>(
    Expression<T> Function($$SyntheticPackagesTableAnnotationComposer a) f,
  ) {
    final $$SyntheticPackagesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.syntheticPackages,
          getReferencedColumn: (t) => t.tariffId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyntheticPackagesTableAnnotationComposer(
                $db: $db,
                $table: $db.syntheticPackages,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$OperatorTariffsTableTableManager
    extends
        RootTableManager<
          _$RiderBizDatabase,
          $OperatorTariffsTable,
          OperatorTariff,
          $$OperatorTariffsTableFilterComposer,
          $$OperatorTariffsTableOrderingComposer,
          $$OperatorTariffsTableAnnotationComposer,
          $$OperatorTariffsTableCreateCompanionBuilder,
          $$OperatorTariffsTableUpdateCompanionBuilder,
          (OperatorTariff, $$OperatorTariffsTableReferences),
          OperatorTariff,
          PrefetchHooks Function({bool operatorId, bool syntheticPackagesRefs})
        > {
  $$OperatorTariffsTableTableManager(
    _$RiderBizDatabase db,
    $OperatorTariffsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperatorTariffsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OperatorTariffsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OperatorTariffsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> operatorId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> unitPriceMinor = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> validFrom = const Value.absent(),
                Value<DateTime?> validUntil = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperatorTariffsCompanion(
                id: id,
                operatorId: operatorId,
                version: version,
                unitPriceMinor: unitPriceMinor,
                currency: currency,
                validFrom: validFrom,
                validUntil: validUntil,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String operatorId,
                required int version,
                required int unitPriceMinor,
                required String currency,
                required DateTime validFrom,
                Value<DateTime?> validUntil = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => OperatorTariffsCompanion.insert(
                id: id,
                operatorId: operatorId,
                version: version,
                unitPriceMinor: unitPriceMinor,
                currency: currency,
                validFrom: validFrom,
                validUntil: validUntil,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OperatorTariffsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({operatorId = false, syntheticPackagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (syntheticPackagesRefs) db.syntheticPackages,
                  ],
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
                        if (operatorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.operatorId,
                            referencedTable: $$OperatorTariffsTableReferences
                                ._operatorIdTable(db),
                            referencedColumn: $$OperatorTariffsTableReferences
                                ._operatorIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (syntheticPackagesRefs)
                        await $_getPrefetchedData<
                          OperatorTariff,
                          $OperatorTariffsTable,
                          SyntheticPackage
                        >(
                          currentTable: table,
                          referencedTable: $$OperatorTariffsTableReferences
                              ._syntheticPackagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OperatorTariffsTableReferences(
                                db,
                                table,
                                p0,
                              ).syntheticPackagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tariffId == item.id,
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

typedef $$OperatorTariffsTableProcessedTableManager =
    ProcessedTableManager<
      _$RiderBizDatabase,
      $OperatorTariffsTable,
      OperatorTariff,
      $$OperatorTariffsTableFilterComposer,
      $$OperatorTariffsTableOrderingComposer,
      $$OperatorTariffsTableAnnotationComposer,
      $$OperatorTariffsTableCreateCompanionBuilder,
      $$OperatorTariffsTableUpdateCompanionBuilder,
      (OperatorTariff, $$OperatorTariffsTableReferences),
      OperatorTariff,
      PrefetchHooks Function({bool operatorId, bool syntheticPackagesRefs})
    >;
typedef $$OperatorLabelProfilesTableCreateCompanionBuilder =
    OperatorLabelProfilesCompanion Function({
      required String id,
      required String operatorId,
      required String marker,
      Value<int> priority,
      Value<bool> isActive,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$OperatorLabelProfilesTableUpdateCompanionBuilder =
    OperatorLabelProfilesCompanion Function({
      Value<String> id,
      Value<String> operatorId,
      Value<String> marker,
      Value<int> priority,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$OperatorLabelProfilesTableReferences
    extends
        BaseReferences<
          _$RiderBizDatabase,
          $OperatorLabelProfilesTable,
          OperatorLabelProfile
        > {
  $$OperatorLabelProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LogisticsOperatorsTable _operatorIdTable(_$RiderBizDatabase db) =>
      db.logisticsOperators.createAlias(
        'operator_label_profiles__operator_id__logistics_operators__id',
      );

  $$LogisticsOperatorsTableProcessedTableManager get operatorId {
    final $_column = $_itemColumn<String>('operator_id')!;

    final manager = $$LogisticsOperatorsTableTableManager(
      $_db,
      $_db.logisticsOperators,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_operatorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OperatorLabelProfilesTableFilterComposer
    extends Composer<_$RiderBizDatabase, $OperatorLabelProfilesTable> {
  $$OperatorLabelProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marker => $composableBuilder(
    column: $table.marker,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LogisticsOperatorsTableFilterComposer get operatorId {
    final $$LogisticsOperatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operatorId,
      referencedTable: $db.logisticsOperators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogisticsOperatorsTableFilterComposer(
            $db: $db,
            $table: $db.logisticsOperators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OperatorLabelProfilesTableOrderingComposer
    extends Composer<_$RiderBizDatabase, $OperatorLabelProfilesTable> {
  $$OperatorLabelProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marker => $composableBuilder(
    column: $table.marker,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LogisticsOperatorsTableOrderingComposer get operatorId {
    final $$LogisticsOperatorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operatorId,
      referencedTable: $db.logisticsOperators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogisticsOperatorsTableOrderingComposer(
            $db: $db,
            $table: $db.logisticsOperators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OperatorLabelProfilesTableAnnotationComposer
    extends Composer<_$RiderBizDatabase, $OperatorLabelProfilesTable> {
  $$OperatorLabelProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get marker =>
      $composableBuilder(column: $table.marker, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LogisticsOperatorsTableAnnotationComposer get operatorId {
    final $$LogisticsOperatorsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.operatorId,
          referencedTable: $db.logisticsOperators,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LogisticsOperatorsTableAnnotationComposer(
                $db: $db,
                $table: $db.logisticsOperators,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$OperatorLabelProfilesTableTableManager
    extends
        RootTableManager<
          _$RiderBizDatabase,
          $OperatorLabelProfilesTable,
          OperatorLabelProfile,
          $$OperatorLabelProfilesTableFilterComposer,
          $$OperatorLabelProfilesTableOrderingComposer,
          $$OperatorLabelProfilesTableAnnotationComposer,
          $$OperatorLabelProfilesTableCreateCompanionBuilder,
          $$OperatorLabelProfilesTableUpdateCompanionBuilder,
          (OperatorLabelProfile, $$OperatorLabelProfilesTableReferences),
          OperatorLabelProfile,
          PrefetchHooks Function({bool operatorId})
        > {
  $$OperatorLabelProfilesTableTableManager(
    _$RiderBizDatabase db,
    $OperatorLabelProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OperatorLabelProfilesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OperatorLabelProfilesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OperatorLabelProfilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> operatorId = const Value.absent(),
                Value<String> marker = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OperatorLabelProfilesCompanion(
                id: id,
                operatorId: operatorId,
                marker: marker,
                priority: priority,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String operatorId,
                required String marker,
                Value<int> priority = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => OperatorLabelProfilesCompanion.insert(
                id: id,
                operatorId: operatorId,
                marker: marker,
                priority: priority,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OperatorLabelProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({operatorId = false}) {
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
                    if (operatorId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.operatorId,
                        referencedTable: $$OperatorLabelProfilesTableReferences
                            ._operatorIdTable(db),
                        referencedColumn: $$OperatorLabelProfilesTableReferences
                            ._operatorIdTable(db)
                            .id,
                      ) as T;
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

typedef $$OperatorLabelProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$RiderBizDatabase,
      $OperatorLabelProfilesTable,
      OperatorLabelProfile,
      $$OperatorLabelProfilesTableFilterComposer,
      $$OperatorLabelProfilesTableOrderingComposer,
      $$OperatorLabelProfilesTableAnnotationComposer,
      $$OperatorLabelProfilesTableCreateCompanionBuilder,
      $$OperatorLabelProfilesTableUpdateCompanionBuilder,
      (OperatorLabelProfile, $$OperatorLabelProfilesTableReferences),
      OperatorLabelProfile,
      PrefetchHooks Function({bool operatorId})
    >;
typedef $$DeliveryRunsTableCreateCompanionBuilder =
    DeliveryRunsCompanion Function({
      required String id,
      required String operatorId,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });
typedef $$DeliveryRunsTableUpdateCompanionBuilder =
    DeliveryRunsCompanion Function({
      Value<String> id,
      Value<String> operatorId,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> rowid,
    });

final class $$DeliveryRunsTableReferences
    extends
        BaseReferences<_$RiderBizDatabase, $DeliveryRunsTable, DeliveryRun> {
  $$DeliveryRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LogisticsOperatorsTable _operatorIdTable(_$RiderBizDatabase db) => db
      .logisticsOperators
      .createAlias('delivery_runs__operator_id__logistics_operators__id');

  $$LogisticsOperatorsTableProcessedTableManager get operatorId {
    final $_column = $_itemColumn<String>('operator_id')!;

    final manager = $$LogisticsOperatorsTableTableManager(
      $_db,
      $_db.logisticsOperators,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_operatorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SyntheticPackagesTable, List<SyntheticPackage>>
  _syntheticPackagesRefsTable(_$RiderBizDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syntheticPackages,
        aliasName: 'delivery_runs__id__synthetic_packages__delivery_run_id',
      );

  $$SyntheticPackagesTableProcessedTableManager get syntheticPackagesRefs {
    final manager = $$SyntheticPackagesTableTableManager(
      $_db,
      $_db.syntheticPackages,
    ).filter((f) => f.deliveryRunId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syntheticPackagesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DeliveryRunsTableFilterComposer
    extends Composer<_$RiderBizDatabase, $DeliveryRunsTable> {
  $$DeliveryRunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LogisticsOperatorsTableFilterComposer get operatorId {
    final $$LogisticsOperatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operatorId,
      referencedTable: $db.logisticsOperators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogisticsOperatorsTableFilterComposer(
            $db: $db,
            $table: $db.logisticsOperators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> syntheticPackagesRefs(
    Expression<bool> Function($$SyntheticPackagesTableFilterComposer f) f,
  ) {
    final $$SyntheticPackagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syntheticPackages,
      getReferencedColumn: (t) => t.deliveryRunId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyntheticPackagesTableFilterComposer(
            $db: $db,
            $table: $db.syntheticPackages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DeliveryRunsTableOrderingComposer
    extends Composer<_$RiderBizDatabase, $DeliveryRunsTable> {
  $$DeliveryRunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LogisticsOperatorsTableOrderingComposer get operatorId {
    final $$LogisticsOperatorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.operatorId,
      referencedTable: $db.logisticsOperators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogisticsOperatorsTableOrderingComposer(
            $db: $db,
            $table: $db.logisticsOperators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeliveryRunsTableAnnotationComposer
    extends Composer<_$RiderBizDatabase, $DeliveryRunsTable> {
  $$DeliveryRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  $$LogisticsOperatorsTableAnnotationComposer get operatorId {
    final $$LogisticsOperatorsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.operatorId,
          referencedTable: $db.logisticsOperators,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LogisticsOperatorsTableAnnotationComposer(
                $db: $db,
                $table: $db.logisticsOperators,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> syntheticPackagesRefs<T extends Object>(
    Expression<T> Function($$SyntheticPackagesTableAnnotationComposer a) f,
  ) {
    final $$SyntheticPackagesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.syntheticPackages,
          getReferencedColumn: (t) => t.deliveryRunId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyntheticPackagesTableAnnotationComposer(
                $db: $db,
                $table: $db.syntheticPackages,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DeliveryRunsTableTableManager
    extends
        RootTableManager<
          _$RiderBizDatabase,
          $DeliveryRunsTable,
          DeliveryRun,
          $$DeliveryRunsTableFilterComposer,
          $$DeliveryRunsTableOrderingComposer,
          $$DeliveryRunsTableAnnotationComposer,
          $$DeliveryRunsTableCreateCompanionBuilder,
          $$DeliveryRunsTableUpdateCompanionBuilder,
          (DeliveryRun, $$DeliveryRunsTableReferences),
          DeliveryRun,
          PrefetchHooks Function({bool operatorId, bool syntheticPackagesRefs})
        > {
  $$DeliveryRunsTableTableManager(
    _$RiderBizDatabase db,
    $DeliveryRunsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeliveryRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeliveryRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeliveryRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> operatorId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeliveryRunsCompanion(
                id: id,
                operatorId: operatorId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String operatorId,
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeliveryRunsCompanion.insert(
                id: id,
                operatorId: operatorId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DeliveryRunsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({operatorId = false, syntheticPackagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (syntheticPackagesRefs) db.syntheticPackages,
                  ],
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
                        if (operatorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.operatorId,
                            referencedTable: $$DeliveryRunsTableReferences
                                ._operatorIdTable(db),
                            referencedColumn: $$DeliveryRunsTableReferences
                                ._operatorIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (syntheticPackagesRefs)
                        await $_getPrefetchedData<
                          DeliveryRun,
                          $DeliveryRunsTable,
                          SyntheticPackage
                        >(
                          currentTable: table,
                          referencedTable: $$DeliveryRunsTableReferences
                              ._syntheticPackagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DeliveryRunsTableReferences(
                                db,
                                table,
                                p0,
                              ).syntheticPackagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deliveryRunId == item.id,
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

typedef $$DeliveryRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$RiderBizDatabase,
      $DeliveryRunsTable,
      DeliveryRun,
      $$DeliveryRunsTableFilterComposer,
      $$DeliveryRunsTableOrderingComposer,
      $$DeliveryRunsTableAnnotationComposer,
      $$DeliveryRunsTableCreateCompanionBuilder,
      $$DeliveryRunsTableUpdateCompanionBuilder,
      (DeliveryRun, $$DeliveryRunsTableReferences),
      DeliveryRun,
      PrefetchHooks Function({bool operatorId, bool syntheticPackagesRefs})
    >;
typedef $$SyntheticPackagesTableCreateCompanionBuilder =
    SyntheticPackagesCompanion Function({
      required String id,
      required String deliveryRunId,
      Value<String> status,
      Value<String?> externalReference,
      Value<String?> identifiedOperatorId,
      Value<String> identificationStatus,
      Value<double?> identificationConfidence,
      Value<String?> tariffId,
      Value<int?> tariffVersionSnapshot,
      Value<int?> unitPriceMinorSnapshot,
      Value<String?> currencySnapshot,
      Value<DateTime?> deliveredAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });
typedef $$SyntheticPackagesTableUpdateCompanionBuilder =
    SyntheticPackagesCompanion Function({
      Value<String> id,
      Value<String> deliveryRunId,
      Value<String> status,
      Value<String?> externalReference,
      Value<String?> identifiedOperatorId,
      Value<String> identificationStatus,
      Value<double?> identificationConfidence,
      Value<String?> tariffId,
      Value<int?> tariffVersionSnapshot,
      Value<int?> unitPriceMinorSnapshot,
      Value<String?> currencySnapshot,
      Value<DateTime?> deliveredAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });

final class $$SyntheticPackagesTableReferences
    extends
        BaseReferences<
          _$RiderBizDatabase,
          $SyntheticPackagesTable,
          SyntheticPackage
        > {
  $$SyntheticPackagesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DeliveryRunsTable _deliveryRunIdTable(_$RiderBizDatabase db) => db
      .deliveryRuns
      .createAlias('synthetic_packages__delivery_run_id__delivery_runs__id');

  $$DeliveryRunsTableProcessedTableManager get deliveryRunId {
    final $_column = $_itemColumn<String>('delivery_run_id')!;

    final manager = $$DeliveryRunsTableTableManager(
      $_db,
      $_db.deliveryRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deliveryRunIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $LogisticsOperatorsTable _identifiedOperatorIdTable(
    _$RiderBizDatabase db,
  ) => db.logisticsOperators.createAlias(
    'synthetic_packages__identified_operator_id__logistics_operators__id',
  );

  $$LogisticsOperatorsTableProcessedTableManager? get identifiedOperatorId {
    final $_column = $_itemColumn<String>('identified_operator_id');
    if ($_column == null) return null;
    final manager = $$LogisticsOperatorsTableTableManager(
      $_db,
      $_db.logisticsOperators,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _identifiedOperatorIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $OperatorTariffsTable _tariffIdTable(_$RiderBizDatabase db) => db
      .operatorTariffs
      .createAlias('synthetic_packages__tariff_id__operator_tariffs__id');

  $$OperatorTariffsTableProcessedTableManager? get tariffId {
    final $_column = $_itemColumn<String>('tariff_id');
    if ($_column == null) return null;
    final manager = $$OperatorTariffsTableTableManager(
      $_db,
      $_db.operatorTariffs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tariffIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DeliveryEventsTable, List<DeliveryEvent>>
  _deliveryEventsRefsTable(_$RiderBizDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.deliveryEvents,
        aliasName: 'synthetic_packages__id__delivery_events__package_id',
      );

  $$DeliveryEventsTableProcessedTableManager get deliveryEventsRefs {
    final manager = $$DeliveryEventsTableTableManager(
      $_db,
      $_db.deliveryEvents,
    ).filter((f) => f.packageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_deliveryEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SyntheticPackagesTableFilterComposer
    extends Composer<_$RiderBizDatabase, $SyntheticPackagesTable> {
  $$SyntheticPackagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalReference => $composableBuilder(
    column: $table.externalReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identificationStatus => $composableBuilder(
    column: $table.identificationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get identificationConfidence => $composableBuilder(
    column: $table.identificationConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tariffVersionSnapshot => $composableBuilder(
    column: $table.tariffVersionSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceMinorSnapshot => $composableBuilder(
    column: $table.unitPriceMinorSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencySnapshot => $composableBuilder(
    column: $table.currencySnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnFilters(column),
  );

  $$DeliveryRunsTableFilterComposer get deliveryRunId {
    final $$DeliveryRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deliveryRunId,
      referencedTable: $db.deliveryRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeliveryRunsTableFilterComposer(
            $db: $db,
            $table: $db.deliveryRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LogisticsOperatorsTableFilterComposer get identifiedOperatorId {
    final $$LogisticsOperatorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identifiedOperatorId,
      referencedTable: $db.logisticsOperators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogisticsOperatorsTableFilterComposer(
            $db: $db,
            $table: $db.logisticsOperators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OperatorTariffsTableFilterComposer get tariffId {
    final $$OperatorTariffsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tariffId,
      referencedTable: $db.operatorTariffs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperatorTariffsTableFilterComposer(
            $db: $db,
            $table: $db.operatorTariffs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> deliveryEventsRefs(
    Expression<bool> Function($$DeliveryEventsTableFilterComposer f) f,
  ) {
    final $$DeliveryEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deliveryEvents,
      getReferencedColumn: (t) => t.packageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeliveryEventsTableFilterComposer(
            $db: $db,
            $table: $db.deliveryEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyntheticPackagesTableOrderingComposer
    extends Composer<_$RiderBizDatabase, $SyntheticPackagesTable> {
  $$SyntheticPackagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalReference => $composableBuilder(
    column: $table.externalReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identificationStatus => $composableBuilder(
    column: $table.identificationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get identificationConfidence => $composableBuilder(
    column: $table.identificationConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tariffVersionSnapshot => $composableBuilder(
    column: $table.tariffVersionSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceMinorSnapshot => $composableBuilder(
    column: $table.unitPriceMinorSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencySnapshot => $composableBuilder(
    column: $table.currencySnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnOrderings(column),
  );

  $$DeliveryRunsTableOrderingComposer get deliveryRunId {
    final $$DeliveryRunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deliveryRunId,
      referencedTable: $db.deliveryRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeliveryRunsTableOrderingComposer(
            $db: $db,
            $table: $db.deliveryRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LogisticsOperatorsTableOrderingComposer get identifiedOperatorId {
    final $$LogisticsOperatorsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.identifiedOperatorId,
      referencedTable: $db.logisticsOperators,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LogisticsOperatorsTableOrderingComposer(
            $db: $db,
            $table: $db.logisticsOperators,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OperatorTariffsTableOrderingComposer get tariffId {
    final $$OperatorTariffsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tariffId,
      referencedTable: $db.operatorTariffs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperatorTariffsTableOrderingComposer(
            $db: $db,
            $table: $db.operatorTariffs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyntheticPackagesTableAnnotationComposer
    extends Composer<_$RiderBizDatabase, $SyntheticPackagesTable> {
  $$SyntheticPackagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get externalReference => $composableBuilder(
    column: $table.externalReference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identificationStatus => $composableBuilder(
    column: $table.identificationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<double> get identificationConfidence => $composableBuilder(
    column: $table.identificationConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tariffVersionSnapshot => $composableBuilder(
    column: $table.tariffVersionSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitPriceMinorSnapshot => $composableBuilder(
    column: $table.unitPriceMinorSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencySnapshot => $composableBuilder(
    column: $table.currencySnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  $$DeliveryRunsTableAnnotationComposer get deliveryRunId {
    final $$DeliveryRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deliveryRunId,
      referencedTable: $db.deliveryRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeliveryRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.deliveryRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$LogisticsOperatorsTableAnnotationComposer get identifiedOperatorId {
    final $$LogisticsOperatorsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.identifiedOperatorId,
          referencedTable: $db.logisticsOperators,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LogisticsOperatorsTableAnnotationComposer(
                $db: $db,
                $table: $db.logisticsOperators,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$OperatorTariffsTableAnnotationComposer get tariffId {
    final $$OperatorTariffsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tariffId,
      referencedTable: $db.operatorTariffs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OperatorTariffsTableAnnotationComposer(
            $db: $db,
            $table: $db.operatorTariffs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> deliveryEventsRefs<T extends Object>(
    Expression<T> Function($$DeliveryEventsTableAnnotationComposer a) f,
  ) {
    final $$DeliveryEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deliveryEvents,
      getReferencedColumn: (t) => t.packageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeliveryEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.deliveryEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyntheticPackagesTableTableManager
    extends
        RootTableManager<
          _$RiderBizDatabase,
          $SyntheticPackagesTable,
          SyntheticPackage,
          $$SyntheticPackagesTableFilterComposer,
          $$SyntheticPackagesTableOrderingComposer,
          $$SyntheticPackagesTableAnnotationComposer,
          $$SyntheticPackagesTableCreateCompanionBuilder,
          $$SyntheticPackagesTableUpdateCompanionBuilder,
          (SyntheticPackage, $$SyntheticPackagesTableReferences),
          SyntheticPackage,
          PrefetchHooks Function({
            bool deliveryRunId,
            bool identifiedOperatorId,
            bool tariffId,
            bool deliveryEventsRefs,
          })
        > {
  $$SyntheticPackagesTableTableManager(
    _$RiderBizDatabase db,
    $SyntheticPackagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyntheticPackagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyntheticPackagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyntheticPackagesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deliveryRunId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> externalReference = const Value.absent(),
                Value<String?> identifiedOperatorId = const Value.absent(),
                Value<String> identificationStatus = const Value.absent(),
                Value<double?> identificationConfidence = const Value.absent(),
                Value<String?> tariffId = const Value.absent(),
                Value<int?> tariffVersionSnapshot = const Value.absent(),
                Value<int?> unitPriceMinorSnapshot = const Value.absent(),
                Value<String?> currencySnapshot = const Value.absent(),
                Value<DateTime?> deliveredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyntheticPackagesCompanion(
                id: id,
                deliveryRunId: deliveryRunId,
                status: status,
                externalReference: externalReference,
                identifiedOperatorId: identifiedOperatorId,
                identificationStatus: identificationStatus,
                identificationConfidence: identificationConfidence,
                tariffId: tariffId,
                tariffVersionSnapshot: tariffVersionSnapshot,
                unitPriceMinorSnapshot: unitPriceMinorSnapshot,
                currencySnapshot: currencySnapshot,
                deliveredAt: deliveredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deliveryRunId,
                Value<String> status = const Value.absent(),
                Value<String?> externalReference = const Value.absent(),
                Value<String?> identifiedOperatorId = const Value.absent(),
                Value<String> identificationStatus = const Value.absent(),
                Value<double?> identificationConfidence = const Value.absent(),
                Value<String?> tariffId = const Value.absent(),
                Value<int?> tariffVersionSnapshot = const Value.absent(),
                Value<int?> unitPriceMinorSnapshot = const Value.absent(),
                Value<String?> currencySnapshot = const Value.absent(),
                Value<DateTime?> deliveredAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyntheticPackagesCompanion.insert(
                id: id,
                deliveryRunId: deliveryRunId,
                status: status,
                externalReference: externalReference,
                identifiedOperatorId: identifiedOperatorId,
                identificationStatus: identificationStatus,
                identificationConfidence: identificationConfidence,
                tariffId: tariffId,
                tariffVersionSnapshot: tariffVersionSnapshot,
                unitPriceMinorSnapshot: unitPriceMinorSnapshot,
                currencySnapshot: currencySnapshot,
                deliveredAt: deliveredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyntheticPackagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                deliveryRunId = false,
                identifiedOperatorId = false,
                tariffId = false,
                deliveryEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (deliveryEventsRefs) db.deliveryEvents,
                  ],
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
                        if (deliveryRunId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.deliveryRunId,
                            referencedTable: $$SyntheticPackagesTableReferences
                                ._deliveryRunIdTable(db),
                            referencedColumn: $$SyntheticPackagesTableReferences
                                ._deliveryRunIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (identifiedOperatorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.identifiedOperatorId,
                            referencedTable: $$SyntheticPackagesTableReferences
                                ._identifiedOperatorIdTable(db),
                            referencedColumn: $$SyntheticPackagesTableReferences
                                ._identifiedOperatorIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (tariffId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tariffId,
                            referencedTable: $$SyntheticPackagesTableReferences
                                ._tariffIdTable(db),
                            referencedColumn: $$SyntheticPackagesTableReferences
                                ._tariffIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (deliveryEventsRefs)
                        await $_getPrefetchedData<
                          SyntheticPackage,
                          $SyntheticPackagesTable,
                          DeliveryEvent
                        >(
                          currentTable: table,
                          referencedTable: $$SyntheticPackagesTableReferences
                              ._deliveryEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyntheticPackagesTableReferences(
                                db,
                                table,
                                p0,
                              ).deliveryEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.packageId == item.id,
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

typedef $$SyntheticPackagesTableProcessedTableManager =
    ProcessedTableManager<
      _$RiderBizDatabase,
      $SyntheticPackagesTable,
      SyntheticPackage,
      $$SyntheticPackagesTableFilterComposer,
      $$SyntheticPackagesTableOrderingComposer,
      $$SyntheticPackagesTableAnnotationComposer,
      $$SyntheticPackagesTableCreateCompanionBuilder,
      $$SyntheticPackagesTableUpdateCompanionBuilder,
      (SyntheticPackage, $$SyntheticPackagesTableReferences),
      SyntheticPackage,
      PrefetchHooks Function({
        bool deliveryRunId,
        bool identifiedOperatorId,
        bool tariffId,
        bool deliveryEventsRefs,
      })
    >;
typedef $$DeliveryEventsTableCreateCompanionBuilder =
    DeliveryEventsCompanion Function({
      required String id,
      required String packageId,
      required String eventType,
      required DateTime occurredAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });
typedef $$DeliveryEventsTableUpdateCompanionBuilder =
    DeliveryEventsCompanion Function({
      Value<String> id,
      Value<String> packageId,
      Value<String> eventType,
      Value<DateTime> occurredAt,
      Value<bool> needsSync,
      Value<int> rowid,
    });

final class $$DeliveryEventsTableReferences
    extends
        BaseReferences<
          _$RiderBizDatabase,
          $DeliveryEventsTable,
          DeliveryEvent
        > {
  $$DeliveryEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyntheticPackagesTable _packageIdTable(_$RiderBizDatabase db) => db
      .syntheticPackages
      .createAlias('delivery_events__package_id__synthetic_packages__id');

  $$SyntheticPackagesTableProcessedTableManager get packageId {
    final $_column = $_itemColumn<String>('package_id')!;

    final manager = $$SyntheticPackagesTableTableManager(
      $_db,
      $_db.syntheticPackages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_packageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DeliveryEventsTableFilterComposer
    extends Composer<_$RiderBizDatabase, $DeliveryEventsTable> {
  $$DeliveryEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnFilters(column),
  );

  $$SyntheticPackagesTableFilterComposer get packageId {
    final $$SyntheticPackagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packageId,
      referencedTable: $db.syntheticPackages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyntheticPackagesTableFilterComposer(
            $db: $db,
            $table: $db.syntheticPackages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeliveryEventsTableOrderingComposer
    extends Composer<_$RiderBizDatabase, $DeliveryEventsTable> {
  $$DeliveryEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsSync => $composableBuilder(
    column: $table.needsSync,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyntheticPackagesTableOrderingComposer get packageId {
    final $$SyntheticPackagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.packageId,
      referencedTable: $db.syntheticPackages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyntheticPackagesTableOrderingComposer(
            $db: $db,
            $table: $db.syntheticPackages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeliveryEventsTableAnnotationComposer
    extends Composer<_$RiderBizDatabase, $DeliveryEventsTable> {
  $$DeliveryEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsSync =>
      $composableBuilder(column: $table.needsSync, builder: (column) => column);

  $$SyntheticPackagesTableAnnotationComposer get packageId {
    final $$SyntheticPackagesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.packageId,
          referencedTable: $db.syntheticPackages,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyntheticPackagesTableAnnotationComposer(
                $db: $db,
                $table: $db.syntheticPackages,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DeliveryEventsTableTableManager
    extends
        RootTableManager<
          _$RiderBizDatabase,
          $DeliveryEventsTable,
          DeliveryEvent,
          $$DeliveryEventsTableFilterComposer,
          $$DeliveryEventsTableOrderingComposer,
          $$DeliveryEventsTableAnnotationComposer,
          $$DeliveryEventsTableCreateCompanionBuilder,
          $$DeliveryEventsTableUpdateCompanionBuilder,
          (DeliveryEvent, $$DeliveryEventsTableReferences),
          DeliveryEvent,
          PrefetchHooks Function({bool packageId})
        > {
  $$DeliveryEventsTableTableManager(
    _$RiderBizDatabase db,
    $DeliveryEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeliveryEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeliveryEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeliveryEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> packageId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeliveryEventsCompanion(
                id: id,
                packageId: packageId,
                eventType: eventType,
                occurredAt: occurredAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String packageId,
                required String eventType,
                required DateTime occurredAt,
                Value<bool> needsSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeliveryEventsCompanion.insert(
                id: id,
                packageId: packageId,
                eventType: eventType,
                occurredAt: occurredAt,
                needsSync: needsSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DeliveryEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({packageId = false}) {
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
                    if (packageId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.packageId,
                        referencedTable: $$DeliveryEventsTableReferences
                            ._packageIdTable(db),
                        referencedColumn: $$DeliveryEventsTableReferences
                            ._packageIdTable(db)
                            .id,
                      ) as T;
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

typedef $$DeliveryEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$RiderBizDatabase,
      $DeliveryEventsTable,
      DeliveryEvent,
      $$DeliveryEventsTableFilterComposer,
      $$DeliveryEventsTableOrderingComposer,
      $$DeliveryEventsTableAnnotationComposer,
      $$DeliveryEventsTableCreateCompanionBuilder,
      $$DeliveryEventsTableUpdateCompanionBuilder,
      (DeliveryEvent, $$DeliveryEventsTableReferences),
      DeliveryEvent,
      PrefetchHooks Function({bool packageId})
    >;

class $RiderBizDatabaseManager {
  final _$RiderBizDatabase _db;
  $RiderBizDatabaseManager(this._db);
  $$LogisticsOperatorsTableTableManager get logisticsOperators =>
      $$LogisticsOperatorsTableTableManager(_db, _db.logisticsOperators);
  $$OperatorTariffsTableTableManager get operatorTariffs =>
      $$OperatorTariffsTableTableManager(_db, _db.operatorTariffs);
  $$OperatorLabelProfilesTableTableManager get operatorLabelProfiles =>
      $$OperatorLabelProfilesTableTableManager(_db, _db.operatorLabelProfiles);
  $$DeliveryRunsTableTableManager get deliveryRuns =>
      $$DeliveryRunsTableTableManager(_db, _db.deliveryRuns);
  $$SyntheticPackagesTableTableManager get syntheticPackages =>
      $$SyntheticPackagesTableTableManager(_db, _db.syntheticPackages);
  $$DeliveryEventsTableTableManager get deliveryEvents =>
      $$DeliveryEventsTableTableManager(_db, _db.deliveryEvents);
}
