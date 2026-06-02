// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AssetsTable extends Assets with TableInfo<$AssetsTable, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<String> lastModifiedAt = GeneratedColumn<String>(
    'last_modified_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetTypeMeta = const VerificationMeta(
    'assetType',
  );
  @override
  late final GeneratedColumn<String> assetType = GeneratedColumn<String>(
    'asset_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('주식'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KRW'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changeMeta = const VerificationMeta('change');
  @override
  late final GeneratedColumn<String> change = GeneratedColumn<String>(
    'change',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodePointMeta = const VerificationMeta(
    'iconCodePoint',
  );
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
    'icon_code_point',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityLabelMeta = const VerificationMeta(
    'quantityLabel',
  );
  @override
  late final GeneratedColumn<String> quantityLabel = GeneratedColumn<String>(
    'quantity_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityValueMeta = const VerificationMeta(
    'quantityValue',
  );
  @override
  late final GeneratedColumn<String> quantityValue = GeneratedColumn<String>(
    'quantity_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageLabelMeta = const VerificationMeta(
    'averageLabel',
  );
  @override
  late final GeneratedColumn<String> averageLabel = GeneratedColumn<String>(
    'average_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averageValueMeta = const VerificationMeta(
    'averageValue',
  );
  @override
  late final GeneratedColumn<String> averageValue = GeneratedColumn<String>(
    'average_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    assetType,
    title,
    alias,
    hidden,
    currencyCode,
    value,
    change,
    iconCodePoint,
    quantityLabel,
    quantityValue,
    averageLabel,
    averageValue,
    note,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Asset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('asset_type')) {
      context.handle(
        _assetTypeMeta,
        assetType.isAcceptableOrUnknown(data['asset_type']!, _assetTypeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('change')) {
      context.handle(
        _changeMeta,
        change.isAcceptableOrUnknown(data['change']!, _changeMeta),
      );
    } else if (isInserting) {
      context.missing(_changeMeta);
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
        _iconCodePointMeta,
        iconCodePoint.isAcceptableOrUnknown(
          data['icon_code_point']!,
          _iconCodePointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_iconCodePointMeta);
    }
    if (data.containsKey('quantity_label')) {
      context.handle(
        _quantityLabelMeta,
        quantityLabel.isAcceptableOrUnknown(
          data['quantity_label']!,
          _quantityLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityLabelMeta);
    }
    if (data.containsKey('quantity_value')) {
      context.handle(
        _quantityValueMeta,
        quantityValue.isAcceptableOrUnknown(
          data['quantity_value']!,
          _quantityValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityValueMeta);
    }
    if (data.containsKey('average_label')) {
      context.handle(
        _averageLabelMeta,
        averageLabel.isAcceptableOrUnknown(
          data['average_label']!,
          _averageLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averageLabelMeta);
    }
    if (data.containsKey('average_value')) {
      context.handle(
        _averageValueMeta,
        averageValue.isAcceptableOrUnknown(
          data['average_value']!,
          _averageValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averageValueMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Asset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      assetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      change: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change'],
      )!,
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      )!,
      quantityLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_label'],
      )!,
      quantityValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_value'],
      )!,
      averageLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}average_label'],
      )!,
      averageValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}average_value'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }
}

class Asset extends DataClass implements Insertable<Asset> {
  final int id;
  final String? clientId;
  final bool dirty;
  final String? lastModifiedAt;
  final String? deletedAt;
  final String assetType;
  final String title;
  final String alias;
  final bool hidden;
  final String currencyCode;
  final String value;
  final String change;
  final int iconCodePoint;
  final String quantityLabel;
  final String quantityValue;
  final String averageLabel;
  final String averageValue;
  final String note;
  final int sortOrder;
  const Asset({
    required this.id,
    this.clientId,
    required this.dirty,
    this.lastModifiedAt,
    this.deletedAt,
    required this.assetType,
    required this.title,
    required this.alias,
    required this.hidden,
    required this.currencyCode,
    required this.value,
    required this.change,
    required this.iconCodePoint,
    required this.quantityLabel,
    required this.quantityValue,
    required this.averageLabel,
    required this.averageValue,
    required this.note,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['dirty'] = Variable<bool>(dirty);
    if (!nullToAbsent || lastModifiedAt != null) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['asset_type'] = Variable<String>(assetType);
    map['title'] = Variable<String>(title);
    map['alias'] = Variable<String>(alias);
    map['hidden'] = Variable<bool>(hidden);
    map['currency_code'] = Variable<String>(currencyCode);
    map['value'] = Variable<String>(value);
    map['change'] = Variable<String>(change);
    map['icon_code_point'] = Variable<int>(iconCodePoint);
    map['quantity_label'] = Variable<String>(quantityLabel);
    map['quantity_value'] = Variable<String>(quantityValue);
    map['average_label'] = Variable<String>(averageLabel);
    map['average_value'] = Variable<String>(averageValue);
    map['note'] = Variable<String>(note);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      dirty: Value(dirty),
      lastModifiedAt: lastModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      assetType: Value(assetType),
      title: Value(title),
      alias: Value(alias),
      hidden: Value(hidden),
      currencyCode: Value(currencyCode),
      value: Value(value),
      change: Value(change),
      iconCodePoint: Value(iconCodePoint),
      quantityLabel: Value(quantityLabel),
      quantityValue: Value(quantityValue),
      averageLabel: Value(averageLabel),
      averageValue: Value(averageValue),
      note: Value(note),
      sortOrder: Value(sortOrder),
    );
  }

  factory Asset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Asset(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      lastModifiedAt: serializer.fromJson<String?>(json['lastModifiedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      assetType: serializer.fromJson<String>(json['assetType']),
      title: serializer.fromJson<String>(json['title']),
      alias: serializer.fromJson<String>(json['alias']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      value: serializer.fromJson<String>(json['value']),
      change: serializer.fromJson<String>(json['change']),
      iconCodePoint: serializer.fromJson<int>(json['iconCodePoint']),
      quantityLabel: serializer.fromJson<String>(json['quantityLabel']),
      quantityValue: serializer.fromJson<String>(json['quantityValue']),
      averageLabel: serializer.fromJson<String>(json['averageLabel']),
      averageValue: serializer.fromJson<String>(json['averageValue']),
      note: serializer.fromJson<String>(json['note']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<String?>(clientId),
      'dirty': serializer.toJson<bool>(dirty),
      'lastModifiedAt': serializer.toJson<String?>(lastModifiedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'assetType': serializer.toJson<String>(assetType),
      'title': serializer.toJson<String>(title),
      'alias': serializer.toJson<String>(alias),
      'hidden': serializer.toJson<bool>(hidden),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'value': serializer.toJson<String>(value),
      'change': serializer.toJson<String>(change),
      'iconCodePoint': serializer.toJson<int>(iconCodePoint),
      'quantityLabel': serializer.toJson<String>(quantityLabel),
      'quantityValue': serializer.toJson<String>(quantityValue),
      'averageLabel': serializer.toJson<String>(averageLabel),
      'averageValue': serializer.toJson<String>(averageValue),
      'note': serializer.toJson<String>(note),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Asset copyWith({
    int? id,
    Value<String?> clientId = const Value.absent(),
    bool? dirty,
    Value<String?> lastModifiedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
    String? assetType,
    String? title,
    String? alias,
    bool? hidden,
    String? currencyCode,
    String? value,
    String? change,
    int? iconCodePoint,
    String? quantityLabel,
    String? quantityValue,
    String? averageLabel,
    String? averageValue,
    String? note,
    int? sortOrder,
  }) => Asset(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    dirty: dirty ?? this.dirty,
    lastModifiedAt: lastModifiedAt.present
        ? lastModifiedAt.value
        : this.lastModifiedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    assetType: assetType ?? this.assetType,
    title: title ?? this.title,
    alias: alias ?? this.alias,
    hidden: hidden ?? this.hidden,
    currencyCode: currencyCode ?? this.currencyCode,
    value: value ?? this.value,
    change: change ?? this.change,
    iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    quantityLabel: quantityLabel ?? this.quantityLabel,
    quantityValue: quantityValue ?? this.quantityValue,
    averageLabel: averageLabel ?? this.averageLabel,
    averageValue: averageValue ?? this.averageValue,
    note: note ?? this.note,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      assetType: data.assetType.present ? data.assetType.value : this.assetType,
      title: data.title.present ? data.title.value : this.title,
      alias: data.alias.present ? data.alias.value : this.alias,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      value: data.value.present ? data.value.value : this.value,
      change: data.change.present ? data.change.value : this.change,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      quantityLabel: data.quantityLabel.present
          ? data.quantityLabel.value
          : this.quantityLabel,
      quantityValue: data.quantityValue.present
          ? data.quantityValue.value
          : this.quantityValue,
      averageLabel: data.averageLabel.present
          ? data.averageLabel.value
          : this.averageLabel,
      averageValue: data.averageValue.present
          ? data.averageValue.value
          : this.averageValue,
      note: data.note.present ? data.note.value : this.note,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('assetType: $assetType, ')
          ..write('title: $title, ')
          ..write('alias: $alias, ')
          ..write('hidden: $hidden, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('value: $value, ')
          ..write('change: $change, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('quantityLabel: $quantityLabel, ')
          ..write('quantityValue: $quantityValue, ')
          ..write('averageLabel: $averageLabel, ')
          ..write('averageValue: $averageValue, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    assetType,
    title,
    alias,
    hidden,
    currencyCode,
    value,
    change,
    iconCodePoint,
    quantityLabel,
    quantityValue,
    averageLabel,
    averageValue,
    note,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.dirty == this.dirty &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.deletedAt == this.deletedAt &&
          other.assetType == this.assetType &&
          other.title == this.title &&
          other.alias == this.alias &&
          other.hidden == this.hidden &&
          other.currencyCode == this.currencyCode &&
          other.value == this.value &&
          other.change == this.change &&
          other.iconCodePoint == this.iconCodePoint &&
          other.quantityLabel == this.quantityLabel &&
          other.quantityValue == this.quantityValue &&
          other.averageLabel == this.averageLabel &&
          other.averageValue == this.averageValue &&
          other.note == this.note &&
          other.sortOrder == this.sortOrder);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<int> id;
  final Value<String?> clientId;
  final Value<bool> dirty;
  final Value<String?> lastModifiedAt;
  final Value<String?> deletedAt;
  final Value<String> assetType;
  final Value<String> title;
  final Value<String> alias;
  final Value<bool> hidden;
  final Value<String> currencyCode;
  final Value<String> value;
  final Value<String> change;
  final Value<int> iconCodePoint;
  final Value<String> quantityLabel;
  final Value<String> quantityValue;
  final Value<String> averageLabel;
  final Value<String> averageValue;
  final Value<String> note;
  final Value<int> sortOrder;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.assetType = const Value.absent(),
    this.title = const Value.absent(),
    this.alias = const Value.absent(),
    this.hidden = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.value = const Value.absent(),
    this.change = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.quantityLabel = const Value.absent(),
    this.quantityValue = const Value.absent(),
    this.averageLabel = const Value.absent(),
    this.averageValue = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  AssetsCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.assetType = const Value.absent(),
    required String title,
    this.alias = const Value.absent(),
    this.hidden = const Value.absent(),
    this.currencyCode = const Value.absent(),
    required String value,
    required String change,
    required int iconCodePoint,
    required String quantityLabel,
    required String quantityValue,
    required String averageLabel,
    required String averageValue,
    required String note,
    required int sortOrder,
  }) : title = Value(title),
       value = Value(value),
       change = Value(change),
       iconCodePoint = Value(iconCodePoint),
       quantityLabel = Value(quantityLabel),
       quantityValue = Value(quantityValue),
       averageLabel = Value(averageLabel),
       averageValue = Value(averageValue),
       note = Value(note),
       sortOrder = Value(sortOrder);
  static Insertable<Asset> custom({
    Expression<int>? id,
    Expression<String>? clientId,
    Expression<bool>? dirty,
    Expression<String>? lastModifiedAt,
    Expression<String>? deletedAt,
    Expression<String>? assetType,
    Expression<String>? title,
    Expression<String>? alias,
    Expression<bool>? hidden,
    Expression<String>? currencyCode,
    Expression<String>? value,
    Expression<String>? change,
    Expression<int>? iconCodePoint,
    Expression<String>? quantityLabel,
    Expression<String>? quantityValue,
    Expression<String>? averageLabel,
    Expression<String>? averageValue,
    Expression<String>? note,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (dirty != null) 'dirty': dirty,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (assetType != null) 'asset_type': assetType,
      if (title != null) 'title': title,
      if (alias != null) 'alias': alias,
      if (hidden != null) 'hidden': hidden,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (value != null) 'value': value,
      if (change != null) 'change': change,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (quantityLabel != null) 'quantity_label': quantityLabel,
      if (quantityValue != null) 'quantity_value': quantityValue,
      if (averageLabel != null) 'average_label': averageLabel,
      if (averageValue != null) 'average_value': averageValue,
      if (note != null) 'note': note,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  AssetsCompanion copyWith({
    Value<int>? id,
    Value<String?>? clientId,
    Value<bool>? dirty,
    Value<String?>? lastModifiedAt,
    Value<String?>? deletedAt,
    Value<String>? assetType,
    Value<String>? title,
    Value<String>? alias,
    Value<bool>? hidden,
    Value<String>? currencyCode,
    Value<String>? value,
    Value<String>? change,
    Value<int>? iconCodePoint,
    Value<String>? quantityLabel,
    Value<String>? quantityValue,
    Value<String>? averageLabel,
    Value<String>? averageValue,
    Value<String>? note,
    Value<int>? sortOrder,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      dirty: dirty ?? this.dirty,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      assetType: assetType ?? this.assetType,
      title: title ?? this.title,
      alias: alias ?? this.alias,
      hidden: hidden ?? this.hidden,
      currencyCode: currencyCode ?? this.currencyCode,
      value: value ?? this.value,
      change: change ?? this.change,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      quantityLabel: quantityLabel ?? this.quantityLabel,
      quantityValue: quantityValue ?? this.quantityValue,
      averageLabel: averageLabel ?? this.averageLabel,
      averageValue: averageValue ?? this.averageValue,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (assetType.present) {
      map['asset_type'] = Variable<String>(assetType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (change.present) {
      map['change'] = Variable<String>(change.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (quantityLabel.present) {
      map['quantity_label'] = Variable<String>(quantityLabel.value);
    }
    if (quantityValue.present) {
      map['quantity_value'] = Variable<String>(quantityValue.value);
    }
    if (averageLabel.present) {
      map['average_label'] = Variable<String>(averageLabel.value);
    }
    if (averageValue.present) {
      map['average_value'] = Variable<String>(averageValue.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('assetType: $assetType, ')
          ..write('title: $title, ')
          ..write('alias: $alias, ')
          ..write('hidden: $hidden, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('value: $value, ')
          ..write('change: $change, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('quantityLabel: $quantityLabel, ')
          ..write('quantityValue: $quantityValue, ')
          ..write('averageLabel: $averageLabel, ')
          ..write('averageValue: $averageValue, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $HoldingsTable extends Holdings with TableInfo<$HoldingsTable, Holding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HoldingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assets (id)',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<String> lastModifiedAt = GeneratedColumn<String>(
    'last_modified_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KRW'),
  );
  static const VerificationMeta _marketUpdatedAtMeta = const VerificationMeta(
    'marketUpdatedAt',
  );
  @override
  late final GeneratedColumn<String> marketUpdatedAt = GeneratedColumn<String>(
    'market_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exchangeCodeMeta = const VerificationMeta(
    'exchangeCode',
  );
  @override
  late final GeneratedColumn<String> exchangeCode = GeneratedColumn<String>(
    'exchange_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averagePriceMeta = const VerificationMeta(
    'averagePrice',
  );
  @override
  late final GeneratedColumn<double> averagePrice = GeneratedColumn<double>(
    'average_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _averagePriceSourceMeta =
      const VerificationMeta('averagePriceSource');
  @override
  late final GeneratedColumn<double> averagePriceSource =
      GeneratedColumn<double>(
        'average_price_source',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _averagePriceKrwMeta = const VerificationMeta(
    'averagePriceKrw',
  );
  @override
  late final GeneratedColumn<double> averagePriceKrw = GeneratedColumn<double>(
    'average_price_krw',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _averagePurchaseFxRateMeta =
      const VerificationMeta('averagePurchaseFxRate');
  @override
  late final GeneratedColumn<double> averagePurchaseFxRate =
      GeneratedColumn<double>(
        'average_purchase_fx_rate',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      );
  static const VerificationMeta _costBasisKrwMeta = const VerificationMeta(
    'costBasisKrw',
  );
  @override
  late final GeneratedColumn<double> costBasisKrw = GeneratedColumn<double>(
    'cost_basis_krw',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentPriceMeta = const VerificationMeta(
    'currentPrice',
  );
  @override
  late final GeneratedColumn<double> currentPrice = GeneratedColumn<double>(
    'current_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    hidden,
    currencyCode,
    marketUpdatedAt,
    exchangeCode,
    name,
    symbol,
    quantity,
    averagePrice,
    averagePriceSource,
    averagePriceKrw,
    averagePurchaseFxRate,
    costBasisKrw,
    currentPrice,
    note,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'holdings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Holding> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('market_updated_at')) {
      context.handle(
        _marketUpdatedAtMeta,
        marketUpdatedAt.isAcceptableOrUnknown(
          data['market_updated_at']!,
          _marketUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('exchange_code')) {
      context.handle(
        _exchangeCodeMeta,
        exchangeCode.isAcceptableOrUnknown(
          data['exchange_code']!,
          _exchangeCodeMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('average_price')) {
      context.handle(
        _averagePriceMeta,
        averagePrice.isAcceptableOrUnknown(
          data['average_price']!,
          _averagePriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_averagePriceMeta);
    }
    if (data.containsKey('average_price_source')) {
      context.handle(
        _averagePriceSourceMeta,
        averagePriceSource.isAcceptableOrUnknown(
          data['average_price_source']!,
          _averagePriceSourceMeta,
        ),
      );
    }
    if (data.containsKey('average_price_krw')) {
      context.handle(
        _averagePriceKrwMeta,
        averagePriceKrw.isAcceptableOrUnknown(
          data['average_price_krw']!,
          _averagePriceKrwMeta,
        ),
      );
    }
    if (data.containsKey('average_purchase_fx_rate')) {
      context.handle(
        _averagePurchaseFxRateMeta,
        averagePurchaseFxRate.isAcceptableOrUnknown(
          data['average_purchase_fx_rate']!,
          _averagePurchaseFxRateMeta,
        ),
      );
    }
    if (data.containsKey('cost_basis_krw')) {
      context.handle(
        _costBasisKrwMeta,
        costBasisKrw.isAcceptableOrUnknown(
          data['cost_basis_krw']!,
          _costBasisKrwMeta,
        ),
      );
    }
    if (data.containsKey('current_price')) {
      context.handle(
        _currentPriceMeta,
        currentPrice.isAcceptableOrUnknown(
          data['current_price']!,
          _currentPriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentPriceMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Holding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Holding(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      marketUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}market_updated_at'],
      ),
      exchangeCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exchange_code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      averagePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_price'],
      )!,
      averagePriceSource: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_price_source'],
      )!,
      averagePriceKrw: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_price_krw'],
      )!,
      averagePurchaseFxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_purchase_fx_rate'],
      )!,
      costBasisKrw: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_basis_krw'],
      )!,
      currentPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_price'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $HoldingsTable createAlias(String alias) {
    return $HoldingsTable(attachedDatabase, alias);
  }
}

class Holding extends DataClass implements Insertable<Holding> {
  final int id;
  final int assetId;
  final String? clientId;
  final bool dirty;
  final String? lastModifiedAt;
  final String? deletedAt;
  final bool hidden;
  final String currencyCode;
  final String? marketUpdatedAt;
  final String exchangeCode;
  final String name;
  final String symbol;
  final double quantity;
  final double averagePrice;
  final double averagePriceSource;
  final double averagePriceKrw;
  final double averagePurchaseFxRate;
  final double costBasisKrw;
  final double currentPrice;
  final String note;
  final int sortOrder;
  const Holding({
    required this.id,
    required this.assetId,
    this.clientId,
    required this.dirty,
    this.lastModifiedAt,
    this.deletedAt,
    required this.hidden,
    required this.currencyCode,
    this.marketUpdatedAt,
    required this.exchangeCode,
    required this.name,
    required this.symbol,
    required this.quantity,
    required this.averagePrice,
    required this.averagePriceSource,
    required this.averagePriceKrw,
    required this.averagePurchaseFxRate,
    required this.costBasisKrw,
    required this.currentPrice,
    required this.note,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['asset_id'] = Variable<int>(assetId);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['dirty'] = Variable<bool>(dirty);
    if (!nullToAbsent || lastModifiedAt != null) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['hidden'] = Variable<bool>(hidden);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || marketUpdatedAt != null) {
      map['market_updated_at'] = Variable<String>(marketUpdatedAt);
    }
    map['exchange_code'] = Variable<String>(exchangeCode);
    map['name'] = Variable<String>(name);
    map['symbol'] = Variable<String>(symbol);
    map['quantity'] = Variable<double>(quantity);
    map['average_price'] = Variable<double>(averagePrice);
    map['average_price_source'] = Variable<double>(averagePriceSource);
    map['average_price_krw'] = Variable<double>(averagePriceKrw);
    map['average_purchase_fx_rate'] = Variable<double>(averagePurchaseFxRate);
    map['cost_basis_krw'] = Variable<double>(costBasisKrw);
    map['current_price'] = Variable<double>(currentPrice);
    map['note'] = Variable<String>(note);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  HoldingsCompanion toCompanion(bool nullToAbsent) {
    return HoldingsCompanion(
      id: Value(id),
      assetId: Value(assetId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      dirty: Value(dirty),
      lastModifiedAt: lastModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      hidden: Value(hidden),
      currencyCode: Value(currencyCode),
      marketUpdatedAt: marketUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(marketUpdatedAt),
      exchangeCode: Value(exchangeCode),
      name: Value(name),
      symbol: Value(symbol),
      quantity: Value(quantity),
      averagePrice: Value(averagePrice),
      averagePriceSource: Value(averagePriceSource),
      averagePriceKrw: Value(averagePriceKrw),
      averagePurchaseFxRate: Value(averagePurchaseFxRate),
      costBasisKrw: Value(costBasisKrw),
      currentPrice: Value(currentPrice),
      note: Value(note),
      sortOrder: Value(sortOrder),
    );
  }

  factory Holding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Holding(
      id: serializer.fromJson<int>(json['id']),
      assetId: serializer.fromJson<int>(json['assetId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      lastModifiedAt: serializer.fromJson<String?>(json['lastModifiedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      marketUpdatedAt: serializer.fromJson<String?>(json['marketUpdatedAt']),
      exchangeCode: serializer.fromJson<String>(json['exchangeCode']),
      name: serializer.fromJson<String>(json['name']),
      symbol: serializer.fromJson<String>(json['symbol']),
      quantity: serializer.fromJson<double>(json['quantity']),
      averagePrice: serializer.fromJson<double>(json['averagePrice']),
      averagePriceSource: serializer.fromJson<double>(
        json['averagePriceSource'],
      ),
      averagePriceKrw: serializer.fromJson<double>(json['averagePriceKrw']),
      averagePurchaseFxRate: serializer.fromJson<double>(
        json['averagePurchaseFxRate'],
      ),
      costBasisKrw: serializer.fromJson<double>(json['costBasisKrw']),
      currentPrice: serializer.fromJson<double>(json['currentPrice']),
      note: serializer.fromJson<String>(json['note']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetId': serializer.toJson<int>(assetId),
      'clientId': serializer.toJson<String?>(clientId),
      'dirty': serializer.toJson<bool>(dirty),
      'lastModifiedAt': serializer.toJson<String?>(lastModifiedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'hidden': serializer.toJson<bool>(hidden),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'marketUpdatedAt': serializer.toJson<String?>(marketUpdatedAt),
      'exchangeCode': serializer.toJson<String>(exchangeCode),
      'name': serializer.toJson<String>(name),
      'symbol': serializer.toJson<String>(symbol),
      'quantity': serializer.toJson<double>(quantity),
      'averagePrice': serializer.toJson<double>(averagePrice),
      'averagePriceSource': serializer.toJson<double>(averagePriceSource),
      'averagePriceKrw': serializer.toJson<double>(averagePriceKrw),
      'averagePurchaseFxRate': serializer.toJson<double>(averagePurchaseFxRate),
      'costBasisKrw': serializer.toJson<double>(costBasisKrw),
      'currentPrice': serializer.toJson<double>(currentPrice),
      'note': serializer.toJson<String>(note),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Holding copyWith({
    int? id,
    int? assetId,
    Value<String?> clientId = const Value.absent(),
    bool? dirty,
    Value<String?> lastModifiedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
    bool? hidden,
    String? currencyCode,
    Value<String?> marketUpdatedAt = const Value.absent(),
    String? exchangeCode,
    String? name,
    String? symbol,
    double? quantity,
    double? averagePrice,
    double? averagePriceSource,
    double? averagePriceKrw,
    double? averagePurchaseFxRate,
    double? costBasisKrw,
    double? currentPrice,
    String? note,
    int? sortOrder,
  }) => Holding(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    clientId: clientId.present ? clientId.value : this.clientId,
    dirty: dirty ?? this.dirty,
    lastModifiedAt: lastModifiedAt.present
        ? lastModifiedAt.value
        : this.lastModifiedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    hidden: hidden ?? this.hidden,
    currencyCode: currencyCode ?? this.currencyCode,
    marketUpdatedAt: marketUpdatedAt.present
        ? marketUpdatedAt.value
        : this.marketUpdatedAt,
    exchangeCode: exchangeCode ?? this.exchangeCode,
    name: name ?? this.name,
    symbol: symbol ?? this.symbol,
    quantity: quantity ?? this.quantity,
    averagePrice: averagePrice ?? this.averagePrice,
    averagePriceSource: averagePriceSource ?? this.averagePriceSource,
    averagePriceKrw: averagePriceKrw ?? this.averagePriceKrw,
    averagePurchaseFxRate: averagePurchaseFxRate ?? this.averagePurchaseFxRate,
    costBasisKrw: costBasisKrw ?? this.costBasisKrw,
    currentPrice: currentPrice ?? this.currentPrice,
    note: note ?? this.note,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Holding copyWithCompanion(HoldingsCompanion data) {
    return Holding(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      marketUpdatedAt: data.marketUpdatedAt.present
          ? data.marketUpdatedAt.value
          : this.marketUpdatedAt,
      exchangeCode: data.exchangeCode.present
          ? data.exchangeCode.value
          : this.exchangeCode,
      name: data.name.present ? data.name.value : this.name,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      averagePrice: data.averagePrice.present
          ? data.averagePrice.value
          : this.averagePrice,
      averagePriceSource: data.averagePriceSource.present
          ? data.averagePriceSource.value
          : this.averagePriceSource,
      averagePriceKrw: data.averagePriceKrw.present
          ? data.averagePriceKrw.value
          : this.averagePriceKrw,
      averagePurchaseFxRate: data.averagePurchaseFxRate.present
          ? data.averagePurchaseFxRate.value
          : this.averagePurchaseFxRate,
      costBasisKrw: data.costBasisKrw.present
          ? data.costBasisKrw.value
          : this.costBasisKrw,
      currentPrice: data.currentPrice.present
          ? data.currentPrice.value
          : this.currentPrice,
      note: data.note.present ? data.note.value : this.note,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Holding(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hidden: $hidden, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('marketUpdatedAt: $marketUpdatedAt, ')
          ..write('exchangeCode: $exchangeCode, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('quantity: $quantity, ')
          ..write('averagePrice: $averagePrice, ')
          ..write('averagePriceSource: $averagePriceSource, ')
          ..write('averagePriceKrw: $averagePriceKrw, ')
          ..write('averagePurchaseFxRate: $averagePurchaseFxRate, ')
          ..write('costBasisKrw: $costBasisKrw, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    assetId,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    hidden,
    currencyCode,
    marketUpdatedAt,
    exchangeCode,
    name,
    symbol,
    quantity,
    averagePrice,
    averagePriceSource,
    averagePriceKrw,
    averagePurchaseFxRate,
    costBasisKrw,
    currentPrice,
    note,
    sortOrder,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Holding &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.clientId == this.clientId &&
          other.dirty == this.dirty &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.deletedAt == this.deletedAt &&
          other.hidden == this.hidden &&
          other.currencyCode == this.currencyCode &&
          other.marketUpdatedAt == this.marketUpdatedAt &&
          other.exchangeCode == this.exchangeCode &&
          other.name == this.name &&
          other.symbol == this.symbol &&
          other.quantity == this.quantity &&
          other.averagePrice == this.averagePrice &&
          other.averagePriceSource == this.averagePriceSource &&
          other.averagePriceKrw == this.averagePriceKrw &&
          other.averagePurchaseFxRate == this.averagePurchaseFxRate &&
          other.costBasisKrw == this.costBasisKrw &&
          other.currentPrice == this.currentPrice &&
          other.note == this.note &&
          other.sortOrder == this.sortOrder);
}

class HoldingsCompanion extends UpdateCompanion<Holding> {
  final Value<int> id;
  final Value<int> assetId;
  final Value<String?> clientId;
  final Value<bool> dirty;
  final Value<String?> lastModifiedAt;
  final Value<String?> deletedAt;
  final Value<bool> hidden;
  final Value<String> currencyCode;
  final Value<String?> marketUpdatedAt;
  final Value<String> exchangeCode;
  final Value<String> name;
  final Value<String> symbol;
  final Value<double> quantity;
  final Value<double> averagePrice;
  final Value<double> averagePriceSource;
  final Value<double> averagePriceKrw;
  final Value<double> averagePurchaseFxRate;
  final Value<double> costBasisKrw;
  final Value<double> currentPrice;
  final Value<String> note;
  final Value<int> sortOrder;
  const HoldingsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hidden = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.marketUpdatedAt = const Value.absent(),
    this.exchangeCode = const Value.absent(),
    this.name = const Value.absent(),
    this.symbol = const Value.absent(),
    this.quantity = const Value.absent(),
    this.averagePrice = const Value.absent(),
    this.averagePriceSource = const Value.absent(),
    this.averagePriceKrw = const Value.absent(),
    this.averagePurchaseFxRate = const Value.absent(),
    this.costBasisKrw = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  HoldingsCompanion.insert({
    this.id = const Value.absent(),
    required int assetId,
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hidden = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.marketUpdatedAt = const Value.absent(),
    this.exchangeCode = const Value.absent(),
    required String name,
    required String symbol,
    required double quantity,
    required double averagePrice,
    this.averagePriceSource = const Value.absent(),
    this.averagePriceKrw = const Value.absent(),
    this.averagePurchaseFxRate = const Value.absent(),
    this.costBasisKrw = const Value.absent(),
    required double currentPrice,
    required String note,
    required int sortOrder,
  }) : assetId = Value(assetId),
       name = Value(name),
       symbol = Value(symbol),
       quantity = Value(quantity),
       averagePrice = Value(averagePrice),
       currentPrice = Value(currentPrice),
       note = Value(note),
       sortOrder = Value(sortOrder);
  static Insertable<Holding> custom({
    Expression<int>? id,
    Expression<int>? assetId,
    Expression<String>? clientId,
    Expression<bool>? dirty,
    Expression<String>? lastModifiedAt,
    Expression<String>? deletedAt,
    Expression<bool>? hidden,
    Expression<String>? currencyCode,
    Expression<String>? marketUpdatedAt,
    Expression<String>? exchangeCode,
    Expression<String>? name,
    Expression<String>? symbol,
    Expression<double>? quantity,
    Expression<double>? averagePrice,
    Expression<double>? averagePriceSource,
    Expression<double>? averagePriceKrw,
    Expression<double>? averagePurchaseFxRate,
    Expression<double>? costBasisKrw,
    Expression<double>? currentPrice,
    Expression<String>? note,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (clientId != null) 'client_id': clientId,
      if (dirty != null) 'dirty': dirty,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (hidden != null) 'hidden': hidden,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (marketUpdatedAt != null) 'market_updated_at': marketUpdatedAt,
      if (exchangeCode != null) 'exchange_code': exchangeCode,
      if (name != null) 'name': name,
      if (symbol != null) 'symbol': symbol,
      if (quantity != null) 'quantity': quantity,
      if (averagePrice != null) 'average_price': averagePrice,
      if (averagePriceSource != null)
        'average_price_source': averagePriceSource,
      if (averagePriceKrw != null) 'average_price_krw': averagePriceKrw,
      if (averagePurchaseFxRate != null)
        'average_purchase_fx_rate': averagePurchaseFxRate,
      if (costBasisKrw != null) 'cost_basis_krw': costBasisKrw,
      if (currentPrice != null) 'current_price': currentPrice,
      if (note != null) 'note': note,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  HoldingsCompanion copyWith({
    Value<int>? id,
    Value<int>? assetId,
    Value<String?>? clientId,
    Value<bool>? dirty,
    Value<String?>? lastModifiedAt,
    Value<String?>? deletedAt,
    Value<bool>? hidden,
    Value<String>? currencyCode,
    Value<String?>? marketUpdatedAt,
    Value<String>? exchangeCode,
    Value<String>? name,
    Value<String>? symbol,
    Value<double>? quantity,
    Value<double>? averagePrice,
    Value<double>? averagePriceSource,
    Value<double>? averagePriceKrw,
    Value<double>? averagePurchaseFxRate,
    Value<double>? costBasisKrw,
    Value<double>? currentPrice,
    Value<String>? note,
    Value<int>? sortOrder,
  }) {
    return HoldingsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      clientId: clientId ?? this.clientId,
      dirty: dirty ?? this.dirty,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      hidden: hidden ?? this.hidden,
      currencyCode: currencyCode ?? this.currencyCode,
      marketUpdatedAt: marketUpdatedAt ?? this.marketUpdatedAt,
      exchangeCode: exchangeCode ?? this.exchangeCode,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      averagePrice: averagePrice ?? this.averagePrice,
      averagePriceSource: averagePriceSource ?? this.averagePriceSource,
      averagePriceKrw: averagePriceKrw ?? this.averagePriceKrw,
      averagePurchaseFxRate:
          averagePurchaseFxRate ?? this.averagePurchaseFxRate,
      costBasisKrw: costBasisKrw ?? this.costBasisKrw,
      currentPrice: currentPrice ?? this.currentPrice,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (marketUpdatedAt.present) {
      map['market_updated_at'] = Variable<String>(marketUpdatedAt.value);
    }
    if (exchangeCode.present) {
      map['exchange_code'] = Variable<String>(exchangeCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (averagePrice.present) {
      map['average_price'] = Variable<double>(averagePrice.value);
    }
    if (averagePriceSource.present) {
      map['average_price_source'] = Variable<double>(averagePriceSource.value);
    }
    if (averagePriceKrw.present) {
      map['average_price_krw'] = Variable<double>(averagePriceKrw.value);
    }
    if (averagePurchaseFxRate.present) {
      map['average_purchase_fx_rate'] = Variable<double>(
        averagePurchaseFxRate.value,
      );
    }
    if (costBasisKrw.present) {
      map['cost_basis_krw'] = Variable<double>(costBasisKrw.value);
    }
    if (currentPrice.present) {
      map['current_price'] = Variable<double>(currentPrice.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HoldingsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hidden: $hidden, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('marketUpdatedAt: $marketUpdatedAt, ')
          ..write('exchangeCode: $exchangeCode, ')
          ..write('name: $name, ')
          ..write('symbol: $symbol, ')
          ..write('quantity: $quantity, ')
          ..write('averagePrice: $averagePrice, ')
          ..write('averagePriceSource: $averagePriceSource, ')
          ..write('averagePriceKrw: $averagePriceKrw, ')
          ..write('averagePurchaseFxRate: $averagePurchaseFxRate, ')
          ..write('costBasisKrw: $costBasisKrw, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assets (id)',
    ),
  );
  static const VerificationMeta _holdingIdMeta = const VerificationMeta(
    'holdingId',
  );
  @override
  late final GeneratedColumn<int> holdingId = GeneratedColumn<int>(
    'holding_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES holdings (id)',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<String> lastModifiedAt = GeneratedColumn<String>(
    'last_modified_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _quantityValueMeta = const VerificationMeta(
    'quantityValue',
  );
  @override
  late final GeneratedColumn<double> quantityValue = GeneratedColumn<double>(
    'quantity_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _grossAmountMeta = const VerificationMeta(
    'grossAmount',
  );
  @override
  late final GeneratedColumn<double> grossAmount = GeneratedColumn<double>(
    'gross_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cashFlowAmountMeta = const VerificationMeta(
    'cashFlowAmount',
  );
  @override
  late final GeneratedColumn<double> cashFlowAmount = GeneratedColumn<double>(
    'cash_flow_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _realizedProfitAmountMeta =
      const VerificationMeta('realizedProfitAmount');
  @override
  late final GeneratedColumn<double> realizedProfitAmount =
      GeneratedColumn<double>(
        'realized_profit_amount',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    holdingId,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    date,
    type,
    name,
    amount,
    quantity,
    unitPrice,
    quantityValue,
    grossAmount,
    cashFlowAmount,
    realizedProfitAmount,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    if (data.containsKey('holding_id')) {
      context.handle(
        _holdingIdMeta,
        holdingId.isAcceptableOrUnknown(data['holding_id']!, _holdingIdMeta),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('quantity_value')) {
      context.handle(
        _quantityValueMeta,
        quantityValue.isAcceptableOrUnknown(
          data['quantity_value']!,
          _quantityValueMeta,
        ),
      );
    }
    if (data.containsKey('gross_amount')) {
      context.handle(
        _grossAmountMeta,
        grossAmount.isAcceptableOrUnknown(
          data['gross_amount']!,
          _grossAmountMeta,
        ),
      );
    }
    if (data.containsKey('cash_flow_amount')) {
      context.handle(
        _cashFlowAmountMeta,
        cashFlowAmount.isAcceptableOrUnknown(
          data['cash_flow_amount']!,
          _cashFlowAmountMeta,
        ),
      );
    }
    if (data.containsKey('realized_profit_amount')) {
      context.handle(
        _realizedProfitAmountMeta,
        realizedProfitAmount.isAcceptableOrUnknown(
          data['realized_profit_amount']!,
          _realizedProfitAmountMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      ),
      holdingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}holding_id'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      quantityValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_value'],
      )!,
      grossAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gross_amount'],
      )!,
      cashFlowAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_flow_amount'],
      )!,
      realizedProfitAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}realized_profit_amount'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final int? assetId;
  final int? holdingId;
  final String? clientId;
  final bool dirty;
  final String? lastModifiedAt;
  final String? deletedAt;
  final String date;
  final String type;
  final String name;
  final String amount;
  final String quantity;
  final double unitPrice;
  final double quantityValue;
  final double grossAmount;
  final double cashFlowAmount;
  final double realizedProfitAmount;
  final int sortOrder;
  const Transaction({
    required this.id,
    this.assetId,
    this.holdingId,
    this.clientId,
    required this.dirty,
    this.lastModifiedAt,
    this.deletedAt,
    required this.date,
    required this.type,
    required this.name,
    required this.amount,
    required this.quantity,
    required this.unitPrice,
    required this.quantityValue,
    required this.grossAmount,
    required this.cashFlowAmount,
    required this.realizedProfitAmount,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<int>(assetId);
    }
    if (!nullToAbsent || holdingId != null) {
      map['holding_id'] = Variable<int>(holdingId);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['dirty'] = Variable<bool>(dirty);
    if (!nullToAbsent || lastModifiedAt != null) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['date'] = Variable<String>(date);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<String>(amount);
    map['quantity'] = Variable<String>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['quantity_value'] = Variable<double>(quantityValue);
    map['gross_amount'] = Variable<double>(grossAmount);
    map['cash_flow_amount'] = Variable<double>(cashFlowAmount);
    map['realized_profit_amount'] = Variable<double>(realizedProfitAmount);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      holdingId: holdingId == null && nullToAbsent
          ? const Value.absent()
          : Value(holdingId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      dirty: Value(dirty),
      lastModifiedAt: lastModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      date: Value(date),
      type: Value(type),
      name: Value(name),
      amount: Value(amount),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      quantityValue: Value(quantityValue),
      grossAmount: Value(grossAmount),
      cashFlowAmount: Value(cashFlowAmount),
      realizedProfitAmount: Value(realizedProfitAmount),
      sortOrder: Value(sortOrder),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      assetId: serializer.fromJson<int?>(json['assetId']),
      holdingId: serializer.fromJson<int?>(json['holdingId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      lastModifiedAt: serializer.fromJson<String?>(json['lastModifiedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      date: serializer.fromJson<String>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<String>(json['amount']),
      quantity: serializer.fromJson<String>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      quantityValue: serializer.fromJson<double>(json['quantityValue']),
      grossAmount: serializer.fromJson<double>(json['grossAmount']),
      cashFlowAmount: serializer.fromJson<double>(json['cashFlowAmount']),
      realizedProfitAmount: serializer.fromJson<double>(
        json['realizedProfitAmount'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetId': serializer.toJson<int?>(assetId),
      'holdingId': serializer.toJson<int?>(holdingId),
      'clientId': serializer.toJson<String?>(clientId),
      'dirty': serializer.toJson<bool>(dirty),
      'lastModifiedAt': serializer.toJson<String?>(lastModifiedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'date': serializer.toJson<String>(date),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<String>(amount),
      'quantity': serializer.toJson<String>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'quantityValue': serializer.toJson<double>(quantityValue),
      'grossAmount': serializer.toJson<double>(grossAmount),
      'cashFlowAmount': serializer.toJson<double>(cashFlowAmount),
      'realizedProfitAmount': serializer.toJson<double>(realizedProfitAmount),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Transaction copyWith({
    int? id,
    Value<int?> assetId = const Value.absent(),
    Value<int?> holdingId = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    bool? dirty,
    Value<String?> lastModifiedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
    String? date,
    String? type,
    String? name,
    String? amount,
    String? quantity,
    double? unitPrice,
    double? quantityValue,
    double? grossAmount,
    double? cashFlowAmount,
    double? realizedProfitAmount,
    int? sortOrder,
  }) => Transaction(
    id: id ?? this.id,
    assetId: assetId.present ? assetId.value : this.assetId,
    holdingId: holdingId.present ? holdingId.value : this.holdingId,
    clientId: clientId.present ? clientId.value : this.clientId,
    dirty: dirty ?? this.dirty,
    lastModifiedAt: lastModifiedAt.present
        ? lastModifiedAt.value
        : this.lastModifiedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    date: date ?? this.date,
    type: type ?? this.type,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    quantityValue: quantityValue ?? this.quantityValue,
    grossAmount: grossAmount ?? this.grossAmount,
    cashFlowAmount: cashFlowAmount ?? this.cashFlowAmount,
    realizedProfitAmount: realizedProfitAmount ?? this.realizedProfitAmount,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      holdingId: data.holdingId.present ? data.holdingId.value : this.holdingId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      quantityValue: data.quantityValue.present
          ? data.quantityValue.value
          : this.quantityValue,
      grossAmount: data.grossAmount.present
          ? data.grossAmount.value
          : this.grossAmount,
      cashFlowAmount: data.cashFlowAmount.present
          ? data.cashFlowAmount.value
          : this.cashFlowAmount,
      realizedProfitAmount: data.realizedProfitAmount.present
          ? data.realizedProfitAmount.value
          : this.realizedProfitAmount,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('holdingId: $holdingId, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('quantityValue: $quantityValue, ')
          ..write('grossAmount: $grossAmount, ')
          ..write('cashFlowAmount: $cashFlowAmount, ')
          ..write('realizedProfitAmount: $realizedProfitAmount, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    holdingId,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    date,
    type,
    name,
    amount,
    quantity,
    unitPrice,
    quantityValue,
    grossAmount,
    cashFlowAmount,
    realizedProfitAmount,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.holdingId == this.holdingId &&
          other.clientId == this.clientId &&
          other.dirty == this.dirty &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.deletedAt == this.deletedAt &&
          other.date == this.date &&
          other.type == this.type &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.quantityValue == this.quantityValue &&
          other.grossAmount == this.grossAmount &&
          other.cashFlowAmount == this.cashFlowAmount &&
          other.realizedProfitAmount == this.realizedProfitAmount &&
          other.sortOrder == this.sortOrder);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<int?> assetId;
  final Value<int?> holdingId;
  final Value<String?> clientId;
  final Value<bool> dirty;
  final Value<String?> lastModifiedAt;
  final Value<String?> deletedAt;
  final Value<String> date;
  final Value<String> type;
  final Value<String> name;
  final Value<String> amount;
  final Value<String> quantity;
  final Value<double> unitPrice;
  final Value<double> quantityValue;
  final Value<double> grossAmount;
  final Value<double> cashFlowAmount;
  final Value<double> realizedProfitAmount;
  final Value<int> sortOrder;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.holdingId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.quantityValue = const Value.absent(),
    this.grossAmount = const Value.absent(),
    this.cashFlowAmount = const Value.absent(),
    this.realizedProfitAmount = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.holdingId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String date,
    required String type,
    required String name,
    required String amount,
    required String quantity,
    this.unitPrice = const Value.absent(),
    this.quantityValue = const Value.absent(),
    this.grossAmount = const Value.absent(),
    this.cashFlowAmount = const Value.absent(),
    this.realizedProfitAmount = const Value.absent(),
    required int sortOrder,
  }) : date = Value(date),
       type = Value(type),
       name = Value(name),
       amount = Value(amount),
       quantity = Value(quantity),
       sortOrder = Value(sortOrder);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<int>? assetId,
    Expression<int>? holdingId,
    Expression<String>? clientId,
    Expression<bool>? dirty,
    Expression<String>? lastModifiedAt,
    Expression<String>? deletedAt,
    Expression<String>? date,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? amount,
    Expression<String>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? quantityValue,
    Expression<double>? grossAmount,
    Expression<double>? cashFlowAmount,
    Expression<double>? realizedProfitAmount,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (holdingId != null) 'holding_id': holdingId,
      if (clientId != null) 'client_id': clientId,
      if (dirty != null) 'dirty': dirty,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (quantityValue != null) 'quantity_value': quantityValue,
      if (grossAmount != null) 'gross_amount': grossAmount,
      if (cashFlowAmount != null) 'cash_flow_amount': cashFlowAmount,
      if (realizedProfitAmount != null)
        'realized_profit_amount': realizedProfitAmount,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? assetId,
    Value<int?>? holdingId,
    Value<String?>? clientId,
    Value<bool>? dirty,
    Value<String?>? lastModifiedAt,
    Value<String?>? deletedAt,
    Value<String>? date,
    Value<String>? type,
    Value<String>? name,
    Value<String>? amount,
    Value<String>? quantity,
    Value<double>? unitPrice,
    Value<double>? quantityValue,
    Value<double>? grossAmount,
    Value<double>? cashFlowAmount,
    Value<double>? realizedProfitAmount,
    Value<int>? sortOrder,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      holdingId: holdingId ?? this.holdingId,
      clientId: clientId ?? this.clientId,
      dirty: dirty ?? this.dirty,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      date: date ?? this.date,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      quantityValue: quantityValue ?? this.quantityValue,
      grossAmount: grossAmount ?? this.grossAmount,
      cashFlowAmount: cashFlowAmount ?? this.cashFlowAmount,
      realizedProfitAmount: realizedProfitAmount ?? this.realizedProfitAmount,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (holdingId.present) {
      map['holding_id'] = Variable<int>(holdingId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (quantityValue.present) {
      map['quantity_value'] = Variable<double>(quantityValue.value);
    }
    if (grossAmount.present) {
      map['gross_amount'] = Variable<double>(grossAmount.value);
    }
    if (cashFlowAmount.present) {
      map['cash_flow_amount'] = Variable<double>(cashFlowAmount.value);
    }
    if (realizedProfitAmount.present) {
      map['realized_profit_amount'] = Variable<double>(
        realizedProfitAmount.value,
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('holdingId: $holdingId, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('quantityValue: $quantityValue, ')
          ..write('grossAmount: $grossAmount, ')
          ..write('cashFlowAmount: $cashFlowAmount, ')
          ..write('realizedProfitAmount: $realizedProfitAmount, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $CashAccountsTable extends CashAccounts
    with TableInfo<$CashAccountsTable, CashAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashAccountsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assets (id)',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<String> lastModifiedAt = GeneratedColumn<String>(
    'last_modified_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KRW'),
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
  static const VerificationMeta _baseBalanceMeta = const VerificationMeta(
    'baseBalance',
  );
  @override
  late final GeneratedColumn<double> baseBalance = GeneratedColumn<double>(
    'base_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    hidden,
    currencyCode,
    name,
    baseBalance,
    balance,
    note,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_balance')) {
      context.handle(
        _baseBalanceMeta,
        baseBalance.isAcceptableOrUnknown(
          data['base_balance']!,
          _baseBalanceMeta,
        ),
      );
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_balance'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CashAccountsTable createAlias(String alias) {
    return $CashAccountsTable(attachedDatabase, alias);
  }
}

class CashAccount extends DataClass implements Insertable<CashAccount> {
  final int id;
  final int assetId;
  final String? clientId;
  final bool dirty;
  final String? lastModifiedAt;
  final String? deletedAt;
  final bool hidden;
  final String currencyCode;
  final String name;
  final double baseBalance;
  final double balance;
  final String note;
  final int sortOrder;
  const CashAccount({
    required this.id,
    required this.assetId,
    this.clientId,
    required this.dirty,
    this.lastModifiedAt,
    this.deletedAt,
    required this.hidden,
    required this.currencyCode,
    required this.name,
    required this.baseBalance,
    required this.balance,
    required this.note,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['asset_id'] = Variable<int>(assetId);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['dirty'] = Variable<bool>(dirty);
    if (!nullToAbsent || lastModifiedAt != null) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['hidden'] = Variable<bool>(hidden);
    map['currency_code'] = Variable<String>(currencyCode);
    map['name'] = Variable<String>(name);
    map['base_balance'] = Variable<double>(baseBalance);
    map['balance'] = Variable<double>(balance);
    map['note'] = Variable<String>(note);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CashAccountsCompanion toCompanion(bool nullToAbsent) {
    return CashAccountsCompanion(
      id: Value(id),
      assetId: Value(assetId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      dirty: Value(dirty),
      lastModifiedAt: lastModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      hidden: Value(hidden),
      currencyCode: Value(currencyCode),
      name: Value(name),
      baseBalance: Value(baseBalance),
      balance: Value(balance),
      note: Value(note),
      sortOrder: Value(sortOrder),
    );
  }

  factory CashAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashAccount(
      id: serializer.fromJson<int>(json['id']),
      assetId: serializer.fromJson<int>(json['assetId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      lastModifiedAt: serializer.fromJson<String?>(json['lastModifiedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      name: serializer.fromJson<String>(json['name']),
      baseBalance: serializer.fromJson<double>(json['baseBalance']),
      balance: serializer.fromJson<double>(json['balance']),
      note: serializer.fromJson<String>(json['note']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetId': serializer.toJson<int>(assetId),
      'clientId': serializer.toJson<String?>(clientId),
      'dirty': serializer.toJson<bool>(dirty),
      'lastModifiedAt': serializer.toJson<String?>(lastModifiedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'hidden': serializer.toJson<bool>(hidden),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'name': serializer.toJson<String>(name),
      'baseBalance': serializer.toJson<double>(baseBalance),
      'balance': serializer.toJson<double>(balance),
      'note': serializer.toJson<String>(note),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CashAccount copyWith({
    int? id,
    int? assetId,
    Value<String?> clientId = const Value.absent(),
    bool? dirty,
    Value<String?> lastModifiedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
    bool? hidden,
    String? currencyCode,
    String? name,
    double? baseBalance,
    double? balance,
    String? note,
    int? sortOrder,
  }) => CashAccount(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    clientId: clientId.present ? clientId.value : this.clientId,
    dirty: dirty ?? this.dirty,
    lastModifiedAt: lastModifiedAt.present
        ? lastModifiedAt.value
        : this.lastModifiedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    hidden: hidden ?? this.hidden,
    currencyCode: currencyCode ?? this.currencyCode,
    name: name ?? this.name,
    baseBalance: baseBalance ?? this.baseBalance,
    balance: balance ?? this.balance,
    note: note ?? this.note,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CashAccount copyWithCompanion(CashAccountsCompanion data) {
    return CashAccount(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      name: data.name.present ? data.name.value : this.name,
      baseBalance: data.baseBalance.present
          ? data.baseBalance.value
          : this.baseBalance,
      balance: data.balance.present ? data.balance.value : this.balance,
      note: data.note.present ? data.note.value : this.note,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashAccount(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hidden: $hidden, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('name: $name, ')
          ..write('baseBalance: $baseBalance, ')
          ..write('balance: $balance, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    hidden,
    currencyCode,
    name,
    baseBalance,
    balance,
    note,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashAccount &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.clientId == this.clientId &&
          other.dirty == this.dirty &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.deletedAt == this.deletedAt &&
          other.hidden == this.hidden &&
          other.currencyCode == this.currencyCode &&
          other.name == this.name &&
          other.baseBalance == this.baseBalance &&
          other.balance == this.balance &&
          other.note == this.note &&
          other.sortOrder == this.sortOrder);
}

class CashAccountsCompanion extends UpdateCompanion<CashAccount> {
  final Value<int> id;
  final Value<int> assetId;
  final Value<String?> clientId;
  final Value<bool> dirty;
  final Value<String?> lastModifiedAt;
  final Value<String?> deletedAt;
  final Value<bool> hidden;
  final Value<String> currencyCode;
  final Value<String> name;
  final Value<double> baseBalance;
  final Value<double> balance;
  final Value<String> note;
  final Value<int> sortOrder;
  const CashAccountsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hidden = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.name = const Value.absent(),
    this.baseBalance = const Value.absent(),
    this.balance = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CashAccountsCompanion.insert({
    this.id = const Value.absent(),
    required int assetId,
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.hidden = const Value.absent(),
    this.currencyCode = const Value.absent(),
    required String name,
    this.baseBalance = const Value.absent(),
    this.balance = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : assetId = Value(assetId),
       name = Value(name);
  static Insertable<CashAccount> custom({
    Expression<int>? id,
    Expression<int>? assetId,
    Expression<String>? clientId,
    Expression<bool>? dirty,
    Expression<String>? lastModifiedAt,
    Expression<String>? deletedAt,
    Expression<bool>? hidden,
    Expression<String>? currencyCode,
    Expression<String>? name,
    Expression<double>? baseBalance,
    Expression<double>? balance,
    Expression<String>? note,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (clientId != null) 'client_id': clientId,
      if (dirty != null) 'dirty': dirty,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (hidden != null) 'hidden': hidden,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (name != null) 'name': name,
      if (baseBalance != null) 'base_balance': baseBalance,
      if (balance != null) 'balance': balance,
      if (note != null) 'note': note,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CashAccountsCompanion copyWith({
    Value<int>? id,
    Value<int>? assetId,
    Value<String?>? clientId,
    Value<bool>? dirty,
    Value<String?>? lastModifiedAt,
    Value<String?>? deletedAt,
    Value<bool>? hidden,
    Value<String>? currencyCode,
    Value<String>? name,
    Value<double>? baseBalance,
    Value<double>? balance,
    Value<String>? note,
    Value<int>? sortOrder,
  }) {
    return CashAccountsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      clientId: clientId ?? this.clientId,
      dirty: dirty ?? this.dirty,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      hidden: hidden ?? this.hidden,
      currencyCode: currencyCode ?? this.currencyCode,
      name: name ?? this.name,
      baseBalance: baseBalance ?? this.baseBalance,
      balance: balance ?? this.balance,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseBalance.present) {
      map['base_balance'] = Variable<double>(baseBalance.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashAccountsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('hidden: $hidden, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('name: $name, ')
          ..write('baseBalance: $baseBalance, ')
          ..write('balance: $balance, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $CashTransactionsTable extends CashTransactions
    with TableInfo<$CashTransactionsTable, CashTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashTransactionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assets (id)',
    ),
  );
  static const VerificationMeta _cashAccountIdMeta = const VerificationMeta(
    'cashAccountId',
  );
  @override
  late final GeneratedColumn<int> cashAccountId = GeneratedColumn<int>(
    'cash_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cash_accounts (id)',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<String> lastModifiedAt = GeneratedColumn<String>(
    'last_modified_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedTransactionIdMeta =
      const VerificationMeta('linkedTransactionId');
  @override
  late final GeneratedColumn<int> linkedTransactionId = GeneratedColumn<int>(
    'linked_transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<String> amount = GeneratedColumn<String>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountValueMeta = const VerificationMeta(
    'amountValue',
  );
  @override
  late final GeneratedColumn<double> amountValue = GeneratedColumn<double>(
    'amount_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cashFlowAmountMeta = const VerificationMeta(
    'cashFlowAmount',
  );
  @override
  late final GeneratedColumn<double> cashFlowAmount = GeneratedColumn<double>(
    'cash_flow_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    cashAccountId,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    linkedTransactionId,
    date,
    type,
    name,
    amount,
    amountValue,
    cashFlowAmount,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('cash_account_id')) {
      context.handle(
        _cashAccountIdMeta,
        cashAccountId.isAcceptableOrUnknown(
          data['cash_account_id']!,
          _cashAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cashAccountIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('linked_transaction_id')) {
      context.handle(
        _linkedTransactionIdMeta,
        linkedTransactionId.isAcceptableOrUnknown(
          data['linked_transaction_id']!,
          _linkedTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('amount_value')) {
      context.handle(
        _amountValueMeta,
        amountValue.isAcceptableOrUnknown(
          data['amount_value']!,
          _amountValueMeta,
        ),
      );
    }
    if (data.containsKey('cash_flow_amount')) {
      context.handle(
        _cashFlowAmountMeta,
        cashFlowAmount.isAcceptableOrUnknown(
          data['cash_flow_amount']!,
          _cashFlowAmountMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      )!,
      cashAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_account_id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      linkedTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}linked_transaction_id'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount'],
      )!,
      amountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_value'],
      )!,
      cashFlowAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_flow_amount'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CashTransactionsTable createAlias(String alias) {
    return $CashTransactionsTable(attachedDatabase, alias);
  }
}

class CashTransaction extends DataClass implements Insertable<CashTransaction> {
  final int id;
  final int assetId;
  final int cashAccountId;
  final String? clientId;
  final bool dirty;
  final String? lastModifiedAt;
  final String? deletedAt;
  final int? linkedTransactionId;
  final String date;
  final String type;
  final String name;
  final String amount;
  final double amountValue;
  final double cashFlowAmount;
  final int sortOrder;
  const CashTransaction({
    required this.id,
    required this.assetId,
    required this.cashAccountId,
    this.clientId,
    required this.dirty,
    this.lastModifiedAt,
    this.deletedAt,
    this.linkedTransactionId,
    required this.date,
    required this.type,
    required this.name,
    required this.amount,
    required this.amountValue,
    required this.cashFlowAmount,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['asset_id'] = Variable<int>(assetId);
    map['cash_account_id'] = Variable<int>(cashAccountId);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['dirty'] = Variable<bool>(dirty);
    if (!nullToAbsent || lastModifiedAt != null) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    if (!nullToAbsent || linkedTransactionId != null) {
      map['linked_transaction_id'] = Variable<int>(linkedTransactionId);
    }
    map['date'] = Variable<String>(date);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<String>(amount);
    map['amount_value'] = Variable<double>(amountValue);
    map['cash_flow_amount'] = Variable<double>(cashFlowAmount);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CashTransactionsCompanion toCompanion(bool nullToAbsent) {
    return CashTransactionsCompanion(
      id: Value(id),
      assetId: Value(assetId),
      cashAccountId: Value(cashAccountId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      dirty: Value(dirty),
      lastModifiedAt: lastModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      linkedTransactionId: linkedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTransactionId),
      date: Value(date),
      type: Value(type),
      name: Value(name),
      amount: Value(amount),
      amountValue: Value(amountValue),
      cashFlowAmount: Value(cashFlowAmount),
      sortOrder: Value(sortOrder),
    );
  }

  factory CashTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashTransaction(
      id: serializer.fromJson<int>(json['id']),
      assetId: serializer.fromJson<int>(json['assetId']),
      cashAccountId: serializer.fromJson<int>(json['cashAccountId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      lastModifiedAt: serializer.fromJson<String?>(json['lastModifiedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      linkedTransactionId: serializer.fromJson<int?>(
        json['linkedTransactionId'],
      ),
      date: serializer.fromJson<String>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<String>(json['amount']),
      amountValue: serializer.fromJson<double>(json['amountValue']),
      cashFlowAmount: serializer.fromJson<double>(json['cashFlowAmount']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetId': serializer.toJson<int>(assetId),
      'cashAccountId': serializer.toJson<int>(cashAccountId),
      'clientId': serializer.toJson<String?>(clientId),
      'dirty': serializer.toJson<bool>(dirty),
      'lastModifiedAt': serializer.toJson<String?>(lastModifiedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'linkedTransactionId': serializer.toJson<int?>(linkedTransactionId),
      'date': serializer.toJson<String>(date),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<String>(amount),
      'amountValue': serializer.toJson<double>(amountValue),
      'cashFlowAmount': serializer.toJson<double>(cashFlowAmount),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CashTransaction copyWith({
    int? id,
    int? assetId,
    int? cashAccountId,
    Value<String?> clientId = const Value.absent(),
    bool? dirty,
    Value<String?> lastModifiedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
    Value<int?> linkedTransactionId = const Value.absent(),
    String? date,
    String? type,
    String? name,
    String? amount,
    double? amountValue,
    double? cashFlowAmount,
    int? sortOrder,
  }) => CashTransaction(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    cashAccountId: cashAccountId ?? this.cashAccountId,
    clientId: clientId.present ? clientId.value : this.clientId,
    dirty: dirty ?? this.dirty,
    lastModifiedAt: lastModifiedAt.present
        ? lastModifiedAt.value
        : this.lastModifiedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    linkedTransactionId: linkedTransactionId.present
        ? linkedTransactionId.value
        : this.linkedTransactionId,
    date: date ?? this.date,
    type: type ?? this.type,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    amountValue: amountValue ?? this.amountValue,
    cashFlowAmount: cashFlowAmount ?? this.cashFlowAmount,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CashTransaction copyWithCompanion(CashTransactionsCompanion data) {
    return CashTransaction(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      cashAccountId: data.cashAccountId.present
          ? data.cashAccountId.value
          : this.cashAccountId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      linkedTransactionId: data.linkedTransactionId.present
          ? data.linkedTransactionId.value
          : this.linkedTransactionId,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      amountValue: data.amountValue.present
          ? data.amountValue.value
          : this.amountValue,
      cashFlowAmount: data.cashFlowAmount.present
          ? data.cashFlowAmount.value
          : this.cashFlowAmount,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashTransaction(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('cashAccountId: $cashAccountId, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('amountValue: $amountValue, ')
          ..write('cashFlowAmount: $cashFlowAmount, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    cashAccountId,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    linkedTransactionId,
    date,
    type,
    name,
    amount,
    amountValue,
    cashFlowAmount,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashTransaction &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.cashAccountId == this.cashAccountId &&
          other.clientId == this.clientId &&
          other.dirty == this.dirty &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.deletedAt == this.deletedAt &&
          other.linkedTransactionId == this.linkedTransactionId &&
          other.date == this.date &&
          other.type == this.type &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.amountValue == this.amountValue &&
          other.cashFlowAmount == this.cashFlowAmount &&
          other.sortOrder == this.sortOrder);
}

class CashTransactionsCompanion extends UpdateCompanion<CashTransaction> {
  final Value<int> id;
  final Value<int> assetId;
  final Value<int> cashAccountId;
  final Value<String?> clientId;
  final Value<bool> dirty;
  final Value<String?> lastModifiedAt;
  final Value<String?> deletedAt;
  final Value<int?> linkedTransactionId;
  final Value<String> date;
  final Value<String> type;
  final Value<String> name;
  final Value<String> amount;
  final Value<double> amountValue;
  final Value<double> cashFlowAmount;
  final Value<int> sortOrder;
  const CashTransactionsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.cashAccountId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.amountValue = const Value.absent(),
    this.cashFlowAmount = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CashTransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int assetId,
    required int cashAccountId,
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    required String date,
    required String type,
    required String name,
    required String amount,
    this.amountValue = const Value.absent(),
    this.cashFlowAmount = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : assetId = Value(assetId),
       cashAccountId = Value(cashAccountId),
       date = Value(date),
       type = Value(type),
       name = Value(name),
       amount = Value(amount);
  static Insertable<CashTransaction> custom({
    Expression<int>? id,
    Expression<int>? assetId,
    Expression<int>? cashAccountId,
    Expression<String>? clientId,
    Expression<bool>? dirty,
    Expression<String>? lastModifiedAt,
    Expression<String>? deletedAt,
    Expression<int>? linkedTransactionId,
    Expression<String>? date,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? amount,
    Expression<double>? amountValue,
    Expression<double>? cashFlowAmount,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (cashAccountId != null) 'cash_account_id': cashAccountId,
      if (clientId != null) 'client_id': clientId,
      if (dirty != null) 'dirty': dirty,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (linkedTransactionId != null)
        'linked_transaction_id': linkedTransactionId,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (amountValue != null) 'amount_value': amountValue,
      if (cashFlowAmount != null) 'cash_flow_amount': cashFlowAmount,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CashTransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? assetId,
    Value<int>? cashAccountId,
    Value<String?>? clientId,
    Value<bool>? dirty,
    Value<String?>? lastModifiedAt,
    Value<String?>? deletedAt,
    Value<int?>? linkedTransactionId,
    Value<String>? date,
    Value<String>? type,
    Value<String>? name,
    Value<String>? amount,
    Value<double>? amountValue,
    Value<double>? cashFlowAmount,
    Value<int>? sortOrder,
  }) {
    return CashTransactionsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      cashAccountId: cashAccountId ?? this.cashAccountId,
      clientId: clientId ?? this.clientId,
      dirty: dirty ?? this.dirty,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      date: date ?? this.date,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      amountValue: amountValue ?? this.amountValue,
      cashFlowAmount: cashFlowAmount ?? this.cashFlowAmount,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (cashAccountId.present) {
      map['cash_account_id'] = Variable<int>(cashAccountId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (linkedTransactionId.present) {
      map['linked_transaction_id'] = Variable<int>(linkedTransactionId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<String>(amount.value);
    }
    if (amountValue.present) {
      map['amount_value'] = Variable<double>(amountValue.value);
    }
    if (cashFlowAmount.present) {
      map['cash_flow_amount'] = Variable<double>(cashFlowAmount.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('cashAccountId: $cashAccountId, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('amountValue: $amountValue, ')
          ..write('cashFlowAmount: $cashFlowAmount, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $TransactionEventsTable extends TransactionEvents
    with TableInfo<$TransactionEventsTable, TransactionEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<String> lastModifiedAt = GeneratedColumn<String>(
    'last_modified_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<String> occurredAt = GeneratedColumn<String>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _flowCategoryMeta = const VerificationMeta(
    'flowCategory',
  );
  @override
  late final GeneratedColumn<String> flowCategory = GeneratedColumn<String>(
    'flow_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('internal'),
  );
  static const VerificationMeta _legacySourceTableMeta = const VerificationMeta(
    'legacySourceTable',
  );
  @override
  late final GeneratedColumn<String> legacySourceTable =
      GeneratedColumn<String>(
        'legacy_source_table',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _legacySourceIdMeta = const VerificationMeta(
    'legacySourceId',
  );
  @override
  late final GeneratedColumn<int> legacySourceId = GeneratedColumn<int>(
    'legacy_source_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    occurredAt,
    kind,
    title,
    memo,
    source,
    flowCategory,
    legacySourceTable,
    legacySourceId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('flow_category')) {
      context.handle(
        _flowCategoryMeta,
        flowCategory.isAcceptableOrUnknown(
          data['flow_category']!,
          _flowCategoryMeta,
        ),
      );
    }
    if (data.containsKey('legacy_source_table')) {
      context.handle(
        _legacySourceTableMeta,
        legacySourceTable.isAcceptableOrUnknown(
          data['legacy_source_table']!,
          _legacySourceTableMeta,
        ),
      );
    }
    if (data.containsKey('legacy_source_id')) {
      context.handle(
        _legacySourceIdMeta,
        legacySourceId.isAcceptableOrUnknown(
          data['legacy_source_id']!,
          _legacySourceIdMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_at'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      flowCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flow_category'],
      )!,
      legacySourceTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_source_table'],
      ),
      legacySourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legacy_source_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TransactionEventsTable createAlias(String alias) {
    return $TransactionEventsTable(attachedDatabase, alias);
  }
}

class TransactionEvent extends DataClass
    implements Insertable<TransactionEvent> {
  final int id;
  final String? clientId;
  final bool dirty;
  final String? lastModifiedAt;
  final String? deletedAt;
  final String occurredAt;
  final String kind;
  final String title;
  final String memo;
  final String source;
  final String flowCategory;
  final String? legacySourceTable;
  final int? legacySourceId;
  final int sortOrder;
  const TransactionEvent({
    required this.id,
    this.clientId,
    required this.dirty,
    this.lastModifiedAt,
    this.deletedAt,
    required this.occurredAt,
    required this.kind,
    required this.title,
    required this.memo,
    required this.source,
    required this.flowCategory,
    this.legacySourceTable,
    this.legacySourceId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['dirty'] = Variable<bool>(dirty);
    if (!nullToAbsent || lastModifiedAt != null) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['occurred_at'] = Variable<String>(occurredAt);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    map['memo'] = Variable<String>(memo);
    map['source'] = Variable<String>(source);
    map['flow_category'] = Variable<String>(flowCategory);
    if (!nullToAbsent || legacySourceTable != null) {
      map['legacy_source_table'] = Variable<String>(legacySourceTable);
    }
    if (!nullToAbsent || legacySourceId != null) {
      map['legacy_source_id'] = Variable<int>(legacySourceId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TransactionEventsCompanion toCompanion(bool nullToAbsent) {
    return TransactionEventsCompanion(
      id: Value(id),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      dirty: Value(dirty),
      lastModifiedAt: lastModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      occurredAt: Value(occurredAt),
      kind: Value(kind),
      title: Value(title),
      memo: Value(memo),
      source: Value(source),
      flowCategory: Value(flowCategory),
      legacySourceTable: legacySourceTable == null && nullToAbsent
          ? const Value.absent()
          : Value(legacySourceTable),
      legacySourceId: legacySourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacySourceId),
      sortOrder: Value(sortOrder),
    );
  }

  factory TransactionEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionEvent(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      lastModifiedAt: serializer.fromJson<String?>(json['lastModifiedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      occurredAt: serializer.fromJson<String>(json['occurredAt']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      memo: serializer.fromJson<String>(json['memo']),
      source: serializer.fromJson<String>(json['source']),
      flowCategory: serializer.fromJson<String>(json['flowCategory']),
      legacySourceTable: serializer.fromJson<String?>(
        json['legacySourceTable'],
      ),
      legacySourceId: serializer.fromJson<int?>(json['legacySourceId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<String?>(clientId),
      'dirty': serializer.toJson<bool>(dirty),
      'lastModifiedAt': serializer.toJson<String?>(lastModifiedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'occurredAt': serializer.toJson<String>(occurredAt),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'memo': serializer.toJson<String>(memo),
      'source': serializer.toJson<String>(source),
      'flowCategory': serializer.toJson<String>(flowCategory),
      'legacySourceTable': serializer.toJson<String?>(legacySourceTable),
      'legacySourceId': serializer.toJson<int?>(legacySourceId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TransactionEvent copyWith({
    int? id,
    Value<String?> clientId = const Value.absent(),
    bool? dirty,
    Value<String?> lastModifiedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
    String? occurredAt,
    String? kind,
    String? title,
    String? memo,
    String? source,
    String? flowCategory,
    Value<String?> legacySourceTable = const Value.absent(),
    Value<int?> legacySourceId = const Value.absent(),
    int? sortOrder,
  }) => TransactionEvent(
    id: id ?? this.id,
    clientId: clientId.present ? clientId.value : this.clientId,
    dirty: dirty ?? this.dirty,
    lastModifiedAt: lastModifiedAt.present
        ? lastModifiedAt.value
        : this.lastModifiedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    occurredAt: occurredAt ?? this.occurredAt,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    memo: memo ?? this.memo,
    source: source ?? this.source,
    flowCategory: flowCategory ?? this.flowCategory,
    legacySourceTable: legacySourceTable.present
        ? legacySourceTable.value
        : this.legacySourceTable,
    legacySourceId: legacySourceId.present
        ? legacySourceId.value
        : this.legacySourceId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TransactionEvent copyWithCompanion(TransactionEventsCompanion data) {
    return TransactionEvent(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      memo: data.memo.present ? data.memo.value : this.memo,
      source: data.source.present ? data.source.value : this.source,
      flowCategory: data.flowCategory.present
          ? data.flowCategory.value
          : this.flowCategory,
      legacySourceTable: data.legacySourceTable.present
          ? data.legacySourceTable.value
          : this.legacySourceTable,
      legacySourceId: data.legacySourceId.present
          ? data.legacySourceId.value
          : this.legacySourceId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionEvent(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('memo: $memo, ')
          ..write('source: $source, ')
          ..write('flowCategory: $flowCategory, ')
          ..write('legacySourceTable: $legacySourceTable, ')
          ..write('legacySourceId: $legacySourceId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    occurredAt,
    kind,
    title,
    memo,
    source,
    flowCategory,
    legacySourceTable,
    legacySourceId,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionEvent &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.dirty == this.dirty &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.deletedAt == this.deletedAt &&
          other.occurredAt == this.occurredAt &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.memo == this.memo &&
          other.source == this.source &&
          other.flowCategory == this.flowCategory &&
          other.legacySourceTable == this.legacySourceTable &&
          other.legacySourceId == this.legacySourceId &&
          other.sortOrder == this.sortOrder);
}

class TransactionEventsCompanion extends UpdateCompanion<TransactionEvent> {
  final Value<int> id;
  final Value<String?> clientId;
  final Value<bool> dirty;
  final Value<String?> lastModifiedAt;
  final Value<String?> deletedAt;
  final Value<String> occurredAt;
  final Value<String> kind;
  final Value<String> title;
  final Value<String> memo;
  final Value<String> source;
  final Value<String> flowCategory;
  final Value<String?> legacySourceTable;
  final Value<int?> legacySourceId;
  final Value<int> sortOrder;
  const TransactionEventsCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.memo = const Value.absent(),
    this.source = const Value.absent(),
    this.flowCategory = const Value.absent(),
    this.legacySourceTable = const Value.absent(),
    this.legacySourceId = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  TransactionEventsCompanion.insert({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String occurredAt,
    required String kind,
    this.title = const Value.absent(),
    this.memo = const Value.absent(),
    this.source = const Value.absent(),
    this.flowCategory = const Value.absent(),
    this.legacySourceTable = const Value.absent(),
    this.legacySourceId = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : occurredAt = Value(occurredAt),
       kind = Value(kind);
  static Insertable<TransactionEvent> custom({
    Expression<int>? id,
    Expression<String>? clientId,
    Expression<bool>? dirty,
    Expression<String>? lastModifiedAt,
    Expression<String>? deletedAt,
    Expression<String>? occurredAt,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? memo,
    Expression<String>? source,
    Expression<String>? flowCategory,
    Expression<String>? legacySourceTable,
    Expression<int>? legacySourceId,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (dirty != null) 'dirty': dirty,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (memo != null) 'memo': memo,
      if (source != null) 'source': source,
      if (flowCategory != null) 'flow_category': flowCategory,
      if (legacySourceTable != null) 'legacy_source_table': legacySourceTable,
      if (legacySourceId != null) 'legacy_source_id': legacySourceId,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  TransactionEventsCompanion copyWith({
    Value<int>? id,
    Value<String?>? clientId,
    Value<bool>? dirty,
    Value<String?>? lastModifiedAt,
    Value<String?>? deletedAt,
    Value<String>? occurredAt,
    Value<String>? kind,
    Value<String>? title,
    Value<String>? memo,
    Value<String>? source,
    Value<String>? flowCategory,
    Value<String?>? legacySourceTable,
    Value<int?>? legacySourceId,
    Value<int>? sortOrder,
  }) {
    return TransactionEventsCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      dirty: dirty ?? this.dirty,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      occurredAt: occurredAt ?? this.occurredAt,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      source: source ?? this.source,
      flowCategory: flowCategory ?? this.flowCategory,
      legacySourceTable: legacySourceTable ?? this.legacySourceTable,
      legacySourceId: legacySourceId ?? this.legacySourceId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<String>(occurredAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (flowCategory.present) {
      map['flow_category'] = Variable<String>(flowCategory.value);
    }
    if (legacySourceTable.present) {
      map['legacy_source_table'] = Variable<String>(legacySourceTable.value);
    }
    if (legacySourceId.present) {
      map['legacy_source_id'] = Variable<int>(legacySourceId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionEventsCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('memo: $memo, ')
          ..write('source: $source, ')
          ..write('flowCategory: $flowCategory, ')
          ..write('legacySourceTable: $legacySourceTable, ')
          ..write('legacySourceId: $legacySourceId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $TransactionLinesTable extends TransactionLines
    with TableInfo<$TransactionLinesTable, TransactionLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionLinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<int> eventId = GeneratedColumn<int>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transaction_events (id)',
    ),
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assets (id)',
    ),
  );
  static const VerificationMeta _holdingIdMeta = const VerificationMeta(
    'holdingId',
  );
  @override
  late final GeneratedColumn<int> holdingId = GeneratedColumn<int>(
    'holding_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES holdings (id)',
    ),
  );
  static const VerificationMeta _cashAccountIdMeta = const VerificationMeta(
    'cashAccountId',
  );
  @override
  late final GeneratedColumn<int> cashAccountId = GeneratedColumn<int>(
    'cash_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cash_accounts (id)',
    ),
  );
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<String> lastModifiedAt = GeneratedColumn<String>(
    'last_modified_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _legacySourceTableMeta = const VerificationMeta(
    'legacySourceTable',
  );
  @override
  late final GeneratedColumn<String> legacySourceTable =
      GeneratedColumn<String>(
        'legacy_source_table',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _legacySourceIdMeta = const VerificationMeta(
    'legacySourceId',
  );
  @override
  late final GeneratedColumn<int> legacySourceId = GeneratedColumn<int>(
    'legacy_source_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KRW'),
  );
  static const VerificationMeta _quantityDeltaMeta = const VerificationMeta(
    'quantityDelta',
  );
  @override
  late final GeneratedColumn<double> quantityDelta = GeneratedColumn<double>(
    'quantity_delta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cashDeltaMeta = const VerificationMeta(
    'cashDelta',
  );
  @override
  late final GeneratedColumn<double> cashDelta = GeneratedColumn<double>(
    'cash_delta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _grossAmountMeta = const VerificationMeta(
    'grossAmount',
  );
  @override
  late final GeneratedColumn<double> grossAmount = GeneratedColumn<double>(
    'gross_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _feeAmountMeta = const VerificationMeta(
    'feeAmount',
  );
  @override
  late final GeneratedColumn<double> feeAmount = GeneratedColumn<double>(
    'fee_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxAmountMeta = const VerificationMeta(
    'taxAmount',
  );
  @override
  late final GeneratedColumn<double> taxAmount = GeneratedColumn<double>(
    'tax_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _costBasisDeltaMeta = const VerificationMeta(
    'costBasisDelta',
  );
  @override
  late final GeneratedColumn<double> costBasisDelta = GeneratedColumn<double>(
    'cost_basis_delta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _costBasisSourceDeltaMeta =
      const VerificationMeta('costBasisSourceDelta');
  @override
  late final GeneratedColumn<double> costBasisSourceDelta =
      GeneratedColumn<double>(
        'cost_basis_source_delta',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _realizedPnlMeta = const VerificationMeta(
    'realizedPnl',
  );
  @override
  late final GeneratedColumn<double> realizedPnl = GeneratedColumn<double>(
    'realized_pnl',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _realizedPnlSourceMeta = const VerificationMeta(
    'realizedPnlSource',
  );
  @override
  late final GeneratedColumn<String> realizedPnlSource =
      GeneratedColumn<String>(
        'realized_pnl_source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('auto'),
      );
  static const VerificationMeta _fxRateMeta = const VerificationMeta('fxRate');
  @override
  late final GeneratedColumn<double> fxRate = GeneratedColumn<double>(
    'fx_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    assetId,
    holdingId,
    cashAccountId,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    legacySourceTable,
    legacySourceId,
    action,
    currencyCode,
    quantityDelta,
    cashDelta,
    unitPrice,
    grossAmount,
    feeAmount,
    taxAmount,
    costBasisDelta,
    costBasisSourceDelta,
    realizedPnl,
    realizedPnlSource,
    fxRate,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    if (data.containsKey('holding_id')) {
      context.handle(
        _holdingIdMeta,
        holdingId.isAcceptableOrUnknown(data['holding_id']!, _holdingIdMeta),
      );
    }
    if (data.containsKey('cash_account_id')) {
      context.handle(
        _cashAccountIdMeta,
        cashAccountId.isAcceptableOrUnknown(
          data['cash_account_id']!,
          _cashAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('legacy_source_table')) {
      context.handle(
        _legacySourceTableMeta,
        legacySourceTable.isAcceptableOrUnknown(
          data['legacy_source_table']!,
          _legacySourceTableMeta,
        ),
      );
    }
    if (data.containsKey('legacy_source_id')) {
      context.handle(
        _legacySourceIdMeta,
        legacySourceId.isAcceptableOrUnknown(
          data['legacy_source_id']!,
          _legacySourceIdMeta,
        ),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('quantity_delta')) {
      context.handle(
        _quantityDeltaMeta,
        quantityDelta.isAcceptableOrUnknown(
          data['quantity_delta']!,
          _quantityDeltaMeta,
        ),
      );
    }
    if (data.containsKey('cash_delta')) {
      context.handle(
        _cashDeltaMeta,
        cashDelta.isAcceptableOrUnknown(data['cash_delta']!, _cashDeltaMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('gross_amount')) {
      context.handle(
        _grossAmountMeta,
        grossAmount.isAcceptableOrUnknown(
          data['gross_amount']!,
          _grossAmountMeta,
        ),
      );
    }
    if (data.containsKey('fee_amount')) {
      context.handle(
        _feeAmountMeta,
        feeAmount.isAcceptableOrUnknown(data['fee_amount']!, _feeAmountMeta),
      );
    }
    if (data.containsKey('tax_amount')) {
      context.handle(
        _taxAmountMeta,
        taxAmount.isAcceptableOrUnknown(data['tax_amount']!, _taxAmountMeta),
      );
    }
    if (data.containsKey('cost_basis_delta')) {
      context.handle(
        _costBasisDeltaMeta,
        costBasisDelta.isAcceptableOrUnknown(
          data['cost_basis_delta']!,
          _costBasisDeltaMeta,
        ),
      );
    }
    if (data.containsKey('cost_basis_source_delta')) {
      context.handle(
        _costBasisSourceDeltaMeta,
        costBasisSourceDelta.isAcceptableOrUnknown(
          data['cost_basis_source_delta']!,
          _costBasisSourceDeltaMeta,
        ),
      );
    }
    if (data.containsKey('realized_pnl')) {
      context.handle(
        _realizedPnlMeta,
        realizedPnl.isAcceptableOrUnknown(
          data['realized_pnl']!,
          _realizedPnlMeta,
        ),
      );
    }
    if (data.containsKey('realized_pnl_source')) {
      context.handle(
        _realizedPnlSourceMeta,
        realizedPnlSource.isAcceptableOrUnknown(
          data['realized_pnl_source']!,
          _realizedPnlSourceMeta,
        ),
      );
    }
    if (data.containsKey('fx_rate')) {
      context.handle(
        _fxRateMeta,
        fxRate.isAcceptableOrUnknown(data['fx_rate']!, _fxRateMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      ),
      holdingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}holding_id'],
      ),
      cashAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cash_account_id'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      legacySourceTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_source_table'],
      ),
      legacySourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legacy_source_id'],
      ),
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      quantityDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_delta'],
      )!,
      cashDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cash_delta'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      grossAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gross_amount'],
      )!,
      feeAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fee_amount'],
      )!,
      taxAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tax_amount'],
      )!,
      costBasisDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_basis_delta'],
      )!,
      costBasisSourceDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_basis_source_delta'],
      )!,
      realizedPnl: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}realized_pnl'],
      )!,
      realizedPnlSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}realized_pnl_source'],
      )!,
      fxRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fx_rate'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TransactionLinesTable createAlias(String alias) {
    return $TransactionLinesTable(attachedDatabase, alias);
  }
}

class TransactionLine extends DataClass implements Insertable<TransactionLine> {
  final int id;
  final int eventId;
  final int? assetId;
  final int? holdingId;
  final int? cashAccountId;
  final String? clientId;
  final bool dirty;
  final String? lastModifiedAt;
  final String? deletedAt;
  final String? legacySourceTable;
  final int? legacySourceId;
  final String action;
  final String currencyCode;
  final double quantityDelta;
  final double cashDelta;
  final double unitPrice;
  final double grossAmount;
  final double feeAmount;
  final double taxAmount;
  final double costBasisDelta;
  final double costBasisSourceDelta;
  final double realizedPnl;
  final String realizedPnlSource;
  final double? fxRate;
  final int sortOrder;
  const TransactionLine({
    required this.id,
    required this.eventId,
    this.assetId,
    this.holdingId,
    this.cashAccountId,
    this.clientId,
    required this.dirty,
    this.lastModifiedAt,
    this.deletedAt,
    this.legacySourceTable,
    this.legacySourceId,
    required this.action,
    required this.currencyCode,
    required this.quantityDelta,
    required this.cashDelta,
    required this.unitPrice,
    required this.grossAmount,
    required this.feeAmount,
    required this.taxAmount,
    required this.costBasisDelta,
    required this.costBasisSourceDelta,
    required this.realizedPnl,
    required this.realizedPnlSource,
    this.fxRate,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<int>(eventId);
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<int>(assetId);
    }
    if (!nullToAbsent || holdingId != null) {
      map['holding_id'] = Variable<int>(holdingId);
    }
    if (!nullToAbsent || cashAccountId != null) {
      map['cash_account_id'] = Variable<int>(cashAccountId);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['dirty'] = Variable<bool>(dirty);
    if (!nullToAbsent || lastModifiedAt != null) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    if (!nullToAbsent || legacySourceTable != null) {
      map['legacy_source_table'] = Variable<String>(legacySourceTable);
    }
    if (!nullToAbsent || legacySourceId != null) {
      map['legacy_source_id'] = Variable<int>(legacySourceId);
    }
    map['action'] = Variable<String>(action);
    map['currency_code'] = Variable<String>(currencyCode);
    map['quantity_delta'] = Variable<double>(quantityDelta);
    map['cash_delta'] = Variable<double>(cashDelta);
    map['unit_price'] = Variable<double>(unitPrice);
    map['gross_amount'] = Variable<double>(grossAmount);
    map['fee_amount'] = Variable<double>(feeAmount);
    map['tax_amount'] = Variable<double>(taxAmount);
    map['cost_basis_delta'] = Variable<double>(costBasisDelta);
    map['cost_basis_source_delta'] = Variable<double>(costBasisSourceDelta);
    map['realized_pnl'] = Variable<double>(realizedPnl);
    map['realized_pnl_source'] = Variable<String>(realizedPnlSource);
    if (!nullToAbsent || fxRate != null) {
      map['fx_rate'] = Variable<double>(fxRate);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TransactionLinesCompanion toCompanion(bool nullToAbsent) {
    return TransactionLinesCompanion(
      id: Value(id),
      eventId: Value(eventId),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      holdingId: holdingId == null && nullToAbsent
          ? const Value.absent()
          : Value(holdingId),
      cashAccountId: cashAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(cashAccountId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      dirty: Value(dirty),
      lastModifiedAt: lastModifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      legacySourceTable: legacySourceTable == null && nullToAbsent
          ? const Value.absent()
          : Value(legacySourceTable),
      legacySourceId: legacySourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacySourceId),
      action: Value(action),
      currencyCode: Value(currencyCode),
      quantityDelta: Value(quantityDelta),
      cashDelta: Value(cashDelta),
      unitPrice: Value(unitPrice),
      grossAmount: Value(grossAmount),
      feeAmount: Value(feeAmount),
      taxAmount: Value(taxAmount),
      costBasisDelta: Value(costBasisDelta),
      costBasisSourceDelta: Value(costBasisSourceDelta),
      realizedPnl: Value(realizedPnl),
      realizedPnlSource: Value(realizedPnlSource),
      fxRate: fxRate == null && nullToAbsent
          ? const Value.absent()
          : Value(fxRate),
      sortOrder: Value(sortOrder),
    );
  }

  factory TransactionLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionLine(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<int>(json['eventId']),
      assetId: serializer.fromJson<int?>(json['assetId']),
      holdingId: serializer.fromJson<int?>(json['holdingId']),
      cashAccountId: serializer.fromJson<int?>(json['cashAccountId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      lastModifiedAt: serializer.fromJson<String?>(json['lastModifiedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      legacySourceTable: serializer.fromJson<String?>(
        json['legacySourceTable'],
      ),
      legacySourceId: serializer.fromJson<int?>(json['legacySourceId']),
      action: serializer.fromJson<String>(json['action']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      quantityDelta: serializer.fromJson<double>(json['quantityDelta']),
      cashDelta: serializer.fromJson<double>(json['cashDelta']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      grossAmount: serializer.fromJson<double>(json['grossAmount']),
      feeAmount: serializer.fromJson<double>(json['feeAmount']),
      taxAmount: serializer.fromJson<double>(json['taxAmount']),
      costBasisDelta: serializer.fromJson<double>(json['costBasisDelta']),
      costBasisSourceDelta: serializer.fromJson<double>(
        json['costBasisSourceDelta'],
      ),
      realizedPnl: serializer.fromJson<double>(json['realizedPnl']),
      realizedPnlSource: serializer.fromJson<String>(json['realizedPnlSource']),
      fxRate: serializer.fromJson<double?>(json['fxRate']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<int>(eventId),
      'assetId': serializer.toJson<int?>(assetId),
      'holdingId': serializer.toJson<int?>(holdingId),
      'cashAccountId': serializer.toJson<int?>(cashAccountId),
      'clientId': serializer.toJson<String?>(clientId),
      'dirty': serializer.toJson<bool>(dirty),
      'lastModifiedAt': serializer.toJson<String?>(lastModifiedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'legacySourceTable': serializer.toJson<String?>(legacySourceTable),
      'legacySourceId': serializer.toJson<int?>(legacySourceId),
      'action': serializer.toJson<String>(action),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'quantityDelta': serializer.toJson<double>(quantityDelta),
      'cashDelta': serializer.toJson<double>(cashDelta),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'grossAmount': serializer.toJson<double>(grossAmount),
      'feeAmount': serializer.toJson<double>(feeAmount),
      'taxAmount': serializer.toJson<double>(taxAmount),
      'costBasisDelta': serializer.toJson<double>(costBasisDelta),
      'costBasisSourceDelta': serializer.toJson<double>(costBasisSourceDelta),
      'realizedPnl': serializer.toJson<double>(realizedPnl),
      'realizedPnlSource': serializer.toJson<String>(realizedPnlSource),
      'fxRate': serializer.toJson<double?>(fxRate),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TransactionLine copyWith({
    int? id,
    int? eventId,
    Value<int?> assetId = const Value.absent(),
    Value<int?> holdingId = const Value.absent(),
    Value<int?> cashAccountId = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    bool? dirty,
    Value<String?> lastModifiedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
    Value<String?> legacySourceTable = const Value.absent(),
    Value<int?> legacySourceId = const Value.absent(),
    String? action,
    String? currencyCode,
    double? quantityDelta,
    double? cashDelta,
    double? unitPrice,
    double? grossAmount,
    double? feeAmount,
    double? taxAmount,
    double? costBasisDelta,
    double? costBasisSourceDelta,
    double? realizedPnl,
    String? realizedPnlSource,
    Value<double?> fxRate = const Value.absent(),
    int? sortOrder,
  }) => TransactionLine(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    assetId: assetId.present ? assetId.value : this.assetId,
    holdingId: holdingId.present ? holdingId.value : this.holdingId,
    cashAccountId: cashAccountId.present
        ? cashAccountId.value
        : this.cashAccountId,
    clientId: clientId.present ? clientId.value : this.clientId,
    dirty: dirty ?? this.dirty,
    lastModifiedAt: lastModifiedAt.present
        ? lastModifiedAt.value
        : this.lastModifiedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    legacySourceTable: legacySourceTable.present
        ? legacySourceTable.value
        : this.legacySourceTable,
    legacySourceId: legacySourceId.present
        ? legacySourceId.value
        : this.legacySourceId,
    action: action ?? this.action,
    currencyCode: currencyCode ?? this.currencyCode,
    quantityDelta: quantityDelta ?? this.quantityDelta,
    cashDelta: cashDelta ?? this.cashDelta,
    unitPrice: unitPrice ?? this.unitPrice,
    grossAmount: grossAmount ?? this.grossAmount,
    feeAmount: feeAmount ?? this.feeAmount,
    taxAmount: taxAmount ?? this.taxAmount,
    costBasisDelta: costBasisDelta ?? this.costBasisDelta,
    costBasisSourceDelta: costBasisSourceDelta ?? this.costBasisSourceDelta,
    realizedPnl: realizedPnl ?? this.realizedPnl,
    realizedPnlSource: realizedPnlSource ?? this.realizedPnlSource,
    fxRate: fxRate.present ? fxRate.value : this.fxRate,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TransactionLine copyWithCompanion(TransactionLinesCompanion data) {
    return TransactionLine(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      holdingId: data.holdingId.present ? data.holdingId.value : this.holdingId,
      cashAccountId: data.cashAccountId.present
          ? data.cashAccountId.value
          : this.cashAccountId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      legacySourceTable: data.legacySourceTable.present
          ? data.legacySourceTable.value
          : this.legacySourceTable,
      legacySourceId: data.legacySourceId.present
          ? data.legacySourceId.value
          : this.legacySourceId,
      action: data.action.present ? data.action.value : this.action,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      quantityDelta: data.quantityDelta.present
          ? data.quantityDelta.value
          : this.quantityDelta,
      cashDelta: data.cashDelta.present ? data.cashDelta.value : this.cashDelta,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      grossAmount: data.grossAmount.present
          ? data.grossAmount.value
          : this.grossAmount,
      feeAmount: data.feeAmount.present ? data.feeAmount.value : this.feeAmount,
      taxAmount: data.taxAmount.present ? data.taxAmount.value : this.taxAmount,
      costBasisDelta: data.costBasisDelta.present
          ? data.costBasisDelta.value
          : this.costBasisDelta,
      costBasisSourceDelta: data.costBasisSourceDelta.present
          ? data.costBasisSourceDelta.value
          : this.costBasisSourceDelta,
      realizedPnl: data.realizedPnl.present
          ? data.realizedPnl.value
          : this.realizedPnl,
      realizedPnlSource: data.realizedPnlSource.present
          ? data.realizedPnlSource.value
          : this.realizedPnlSource,
      fxRate: data.fxRate.present ? data.fxRate.value : this.fxRate,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionLine(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('assetId: $assetId, ')
          ..write('holdingId: $holdingId, ')
          ..write('cashAccountId: $cashAccountId, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('legacySourceTable: $legacySourceTable, ')
          ..write('legacySourceId: $legacySourceId, ')
          ..write('action: $action, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('cashDelta: $cashDelta, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('grossAmount: $grossAmount, ')
          ..write('feeAmount: $feeAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('costBasisDelta: $costBasisDelta, ')
          ..write('costBasisSourceDelta: $costBasisSourceDelta, ')
          ..write('realizedPnl: $realizedPnl, ')
          ..write('realizedPnlSource: $realizedPnlSource, ')
          ..write('fxRate: $fxRate, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    eventId,
    assetId,
    holdingId,
    cashAccountId,
    clientId,
    dirty,
    lastModifiedAt,
    deletedAt,
    legacySourceTable,
    legacySourceId,
    action,
    currencyCode,
    quantityDelta,
    cashDelta,
    unitPrice,
    grossAmount,
    feeAmount,
    taxAmount,
    costBasisDelta,
    costBasisSourceDelta,
    realizedPnl,
    realizedPnlSource,
    fxRate,
    sortOrder,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionLine &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.assetId == this.assetId &&
          other.holdingId == this.holdingId &&
          other.cashAccountId == this.cashAccountId &&
          other.clientId == this.clientId &&
          other.dirty == this.dirty &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.deletedAt == this.deletedAt &&
          other.legacySourceTable == this.legacySourceTable &&
          other.legacySourceId == this.legacySourceId &&
          other.action == this.action &&
          other.currencyCode == this.currencyCode &&
          other.quantityDelta == this.quantityDelta &&
          other.cashDelta == this.cashDelta &&
          other.unitPrice == this.unitPrice &&
          other.grossAmount == this.grossAmount &&
          other.feeAmount == this.feeAmount &&
          other.taxAmount == this.taxAmount &&
          other.costBasisDelta == this.costBasisDelta &&
          other.costBasisSourceDelta == this.costBasisSourceDelta &&
          other.realizedPnl == this.realizedPnl &&
          other.realizedPnlSource == this.realizedPnlSource &&
          other.fxRate == this.fxRate &&
          other.sortOrder == this.sortOrder);
}

class TransactionLinesCompanion extends UpdateCompanion<TransactionLine> {
  final Value<int> id;
  final Value<int> eventId;
  final Value<int?> assetId;
  final Value<int?> holdingId;
  final Value<int?> cashAccountId;
  final Value<String?> clientId;
  final Value<bool> dirty;
  final Value<String?> lastModifiedAt;
  final Value<String?> deletedAt;
  final Value<String?> legacySourceTable;
  final Value<int?> legacySourceId;
  final Value<String> action;
  final Value<String> currencyCode;
  final Value<double> quantityDelta;
  final Value<double> cashDelta;
  final Value<double> unitPrice;
  final Value<double> grossAmount;
  final Value<double> feeAmount;
  final Value<double> taxAmount;
  final Value<double> costBasisDelta;
  final Value<double> costBasisSourceDelta;
  final Value<double> realizedPnl;
  final Value<String> realizedPnlSource;
  final Value<double?> fxRate;
  final Value<int> sortOrder;
  const TransactionLinesCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.holdingId = const Value.absent(),
    this.cashAccountId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.legacySourceTable = const Value.absent(),
    this.legacySourceId = const Value.absent(),
    this.action = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.quantityDelta = const Value.absent(),
    this.cashDelta = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.grossAmount = const Value.absent(),
    this.feeAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.costBasisDelta = const Value.absent(),
    this.costBasisSourceDelta = const Value.absent(),
    this.realizedPnl = const Value.absent(),
    this.realizedPnlSource = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  TransactionLinesCompanion.insert({
    this.id = const Value.absent(),
    required int eventId,
    this.assetId = const Value.absent(),
    this.holdingId = const Value.absent(),
    this.cashAccountId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.dirty = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.legacySourceTable = const Value.absent(),
    this.legacySourceId = const Value.absent(),
    required String action,
    this.currencyCode = const Value.absent(),
    this.quantityDelta = const Value.absent(),
    this.cashDelta = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.grossAmount = const Value.absent(),
    this.feeAmount = const Value.absent(),
    this.taxAmount = const Value.absent(),
    this.costBasisDelta = const Value.absent(),
    this.costBasisSourceDelta = const Value.absent(),
    this.realizedPnl = const Value.absent(),
    this.realizedPnlSource = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : eventId = Value(eventId),
       action = Value(action);
  static Insertable<TransactionLine> custom({
    Expression<int>? id,
    Expression<int>? eventId,
    Expression<int>? assetId,
    Expression<int>? holdingId,
    Expression<int>? cashAccountId,
    Expression<String>? clientId,
    Expression<bool>? dirty,
    Expression<String>? lastModifiedAt,
    Expression<String>? deletedAt,
    Expression<String>? legacySourceTable,
    Expression<int>? legacySourceId,
    Expression<String>? action,
    Expression<String>? currencyCode,
    Expression<double>? quantityDelta,
    Expression<double>? cashDelta,
    Expression<double>? unitPrice,
    Expression<double>? grossAmount,
    Expression<double>? feeAmount,
    Expression<double>? taxAmount,
    Expression<double>? costBasisDelta,
    Expression<double>? costBasisSourceDelta,
    Expression<double>? realizedPnl,
    Expression<String>? realizedPnlSource,
    Expression<double>? fxRate,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (assetId != null) 'asset_id': assetId,
      if (holdingId != null) 'holding_id': holdingId,
      if (cashAccountId != null) 'cash_account_id': cashAccountId,
      if (clientId != null) 'client_id': clientId,
      if (dirty != null) 'dirty': dirty,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (legacySourceTable != null) 'legacy_source_table': legacySourceTable,
      if (legacySourceId != null) 'legacy_source_id': legacySourceId,
      if (action != null) 'action': action,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (quantityDelta != null) 'quantity_delta': quantityDelta,
      if (cashDelta != null) 'cash_delta': cashDelta,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (grossAmount != null) 'gross_amount': grossAmount,
      if (feeAmount != null) 'fee_amount': feeAmount,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (costBasisDelta != null) 'cost_basis_delta': costBasisDelta,
      if (costBasisSourceDelta != null)
        'cost_basis_source_delta': costBasisSourceDelta,
      if (realizedPnl != null) 'realized_pnl': realizedPnl,
      if (realizedPnlSource != null) 'realized_pnl_source': realizedPnlSource,
      if (fxRate != null) 'fx_rate': fxRate,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  TransactionLinesCompanion copyWith({
    Value<int>? id,
    Value<int>? eventId,
    Value<int?>? assetId,
    Value<int?>? holdingId,
    Value<int?>? cashAccountId,
    Value<String?>? clientId,
    Value<bool>? dirty,
    Value<String?>? lastModifiedAt,
    Value<String?>? deletedAt,
    Value<String?>? legacySourceTable,
    Value<int?>? legacySourceId,
    Value<String>? action,
    Value<String>? currencyCode,
    Value<double>? quantityDelta,
    Value<double>? cashDelta,
    Value<double>? unitPrice,
    Value<double>? grossAmount,
    Value<double>? feeAmount,
    Value<double>? taxAmount,
    Value<double>? costBasisDelta,
    Value<double>? costBasisSourceDelta,
    Value<double>? realizedPnl,
    Value<String>? realizedPnlSource,
    Value<double?>? fxRate,
    Value<int>? sortOrder,
  }) {
    return TransactionLinesCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      assetId: assetId ?? this.assetId,
      holdingId: holdingId ?? this.holdingId,
      cashAccountId: cashAccountId ?? this.cashAccountId,
      clientId: clientId ?? this.clientId,
      dirty: dirty ?? this.dirty,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      legacySourceTable: legacySourceTable ?? this.legacySourceTable,
      legacySourceId: legacySourceId ?? this.legacySourceId,
      action: action ?? this.action,
      currencyCode: currencyCode ?? this.currencyCode,
      quantityDelta: quantityDelta ?? this.quantityDelta,
      cashDelta: cashDelta ?? this.cashDelta,
      unitPrice: unitPrice ?? this.unitPrice,
      grossAmount: grossAmount ?? this.grossAmount,
      feeAmount: feeAmount ?? this.feeAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      costBasisDelta: costBasisDelta ?? this.costBasisDelta,
      costBasisSourceDelta: costBasisSourceDelta ?? this.costBasisSourceDelta,
      realizedPnl: realizedPnl ?? this.realizedPnl,
      realizedPnlSource: realizedPnlSource ?? this.realizedPnlSource,
      fxRate: fxRate ?? this.fxRate,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<int>(eventId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (holdingId.present) {
      map['holding_id'] = Variable<int>(holdingId.value);
    }
    if (cashAccountId.present) {
      map['cash_account_id'] = Variable<int>(cashAccountId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<String>(lastModifiedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (legacySourceTable.present) {
      map['legacy_source_table'] = Variable<String>(legacySourceTable.value);
    }
    if (legacySourceId.present) {
      map['legacy_source_id'] = Variable<int>(legacySourceId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (quantityDelta.present) {
      map['quantity_delta'] = Variable<double>(quantityDelta.value);
    }
    if (cashDelta.present) {
      map['cash_delta'] = Variable<double>(cashDelta.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (grossAmount.present) {
      map['gross_amount'] = Variable<double>(grossAmount.value);
    }
    if (feeAmount.present) {
      map['fee_amount'] = Variable<double>(feeAmount.value);
    }
    if (taxAmount.present) {
      map['tax_amount'] = Variable<double>(taxAmount.value);
    }
    if (costBasisDelta.present) {
      map['cost_basis_delta'] = Variable<double>(costBasisDelta.value);
    }
    if (costBasisSourceDelta.present) {
      map['cost_basis_source_delta'] = Variable<double>(
        costBasisSourceDelta.value,
      );
    }
    if (realizedPnl.present) {
      map['realized_pnl'] = Variable<double>(realizedPnl.value);
    }
    if (realizedPnlSource.present) {
      map['realized_pnl_source'] = Variable<String>(realizedPnlSource.value);
    }
    if (fxRate.present) {
      map['fx_rate'] = Variable<double>(fxRate.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionLinesCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('assetId: $assetId, ')
          ..write('holdingId: $holdingId, ')
          ..write('cashAccountId: $cashAccountId, ')
          ..write('clientId: $clientId, ')
          ..write('dirty: $dirty, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('legacySourceTable: $legacySourceTable, ')
          ..write('legacySourceId: $legacySourceId, ')
          ..write('action: $action, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('cashDelta: $cashDelta, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('grossAmount: $grossAmount, ')
          ..write('feeAmount: $feeAmount, ')
          ..write('taxAmount: $taxAmount, ')
          ..write('costBasisDelta: $costBasisDelta, ')
          ..write('costBasisSourceDelta: $costBasisSourceDelta, ')
          ..write('realizedPnl: $realizedPnl, ')
          ..write('realizedPnlSource: $realizedPnlSource, ')
          ..write('fxRate: $fxRate, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $MarketNewsCachesTable extends MarketNewsCaches
    with TableInfo<$MarketNewsCachesTable, MarketNewsCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MarketNewsCachesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _foundMeta = const VerificationMeta('found');
  @override
  late final GeneratedColumn<bool> found = GeneratedColumn<bool>(
    'found',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("found" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _summaryDateMeta = const VerificationMeta(
    'summaryDate',
  );
  @override
  late final GeneratedColumn<String> summaryDate = GeneratedColumn<String>(
    'summary_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newsCountMeta = const VerificationMeta(
    'newsCount',
  );
  @override
  late final GeneratedColumn<int> newsCount = GeneratedColumn<int>(
    'news_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryJsonMeta = const VerificationMeta(
    'summaryJson',
  );
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
    'summary_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<String> cachedAt = GeneratedColumn<String>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    found,
    summaryDate,
    model,
    newsCount,
    summaryJson,
    createdAt,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'market_news_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<MarketNewsCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('found')) {
      context.handle(
        _foundMeta,
        found.isAcceptableOrUnknown(data['found']!, _foundMeta),
      );
    }
    if (data.containsKey('summary_date')) {
      context.handle(
        _summaryDateMeta,
        summaryDate.isAcceptableOrUnknown(
          data['summary_date']!,
          _summaryDateMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('news_count')) {
      context.handle(
        _newsCountMeta,
        newsCount.isAcceptableOrUnknown(data['news_count']!, _newsCountMeta),
      );
    }
    if (data.containsKey('summary_json')) {
      context.handle(
        _summaryJsonMeta,
        summaryJson.isAcceptableOrUnknown(
          data['summary_json']!,
          _summaryJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MarketNewsCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MarketNewsCache(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      found: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}found'],
      )!,
      summaryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_date'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      newsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}news_count'],
      ),
      summaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $MarketNewsCachesTable createAlias(String alias) {
    return $MarketNewsCachesTable(attachedDatabase, alias);
  }
}

class MarketNewsCache extends DataClass implements Insertable<MarketNewsCache> {
  final int id;
  final String category;
  final bool found;
  final String? summaryDate;
  final String? model;
  final int? newsCount;
  final String? summaryJson;
  final String? createdAt;
  final String? updatedAt;
  final String cachedAt;
  const MarketNewsCache({
    required this.id,
    required this.category,
    required this.found,
    this.summaryDate,
    this.model,
    this.newsCount,
    this.summaryJson,
    this.createdAt,
    this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category'] = Variable<String>(category);
    map['found'] = Variable<bool>(found);
    if (!nullToAbsent || summaryDate != null) {
      map['summary_date'] = Variable<String>(summaryDate);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || newsCount != null) {
      map['news_count'] = Variable<int>(newsCount);
    }
    if (!nullToAbsent || summaryJson != null) {
      map['summary_json'] = Variable<String>(summaryJson);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['cached_at'] = Variable<String>(cachedAt);
    return map;
  }

  MarketNewsCachesCompanion toCompanion(bool nullToAbsent) {
    return MarketNewsCachesCompanion(
      id: Value(id),
      category: Value(category),
      found: Value(found),
      summaryDate: summaryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryDate),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      newsCount: newsCount == null && nullToAbsent
          ? const Value.absent()
          : Value(newsCount),
      summaryJson: summaryJson == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryJson),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory MarketNewsCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MarketNewsCache(
      id: serializer.fromJson<int>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      found: serializer.fromJson<bool>(json['found']),
      summaryDate: serializer.fromJson<String?>(json['summaryDate']),
      model: serializer.fromJson<String?>(json['model']),
      newsCount: serializer.fromJson<int?>(json['newsCount']),
      summaryJson: serializer.fromJson<String?>(json['summaryJson']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      cachedAt: serializer.fromJson<String>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<String>(category),
      'found': serializer.toJson<bool>(found),
      'summaryDate': serializer.toJson<String?>(summaryDate),
      'model': serializer.toJson<String?>(model),
      'newsCount': serializer.toJson<int?>(newsCount),
      'summaryJson': serializer.toJson<String?>(summaryJson),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'cachedAt': serializer.toJson<String>(cachedAt),
    };
  }

  MarketNewsCache copyWith({
    int? id,
    String? category,
    bool? found,
    Value<String?> summaryDate = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<int?> newsCount = const Value.absent(),
    Value<String?> summaryJson = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    String? cachedAt,
  }) => MarketNewsCache(
    id: id ?? this.id,
    category: category ?? this.category,
    found: found ?? this.found,
    summaryDate: summaryDate.present ? summaryDate.value : this.summaryDate,
    model: model.present ? model.value : this.model,
    newsCount: newsCount.present ? newsCount.value : this.newsCount,
    summaryJson: summaryJson.present ? summaryJson.value : this.summaryJson,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  MarketNewsCache copyWithCompanion(MarketNewsCachesCompanion data) {
    return MarketNewsCache(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      found: data.found.present ? data.found.value : this.found,
      summaryDate: data.summaryDate.present
          ? data.summaryDate.value
          : this.summaryDate,
      model: data.model.present ? data.model.value : this.model,
      newsCount: data.newsCount.present ? data.newsCount.value : this.newsCount,
      summaryJson: data.summaryJson.present
          ? data.summaryJson.value
          : this.summaryJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MarketNewsCache(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('found: $found, ')
          ..write('summaryDate: $summaryDate, ')
          ..write('model: $model, ')
          ..write('newsCount: $newsCount, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    found,
    summaryDate,
    model,
    newsCount,
    summaryJson,
    createdAt,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MarketNewsCache &&
          other.id == this.id &&
          other.category == this.category &&
          other.found == this.found &&
          other.summaryDate == this.summaryDate &&
          other.model == this.model &&
          other.newsCount == this.newsCount &&
          other.summaryJson == this.summaryJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class MarketNewsCachesCompanion extends UpdateCompanion<MarketNewsCache> {
  final Value<int> id;
  final Value<String> category;
  final Value<bool> found;
  final Value<String?> summaryDate;
  final Value<String?> model;
  final Value<int?> newsCount;
  final Value<String?> summaryJson;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<String> cachedAt;
  const MarketNewsCachesCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.found = const Value.absent(),
    this.summaryDate = const Value.absent(),
    this.model = const Value.absent(),
    this.newsCount = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  MarketNewsCachesCompanion.insert({
    this.id = const Value.absent(),
    required String category,
    this.found = const Value.absent(),
    this.summaryDate = const Value.absent(),
    this.model = const Value.absent(),
    this.newsCount = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String cachedAt,
  }) : category = Value(category),
       cachedAt = Value(cachedAt);
  static Insertable<MarketNewsCache> custom({
    Expression<int>? id,
    Expression<String>? category,
    Expression<bool>? found,
    Expression<String>? summaryDate,
    Expression<String>? model,
    Expression<int>? newsCount,
    Expression<String>? summaryJson,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (found != null) 'found': found,
      if (summaryDate != null) 'summary_date': summaryDate,
      if (model != null) 'model': model,
      if (newsCount != null) 'news_count': newsCount,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  MarketNewsCachesCompanion copyWith({
    Value<int>? id,
    Value<String>? category,
    Value<bool>? found,
    Value<String?>? summaryDate,
    Value<String?>? model,
    Value<int?>? newsCount,
    Value<String?>? summaryJson,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<String>? cachedAt,
  }) {
    return MarketNewsCachesCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      found: found ?? this.found,
      summaryDate: summaryDate ?? this.summaryDate,
      model: model ?? this.model,
      newsCount: newsCount ?? this.newsCount,
      summaryJson: summaryJson ?? this.summaryJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (found.present) {
      map['found'] = Variable<bool>(found.value);
    }
    if (summaryDate.present) {
      map['summary_date'] = Variable<String>(summaryDate.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (newsCount.present) {
      map['news_count'] = Variable<int>(newsCount.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<String>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MarketNewsCachesCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('found: $found, ')
          ..write('summaryDate: $summaryDate, ')
          ..write('model: $model, ')
          ..write('newsCount: $newsCount, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CompanyNewsCachesTable extends CompanyNewsCaches
    with TableInfo<$CompanyNewsCachesTable, CompanyNewsCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompanyNewsCachesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _symbolMeta = const VerificationMeta('symbol');
  @override
  late final GeneratedColumn<String> symbol = GeneratedColumn<String>(
    'symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _foundMeta = const VerificationMeta('found');
  @override
  late final GeneratedColumn<bool> found = GeneratedColumn<bool>(
    'found',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("found" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _summaryDateMeta = const VerificationMeta(
    'summaryDate',
  );
  @override
  late final GeneratedColumn<String> summaryDate = GeneratedColumn<String>(
    'summary_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newsCountMeta = const VerificationMeta(
    'newsCount',
  );
  @override
  late final GeneratedColumn<int> newsCount = GeneratedColumn<int>(
    'news_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryJsonMeta = const VerificationMeta(
    'summaryJson',
  );
  @override
  late final GeneratedColumn<String> summaryJson = GeneratedColumn<String>(
    'summary_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<String> cachedAt = GeneratedColumn<String>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    symbol,
    found,
    summaryDate,
    model,
    newsCount,
    summaryJson,
    createdAt,
    updatedAt,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'company_news_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompanyNewsCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('symbol')) {
      context.handle(
        _symbolMeta,
        symbol.isAcceptableOrUnknown(data['symbol']!, _symbolMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolMeta);
    }
    if (data.containsKey('found')) {
      context.handle(
        _foundMeta,
        found.isAcceptableOrUnknown(data['found']!, _foundMeta),
      );
    }
    if (data.containsKey('summary_date')) {
      context.handle(
        _summaryDateMeta,
        summaryDate.isAcceptableOrUnknown(
          data['summary_date']!,
          _summaryDateMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('news_count')) {
      context.handle(
        _newsCountMeta,
        newsCount.isAcceptableOrUnknown(data['news_count']!, _newsCountMeta),
      );
    }
    if (data.containsKey('summary_json')) {
      context.handle(
        _summaryJsonMeta,
        summaryJson.isAcceptableOrUnknown(
          data['summary_json']!,
          _summaryJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CompanyNewsCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompanyNewsCache(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      symbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol'],
      )!,
      found: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}found'],
      )!,
      summaryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_date'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      newsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}news_count'],
      ),
      summaryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CompanyNewsCachesTable createAlias(String alias) {
    return $CompanyNewsCachesTable(attachedDatabase, alias);
  }
}

class CompanyNewsCache extends DataClass
    implements Insertable<CompanyNewsCache> {
  final int id;
  final String symbol;
  final bool found;
  final String? summaryDate;
  final String? model;
  final int? newsCount;
  final String? summaryJson;
  final String? createdAt;
  final String? updatedAt;
  final String cachedAt;
  const CompanyNewsCache({
    required this.id,
    required this.symbol,
    required this.found,
    this.summaryDate,
    this.model,
    this.newsCount,
    this.summaryJson,
    this.createdAt,
    this.updatedAt,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['symbol'] = Variable<String>(symbol);
    map['found'] = Variable<bool>(found);
    if (!nullToAbsent || summaryDate != null) {
      map['summary_date'] = Variable<String>(summaryDate);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || newsCount != null) {
      map['news_count'] = Variable<int>(newsCount);
    }
    if (!nullToAbsent || summaryJson != null) {
      map['summary_json'] = Variable<String>(summaryJson);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    map['cached_at'] = Variable<String>(cachedAt);
    return map;
  }

  CompanyNewsCachesCompanion toCompanion(bool nullToAbsent) {
    return CompanyNewsCachesCompanion(
      id: Value(id),
      symbol: Value(symbol),
      found: Value(found),
      summaryDate: summaryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryDate),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      newsCount: newsCount == null && nullToAbsent
          ? const Value.absent()
          : Value(newsCount),
      summaryJson: summaryJson == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryJson),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CompanyNewsCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompanyNewsCache(
      id: serializer.fromJson<int>(json['id']),
      symbol: serializer.fromJson<String>(json['symbol']),
      found: serializer.fromJson<bool>(json['found']),
      summaryDate: serializer.fromJson<String?>(json['summaryDate']),
      model: serializer.fromJson<String?>(json['model']),
      newsCount: serializer.fromJson<int?>(json['newsCount']),
      summaryJson: serializer.fromJson<String?>(json['summaryJson']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      cachedAt: serializer.fromJson<String>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'symbol': serializer.toJson<String>(symbol),
      'found': serializer.toJson<bool>(found),
      'summaryDate': serializer.toJson<String?>(summaryDate),
      'model': serializer.toJson<String?>(model),
      'newsCount': serializer.toJson<int?>(newsCount),
      'summaryJson': serializer.toJson<String?>(summaryJson),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'cachedAt': serializer.toJson<String>(cachedAt),
    };
  }

  CompanyNewsCache copyWith({
    int? id,
    String? symbol,
    bool? found,
    Value<String?> summaryDate = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<int?> newsCount = const Value.absent(),
    Value<String?> summaryJson = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    String? cachedAt,
  }) => CompanyNewsCache(
    id: id ?? this.id,
    symbol: symbol ?? this.symbol,
    found: found ?? this.found,
    summaryDate: summaryDate.present ? summaryDate.value : this.summaryDate,
    model: model.present ? model.value : this.model,
    newsCount: newsCount.present ? newsCount.value : this.newsCount,
    summaryJson: summaryJson.present ? summaryJson.value : this.summaryJson,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CompanyNewsCache copyWithCompanion(CompanyNewsCachesCompanion data) {
    return CompanyNewsCache(
      id: data.id.present ? data.id.value : this.id,
      symbol: data.symbol.present ? data.symbol.value : this.symbol,
      found: data.found.present ? data.found.value : this.found,
      summaryDate: data.summaryDate.present
          ? data.summaryDate.value
          : this.summaryDate,
      model: data.model.present ? data.model.value : this.model,
      newsCount: data.newsCount.present ? data.newsCount.value : this.newsCount,
      summaryJson: data.summaryJson.present
          ? data.summaryJson.value
          : this.summaryJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompanyNewsCache(')
          ..write('id: $id, ')
          ..write('symbol: $symbol, ')
          ..write('found: $found, ')
          ..write('summaryDate: $summaryDate, ')
          ..write('model: $model, ')
          ..write('newsCount: $newsCount, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    symbol,
    found,
    summaryDate,
    model,
    newsCount,
    summaryJson,
    createdAt,
    updatedAt,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompanyNewsCache &&
          other.id == this.id &&
          other.symbol == this.symbol &&
          other.found == this.found &&
          other.summaryDate == this.summaryDate &&
          other.model == this.model &&
          other.newsCount == this.newsCount &&
          other.summaryJson == this.summaryJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.cachedAt == this.cachedAt);
}

class CompanyNewsCachesCompanion extends UpdateCompanion<CompanyNewsCache> {
  final Value<int> id;
  final Value<String> symbol;
  final Value<bool> found;
  final Value<String?> summaryDate;
  final Value<String?> model;
  final Value<int?> newsCount;
  final Value<String?> summaryJson;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<String> cachedAt;
  const CompanyNewsCachesCompanion({
    this.id = const Value.absent(),
    this.symbol = const Value.absent(),
    this.found = const Value.absent(),
    this.summaryDate = const Value.absent(),
    this.model = const Value.absent(),
    this.newsCount = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CompanyNewsCachesCompanion.insert({
    this.id = const Value.absent(),
    required String symbol,
    this.found = const Value.absent(),
    this.summaryDate = const Value.absent(),
    this.model = const Value.absent(),
    this.newsCount = const Value.absent(),
    this.summaryJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String cachedAt,
  }) : symbol = Value(symbol),
       cachedAt = Value(cachedAt);
  static Insertable<CompanyNewsCache> custom({
    Expression<int>? id,
    Expression<String>? symbol,
    Expression<bool>? found,
    Expression<String>? summaryDate,
    Expression<String>? model,
    Expression<int>? newsCount,
    Expression<String>? summaryJson,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (symbol != null) 'symbol': symbol,
      if (found != null) 'found': found,
      if (summaryDate != null) 'summary_date': summaryDate,
      if (model != null) 'model': model,
      if (newsCount != null) 'news_count': newsCount,
      if (summaryJson != null) 'summary_json': summaryJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CompanyNewsCachesCompanion copyWith({
    Value<int>? id,
    Value<String>? symbol,
    Value<bool>? found,
    Value<String?>? summaryDate,
    Value<String?>? model,
    Value<int?>? newsCount,
    Value<String?>? summaryJson,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<String>? cachedAt,
  }) {
    return CompanyNewsCachesCompanion(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      found: found ?? this.found,
      summaryDate: summaryDate ?? this.summaryDate,
      model: model ?? this.model,
      newsCount: newsCount ?? this.newsCount,
      summaryJson: summaryJson ?? this.summaryJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (symbol.present) {
      map['symbol'] = Variable<String>(symbol.value);
    }
    if (found.present) {
      map['found'] = Variable<bool>(found.value);
    }
    if (summaryDate.present) {
      map['summary_date'] = Variable<String>(summaryDate.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (newsCount.present) {
      map['news_count'] = Variable<int>(newsCount.value);
    }
    if (summaryJson.present) {
      map['summary_json'] = Variable<String>(summaryJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<String>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompanyNewsCachesCompanion(')
          ..write('id: $id, ')
          ..write('symbol: $symbol, ')
          ..write('found: $found, ')
          ..write('summaryDate: $summaryDate, ')
          ..write('model: $model, ')
          ..write('newsCount: $newsCount, ')
          ..write('summaryJson: $summaryJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyPortfolioSnapshotsTable extends DailyPortfolioSnapshots
    with TableInfo<$DailyPortfolioSnapshotsTable, DailyPortfolioSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPortfolioSnapshotsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _snapshotDateMeta = const VerificationMeta(
    'snapshotDate',
  );
  @override
  late final GeneratedColumn<String> snapshotDate = GeneratedColumn<String>(
    'snapshot_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPurchaseAmountMeta =
      const VerificationMeta('totalPurchaseAmount');
  @override
  late final GeneratedColumn<double> totalPurchaseAmount =
      GeneratedColumn<double>(
        'total_purchase_amount',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _totalValuationAmountMeta =
      const VerificationMeta('totalValuationAmount');
  @override
  late final GeneratedColumn<double> totalValuationAmount =
      GeneratedColumn<double>(
        'total_valuation_amount',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _profitAmountMeta = const VerificationMeta(
    'profitAmount',
  );
  @override
  late final GeneratedColumn<double> profitAmount = GeneratedColumn<double>(
    'profit_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profitRateMeta = const VerificationMeta(
    'profitRate',
  );
  @override
  late final GeneratedColumn<double> profitRate = GeneratedColumn<double>(
    'profit_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exchangeRateMeta = const VerificationMeta(
    'exchangeRate',
  );
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
    'exchange_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    snapshotDate,
    totalPurchaseAmount,
    totalValuationAmount,
    profitAmount,
    profitRate,
    exchangeRate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_portfolio_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPortfolioSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('snapshot_date')) {
      context.handle(
        _snapshotDateMeta,
        snapshotDate.isAcceptableOrUnknown(
          data['snapshot_date']!,
          _snapshotDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotDateMeta);
    }
    if (data.containsKey('total_purchase_amount')) {
      context.handle(
        _totalPurchaseAmountMeta,
        totalPurchaseAmount.isAcceptableOrUnknown(
          data['total_purchase_amount']!,
          _totalPurchaseAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPurchaseAmountMeta);
    }
    if (data.containsKey('total_valuation_amount')) {
      context.handle(
        _totalValuationAmountMeta,
        totalValuationAmount.isAcceptableOrUnknown(
          data['total_valuation_amount']!,
          _totalValuationAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalValuationAmountMeta);
    }
    if (data.containsKey('profit_amount')) {
      context.handle(
        _profitAmountMeta,
        profitAmount.isAcceptableOrUnknown(
          data['profit_amount']!,
          _profitAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profitAmountMeta);
    }
    if (data.containsKey('profit_rate')) {
      context.handle(
        _profitRateMeta,
        profitRate.isAcceptableOrUnknown(data['profit_rate']!, _profitRateMeta),
      );
    } else if (isInserting) {
      context.missing(_profitRateMeta);
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
        _exchangeRateMeta,
        exchangeRate.isAcceptableOrUnknown(
          data['exchange_rate']!,
          _exchangeRateMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyPortfolioSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPortfolioSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      snapshotDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_date'],
      )!,
      totalPurchaseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_purchase_amount'],
      )!,
      totalValuationAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_valuation_amount'],
      )!,
      profitAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_amount'],
      )!,
      profitRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_rate'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DailyPortfolioSnapshotsTable createAlias(String alias) {
    return $DailyPortfolioSnapshotsTable(attachedDatabase, alias);
  }
}

class DailyPortfolioSnapshot extends DataClass
    implements Insertable<DailyPortfolioSnapshot> {
  final int id;
  final String snapshotDate;
  final double totalPurchaseAmount;
  final double totalValuationAmount;
  final double profitAmount;
  final double profitRate;
  final double exchangeRate;
  final String createdAt;
  const DailyPortfolioSnapshot({
    required this.id,
    required this.snapshotDate,
    required this.totalPurchaseAmount,
    required this.totalValuationAmount,
    required this.profitAmount,
    required this.profitRate,
    required this.exchangeRate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['snapshot_date'] = Variable<String>(snapshotDate);
    map['total_purchase_amount'] = Variable<double>(totalPurchaseAmount);
    map['total_valuation_amount'] = Variable<double>(totalValuationAmount);
    map['profit_amount'] = Variable<double>(profitAmount);
    map['profit_rate'] = Variable<double>(profitRate);
    map['exchange_rate'] = Variable<double>(exchangeRate);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  DailyPortfolioSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return DailyPortfolioSnapshotsCompanion(
      id: Value(id),
      snapshotDate: Value(snapshotDate),
      totalPurchaseAmount: Value(totalPurchaseAmount),
      totalValuationAmount: Value(totalValuationAmount),
      profitAmount: Value(profitAmount),
      profitRate: Value(profitRate),
      exchangeRate: Value(exchangeRate),
      createdAt: Value(createdAt),
    );
  }

  factory DailyPortfolioSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPortfolioSnapshot(
      id: serializer.fromJson<int>(json['id']),
      snapshotDate: serializer.fromJson<String>(json['snapshotDate']),
      totalPurchaseAmount: serializer.fromJson<double>(
        json['totalPurchaseAmount'],
      ),
      totalValuationAmount: serializer.fromJson<double>(
        json['totalValuationAmount'],
      ),
      profitAmount: serializer.fromJson<double>(json['profitAmount']),
      profitRate: serializer.fromJson<double>(json['profitRate']),
      exchangeRate: serializer.fromJson<double>(json['exchangeRate']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'snapshotDate': serializer.toJson<String>(snapshotDate),
      'totalPurchaseAmount': serializer.toJson<double>(totalPurchaseAmount),
      'totalValuationAmount': serializer.toJson<double>(totalValuationAmount),
      'profitAmount': serializer.toJson<double>(profitAmount),
      'profitRate': serializer.toJson<double>(profitRate),
      'exchangeRate': serializer.toJson<double>(exchangeRate),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  DailyPortfolioSnapshot copyWith({
    int? id,
    String? snapshotDate,
    double? totalPurchaseAmount,
    double? totalValuationAmount,
    double? profitAmount,
    double? profitRate,
    double? exchangeRate,
    String? createdAt,
  }) => DailyPortfolioSnapshot(
    id: id ?? this.id,
    snapshotDate: snapshotDate ?? this.snapshotDate,
    totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
    totalValuationAmount: totalValuationAmount ?? this.totalValuationAmount,
    profitAmount: profitAmount ?? this.profitAmount,
    profitRate: profitRate ?? this.profitRate,
    exchangeRate: exchangeRate ?? this.exchangeRate,
    createdAt: createdAt ?? this.createdAt,
  );
  DailyPortfolioSnapshot copyWithCompanion(
    DailyPortfolioSnapshotsCompanion data,
  ) {
    return DailyPortfolioSnapshot(
      id: data.id.present ? data.id.value : this.id,
      snapshotDate: data.snapshotDate.present
          ? data.snapshotDate.value
          : this.snapshotDate,
      totalPurchaseAmount: data.totalPurchaseAmount.present
          ? data.totalPurchaseAmount.value
          : this.totalPurchaseAmount,
      totalValuationAmount: data.totalValuationAmount.present
          ? data.totalValuationAmount.value
          : this.totalValuationAmount,
      profitAmount: data.profitAmount.present
          ? data.profitAmount.value
          : this.profitAmount,
      profitRate: data.profitRate.present
          ? data.profitRate.value
          : this.profitRate,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPortfolioSnapshot(')
          ..write('id: $id, ')
          ..write('snapshotDate: $snapshotDate, ')
          ..write('totalPurchaseAmount: $totalPurchaseAmount, ')
          ..write('totalValuationAmount: $totalValuationAmount, ')
          ..write('profitAmount: $profitAmount, ')
          ..write('profitRate: $profitRate, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    snapshotDate,
    totalPurchaseAmount,
    totalValuationAmount,
    profitAmount,
    profitRate,
    exchangeRate,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPortfolioSnapshot &&
          other.id == this.id &&
          other.snapshotDate == this.snapshotDate &&
          other.totalPurchaseAmount == this.totalPurchaseAmount &&
          other.totalValuationAmount == this.totalValuationAmount &&
          other.profitAmount == this.profitAmount &&
          other.profitRate == this.profitRate &&
          other.exchangeRate == this.exchangeRate &&
          other.createdAt == this.createdAt);
}

class DailyPortfolioSnapshotsCompanion
    extends UpdateCompanion<DailyPortfolioSnapshot> {
  final Value<int> id;
  final Value<String> snapshotDate;
  final Value<double> totalPurchaseAmount;
  final Value<double> totalValuationAmount;
  final Value<double> profitAmount;
  final Value<double> profitRate;
  final Value<double> exchangeRate;
  final Value<String> createdAt;
  const DailyPortfolioSnapshotsCompanion({
    this.id = const Value.absent(),
    this.snapshotDate = const Value.absent(),
    this.totalPurchaseAmount = const Value.absent(),
    this.totalValuationAmount = const Value.absent(),
    this.profitAmount = const Value.absent(),
    this.profitRate = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DailyPortfolioSnapshotsCompanion.insert({
    this.id = const Value.absent(),
    required String snapshotDate,
    required double totalPurchaseAmount,
    required double totalValuationAmount,
    required double profitAmount,
    required double profitRate,
    this.exchangeRate = const Value.absent(),
    required String createdAt,
  }) : snapshotDate = Value(snapshotDate),
       totalPurchaseAmount = Value(totalPurchaseAmount),
       totalValuationAmount = Value(totalValuationAmount),
       profitAmount = Value(profitAmount),
       profitRate = Value(profitRate),
       createdAt = Value(createdAt);
  static Insertable<DailyPortfolioSnapshot> custom({
    Expression<int>? id,
    Expression<String>? snapshotDate,
    Expression<double>? totalPurchaseAmount,
    Expression<double>? totalValuationAmount,
    Expression<double>? profitAmount,
    Expression<double>? profitRate,
    Expression<double>? exchangeRate,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (snapshotDate != null) 'snapshot_date': snapshotDate,
      if (totalPurchaseAmount != null)
        'total_purchase_amount': totalPurchaseAmount,
      if (totalValuationAmount != null)
        'total_valuation_amount': totalValuationAmount,
      if (profitAmount != null) 'profit_amount': profitAmount,
      if (profitRate != null) 'profit_rate': profitRate,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DailyPortfolioSnapshotsCompanion copyWith({
    Value<int>? id,
    Value<String>? snapshotDate,
    Value<double>? totalPurchaseAmount,
    Value<double>? totalValuationAmount,
    Value<double>? profitAmount,
    Value<double>? profitRate,
    Value<double>? exchangeRate,
    Value<String>? createdAt,
  }) {
    return DailyPortfolioSnapshotsCompanion(
      id: id ?? this.id,
      snapshotDate: snapshotDate ?? this.snapshotDate,
      totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
      totalValuationAmount: totalValuationAmount ?? this.totalValuationAmount,
      profitAmount: profitAmount ?? this.profitAmount,
      profitRate: profitRate ?? this.profitRate,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (snapshotDate.present) {
      map['snapshot_date'] = Variable<String>(snapshotDate.value);
    }
    if (totalPurchaseAmount.present) {
      map['total_purchase_amount'] = Variable<double>(
        totalPurchaseAmount.value,
      );
    }
    if (totalValuationAmount.present) {
      map['total_valuation_amount'] = Variable<double>(
        totalValuationAmount.value,
      );
    }
    if (profitAmount.present) {
      map['profit_amount'] = Variable<double>(profitAmount.value);
    }
    if (profitRate.present) {
      map['profit_rate'] = Variable<double>(profitRate.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPortfolioSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('snapshotDate: $snapshotDate, ')
          ..write('totalPurchaseAmount: $totalPurchaseAmount, ')
          ..write('totalValuationAmount: $totalValuationAmount, ')
          ..write('profitAmount: $profitAmount, ')
          ..write('profitRate: $profitRate, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DailyPortfolioSnapshotItemsTable extends DailyPortfolioSnapshotItems
    with
        TableInfo<
          $DailyPortfolioSnapshotItemsTable,
          DailyPortfolioSnapshotItem
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPortfolioSnapshotItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _snapshotIdMeta = const VerificationMeta(
    'snapshotId',
  );
  @override
  late final GeneratedColumn<int> snapshotId = GeneratedColumn<int>(
    'snapshot_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES daily_portfolio_snapshots (id)',
    ),
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assets (id)',
    ),
  );
  static const VerificationMeta _assetClientIdMeta = const VerificationMeta(
    'assetClientId',
  );
  @override
  late final GeneratedColumn<String> assetClientId = GeneratedColumn<String>(
    'asset_client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetTitleMeta = const VerificationMeta(
    'assetTitle',
  );
  @override
  late final GeneratedColumn<String> assetTitle = GeneratedColumn<String>(
    'asset_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPurchaseAmountMeta =
      const VerificationMeta('totalPurchaseAmount');
  @override
  late final GeneratedColumn<double> totalPurchaseAmount =
      GeneratedColumn<double>(
        'total_purchase_amount',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _totalValuationAmountMeta =
      const VerificationMeta('totalValuationAmount');
  @override
  late final GeneratedColumn<double> totalValuationAmount =
      GeneratedColumn<double>(
        'total_valuation_amount',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _profitAmountMeta = const VerificationMeta(
    'profitAmount',
  );
  @override
  late final GeneratedColumn<double> profitAmount = GeneratedColumn<double>(
    'profit_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profitRateMeta = const VerificationMeta(
    'profitRate',
  );
  @override
  late final GeneratedColumn<double> profitRate = GeneratedColumn<double>(
    'profit_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _holdingCountMeta = const VerificationMeta(
    'holdingCount',
  );
  @override
  late final GeneratedColumn<int> holdingCount = GeneratedColumn<int>(
    'holding_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    snapshotId,
    assetId,
    assetClientId,
    assetTitle,
    totalPurchaseAmount,
    totalValuationAmount,
    profitAmount,
    profitRate,
    holdingCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_portfolio_snapshot_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPortfolioSnapshotItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('snapshot_id')) {
      context.handle(
        _snapshotIdMeta,
        snapshotId.isAcceptableOrUnknown(data['snapshot_id']!, _snapshotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotIdMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('asset_client_id')) {
      context.handle(
        _assetClientIdMeta,
        assetClientId.isAcceptableOrUnknown(
          data['asset_client_id']!,
          _assetClientIdMeta,
        ),
      );
    }
    if (data.containsKey('asset_title')) {
      context.handle(
        _assetTitleMeta,
        assetTitle.isAcceptableOrUnknown(data['asset_title']!, _assetTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_assetTitleMeta);
    }
    if (data.containsKey('total_purchase_amount')) {
      context.handle(
        _totalPurchaseAmountMeta,
        totalPurchaseAmount.isAcceptableOrUnknown(
          data['total_purchase_amount']!,
          _totalPurchaseAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPurchaseAmountMeta);
    }
    if (data.containsKey('total_valuation_amount')) {
      context.handle(
        _totalValuationAmountMeta,
        totalValuationAmount.isAcceptableOrUnknown(
          data['total_valuation_amount']!,
          _totalValuationAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalValuationAmountMeta);
    }
    if (data.containsKey('profit_amount')) {
      context.handle(
        _profitAmountMeta,
        profitAmount.isAcceptableOrUnknown(
          data['profit_amount']!,
          _profitAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profitAmountMeta);
    }
    if (data.containsKey('profit_rate')) {
      context.handle(
        _profitRateMeta,
        profitRate.isAcceptableOrUnknown(data['profit_rate']!, _profitRateMeta),
      );
    } else if (isInserting) {
      context.missing(_profitRateMeta);
    }
    if (data.containsKey('holding_count')) {
      context.handle(
        _holdingCountMeta,
        holdingCount.isAcceptableOrUnknown(
          data['holding_count']!,
          _holdingCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_holdingCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyPortfolioSnapshotItem map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPortfolioSnapshotItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      snapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snapshot_id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      )!,
      assetClientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_client_id'],
      ),
      assetTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_title'],
      )!,
      totalPurchaseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_purchase_amount'],
      )!,
      totalValuationAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_valuation_amount'],
      )!,
      profitAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_amount'],
      )!,
      profitRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_rate'],
      )!,
      holdingCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}holding_count'],
      )!,
    );
  }

  @override
  $DailyPortfolioSnapshotItemsTable createAlias(String alias) {
    return $DailyPortfolioSnapshotItemsTable(attachedDatabase, alias);
  }
}

class DailyPortfolioSnapshotItem extends DataClass
    implements Insertable<DailyPortfolioSnapshotItem> {
  final int id;
  final int snapshotId;
  final int assetId;
  final String? assetClientId;
  final String assetTitle;
  final double totalPurchaseAmount;
  final double totalValuationAmount;
  final double profitAmount;
  final double profitRate;
  final int holdingCount;
  const DailyPortfolioSnapshotItem({
    required this.id,
    required this.snapshotId,
    required this.assetId,
    this.assetClientId,
    required this.assetTitle,
    required this.totalPurchaseAmount,
    required this.totalValuationAmount,
    required this.profitAmount,
    required this.profitRate,
    required this.holdingCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['snapshot_id'] = Variable<int>(snapshotId);
    map['asset_id'] = Variable<int>(assetId);
    if (!nullToAbsent || assetClientId != null) {
      map['asset_client_id'] = Variable<String>(assetClientId);
    }
    map['asset_title'] = Variable<String>(assetTitle);
    map['total_purchase_amount'] = Variable<double>(totalPurchaseAmount);
    map['total_valuation_amount'] = Variable<double>(totalValuationAmount);
    map['profit_amount'] = Variable<double>(profitAmount);
    map['profit_rate'] = Variable<double>(profitRate);
    map['holding_count'] = Variable<int>(holdingCount);
    return map;
  }

  DailyPortfolioSnapshotItemsCompanion toCompanion(bool nullToAbsent) {
    return DailyPortfolioSnapshotItemsCompanion(
      id: Value(id),
      snapshotId: Value(snapshotId),
      assetId: Value(assetId),
      assetClientId: assetClientId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetClientId),
      assetTitle: Value(assetTitle),
      totalPurchaseAmount: Value(totalPurchaseAmount),
      totalValuationAmount: Value(totalValuationAmount),
      profitAmount: Value(profitAmount),
      profitRate: Value(profitRate),
      holdingCount: Value(holdingCount),
    );
  }

  factory DailyPortfolioSnapshotItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPortfolioSnapshotItem(
      id: serializer.fromJson<int>(json['id']),
      snapshotId: serializer.fromJson<int>(json['snapshotId']),
      assetId: serializer.fromJson<int>(json['assetId']),
      assetClientId: serializer.fromJson<String?>(json['assetClientId']),
      assetTitle: serializer.fromJson<String>(json['assetTitle']),
      totalPurchaseAmount: serializer.fromJson<double>(
        json['totalPurchaseAmount'],
      ),
      totalValuationAmount: serializer.fromJson<double>(
        json['totalValuationAmount'],
      ),
      profitAmount: serializer.fromJson<double>(json['profitAmount']),
      profitRate: serializer.fromJson<double>(json['profitRate']),
      holdingCount: serializer.fromJson<int>(json['holdingCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'snapshotId': serializer.toJson<int>(snapshotId),
      'assetId': serializer.toJson<int>(assetId),
      'assetClientId': serializer.toJson<String?>(assetClientId),
      'assetTitle': serializer.toJson<String>(assetTitle),
      'totalPurchaseAmount': serializer.toJson<double>(totalPurchaseAmount),
      'totalValuationAmount': serializer.toJson<double>(totalValuationAmount),
      'profitAmount': serializer.toJson<double>(profitAmount),
      'profitRate': serializer.toJson<double>(profitRate),
      'holdingCount': serializer.toJson<int>(holdingCount),
    };
  }

  DailyPortfolioSnapshotItem copyWith({
    int? id,
    int? snapshotId,
    int? assetId,
    Value<String?> assetClientId = const Value.absent(),
    String? assetTitle,
    double? totalPurchaseAmount,
    double? totalValuationAmount,
    double? profitAmount,
    double? profitRate,
    int? holdingCount,
  }) => DailyPortfolioSnapshotItem(
    id: id ?? this.id,
    snapshotId: snapshotId ?? this.snapshotId,
    assetId: assetId ?? this.assetId,
    assetClientId: assetClientId.present
        ? assetClientId.value
        : this.assetClientId,
    assetTitle: assetTitle ?? this.assetTitle,
    totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
    totalValuationAmount: totalValuationAmount ?? this.totalValuationAmount,
    profitAmount: profitAmount ?? this.profitAmount,
    profitRate: profitRate ?? this.profitRate,
    holdingCount: holdingCount ?? this.holdingCount,
  );
  DailyPortfolioSnapshotItem copyWithCompanion(
    DailyPortfolioSnapshotItemsCompanion data,
  ) {
    return DailyPortfolioSnapshotItem(
      id: data.id.present ? data.id.value : this.id,
      snapshotId: data.snapshotId.present
          ? data.snapshotId.value
          : this.snapshotId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      assetClientId: data.assetClientId.present
          ? data.assetClientId.value
          : this.assetClientId,
      assetTitle: data.assetTitle.present
          ? data.assetTitle.value
          : this.assetTitle,
      totalPurchaseAmount: data.totalPurchaseAmount.present
          ? data.totalPurchaseAmount.value
          : this.totalPurchaseAmount,
      totalValuationAmount: data.totalValuationAmount.present
          ? data.totalValuationAmount.value
          : this.totalValuationAmount,
      profitAmount: data.profitAmount.present
          ? data.profitAmount.value
          : this.profitAmount,
      profitRate: data.profitRate.present
          ? data.profitRate.value
          : this.profitRate,
      holdingCount: data.holdingCount.present
          ? data.holdingCount.value
          : this.holdingCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPortfolioSnapshotItem(')
          ..write('id: $id, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('assetId: $assetId, ')
          ..write('assetClientId: $assetClientId, ')
          ..write('assetTitle: $assetTitle, ')
          ..write('totalPurchaseAmount: $totalPurchaseAmount, ')
          ..write('totalValuationAmount: $totalValuationAmount, ')
          ..write('profitAmount: $profitAmount, ')
          ..write('profitRate: $profitRate, ')
          ..write('holdingCount: $holdingCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    snapshotId,
    assetId,
    assetClientId,
    assetTitle,
    totalPurchaseAmount,
    totalValuationAmount,
    profitAmount,
    profitRate,
    holdingCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPortfolioSnapshotItem &&
          other.id == this.id &&
          other.snapshotId == this.snapshotId &&
          other.assetId == this.assetId &&
          other.assetClientId == this.assetClientId &&
          other.assetTitle == this.assetTitle &&
          other.totalPurchaseAmount == this.totalPurchaseAmount &&
          other.totalValuationAmount == this.totalValuationAmount &&
          other.profitAmount == this.profitAmount &&
          other.profitRate == this.profitRate &&
          other.holdingCount == this.holdingCount);
}

class DailyPortfolioSnapshotItemsCompanion
    extends UpdateCompanion<DailyPortfolioSnapshotItem> {
  final Value<int> id;
  final Value<int> snapshotId;
  final Value<int> assetId;
  final Value<String?> assetClientId;
  final Value<String> assetTitle;
  final Value<double> totalPurchaseAmount;
  final Value<double> totalValuationAmount;
  final Value<double> profitAmount;
  final Value<double> profitRate;
  final Value<int> holdingCount;
  const DailyPortfolioSnapshotItemsCompanion({
    this.id = const Value.absent(),
    this.snapshotId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetClientId = const Value.absent(),
    this.assetTitle = const Value.absent(),
    this.totalPurchaseAmount = const Value.absent(),
    this.totalValuationAmount = const Value.absent(),
    this.profitAmount = const Value.absent(),
    this.profitRate = const Value.absent(),
    this.holdingCount = const Value.absent(),
  });
  DailyPortfolioSnapshotItemsCompanion.insert({
    this.id = const Value.absent(),
    required int snapshotId,
    required int assetId,
    this.assetClientId = const Value.absent(),
    required String assetTitle,
    required double totalPurchaseAmount,
    required double totalValuationAmount,
    required double profitAmount,
    required double profitRate,
    required int holdingCount,
  }) : snapshotId = Value(snapshotId),
       assetId = Value(assetId),
       assetTitle = Value(assetTitle),
       totalPurchaseAmount = Value(totalPurchaseAmount),
       totalValuationAmount = Value(totalValuationAmount),
       profitAmount = Value(profitAmount),
       profitRate = Value(profitRate),
       holdingCount = Value(holdingCount);
  static Insertable<DailyPortfolioSnapshotItem> custom({
    Expression<int>? id,
    Expression<int>? snapshotId,
    Expression<int>? assetId,
    Expression<String>? assetClientId,
    Expression<String>? assetTitle,
    Expression<double>? totalPurchaseAmount,
    Expression<double>? totalValuationAmount,
    Expression<double>? profitAmount,
    Expression<double>? profitRate,
    Expression<int>? holdingCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (assetId != null) 'asset_id': assetId,
      if (assetClientId != null) 'asset_client_id': assetClientId,
      if (assetTitle != null) 'asset_title': assetTitle,
      if (totalPurchaseAmount != null)
        'total_purchase_amount': totalPurchaseAmount,
      if (totalValuationAmount != null)
        'total_valuation_amount': totalValuationAmount,
      if (profitAmount != null) 'profit_amount': profitAmount,
      if (profitRate != null) 'profit_rate': profitRate,
      if (holdingCount != null) 'holding_count': holdingCount,
    });
  }

  DailyPortfolioSnapshotItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? snapshotId,
    Value<int>? assetId,
    Value<String?>? assetClientId,
    Value<String>? assetTitle,
    Value<double>? totalPurchaseAmount,
    Value<double>? totalValuationAmount,
    Value<double>? profitAmount,
    Value<double>? profitRate,
    Value<int>? holdingCount,
  }) {
    return DailyPortfolioSnapshotItemsCompanion(
      id: id ?? this.id,
      snapshotId: snapshotId ?? this.snapshotId,
      assetId: assetId ?? this.assetId,
      assetClientId: assetClientId ?? this.assetClientId,
      assetTitle: assetTitle ?? this.assetTitle,
      totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
      totalValuationAmount: totalValuationAmount ?? this.totalValuationAmount,
      profitAmount: profitAmount ?? this.profitAmount,
      profitRate: profitRate ?? this.profitRate,
      holdingCount: holdingCount ?? this.holdingCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<int>(snapshotId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (assetClientId.present) {
      map['asset_client_id'] = Variable<String>(assetClientId.value);
    }
    if (assetTitle.present) {
      map['asset_title'] = Variable<String>(assetTitle.value);
    }
    if (totalPurchaseAmount.present) {
      map['total_purchase_amount'] = Variable<double>(
        totalPurchaseAmount.value,
      );
    }
    if (totalValuationAmount.present) {
      map['total_valuation_amount'] = Variable<double>(
        totalValuationAmount.value,
      );
    }
    if (profitAmount.present) {
      map['profit_amount'] = Variable<double>(profitAmount.value);
    }
    if (profitRate.present) {
      map['profit_rate'] = Variable<double>(profitRate.value);
    }
    if (holdingCount.present) {
      map['holding_count'] = Variable<int>(holdingCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPortfolioSnapshotItemsCompanion(')
          ..write('id: $id, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('assetId: $assetId, ')
          ..write('assetClientId: $assetClientId, ')
          ..write('assetTitle: $assetTitle, ')
          ..write('totalPurchaseAmount: $totalPurchaseAmount, ')
          ..write('totalValuationAmount: $totalValuationAmount, ')
          ..write('profitAmount: $profitAmount, ')
          ..write('profitRate: $profitRate, ')
          ..write('holdingCount: $holdingCount')
          ..write(')'))
        .toString();
  }
}

class $DailyPortfolioSnapshotHoldingItemsTable
    extends DailyPortfolioSnapshotHoldingItems
    with
        TableInfo<
          $DailyPortfolioSnapshotHoldingItemsTable,
          DailyPortfolioSnapshotHoldingItem
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPortfolioSnapshotHoldingItemsTable(
    this.attachedDatabase, [
    this._alias,
  ]);
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
  static const VerificationMeta _snapshotIdMeta = const VerificationMeta(
    'snapshotId',
  );
  @override
  late final GeneratedColumn<int> snapshotId = GeneratedColumn<int>(
    'snapshot_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES daily_portfolio_snapshots (id)',
    ),
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetClientIdMeta = const VerificationMeta(
    'assetClientId',
  );
  @override
  late final GeneratedColumn<String> assetClientId = GeneratedColumn<String>(
    'asset_client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetTitleMeta = const VerificationMeta(
    'assetTitle',
  );
  @override
  late final GeneratedColumn<String> assetTitle = GeneratedColumn<String>(
    'asset_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _holdingIdMeta = const VerificationMeta(
    'holdingId',
  );
  @override
  late final GeneratedColumn<int> holdingId = GeneratedColumn<int>(
    'holding_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _holdingClientIdMeta = const VerificationMeta(
    'holdingClientId',
  );
  @override
  late final GeneratedColumn<String> holdingClientId = GeneratedColumn<String>(
    'holding_client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _holdingNameMeta = const VerificationMeta(
    'holdingName',
  );
  @override
  late final GeneratedColumn<String> holdingName = GeneratedColumn<String>(
    'holding_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _holdingSymbolMeta = const VerificationMeta(
    'holdingSymbol',
  );
  @override
  late final GeneratedColumn<String> holdingSymbol = GeneratedColumn<String>(
    'holding_symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPurchaseAmountMeta =
      const VerificationMeta('totalPurchaseAmount');
  @override
  late final GeneratedColumn<double> totalPurchaseAmount =
      GeneratedColumn<double>(
        'total_purchase_amount',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _totalValuationAmountMeta =
      const VerificationMeta('totalValuationAmount');
  @override
  late final GeneratedColumn<double> totalValuationAmount =
      GeneratedColumn<double>(
        'total_valuation_amount',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _profitAmountMeta = const VerificationMeta(
    'profitAmount',
  );
  @override
  late final GeneratedColumn<double> profitAmount = GeneratedColumn<double>(
    'profit_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profitRateMeta = const VerificationMeta(
    'profitRate',
  );
  @override
  late final GeneratedColumn<double> profitRate = GeneratedColumn<double>(
    'profit_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    snapshotId,
    assetId,
    assetClientId,
    assetTitle,
    holdingId,
    holdingClientId,
    holdingName,
    holdingSymbol,
    currencyCode,
    quantity,
    totalPurchaseAmount,
    totalValuationAmount,
    profitAmount,
    profitRate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_portfolio_snapshot_holding_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPortfolioSnapshotHoldingItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('snapshot_id')) {
      context.handle(
        _snapshotIdMeta,
        snapshotId.isAcceptableOrUnknown(data['snapshot_id']!, _snapshotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotIdMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    if (data.containsKey('asset_client_id')) {
      context.handle(
        _assetClientIdMeta,
        assetClientId.isAcceptableOrUnknown(
          data['asset_client_id']!,
          _assetClientIdMeta,
        ),
      );
    }
    if (data.containsKey('asset_title')) {
      context.handle(
        _assetTitleMeta,
        assetTitle.isAcceptableOrUnknown(data['asset_title']!, _assetTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_assetTitleMeta);
    }
    if (data.containsKey('holding_id')) {
      context.handle(
        _holdingIdMeta,
        holdingId.isAcceptableOrUnknown(data['holding_id']!, _holdingIdMeta),
      );
    }
    if (data.containsKey('holding_client_id')) {
      context.handle(
        _holdingClientIdMeta,
        holdingClientId.isAcceptableOrUnknown(
          data['holding_client_id']!,
          _holdingClientIdMeta,
        ),
      );
    }
    if (data.containsKey('holding_name')) {
      context.handle(
        _holdingNameMeta,
        holdingName.isAcceptableOrUnknown(
          data['holding_name']!,
          _holdingNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_holdingNameMeta);
    }
    if (data.containsKey('holding_symbol')) {
      context.handle(
        _holdingSymbolMeta,
        holdingSymbol.isAcceptableOrUnknown(
          data['holding_symbol']!,
          _holdingSymbolMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_holdingSymbolMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('total_purchase_amount')) {
      context.handle(
        _totalPurchaseAmountMeta,
        totalPurchaseAmount.isAcceptableOrUnknown(
          data['total_purchase_amount']!,
          _totalPurchaseAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPurchaseAmountMeta);
    }
    if (data.containsKey('total_valuation_amount')) {
      context.handle(
        _totalValuationAmountMeta,
        totalValuationAmount.isAcceptableOrUnknown(
          data['total_valuation_amount']!,
          _totalValuationAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalValuationAmountMeta);
    }
    if (data.containsKey('profit_amount')) {
      context.handle(
        _profitAmountMeta,
        profitAmount.isAcceptableOrUnknown(
          data['profit_amount']!,
          _profitAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_profitAmountMeta);
    }
    if (data.containsKey('profit_rate')) {
      context.handle(
        _profitRateMeta,
        profitRate.isAcceptableOrUnknown(data['profit_rate']!, _profitRateMeta),
      );
    } else if (isInserting) {
      context.missing(_profitRateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyPortfolioSnapshotHoldingItem map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPortfolioSnapshotHoldingItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      snapshotId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snapshot_id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      ),
      assetClientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_client_id'],
      ),
      assetTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_title'],
      )!,
      holdingId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}holding_id'],
      ),
      holdingClientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}holding_client_id'],
      ),
      holdingName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}holding_name'],
      )!,
      holdingSymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}holding_symbol'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      totalPurchaseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_purchase_amount'],
      )!,
      totalValuationAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_valuation_amount'],
      )!,
      profitAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_amount'],
      )!,
      profitRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}profit_rate'],
      )!,
    );
  }

  @override
  $DailyPortfolioSnapshotHoldingItemsTable createAlias(String alias) {
    return $DailyPortfolioSnapshotHoldingItemsTable(attachedDatabase, alias);
  }
}

class DailyPortfolioSnapshotHoldingItem extends DataClass
    implements Insertable<DailyPortfolioSnapshotHoldingItem> {
  final int id;
  final int snapshotId;
  final int? assetId;
  final String? assetClientId;
  final String assetTitle;
  final int? holdingId;
  final String? holdingClientId;
  final String holdingName;
  final String holdingSymbol;
  final String currencyCode;
  final double quantity;
  final double totalPurchaseAmount;
  final double totalValuationAmount;
  final double profitAmount;
  final double profitRate;
  const DailyPortfolioSnapshotHoldingItem({
    required this.id,
    required this.snapshotId,
    this.assetId,
    this.assetClientId,
    required this.assetTitle,
    this.holdingId,
    this.holdingClientId,
    required this.holdingName,
    required this.holdingSymbol,
    required this.currencyCode,
    required this.quantity,
    required this.totalPurchaseAmount,
    required this.totalValuationAmount,
    required this.profitAmount,
    required this.profitRate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['snapshot_id'] = Variable<int>(snapshotId);
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<int>(assetId);
    }
    if (!nullToAbsent || assetClientId != null) {
      map['asset_client_id'] = Variable<String>(assetClientId);
    }
    map['asset_title'] = Variable<String>(assetTitle);
    if (!nullToAbsent || holdingId != null) {
      map['holding_id'] = Variable<int>(holdingId);
    }
    if (!nullToAbsent || holdingClientId != null) {
      map['holding_client_id'] = Variable<String>(holdingClientId);
    }
    map['holding_name'] = Variable<String>(holdingName);
    map['holding_symbol'] = Variable<String>(holdingSymbol);
    map['currency_code'] = Variable<String>(currencyCode);
    map['quantity'] = Variable<double>(quantity);
    map['total_purchase_amount'] = Variable<double>(totalPurchaseAmount);
    map['total_valuation_amount'] = Variable<double>(totalValuationAmount);
    map['profit_amount'] = Variable<double>(profitAmount);
    map['profit_rate'] = Variable<double>(profitRate);
    return map;
  }

  DailyPortfolioSnapshotHoldingItemsCompanion toCompanion(bool nullToAbsent) {
    return DailyPortfolioSnapshotHoldingItemsCompanion(
      id: Value(id),
      snapshotId: Value(snapshotId),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      assetClientId: assetClientId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetClientId),
      assetTitle: Value(assetTitle),
      holdingId: holdingId == null && nullToAbsent
          ? const Value.absent()
          : Value(holdingId),
      holdingClientId: holdingClientId == null && nullToAbsent
          ? const Value.absent()
          : Value(holdingClientId),
      holdingName: Value(holdingName),
      holdingSymbol: Value(holdingSymbol),
      currencyCode: Value(currencyCode),
      quantity: Value(quantity),
      totalPurchaseAmount: Value(totalPurchaseAmount),
      totalValuationAmount: Value(totalValuationAmount),
      profitAmount: Value(profitAmount),
      profitRate: Value(profitRate),
    );
  }

  factory DailyPortfolioSnapshotHoldingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPortfolioSnapshotHoldingItem(
      id: serializer.fromJson<int>(json['id']),
      snapshotId: serializer.fromJson<int>(json['snapshotId']),
      assetId: serializer.fromJson<int?>(json['assetId']),
      assetClientId: serializer.fromJson<String?>(json['assetClientId']),
      assetTitle: serializer.fromJson<String>(json['assetTitle']),
      holdingId: serializer.fromJson<int?>(json['holdingId']),
      holdingClientId: serializer.fromJson<String?>(json['holdingClientId']),
      holdingName: serializer.fromJson<String>(json['holdingName']),
      holdingSymbol: serializer.fromJson<String>(json['holdingSymbol']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      quantity: serializer.fromJson<double>(json['quantity']),
      totalPurchaseAmount: serializer.fromJson<double>(
        json['totalPurchaseAmount'],
      ),
      totalValuationAmount: serializer.fromJson<double>(
        json['totalValuationAmount'],
      ),
      profitAmount: serializer.fromJson<double>(json['profitAmount']),
      profitRate: serializer.fromJson<double>(json['profitRate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'snapshotId': serializer.toJson<int>(snapshotId),
      'assetId': serializer.toJson<int?>(assetId),
      'assetClientId': serializer.toJson<String?>(assetClientId),
      'assetTitle': serializer.toJson<String>(assetTitle),
      'holdingId': serializer.toJson<int?>(holdingId),
      'holdingClientId': serializer.toJson<String?>(holdingClientId),
      'holdingName': serializer.toJson<String>(holdingName),
      'holdingSymbol': serializer.toJson<String>(holdingSymbol),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'quantity': serializer.toJson<double>(quantity),
      'totalPurchaseAmount': serializer.toJson<double>(totalPurchaseAmount),
      'totalValuationAmount': serializer.toJson<double>(totalValuationAmount),
      'profitAmount': serializer.toJson<double>(profitAmount),
      'profitRate': serializer.toJson<double>(profitRate),
    };
  }

  DailyPortfolioSnapshotHoldingItem copyWith({
    int? id,
    int? snapshotId,
    Value<int?> assetId = const Value.absent(),
    Value<String?> assetClientId = const Value.absent(),
    String? assetTitle,
    Value<int?> holdingId = const Value.absent(),
    Value<String?> holdingClientId = const Value.absent(),
    String? holdingName,
    String? holdingSymbol,
    String? currencyCode,
    double? quantity,
    double? totalPurchaseAmount,
    double? totalValuationAmount,
    double? profitAmount,
    double? profitRate,
  }) => DailyPortfolioSnapshotHoldingItem(
    id: id ?? this.id,
    snapshotId: snapshotId ?? this.snapshotId,
    assetId: assetId.present ? assetId.value : this.assetId,
    assetClientId: assetClientId.present
        ? assetClientId.value
        : this.assetClientId,
    assetTitle: assetTitle ?? this.assetTitle,
    holdingId: holdingId.present ? holdingId.value : this.holdingId,
    holdingClientId: holdingClientId.present
        ? holdingClientId.value
        : this.holdingClientId,
    holdingName: holdingName ?? this.holdingName,
    holdingSymbol: holdingSymbol ?? this.holdingSymbol,
    currencyCode: currencyCode ?? this.currencyCode,
    quantity: quantity ?? this.quantity,
    totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
    totalValuationAmount: totalValuationAmount ?? this.totalValuationAmount,
    profitAmount: profitAmount ?? this.profitAmount,
    profitRate: profitRate ?? this.profitRate,
  );
  DailyPortfolioSnapshotHoldingItem copyWithCompanion(
    DailyPortfolioSnapshotHoldingItemsCompanion data,
  ) {
    return DailyPortfolioSnapshotHoldingItem(
      id: data.id.present ? data.id.value : this.id,
      snapshotId: data.snapshotId.present
          ? data.snapshotId.value
          : this.snapshotId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      assetClientId: data.assetClientId.present
          ? data.assetClientId.value
          : this.assetClientId,
      assetTitle: data.assetTitle.present
          ? data.assetTitle.value
          : this.assetTitle,
      holdingId: data.holdingId.present ? data.holdingId.value : this.holdingId,
      holdingClientId: data.holdingClientId.present
          ? data.holdingClientId.value
          : this.holdingClientId,
      holdingName: data.holdingName.present
          ? data.holdingName.value
          : this.holdingName,
      holdingSymbol: data.holdingSymbol.present
          ? data.holdingSymbol.value
          : this.holdingSymbol,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      totalPurchaseAmount: data.totalPurchaseAmount.present
          ? data.totalPurchaseAmount.value
          : this.totalPurchaseAmount,
      totalValuationAmount: data.totalValuationAmount.present
          ? data.totalValuationAmount.value
          : this.totalValuationAmount,
      profitAmount: data.profitAmount.present
          ? data.profitAmount.value
          : this.profitAmount,
      profitRate: data.profitRate.present
          ? data.profitRate.value
          : this.profitRate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPortfolioSnapshotHoldingItem(')
          ..write('id: $id, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('assetId: $assetId, ')
          ..write('assetClientId: $assetClientId, ')
          ..write('assetTitle: $assetTitle, ')
          ..write('holdingId: $holdingId, ')
          ..write('holdingClientId: $holdingClientId, ')
          ..write('holdingName: $holdingName, ')
          ..write('holdingSymbol: $holdingSymbol, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('quantity: $quantity, ')
          ..write('totalPurchaseAmount: $totalPurchaseAmount, ')
          ..write('totalValuationAmount: $totalValuationAmount, ')
          ..write('profitAmount: $profitAmount, ')
          ..write('profitRate: $profitRate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    snapshotId,
    assetId,
    assetClientId,
    assetTitle,
    holdingId,
    holdingClientId,
    holdingName,
    holdingSymbol,
    currencyCode,
    quantity,
    totalPurchaseAmount,
    totalValuationAmount,
    profitAmount,
    profitRate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPortfolioSnapshotHoldingItem &&
          other.id == this.id &&
          other.snapshotId == this.snapshotId &&
          other.assetId == this.assetId &&
          other.assetClientId == this.assetClientId &&
          other.assetTitle == this.assetTitle &&
          other.holdingId == this.holdingId &&
          other.holdingClientId == this.holdingClientId &&
          other.holdingName == this.holdingName &&
          other.holdingSymbol == this.holdingSymbol &&
          other.currencyCode == this.currencyCode &&
          other.quantity == this.quantity &&
          other.totalPurchaseAmount == this.totalPurchaseAmount &&
          other.totalValuationAmount == this.totalValuationAmount &&
          other.profitAmount == this.profitAmount &&
          other.profitRate == this.profitRate);
}

class DailyPortfolioSnapshotHoldingItemsCompanion
    extends UpdateCompanion<DailyPortfolioSnapshotHoldingItem> {
  final Value<int> id;
  final Value<int> snapshotId;
  final Value<int?> assetId;
  final Value<String?> assetClientId;
  final Value<String> assetTitle;
  final Value<int?> holdingId;
  final Value<String?> holdingClientId;
  final Value<String> holdingName;
  final Value<String> holdingSymbol;
  final Value<String> currencyCode;
  final Value<double> quantity;
  final Value<double> totalPurchaseAmount;
  final Value<double> totalValuationAmount;
  final Value<double> profitAmount;
  final Value<double> profitRate;
  const DailyPortfolioSnapshotHoldingItemsCompanion({
    this.id = const Value.absent(),
    this.snapshotId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetClientId = const Value.absent(),
    this.assetTitle = const Value.absent(),
    this.holdingId = const Value.absent(),
    this.holdingClientId = const Value.absent(),
    this.holdingName = const Value.absent(),
    this.holdingSymbol = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.totalPurchaseAmount = const Value.absent(),
    this.totalValuationAmount = const Value.absent(),
    this.profitAmount = const Value.absent(),
    this.profitRate = const Value.absent(),
  });
  DailyPortfolioSnapshotHoldingItemsCompanion.insert({
    this.id = const Value.absent(),
    required int snapshotId,
    this.assetId = const Value.absent(),
    this.assetClientId = const Value.absent(),
    required String assetTitle,
    this.holdingId = const Value.absent(),
    this.holdingClientId = const Value.absent(),
    required String holdingName,
    required String holdingSymbol,
    required String currencyCode,
    required double quantity,
    required double totalPurchaseAmount,
    required double totalValuationAmount,
    required double profitAmount,
    required double profitRate,
  }) : snapshotId = Value(snapshotId),
       assetTitle = Value(assetTitle),
       holdingName = Value(holdingName),
       holdingSymbol = Value(holdingSymbol),
       currencyCode = Value(currencyCode),
       quantity = Value(quantity),
       totalPurchaseAmount = Value(totalPurchaseAmount),
       totalValuationAmount = Value(totalValuationAmount),
       profitAmount = Value(profitAmount),
       profitRate = Value(profitRate);
  static Insertable<DailyPortfolioSnapshotHoldingItem> custom({
    Expression<int>? id,
    Expression<int>? snapshotId,
    Expression<int>? assetId,
    Expression<String>? assetClientId,
    Expression<String>? assetTitle,
    Expression<int>? holdingId,
    Expression<String>? holdingClientId,
    Expression<String>? holdingName,
    Expression<String>? holdingSymbol,
    Expression<String>? currencyCode,
    Expression<double>? quantity,
    Expression<double>? totalPurchaseAmount,
    Expression<double>? totalValuationAmount,
    Expression<double>? profitAmount,
    Expression<double>? profitRate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (snapshotId != null) 'snapshot_id': snapshotId,
      if (assetId != null) 'asset_id': assetId,
      if (assetClientId != null) 'asset_client_id': assetClientId,
      if (assetTitle != null) 'asset_title': assetTitle,
      if (holdingId != null) 'holding_id': holdingId,
      if (holdingClientId != null) 'holding_client_id': holdingClientId,
      if (holdingName != null) 'holding_name': holdingName,
      if (holdingSymbol != null) 'holding_symbol': holdingSymbol,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (quantity != null) 'quantity': quantity,
      if (totalPurchaseAmount != null)
        'total_purchase_amount': totalPurchaseAmount,
      if (totalValuationAmount != null)
        'total_valuation_amount': totalValuationAmount,
      if (profitAmount != null) 'profit_amount': profitAmount,
      if (profitRate != null) 'profit_rate': profitRate,
    });
  }

  DailyPortfolioSnapshotHoldingItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? snapshotId,
    Value<int?>? assetId,
    Value<String?>? assetClientId,
    Value<String>? assetTitle,
    Value<int?>? holdingId,
    Value<String?>? holdingClientId,
    Value<String>? holdingName,
    Value<String>? holdingSymbol,
    Value<String>? currencyCode,
    Value<double>? quantity,
    Value<double>? totalPurchaseAmount,
    Value<double>? totalValuationAmount,
    Value<double>? profitAmount,
    Value<double>? profitRate,
  }) {
    return DailyPortfolioSnapshotHoldingItemsCompanion(
      id: id ?? this.id,
      snapshotId: snapshotId ?? this.snapshotId,
      assetId: assetId ?? this.assetId,
      assetClientId: assetClientId ?? this.assetClientId,
      assetTitle: assetTitle ?? this.assetTitle,
      holdingId: holdingId ?? this.holdingId,
      holdingClientId: holdingClientId ?? this.holdingClientId,
      holdingName: holdingName ?? this.holdingName,
      holdingSymbol: holdingSymbol ?? this.holdingSymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      quantity: quantity ?? this.quantity,
      totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
      totalValuationAmount: totalValuationAmount ?? this.totalValuationAmount,
      profitAmount: profitAmount ?? this.profitAmount,
      profitRate: profitRate ?? this.profitRate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (snapshotId.present) {
      map['snapshot_id'] = Variable<int>(snapshotId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (assetClientId.present) {
      map['asset_client_id'] = Variable<String>(assetClientId.value);
    }
    if (assetTitle.present) {
      map['asset_title'] = Variable<String>(assetTitle.value);
    }
    if (holdingId.present) {
      map['holding_id'] = Variable<int>(holdingId.value);
    }
    if (holdingClientId.present) {
      map['holding_client_id'] = Variable<String>(holdingClientId.value);
    }
    if (holdingName.present) {
      map['holding_name'] = Variable<String>(holdingName.value);
    }
    if (holdingSymbol.present) {
      map['holding_symbol'] = Variable<String>(holdingSymbol.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (totalPurchaseAmount.present) {
      map['total_purchase_amount'] = Variable<double>(
        totalPurchaseAmount.value,
      );
    }
    if (totalValuationAmount.present) {
      map['total_valuation_amount'] = Variable<double>(
        totalValuationAmount.value,
      );
    }
    if (profitAmount.present) {
      map['profit_amount'] = Variable<double>(profitAmount.value);
    }
    if (profitRate.present) {
      map['profit_rate'] = Variable<double>(profitRate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPortfolioSnapshotHoldingItemsCompanion(')
          ..write('id: $id, ')
          ..write('snapshotId: $snapshotId, ')
          ..write('assetId: $assetId, ')
          ..write('assetClientId: $assetClientId, ')
          ..write('assetTitle: $assetTitle, ')
          ..write('holdingId: $holdingId, ')
          ..write('holdingClientId: $holdingClientId, ')
          ..write('holdingName: $holdingName, ')
          ..write('holdingSymbol: $holdingSymbol, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('quantity: $quantity, ')
          ..write('totalPurchaseAmount: $totalPurchaseAmount, ')
          ..write('totalValuationAmount: $totalValuationAmount, ')
          ..write('profitAmount: $profitAmount, ')
          ..write('profitRate: $profitRate')
          ..write(')'))
        .toString();
  }
}

class $AssetAllocationTargetsTable extends AssetAllocationTargets
    with TableInfo<$AssetAllocationTargetsTable, AssetAllocationTarget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetAllocationTargetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES assets (id)',
    ),
  );
  static const VerificationMeta _targetRatioMeta = const VerificationMeta(
    'targetRatio',
  );
  @override
  late final GeneratedColumn<double> targetRatio = GeneratedColumn<double>(
    'target_ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, assetId, targetRatio];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_allocation_targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetAllocationTarget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('target_ratio')) {
      context.handle(
        _targetRatioMeta,
        targetRatio.isAcceptableOrUnknown(
          data['target_ratio']!,
          _targetRatioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetRatioMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetAllocationTarget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetAllocationTarget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}asset_id'],
      )!,
      targetRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_ratio'],
      )!,
    );
  }

  @override
  $AssetAllocationTargetsTable createAlias(String alias) {
    return $AssetAllocationTargetsTable(attachedDatabase, alias);
  }
}

class AssetAllocationTarget extends DataClass
    implements Insertable<AssetAllocationTarget> {
  final int id;
  final int assetId;
  final double targetRatio;
  const AssetAllocationTarget({
    required this.id,
    required this.assetId,
    required this.targetRatio,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['asset_id'] = Variable<int>(assetId);
    map['target_ratio'] = Variable<double>(targetRatio);
    return map;
  }

  AssetAllocationTargetsCompanion toCompanion(bool nullToAbsent) {
    return AssetAllocationTargetsCompanion(
      id: Value(id),
      assetId: Value(assetId),
      targetRatio: Value(targetRatio),
    );
  }

  factory AssetAllocationTarget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetAllocationTarget(
      id: serializer.fromJson<int>(json['id']),
      assetId: serializer.fromJson<int>(json['assetId']),
      targetRatio: serializer.fromJson<double>(json['targetRatio']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetId': serializer.toJson<int>(assetId),
      'targetRatio': serializer.toJson<double>(targetRatio),
    };
  }

  AssetAllocationTarget copyWith({
    int? id,
    int? assetId,
    double? targetRatio,
  }) => AssetAllocationTarget(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    targetRatio: targetRatio ?? this.targetRatio,
  );
  AssetAllocationTarget copyWithCompanion(
    AssetAllocationTargetsCompanion data,
  ) {
    return AssetAllocationTarget(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      targetRatio: data.targetRatio.present
          ? data.targetRatio.value
          : this.targetRatio,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetAllocationTarget(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('targetRatio: $targetRatio')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, assetId, targetRatio);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetAllocationTarget &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.targetRatio == this.targetRatio);
}

class AssetAllocationTargetsCompanion
    extends UpdateCompanion<AssetAllocationTarget> {
  final Value<int> id;
  final Value<int> assetId;
  final Value<double> targetRatio;
  const AssetAllocationTargetsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.targetRatio = const Value.absent(),
  });
  AssetAllocationTargetsCompanion.insert({
    this.id = const Value.absent(),
    required int assetId,
    required double targetRatio,
  }) : assetId = Value(assetId),
       targetRatio = Value(targetRatio);
  static Insertable<AssetAllocationTarget> custom({
    Expression<int>? id,
    Expression<int>? assetId,
    Expression<double>? targetRatio,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (targetRatio != null) 'target_ratio': targetRatio,
    });
  }

  AssetAllocationTargetsCompanion copyWith({
    Value<int>? id,
    Value<int>? assetId,
    Value<double>? targetRatio,
  }) {
    return AssetAllocationTargetsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      targetRatio: targetRatio ?? this.targetRatio,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (targetRatio.present) {
      map['target_ratio'] = Variable<double>(targetRatio.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetAllocationTargetsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('targetRatio: $targetRatio')
          ..write(')'))
        .toString();
  }
}

class $ExchangeRatesTable extends ExchangeRates
    with TableInfo<$ExchangeRatesTable, ExchangeRate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeRatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _currencyPairMeta = const VerificationMeta(
    'currencyPair',
  );
  @override
  late final GeneratedColumn<String> currencyPair = GeneratedColumn<String>(
    'currency_pair',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<String> recordedAt = GeneratedColumn<String>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currencyPair,
    rate,
    recordedAt,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExchangeRate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('currency_pair')) {
      context.handle(
        _currencyPairMeta,
        currencyPair.isAcceptableOrUnknown(
          data['currency_pair']!,
          _currencyPairMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyPairMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExchangeRate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currencyPair: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_pair'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $ExchangeRatesTable createAlias(String alias) {
    return $ExchangeRatesTable(attachedDatabase, alias);
  }
}

class ExchangeRate extends DataClass implements Insertable<ExchangeRate> {
  final int id;
  final String currencyPair;
  final double rate;
  final String recordedAt;
  final String source;
  const ExchangeRate({
    required this.id,
    required this.currencyPair,
    required this.rate,
    required this.recordedAt,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['currency_pair'] = Variable<String>(currencyPair);
    map['rate'] = Variable<double>(rate);
    map['recorded_at'] = Variable<String>(recordedAt);
    map['source'] = Variable<String>(source);
    return map;
  }

  ExchangeRatesCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesCompanion(
      id: Value(id),
      currencyPair: Value(currencyPair),
      rate: Value(rate),
      recordedAt: Value(recordedAt),
      source: Value(source),
    );
  }

  factory ExchangeRate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRate(
      id: serializer.fromJson<int>(json['id']),
      currencyPair: serializer.fromJson<String>(json['currencyPair']),
      rate: serializer.fromJson<double>(json['rate']),
      recordedAt: serializer.fromJson<String>(json['recordedAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currencyPair': serializer.toJson<String>(currencyPair),
      'rate': serializer.toJson<double>(rate),
      'recordedAt': serializer.toJson<String>(recordedAt),
      'source': serializer.toJson<String>(source),
    };
  }

  ExchangeRate copyWith({
    int? id,
    String? currencyPair,
    double? rate,
    String? recordedAt,
    String? source,
  }) => ExchangeRate(
    id: id ?? this.id,
    currencyPair: currencyPair ?? this.currencyPair,
    rate: rate ?? this.rate,
    recordedAt: recordedAt ?? this.recordedAt,
    source: source ?? this.source,
  );
  ExchangeRate copyWithCompanion(ExchangeRatesCompanion data) {
    return ExchangeRate(
      id: data.id.present ? data.id.value : this.id,
      currencyPair: data.currencyPair.present
          ? data.currencyPair.value
          : this.currencyPair,
      rate: data.rate.present ? data.rate.value : this.rate,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRate(')
          ..write('id: $id, ')
          ..write('currencyPair: $currencyPair, ')
          ..write('rate: $rate, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, currencyPair, rate, recordedAt, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRate &&
          other.id == this.id &&
          other.currencyPair == this.currencyPair &&
          other.rate == this.rate &&
          other.recordedAt == this.recordedAt &&
          other.source == this.source);
}

class ExchangeRatesCompanion extends UpdateCompanion<ExchangeRate> {
  final Value<int> id;
  final Value<String> currencyPair;
  final Value<double> rate;
  final Value<String> recordedAt;
  final Value<String> source;
  const ExchangeRatesCompanion({
    this.id = const Value.absent(),
    this.currencyPair = const Value.absent(),
    this.rate = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.source = const Value.absent(),
  });
  ExchangeRatesCompanion.insert({
    this.id = const Value.absent(),
    required String currencyPair,
    required double rate,
    required String recordedAt,
    this.source = const Value.absent(),
  }) : currencyPair = Value(currencyPair),
       rate = Value(rate),
       recordedAt = Value(recordedAt);
  static Insertable<ExchangeRate> custom({
    Expression<int>? id,
    Expression<String>? currencyPair,
    Expression<double>? rate,
    Expression<String>? recordedAt,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currencyPair != null) 'currency_pair': currencyPair,
      if (rate != null) 'rate': rate,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (source != null) 'source': source,
    });
  }

  ExchangeRatesCompanion copyWith({
    Value<int>? id,
    Value<String>? currencyPair,
    Value<double>? rate,
    Value<String>? recordedAt,
    Value<String>? source,
  }) {
    return ExchangeRatesCompanion(
      id: id ?? this.id,
      currencyPair: currencyPair ?? this.currencyPair,
      rate: rate ?? this.rate,
      recordedAt: recordedAt ?? this.recordedAt,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currencyPair.present) {
      map['currency_pair'] = Variable<String>(currencyPair.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<String>(recordedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRatesCompanion(')
          ..write('id: $id, ')
          ..write('currencyPair: $currencyPair, ')
          ..write('rate: $rate, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $PortfolioDailyReturnsTable extends PortfolioDailyReturns
    with TableInfo<$PortfolioDailyReturnsTable, PortfolioDailyReturn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PortfolioDailyReturnsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _localUserIdMeta = const VerificationMeta(
    'localUserId',
  );
  @override
  late final GeneratedColumn<String> localUserId = GeneratedColumn<String>(
    'local_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _returnDateMeta = const VerificationMeta(
    'returnDate',
  );
  @override
  late final GeneratedColumn<String> returnDate = GeneratedColumn<String>(
    'return_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beginningValueKrwMeta = const VerificationMeta(
    'beginningValueKrw',
  );
  @override
  late final GeneratedColumn<double> beginningValueKrw =
      GeneratedColumn<double>(
        'beginning_value_krw',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _endingValueKrwMeta = const VerificationMeta(
    'endingValueKrw',
  );
  @override
  late final GeneratedColumn<double> endingValueKrw = GeneratedColumn<double>(
    'ending_value_krw',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portfolioValueKrwMeta = const VerificationMeta(
    'portfolioValueKrw',
  );
  @override
  late final GeneratedColumn<double> portfolioValueKrw =
      GeneratedColumn<double>(
        'portfolio_value_krw',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _externalCashFlowKrwMeta =
      const VerificationMeta('externalCashFlowKrw');
  @override
  late final GeneratedColumn<double> externalCashFlowKrw =
      GeneratedColumn<double>(
        'external_cash_flow_krw',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _dailyReturnMeta = const VerificationMeta(
    'dailyReturn',
  );
  @override
  late final GeneratedColumn<double> dailyReturn = GeneratedColumn<double>(
    'daily_return',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataQualityMeta = const VerificationMeta(
    'dataQuality',
  );
  @override
  late final GeneratedColumn<String> dataQuality = GeneratedColumn<String>(
    'data_quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('complete'),
  );
  static const VerificationMeta _calculationVersionMeta =
      const VerificationMeta('calculationVersion');
  @override
  late final GeneratedColumn<int> calculationVersion = GeneratedColumn<int>(
    'calculation_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localUserId,
    returnDate,
    beginningValueKrw,
    endingValueKrw,
    portfolioValueKrw,
    externalCashFlowKrw,
    dailyReturn,
    dataQuality,
    calculationVersion,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'portfolio_daily_returns';
  @override
  VerificationContext validateIntegrity(
    Insertable<PortfolioDailyReturn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_user_id')) {
      context.handle(
        _localUserIdMeta,
        localUserId.isAcceptableOrUnknown(
          data['local_user_id']!,
          _localUserIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUserIdMeta);
    }
    if (data.containsKey('return_date')) {
      context.handle(
        _returnDateMeta,
        returnDate.isAcceptableOrUnknown(data['return_date']!, _returnDateMeta),
      );
    } else if (isInserting) {
      context.missing(_returnDateMeta);
    }
    if (data.containsKey('beginning_value_krw')) {
      context.handle(
        _beginningValueKrwMeta,
        beginningValueKrw.isAcceptableOrUnknown(
          data['beginning_value_krw']!,
          _beginningValueKrwMeta,
        ),
      );
    }
    if (data.containsKey('ending_value_krw')) {
      context.handle(
        _endingValueKrwMeta,
        endingValueKrw.isAcceptableOrUnknown(
          data['ending_value_krw']!,
          _endingValueKrwMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endingValueKrwMeta);
    }
    if (data.containsKey('portfolio_value_krw')) {
      context.handle(
        _portfolioValueKrwMeta,
        portfolioValueKrw.isAcceptableOrUnknown(
          data['portfolio_value_krw']!,
          _portfolioValueKrwMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_portfolioValueKrwMeta);
    }
    if (data.containsKey('external_cash_flow_krw')) {
      context.handle(
        _externalCashFlowKrwMeta,
        externalCashFlowKrw.isAcceptableOrUnknown(
          data['external_cash_flow_krw']!,
          _externalCashFlowKrwMeta,
        ),
      );
    }
    if (data.containsKey('daily_return')) {
      context.handle(
        _dailyReturnMeta,
        dailyReturn.isAcceptableOrUnknown(
          data['daily_return']!,
          _dailyReturnMeta,
        ),
      );
    }
    if (data.containsKey('data_quality')) {
      context.handle(
        _dataQualityMeta,
        dataQuality.isAcceptableOrUnknown(
          data['data_quality']!,
          _dataQualityMeta,
        ),
      );
    }
    if (data.containsKey('calculation_version')) {
      context.handle(
        _calculationVersionMeta,
        calculationVersion.isAcceptableOrUnknown(
          data['calculation_version']!,
          _calculationVersionMeta,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {localUserId, returnDate},
  ];
  @override
  PortfolioDailyReturn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PortfolioDailyReturn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_user_id'],
      )!,
      returnDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}return_date'],
      )!,
      beginningValueKrw: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}beginning_value_krw'],
      ),
      endingValueKrw: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ending_value_krw'],
      )!,
      portfolioValueKrw: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}portfolio_value_krw'],
      )!,
      externalCashFlowKrw: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}external_cash_flow_krw'],
      )!,
      dailyReturn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}daily_return'],
      ),
      dataQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_quality'],
      )!,
      calculationVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calculation_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PortfolioDailyReturnsTable createAlias(String alias) {
    return $PortfolioDailyReturnsTable(attachedDatabase, alias);
  }
}

class PortfolioDailyReturn extends DataClass
    implements Insertable<PortfolioDailyReturn> {
  final int id;
  final String localUserId;
  final String returnDate;
  final double? beginningValueKrw;
  final double endingValueKrw;
  final double portfolioValueKrw;
  final double externalCashFlowKrw;
  final double? dailyReturn;
  final String dataQuality;
  final int calculationVersion;
  final String createdAt;
  final String updatedAt;
  const PortfolioDailyReturn({
    required this.id,
    required this.localUserId,
    required this.returnDate,
    this.beginningValueKrw,
    required this.endingValueKrw,
    required this.portfolioValueKrw,
    required this.externalCashFlowKrw,
    this.dailyReturn,
    required this.dataQuality,
    required this.calculationVersion,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_user_id'] = Variable<String>(localUserId);
    map['return_date'] = Variable<String>(returnDate);
    if (!nullToAbsent || beginningValueKrw != null) {
      map['beginning_value_krw'] = Variable<double>(beginningValueKrw);
    }
    map['ending_value_krw'] = Variable<double>(endingValueKrw);
    map['portfolio_value_krw'] = Variable<double>(portfolioValueKrw);
    map['external_cash_flow_krw'] = Variable<double>(externalCashFlowKrw);
    if (!nullToAbsent || dailyReturn != null) {
      map['daily_return'] = Variable<double>(dailyReturn);
    }
    map['data_quality'] = Variable<String>(dataQuality);
    map['calculation_version'] = Variable<int>(calculationVersion);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  PortfolioDailyReturnsCompanion toCompanion(bool nullToAbsent) {
    return PortfolioDailyReturnsCompanion(
      id: Value(id),
      localUserId: Value(localUserId),
      returnDate: Value(returnDate),
      beginningValueKrw: beginningValueKrw == null && nullToAbsent
          ? const Value.absent()
          : Value(beginningValueKrw),
      endingValueKrw: Value(endingValueKrw),
      portfolioValueKrw: Value(portfolioValueKrw),
      externalCashFlowKrw: Value(externalCashFlowKrw),
      dailyReturn: dailyReturn == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyReturn),
      dataQuality: Value(dataQuality),
      calculationVersion: Value(calculationVersion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PortfolioDailyReturn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PortfolioDailyReturn(
      id: serializer.fromJson<int>(json['id']),
      localUserId: serializer.fromJson<String>(json['localUserId']),
      returnDate: serializer.fromJson<String>(json['returnDate']),
      beginningValueKrw: serializer.fromJson<double?>(
        json['beginningValueKrw'],
      ),
      endingValueKrw: serializer.fromJson<double>(json['endingValueKrw']),
      portfolioValueKrw: serializer.fromJson<double>(json['portfolioValueKrw']),
      externalCashFlowKrw: serializer.fromJson<double>(
        json['externalCashFlowKrw'],
      ),
      dailyReturn: serializer.fromJson<double?>(json['dailyReturn']),
      dataQuality: serializer.fromJson<String>(json['dataQuality']),
      calculationVersion: serializer.fromJson<int>(json['calculationVersion']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localUserId': serializer.toJson<String>(localUserId),
      'returnDate': serializer.toJson<String>(returnDate),
      'beginningValueKrw': serializer.toJson<double?>(beginningValueKrw),
      'endingValueKrw': serializer.toJson<double>(endingValueKrw),
      'portfolioValueKrw': serializer.toJson<double>(portfolioValueKrw),
      'externalCashFlowKrw': serializer.toJson<double>(externalCashFlowKrw),
      'dailyReturn': serializer.toJson<double?>(dailyReturn),
      'dataQuality': serializer.toJson<String>(dataQuality),
      'calculationVersion': serializer.toJson<int>(calculationVersion),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  PortfolioDailyReturn copyWith({
    int? id,
    String? localUserId,
    String? returnDate,
    Value<double?> beginningValueKrw = const Value.absent(),
    double? endingValueKrw,
    double? portfolioValueKrw,
    double? externalCashFlowKrw,
    Value<double?> dailyReturn = const Value.absent(),
    String? dataQuality,
    int? calculationVersion,
    String? createdAt,
    String? updatedAt,
  }) => PortfolioDailyReturn(
    id: id ?? this.id,
    localUserId: localUserId ?? this.localUserId,
    returnDate: returnDate ?? this.returnDate,
    beginningValueKrw: beginningValueKrw.present
        ? beginningValueKrw.value
        : this.beginningValueKrw,
    endingValueKrw: endingValueKrw ?? this.endingValueKrw,
    portfolioValueKrw: portfolioValueKrw ?? this.portfolioValueKrw,
    externalCashFlowKrw: externalCashFlowKrw ?? this.externalCashFlowKrw,
    dailyReturn: dailyReturn.present ? dailyReturn.value : this.dailyReturn,
    dataQuality: dataQuality ?? this.dataQuality,
    calculationVersion: calculationVersion ?? this.calculationVersion,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PortfolioDailyReturn copyWithCompanion(PortfolioDailyReturnsCompanion data) {
    return PortfolioDailyReturn(
      id: data.id.present ? data.id.value : this.id,
      localUserId: data.localUserId.present
          ? data.localUserId.value
          : this.localUserId,
      returnDate: data.returnDate.present
          ? data.returnDate.value
          : this.returnDate,
      beginningValueKrw: data.beginningValueKrw.present
          ? data.beginningValueKrw.value
          : this.beginningValueKrw,
      endingValueKrw: data.endingValueKrw.present
          ? data.endingValueKrw.value
          : this.endingValueKrw,
      portfolioValueKrw: data.portfolioValueKrw.present
          ? data.portfolioValueKrw.value
          : this.portfolioValueKrw,
      externalCashFlowKrw: data.externalCashFlowKrw.present
          ? data.externalCashFlowKrw.value
          : this.externalCashFlowKrw,
      dailyReturn: data.dailyReturn.present
          ? data.dailyReturn.value
          : this.dailyReturn,
      dataQuality: data.dataQuality.present
          ? data.dataQuality.value
          : this.dataQuality,
      calculationVersion: data.calculationVersion.present
          ? data.calculationVersion.value
          : this.calculationVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioDailyReturn(')
          ..write('id: $id, ')
          ..write('localUserId: $localUserId, ')
          ..write('returnDate: $returnDate, ')
          ..write('beginningValueKrw: $beginningValueKrw, ')
          ..write('endingValueKrw: $endingValueKrw, ')
          ..write('portfolioValueKrw: $portfolioValueKrw, ')
          ..write('externalCashFlowKrw: $externalCashFlowKrw, ')
          ..write('dailyReturn: $dailyReturn, ')
          ..write('dataQuality: $dataQuality, ')
          ..write('calculationVersion: $calculationVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localUserId,
    returnDate,
    beginningValueKrw,
    endingValueKrw,
    portfolioValueKrw,
    externalCashFlowKrw,
    dailyReturn,
    dataQuality,
    calculationVersion,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PortfolioDailyReturn &&
          other.id == this.id &&
          other.localUserId == this.localUserId &&
          other.returnDate == this.returnDate &&
          other.beginningValueKrw == this.beginningValueKrw &&
          other.endingValueKrw == this.endingValueKrw &&
          other.portfolioValueKrw == this.portfolioValueKrw &&
          other.externalCashFlowKrw == this.externalCashFlowKrw &&
          other.dailyReturn == this.dailyReturn &&
          other.dataQuality == this.dataQuality &&
          other.calculationVersion == this.calculationVersion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PortfolioDailyReturnsCompanion
    extends UpdateCompanion<PortfolioDailyReturn> {
  final Value<int> id;
  final Value<String> localUserId;
  final Value<String> returnDate;
  final Value<double?> beginningValueKrw;
  final Value<double> endingValueKrw;
  final Value<double> portfolioValueKrw;
  final Value<double> externalCashFlowKrw;
  final Value<double?> dailyReturn;
  final Value<String> dataQuality;
  final Value<int> calculationVersion;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const PortfolioDailyReturnsCompanion({
    this.id = const Value.absent(),
    this.localUserId = const Value.absent(),
    this.returnDate = const Value.absent(),
    this.beginningValueKrw = const Value.absent(),
    this.endingValueKrw = const Value.absent(),
    this.portfolioValueKrw = const Value.absent(),
    this.externalCashFlowKrw = const Value.absent(),
    this.dailyReturn = const Value.absent(),
    this.dataQuality = const Value.absent(),
    this.calculationVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PortfolioDailyReturnsCompanion.insert({
    this.id = const Value.absent(),
    required String localUserId,
    required String returnDate,
    this.beginningValueKrw = const Value.absent(),
    required double endingValueKrw,
    required double portfolioValueKrw,
    this.externalCashFlowKrw = const Value.absent(),
    this.dailyReturn = const Value.absent(),
    this.dataQuality = const Value.absent(),
    this.calculationVersion = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : localUserId = Value(localUserId),
       returnDate = Value(returnDate),
       endingValueKrw = Value(endingValueKrw),
       portfolioValueKrw = Value(portfolioValueKrw),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PortfolioDailyReturn> custom({
    Expression<int>? id,
    Expression<String>? localUserId,
    Expression<String>? returnDate,
    Expression<double>? beginningValueKrw,
    Expression<double>? endingValueKrw,
    Expression<double>? portfolioValueKrw,
    Expression<double>? externalCashFlowKrw,
    Expression<double>? dailyReturn,
    Expression<String>? dataQuality,
    Expression<int>? calculationVersion,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localUserId != null) 'local_user_id': localUserId,
      if (returnDate != null) 'return_date': returnDate,
      if (beginningValueKrw != null) 'beginning_value_krw': beginningValueKrw,
      if (endingValueKrw != null) 'ending_value_krw': endingValueKrw,
      if (portfolioValueKrw != null) 'portfolio_value_krw': portfolioValueKrw,
      if (externalCashFlowKrw != null)
        'external_cash_flow_krw': externalCashFlowKrw,
      if (dailyReturn != null) 'daily_return': dailyReturn,
      if (dataQuality != null) 'data_quality': dataQuality,
      if (calculationVersion != null) 'calculation_version': calculationVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PortfolioDailyReturnsCompanion copyWith({
    Value<int>? id,
    Value<String>? localUserId,
    Value<String>? returnDate,
    Value<double?>? beginningValueKrw,
    Value<double>? endingValueKrw,
    Value<double>? portfolioValueKrw,
    Value<double>? externalCashFlowKrw,
    Value<double?>? dailyReturn,
    Value<String>? dataQuality,
    Value<int>? calculationVersion,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return PortfolioDailyReturnsCompanion(
      id: id ?? this.id,
      localUserId: localUserId ?? this.localUserId,
      returnDate: returnDate ?? this.returnDate,
      beginningValueKrw: beginningValueKrw ?? this.beginningValueKrw,
      endingValueKrw: endingValueKrw ?? this.endingValueKrw,
      portfolioValueKrw: portfolioValueKrw ?? this.portfolioValueKrw,
      externalCashFlowKrw: externalCashFlowKrw ?? this.externalCashFlowKrw,
      dailyReturn: dailyReturn ?? this.dailyReturn,
      dataQuality: dataQuality ?? this.dataQuality,
      calculationVersion: calculationVersion ?? this.calculationVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localUserId.present) {
      map['local_user_id'] = Variable<String>(localUserId.value);
    }
    if (returnDate.present) {
      map['return_date'] = Variable<String>(returnDate.value);
    }
    if (beginningValueKrw.present) {
      map['beginning_value_krw'] = Variable<double>(beginningValueKrw.value);
    }
    if (endingValueKrw.present) {
      map['ending_value_krw'] = Variable<double>(endingValueKrw.value);
    }
    if (portfolioValueKrw.present) {
      map['portfolio_value_krw'] = Variable<double>(portfolioValueKrw.value);
    }
    if (externalCashFlowKrw.present) {
      map['external_cash_flow_krw'] = Variable<double>(
        externalCashFlowKrw.value,
      );
    }
    if (dailyReturn.present) {
      map['daily_return'] = Variable<double>(dailyReturn.value);
    }
    if (dataQuality.present) {
      map['data_quality'] = Variable<String>(dataQuality.value);
    }
    if (calculationVersion.present) {
      map['calculation_version'] = Variable<int>(calculationVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PortfolioDailyReturnsCompanion(')
          ..write('id: $id, ')
          ..write('localUserId: $localUserId, ')
          ..write('returnDate: $returnDate, ')
          ..write('beginningValueKrw: $beginningValueKrw, ')
          ..write('endingValueKrw: $endingValueKrw, ')
          ..write('portfolioValueKrw: $portfolioValueKrw, ')
          ..write('externalCashFlowKrw: $externalCashFlowKrw, ')
          ..write('dailyReturn: $dailyReturn, ')
          ..write('dataQuality: $dataQuality, ')
          ..write('calculationVersion: $calculationVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BenchmarkPricesTable extends BenchmarkPrices
    with TableInfo<$BenchmarkPricesTable, BenchmarkPrice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BenchmarkPricesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _benchmarkCodeMeta = const VerificationMeta(
    'benchmarkCode',
  );
  @override
  late final GeneratedColumn<String> benchmarkCode = GeneratedColumn<String>(
    'benchmark_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceDateMeta = const VerificationMeta(
    'priceDate',
  );
  @override
  late final GeneratedColumn<String> priceDate = GeneratedColumn<String>(
    'price_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closePriceMeta = const VerificationMeta(
    'closePrice',
  );
  @override
  late final GeneratedColumn<double> closePrice = GeneratedColumn<double>(
    'close_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adjustedClosePriceMeta =
      const VerificationMeta('adjustedClosePrice');
  @override
  late final GeneratedColumn<double> adjustedClosePrice =
      GeneratedColumn<double>(
        'adjusted_close_price',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('KRW'),
  );
  static const VerificationMeta _fxRateToKrwMeta = const VerificationMeta(
    'fxRateToKrw',
  );
  @override
  late final GeneratedColumn<double> fxRateToKrw = GeneratedColumn<double>(
    'fx_rate_to_krw',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    benchmarkCode,
    priceDate,
    closePrice,
    adjustedClosePrice,
    currencyCode,
    fxRateToKrw,
    source,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'benchmark_prices';
  @override
  VerificationContext validateIntegrity(
    Insertable<BenchmarkPrice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('benchmark_code')) {
      context.handle(
        _benchmarkCodeMeta,
        benchmarkCode.isAcceptableOrUnknown(
          data['benchmark_code']!,
          _benchmarkCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_benchmarkCodeMeta);
    }
    if (data.containsKey('price_date')) {
      context.handle(
        _priceDateMeta,
        priceDate.isAcceptableOrUnknown(data['price_date']!, _priceDateMeta),
      );
    } else if (isInserting) {
      context.missing(_priceDateMeta);
    }
    if (data.containsKey('close_price')) {
      context.handle(
        _closePriceMeta,
        closePrice.isAcceptableOrUnknown(data['close_price']!, _closePriceMeta),
      );
    } else if (isInserting) {
      context.missing(_closePriceMeta);
    }
    if (data.containsKey('adjusted_close_price')) {
      context.handle(
        _adjustedClosePriceMeta,
        adjustedClosePrice.isAcceptableOrUnknown(
          data['adjusted_close_price']!,
          _adjustedClosePriceMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('fx_rate_to_krw')) {
      context.handle(
        _fxRateToKrwMeta,
        fxRateToKrw.isAcceptableOrUnknown(
          data['fx_rate_to_krw']!,
          _fxRateToKrwMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {benchmarkCode, priceDate},
  ];
  @override
  BenchmarkPrice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BenchmarkPrice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      benchmarkCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}benchmark_code'],
      )!,
      priceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price_date'],
      )!,
      closePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}close_price'],
      )!,
      adjustedClosePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}adjusted_close_price'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      fxRateToKrw: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fx_rate_to_krw'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BenchmarkPricesTable createAlias(String alias) {
    return $BenchmarkPricesTable(attachedDatabase, alias);
  }
}

class BenchmarkPrice extends DataClass implements Insertable<BenchmarkPrice> {
  final int id;
  final String benchmarkCode;
  final String priceDate;
  final double closePrice;
  final double? adjustedClosePrice;
  final String currencyCode;
  final double? fxRateToKrw;
  final String? source;
  final String createdAt;
  final String updatedAt;
  const BenchmarkPrice({
    required this.id,
    required this.benchmarkCode,
    required this.priceDate,
    required this.closePrice,
    this.adjustedClosePrice,
    required this.currencyCode,
    this.fxRateToKrw,
    this.source,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['benchmark_code'] = Variable<String>(benchmarkCode);
    map['price_date'] = Variable<String>(priceDate);
    map['close_price'] = Variable<double>(closePrice);
    if (!nullToAbsent || adjustedClosePrice != null) {
      map['adjusted_close_price'] = Variable<double>(adjustedClosePrice);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || fxRateToKrw != null) {
      map['fx_rate_to_krw'] = Variable<double>(fxRateToKrw);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  BenchmarkPricesCompanion toCompanion(bool nullToAbsent) {
    return BenchmarkPricesCompanion(
      id: Value(id),
      benchmarkCode: Value(benchmarkCode),
      priceDate: Value(priceDate),
      closePrice: Value(closePrice),
      adjustedClosePrice: adjustedClosePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(adjustedClosePrice),
      currencyCode: Value(currencyCode),
      fxRateToKrw: fxRateToKrw == null && nullToAbsent
          ? const Value.absent()
          : Value(fxRateToKrw),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BenchmarkPrice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BenchmarkPrice(
      id: serializer.fromJson<int>(json['id']),
      benchmarkCode: serializer.fromJson<String>(json['benchmarkCode']),
      priceDate: serializer.fromJson<String>(json['priceDate']),
      closePrice: serializer.fromJson<double>(json['closePrice']),
      adjustedClosePrice: serializer.fromJson<double?>(
        json['adjustedClosePrice'],
      ),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      fxRateToKrw: serializer.fromJson<double?>(json['fxRateToKrw']),
      source: serializer.fromJson<String?>(json['source']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'benchmarkCode': serializer.toJson<String>(benchmarkCode),
      'priceDate': serializer.toJson<String>(priceDate),
      'closePrice': serializer.toJson<double>(closePrice),
      'adjustedClosePrice': serializer.toJson<double?>(adjustedClosePrice),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'fxRateToKrw': serializer.toJson<double?>(fxRateToKrw),
      'source': serializer.toJson<String?>(source),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  BenchmarkPrice copyWith({
    int? id,
    String? benchmarkCode,
    String? priceDate,
    double? closePrice,
    Value<double?> adjustedClosePrice = const Value.absent(),
    String? currencyCode,
    Value<double?> fxRateToKrw = const Value.absent(),
    Value<String?> source = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => BenchmarkPrice(
    id: id ?? this.id,
    benchmarkCode: benchmarkCode ?? this.benchmarkCode,
    priceDate: priceDate ?? this.priceDate,
    closePrice: closePrice ?? this.closePrice,
    adjustedClosePrice: adjustedClosePrice.present
        ? adjustedClosePrice.value
        : this.adjustedClosePrice,
    currencyCode: currencyCode ?? this.currencyCode,
    fxRateToKrw: fxRateToKrw.present ? fxRateToKrw.value : this.fxRateToKrw,
    source: source.present ? source.value : this.source,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BenchmarkPrice copyWithCompanion(BenchmarkPricesCompanion data) {
    return BenchmarkPrice(
      id: data.id.present ? data.id.value : this.id,
      benchmarkCode: data.benchmarkCode.present
          ? data.benchmarkCode.value
          : this.benchmarkCode,
      priceDate: data.priceDate.present ? data.priceDate.value : this.priceDate,
      closePrice: data.closePrice.present
          ? data.closePrice.value
          : this.closePrice,
      adjustedClosePrice: data.adjustedClosePrice.present
          ? data.adjustedClosePrice.value
          : this.adjustedClosePrice,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      fxRateToKrw: data.fxRateToKrw.present
          ? data.fxRateToKrw.value
          : this.fxRateToKrw,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BenchmarkPrice(')
          ..write('id: $id, ')
          ..write('benchmarkCode: $benchmarkCode, ')
          ..write('priceDate: $priceDate, ')
          ..write('closePrice: $closePrice, ')
          ..write('adjustedClosePrice: $adjustedClosePrice, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('fxRateToKrw: $fxRateToKrw, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    benchmarkCode,
    priceDate,
    closePrice,
    adjustedClosePrice,
    currencyCode,
    fxRateToKrw,
    source,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BenchmarkPrice &&
          other.id == this.id &&
          other.benchmarkCode == this.benchmarkCode &&
          other.priceDate == this.priceDate &&
          other.closePrice == this.closePrice &&
          other.adjustedClosePrice == this.adjustedClosePrice &&
          other.currencyCode == this.currencyCode &&
          other.fxRateToKrw == this.fxRateToKrw &&
          other.source == this.source &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BenchmarkPricesCompanion extends UpdateCompanion<BenchmarkPrice> {
  final Value<int> id;
  final Value<String> benchmarkCode;
  final Value<String> priceDate;
  final Value<double> closePrice;
  final Value<double?> adjustedClosePrice;
  final Value<String> currencyCode;
  final Value<double?> fxRateToKrw;
  final Value<String?> source;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  const BenchmarkPricesCompanion({
    this.id = const Value.absent(),
    this.benchmarkCode = const Value.absent(),
    this.priceDate = const Value.absent(),
    this.closePrice = const Value.absent(),
    this.adjustedClosePrice = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.fxRateToKrw = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BenchmarkPricesCompanion.insert({
    this.id = const Value.absent(),
    required String benchmarkCode,
    required String priceDate,
    required double closePrice,
    this.adjustedClosePrice = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.fxRateToKrw = const Value.absent(),
    this.source = const Value.absent(),
    required String createdAt,
    required String updatedAt,
  }) : benchmarkCode = Value(benchmarkCode),
       priceDate = Value(priceDate),
       closePrice = Value(closePrice),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BenchmarkPrice> custom({
    Expression<int>? id,
    Expression<String>? benchmarkCode,
    Expression<String>? priceDate,
    Expression<double>? closePrice,
    Expression<double>? adjustedClosePrice,
    Expression<String>? currencyCode,
    Expression<double>? fxRateToKrw,
    Expression<String>? source,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (benchmarkCode != null) 'benchmark_code': benchmarkCode,
      if (priceDate != null) 'price_date': priceDate,
      if (closePrice != null) 'close_price': closePrice,
      if (adjustedClosePrice != null)
        'adjusted_close_price': adjustedClosePrice,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (fxRateToKrw != null) 'fx_rate_to_krw': fxRateToKrw,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BenchmarkPricesCompanion copyWith({
    Value<int>? id,
    Value<String>? benchmarkCode,
    Value<String>? priceDate,
    Value<double>? closePrice,
    Value<double?>? adjustedClosePrice,
    Value<String>? currencyCode,
    Value<double?>? fxRateToKrw,
    Value<String?>? source,
    Value<String>? createdAt,
    Value<String>? updatedAt,
  }) {
    return BenchmarkPricesCompanion(
      id: id ?? this.id,
      benchmarkCode: benchmarkCode ?? this.benchmarkCode,
      priceDate: priceDate ?? this.priceDate,
      closePrice: closePrice ?? this.closePrice,
      adjustedClosePrice: adjustedClosePrice ?? this.adjustedClosePrice,
      currencyCode: currencyCode ?? this.currencyCode,
      fxRateToKrw: fxRateToKrw ?? this.fxRateToKrw,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (benchmarkCode.present) {
      map['benchmark_code'] = Variable<String>(benchmarkCode.value);
    }
    if (priceDate.present) {
      map['price_date'] = Variable<String>(priceDate.value);
    }
    if (closePrice.present) {
      map['close_price'] = Variable<double>(closePrice.value);
    }
    if (adjustedClosePrice.present) {
      map['adjusted_close_price'] = Variable<double>(adjustedClosePrice.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (fxRateToKrw.present) {
      map['fx_rate_to_krw'] = Variable<double>(fxRateToKrw.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BenchmarkPricesCompanion(')
          ..write('id: $id, ')
          ..write('benchmarkCode: $benchmarkCode, ')
          ..write('priceDate: $priceDate, ')
          ..write('closePrice: $closePrice, ')
          ..write('adjustedClosePrice: $adjustedClosePrice, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('fxRateToKrw: $fxRateToKrw, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DailyInvestmentReviewsTable extends DailyInvestmentReviews
    with TableInfo<$DailyInvestmentReviewsTable, DailyInvestmentReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyInvestmentReviewsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _reviewDateMeta = const VerificationMeta(
    'reviewDate',
  );
  @override
  late final GeneratedColumn<String> reviewDate = GeneratedColumn<String>(
    'review_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
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
  static const VerificationMeta _performanceNoteMeta = const VerificationMeta(
    'performanceNote',
  );
  @override
  late final GeneratedColumn<String> performanceNote = GeneratedColumn<String>(
    'performance_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _tradeReviewNoteMeta = const VerificationMeta(
    'tradeReviewNote',
  );
  @override
  late final GeneratedColumn<String> tradeReviewNote = GeneratedColumn<String>(
    'trade_review_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _selectedDecisionTagsMeta =
      const VerificationMeta('selectedDecisionTags');
  @override
  late final GeneratedColumn<String> selectedDecisionTags =
      GeneratedColumn<String>(
        'selected_decision_tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _selectedNoTradeReasonsMeta =
      const VerificationMeta('selectedNoTradeReasons');
  @override
  late final GeneratedColumn<String> selectedNoTradeReasons =
      GeneratedColumn<String>(
        'selected_no_trade_reasons',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _selectedEmotionsMeta = const VerificationMeta(
    'selectedEmotions',
  );
  @override
  late final GeneratedColumn<String> selectedEmotions = GeneratedColumn<String>(
    'selected_emotions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _principleCheckMeta = const VerificationMeta(
    'principleCheck',
  );
  @override
  late final GeneratedColumn<String> principleCheck = GeneratedColumn<String>(
    'principle_check',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('notApplicable'),
  );
  static const VerificationMeta _riskNoteMeta = const VerificationMeta(
    'riskNote',
  );
  @override
  late final GeneratedColumn<String> riskNote = GeneratedColumn<String>(
    'risk_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _insightGoodMeta = const VerificationMeta(
    'insightGood',
  );
  @override
  late final GeneratedColumn<String> insightGood = GeneratedColumn<String>(
    'insight_good',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _insightWeakMeta = const VerificationMeta(
    'insightWeak',
  );
  @override
  late final GeneratedColumn<String> insightWeak = GeneratedColumn<String>(
    'insight_weak',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _insightRepeatOrAvoidMeta =
      const VerificationMeta('insightRepeatOrAvoid');
  @override
  late final GeneratedColumn<String> insightRepeatOrAvoid =
      GeneratedColumn<String>(
        'insight_repeat_or_avoid',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _nextPlanMeta = const VerificationMeta(
    'nextPlan',
  );
  @override
  late final GeneratedColumn<String> nextPlan = GeneratedColumn<String>(
    'next_plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reviewDate,
    status,
    mode,
    performanceNote,
    tradeReviewNote,
    selectedDecisionTags,
    selectedNoTradeReasons,
    selectedEmotions,
    principleCheck,
    riskNote,
    insightGood,
    insightWeak,
    insightRepeatOrAvoid,
    nextPlan,
    createdAt,
    updatedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_investment_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyInvestmentReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('review_date')) {
      context.handle(
        _reviewDateMeta,
        reviewDate.isAcceptableOrUnknown(data['review_date']!, _reviewDateMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('performance_note')) {
      context.handle(
        _performanceNoteMeta,
        performanceNote.isAcceptableOrUnknown(
          data['performance_note']!,
          _performanceNoteMeta,
        ),
      );
    }
    if (data.containsKey('trade_review_note')) {
      context.handle(
        _tradeReviewNoteMeta,
        tradeReviewNote.isAcceptableOrUnknown(
          data['trade_review_note']!,
          _tradeReviewNoteMeta,
        ),
      );
    }
    if (data.containsKey('selected_decision_tags')) {
      context.handle(
        _selectedDecisionTagsMeta,
        selectedDecisionTags.isAcceptableOrUnknown(
          data['selected_decision_tags']!,
          _selectedDecisionTagsMeta,
        ),
      );
    }
    if (data.containsKey('selected_no_trade_reasons')) {
      context.handle(
        _selectedNoTradeReasonsMeta,
        selectedNoTradeReasons.isAcceptableOrUnknown(
          data['selected_no_trade_reasons']!,
          _selectedNoTradeReasonsMeta,
        ),
      );
    }
    if (data.containsKey('selected_emotions')) {
      context.handle(
        _selectedEmotionsMeta,
        selectedEmotions.isAcceptableOrUnknown(
          data['selected_emotions']!,
          _selectedEmotionsMeta,
        ),
      );
    }
    if (data.containsKey('principle_check')) {
      context.handle(
        _principleCheckMeta,
        principleCheck.isAcceptableOrUnknown(
          data['principle_check']!,
          _principleCheckMeta,
        ),
      );
    }
    if (data.containsKey('risk_note')) {
      context.handle(
        _riskNoteMeta,
        riskNote.isAcceptableOrUnknown(data['risk_note']!, _riskNoteMeta),
      );
    }
    if (data.containsKey('insight_good')) {
      context.handle(
        _insightGoodMeta,
        insightGood.isAcceptableOrUnknown(
          data['insight_good']!,
          _insightGoodMeta,
        ),
      );
    }
    if (data.containsKey('insight_weak')) {
      context.handle(
        _insightWeakMeta,
        insightWeak.isAcceptableOrUnknown(
          data['insight_weak']!,
          _insightWeakMeta,
        ),
      );
    }
    if (data.containsKey('insight_repeat_or_avoid')) {
      context.handle(
        _insightRepeatOrAvoidMeta,
        insightRepeatOrAvoid.isAcceptableOrUnknown(
          data['insight_repeat_or_avoid']!,
          _insightRepeatOrAvoidMeta,
        ),
      );
    }
    if (data.containsKey('next_plan')) {
      context.handle(
        _nextPlanMeta,
        nextPlan.isAcceptableOrUnknown(data['next_plan']!, _nextPlanMeta),
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
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyInvestmentReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyInvestmentReview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      performanceNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}performance_note'],
      )!,
      tradeReviewNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trade_review_note'],
      )!,
      selectedDecisionTags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_decision_tags'],
      )!,
      selectedNoTradeReasons: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_no_trade_reasons'],
      )!,
      selectedEmotions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_emotions'],
      )!,
      principleCheck: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}principle_check'],
      )!,
      riskNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}risk_note'],
      )!,
      insightGood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insight_good'],
      )!,
      insightWeak: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insight_weak'],
      )!,
      insightRepeatOrAvoid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insight_repeat_or_avoid'],
      )!,
      nextPlan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_plan'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $DailyInvestmentReviewsTable createAlias(String alias) {
    return $DailyInvestmentReviewsTable(attachedDatabase, alias);
  }
}

class DailyInvestmentReview extends DataClass
    implements Insertable<DailyInvestmentReview> {
  final int id;
  final String reviewDate;
  final String status;
  final String mode;
  final String performanceNote;
  final String tradeReviewNote;
  final String selectedDecisionTags;
  final String selectedNoTradeReasons;
  final String selectedEmotions;
  final String principleCheck;
  final String riskNote;
  final String insightGood;
  final String insightWeak;
  final String insightRepeatOrAvoid;
  final String nextPlan;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  const DailyInvestmentReview({
    required this.id,
    required this.reviewDate,
    required this.status,
    required this.mode,
    required this.performanceNote,
    required this.tradeReviewNote,
    required this.selectedDecisionTags,
    required this.selectedNoTradeReasons,
    required this.selectedEmotions,
    required this.principleCheck,
    required this.riskNote,
    required this.insightGood,
    required this.insightWeak,
    required this.insightRepeatOrAvoid,
    required this.nextPlan,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['review_date'] = Variable<String>(reviewDate);
    map['status'] = Variable<String>(status);
    map['mode'] = Variable<String>(mode);
    map['performance_note'] = Variable<String>(performanceNote);
    map['trade_review_note'] = Variable<String>(tradeReviewNote);
    map['selected_decision_tags'] = Variable<String>(selectedDecisionTags);
    map['selected_no_trade_reasons'] = Variable<String>(selectedNoTradeReasons);
    map['selected_emotions'] = Variable<String>(selectedEmotions);
    map['principle_check'] = Variable<String>(principleCheck);
    map['risk_note'] = Variable<String>(riskNote);
    map['insight_good'] = Variable<String>(insightGood);
    map['insight_weak'] = Variable<String>(insightWeak);
    map['insight_repeat_or_avoid'] = Variable<String>(insightRepeatOrAvoid);
    map['next_plan'] = Variable<String>(nextPlan);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    return map;
  }

  DailyInvestmentReviewsCompanion toCompanion(bool nullToAbsent) {
    return DailyInvestmentReviewsCompanion(
      id: Value(id),
      reviewDate: Value(reviewDate),
      status: Value(status),
      mode: Value(mode),
      performanceNote: Value(performanceNote),
      tradeReviewNote: Value(tradeReviewNote),
      selectedDecisionTags: Value(selectedDecisionTags),
      selectedNoTradeReasons: Value(selectedNoTradeReasons),
      selectedEmotions: Value(selectedEmotions),
      principleCheck: Value(principleCheck),
      riskNote: Value(riskNote),
      insightGood: Value(insightGood),
      insightWeak: Value(insightWeak),
      insightRepeatOrAvoid: Value(insightRepeatOrAvoid),
      nextPlan: Value(nextPlan),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory DailyInvestmentReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyInvestmentReview(
      id: serializer.fromJson<int>(json['id']),
      reviewDate: serializer.fromJson<String>(json['reviewDate']),
      status: serializer.fromJson<String>(json['status']),
      mode: serializer.fromJson<String>(json['mode']),
      performanceNote: serializer.fromJson<String>(json['performanceNote']),
      tradeReviewNote: serializer.fromJson<String>(json['tradeReviewNote']),
      selectedDecisionTags: serializer.fromJson<String>(
        json['selectedDecisionTags'],
      ),
      selectedNoTradeReasons: serializer.fromJson<String>(
        json['selectedNoTradeReasons'],
      ),
      selectedEmotions: serializer.fromJson<String>(json['selectedEmotions']),
      principleCheck: serializer.fromJson<String>(json['principleCheck']),
      riskNote: serializer.fromJson<String>(json['riskNote']),
      insightGood: serializer.fromJson<String>(json['insightGood']),
      insightWeak: serializer.fromJson<String>(json['insightWeak']),
      insightRepeatOrAvoid: serializer.fromJson<String>(
        json['insightRepeatOrAvoid'],
      ),
      nextPlan: serializer.fromJson<String>(json['nextPlan']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reviewDate': serializer.toJson<String>(reviewDate),
      'status': serializer.toJson<String>(status),
      'mode': serializer.toJson<String>(mode),
      'performanceNote': serializer.toJson<String>(performanceNote),
      'tradeReviewNote': serializer.toJson<String>(tradeReviewNote),
      'selectedDecisionTags': serializer.toJson<String>(selectedDecisionTags),
      'selectedNoTradeReasons': serializer.toJson<String>(
        selectedNoTradeReasons,
      ),
      'selectedEmotions': serializer.toJson<String>(selectedEmotions),
      'principleCheck': serializer.toJson<String>(principleCheck),
      'riskNote': serializer.toJson<String>(riskNote),
      'insightGood': serializer.toJson<String>(insightGood),
      'insightWeak': serializer.toJson<String>(insightWeak),
      'insightRepeatOrAvoid': serializer.toJson<String>(insightRepeatOrAvoid),
      'nextPlan': serializer.toJson<String>(nextPlan),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'completedAt': serializer.toJson<String?>(completedAt),
    };
  }

  DailyInvestmentReview copyWith({
    int? id,
    String? reviewDate,
    String? status,
    String? mode,
    String? performanceNote,
    String? tradeReviewNote,
    String? selectedDecisionTags,
    String? selectedNoTradeReasons,
    String? selectedEmotions,
    String? principleCheck,
    String? riskNote,
    String? insightGood,
    String? insightWeak,
    String? insightRepeatOrAvoid,
    String? nextPlan,
    String? createdAt,
    String? updatedAt,
    Value<String?> completedAt = const Value.absent(),
  }) => DailyInvestmentReview(
    id: id ?? this.id,
    reviewDate: reviewDate ?? this.reviewDate,
    status: status ?? this.status,
    mode: mode ?? this.mode,
    performanceNote: performanceNote ?? this.performanceNote,
    tradeReviewNote: tradeReviewNote ?? this.tradeReviewNote,
    selectedDecisionTags: selectedDecisionTags ?? this.selectedDecisionTags,
    selectedNoTradeReasons:
        selectedNoTradeReasons ?? this.selectedNoTradeReasons,
    selectedEmotions: selectedEmotions ?? this.selectedEmotions,
    principleCheck: principleCheck ?? this.principleCheck,
    riskNote: riskNote ?? this.riskNote,
    insightGood: insightGood ?? this.insightGood,
    insightWeak: insightWeak ?? this.insightWeak,
    insightRepeatOrAvoid: insightRepeatOrAvoid ?? this.insightRepeatOrAvoid,
    nextPlan: nextPlan ?? this.nextPlan,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  DailyInvestmentReview copyWithCompanion(
    DailyInvestmentReviewsCompanion data,
  ) {
    return DailyInvestmentReview(
      id: data.id.present ? data.id.value : this.id,
      reviewDate: data.reviewDate.present
          ? data.reviewDate.value
          : this.reviewDate,
      status: data.status.present ? data.status.value : this.status,
      mode: data.mode.present ? data.mode.value : this.mode,
      performanceNote: data.performanceNote.present
          ? data.performanceNote.value
          : this.performanceNote,
      tradeReviewNote: data.tradeReviewNote.present
          ? data.tradeReviewNote.value
          : this.tradeReviewNote,
      selectedDecisionTags: data.selectedDecisionTags.present
          ? data.selectedDecisionTags.value
          : this.selectedDecisionTags,
      selectedNoTradeReasons: data.selectedNoTradeReasons.present
          ? data.selectedNoTradeReasons.value
          : this.selectedNoTradeReasons,
      selectedEmotions: data.selectedEmotions.present
          ? data.selectedEmotions.value
          : this.selectedEmotions,
      principleCheck: data.principleCheck.present
          ? data.principleCheck.value
          : this.principleCheck,
      riskNote: data.riskNote.present ? data.riskNote.value : this.riskNote,
      insightGood: data.insightGood.present
          ? data.insightGood.value
          : this.insightGood,
      insightWeak: data.insightWeak.present
          ? data.insightWeak.value
          : this.insightWeak,
      insightRepeatOrAvoid: data.insightRepeatOrAvoid.present
          ? data.insightRepeatOrAvoid.value
          : this.insightRepeatOrAvoid,
      nextPlan: data.nextPlan.present ? data.nextPlan.value : this.nextPlan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyInvestmentReview(')
          ..write('id: $id, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('status: $status, ')
          ..write('mode: $mode, ')
          ..write('performanceNote: $performanceNote, ')
          ..write('tradeReviewNote: $tradeReviewNote, ')
          ..write('selectedDecisionTags: $selectedDecisionTags, ')
          ..write('selectedNoTradeReasons: $selectedNoTradeReasons, ')
          ..write('selectedEmotions: $selectedEmotions, ')
          ..write('principleCheck: $principleCheck, ')
          ..write('riskNote: $riskNote, ')
          ..write('insightGood: $insightGood, ')
          ..write('insightWeak: $insightWeak, ')
          ..write('insightRepeatOrAvoid: $insightRepeatOrAvoid, ')
          ..write('nextPlan: $nextPlan, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reviewDate,
    status,
    mode,
    performanceNote,
    tradeReviewNote,
    selectedDecisionTags,
    selectedNoTradeReasons,
    selectedEmotions,
    principleCheck,
    riskNote,
    insightGood,
    insightWeak,
    insightRepeatOrAvoid,
    nextPlan,
    createdAt,
    updatedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyInvestmentReview &&
          other.id == this.id &&
          other.reviewDate == this.reviewDate &&
          other.status == this.status &&
          other.mode == this.mode &&
          other.performanceNote == this.performanceNote &&
          other.tradeReviewNote == this.tradeReviewNote &&
          other.selectedDecisionTags == this.selectedDecisionTags &&
          other.selectedNoTradeReasons == this.selectedNoTradeReasons &&
          other.selectedEmotions == this.selectedEmotions &&
          other.principleCheck == this.principleCheck &&
          other.riskNote == this.riskNote &&
          other.insightGood == this.insightGood &&
          other.insightWeak == this.insightWeak &&
          other.insightRepeatOrAvoid == this.insightRepeatOrAvoid &&
          other.nextPlan == this.nextPlan &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class DailyInvestmentReviewsCompanion
    extends UpdateCompanion<DailyInvestmentReview> {
  final Value<int> id;
  final Value<String> reviewDate;
  final Value<String> status;
  final Value<String> mode;
  final Value<String> performanceNote;
  final Value<String> tradeReviewNote;
  final Value<String> selectedDecisionTags;
  final Value<String> selectedNoTradeReasons;
  final Value<String> selectedEmotions;
  final Value<String> principleCheck;
  final Value<String> riskNote;
  final Value<String> insightGood;
  final Value<String> insightWeak;
  final Value<String> insightRepeatOrAvoid;
  final Value<String> nextPlan;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> completedAt;
  const DailyInvestmentReviewsCompanion({
    this.id = const Value.absent(),
    this.reviewDate = const Value.absent(),
    this.status = const Value.absent(),
    this.mode = const Value.absent(),
    this.performanceNote = const Value.absent(),
    this.tradeReviewNote = const Value.absent(),
    this.selectedDecisionTags = const Value.absent(),
    this.selectedNoTradeReasons = const Value.absent(),
    this.selectedEmotions = const Value.absent(),
    this.principleCheck = const Value.absent(),
    this.riskNote = const Value.absent(),
    this.insightGood = const Value.absent(),
    this.insightWeak = const Value.absent(),
    this.insightRepeatOrAvoid = const Value.absent(),
    this.nextPlan = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  DailyInvestmentReviewsCompanion.insert({
    this.id = const Value.absent(),
    required String reviewDate,
    required String status,
    required String mode,
    this.performanceNote = const Value.absent(),
    this.tradeReviewNote = const Value.absent(),
    this.selectedDecisionTags = const Value.absent(),
    this.selectedNoTradeReasons = const Value.absent(),
    this.selectedEmotions = const Value.absent(),
    this.principleCheck = const Value.absent(),
    this.riskNote = const Value.absent(),
    this.insightGood = const Value.absent(),
    this.insightWeak = const Value.absent(),
    this.insightRepeatOrAvoid = const Value.absent(),
    this.nextPlan = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.completedAt = const Value.absent(),
  }) : reviewDate = Value(reviewDate),
       status = Value(status),
       mode = Value(mode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DailyInvestmentReview> custom({
    Expression<int>? id,
    Expression<String>? reviewDate,
    Expression<String>? status,
    Expression<String>? mode,
    Expression<String>? performanceNote,
    Expression<String>? tradeReviewNote,
    Expression<String>? selectedDecisionTags,
    Expression<String>? selectedNoTradeReasons,
    Expression<String>? selectedEmotions,
    Expression<String>? principleCheck,
    Expression<String>? riskNote,
    Expression<String>? insightGood,
    Expression<String>? insightWeak,
    Expression<String>? insightRepeatOrAvoid,
    Expression<String>? nextPlan,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reviewDate != null) 'review_date': reviewDate,
      if (status != null) 'status': status,
      if (mode != null) 'mode': mode,
      if (performanceNote != null) 'performance_note': performanceNote,
      if (tradeReviewNote != null) 'trade_review_note': tradeReviewNote,
      if (selectedDecisionTags != null)
        'selected_decision_tags': selectedDecisionTags,
      if (selectedNoTradeReasons != null)
        'selected_no_trade_reasons': selectedNoTradeReasons,
      if (selectedEmotions != null) 'selected_emotions': selectedEmotions,
      if (principleCheck != null) 'principle_check': principleCheck,
      if (riskNote != null) 'risk_note': riskNote,
      if (insightGood != null) 'insight_good': insightGood,
      if (insightWeak != null) 'insight_weak': insightWeak,
      if (insightRepeatOrAvoid != null)
        'insight_repeat_or_avoid': insightRepeatOrAvoid,
      if (nextPlan != null) 'next_plan': nextPlan,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  DailyInvestmentReviewsCompanion copyWith({
    Value<int>? id,
    Value<String>? reviewDate,
    Value<String>? status,
    Value<String>? mode,
    Value<String>? performanceNote,
    Value<String>? tradeReviewNote,
    Value<String>? selectedDecisionTags,
    Value<String>? selectedNoTradeReasons,
    Value<String>? selectedEmotions,
    Value<String>? principleCheck,
    Value<String>? riskNote,
    Value<String>? insightGood,
    Value<String>? insightWeak,
    Value<String>? insightRepeatOrAvoid,
    Value<String>? nextPlan,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? completedAt,
  }) {
    return DailyInvestmentReviewsCompanion(
      id: id ?? this.id,
      reviewDate: reviewDate ?? this.reviewDate,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      performanceNote: performanceNote ?? this.performanceNote,
      tradeReviewNote: tradeReviewNote ?? this.tradeReviewNote,
      selectedDecisionTags: selectedDecisionTags ?? this.selectedDecisionTags,
      selectedNoTradeReasons:
          selectedNoTradeReasons ?? this.selectedNoTradeReasons,
      selectedEmotions: selectedEmotions ?? this.selectedEmotions,
      principleCheck: principleCheck ?? this.principleCheck,
      riskNote: riskNote ?? this.riskNote,
      insightGood: insightGood ?? this.insightGood,
      insightWeak: insightWeak ?? this.insightWeak,
      insightRepeatOrAvoid: insightRepeatOrAvoid ?? this.insightRepeatOrAvoid,
      nextPlan: nextPlan ?? this.nextPlan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reviewDate.present) {
      map['review_date'] = Variable<String>(reviewDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (performanceNote.present) {
      map['performance_note'] = Variable<String>(performanceNote.value);
    }
    if (tradeReviewNote.present) {
      map['trade_review_note'] = Variable<String>(tradeReviewNote.value);
    }
    if (selectedDecisionTags.present) {
      map['selected_decision_tags'] = Variable<String>(
        selectedDecisionTags.value,
      );
    }
    if (selectedNoTradeReasons.present) {
      map['selected_no_trade_reasons'] = Variable<String>(
        selectedNoTradeReasons.value,
      );
    }
    if (selectedEmotions.present) {
      map['selected_emotions'] = Variable<String>(selectedEmotions.value);
    }
    if (principleCheck.present) {
      map['principle_check'] = Variable<String>(principleCheck.value);
    }
    if (riskNote.present) {
      map['risk_note'] = Variable<String>(riskNote.value);
    }
    if (insightGood.present) {
      map['insight_good'] = Variable<String>(insightGood.value);
    }
    if (insightWeak.present) {
      map['insight_weak'] = Variable<String>(insightWeak.value);
    }
    if (insightRepeatOrAvoid.present) {
      map['insight_repeat_or_avoid'] = Variable<String>(
        insightRepeatOrAvoid.value,
      );
    }
    if (nextPlan.present) {
      map['next_plan'] = Variable<String>(nextPlan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyInvestmentReviewsCompanion(')
          ..write('id: $id, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('status: $status, ')
          ..write('mode: $mode, ')
          ..write('performanceNote: $performanceNote, ')
          ..write('tradeReviewNote: $tradeReviewNote, ')
          ..write('selectedDecisionTags: $selectedDecisionTags, ')
          ..write('selectedNoTradeReasons: $selectedNoTradeReasons, ')
          ..write('selectedEmotions: $selectedEmotions, ')
          ..write('principleCheck: $principleCheck, ')
          ..write('riskNote: $riskNote, ')
          ..write('insightGood: $insightGood, ')
          ..write('insightWeak: $insightWeak, ')
          ..write('insightRepeatOrAvoid: $insightRepeatOrAvoid, ')
          ..write('nextPlan: $nextPlan, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $HoldingsTable holdings = $HoldingsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $CashAccountsTable cashAccounts = $CashAccountsTable(this);
  late final $CashTransactionsTable cashTransactions = $CashTransactionsTable(
    this,
  );
  late final $TransactionEventsTable transactionEvents =
      $TransactionEventsTable(this);
  late final $TransactionLinesTable transactionLines = $TransactionLinesTable(
    this,
  );
  late final $MarketNewsCachesTable marketNewsCaches = $MarketNewsCachesTable(
    this,
  );
  late final $CompanyNewsCachesTable companyNewsCaches =
      $CompanyNewsCachesTable(this);
  late final $DailyPortfolioSnapshotsTable dailyPortfolioSnapshots =
      $DailyPortfolioSnapshotsTable(this);
  late final $DailyPortfolioSnapshotItemsTable dailyPortfolioSnapshotItems =
      $DailyPortfolioSnapshotItemsTable(this);
  late final $DailyPortfolioSnapshotHoldingItemsTable
  dailyPortfolioSnapshotHoldingItems = $DailyPortfolioSnapshotHoldingItemsTable(
    this,
  );
  late final $AssetAllocationTargetsTable assetAllocationTargets =
      $AssetAllocationTargetsTable(this);
  late final $ExchangeRatesTable exchangeRates = $ExchangeRatesTable(this);
  late final $PortfolioDailyReturnsTable portfolioDailyReturns =
      $PortfolioDailyReturnsTable(this);
  late final $BenchmarkPricesTable benchmarkPrices = $BenchmarkPricesTable(
    this,
  );
  late final $DailyInvestmentReviewsTable dailyInvestmentReviews =
      $DailyInvestmentReviewsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    assets,
    holdings,
    transactions,
    cashAccounts,
    cashTransactions,
    transactionEvents,
    transactionLines,
    marketNewsCaches,
    companyNewsCaches,
    dailyPortfolioSnapshots,
    dailyPortfolioSnapshotItems,
    dailyPortfolioSnapshotHoldingItems,
    assetAllocationTargets,
    exchangeRates,
    portfolioDailyReturns,
    benchmarkPrices,
    dailyInvestmentReviews,
  ];
}

typedef $$AssetsTableCreateCompanionBuilder =
    AssetsCompanion Function({
      Value<int> id,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<String> assetType,
      required String title,
      Value<String> alias,
      Value<bool> hidden,
      Value<String> currencyCode,
      required String value,
      required String change,
      required int iconCodePoint,
      required String quantityLabel,
      required String quantityValue,
      required String averageLabel,
      required String averageValue,
      required String note,
      required int sortOrder,
    });
typedef $$AssetsTableUpdateCompanionBuilder =
    AssetsCompanion Function({
      Value<int> id,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<String> assetType,
      Value<String> title,
      Value<String> alias,
      Value<bool> hidden,
      Value<String> currencyCode,
      Value<String> value,
      Value<String> change,
      Value<int> iconCodePoint,
      Value<String> quantityLabel,
      Value<String> quantityValue,
      Value<String> averageLabel,
      Value<String> averageValue,
      Value<String> note,
      Value<int> sortOrder,
    });

final class $$AssetsTableReferences
    extends BaseReferences<_$AppDatabase, $AssetsTable, Asset> {
  $$AssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HoldingsTable, List<Holding>> _holdingsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.holdings,
    aliasName: $_aliasNameGenerator(db.assets.id, db.holdings.assetId),
  );

  $$HoldingsTableProcessedTableManager get holdingsRefs {
    final manager = $$HoldingsTableTableManager(
      $_db,
      $_db.holdings,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_holdingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.assets.id, db.transactions.assetId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CashAccountsTable, List<CashAccount>>
  _cashAccountsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cashAccounts,
    aliasName: $_aliasNameGenerator(db.assets.id, db.cashAccounts.assetId),
  );

  $$CashAccountsTableProcessedTableManager get cashAccountsRefs {
    final manager = $$CashAccountsTableTableManager(
      $_db,
      $_db.cashAccounts,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cashAccountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CashTransactionsTable, List<CashTransaction>>
  _cashTransactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cashTransactions,
    aliasName: $_aliasNameGenerator(db.assets.id, db.cashTransactions.assetId),
  );

  $$CashTransactionsTableProcessedTableManager get cashTransactionsRefs {
    final manager = $$CashTransactionsTableTableManager(
      $_db,
      $_db.cashTransactions,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cashTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionLinesTable, List<TransactionLine>>
  _transactionLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactionLines,
    aliasName: $_aliasNameGenerator(db.assets.id, db.transactionLines.assetId),
  );

  $$TransactionLinesTableProcessedTableManager get transactionLinesRefs {
    final manager = $$TransactionLinesTableTableManager(
      $_db,
      $_db.transactionLines,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DailyPortfolioSnapshotItemsTable,
    List<DailyPortfolioSnapshotItem>
  >
  _dailyPortfolioSnapshotItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dailyPortfolioSnapshotItems,
        aliasName: $_aliasNameGenerator(
          db.assets.id,
          db.dailyPortfolioSnapshotItems.assetId,
        ),
      );

  $$DailyPortfolioSnapshotItemsTableProcessedTableManager
  get dailyPortfolioSnapshotItemsRefs {
    final manager = $$DailyPortfolioSnapshotItemsTableTableManager(
      $_db,
      $_db.dailyPortfolioSnapshotItems,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dailyPortfolioSnapshotItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AssetAllocationTargetsTable,
    List<AssetAllocationTarget>
  >
  _assetAllocationTargetsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.assetAllocationTargets,
        aliasName: $_aliasNameGenerator(
          db.assets.id,
          db.assetAllocationTargets.assetId,
        ),
      );

  $$AssetAllocationTargetsTableProcessedTableManager
  get assetAllocationTargetsRefs {
    final manager = $$AssetAllocationTargetsTableTableManager(
      $_db,
      $_db.assetAllocationTargets,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _assetAllocationTargetsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssetsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetType => $composableBuilder(
    column: $table.assetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get change => $composableBuilder(
    column: $table.change,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityLabel => $composableBuilder(
    column: $table.quantityLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityValue => $composableBuilder(
    column: $table.quantityValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get averageLabel => $composableBuilder(
    column: $table.averageLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get averageValue => $composableBuilder(
    column: $table.averageValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> holdingsRefs(
    Expression<bool> Function($$HoldingsTableFilterComposer f) f,
  ) {
    final $$HoldingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.holdings,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoldingsTableFilterComposer(
            $db: $db,
            $table: $db.holdings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cashAccountsRefs(
    Expression<bool> Function($$CashAccountsTableFilterComposer f) f,
  ) {
    final $$CashAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashAccounts,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashAccountsTableFilterComposer(
            $db: $db,
            $table: $db.cashAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cashTransactionsRefs(
    Expression<bool> Function($$CashTransactionsTableFilterComposer f) f,
  ) {
    final $$CashTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashTransactions,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.cashTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionLinesRefs(
    Expression<bool> Function($$TransactionLinesTableFilterComposer f) f,
  ) {
    final $$TransactionLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableFilterComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dailyPortfolioSnapshotItemsRefs(
    Expression<bool> Function(
      $$DailyPortfolioSnapshotItemsTableFilterComposer f,
    )
    f,
  ) {
    final $$DailyPortfolioSnapshotItemsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dailyPortfolioSnapshotItems,
          getReferencedColumn: (t) => t.assetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotItemsTableFilterComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshotItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> assetAllocationTargetsRefs(
    Expression<bool> Function($$AssetAllocationTargetsTableFilterComposer f) f,
  ) {
    final $$AssetAllocationTargetsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.assetAllocationTargets,
          getReferencedColumn: (t) => t.assetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssetAllocationTargetsTableFilterComposer(
                $db: $db,
                $table: $db.assetAllocationTargets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetType => $composableBuilder(
    column: $table.assetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get change => $composableBuilder(
    column: $table.change,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityLabel => $composableBuilder(
    column: $table.quantityLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityValue => $composableBuilder(
    column: $table.quantityValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get averageLabel => $composableBuilder(
    column: $table.averageLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get averageValue => $composableBuilder(
    column: $table.averageValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get assetType =>
      $composableBuilder(column: $table.assetType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get change =>
      $composableBuilder(column: $table.change, builder: (column) => column);

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantityLabel => $composableBuilder(
    column: $table.quantityLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quantityValue => $composableBuilder(
    column: $table.quantityValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get averageLabel => $composableBuilder(
    column: $table.averageLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get averageValue => $composableBuilder(
    column: $table.averageValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> holdingsRefs<T extends Object>(
    Expression<T> Function($$HoldingsTableAnnotationComposer a) f,
  ) {
    final $$HoldingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.holdings,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoldingsTableAnnotationComposer(
            $db: $db,
            $table: $db.holdings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cashAccountsRefs<T extends Object>(
    Expression<T> Function($$CashAccountsTableAnnotationComposer a) f,
  ) {
    final $$CashAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashAccounts,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.cashAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cashTransactionsRefs<T extends Object>(
    Expression<T> Function($$CashTransactionsTableAnnotationComposer a) f,
  ) {
    final $$CashTransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashTransactions,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashTransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.cashTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionLinesRefs<T extends Object>(
    Expression<T> Function($$TransactionLinesTableAnnotationComposer a) f,
  ) {
    final $$TransactionLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dailyPortfolioSnapshotItemsRefs<T extends Object>(
    Expression<T> Function(
      $$DailyPortfolioSnapshotItemsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$DailyPortfolioSnapshotItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dailyPortfolioSnapshotItems,
          getReferencedColumn: (t) => t.assetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshotItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> assetAllocationTargetsRefs<T extends Object>(
    Expression<T> Function($$AssetAllocationTargetsTableAnnotationComposer a) f,
  ) {
    final $$AssetAllocationTargetsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.assetAllocationTargets,
          getReferencedColumn: (t) => t.assetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssetAllocationTargetsTableAnnotationComposer(
                $db: $db,
                $table: $db.assetAllocationTargets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetsTable,
          Asset,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (Asset, $$AssetsTableReferences),
          Asset,
          PrefetchHooks Function({
            bool holdingsRefs,
            bool transactionsRefs,
            bool cashAccountsRefs,
            bool cashTransactionsRefs,
            bool transactionLinesRefs,
            bool dailyPortfolioSnapshotItemsRefs,
            bool assetAllocationTargetsRefs,
          })
        > {
  $$AssetsTableTableManager(_$AppDatabase db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> assetType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> alias = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String> change = const Value.absent(),
                Value<int> iconCodePoint = const Value.absent(),
                Value<String> quantityLabel = const Value.absent(),
                Value<String> quantityValue = const Value.absent(),
                Value<String> averageLabel = const Value.absent(),
                Value<String> averageValue = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                assetType: assetType,
                title: title,
                alias: alias,
                hidden: hidden,
                currencyCode: currencyCode,
                value: value,
                change: change,
                iconCodePoint: iconCodePoint,
                quantityLabel: quantityLabel,
                quantityValue: quantityValue,
                averageLabel: averageLabel,
                averageValue: averageValue,
                note: note,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> assetType = const Value.absent(),
                required String title,
                Value<String> alias = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                required String value,
                required String change,
                required int iconCodePoint,
                required String quantityLabel,
                required String quantityValue,
                required String averageLabel,
                required String averageValue,
                required String note,
                required int sortOrder,
              }) => AssetsCompanion.insert(
                id: id,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                assetType: assetType,
                title: title,
                alias: alias,
                hidden: hidden,
                currencyCode: currencyCode,
                value: value,
                change: change,
                iconCodePoint: iconCodePoint,
                quantityLabel: quantityLabel,
                quantityValue: quantityValue,
                averageLabel: averageLabel,
                averageValue: averageValue,
                note: note,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AssetsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                holdingsRefs = false,
                transactionsRefs = false,
                cashAccountsRefs = false,
                cashTransactionsRefs = false,
                transactionLinesRefs = false,
                dailyPortfolioSnapshotItemsRefs = false,
                assetAllocationTargetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (holdingsRefs) db.holdings,
                    if (transactionsRefs) db.transactions,
                    if (cashAccountsRefs) db.cashAccounts,
                    if (cashTransactionsRefs) db.cashTransactions,
                    if (transactionLinesRefs) db.transactionLines,
                    if (dailyPortfolioSnapshotItemsRefs)
                      db.dailyPortfolioSnapshotItems,
                    if (assetAllocationTargetsRefs) db.assetAllocationTargets,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (holdingsRefs)
                        await $_getPrefetchedData<Asset, $AssetsTable, Holding>(
                          currentTable: table,
                          referencedTable: $$AssetsTableReferences
                              ._holdingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).holdingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          Asset,
                          $AssetsTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$AssetsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cashAccountsRefs)
                        await $_getPrefetchedData<
                          Asset,
                          $AssetsTable,
                          CashAccount
                        >(
                          currentTable: table,
                          referencedTable: $$AssetsTableReferences
                              ._cashAccountsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).cashAccountsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cashTransactionsRefs)
                        await $_getPrefetchedData<
                          Asset,
                          $AssetsTable,
                          CashTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$AssetsTableReferences
                              ._cashTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).cashTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionLinesRefs)
                        await $_getPrefetchedData<
                          Asset,
                          $AssetsTable,
                          TransactionLine
                        >(
                          currentTable: table,
                          referencedTable: $$AssetsTableReferences
                              ._transactionLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionLinesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dailyPortfolioSnapshotItemsRefs)
                        await $_getPrefetchedData<
                          Asset,
                          $AssetsTable,
                          DailyPortfolioSnapshotItem
                        >(
                          currentTable: table,
                          referencedTable: $$AssetsTableReferences
                              ._dailyPortfolioSnapshotItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).dailyPortfolioSnapshotItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assetAllocationTargetsRefs)
                        await $_getPrefetchedData<
                          Asset,
                          $AssetsTable,
                          AssetAllocationTarget
                        >(
                          currentTable: table,
                          referencedTable: $$AssetsTableReferences
                              ._assetAllocationTargetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).assetAllocationTargetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
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

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetsTable,
      Asset,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (Asset, $$AssetsTableReferences),
      Asset,
      PrefetchHooks Function({
        bool holdingsRefs,
        bool transactionsRefs,
        bool cashAccountsRefs,
        bool cashTransactionsRefs,
        bool transactionLinesRefs,
        bool dailyPortfolioSnapshotItemsRefs,
        bool assetAllocationTargetsRefs,
      })
    >;
typedef $$HoldingsTableCreateCompanionBuilder =
    HoldingsCompanion Function({
      Value<int> id,
      required int assetId,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<bool> hidden,
      Value<String> currencyCode,
      Value<String?> marketUpdatedAt,
      Value<String> exchangeCode,
      required String name,
      required String symbol,
      required double quantity,
      required double averagePrice,
      Value<double> averagePriceSource,
      Value<double> averagePriceKrw,
      Value<double> averagePurchaseFxRate,
      Value<double> costBasisKrw,
      required double currentPrice,
      required String note,
      required int sortOrder,
    });
typedef $$HoldingsTableUpdateCompanionBuilder =
    HoldingsCompanion Function({
      Value<int> id,
      Value<int> assetId,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<bool> hidden,
      Value<String> currencyCode,
      Value<String?> marketUpdatedAt,
      Value<String> exchangeCode,
      Value<String> name,
      Value<String> symbol,
      Value<double> quantity,
      Value<double> averagePrice,
      Value<double> averagePriceSource,
      Value<double> averagePriceKrw,
      Value<double> averagePurchaseFxRate,
      Value<double> costBasisKrw,
      Value<double> currentPrice,
      Value<String> note,
      Value<int> sortOrder,
    });

final class $$HoldingsTableReferences
    extends BaseReferences<_$AppDatabase, $HoldingsTable, Holding> {
  $$HoldingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
    $_aliasNameGenerator(db.holdings.assetId, db.assets.id),
  );

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.holdings.id, db.transactions.holdingId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.holdingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionLinesTable, List<TransactionLine>>
  _transactionLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactionLines,
    aliasName: $_aliasNameGenerator(
      db.holdings.id,
      db.transactionLines.holdingId,
    ),
  );

  $$TransactionLinesTableProcessedTableManager get transactionLinesRefs {
    final manager = $$TransactionLinesTableTableManager(
      $_db,
      $_db.transactionLines,
    ).filter((f) => f.holdingId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HoldingsTableFilterComposer
    extends Composer<_$AppDatabase, $HoldingsTable> {
  $$HoldingsTableFilterComposer({
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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marketUpdatedAt => $composableBuilder(
    column: $table.marketUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exchangeCode => $composableBuilder(
    column: $table.exchangeCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averagePrice => $composableBuilder(
    column: $table.averagePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averagePriceSource => $composableBuilder(
    column: $table.averagePriceSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averagePriceKrw => $composableBuilder(
    column: $table.averagePriceKrw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averagePurchaseFxRate => $composableBuilder(
    column: $table.averagePurchaseFxRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costBasisKrw => $composableBuilder(
    column: $table.costBasisKrw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.holdingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionLinesRefs(
    Expression<bool> Function($$TransactionLinesTableFilterComposer f) f,
  ) {
    final $$TransactionLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.holdingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableFilterComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HoldingsTableOrderingComposer
    extends Composer<_$AppDatabase, $HoldingsTable> {
  $$HoldingsTableOrderingComposer({
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marketUpdatedAt => $composableBuilder(
    column: $table.marketUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exchangeCode => $composableBuilder(
    column: $table.exchangeCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averagePrice => $composableBuilder(
    column: $table.averagePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averagePriceSource => $composableBuilder(
    column: $table.averagePriceSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averagePriceKrw => $composableBuilder(
    column: $table.averagePriceKrw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averagePurchaseFxRate => $composableBuilder(
    column: $table.averagePurchaseFxRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costBasisKrw => $composableBuilder(
    column: $table.costBasisKrw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HoldingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HoldingsTable> {
  $$HoldingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get marketUpdatedAt => $composableBuilder(
    column: $table.marketUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exchangeCode => $composableBuilder(
    column: $table.exchangeCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get averagePrice => $composableBuilder(
    column: $table.averagePrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averagePriceSource => $composableBuilder(
    column: $table.averagePriceSource,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averagePriceKrw => $composableBuilder(
    column: $table.averagePriceKrw,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averagePurchaseFxRate => $composableBuilder(
    column: $table.averagePurchaseFxRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costBasisKrw => $composableBuilder(
    column: $table.costBasisKrw,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.holdingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionLinesRefs<T extends Object>(
    Expression<T> Function($$TransactionLinesTableAnnotationComposer a) f,
  ) {
    final $$TransactionLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.holdingId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HoldingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HoldingsTable,
          Holding,
          $$HoldingsTableFilterComposer,
          $$HoldingsTableOrderingComposer,
          $$HoldingsTableAnnotationComposer,
          $$HoldingsTableCreateCompanionBuilder,
          $$HoldingsTableUpdateCompanionBuilder,
          (Holding, $$HoldingsTableReferences),
          Holding,
          PrefetchHooks Function({
            bool assetId,
            bool transactionsRefs,
            bool transactionLinesRefs,
          })
        > {
  $$HoldingsTableTableManager(_$AppDatabase db, $HoldingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HoldingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HoldingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HoldingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> assetId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String?> marketUpdatedAt = const Value.absent(),
                Value<String> exchangeCode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> averagePrice = const Value.absent(),
                Value<double> averagePriceSource = const Value.absent(),
                Value<double> averagePriceKrw = const Value.absent(),
                Value<double> averagePurchaseFxRate = const Value.absent(),
                Value<double> costBasisKrw = const Value.absent(),
                Value<double> currentPrice = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => HoldingsCompanion(
                id: id,
                assetId: assetId,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                hidden: hidden,
                currencyCode: currencyCode,
                marketUpdatedAt: marketUpdatedAt,
                exchangeCode: exchangeCode,
                name: name,
                symbol: symbol,
                quantity: quantity,
                averagePrice: averagePrice,
                averagePriceSource: averagePriceSource,
                averagePriceKrw: averagePriceKrw,
                averagePurchaseFxRate: averagePurchaseFxRate,
                costBasisKrw: costBasisKrw,
                currentPrice: currentPrice,
                note: note,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int assetId,
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String?> marketUpdatedAt = const Value.absent(),
                Value<String> exchangeCode = const Value.absent(),
                required String name,
                required String symbol,
                required double quantity,
                required double averagePrice,
                Value<double> averagePriceSource = const Value.absent(),
                Value<double> averagePriceKrw = const Value.absent(),
                Value<double> averagePurchaseFxRate = const Value.absent(),
                Value<double> costBasisKrw = const Value.absent(),
                required double currentPrice,
                required String note,
                required int sortOrder,
              }) => HoldingsCompanion.insert(
                id: id,
                assetId: assetId,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                hidden: hidden,
                currencyCode: currencyCode,
                marketUpdatedAt: marketUpdatedAt,
                exchangeCode: exchangeCode,
                name: name,
                symbol: symbol,
                quantity: quantity,
                averagePrice: averagePrice,
                averagePriceSource: averagePriceSource,
                averagePriceKrw: averagePriceKrw,
                averagePurchaseFxRate: averagePurchaseFxRate,
                costBasisKrw: costBasisKrw,
                currentPrice: currentPrice,
                note: note,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HoldingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                assetId = false,
                transactionsRefs = false,
                transactionLinesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (transactionLinesRefs) db.transactionLines,
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
                        if (assetId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.assetId,
                                    referencedTable: $$HoldingsTableReferences
                                        ._assetIdTable(db),
                                    referencedColumn: $$HoldingsTableReferences
                                        ._assetIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          Holding,
                          $HoldingsTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$HoldingsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HoldingsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.holdingId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionLinesRefs)
                        await $_getPrefetchedData<
                          Holding,
                          $HoldingsTable,
                          TransactionLine
                        >(
                          currentTable: table,
                          referencedTable: $$HoldingsTableReferences
                              ._transactionLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HoldingsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionLinesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.holdingId == item.id,
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

typedef $$HoldingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HoldingsTable,
      Holding,
      $$HoldingsTableFilterComposer,
      $$HoldingsTableOrderingComposer,
      $$HoldingsTableAnnotationComposer,
      $$HoldingsTableCreateCompanionBuilder,
      $$HoldingsTableUpdateCompanionBuilder,
      (Holding, $$HoldingsTableReferences),
      Holding,
      PrefetchHooks Function({
        bool assetId,
        bool transactionsRefs,
        bool transactionLinesRefs,
      })
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int?> assetId,
      Value<int?> holdingId,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      required String date,
      required String type,
      required String name,
      required String amount,
      required String quantity,
      Value<double> unitPrice,
      Value<double> quantityValue,
      Value<double> grossAmount,
      Value<double> cashFlowAmount,
      Value<double> realizedProfitAmount,
      required int sortOrder,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int?> assetId,
      Value<int?> holdingId,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<String> date,
      Value<String> type,
      Value<String> name,
      Value<String> amount,
      Value<String> quantity,
      Value<double> unitPrice,
      Value<double> quantityValue,
      Value<double> grossAmount,
      Value<double> cashFlowAmount,
      Value<double> realizedProfitAmount,
      Value<int> sortOrder,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
    $_aliasNameGenerator(db.transactions.assetId, db.assets.id),
  );

  $$AssetsTableProcessedTableManager? get assetId {
    final $_column = $_itemColumn<int>('asset_id');
    if ($_column == null) return null;
    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $HoldingsTable _holdingIdTable(_$AppDatabase db) =>
      db.holdings.createAlias(
        $_aliasNameGenerator(db.transactions.holdingId, db.holdings.id),
      );

  $$HoldingsTableProcessedTableManager? get holdingId {
    final $_column = $_itemColumn<int>('holding_id');
    if ($_column == null) return null;
    final manager = $$HoldingsTableTableManager(
      $_db,
      $_db.holdings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_holdingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityValue => $composableBuilder(
    column: $table.quantityValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grossAmount => $composableBuilder(
    column: $table.grossAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashFlowAmount => $composableBuilder(
    column: $table.cashFlowAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get realizedProfitAmount => $composableBuilder(
    column: $table.realizedProfitAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HoldingsTableFilterComposer get holdingId {
    final $$HoldingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.holdings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoldingsTableFilterComposer(
            $db: $db,
            $table: $db.holdings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityValue => $composableBuilder(
    column: $table.quantityValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grossAmount => $composableBuilder(
    column: $table.grossAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashFlowAmount => $composableBuilder(
    column: $table.cashFlowAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get realizedProfitAmount => $composableBuilder(
    column: $table.realizedProfitAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HoldingsTableOrderingComposer get holdingId {
    final $$HoldingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.holdings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoldingsTableOrderingComposer(
            $db: $db,
            $table: $db.holdings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get quantityValue => $composableBuilder(
    column: $table.quantityValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get grossAmount => $composableBuilder(
    column: $table.grossAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashFlowAmount => $composableBuilder(
    column: $table.cashFlowAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get realizedProfitAmount => $composableBuilder(
    column: $table.realizedProfitAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HoldingsTableAnnotationComposer get holdingId {
    final $$HoldingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.holdings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoldingsTableAnnotationComposer(
            $db: $db,
            $table: $db.holdings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({bool assetId, bool holdingId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> assetId = const Value.absent(),
                Value<int?> holdingId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> amount = const Value.absent(),
                Value<String> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> quantityValue = const Value.absent(),
                Value<double> grossAmount = const Value.absent(),
                Value<double> cashFlowAmount = const Value.absent(),
                Value<double> realizedProfitAmount = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                assetId: assetId,
                holdingId: holdingId,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                date: date,
                type: type,
                name: name,
                amount: amount,
                quantity: quantity,
                unitPrice: unitPrice,
                quantityValue: quantityValue,
                grossAmount: grossAmount,
                cashFlowAmount: cashFlowAmount,
                realizedProfitAmount: realizedProfitAmount,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> assetId = const Value.absent(),
                Value<int?> holdingId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                required String date,
                required String type,
                required String name,
                required String amount,
                required String quantity,
                Value<double> unitPrice = const Value.absent(),
                Value<double> quantityValue = const Value.absent(),
                Value<double> grossAmount = const Value.absent(),
                Value<double> cashFlowAmount = const Value.absent(),
                Value<double> realizedProfitAmount = const Value.absent(),
                required int sortOrder,
              }) => TransactionsCompanion.insert(
                id: id,
                assetId: assetId,
                holdingId: holdingId,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                date: date,
                type: type,
                name: name,
                amount: amount,
                quantity: quantity,
                unitPrice: unitPrice,
                quantityValue: quantityValue,
                grossAmount: grossAmount,
                cashFlowAmount: cashFlowAmount,
                realizedProfitAmount: realizedProfitAmount,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false, holdingId = false}) {
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
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable: $$TransactionsTableReferences
                                    ._assetIdTable(db),
                                referencedColumn: $$TransactionsTableReferences
                                    ._assetIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (holdingId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.holdingId,
                                referencedTable: $$TransactionsTableReferences
                                    ._holdingIdTable(db),
                                referencedColumn: $$TransactionsTableReferences
                                    ._holdingIdTable(db)
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

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({bool assetId, bool holdingId})
    >;
typedef $$CashAccountsTableCreateCompanionBuilder =
    CashAccountsCompanion Function({
      Value<int> id,
      required int assetId,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<bool> hidden,
      Value<String> currencyCode,
      required String name,
      Value<double> baseBalance,
      Value<double> balance,
      Value<String> note,
      Value<int> sortOrder,
    });
typedef $$CashAccountsTableUpdateCompanionBuilder =
    CashAccountsCompanion Function({
      Value<int> id,
      Value<int> assetId,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<bool> hidden,
      Value<String> currencyCode,
      Value<String> name,
      Value<double> baseBalance,
      Value<double> balance,
      Value<String> note,
      Value<int> sortOrder,
    });

final class $$CashAccountsTableReferences
    extends BaseReferences<_$AppDatabase, $CashAccountsTable, CashAccount> {
  $$CashAccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
    $_aliasNameGenerator(db.cashAccounts.assetId, db.assets.id),
  );

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CashTransactionsTable, List<CashTransaction>>
  _cashTransactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cashTransactions,
    aliasName: $_aliasNameGenerator(
      db.cashAccounts.id,
      db.cashTransactions.cashAccountId,
    ),
  );

  $$CashTransactionsTableProcessedTableManager get cashTransactionsRefs {
    final manager = $$CashTransactionsTableTableManager(
      $_db,
      $_db.cashTransactions,
    ).filter((f) => f.cashAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cashTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionLinesTable, List<TransactionLine>>
  _transactionLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactionLines,
    aliasName: $_aliasNameGenerator(
      db.cashAccounts.id,
      db.transactionLines.cashAccountId,
    ),
  );

  $$TransactionLinesTableProcessedTableManager get transactionLinesRefs {
    final manager = $$TransactionLinesTableTableManager(
      $_db,
      $_db.transactionLines,
    ).filter((f) => f.cashAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CashAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $CashAccountsTable> {
  $$CashAccountsTableFilterComposer({
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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseBalance => $composableBuilder(
    column: $table.baseBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cashTransactionsRefs(
    Expression<bool> Function($$CashTransactionsTableFilterComposer f) f,
  ) {
    final $$CashTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashTransactions,
      getReferencedColumn: (t) => t.cashAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.cashTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionLinesRefs(
    Expression<bool> Function($$TransactionLinesTableFilterComposer f) f,
  ) {
    final $$TransactionLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.cashAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableFilterComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CashAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashAccountsTable> {
  $$CashAccountsTableOrderingComposer({
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseBalance => $composableBuilder(
    column: $table.baseBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashAccountsTable> {
  $$CashAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get baseBalance => $composableBuilder(
    column: $table.baseBalance,
    builder: (column) => column,
  );

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cashTransactionsRefs<T extends Object>(
    Expression<T> Function($$CashTransactionsTableAnnotationComposer a) f,
  ) {
    final $$CashTransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cashTransactions,
      getReferencedColumn: (t) => t.cashAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashTransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.cashTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionLinesRefs<T extends Object>(
    Expression<T> Function($$TransactionLinesTableAnnotationComposer a) f,
  ) {
    final $$TransactionLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.cashAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CashAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashAccountsTable,
          CashAccount,
          $$CashAccountsTableFilterComposer,
          $$CashAccountsTableOrderingComposer,
          $$CashAccountsTableAnnotationComposer,
          $$CashAccountsTableCreateCompanionBuilder,
          $$CashAccountsTableUpdateCompanionBuilder,
          (CashAccount, $$CashAccountsTableReferences),
          CashAccount,
          PrefetchHooks Function({
            bool assetId,
            bool cashTransactionsRefs,
            bool transactionLinesRefs,
          })
        > {
  $$CashAccountsTableTableManager(_$AppDatabase db, $CashAccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> assetId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> baseBalance = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CashAccountsCompanion(
                id: id,
                assetId: assetId,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                hidden: hidden,
                currencyCode: currencyCode,
                name: name,
                baseBalance: baseBalance,
                balance: balance,
                note: note,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int assetId,
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                required String name,
                Value<double> baseBalance = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CashAccountsCompanion.insert(
                id: id,
                assetId: assetId,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                hidden: hidden,
                currencyCode: currencyCode,
                name: name,
                baseBalance: baseBalance,
                balance: balance,
                note: note,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CashAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                assetId = false,
                cashTransactionsRefs = false,
                transactionLinesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cashTransactionsRefs) db.cashTransactions,
                    if (transactionLinesRefs) db.transactionLines,
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
                        if (assetId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.assetId,
                                    referencedTable:
                                        $$CashAccountsTableReferences
                                            ._assetIdTable(db),
                                    referencedColumn:
                                        $$CashAccountsTableReferences
                                            ._assetIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cashTransactionsRefs)
                        await $_getPrefetchedData<
                          CashAccount,
                          $CashAccountsTable,
                          CashTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$CashAccountsTableReferences
                              ._cashTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CashAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).cashTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cashAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transactionLinesRefs)
                        await $_getPrefetchedData<
                          CashAccount,
                          $CashAccountsTable,
                          TransactionLine
                        >(
                          currentTable: table,
                          referencedTable: $$CashAccountsTableReferences
                              ._transactionLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CashAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionLinesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cashAccountId == item.id,
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

typedef $$CashAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashAccountsTable,
      CashAccount,
      $$CashAccountsTableFilterComposer,
      $$CashAccountsTableOrderingComposer,
      $$CashAccountsTableAnnotationComposer,
      $$CashAccountsTableCreateCompanionBuilder,
      $$CashAccountsTableUpdateCompanionBuilder,
      (CashAccount, $$CashAccountsTableReferences),
      CashAccount,
      PrefetchHooks Function({
        bool assetId,
        bool cashTransactionsRefs,
        bool transactionLinesRefs,
      })
    >;
typedef $$CashTransactionsTableCreateCompanionBuilder =
    CashTransactionsCompanion Function({
      Value<int> id,
      required int assetId,
      required int cashAccountId,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<int?> linkedTransactionId,
      required String date,
      required String type,
      required String name,
      required String amount,
      Value<double> amountValue,
      Value<double> cashFlowAmount,
      Value<int> sortOrder,
    });
typedef $$CashTransactionsTableUpdateCompanionBuilder =
    CashTransactionsCompanion Function({
      Value<int> id,
      Value<int> assetId,
      Value<int> cashAccountId,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<int?> linkedTransactionId,
      Value<String> date,
      Value<String> type,
      Value<String> name,
      Value<String> amount,
      Value<double> amountValue,
      Value<double> cashFlowAmount,
      Value<int> sortOrder,
    });

final class $$CashTransactionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CashTransactionsTable, CashTransaction> {
  $$CashTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
    $_aliasNameGenerator(db.cashTransactions.assetId, db.assets.id),
  );

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CashAccountsTable _cashAccountIdTable(_$AppDatabase db) =>
      db.cashAccounts.createAlias(
        $_aliasNameGenerator(
          db.cashTransactions.cashAccountId,
          db.cashAccounts.id,
        ),
      );

  $$CashAccountsTableProcessedTableManager get cashAccountId {
    final $_column = $_itemColumn<int>('cash_account_id')!;

    final manager = $$CashAccountsTableTableManager(
      $_db,
      $_db.cashAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cashAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CashTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $CashTransactionsTable> {
  $$CashTransactionsTableFilterComposer({
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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amountValue => $composableBuilder(
    column: $table.amountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashFlowAmount => $composableBuilder(
    column: $table.cashFlowAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CashAccountsTableFilterComposer get cashAccountId {
    final $$CashAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashAccountId,
      referencedTable: $db.cashAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashAccountsTableFilterComposer(
            $db: $db,
            $table: $db.cashAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashTransactionsTable> {
  $$CashTransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amountValue => $composableBuilder(
    column: $table.amountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashFlowAmount => $composableBuilder(
    column: $table.cashFlowAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CashAccountsTableOrderingComposer get cashAccountId {
    final $$CashAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashAccountId,
      referencedTable: $db.cashAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.cashAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashTransactionsTable> {
  $$CashTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get amountValue => $composableBuilder(
    column: $table.amountValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashFlowAmount => $composableBuilder(
    column: $table.cashFlowAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CashAccountsTableAnnotationComposer get cashAccountId {
    final $$CashAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashAccountId,
      referencedTable: $db.cashAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.cashAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashTransactionsTable,
          CashTransaction,
          $$CashTransactionsTableFilterComposer,
          $$CashTransactionsTableOrderingComposer,
          $$CashTransactionsTableAnnotationComposer,
          $$CashTransactionsTableCreateCompanionBuilder,
          $$CashTransactionsTableUpdateCompanionBuilder,
          (CashTransaction, $$CashTransactionsTableReferences),
          CashTransaction,
          PrefetchHooks Function({bool assetId, bool cashAccountId})
        > {
  $$CashTransactionsTableTableManager(
    _$AppDatabase db,
    $CashTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashTransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> assetId = const Value.absent(),
                Value<int> cashAccountId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int?> linkedTransactionId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> amount = const Value.absent(),
                Value<double> amountValue = const Value.absent(),
                Value<double> cashFlowAmount = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CashTransactionsCompanion(
                id: id,
                assetId: assetId,
                cashAccountId: cashAccountId,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                linkedTransactionId: linkedTransactionId,
                date: date,
                type: type,
                name: name,
                amount: amount,
                amountValue: amountValue,
                cashFlowAmount: cashFlowAmount,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int assetId,
                required int cashAccountId,
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int?> linkedTransactionId = const Value.absent(),
                required String date,
                required String type,
                required String name,
                required String amount,
                Value<double> amountValue = const Value.absent(),
                Value<double> cashFlowAmount = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CashTransactionsCompanion.insert(
                id: id,
                assetId: assetId,
                cashAccountId: cashAccountId,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                linkedTransactionId: linkedTransactionId,
                date: date,
                type: type,
                name: name,
                amount: amount,
                amountValue: amountValue,
                cashFlowAmount: cashFlowAmount,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CashTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false, cashAccountId = false}) {
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
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable:
                                    $$CashTransactionsTableReferences
                                        ._assetIdTable(db),
                                referencedColumn:
                                    $$CashTransactionsTableReferences
                                        ._assetIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (cashAccountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cashAccountId,
                                referencedTable:
                                    $$CashTransactionsTableReferences
                                        ._cashAccountIdTable(db),
                                referencedColumn:
                                    $$CashTransactionsTableReferences
                                        ._cashAccountIdTable(db)
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

typedef $$CashTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashTransactionsTable,
      CashTransaction,
      $$CashTransactionsTableFilterComposer,
      $$CashTransactionsTableOrderingComposer,
      $$CashTransactionsTableAnnotationComposer,
      $$CashTransactionsTableCreateCompanionBuilder,
      $$CashTransactionsTableUpdateCompanionBuilder,
      (CashTransaction, $$CashTransactionsTableReferences),
      CashTransaction,
      PrefetchHooks Function({bool assetId, bool cashAccountId})
    >;
typedef $$TransactionEventsTableCreateCompanionBuilder =
    TransactionEventsCompanion Function({
      Value<int> id,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      required String occurredAt,
      required String kind,
      Value<String> title,
      Value<String> memo,
      Value<String> source,
      Value<String> flowCategory,
      Value<String?> legacySourceTable,
      Value<int?> legacySourceId,
      Value<int> sortOrder,
    });
typedef $$TransactionEventsTableUpdateCompanionBuilder =
    TransactionEventsCompanion Function({
      Value<int> id,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<String> occurredAt,
      Value<String> kind,
      Value<String> title,
      Value<String> memo,
      Value<String> source,
      Value<String> flowCategory,
      Value<String?> legacySourceTable,
      Value<int?> legacySourceId,
      Value<int> sortOrder,
    });

final class $$TransactionEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TransactionEventsTable,
          TransactionEvent
        > {
  $$TransactionEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TransactionLinesTable, List<TransactionLine>>
  _transactionLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactionLines,
    aliasName: $_aliasNameGenerator(
      db.transactionEvents.id,
      db.transactionLines.eventId,
    ),
  );

  $$TransactionLinesTableProcessedTableManager get transactionLinesRefs {
    final manager = $$TransactionLinesTableTableManager(
      $_db,
      $_db.transactionLines,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transactionLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransactionEventsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionEventsTable> {
  $$TransactionEventsTableFilterComposer({
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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flowCategory => $composableBuilder(
    column: $table.flowCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legacySourceTable => $composableBuilder(
    column: $table.legacySourceTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get legacySourceId => $composableBuilder(
    column: $table.legacySourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionLinesRefs(
    Expression<bool> Function($$TransactionLinesTableFilterComposer f) f,
  ) {
    final $$TransactionLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableFilterComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionEventsTable> {
  $$TransactionEventsTableOrderingComposer({
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flowCategory => $composableBuilder(
    column: $table.flowCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacySourceTable => $composableBuilder(
    column: $table.legacySourceTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get legacySourceId => $composableBuilder(
    column: $table.legacySourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionEventsTable> {
  $$TransactionEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get flowCategory => $composableBuilder(
    column: $table.flowCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get legacySourceTable => $composableBuilder(
    column: $table.legacySourceTable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get legacySourceId => $composableBuilder(
    column: $table.legacySourceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> transactionLinesRefs<T extends Object>(
    Expression<T> Function($$TransactionLinesTableAnnotationComposer a) f,
  ) {
    final $$TransactionLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactionLines,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.transactionLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransactionEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionEventsTable,
          TransactionEvent,
          $$TransactionEventsTableFilterComposer,
          $$TransactionEventsTableOrderingComposer,
          $$TransactionEventsTableAnnotationComposer,
          $$TransactionEventsTableCreateCompanionBuilder,
          $$TransactionEventsTableUpdateCompanionBuilder,
          (TransactionEvent, $$TransactionEventsTableReferences),
          TransactionEvent,
          PrefetchHooks Function({bool transactionLinesRefs})
        > {
  $$TransactionEventsTableTableManager(
    _$AppDatabase db,
    $TransactionEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> occurredAt = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> flowCategory = const Value.absent(),
                Value<String?> legacySourceTable = const Value.absent(),
                Value<int?> legacySourceId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => TransactionEventsCompanion(
                id: id,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                occurredAt: occurredAt,
                kind: kind,
                title: title,
                memo: memo,
                source: source,
                flowCategory: flowCategory,
                legacySourceTable: legacySourceTable,
                legacySourceId: legacySourceId,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                required String occurredAt,
                required String kind,
                Value<String> title = const Value.absent(),
                Value<String> memo = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> flowCategory = const Value.absent(),
                Value<String?> legacySourceTable = const Value.absent(),
                Value<int?> legacySourceId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => TransactionEventsCompanion.insert(
                id: id,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                occurredAt: occurredAt,
                kind: kind,
                title: title,
                memo: memo,
                source: source,
                flowCategory: flowCategory,
                legacySourceTable: legacySourceTable,
                legacySourceId: legacySourceId,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionLinesRefs) db.transactionLines,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionLinesRefs)
                    await $_getPrefetchedData<
                      TransactionEvent,
                      $TransactionEventsTable,
                      TransactionLine
                    >(
                      currentTable: table,
                      referencedTable: $$TransactionEventsTableReferences
                          ._transactionLinesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TransactionEventsTableReferences(
                            db,
                            table,
                            p0,
                          ).transactionLinesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.eventId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TransactionEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionEventsTable,
      TransactionEvent,
      $$TransactionEventsTableFilterComposer,
      $$TransactionEventsTableOrderingComposer,
      $$TransactionEventsTableAnnotationComposer,
      $$TransactionEventsTableCreateCompanionBuilder,
      $$TransactionEventsTableUpdateCompanionBuilder,
      (TransactionEvent, $$TransactionEventsTableReferences),
      TransactionEvent,
      PrefetchHooks Function({bool transactionLinesRefs})
    >;
typedef $$TransactionLinesTableCreateCompanionBuilder =
    TransactionLinesCompanion Function({
      Value<int> id,
      required int eventId,
      Value<int?> assetId,
      Value<int?> holdingId,
      Value<int?> cashAccountId,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<String?> legacySourceTable,
      Value<int?> legacySourceId,
      required String action,
      Value<String> currencyCode,
      Value<double> quantityDelta,
      Value<double> cashDelta,
      Value<double> unitPrice,
      Value<double> grossAmount,
      Value<double> feeAmount,
      Value<double> taxAmount,
      Value<double> costBasisDelta,
      Value<double> costBasisSourceDelta,
      Value<double> realizedPnl,
      Value<String> realizedPnlSource,
      Value<double?> fxRate,
      Value<int> sortOrder,
    });
typedef $$TransactionLinesTableUpdateCompanionBuilder =
    TransactionLinesCompanion Function({
      Value<int> id,
      Value<int> eventId,
      Value<int?> assetId,
      Value<int?> holdingId,
      Value<int?> cashAccountId,
      Value<String?> clientId,
      Value<bool> dirty,
      Value<String?> lastModifiedAt,
      Value<String?> deletedAt,
      Value<String?> legacySourceTable,
      Value<int?> legacySourceId,
      Value<String> action,
      Value<String> currencyCode,
      Value<double> quantityDelta,
      Value<double> cashDelta,
      Value<double> unitPrice,
      Value<double> grossAmount,
      Value<double> feeAmount,
      Value<double> taxAmount,
      Value<double> costBasisDelta,
      Value<double> costBasisSourceDelta,
      Value<double> realizedPnl,
      Value<String> realizedPnlSource,
      Value<double?> fxRate,
      Value<int> sortOrder,
    });

final class $$TransactionLinesTableReferences
    extends
        BaseReferences<_$AppDatabase, $TransactionLinesTable, TransactionLine> {
  $$TransactionLinesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransactionEventsTable _eventIdTable(_$AppDatabase db) =>
      db.transactionEvents.createAlias(
        $_aliasNameGenerator(
          db.transactionLines.eventId,
          db.transactionEvents.id,
        ),
      );

  $$TransactionEventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<int>('event_id')!;

    final manager = $$TransactionEventsTableTableManager(
      $_db,
      $_db.transactionEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
    $_aliasNameGenerator(db.transactionLines.assetId, db.assets.id),
  );

  $$AssetsTableProcessedTableManager? get assetId {
    final $_column = $_itemColumn<int>('asset_id');
    if ($_column == null) return null;
    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $HoldingsTable _holdingIdTable(_$AppDatabase db) =>
      db.holdings.createAlias(
        $_aliasNameGenerator(db.transactionLines.holdingId, db.holdings.id),
      );

  $$HoldingsTableProcessedTableManager? get holdingId {
    final $_column = $_itemColumn<int>('holding_id');
    if ($_column == null) return null;
    final manager = $$HoldingsTableTableManager(
      $_db,
      $_db.holdings,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_holdingIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CashAccountsTable _cashAccountIdTable(_$AppDatabase db) =>
      db.cashAccounts.createAlias(
        $_aliasNameGenerator(
          db.transactionLines.cashAccountId,
          db.cashAccounts.id,
        ),
      );

  $$CashAccountsTableProcessedTableManager? get cashAccountId {
    final $_column = $_itemColumn<int>('cash_account_id');
    if ($_column == null) return null;
    final manager = $$CashAccountsTableTableManager(
      $_db,
      $_db.cashAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cashAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionLinesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionLinesTable> {
  $$TransactionLinesTableFilterComposer({
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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legacySourceTable => $composableBuilder(
    column: $table.legacySourceTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get legacySourceId => $composableBuilder(
    column: $table.legacySourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cashDelta => $composableBuilder(
    column: $table.cashDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grossAmount => $composableBuilder(
    column: $table.grossAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get feeAmount => $composableBuilder(
    column: $table.feeAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costBasisDelta => $composableBuilder(
    column: $table.costBasisDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costBasisSourceDelta => $composableBuilder(
    column: $table.costBasisSourceDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get realizedPnl => $composableBuilder(
    column: $table.realizedPnl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get realizedPnlSource => $composableBuilder(
    column: $table.realizedPnlSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fxRate => $composableBuilder(
    column: $table.fxRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$TransactionEventsTableFilterComposer get eventId {
    final $$TransactionEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.transactionEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionEventsTableFilterComposer(
            $db: $db,
            $table: $db.transactionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HoldingsTableFilterComposer get holdingId {
    final $$HoldingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.holdings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoldingsTableFilterComposer(
            $db: $db,
            $table: $db.holdings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CashAccountsTableFilterComposer get cashAccountId {
    final $$CashAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashAccountId,
      referencedTable: $db.cashAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashAccountsTableFilterComposer(
            $db: $db,
            $table: $db.cashAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionLinesTable> {
  $$TransactionLinesTableOrderingComposer({
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacySourceTable => $composableBuilder(
    column: $table.legacySourceTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get legacySourceId => $composableBuilder(
    column: $table.legacySourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cashDelta => $composableBuilder(
    column: $table.cashDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grossAmount => $composableBuilder(
    column: $table.grossAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get feeAmount => $composableBuilder(
    column: $table.feeAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get taxAmount => $composableBuilder(
    column: $table.taxAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costBasisDelta => $composableBuilder(
    column: $table.costBasisDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costBasisSourceDelta => $composableBuilder(
    column: $table.costBasisSourceDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get realizedPnl => $composableBuilder(
    column: $table.realizedPnl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get realizedPnlSource => $composableBuilder(
    column: $table.realizedPnlSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fxRate => $composableBuilder(
    column: $table.fxRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransactionEventsTableOrderingComposer get eventId {
    final $$TransactionEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.transactionEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionEventsTableOrderingComposer(
            $db: $db,
            $table: $db.transactionEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HoldingsTableOrderingComposer get holdingId {
    final $$HoldingsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.holdings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoldingsTableOrderingComposer(
            $db: $db,
            $table: $db.holdings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CashAccountsTableOrderingComposer get cashAccountId {
    final $$CashAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashAccountId,
      referencedTable: $db.cashAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.cashAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionLinesTable> {
  $$TransactionLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get legacySourceTable => $composableBuilder(
    column: $table.legacySourceTable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get legacySourceId => $composableBuilder(
    column: $table.legacySourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cashDelta =>
      $composableBuilder(column: $table.cashDelta, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get grossAmount => $composableBuilder(
    column: $table.grossAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get feeAmount =>
      $composableBuilder(column: $table.feeAmount, builder: (column) => column);

  GeneratedColumn<double> get taxAmount =>
      $composableBuilder(column: $table.taxAmount, builder: (column) => column);

  GeneratedColumn<double> get costBasisDelta => $composableBuilder(
    column: $table.costBasisDelta,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costBasisSourceDelta => $composableBuilder(
    column: $table.costBasisSourceDelta,
    builder: (column) => column,
  );

  GeneratedColumn<double> get realizedPnl => $composableBuilder(
    column: $table.realizedPnl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get realizedPnlSource => $composableBuilder(
    column: $table.realizedPnlSource,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fxRate =>
      $composableBuilder(column: $table.fxRate, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$TransactionEventsTableAnnotationComposer get eventId {
    final $$TransactionEventsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.eventId,
          referencedTable: $db.transactionEvents,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TransactionEventsTableAnnotationComposer(
                $db: $db,
                $table: $db.transactionEvents,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$HoldingsTableAnnotationComposer get holdingId {
    final $$HoldingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.holdingId,
      referencedTable: $db.holdings,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoldingsTableAnnotationComposer(
            $db: $db,
            $table: $db.holdings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CashAccountsTableAnnotationComposer get cashAccountId {
    final $$CashAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cashAccountId,
      referencedTable: $db.cashAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.cashAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionLinesTable,
          TransactionLine,
          $$TransactionLinesTableFilterComposer,
          $$TransactionLinesTableOrderingComposer,
          $$TransactionLinesTableAnnotationComposer,
          $$TransactionLinesTableCreateCompanionBuilder,
          $$TransactionLinesTableUpdateCompanionBuilder,
          (TransactionLine, $$TransactionLinesTableReferences),
          TransactionLine,
          PrefetchHooks Function({
            bool eventId,
            bool assetId,
            bool holdingId,
            bool cashAccountId,
          })
        > {
  $$TransactionLinesTableTableManager(
    _$AppDatabase db,
    $TransactionLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> eventId = const Value.absent(),
                Value<int?> assetId = const Value.absent(),
                Value<int?> holdingId = const Value.absent(),
                Value<int?> cashAccountId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String?> legacySourceTable = const Value.absent(),
                Value<int?> legacySourceId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<double> quantityDelta = const Value.absent(),
                Value<double> cashDelta = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> grossAmount = const Value.absent(),
                Value<double> feeAmount = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                Value<double> costBasisDelta = const Value.absent(),
                Value<double> costBasisSourceDelta = const Value.absent(),
                Value<double> realizedPnl = const Value.absent(),
                Value<String> realizedPnlSource = const Value.absent(),
                Value<double?> fxRate = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => TransactionLinesCompanion(
                id: id,
                eventId: eventId,
                assetId: assetId,
                holdingId: holdingId,
                cashAccountId: cashAccountId,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                legacySourceTable: legacySourceTable,
                legacySourceId: legacySourceId,
                action: action,
                currencyCode: currencyCode,
                quantityDelta: quantityDelta,
                cashDelta: cashDelta,
                unitPrice: unitPrice,
                grossAmount: grossAmount,
                feeAmount: feeAmount,
                taxAmount: taxAmount,
                costBasisDelta: costBasisDelta,
                costBasisSourceDelta: costBasisSourceDelta,
                realizedPnl: realizedPnl,
                realizedPnlSource: realizedPnlSource,
                fxRate: fxRate,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int eventId,
                Value<int?> assetId = const Value.absent(),
                Value<int?> holdingId = const Value.absent(),
                Value<int?> cashAccountId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<String?> lastModifiedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String?> legacySourceTable = const Value.absent(),
                Value<int?> legacySourceId = const Value.absent(),
                required String action,
                Value<String> currencyCode = const Value.absent(),
                Value<double> quantityDelta = const Value.absent(),
                Value<double> cashDelta = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> grossAmount = const Value.absent(),
                Value<double> feeAmount = const Value.absent(),
                Value<double> taxAmount = const Value.absent(),
                Value<double> costBasisDelta = const Value.absent(),
                Value<double> costBasisSourceDelta = const Value.absent(),
                Value<double> realizedPnl = const Value.absent(),
                Value<String> realizedPnlSource = const Value.absent(),
                Value<double?> fxRate = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => TransactionLinesCompanion.insert(
                id: id,
                eventId: eventId,
                assetId: assetId,
                holdingId: holdingId,
                cashAccountId: cashAccountId,
                clientId: clientId,
                dirty: dirty,
                lastModifiedAt: lastModifiedAt,
                deletedAt: deletedAt,
                legacySourceTable: legacySourceTable,
                legacySourceId: legacySourceId,
                action: action,
                currencyCode: currencyCode,
                quantityDelta: quantityDelta,
                cashDelta: cashDelta,
                unitPrice: unitPrice,
                grossAmount: grossAmount,
                feeAmount: feeAmount,
                taxAmount: taxAmount,
                costBasisDelta: costBasisDelta,
                costBasisSourceDelta: costBasisSourceDelta,
                realizedPnl: realizedPnl,
                realizedPnlSource: realizedPnlSource,
                fxRate: fxRate,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                eventId = false,
                assetId = false,
                holdingId = false,
                cashAccountId = false,
              }) {
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
                        if (eventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.eventId,
                                    referencedTable:
                                        $$TransactionLinesTableReferences
                                            ._eventIdTable(db),
                                    referencedColumn:
                                        $$TransactionLinesTableReferences
                                            ._eventIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (assetId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.assetId,
                                    referencedTable:
                                        $$TransactionLinesTableReferences
                                            ._assetIdTable(db),
                                    referencedColumn:
                                        $$TransactionLinesTableReferences
                                            ._assetIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (holdingId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.holdingId,
                                    referencedTable:
                                        $$TransactionLinesTableReferences
                                            ._holdingIdTable(db),
                                    referencedColumn:
                                        $$TransactionLinesTableReferences
                                            ._holdingIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (cashAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cashAccountId,
                                    referencedTable:
                                        $$TransactionLinesTableReferences
                                            ._cashAccountIdTable(db),
                                    referencedColumn:
                                        $$TransactionLinesTableReferences
                                            ._cashAccountIdTable(db)
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

typedef $$TransactionLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionLinesTable,
      TransactionLine,
      $$TransactionLinesTableFilterComposer,
      $$TransactionLinesTableOrderingComposer,
      $$TransactionLinesTableAnnotationComposer,
      $$TransactionLinesTableCreateCompanionBuilder,
      $$TransactionLinesTableUpdateCompanionBuilder,
      (TransactionLine, $$TransactionLinesTableReferences),
      TransactionLine,
      PrefetchHooks Function({
        bool eventId,
        bool assetId,
        bool holdingId,
        bool cashAccountId,
      })
    >;
typedef $$MarketNewsCachesTableCreateCompanionBuilder =
    MarketNewsCachesCompanion Function({
      Value<int> id,
      required String category,
      Value<bool> found,
      Value<String?> summaryDate,
      Value<String?> model,
      Value<int?> newsCount,
      Value<String?> summaryJson,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      required String cachedAt,
    });
typedef $$MarketNewsCachesTableUpdateCompanionBuilder =
    MarketNewsCachesCompanion Function({
      Value<int> id,
      Value<String> category,
      Value<bool> found,
      Value<String?> summaryDate,
      Value<String?> model,
      Value<int?> newsCount,
      Value<String?> summaryJson,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<String> cachedAt,
    });

class $$MarketNewsCachesTableFilterComposer
    extends Composer<_$AppDatabase, $MarketNewsCachesTable> {
  $$MarketNewsCachesTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get found => $composableBuilder(
    column: $table.found,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryDate => $composableBuilder(
    column: $table.summaryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newsCount => $composableBuilder(
    column: $table.newsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MarketNewsCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $MarketNewsCachesTable> {
  $$MarketNewsCachesTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get found => $composableBuilder(
    column: $table.found,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryDate => $composableBuilder(
    column: $table.summaryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newsCount => $composableBuilder(
    column: $table.newsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MarketNewsCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MarketNewsCachesTable> {
  $$MarketNewsCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get found =>
      $composableBuilder(column: $table.found, builder: (column) => column);

  GeneratedColumn<String> get summaryDate => $composableBuilder(
    column: $table.summaryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get newsCount =>
      $composableBuilder(column: $table.newsCount, builder: (column) => column);

  GeneratedColumn<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$MarketNewsCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MarketNewsCachesTable,
          MarketNewsCache,
          $$MarketNewsCachesTableFilterComposer,
          $$MarketNewsCachesTableOrderingComposer,
          $$MarketNewsCachesTableAnnotationComposer,
          $$MarketNewsCachesTableCreateCompanionBuilder,
          $$MarketNewsCachesTableUpdateCompanionBuilder,
          (
            MarketNewsCache,
            BaseReferences<
              _$AppDatabase,
              $MarketNewsCachesTable,
              MarketNewsCache
            >,
          ),
          MarketNewsCache,
          PrefetchHooks Function()
        > {
  $$MarketNewsCachesTableTableManager(
    _$AppDatabase db,
    $MarketNewsCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MarketNewsCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MarketNewsCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MarketNewsCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> found = const Value.absent(),
                Value<String?> summaryDate = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> newsCount = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String> cachedAt = const Value.absent(),
              }) => MarketNewsCachesCompanion(
                id: id,
                category: category,
                found: found,
                summaryDate: summaryDate,
                model: model,
                newsCount: newsCount,
                summaryJson: summaryJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String category,
                Value<bool> found = const Value.absent(),
                Value<String?> summaryDate = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> newsCount = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                required String cachedAt,
              }) => MarketNewsCachesCompanion.insert(
                id: id,
                category: category,
                found: found,
                summaryDate: summaryDate,
                model: model,
                newsCount: newsCount,
                summaryJson: summaryJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MarketNewsCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MarketNewsCachesTable,
      MarketNewsCache,
      $$MarketNewsCachesTableFilterComposer,
      $$MarketNewsCachesTableOrderingComposer,
      $$MarketNewsCachesTableAnnotationComposer,
      $$MarketNewsCachesTableCreateCompanionBuilder,
      $$MarketNewsCachesTableUpdateCompanionBuilder,
      (
        MarketNewsCache,
        BaseReferences<_$AppDatabase, $MarketNewsCachesTable, MarketNewsCache>,
      ),
      MarketNewsCache,
      PrefetchHooks Function()
    >;
typedef $$CompanyNewsCachesTableCreateCompanionBuilder =
    CompanyNewsCachesCompanion Function({
      Value<int> id,
      required String symbol,
      Value<bool> found,
      Value<String?> summaryDate,
      Value<String?> model,
      Value<int?> newsCount,
      Value<String?> summaryJson,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      required String cachedAt,
    });
typedef $$CompanyNewsCachesTableUpdateCompanionBuilder =
    CompanyNewsCachesCompanion Function({
      Value<int> id,
      Value<String> symbol,
      Value<bool> found,
      Value<String?> summaryDate,
      Value<String?> model,
      Value<int?> newsCount,
      Value<String?> summaryJson,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<String> cachedAt,
    });

class $$CompanyNewsCachesTableFilterComposer
    extends Composer<_$AppDatabase, $CompanyNewsCachesTable> {
  $$CompanyNewsCachesTableFilterComposer({
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

  ColumnFilters<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get found => $composableBuilder(
    column: $table.found,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryDate => $composableBuilder(
    column: $table.summaryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newsCount => $composableBuilder(
    column: $table.newsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompanyNewsCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $CompanyNewsCachesTable> {
  $$CompanyNewsCachesTableOrderingComposer({
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

  ColumnOrderings<String> get symbol => $composableBuilder(
    column: $table.symbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get found => $composableBuilder(
    column: $table.found,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryDate => $composableBuilder(
    column: $table.summaryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newsCount => $composableBuilder(
    column: $table.newsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompanyNewsCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompanyNewsCachesTable> {
  $$CompanyNewsCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get symbol =>
      $composableBuilder(column: $table.symbol, builder: (column) => column);

  GeneratedColumn<bool> get found =>
      $composableBuilder(column: $table.found, builder: (column) => column);

  GeneratedColumn<String> get summaryDate => $composableBuilder(
    column: $table.summaryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get newsCount =>
      $composableBuilder(column: $table.newsCount, builder: (column) => column);

  GeneratedColumn<String> get summaryJson => $composableBuilder(
    column: $table.summaryJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CompanyNewsCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompanyNewsCachesTable,
          CompanyNewsCache,
          $$CompanyNewsCachesTableFilterComposer,
          $$CompanyNewsCachesTableOrderingComposer,
          $$CompanyNewsCachesTableAnnotationComposer,
          $$CompanyNewsCachesTableCreateCompanionBuilder,
          $$CompanyNewsCachesTableUpdateCompanionBuilder,
          (
            CompanyNewsCache,
            BaseReferences<
              _$AppDatabase,
              $CompanyNewsCachesTable,
              CompanyNewsCache
            >,
          ),
          CompanyNewsCache,
          PrefetchHooks Function()
        > {
  $$CompanyNewsCachesTableTableManager(
    _$AppDatabase db,
    $CompanyNewsCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompanyNewsCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompanyNewsCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompanyNewsCachesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> symbol = const Value.absent(),
                Value<bool> found = const Value.absent(),
                Value<String?> summaryDate = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> newsCount = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String> cachedAt = const Value.absent(),
              }) => CompanyNewsCachesCompanion(
                id: id,
                symbol: symbol,
                found: found,
                summaryDate: summaryDate,
                model: model,
                newsCount: newsCount,
                summaryJson: summaryJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String symbol,
                Value<bool> found = const Value.absent(),
                Value<String?> summaryDate = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> newsCount = const Value.absent(),
                Value<String?> summaryJson = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                required String cachedAt,
              }) => CompanyNewsCachesCompanion.insert(
                id: id,
                symbol: symbol,
                found: found,
                summaryDate: summaryDate,
                model: model,
                newsCount: newsCount,
                summaryJson: summaryJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompanyNewsCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompanyNewsCachesTable,
      CompanyNewsCache,
      $$CompanyNewsCachesTableFilterComposer,
      $$CompanyNewsCachesTableOrderingComposer,
      $$CompanyNewsCachesTableAnnotationComposer,
      $$CompanyNewsCachesTableCreateCompanionBuilder,
      $$CompanyNewsCachesTableUpdateCompanionBuilder,
      (
        CompanyNewsCache,
        BaseReferences<
          _$AppDatabase,
          $CompanyNewsCachesTable,
          CompanyNewsCache
        >,
      ),
      CompanyNewsCache,
      PrefetchHooks Function()
    >;
typedef $$DailyPortfolioSnapshotsTableCreateCompanionBuilder =
    DailyPortfolioSnapshotsCompanion Function({
      Value<int> id,
      required String snapshotDate,
      required double totalPurchaseAmount,
      required double totalValuationAmount,
      required double profitAmount,
      required double profitRate,
      Value<double> exchangeRate,
      required String createdAt,
    });
typedef $$DailyPortfolioSnapshotsTableUpdateCompanionBuilder =
    DailyPortfolioSnapshotsCompanion Function({
      Value<int> id,
      Value<String> snapshotDate,
      Value<double> totalPurchaseAmount,
      Value<double> totalValuationAmount,
      Value<double> profitAmount,
      Value<double> profitRate,
      Value<double> exchangeRate,
      Value<String> createdAt,
    });

final class $$DailyPortfolioSnapshotsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DailyPortfolioSnapshotsTable,
          DailyPortfolioSnapshot
        > {
  $$DailyPortfolioSnapshotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $DailyPortfolioSnapshotItemsTable,
    List<DailyPortfolioSnapshotItem>
  >
  _dailyPortfolioSnapshotItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dailyPortfolioSnapshotItems,
        aliasName: $_aliasNameGenerator(
          db.dailyPortfolioSnapshots.id,
          db.dailyPortfolioSnapshotItems.snapshotId,
        ),
      );

  $$DailyPortfolioSnapshotItemsTableProcessedTableManager
  get dailyPortfolioSnapshotItemsRefs {
    final manager = $$DailyPortfolioSnapshotItemsTableTableManager(
      $_db,
      $_db.dailyPortfolioSnapshotItems,
    ).filter((f) => f.snapshotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dailyPortfolioSnapshotItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $DailyPortfolioSnapshotHoldingItemsTable,
    List<DailyPortfolioSnapshotHoldingItem>
  >
  _dailyPortfolioSnapshotHoldingItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dailyPortfolioSnapshotHoldingItems,
        aliasName: $_aliasNameGenerator(
          db.dailyPortfolioSnapshots.id,
          db.dailyPortfolioSnapshotHoldingItems.snapshotId,
        ),
      );

  $$DailyPortfolioSnapshotHoldingItemsTableProcessedTableManager
  get dailyPortfolioSnapshotHoldingItemsRefs {
    final manager = $$DailyPortfolioSnapshotHoldingItemsTableTableManager(
      $_db,
      $_db.dailyPortfolioSnapshotHoldingItems,
    ).filter((f) => f.snapshotId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dailyPortfolioSnapshotHoldingItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DailyPortfolioSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPortfolioSnapshotsTable> {
  $$DailyPortfolioSnapshotsTableFilterComposer({
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

  ColumnFilters<String> get snapshotDate => $composableBuilder(
    column: $table.snapshotDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPurchaseAmount => $composableBuilder(
    column: $table.totalPurchaseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalValuationAmount => $composableBuilder(
    column: $table.totalValuationAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitAmount => $composableBuilder(
    column: $table.profitAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitRate => $composableBuilder(
    column: $table.profitRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dailyPortfolioSnapshotItemsRefs(
    Expression<bool> Function(
      $$DailyPortfolioSnapshotItemsTableFilterComposer f,
    )
    f,
  ) {
    final $$DailyPortfolioSnapshotItemsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dailyPortfolioSnapshotItems,
          getReferencedColumn: (t) => t.snapshotId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotItemsTableFilterComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshotItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> dailyPortfolioSnapshotHoldingItemsRefs(
    Expression<bool> Function(
      $$DailyPortfolioSnapshotHoldingItemsTableFilterComposer f,
    )
    f,
  ) {
    final $$DailyPortfolioSnapshotHoldingItemsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dailyPortfolioSnapshotHoldingItems,
          getReferencedColumn: (t) => t.snapshotId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotHoldingItemsTableFilterComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshotHoldingItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DailyPortfolioSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPortfolioSnapshotsTable> {
  $$DailyPortfolioSnapshotsTableOrderingComposer({
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

  ColumnOrderings<String> get snapshotDate => $composableBuilder(
    column: $table.snapshotDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPurchaseAmount => $composableBuilder(
    column: $table.totalPurchaseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalValuationAmount => $composableBuilder(
    column: $table.totalValuationAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitAmount => $composableBuilder(
    column: $table.profitAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitRate => $composableBuilder(
    column: $table.profitRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyPortfolioSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPortfolioSnapshotsTable> {
  $$DailyPortfolioSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get snapshotDate => $composableBuilder(
    column: $table.snapshotDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalPurchaseAmount => $composableBuilder(
    column: $table.totalPurchaseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalValuationAmount => $composableBuilder(
    column: $table.totalValuationAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profitAmount => $composableBuilder(
    column: $table.profitAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profitRate => $composableBuilder(
    column: $table.profitRate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> dailyPortfolioSnapshotItemsRefs<T extends Object>(
    Expression<T> Function(
      $$DailyPortfolioSnapshotItemsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$DailyPortfolioSnapshotItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dailyPortfolioSnapshotItems,
          getReferencedColumn: (t) => t.snapshotId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshotItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> dailyPortfolioSnapshotHoldingItemsRefs<T extends Object>(
    Expression<T> Function(
      $$DailyPortfolioSnapshotHoldingItemsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$DailyPortfolioSnapshotHoldingItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dailyPortfolioSnapshotHoldingItems,
          getReferencedColumn: (t) => t.snapshotId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotHoldingItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshotHoldingItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DailyPortfolioSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPortfolioSnapshotsTable,
          DailyPortfolioSnapshot,
          $$DailyPortfolioSnapshotsTableFilterComposer,
          $$DailyPortfolioSnapshotsTableOrderingComposer,
          $$DailyPortfolioSnapshotsTableAnnotationComposer,
          $$DailyPortfolioSnapshotsTableCreateCompanionBuilder,
          $$DailyPortfolioSnapshotsTableUpdateCompanionBuilder,
          (DailyPortfolioSnapshot, $$DailyPortfolioSnapshotsTableReferences),
          DailyPortfolioSnapshot,
          PrefetchHooks Function({
            bool dailyPortfolioSnapshotItemsRefs,
            bool dailyPortfolioSnapshotHoldingItemsRefs,
          })
        > {
  $$DailyPortfolioSnapshotsTableTableManager(
    _$AppDatabase db,
    $DailyPortfolioSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPortfolioSnapshotsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DailyPortfolioSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyPortfolioSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> snapshotDate = const Value.absent(),
                Value<double> totalPurchaseAmount = const Value.absent(),
                Value<double> totalValuationAmount = const Value.absent(),
                Value<double> profitAmount = const Value.absent(),
                Value<double> profitRate = const Value.absent(),
                Value<double> exchangeRate = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => DailyPortfolioSnapshotsCompanion(
                id: id,
                snapshotDate: snapshotDate,
                totalPurchaseAmount: totalPurchaseAmount,
                totalValuationAmount: totalValuationAmount,
                profitAmount: profitAmount,
                profitRate: profitRate,
                exchangeRate: exchangeRate,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String snapshotDate,
                required double totalPurchaseAmount,
                required double totalValuationAmount,
                required double profitAmount,
                required double profitRate,
                Value<double> exchangeRate = const Value.absent(),
                required String createdAt,
              }) => DailyPortfolioSnapshotsCompanion.insert(
                id: id,
                snapshotDate: snapshotDate,
                totalPurchaseAmount: totalPurchaseAmount,
                totalValuationAmount: totalValuationAmount,
                profitAmount: profitAmount,
                profitRate: profitRate,
                exchangeRate: exchangeRate,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DailyPortfolioSnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                dailyPortfolioSnapshotItemsRefs = false,
                dailyPortfolioSnapshotHoldingItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (dailyPortfolioSnapshotItemsRefs)
                      db.dailyPortfolioSnapshotItems,
                    if (dailyPortfolioSnapshotHoldingItemsRefs)
                      db.dailyPortfolioSnapshotHoldingItems,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (dailyPortfolioSnapshotItemsRefs)
                        await $_getPrefetchedData<
                          DailyPortfolioSnapshot,
                          $DailyPortfolioSnapshotsTable,
                          DailyPortfolioSnapshotItem
                        >(
                          currentTable: table,
                          referencedTable:
                              $$DailyPortfolioSnapshotsTableReferences
                                  ._dailyPortfolioSnapshotItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DailyPortfolioSnapshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).dailyPortfolioSnapshotItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.snapshotId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dailyPortfolioSnapshotHoldingItemsRefs)
                        await $_getPrefetchedData<
                          DailyPortfolioSnapshot,
                          $DailyPortfolioSnapshotsTable,
                          DailyPortfolioSnapshotHoldingItem
                        >(
                          currentTable: table,
                          referencedTable:
                              $$DailyPortfolioSnapshotsTableReferences
                                  ._dailyPortfolioSnapshotHoldingItemsRefsTable(
                                    db,
                                  ),
                          managerFromTypedResult: (p0) =>
                              $$DailyPortfolioSnapshotsTableReferences(
                                db,
                                table,
                                p0,
                              ).dailyPortfolioSnapshotHoldingItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.snapshotId == item.id,
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

typedef $$DailyPortfolioSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPortfolioSnapshotsTable,
      DailyPortfolioSnapshot,
      $$DailyPortfolioSnapshotsTableFilterComposer,
      $$DailyPortfolioSnapshotsTableOrderingComposer,
      $$DailyPortfolioSnapshotsTableAnnotationComposer,
      $$DailyPortfolioSnapshotsTableCreateCompanionBuilder,
      $$DailyPortfolioSnapshotsTableUpdateCompanionBuilder,
      (DailyPortfolioSnapshot, $$DailyPortfolioSnapshotsTableReferences),
      DailyPortfolioSnapshot,
      PrefetchHooks Function({
        bool dailyPortfolioSnapshotItemsRefs,
        bool dailyPortfolioSnapshotHoldingItemsRefs,
      })
    >;
typedef $$DailyPortfolioSnapshotItemsTableCreateCompanionBuilder =
    DailyPortfolioSnapshotItemsCompanion Function({
      Value<int> id,
      required int snapshotId,
      required int assetId,
      Value<String?> assetClientId,
      required String assetTitle,
      required double totalPurchaseAmount,
      required double totalValuationAmount,
      required double profitAmount,
      required double profitRate,
      required int holdingCount,
    });
typedef $$DailyPortfolioSnapshotItemsTableUpdateCompanionBuilder =
    DailyPortfolioSnapshotItemsCompanion Function({
      Value<int> id,
      Value<int> snapshotId,
      Value<int> assetId,
      Value<String?> assetClientId,
      Value<String> assetTitle,
      Value<double> totalPurchaseAmount,
      Value<double> totalValuationAmount,
      Value<double> profitAmount,
      Value<double> profitRate,
      Value<int> holdingCount,
    });

final class $$DailyPortfolioSnapshotItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DailyPortfolioSnapshotItemsTable,
          DailyPortfolioSnapshotItem
        > {
  $$DailyPortfolioSnapshotItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DailyPortfolioSnapshotsTable _snapshotIdTable(_$AppDatabase db) =>
      db.dailyPortfolioSnapshots.createAlias(
        $_aliasNameGenerator(
          db.dailyPortfolioSnapshotItems.snapshotId,
          db.dailyPortfolioSnapshots.id,
        ),
      );

  $$DailyPortfolioSnapshotsTableProcessedTableManager get snapshotId {
    final $_column = $_itemColumn<int>('snapshot_id')!;

    final manager = $$DailyPortfolioSnapshotsTableTableManager(
      $_db,
      $_db.dailyPortfolioSnapshots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_snapshotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
    $_aliasNameGenerator(db.dailyPortfolioSnapshotItems.assetId, db.assets.id),
  );

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DailyPortfolioSnapshotItemsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPortfolioSnapshotItemsTable> {
  $$DailyPortfolioSnapshotItemsTableFilterComposer({
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

  ColumnFilters<String> get assetClientId => $composableBuilder(
    column: $table.assetClientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetTitle => $composableBuilder(
    column: $table.assetTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPurchaseAmount => $composableBuilder(
    column: $table.totalPurchaseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalValuationAmount => $composableBuilder(
    column: $table.totalValuationAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitAmount => $composableBuilder(
    column: $table.profitAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitRate => $composableBuilder(
    column: $table.profitRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get holdingCount => $composableBuilder(
    column: $table.holdingCount,
    builder: (column) => ColumnFilters(column),
  );

  $$DailyPortfolioSnapshotsTableFilterComposer get snapshotId {
    final $$DailyPortfolioSnapshotsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.snapshotId,
          referencedTable: $db.dailyPortfolioSnapshots,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotsTableFilterComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyPortfolioSnapshotItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPortfolioSnapshotItemsTable> {
  $$DailyPortfolioSnapshotItemsTableOrderingComposer({
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

  ColumnOrderings<String> get assetClientId => $composableBuilder(
    column: $table.assetClientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetTitle => $composableBuilder(
    column: $table.assetTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPurchaseAmount => $composableBuilder(
    column: $table.totalPurchaseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalValuationAmount => $composableBuilder(
    column: $table.totalValuationAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitAmount => $composableBuilder(
    column: $table.profitAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitRate => $composableBuilder(
    column: $table.profitRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get holdingCount => $composableBuilder(
    column: $table.holdingCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$DailyPortfolioSnapshotsTableOrderingComposer get snapshotId {
    final $$DailyPortfolioSnapshotsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.snapshotId,
          referencedTable: $db.dailyPortfolioSnapshots,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotsTableOrderingComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyPortfolioSnapshotItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPortfolioSnapshotItemsTable> {
  $$DailyPortfolioSnapshotItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get assetClientId => $composableBuilder(
    column: $table.assetClientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetTitle => $composableBuilder(
    column: $table.assetTitle,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalPurchaseAmount => $composableBuilder(
    column: $table.totalPurchaseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalValuationAmount => $composableBuilder(
    column: $table.totalValuationAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profitAmount => $composableBuilder(
    column: $table.profitAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profitRate => $composableBuilder(
    column: $table.profitRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get holdingCount => $composableBuilder(
    column: $table.holdingCount,
    builder: (column) => column,
  );

  $$DailyPortfolioSnapshotsTableAnnotationComposer get snapshotId {
    final $$DailyPortfolioSnapshotsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.snapshotId,
          referencedTable: $db.dailyPortfolioSnapshots,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotsTableAnnotationComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyPortfolioSnapshotItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPortfolioSnapshotItemsTable,
          DailyPortfolioSnapshotItem,
          $$DailyPortfolioSnapshotItemsTableFilterComposer,
          $$DailyPortfolioSnapshotItemsTableOrderingComposer,
          $$DailyPortfolioSnapshotItemsTableAnnotationComposer,
          $$DailyPortfolioSnapshotItemsTableCreateCompanionBuilder,
          $$DailyPortfolioSnapshotItemsTableUpdateCompanionBuilder,
          (
            DailyPortfolioSnapshotItem,
            $$DailyPortfolioSnapshotItemsTableReferences,
          ),
          DailyPortfolioSnapshotItem,
          PrefetchHooks Function({bool snapshotId, bool assetId})
        > {
  $$DailyPortfolioSnapshotItemsTableTableManager(
    _$AppDatabase db,
    $DailyPortfolioSnapshotItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPortfolioSnapshotItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DailyPortfolioSnapshotItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyPortfolioSnapshotItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> snapshotId = const Value.absent(),
                Value<int> assetId = const Value.absent(),
                Value<String?> assetClientId = const Value.absent(),
                Value<String> assetTitle = const Value.absent(),
                Value<double> totalPurchaseAmount = const Value.absent(),
                Value<double> totalValuationAmount = const Value.absent(),
                Value<double> profitAmount = const Value.absent(),
                Value<double> profitRate = const Value.absent(),
                Value<int> holdingCount = const Value.absent(),
              }) => DailyPortfolioSnapshotItemsCompanion(
                id: id,
                snapshotId: snapshotId,
                assetId: assetId,
                assetClientId: assetClientId,
                assetTitle: assetTitle,
                totalPurchaseAmount: totalPurchaseAmount,
                totalValuationAmount: totalValuationAmount,
                profitAmount: profitAmount,
                profitRate: profitRate,
                holdingCount: holdingCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int snapshotId,
                required int assetId,
                Value<String?> assetClientId = const Value.absent(),
                required String assetTitle,
                required double totalPurchaseAmount,
                required double totalValuationAmount,
                required double profitAmount,
                required double profitRate,
                required int holdingCount,
              }) => DailyPortfolioSnapshotItemsCompanion.insert(
                id: id,
                snapshotId: snapshotId,
                assetId: assetId,
                assetClientId: assetClientId,
                assetTitle: assetTitle,
                totalPurchaseAmount: totalPurchaseAmount,
                totalValuationAmount: totalValuationAmount,
                profitAmount: profitAmount,
                profitRate: profitRate,
                holdingCount: holdingCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DailyPortfolioSnapshotItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({snapshotId = false, assetId = false}) {
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
                    if (snapshotId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.snapshotId,
                                referencedTable:
                                    $$DailyPortfolioSnapshotItemsTableReferences
                                        ._snapshotIdTable(db),
                                referencedColumn:
                                    $$DailyPortfolioSnapshotItemsTableReferences
                                        ._snapshotIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable:
                                    $$DailyPortfolioSnapshotItemsTableReferences
                                        ._assetIdTable(db),
                                referencedColumn:
                                    $$DailyPortfolioSnapshotItemsTableReferences
                                        ._assetIdTable(db)
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

typedef $$DailyPortfolioSnapshotItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPortfolioSnapshotItemsTable,
      DailyPortfolioSnapshotItem,
      $$DailyPortfolioSnapshotItemsTableFilterComposer,
      $$DailyPortfolioSnapshotItemsTableOrderingComposer,
      $$DailyPortfolioSnapshotItemsTableAnnotationComposer,
      $$DailyPortfolioSnapshotItemsTableCreateCompanionBuilder,
      $$DailyPortfolioSnapshotItemsTableUpdateCompanionBuilder,
      (
        DailyPortfolioSnapshotItem,
        $$DailyPortfolioSnapshotItemsTableReferences,
      ),
      DailyPortfolioSnapshotItem,
      PrefetchHooks Function({bool snapshotId, bool assetId})
    >;
typedef $$DailyPortfolioSnapshotHoldingItemsTableCreateCompanionBuilder =
    DailyPortfolioSnapshotHoldingItemsCompanion Function({
      Value<int> id,
      required int snapshotId,
      Value<int?> assetId,
      Value<String?> assetClientId,
      required String assetTitle,
      Value<int?> holdingId,
      Value<String?> holdingClientId,
      required String holdingName,
      required String holdingSymbol,
      required String currencyCode,
      required double quantity,
      required double totalPurchaseAmount,
      required double totalValuationAmount,
      required double profitAmount,
      required double profitRate,
    });
typedef $$DailyPortfolioSnapshotHoldingItemsTableUpdateCompanionBuilder =
    DailyPortfolioSnapshotHoldingItemsCompanion Function({
      Value<int> id,
      Value<int> snapshotId,
      Value<int?> assetId,
      Value<String?> assetClientId,
      Value<String> assetTitle,
      Value<int?> holdingId,
      Value<String?> holdingClientId,
      Value<String> holdingName,
      Value<String> holdingSymbol,
      Value<String> currencyCode,
      Value<double> quantity,
      Value<double> totalPurchaseAmount,
      Value<double> totalValuationAmount,
      Value<double> profitAmount,
      Value<double> profitRate,
    });

final class $$DailyPortfolioSnapshotHoldingItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DailyPortfolioSnapshotHoldingItemsTable,
          DailyPortfolioSnapshotHoldingItem
        > {
  $$DailyPortfolioSnapshotHoldingItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DailyPortfolioSnapshotsTable _snapshotIdTable(_$AppDatabase db) =>
      db.dailyPortfolioSnapshots.createAlias(
        $_aliasNameGenerator(
          db.dailyPortfolioSnapshotHoldingItems.snapshotId,
          db.dailyPortfolioSnapshots.id,
        ),
      );

  $$DailyPortfolioSnapshotsTableProcessedTableManager get snapshotId {
    final $_column = $_itemColumn<int>('snapshot_id')!;

    final manager = $$DailyPortfolioSnapshotsTableTableManager(
      $_db,
      $_db.dailyPortfolioSnapshots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_snapshotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DailyPortfolioSnapshotHoldingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPortfolioSnapshotHoldingItemsTable> {
  $$DailyPortfolioSnapshotHoldingItemsTableFilterComposer({
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

  ColumnFilters<int> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetClientId => $composableBuilder(
    column: $table.assetClientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetTitle => $composableBuilder(
    column: $table.assetTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get holdingId => $composableBuilder(
    column: $table.holdingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get holdingClientId => $composableBuilder(
    column: $table.holdingClientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get holdingName => $composableBuilder(
    column: $table.holdingName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get holdingSymbol => $composableBuilder(
    column: $table.holdingSymbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPurchaseAmount => $composableBuilder(
    column: $table.totalPurchaseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalValuationAmount => $composableBuilder(
    column: $table.totalValuationAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitAmount => $composableBuilder(
    column: $table.profitAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get profitRate => $composableBuilder(
    column: $table.profitRate,
    builder: (column) => ColumnFilters(column),
  );

  $$DailyPortfolioSnapshotsTableFilterComposer get snapshotId {
    final $$DailyPortfolioSnapshotsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.snapshotId,
          referencedTable: $db.dailyPortfolioSnapshots,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotsTableFilterComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DailyPortfolioSnapshotHoldingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPortfolioSnapshotHoldingItemsTable> {
  $$DailyPortfolioSnapshotHoldingItemsTableOrderingComposer({
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

  ColumnOrderings<int> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetClientId => $composableBuilder(
    column: $table.assetClientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetTitle => $composableBuilder(
    column: $table.assetTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get holdingId => $composableBuilder(
    column: $table.holdingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get holdingClientId => $composableBuilder(
    column: $table.holdingClientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get holdingName => $composableBuilder(
    column: $table.holdingName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get holdingSymbol => $composableBuilder(
    column: $table.holdingSymbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPurchaseAmount => $composableBuilder(
    column: $table.totalPurchaseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalValuationAmount => $composableBuilder(
    column: $table.totalValuationAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitAmount => $composableBuilder(
    column: $table.profitAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get profitRate => $composableBuilder(
    column: $table.profitRate,
    builder: (column) => ColumnOrderings(column),
  );

  $$DailyPortfolioSnapshotsTableOrderingComposer get snapshotId {
    final $$DailyPortfolioSnapshotsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.snapshotId,
          referencedTable: $db.dailyPortfolioSnapshots,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotsTableOrderingComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DailyPortfolioSnapshotHoldingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPortfolioSnapshotHoldingItemsTable> {
  $$DailyPortfolioSnapshotHoldingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get assetClientId => $composableBuilder(
    column: $table.assetClientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assetTitle => $composableBuilder(
    column: $table.assetTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get holdingId =>
      $composableBuilder(column: $table.holdingId, builder: (column) => column);

  GeneratedColumn<String> get holdingClientId => $composableBuilder(
    column: $table.holdingClientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get holdingName => $composableBuilder(
    column: $table.holdingName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get holdingSymbol => $composableBuilder(
    column: $table.holdingSymbol,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get totalPurchaseAmount => $composableBuilder(
    column: $table.totalPurchaseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalValuationAmount => $composableBuilder(
    column: $table.totalValuationAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profitAmount => $composableBuilder(
    column: $table.profitAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get profitRate => $composableBuilder(
    column: $table.profitRate,
    builder: (column) => column,
  );

  $$DailyPortfolioSnapshotsTableAnnotationComposer get snapshotId {
    final $$DailyPortfolioSnapshotsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.snapshotId,
          referencedTable: $db.dailyPortfolioSnapshots,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPortfolioSnapshotsTableAnnotationComposer(
                $db: $db,
                $table: $db.dailyPortfolioSnapshots,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$DailyPortfolioSnapshotHoldingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPortfolioSnapshotHoldingItemsTable,
          DailyPortfolioSnapshotHoldingItem,
          $$DailyPortfolioSnapshotHoldingItemsTableFilterComposer,
          $$DailyPortfolioSnapshotHoldingItemsTableOrderingComposer,
          $$DailyPortfolioSnapshotHoldingItemsTableAnnotationComposer,
          $$DailyPortfolioSnapshotHoldingItemsTableCreateCompanionBuilder,
          $$DailyPortfolioSnapshotHoldingItemsTableUpdateCompanionBuilder,
          (
            DailyPortfolioSnapshotHoldingItem,
            $$DailyPortfolioSnapshotHoldingItemsTableReferences,
          ),
          DailyPortfolioSnapshotHoldingItem,
          PrefetchHooks Function({bool snapshotId})
        > {
  $$DailyPortfolioSnapshotHoldingItemsTableTableManager(
    _$AppDatabase db,
    $DailyPortfolioSnapshotHoldingItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPortfolioSnapshotHoldingItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DailyPortfolioSnapshotHoldingItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyPortfolioSnapshotHoldingItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> snapshotId = const Value.absent(),
                Value<int?> assetId = const Value.absent(),
                Value<String?> assetClientId = const Value.absent(),
                Value<String> assetTitle = const Value.absent(),
                Value<int?> holdingId = const Value.absent(),
                Value<String?> holdingClientId = const Value.absent(),
                Value<String> holdingName = const Value.absent(),
                Value<String> holdingSymbol = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> totalPurchaseAmount = const Value.absent(),
                Value<double> totalValuationAmount = const Value.absent(),
                Value<double> profitAmount = const Value.absent(),
                Value<double> profitRate = const Value.absent(),
              }) => DailyPortfolioSnapshotHoldingItemsCompanion(
                id: id,
                snapshotId: snapshotId,
                assetId: assetId,
                assetClientId: assetClientId,
                assetTitle: assetTitle,
                holdingId: holdingId,
                holdingClientId: holdingClientId,
                holdingName: holdingName,
                holdingSymbol: holdingSymbol,
                currencyCode: currencyCode,
                quantity: quantity,
                totalPurchaseAmount: totalPurchaseAmount,
                totalValuationAmount: totalValuationAmount,
                profitAmount: profitAmount,
                profitRate: profitRate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int snapshotId,
                Value<int?> assetId = const Value.absent(),
                Value<String?> assetClientId = const Value.absent(),
                required String assetTitle,
                Value<int?> holdingId = const Value.absent(),
                Value<String?> holdingClientId = const Value.absent(),
                required String holdingName,
                required String holdingSymbol,
                required String currencyCode,
                required double quantity,
                required double totalPurchaseAmount,
                required double totalValuationAmount,
                required double profitAmount,
                required double profitRate,
              }) => DailyPortfolioSnapshotHoldingItemsCompanion.insert(
                id: id,
                snapshotId: snapshotId,
                assetId: assetId,
                assetClientId: assetClientId,
                assetTitle: assetTitle,
                holdingId: holdingId,
                holdingClientId: holdingClientId,
                holdingName: holdingName,
                holdingSymbol: holdingSymbol,
                currencyCode: currencyCode,
                quantity: quantity,
                totalPurchaseAmount: totalPurchaseAmount,
                totalValuationAmount: totalValuationAmount,
                profitAmount: profitAmount,
                profitRate: profitRate,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DailyPortfolioSnapshotHoldingItemsTableReferences(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({snapshotId = false}) {
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
                    if (snapshotId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.snapshotId,
                                referencedTable:
                                    $$DailyPortfolioSnapshotHoldingItemsTableReferences
                                        ._snapshotIdTable(db),
                                referencedColumn:
                                    $$DailyPortfolioSnapshotHoldingItemsTableReferences
                                        ._snapshotIdTable(db)
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

typedef $$DailyPortfolioSnapshotHoldingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPortfolioSnapshotHoldingItemsTable,
      DailyPortfolioSnapshotHoldingItem,
      $$DailyPortfolioSnapshotHoldingItemsTableFilterComposer,
      $$DailyPortfolioSnapshotHoldingItemsTableOrderingComposer,
      $$DailyPortfolioSnapshotHoldingItemsTableAnnotationComposer,
      $$DailyPortfolioSnapshotHoldingItemsTableCreateCompanionBuilder,
      $$DailyPortfolioSnapshotHoldingItemsTableUpdateCompanionBuilder,
      (
        DailyPortfolioSnapshotHoldingItem,
        $$DailyPortfolioSnapshotHoldingItemsTableReferences,
      ),
      DailyPortfolioSnapshotHoldingItem,
      PrefetchHooks Function({bool snapshotId})
    >;
typedef $$AssetAllocationTargetsTableCreateCompanionBuilder =
    AssetAllocationTargetsCompanion Function({
      Value<int> id,
      required int assetId,
      required double targetRatio,
    });
typedef $$AssetAllocationTargetsTableUpdateCompanionBuilder =
    AssetAllocationTargetsCompanion Function({
      Value<int> id,
      Value<int> assetId,
      Value<double> targetRatio,
    });

final class $$AssetAllocationTargetsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AssetAllocationTargetsTable,
          AssetAllocationTarget
        > {
  $$AssetAllocationTargetsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
    $_aliasNameGenerator(db.assetAllocationTargets.assetId, db.assets.id),
  );

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetAllocationTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetAllocationTargetsTable> {
  $$AssetAllocationTargetsTableFilterComposer({
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

  ColumnFilters<double> get targetRatio => $composableBuilder(
    column: $table.targetRatio,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetAllocationTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetAllocationTargetsTable> {
  $$AssetAllocationTargetsTableOrderingComposer({
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

  ColumnOrderings<double> get targetRatio => $composableBuilder(
    column: $table.targetRatio,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetAllocationTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetAllocationTargetsTable> {
  $$AssetAllocationTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get targetRatio => $composableBuilder(
    column: $table.targetRatio,
    builder: (column) => column,
  );

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetAllocationTargetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetAllocationTargetsTable,
          AssetAllocationTarget,
          $$AssetAllocationTargetsTableFilterComposer,
          $$AssetAllocationTargetsTableOrderingComposer,
          $$AssetAllocationTargetsTableAnnotationComposer,
          $$AssetAllocationTargetsTableCreateCompanionBuilder,
          $$AssetAllocationTargetsTableUpdateCompanionBuilder,
          (AssetAllocationTarget, $$AssetAllocationTargetsTableReferences),
          AssetAllocationTarget,
          PrefetchHooks Function({bool assetId})
        > {
  $$AssetAllocationTargetsTableTableManager(
    _$AppDatabase db,
    $AssetAllocationTargetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetAllocationTargetsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AssetAllocationTargetsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AssetAllocationTargetsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> assetId = const Value.absent(),
                Value<double> targetRatio = const Value.absent(),
              }) => AssetAllocationTargetsCompanion(
                id: id,
                assetId: assetId,
                targetRatio: targetRatio,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int assetId,
                required double targetRatio,
              }) => AssetAllocationTargetsCompanion.insert(
                id: id,
                assetId: assetId,
                targetRatio: targetRatio,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssetAllocationTargetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false}) {
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
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable:
                                    $$AssetAllocationTargetsTableReferences
                                        ._assetIdTable(db),
                                referencedColumn:
                                    $$AssetAllocationTargetsTableReferences
                                        ._assetIdTable(db)
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

typedef $$AssetAllocationTargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetAllocationTargetsTable,
      AssetAllocationTarget,
      $$AssetAllocationTargetsTableFilterComposer,
      $$AssetAllocationTargetsTableOrderingComposer,
      $$AssetAllocationTargetsTableAnnotationComposer,
      $$AssetAllocationTargetsTableCreateCompanionBuilder,
      $$AssetAllocationTargetsTableUpdateCompanionBuilder,
      (AssetAllocationTarget, $$AssetAllocationTargetsTableReferences),
      AssetAllocationTarget,
      PrefetchHooks Function({bool assetId})
    >;
typedef $$ExchangeRatesTableCreateCompanionBuilder =
    ExchangeRatesCompanion Function({
      Value<int> id,
      required String currencyPair,
      required double rate,
      required String recordedAt,
      Value<String> source,
    });
typedef $$ExchangeRatesTableUpdateCompanionBuilder =
    ExchangeRatesCompanion Function({
      Value<int> id,
      Value<String> currencyPair,
      Value<double> rate,
      Value<String> recordedAt,
      Value<String> source,
    });

class $$ExchangeRatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableFilterComposer({
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

  ColumnFilters<String> get currencyPair => $composableBuilder(
    column: $table.currencyPair,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExchangeRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableOrderingComposer({
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

  ColumnOrderings<String> get currencyPair => $composableBuilder(
    column: $table.currencyPair,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExchangeRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currencyPair => $composableBuilder(
    column: $table.currencyPair,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<String> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$ExchangeRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExchangeRatesTable,
          ExchangeRate,
          $$ExchangeRatesTableFilterComposer,
          $$ExchangeRatesTableOrderingComposer,
          $$ExchangeRatesTableAnnotationComposer,
          $$ExchangeRatesTableCreateCompanionBuilder,
          $$ExchangeRatesTableUpdateCompanionBuilder,
          (
            ExchangeRate,
            BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRate>,
          ),
          ExchangeRate,
          PrefetchHooks Function()
        > {
  $$ExchangeRatesTableTableManager(_$AppDatabase db, $ExchangeRatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> currencyPair = const Value.absent(),
                Value<double> rate = const Value.absent(),
                Value<String> recordedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => ExchangeRatesCompanion(
                id: id,
                currencyPair: currencyPair,
                rate: rate,
                recordedAt: recordedAt,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String currencyPair,
                required double rate,
                required String recordedAt,
                Value<String> source = const Value.absent(),
              }) => ExchangeRatesCompanion.insert(
                id: id,
                currencyPair: currencyPair,
                rate: rate,
                recordedAt: recordedAt,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExchangeRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExchangeRatesTable,
      ExchangeRate,
      $$ExchangeRatesTableFilterComposer,
      $$ExchangeRatesTableOrderingComposer,
      $$ExchangeRatesTableAnnotationComposer,
      $$ExchangeRatesTableCreateCompanionBuilder,
      $$ExchangeRatesTableUpdateCompanionBuilder,
      (
        ExchangeRate,
        BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRate>,
      ),
      ExchangeRate,
      PrefetchHooks Function()
    >;
typedef $$PortfolioDailyReturnsTableCreateCompanionBuilder =
    PortfolioDailyReturnsCompanion Function({
      Value<int> id,
      required String localUserId,
      required String returnDate,
      Value<double?> beginningValueKrw,
      required double endingValueKrw,
      required double portfolioValueKrw,
      Value<double> externalCashFlowKrw,
      Value<double?> dailyReturn,
      Value<String> dataQuality,
      Value<int> calculationVersion,
      required String createdAt,
      required String updatedAt,
    });
typedef $$PortfolioDailyReturnsTableUpdateCompanionBuilder =
    PortfolioDailyReturnsCompanion Function({
      Value<int> id,
      Value<String> localUserId,
      Value<String> returnDate,
      Value<double?> beginningValueKrw,
      Value<double> endingValueKrw,
      Value<double> portfolioValueKrw,
      Value<double> externalCashFlowKrw,
      Value<double?> dailyReturn,
      Value<String> dataQuality,
      Value<int> calculationVersion,
      Value<String> createdAt,
      Value<String> updatedAt,
    });

class $$PortfolioDailyReturnsTableFilterComposer
    extends Composer<_$AppDatabase, $PortfolioDailyReturnsTable> {
  $$PortfolioDailyReturnsTableFilterComposer({
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

  ColumnFilters<String> get localUserId => $composableBuilder(
    column: $table.localUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get returnDate => $composableBuilder(
    column: $table.returnDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get beginningValueKrw => $composableBuilder(
    column: $table.beginningValueKrw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get endingValueKrw => $composableBuilder(
    column: $table.endingValueKrw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get portfolioValueKrw => $composableBuilder(
    column: $table.portfolioValueKrw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get externalCashFlowKrw => $composableBuilder(
    column: $table.externalCashFlowKrw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get dailyReturn => $composableBuilder(
    column: $table.dailyReturn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataQuality => $composableBuilder(
    column: $table.dataQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get calculationVersion => $composableBuilder(
    column: $table.calculationVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PortfolioDailyReturnsTableOrderingComposer
    extends Composer<_$AppDatabase, $PortfolioDailyReturnsTable> {
  $$PortfolioDailyReturnsTableOrderingComposer({
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

  ColumnOrderings<String> get localUserId => $composableBuilder(
    column: $table.localUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get returnDate => $composableBuilder(
    column: $table.returnDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get beginningValueKrw => $composableBuilder(
    column: $table.beginningValueKrw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get endingValueKrw => $composableBuilder(
    column: $table.endingValueKrw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get portfolioValueKrw => $composableBuilder(
    column: $table.portfolioValueKrw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get externalCashFlowKrw => $composableBuilder(
    column: $table.externalCashFlowKrw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get dailyReturn => $composableBuilder(
    column: $table.dailyReturn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataQuality => $composableBuilder(
    column: $table.dataQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get calculationVersion => $composableBuilder(
    column: $table.calculationVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PortfolioDailyReturnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PortfolioDailyReturnsTable> {
  $$PortfolioDailyReturnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localUserId => $composableBuilder(
    column: $table.localUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get returnDate => $composableBuilder(
    column: $table.returnDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get beginningValueKrw => $composableBuilder(
    column: $table.beginningValueKrw,
    builder: (column) => column,
  );

  GeneratedColumn<double> get endingValueKrw => $composableBuilder(
    column: $table.endingValueKrw,
    builder: (column) => column,
  );

  GeneratedColumn<double> get portfolioValueKrw => $composableBuilder(
    column: $table.portfolioValueKrw,
    builder: (column) => column,
  );

  GeneratedColumn<double> get externalCashFlowKrw => $composableBuilder(
    column: $table.externalCashFlowKrw,
    builder: (column) => column,
  );

  GeneratedColumn<double> get dailyReturn => $composableBuilder(
    column: $table.dailyReturn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataQuality => $composableBuilder(
    column: $table.dataQuality,
    builder: (column) => column,
  );

  GeneratedColumn<int> get calculationVersion => $composableBuilder(
    column: $table.calculationVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PortfolioDailyReturnsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PortfolioDailyReturnsTable,
          PortfolioDailyReturn,
          $$PortfolioDailyReturnsTableFilterComposer,
          $$PortfolioDailyReturnsTableOrderingComposer,
          $$PortfolioDailyReturnsTableAnnotationComposer,
          $$PortfolioDailyReturnsTableCreateCompanionBuilder,
          $$PortfolioDailyReturnsTableUpdateCompanionBuilder,
          (
            PortfolioDailyReturn,
            BaseReferences<
              _$AppDatabase,
              $PortfolioDailyReturnsTable,
              PortfolioDailyReturn
            >,
          ),
          PortfolioDailyReturn,
          PrefetchHooks Function()
        > {
  $$PortfolioDailyReturnsTableTableManager(
    _$AppDatabase db,
    $PortfolioDailyReturnsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PortfolioDailyReturnsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PortfolioDailyReturnsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PortfolioDailyReturnsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localUserId = const Value.absent(),
                Value<String> returnDate = const Value.absent(),
                Value<double?> beginningValueKrw = const Value.absent(),
                Value<double> endingValueKrw = const Value.absent(),
                Value<double> portfolioValueKrw = const Value.absent(),
                Value<double> externalCashFlowKrw = const Value.absent(),
                Value<double?> dailyReturn = const Value.absent(),
                Value<String> dataQuality = const Value.absent(),
                Value<int> calculationVersion = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => PortfolioDailyReturnsCompanion(
                id: id,
                localUserId: localUserId,
                returnDate: returnDate,
                beginningValueKrw: beginningValueKrw,
                endingValueKrw: endingValueKrw,
                portfolioValueKrw: portfolioValueKrw,
                externalCashFlowKrw: externalCashFlowKrw,
                dailyReturn: dailyReturn,
                dataQuality: dataQuality,
                calculationVersion: calculationVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localUserId,
                required String returnDate,
                Value<double?> beginningValueKrw = const Value.absent(),
                required double endingValueKrw,
                required double portfolioValueKrw,
                Value<double> externalCashFlowKrw = const Value.absent(),
                Value<double?> dailyReturn = const Value.absent(),
                Value<String> dataQuality = const Value.absent(),
                Value<int> calculationVersion = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => PortfolioDailyReturnsCompanion.insert(
                id: id,
                localUserId: localUserId,
                returnDate: returnDate,
                beginningValueKrw: beginningValueKrw,
                endingValueKrw: endingValueKrw,
                portfolioValueKrw: portfolioValueKrw,
                externalCashFlowKrw: externalCashFlowKrw,
                dailyReturn: dailyReturn,
                dataQuality: dataQuality,
                calculationVersion: calculationVersion,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PortfolioDailyReturnsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PortfolioDailyReturnsTable,
      PortfolioDailyReturn,
      $$PortfolioDailyReturnsTableFilterComposer,
      $$PortfolioDailyReturnsTableOrderingComposer,
      $$PortfolioDailyReturnsTableAnnotationComposer,
      $$PortfolioDailyReturnsTableCreateCompanionBuilder,
      $$PortfolioDailyReturnsTableUpdateCompanionBuilder,
      (
        PortfolioDailyReturn,
        BaseReferences<
          _$AppDatabase,
          $PortfolioDailyReturnsTable,
          PortfolioDailyReturn
        >,
      ),
      PortfolioDailyReturn,
      PrefetchHooks Function()
    >;
typedef $$BenchmarkPricesTableCreateCompanionBuilder =
    BenchmarkPricesCompanion Function({
      Value<int> id,
      required String benchmarkCode,
      required String priceDate,
      required double closePrice,
      Value<double?> adjustedClosePrice,
      Value<String> currencyCode,
      Value<double?> fxRateToKrw,
      Value<String?> source,
      required String createdAt,
      required String updatedAt,
    });
typedef $$BenchmarkPricesTableUpdateCompanionBuilder =
    BenchmarkPricesCompanion Function({
      Value<int> id,
      Value<String> benchmarkCode,
      Value<String> priceDate,
      Value<double> closePrice,
      Value<double?> adjustedClosePrice,
      Value<String> currencyCode,
      Value<double?> fxRateToKrw,
      Value<String?> source,
      Value<String> createdAt,
      Value<String> updatedAt,
    });

class $$BenchmarkPricesTableFilterComposer
    extends Composer<_$AppDatabase, $BenchmarkPricesTable> {
  $$BenchmarkPricesTableFilterComposer({
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

  ColumnFilters<String> get benchmarkCode => $composableBuilder(
    column: $table.benchmarkCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priceDate => $composableBuilder(
    column: $table.priceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get closePrice => $composableBuilder(
    column: $table.closePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get adjustedClosePrice => $composableBuilder(
    column: $table.adjustedClosePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fxRateToKrw => $composableBuilder(
    column: $table.fxRateToKrw,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BenchmarkPricesTableOrderingComposer
    extends Composer<_$AppDatabase, $BenchmarkPricesTable> {
  $$BenchmarkPricesTableOrderingComposer({
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

  ColumnOrderings<String> get benchmarkCode => $composableBuilder(
    column: $table.benchmarkCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priceDate => $composableBuilder(
    column: $table.priceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get closePrice => $composableBuilder(
    column: $table.closePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get adjustedClosePrice => $composableBuilder(
    column: $table.adjustedClosePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fxRateToKrw => $composableBuilder(
    column: $table.fxRateToKrw,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BenchmarkPricesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BenchmarkPricesTable> {
  $$BenchmarkPricesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get benchmarkCode => $composableBuilder(
    column: $table.benchmarkCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get priceDate =>
      $composableBuilder(column: $table.priceDate, builder: (column) => column);

  GeneratedColumn<double> get closePrice => $composableBuilder(
    column: $table.closePrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get adjustedClosePrice => $composableBuilder(
    column: $table.adjustedClosePrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fxRateToKrw => $composableBuilder(
    column: $table.fxRateToKrw,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BenchmarkPricesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BenchmarkPricesTable,
          BenchmarkPrice,
          $$BenchmarkPricesTableFilterComposer,
          $$BenchmarkPricesTableOrderingComposer,
          $$BenchmarkPricesTableAnnotationComposer,
          $$BenchmarkPricesTableCreateCompanionBuilder,
          $$BenchmarkPricesTableUpdateCompanionBuilder,
          (
            BenchmarkPrice,
            BaseReferences<
              _$AppDatabase,
              $BenchmarkPricesTable,
              BenchmarkPrice
            >,
          ),
          BenchmarkPrice,
          PrefetchHooks Function()
        > {
  $$BenchmarkPricesTableTableManager(
    _$AppDatabase db,
    $BenchmarkPricesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BenchmarkPricesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BenchmarkPricesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BenchmarkPricesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> benchmarkCode = const Value.absent(),
                Value<String> priceDate = const Value.absent(),
                Value<double> closePrice = const Value.absent(),
                Value<double?> adjustedClosePrice = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<double?> fxRateToKrw = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
              }) => BenchmarkPricesCompanion(
                id: id,
                benchmarkCode: benchmarkCode,
                priceDate: priceDate,
                closePrice: closePrice,
                adjustedClosePrice: adjustedClosePrice,
                currencyCode: currencyCode,
                fxRateToKrw: fxRateToKrw,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String benchmarkCode,
                required String priceDate,
                required double closePrice,
                Value<double?> adjustedClosePrice = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<double?> fxRateToKrw = const Value.absent(),
                Value<String?> source = const Value.absent(),
                required String createdAt,
                required String updatedAt,
              }) => BenchmarkPricesCompanion.insert(
                id: id,
                benchmarkCode: benchmarkCode,
                priceDate: priceDate,
                closePrice: closePrice,
                adjustedClosePrice: adjustedClosePrice,
                currencyCode: currencyCode,
                fxRateToKrw: fxRateToKrw,
                source: source,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BenchmarkPricesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BenchmarkPricesTable,
      BenchmarkPrice,
      $$BenchmarkPricesTableFilterComposer,
      $$BenchmarkPricesTableOrderingComposer,
      $$BenchmarkPricesTableAnnotationComposer,
      $$BenchmarkPricesTableCreateCompanionBuilder,
      $$BenchmarkPricesTableUpdateCompanionBuilder,
      (
        BenchmarkPrice,
        BaseReferences<_$AppDatabase, $BenchmarkPricesTable, BenchmarkPrice>,
      ),
      BenchmarkPrice,
      PrefetchHooks Function()
    >;
typedef $$DailyInvestmentReviewsTableCreateCompanionBuilder =
    DailyInvestmentReviewsCompanion Function({
      Value<int> id,
      required String reviewDate,
      required String status,
      required String mode,
      Value<String> performanceNote,
      Value<String> tradeReviewNote,
      Value<String> selectedDecisionTags,
      Value<String> selectedNoTradeReasons,
      Value<String> selectedEmotions,
      Value<String> principleCheck,
      Value<String> riskNote,
      Value<String> insightGood,
      Value<String> insightWeak,
      Value<String> insightRepeatOrAvoid,
      Value<String> nextPlan,
      required String createdAt,
      required String updatedAt,
      Value<String?> completedAt,
    });
typedef $$DailyInvestmentReviewsTableUpdateCompanionBuilder =
    DailyInvestmentReviewsCompanion Function({
      Value<int> id,
      Value<String> reviewDate,
      Value<String> status,
      Value<String> mode,
      Value<String> performanceNote,
      Value<String> tradeReviewNote,
      Value<String> selectedDecisionTags,
      Value<String> selectedNoTradeReasons,
      Value<String> selectedEmotions,
      Value<String> principleCheck,
      Value<String> riskNote,
      Value<String> insightGood,
      Value<String> insightWeak,
      Value<String> insightRepeatOrAvoid,
      Value<String> nextPlan,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String?> completedAt,
    });

class $$DailyInvestmentReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyInvestmentReviewsTable> {
  $$DailyInvestmentReviewsTableFilterComposer({
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

  ColumnFilters<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get performanceNote => $composableBuilder(
    column: $table.performanceNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tradeReviewNote => $composableBuilder(
    column: $table.tradeReviewNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedDecisionTags => $composableBuilder(
    column: $table.selectedDecisionTags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedNoTradeReasons => $composableBuilder(
    column: $table.selectedNoTradeReasons,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedEmotions => $composableBuilder(
    column: $table.selectedEmotions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get principleCheck => $composableBuilder(
    column: $table.principleCheck,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get riskNote => $composableBuilder(
    column: $table.riskNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get insightGood => $composableBuilder(
    column: $table.insightGood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get insightWeak => $composableBuilder(
    column: $table.insightWeak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get insightRepeatOrAvoid => $composableBuilder(
    column: $table.insightRepeatOrAvoid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextPlan => $composableBuilder(
    column: $table.nextPlan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyInvestmentReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyInvestmentReviewsTable> {
  $$DailyInvestmentReviewsTableOrderingComposer({
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

  ColumnOrderings<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get performanceNote => $composableBuilder(
    column: $table.performanceNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tradeReviewNote => $composableBuilder(
    column: $table.tradeReviewNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedDecisionTags => $composableBuilder(
    column: $table.selectedDecisionTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedNoTradeReasons => $composableBuilder(
    column: $table.selectedNoTradeReasons,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedEmotions => $composableBuilder(
    column: $table.selectedEmotions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get principleCheck => $composableBuilder(
    column: $table.principleCheck,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get riskNote => $composableBuilder(
    column: $table.riskNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get insightGood => $composableBuilder(
    column: $table.insightGood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get insightWeak => $composableBuilder(
    column: $table.insightWeak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get insightRepeatOrAvoid => $composableBuilder(
    column: $table.insightRepeatOrAvoid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextPlan => $composableBuilder(
    column: $table.nextPlan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyInvestmentReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyInvestmentReviewsTable> {
  $$DailyInvestmentReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get performanceNote => $composableBuilder(
    column: $table.performanceNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tradeReviewNote => $composableBuilder(
    column: $table.tradeReviewNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedDecisionTags => $composableBuilder(
    column: $table.selectedDecisionTags,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedNoTradeReasons => $composableBuilder(
    column: $table.selectedNoTradeReasons,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedEmotions => $composableBuilder(
    column: $table.selectedEmotions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get principleCheck => $composableBuilder(
    column: $table.principleCheck,
    builder: (column) => column,
  );

  GeneratedColumn<String> get riskNote =>
      $composableBuilder(column: $table.riskNote, builder: (column) => column);

  GeneratedColumn<String> get insightGood => $composableBuilder(
    column: $table.insightGood,
    builder: (column) => column,
  );

  GeneratedColumn<String> get insightWeak => $composableBuilder(
    column: $table.insightWeak,
    builder: (column) => column,
  );

  GeneratedColumn<String> get insightRepeatOrAvoid => $composableBuilder(
    column: $table.insightRepeatOrAvoid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextPlan =>
      $composableBuilder(column: $table.nextPlan, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$DailyInvestmentReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyInvestmentReviewsTable,
          DailyInvestmentReview,
          $$DailyInvestmentReviewsTableFilterComposer,
          $$DailyInvestmentReviewsTableOrderingComposer,
          $$DailyInvestmentReviewsTableAnnotationComposer,
          $$DailyInvestmentReviewsTableCreateCompanionBuilder,
          $$DailyInvestmentReviewsTableUpdateCompanionBuilder,
          (
            DailyInvestmentReview,
            BaseReferences<
              _$AppDatabase,
              $DailyInvestmentReviewsTable,
              DailyInvestmentReview
            >,
          ),
          DailyInvestmentReview,
          PrefetchHooks Function()
        > {
  $$DailyInvestmentReviewsTableTableManager(
    _$AppDatabase db,
    $DailyInvestmentReviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyInvestmentReviewsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DailyInvestmentReviewsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyInvestmentReviewsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> reviewDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> performanceNote = const Value.absent(),
                Value<String> tradeReviewNote = const Value.absent(),
                Value<String> selectedDecisionTags = const Value.absent(),
                Value<String> selectedNoTradeReasons = const Value.absent(),
                Value<String> selectedEmotions = const Value.absent(),
                Value<String> principleCheck = const Value.absent(),
                Value<String> riskNote = const Value.absent(),
                Value<String> insightGood = const Value.absent(),
                Value<String> insightWeak = const Value.absent(),
                Value<String> insightRepeatOrAvoid = const Value.absent(),
                Value<String> nextPlan = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
              }) => DailyInvestmentReviewsCompanion(
                id: id,
                reviewDate: reviewDate,
                status: status,
                mode: mode,
                performanceNote: performanceNote,
                tradeReviewNote: tradeReviewNote,
                selectedDecisionTags: selectedDecisionTags,
                selectedNoTradeReasons: selectedNoTradeReasons,
                selectedEmotions: selectedEmotions,
                principleCheck: principleCheck,
                riskNote: riskNote,
                insightGood: insightGood,
                insightWeak: insightWeak,
                insightRepeatOrAvoid: insightRepeatOrAvoid,
                nextPlan: nextPlan,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String reviewDate,
                required String status,
                required String mode,
                Value<String> performanceNote = const Value.absent(),
                Value<String> tradeReviewNote = const Value.absent(),
                Value<String> selectedDecisionTags = const Value.absent(),
                Value<String> selectedNoTradeReasons = const Value.absent(),
                Value<String> selectedEmotions = const Value.absent(),
                Value<String> principleCheck = const Value.absent(),
                Value<String> riskNote = const Value.absent(),
                Value<String> insightGood = const Value.absent(),
                Value<String> insightWeak = const Value.absent(),
                Value<String> insightRepeatOrAvoid = const Value.absent(),
                Value<String> nextPlan = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<String?> completedAt = const Value.absent(),
              }) => DailyInvestmentReviewsCompanion.insert(
                id: id,
                reviewDate: reviewDate,
                status: status,
                mode: mode,
                performanceNote: performanceNote,
                tradeReviewNote: tradeReviewNote,
                selectedDecisionTags: selectedDecisionTags,
                selectedNoTradeReasons: selectedNoTradeReasons,
                selectedEmotions: selectedEmotions,
                principleCheck: principleCheck,
                riskNote: riskNote,
                insightGood: insightGood,
                insightWeak: insightWeak,
                insightRepeatOrAvoid: insightRepeatOrAvoid,
                nextPlan: nextPlan,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyInvestmentReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyInvestmentReviewsTable,
      DailyInvestmentReview,
      $$DailyInvestmentReviewsTableFilterComposer,
      $$DailyInvestmentReviewsTableOrderingComposer,
      $$DailyInvestmentReviewsTableAnnotationComposer,
      $$DailyInvestmentReviewsTableCreateCompanionBuilder,
      $$DailyInvestmentReviewsTableUpdateCompanionBuilder,
      (
        DailyInvestmentReview,
        BaseReferences<
          _$AppDatabase,
          $DailyInvestmentReviewsTable,
          DailyInvestmentReview
        >,
      ),
      DailyInvestmentReview,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$HoldingsTableTableManager get holdings =>
      $$HoldingsTableTableManager(_db, _db.holdings);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$CashAccountsTableTableManager get cashAccounts =>
      $$CashAccountsTableTableManager(_db, _db.cashAccounts);
  $$CashTransactionsTableTableManager get cashTransactions =>
      $$CashTransactionsTableTableManager(_db, _db.cashTransactions);
  $$TransactionEventsTableTableManager get transactionEvents =>
      $$TransactionEventsTableTableManager(_db, _db.transactionEvents);
  $$TransactionLinesTableTableManager get transactionLines =>
      $$TransactionLinesTableTableManager(_db, _db.transactionLines);
  $$MarketNewsCachesTableTableManager get marketNewsCaches =>
      $$MarketNewsCachesTableTableManager(_db, _db.marketNewsCaches);
  $$CompanyNewsCachesTableTableManager get companyNewsCaches =>
      $$CompanyNewsCachesTableTableManager(_db, _db.companyNewsCaches);
  $$DailyPortfolioSnapshotsTableTableManager get dailyPortfolioSnapshots =>
      $$DailyPortfolioSnapshotsTableTableManager(
        _db,
        _db.dailyPortfolioSnapshots,
      );
  $$DailyPortfolioSnapshotItemsTableTableManager
  get dailyPortfolioSnapshotItems =>
      $$DailyPortfolioSnapshotItemsTableTableManager(
        _db,
        _db.dailyPortfolioSnapshotItems,
      );
  $$DailyPortfolioSnapshotHoldingItemsTableTableManager
  get dailyPortfolioSnapshotHoldingItems =>
      $$DailyPortfolioSnapshotHoldingItemsTableTableManager(
        _db,
        _db.dailyPortfolioSnapshotHoldingItems,
      );
  $$AssetAllocationTargetsTableTableManager get assetAllocationTargets =>
      $$AssetAllocationTargetsTableTableManager(
        _db,
        _db.assetAllocationTargets,
      );
  $$ExchangeRatesTableTableManager get exchangeRates =>
      $$ExchangeRatesTableTableManager(_db, _db.exchangeRates);
  $$PortfolioDailyReturnsTableTableManager get portfolioDailyReturns =>
      $$PortfolioDailyReturnsTableTableManager(_db, _db.portfolioDailyReturns);
  $$BenchmarkPricesTableTableManager get benchmarkPrices =>
      $$BenchmarkPricesTableTableManager(_db, _db.benchmarkPrices);
  $$DailyInvestmentReviewsTableTableManager get dailyInvestmentReviews =>
      $$DailyInvestmentReviewsTableTableManager(
        _db,
        _db.dailyInvestmentReviews,
      );
}
