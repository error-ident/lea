// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TrackingCategoriesTable extends TrackingCategories
    with TableInfo<$TrackingCategoriesTable, TrackingCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleKeyMeta =
      const VerificationMeta('titleKey');
  @override
  late final GeneratedColumn<String> titleKey = GeneratedColumn<String>(
      'title_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconRefMeta =
      const VerificationMeta('iconRef');
  @override
  late final GeneratedColumn<String> iconRef = GeneratedColumn<String>(
      'icon_ref', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<TrackingType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<TrackingType>($TrackingCategoriesTable.$convertertype);
  static const VerificationMeta _isBuiltInMeta =
      const VerificationMeta('isBuiltIn');
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
      'is_built_in', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_built_in" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isHiddenMeta =
      const VerificationMeta('isHidden');
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
      'is_hidden', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_hidden" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, code, titleKey, iconRef, type, isBuiltIn, isHidden, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_categories';
  @override
  VerificationContext validateIntegrity(Insertable<TrackingCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('title_key')) {
      context.handle(_titleKeyMeta,
          titleKey.isAcceptableOrUnknown(data['title_key']!, _titleKeyMeta));
    } else if (isInserting) {
      context.missing(_titleKeyMeta);
    }
    if (data.containsKey('icon_ref')) {
      context.handle(_iconRefMeta,
          iconRef.isAcceptableOrUnknown(data['icon_ref']!, _iconRefMeta));
    }
    context.handle(_typeMeta, const VerificationResult.success());
    if (data.containsKey('is_built_in')) {
      context.handle(
          _isBuiltInMeta,
          isBuiltIn.isAcceptableOrUnknown(
              data['is_built_in']!, _isBuiltInMeta));
    }
    if (data.containsKey('is_hidden')) {
      context.handle(_isHiddenMeta,
          isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackingCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      titleKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_key'])!,
      iconRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_ref'])!,
      type: $TrackingCategoriesTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      isBuiltIn: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_built_in'])!,
      isHidden: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_hidden'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $TrackingCategoriesTable createAlias(String alias) {
    return $TrackingCategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TrackingType, int, int> $convertertype =
      const EnumIndexConverter<TrackingType>(TrackingType.values);
}

class TrackingCategory extends DataClass
    implements Insertable<TrackingCategory> {
  final int id;

  /// Машинный код: mood, symptoms, discharge, sex, digestion, activity,
  /// contraception, pills, ovulation_test, other, weight, bbt, water.
  final String code;

  /// Ключ локализации названия.
  final String titleKey;

  /// Имя Rive/иконки.
  final String iconRef;
  final TrackingType type;
  final bool isBuiltIn;
  final bool isHidden;
  final int sortOrder;
  const TrackingCategory(
      {required this.id,
      required this.code,
      required this.titleKey,
      required this.iconRef,
      required this.type,
      required this.isBuiltIn,
      required this.isHidden,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['title_key'] = Variable<String>(titleKey);
    map['icon_ref'] = Variable<String>(iconRef);
    {
      map['type'] =
          Variable<int>($TrackingCategoriesTable.$convertertype.toSql(type));
    }
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['is_hidden'] = Variable<bool>(isHidden);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TrackingCategoriesCompanion toCompanion(bool nullToAbsent) {
    return TrackingCategoriesCompanion(
      id: Value(id),
      code: Value(code),
      titleKey: Value(titleKey),
      iconRef: Value(iconRef),
      type: Value(type),
      isBuiltIn: Value(isBuiltIn),
      isHidden: Value(isHidden),
      sortOrder: Value(sortOrder),
    );
  }

  factory TrackingCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingCategory(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      titleKey: serializer.fromJson<String>(json['titleKey']),
      iconRef: serializer.fromJson<String>(json['iconRef']),
      type: $TrackingCategoriesTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'titleKey': serializer.toJson<String>(titleKey),
      'iconRef': serializer.toJson<String>(iconRef),
      'type': serializer
          .toJson<int>($TrackingCategoriesTable.$convertertype.toJson(type)),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'isHidden': serializer.toJson<bool>(isHidden),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TrackingCategory copyWith(
          {int? id,
          String? code,
          String? titleKey,
          String? iconRef,
          TrackingType? type,
          bool? isBuiltIn,
          bool? isHidden,
          int? sortOrder}) =>
      TrackingCategory(
        id: id ?? this.id,
        code: code ?? this.code,
        titleKey: titleKey ?? this.titleKey,
        iconRef: iconRef ?? this.iconRef,
        type: type ?? this.type,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        isHidden: isHidden ?? this.isHidden,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  TrackingCategory copyWithCompanion(TrackingCategoriesCompanion data) {
    return TrackingCategory(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      titleKey: data.titleKey.present ? data.titleKey.value : this.titleKey,
      iconRef: data.iconRef.present ? data.iconRef.value : this.iconRef,
      type: data.type.present ? data.type.value : this.type,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingCategory(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('titleKey: $titleKey, ')
          ..write('iconRef: $iconRef, ')
          ..write('type: $type, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isHidden: $isHidden, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, code, titleKey, iconRef, type, isBuiltIn, isHidden, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingCategory &&
          other.id == this.id &&
          other.code == this.code &&
          other.titleKey == this.titleKey &&
          other.iconRef == this.iconRef &&
          other.type == this.type &&
          other.isBuiltIn == this.isBuiltIn &&
          other.isHidden == this.isHidden &&
          other.sortOrder == this.sortOrder);
}

class TrackingCategoriesCompanion extends UpdateCompanion<TrackingCategory> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> titleKey;
  final Value<String> iconRef;
  final Value<TrackingType> type;
  final Value<bool> isBuiltIn;
  final Value<bool> isHidden;
  final Value<int> sortOrder;
  const TrackingCategoriesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.titleKey = const Value.absent(),
    this.iconRef = const Value.absent(),
    this.type = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  TrackingCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String titleKey,
    this.iconRef = const Value.absent(),
    required TrackingType type,
    this.isBuiltIn = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.sortOrder = const Value.absent(),
  })  : code = Value(code),
        titleKey = Value(titleKey),
        type = Value(type);
  static Insertable<TrackingCategory> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? titleKey,
    Expression<String>? iconRef,
    Expression<int>? type,
    Expression<bool>? isBuiltIn,
    Expression<bool>? isHidden,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (titleKey != null) 'title_key': titleKey,
      if (iconRef != null) 'icon_ref': iconRef,
      if (type != null) 'type': type,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (isHidden != null) 'is_hidden': isHidden,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  TrackingCategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? code,
      Value<String>? titleKey,
      Value<String>? iconRef,
      Value<TrackingType>? type,
      Value<bool>? isBuiltIn,
      Value<bool>? isHidden,
      Value<int>? sortOrder}) {
    return TrackingCategoriesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      titleKey: titleKey ?? this.titleKey,
      iconRef: iconRef ?? this.iconRef,
      type: type ?? this.type,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isHidden: isHidden ?? this.isHidden,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (titleKey.present) {
      map['title_key'] = Variable<String>(titleKey.value);
    }
    if (iconRef.present) {
      map['icon_ref'] = Variable<String>(iconRef.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
          $TrackingCategoriesTable.$convertertype.toSql(type.value));
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('titleKey: $titleKey, ')
          ..write('iconRef: $iconRef, ')
          ..write('type: $type, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isHidden: $isHidden, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $TrackingOptionsTable extends TrackingOptions
    with TableInfo<$TrackingOptionsTable, TrackingOption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackingOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tracking_categories (id)'));
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleKeyMeta =
      const VerificationMeta('titleKey');
  @override
  late final GeneratedColumn<String> titleKey = GeneratedColumn<String>(
      'title_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconRefMeta =
      const VerificationMeta('iconRef');
  @override
  late final GeneratedColumn<String> iconRef = GeneratedColumn<String>(
      'icon_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isBuiltInMeta =
      const VerificationMeta('isBuiltIn');
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
      'is_built_in', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_built_in" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isHiddenMeta =
      const VerificationMeta('isHidden');
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
      'is_hidden', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_hidden" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        categoryId,
        code,
        titleKey,
        iconRef,
        colorHex,
        isBuiltIn,
        isHidden,
        sortOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracking_options';
  @override
  VerificationContext validateIntegrity(Insertable<TrackingOption> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('title_key')) {
      context.handle(_titleKeyMeta,
          titleKey.isAcceptableOrUnknown(data['title_key']!, _titleKeyMeta));
    } else if (isInserting) {
      context.missing(_titleKeyMeta);
    }
    if (data.containsKey('icon_ref')) {
      context.handle(_iconRefMeta,
          iconRef.isAcceptableOrUnknown(data['icon_ref']!, _iconRefMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
          _isBuiltInMeta,
          isBuiltIn.isAcceptableOrUnknown(
              data['is_built_in']!, _isBuiltInMeta));
    }
    if (data.containsKey('is_hidden')) {
      context.handle(_isHiddenMeta,
          isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackingOption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackingOption(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      titleKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title_key'])!,
      iconRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_ref']),
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex']),
      isBuiltIn: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_built_in'])!,
      isHidden: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_hidden'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $TrackingOptionsTable createAlias(String alias) {
    return $TrackingOptionsTable(attachedDatabase, alias);
  }
}

class TrackingOption extends DataClass implements Insertable<TrackingOption> {
  final int id;
  final int categoryId;
  final String code;
  final String titleKey;
  final String? iconRef;
  final String? colorHex;
  final bool isBuiltIn;
  final bool isHidden;
  final int sortOrder;
  const TrackingOption(
      {required this.id,
      required this.categoryId,
      required this.code,
      required this.titleKey,
      this.iconRef,
      this.colorHex,
      required this.isBuiltIn,
      required this.isHidden,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['code'] = Variable<String>(code);
    map['title_key'] = Variable<String>(titleKey);
    if (!nullToAbsent || iconRef != null) {
      map['icon_ref'] = Variable<String>(iconRef);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['is_hidden'] = Variable<bool>(isHidden);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TrackingOptionsCompanion toCompanion(bool nullToAbsent) {
    return TrackingOptionsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      code: Value(code),
      titleKey: Value(titleKey),
      iconRef: iconRef == null && nullToAbsent
          ? const Value.absent()
          : Value(iconRef),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      isBuiltIn: Value(isBuiltIn),
      isHidden: Value(isHidden),
      sortOrder: Value(sortOrder),
    );
  }

  factory TrackingOption.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackingOption(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      code: serializer.fromJson<String>(json['code']),
      titleKey: serializer.fromJson<String>(json['titleKey']),
      iconRef: serializer.fromJson<String?>(json['iconRef']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'code': serializer.toJson<String>(code),
      'titleKey': serializer.toJson<String>(titleKey),
      'iconRef': serializer.toJson<String?>(iconRef),
      'colorHex': serializer.toJson<String?>(colorHex),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'isHidden': serializer.toJson<bool>(isHidden),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TrackingOption copyWith(
          {int? id,
          int? categoryId,
          String? code,
          String? titleKey,
          Value<String?> iconRef = const Value.absent(),
          Value<String?> colorHex = const Value.absent(),
          bool? isBuiltIn,
          bool? isHidden,
          int? sortOrder}) =>
      TrackingOption(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        code: code ?? this.code,
        titleKey: titleKey ?? this.titleKey,
        iconRef: iconRef.present ? iconRef.value : this.iconRef,
        colorHex: colorHex.present ? colorHex.value : this.colorHex,
        isBuiltIn: isBuiltIn ?? this.isBuiltIn,
        isHidden: isHidden ?? this.isHidden,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  TrackingOption copyWithCompanion(TrackingOptionsCompanion data) {
    return TrackingOption(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      code: data.code.present ? data.code.value : this.code,
      titleKey: data.titleKey.present ? data.titleKey.value : this.titleKey,
      iconRef: data.iconRef.present ? data.iconRef.value : this.iconRef,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackingOption(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('code: $code, ')
          ..write('titleKey: $titleKey, ')
          ..write('iconRef: $iconRef, ')
          ..write('colorHex: $colorHex, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isHidden: $isHidden, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, code, titleKey, iconRef,
      colorHex, isBuiltIn, isHidden, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackingOption &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.code == this.code &&
          other.titleKey == this.titleKey &&
          other.iconRef == this.iconRef &&
          other.colorHex == this.colorHex &&
          other.isBuiltIn == this.isBuiltIn &&
          other.isHidden == this.isHidden &&
          other.sortOrder == this.sortOrder);
}

class TrackingOptionsCompanion extends UpdateCompanion<TrackingOption> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<String> code;
  final Value<String> titleKey;
  final Value<String?> iconRef;
  final Value<String?> colorHex;
  final Value<bool> isBuiltIn;
  final Value<bool> isHidden;
  final Value<int> sortOrder;
  const TrackingOptionsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.code = const Value.absent(),
    this.titleKey = const Value.absent(),
    this.iconRef = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  TrackingOptionsCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required String code,
    required String titleKey,
    this.iconRef = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.sortOrder = const Value.absent(),
  })  : categoryId = Value(categoryId),
        code = Value(code),
        titleKey = Value(titleKey);
  static Insertable<TrackingOption> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<String>? code,
    Expression<String>? titleKey,
    Expression<String>? iconRef,
    Expression<String>? colorHex,
    Expression<bool>? isBuiltIn,
    Expression<bool>? isHidden,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (code != null) 'code': code,
      if (titleKey != null) 'title_key': titleKey,
      if (iconRef != null) 'icon_ref': iconRef,
      if (colorHex != null) 'color_hex': colorHex,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (isHidden != null) 'is_hidden': isHidden,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  TrackingOptionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? categoryId,
      Value<String>? code,
      Value<String>? titleKey,
      Value<String?>? iconRef,
      Value<String?>? colorHex,
      Value<bool>? isBuiltIn,
      Value<bool>? isHidden,
      Value<int>? sortOrder}) {
    return TrackingOptionsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      code: code ?? this.code,
      titleKey: titleKey ?? this.titleKey,
      iconRef: iconRef ?? this.iconRef,
      colorHex: colorHex ?? this.colorHex,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isHidden: isHidden ?? this.isHidden,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (titleKey.present) {
      map['title_key'] = Variable<String>(titleKey.value);
    }
    if (iconRef.present) {
      map['icon_ref'] = Variable<String>(iconRef.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackingOptionsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('code: $code, ')
          ..write('titleKey: $titleKey, ')
          ..write('iconRef: $iconRef, ')
          ..write('colorHex: $colorHex, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isHidden: $isHidden, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $PeriodDaysTable extends PeriodDays
    with TableInfo<$PeriodDaysTable, PeriodDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _flowOptionIdMeta =
      const VerificationMeta('flowOptionId');
  @override
  late final GeneratedColumn<int> flowOptionId = GeneratedColumn<int>(
      'flow_option_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tracking_options (id)'));
  static const VerificationMeta _isCycleStartMeta =
      const VerificationMeta('isCycleStart');
  @override
  late final GeneratedColumn<bool> isCycleStart = GeneratedColumn<bool>(
      'is_cycle_start', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_cycle_start" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, flowOptionId, isCycleStart, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'period_days';
  @override
  VerificationContext validateIntegrity(Insertable<PeriodDay> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('flow_option_id')) {
      context.handle(
          _flowOptionIdMeta,
          flowOptionId.isAcceptableOrUnknown(
              data['flow_option_id']!, _flowOptionIdMeta));
    }
    if (data.containsKey('is_cycle_start')) {
      context.handle(
          _isCycleStartMeta,
          isCycleStart.isAcceptableOrUnknown(
              data['is_cycle_start']!, _isCycleStartMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {date},
      ];
  @override
  PeriodDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodDay(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      flowOptionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}flow_option_id']),
      isCycleStart: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_cycle_start'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PeriodDaysTable createAlias(String alias) {
    return $PeriodDaysTable(attachedDatabase, alias);
  }
}

class PeriodDay extends DataClass implements Insertable<PeriodDay> {
  final int id;

  /// День (хранится как дата без времени).
  final DateTime date;

  /// Обильность — ссылка на опцию справочника (discharge/flow), опционально.
  final int? flowOptionId;

  /// true = первый день цикла (опора расчёта).
  final bool isCycleStart;
  final DateTime createdAt;
  const PeriodDay(
      {required this.id,
      required this.date,
      this.flowOptionId,
      required this.isCycleStart,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || flowOptionId != null) {
      map['flow_option_id'] = Variable<int>(flowOptionId);
    }
    map['is_cycle_start'] = Variable<bool>(isCycleStart);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PeriodDaysCompanion toCompanion(bool nullToAbsent) {
    return PeriodDaysCompanion(
      id: Value(id),
      date: Value(date),
      flowOptionId: flowOptionId == null && nullToAbsent
          ? const Value.absent()
          : Value(flowOptionId),
      isCycleStart: Value(isCycleStart),
      createdAt: Value(createdAt),
    );
  }

  factory PeriodDay.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodDay(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      flowOptionId: serializer.fromJson<int?>(json['flowOptionId']),
      isCycleStart: serializer.fromJson<bool>(json['isCycleStart']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'flowOptionId': serializer.toJson<int?>(flowOptionId),
      'isCycleStart': serializer.toJson<bool>(isCycleStart),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PeriodDay copyWith(
          {int? id,
          DateTime? date,
          Value<int?> flowOptionId = const Value.absent(),
          bool? isCycleStart,
          DateTime? createdAt}) =>
      PeriodDay(
        id: id ?? this.id,
        date: date ?? this.date,
        flowOptionId:
            flowOptionId.present ? flowOptionId.value : this.flowOptionId,
        isCycleStart: isCycleStart ?? this.isCycleStart,
        createdAt: createdAt ?? this.createdAt,
      );
  PeriodDay copyWithCompanion(PeriodDaysCompanion data) {
    return PeriodDay(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      flowOptionId: data.flowOptionId.present
          ? data.flowOptionId.value
          : this.flowOptionId,
      isCycleStart: data.isCycleStart.present
          ? data.isCycleStart.value
          : this.isCycleStart,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodDay(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('flowOptionId: $flowOptionId, ')
          ..write('isCycleStart: $isCycleStart, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, flowOptionId, isCycleStart, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodDay &&
          other.id == this.id &&
          other.date == this.date &&
          other.flowOptionId == this.flowOptionId &&
          other.isCycleStart == this.isCycleStart &&
          other.createdAt == this.createdAt);
}

class PeriodDaysCompanion extends UpdateCompanion<PeriodDay> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int?> flowOptionId;
  final Value<bool> isCycleStart;
  final Value<DateTime> createdAt;
  const PeriodDaysCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.flowOptionId = const Value.absent(),
    this.isCycleStart = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PeriodDaysCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    this.flowOptionId = const Value.absent(),
    this.isCycleStart = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : date = Value(date);
  static Insertable<PeriodDay> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? flowOptionId,
    Expression<bool>? isCycleStart,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (flowOptionId != null) 'flow_option_id': flowOptionId,
      if (isCycleStart != null) 'is_cycle_start': isCycleStart,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PeriodDaysCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<int?>? flowOptionId,
      Value<bool>? isCycleStart,
      Value<DateTime>? createdAt}) {
    return PeriodDaysCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      flowOptionId: flowOptionId ?? this.flowOptionId,
      isCycleStart: isCycleStart ?? this.isCycleStart,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (flowOptionId.present) {
      map['flow_option_id'] = Variable<int>(flowOptionId.value);
    }
    if (isCycleStart.present) {
      map['is_cycle_start'] = Variable<bool>(isCycleStart.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodDaysCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('flowOptionId: $flowOptionId, ')
          ..write('isCycleStart: $isCycleStart, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DayLogsTable extends DayLogs with TableInfo<$DayLogsTable, DayLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _optionIdMeta =
      const VerificationMeta('optionId');
  @override
  late final GeneratedColumn<int> optionId = GeneratedColumn<int>(
      'option_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tracking_options (id)'));
  static const VerificationMeta _intensityMeta =
      const VerificationMeta('intensity');
  @override
  late final GeneratedColumn<int> intensity = GeneratedColumn<int>(
      'intensity', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, optionId, intensity, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_logs';
  @override
  VerificationContext validateIntegrity(Insertable<DayLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('option_id')) {
      context.handle(_optionIdMeta,
          optionId.isAcceptableOrUnknown(data['option_id']!, _optionIdMeta));
    } else if (isInserting) {
      context.missing(_optionIdMeta);
    }
    if (data.containsKey('intensity')) {
      context.handle(_intensityMeta,
          intensity.isAcceptableOrUnknown(data['intensity']!, _intensityMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {date, optionId},
      ];
  @override
  DayLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      optionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}option_id'])!,
      intensity: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}intensity']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $DayLogsTable createAlias(String alias) {
    return $DayLogsTable(attachedDatabase, alias);
  }
}

class DayLog extends DataClass implements Insertable<DayLog> {
  final int id;
  final DateTime date;
  final int optionId;

  /// Опциональная интенсивность (напр. сила симптома 1–3).
  final int? intensity;
  final DateTime createdAt;
  const DayLog(
      {required this.id,
      required this.date,
      required this.optionId,
      this.intensity,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['option_id'] = Variable<int>(optionId);
    if (!nullToAbsent || intensity != null) {
      map['intensity'] = Variable<int>(intensity);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DayLogsCompanion toCompanion(bool nullToAbsent) {
    return DayLogsCompanion(
      id: Value(id),
      date: Value(date),
      optionId: Value(optionId),
      intensity: intensity == null && nullToAbsent
          ? const Value.absent()
          : Value(intensity),
      createdAt: Value(createdAt),
    );
  }

  factory DayLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      optionId: serializer.fromJson<int>(json['optionId']),
      intensity: serializer.fromJson<int?>(json['intensity']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'optionId': serializer.toJson<int>(optionId),
      'intensity': serializer.toJson<int?>(intensity),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DayLog copyWith(
          {int? id,
          DateTime? date,
          int? optionId,
          Value<int?> intensity = const Value.absent(),
          DateTime? createdAt}) =>
      DayLog(
        id: id ?? this.id,
        date: date ?? this.date,
        optionId: optionId ?? this.optionId,
        intensity: intensity.present ? intensity.value : this.intensity,
        createdAt: createdAt ?? this.createdAt,
      );
  DayLog copyWithCompanion(DayLogsCompanion data) {
    return DayLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      optionId: data.optionId.present ? data.optionId.value : this.optionId,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('optionId: $optionId, ')
          ..write('intensity: $intensity, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, optionId, intensity, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.optionId == this.optionId &&
          other.intensity == this.intensity &&
          other.createdAt == this.createdAt);
}

class DayLogsCompanion extends UpdateCompanion<DayLog> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<int> optionId;
  final Value<int?> intensity;
  final Value<DateTime> createdAt;
  const DayLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.optionId = const Value.absent(),
    this.intensity = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DayLogsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required int optionId,
    this.intensity = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : date = Value(date),
        optionId = Value(optionId);
  static Insertable<DayLog> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<int>? optionId,
    Expression<int>? intensity,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (optionId != null) 'option_id': optionId,
      if (intensity != null) 'intensity': intensity,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DayLogsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<int>? optionId,
      Value<int?>? intensity,
      Value<DateTime>? createdAt}) {
    return DayLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      optionId: optionId ?? this.optionId,
      intensity: intensity ?? this.intensity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (optionId.present) {
      map['option_id'] = Variable<int>(optionId.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<int>(intensity.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('optionId: $optionId, ')
          ..write('intensity: $intensity, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DayNotesTable extends DayNotes with TableInfo<$DayNotesTable, DayNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, date, note, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_notes';
  @override
  VerificationContext validateIntegrity(Insertable<DayNote> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {date},
      ];
  @override
  DayNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayNote(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DayNotesTable createAlias(String alias) {
    return $DayNotesTable(attachedDatabase, alias);
  }
}

class DayNote extends DataClass implements Insertable<DayNote> {
  final int id;
  final DateTime date;
  final String note;
  final DateTime updatedAt;
  const DayNote(
      {required this.id,
      required this.date,
      required this.note,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['note'] = Variable<String>(note);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DayNotesCompanion toCompanion(bool nullToAbsent) {
    return DayNotesCompanion(
      id: Value(id),
      date: Value(date),
      note: Value(note),
      updatedAt: Value(updatedAt),
    );
  }

  factory DayNote.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayNote(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      note: serializer.fromJson<String>(json['note']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'note': serializer.toJson<String>(note),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DayNote copyWith(
          {int? id, DateTime? date, String? note, DateTime? updatedAt}) =>
      DayNote(
        id: id ?? this.id,
        date: date ?? this.date,
        note: note ?? this.note,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DayNote copyWithCompanion(DayNotesCompanion data) {
    return DayNote(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayNote(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, note, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayNote &&
          other.id == this.id &&
          other.date == this.date &&
          other.note == this.note &&
          other.updatedAt == this.updatedAt);
}

class DayNotesCompanion extends UpdateCompanion<DayNote> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> note;
  final Value<DateTime> updatedAt;
  const DayNotesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DayNotesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String note,
    this.updatedAt = const Value.absent(),
  })  : date = Value(date),
        note = Value(note);
  static Insertable<DayNote> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? note,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DayNotesCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<String>? note,
      Value<DateTime>? updatedAt}) {
    return DayNotesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayNotesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MeasurementsTable extends Measurements
    with TableInfo<$MeasurementsTable, Measurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _typeCodeMeta =
      const VerificationMeta('typeCode');
  @override
  late final GeneratedColumn<String> typeCode = GeneratedColumn<String>(
      'type_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, typeCode, value, unit, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'measurements';
  @override
  VerificationContext validateIntegrity(Insertable<Measurement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type_code')) {
      context.handle(_typeCodeMeta,
          typeCode.isAcceptableOrUnknown(data['type_code']!, _typeCodeMeta));
    } else if (isInserting) {
      context.missing(_typeCodeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Measurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Measurement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      typeCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type_code'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MeasurementsTable createAlias(String alias) {
    return $MeasurementsTable(attachedDatabase, alias);
  }
}

class Measurement extends DataClass implements Insertable<Measurement> {
  final int id;
  final DateTime date;

  /// Код категории numeric: weight / bbt / water.
  final String typeCode;
  final double value;
  final String unit;
  final DateTime createdAt;
  const Measurement(
      {required this.id,
      required this.date,
      required this.typeCode,
      required this.value,
      required this.unit,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['type_code'] = Variable<String>(typeCode);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MeasurementsCompanion toCompanion(bool nullToAbsent) {
    return MeasurementsCompanion(
      id: Value(id),
      date: Value(date),
      typeCode: Value(typeCode),
      value: Value(value),
      unit: Value(unit),
      createdAt: Value(createdAt),
    );
  }

  factory Measurement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Measurement(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      typeCode: serializer.fromJson<String>(json['typeCode']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'typeCode': serializer.toJson<String>(typeCode),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Measurement copyWith(
          {int? id,
          DateTime? date,
          String? typeCode,
          double? value,
          String? unit,
          DateTime? createdAt}) =>
      Measurement(
        id: id ?? this.id,
        date: date ?? this.date,
        typeCode: typeCode ?? this.typeCode,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        createdAt: createdAt ?? this.createdAt,
      );
  Measurement copyWithCompanion(MeasurementsCompanion data) {
    return Measurement(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      typeCode: data.typeCode.present ? data.typeCode.value : this.typeCode,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Measurement(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('typeCode: $typeCode, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, typeCode, value, unit, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Measurement &&
          other.id == this.id &&
          other.date == this.date &&
          other.typeCode == this.typeCode &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.createdAt == this.createdAt);
}

class MeasurementsCompanion extends UpdateCompanion<Measurement> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> typeCode;
  final Value<double> value;
  final Value<String> unit;
  final Value<DateTime> createdAt;
  const MeasurementsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.typeCode = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MeasurementsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String typeCode,
    required double value,
    required String unit,
    this.createdAt = const Value.absent(),
  })  : date = Value(date),
        typeCode = Value(typeCode),
        value = Value(value),
        unit = Value(unit);
  static Insertable<Measurement> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? typeCode,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (typeCode != null) 'type_code': typeCode,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MeasurementsCompanion copyWith(
      {Value<int>? id,
      Value<DateTime>? date,
      Value<String>? typeCode,
      Value<double>? value,
      Value<String>? unit,
      Value<DateTime>? createdAt}) {
    return MeasurementsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      typeCode: typeCode ?? this.typeCode,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (typeCode.present) {
      map['type_code'] = Variable<String>(typeCode.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('typeCode: $typeCode, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsKvTable extends SettingsKv
    with TableInfo<$SettingsKvTable, SettingsKvData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_kv';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsKvData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsKvData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsKvData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsKvTable createAlias(String alias) {
    return $SettingsKvTable(attachedDatabase, alias);
  }
}

class SettingsKvData extends DataClass implements Insertable<SettingsKvData> {
  final String key;
  final String value;
  const SettingsKvData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsKvCompanion toCompanion(bool nullToAbsent) {
    return SettingsKvCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingsKvData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsKvData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsKvData copyWith({String? key, String? value}) => SettingsKvData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingsKvData copyWithCompanion(SettingsKvCompanion data) {
    return SettingsKvData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsKvData &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsKvCompanion extends UpdateCompanion<SettingsKvData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsKvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsKvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingsKvData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsKvCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsKvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsKvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TrackingCategoriesTable trackingCategories =
      $TrackingCategoriesTable(this);
  late final $TrackingOptionsTable trackingOptions =
      $TrackingOptionsTable(this);
  late final $PeriodDaysTable periodDays = $PeriodDaysTable(this);
  late final $DayLogsTable dayLogs = $DayLogsTable(this);
  late final $DayNotesTable dayNotes = $DayNotesTable(this);
  late final $MeasurementsTable measurements = $MeasurementsTable(this);
  late final $SettingsKvTable settingsKv = $SettingsKvTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        trackingCategories,
        trackingOptions,
        periodDays,
        dayLogs,
        dayNotes,
        measurements,
        settingsKv
      ];
}

typedef $$TrackingCategoriesTableCreateCompanionBuilder
    = TrackingCategoriesCompanion Function({
  Value<int> id,
  required String code,
  required String titleKey,
  Value<String> iconRef,
  required TrackingType type,
  Value<bool> isBuiltIn,
  Value<bool> isHidden,
  Value<int> sortOrder,
});
typedef $$TrackingCategoriesTableUpdateCompanionBuilder
    = TrackingCategoriesCompanion Function({
  Value<int> id,
  Value<String> code,
  Value<String> titleKey,
  Value<String> iconRef,
  Value<TrackingType> type,
  Value<bool> isBuiltIn,
  Value<bool> isHidden,
  Value<int> sortOrder,
});

class $$TrackingCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrackingCategoriesTable,
    TrackingCategory,
    $$TrackingCategoriesTableFilterComposer,
    $$TrackingCategoriesTableOrderingComposer,
    $$TrackingCategoriesTableCreateCompanionBuilder,
    $$TrackingCategoriesTableUpdateCompanionBuilder> {
  $$TrackingCategoriesTableTableManager(
      _$AppDatabase db, $TrackingCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TrackingCategoriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$TrackingCategoriesTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> titleKey = const Value.absent(),
            Value<String> iconRef = const Value.absent(),
            Value<TrackingType> type = const Value.absent(),
            Value<bool> isBuiltIn = const Value.absent(),
            Value<bool> isHidden = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              TrackingCategoriesCompanion(
            id: id,
            code: code,
            titleKey: titleKey,
            iconRef: iconRef,
            type: type,
            isBuiltIn: isBuiltIn,
            isHidden: isHidden,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String code,
            required String titleKey,
            Value<String> iconRef = const Value.absent(),
            required TrackingType type,
            Value<bool> isBuiltIn = const Value.absent(),
            Value<bool> isHidden = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              TrackingCategoriesCompanion.insert(
            id: id,
            code: code,
            titleKey: titleKey,
            iconRef: iconRef,
            type: type,
            isBuiltIn: isBuiltIn,
            isHidden: isHidden,
            sortOrder: sortOrder,
          ),
        ));
}

class $$TrackingCategoriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TrackingCategoriesTable> {
  $$TrackingCategoriesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get code => $state.composableBuilder(
      column: $state.table.code,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get titleKey => $state.composableBuilder(
      column: $state.table.titleKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iconRef => $state.composableBuilder(
      column: $state.table.iconRef,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<TrackingType, TrackingType, int> get type =>
      $state.composableBuilder(
          column: $state.table.type,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<bool> get isBuiltIn => $state.composableBuilder(
      column: $state.table.isBuiltIn,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isHidden => $state.composableBuilder(
      column: $state.table.isHidden,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter trackingOptionsRefs(
      ComposableFilter Function($$TrackingOptionsTableFilterComposer f) f) {
    final $$TrackingOptionsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.trackingOptions,
            getReferencedColumn: (t) => t.categoryId,
            builder: (joinBuilder, parentComposers) =>
                $$TrackingOptionsTableFilterComposer(ComposerState($state.db,
                    $state.db.trackingOptions, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$TrackingCategoriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TrackingCategoriesTable> {
  $$TrackingCategoriesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get code => $state.composableBuilder(
      column: $state.table.code,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get titleKey => $state.composableBuilder(
      column: $state.table.titleKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iconRef => $state.composableBuilder(
      column: $state.table.iconRef,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isBuiltIn => $state.composableBuilder(
      column: $state.table.isBuiltIn,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isHidden => $state.composableBuilder(
      column: $state.table.isHidden,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$TrackingOptionsTableCreateCompanionBuilder = TrackingOptionsCompanion
    Function({
  Value<int> id,
  required int categoryId,
  required String code,
  required String titleKey,
  Value<String?> iconRef,
  Value<String?> colorHex,
  Value<bool> isBuiltIn,
  Value<bool> isHidden,
  Value<int> sortOrder,
});
typedef $$TrackingOptionsTableUpdateCompanionBuilder = TrackingOptionsCompanion
    Function({
  Value<int> id,
  Value<int> categoryId,
  Value<String> code,
  Value<String> titleKey,
  Value<String?> iconRef,
  Value<String?> colorHex,
  Value<bool> isBuiltIn,
  Value<bool> isHidden,
  Value<int> sortOrder,
});

class $$TrackingOptionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TrackingOptionsTable,
    TrackingOption,
    $$TrackingOptionsTableFilterComposer,
    $$TrackingOptionsTableOrderingComposer,
    $$TrackingOptionsTableCreateCompanionBuilder,
    $$TrackingOptionsTableUpdateCompanionBuilder> {
  $$TrackingOptionsTableTableManager(
      _$AppDatabase db, $TrackingOptionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TrackingOptionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TrackingOptionsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> titleKey = const Value.absent(),
            Value<String?> iconRef = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<bool> isBuiltIn = const Value.absent(),
            Value<bool> isHidden = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              TrackingOptionsCompanion(
            id: id,
            categoryId: categoryId,
            code: code,
            titleKey: titleKey,
            iconRef: iconRef,
            colorHex: colorHex,
            isBuiltIn: isBuiltIn,
            isHidden: isHidden,
            sortOrder: sortOrder,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int categoryId,
            required String code,
            required String titleKey,
            Value<String?> iconRef = const Value.absent(),
            Value<String?> colorHex = const Value.absent(),
            Value<bool> isBuiltIn = const Value.absent(),
            Value<bool> isHidden = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
          }) =>
              TrackingOptionsCompanion.insert(
            id: id,
            categoryId: categoryId,
            code: code,
            titleKey: titleKey,
            iconRef: iconRef,
            colorHex: colorHex,
            isBuiltIn: isBuiltIn,
            isHidden: isHidden,
            sortOrder: sortOrder,
          ),
        ));
}

class $$TrackingOptionsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TrackingOptionsTable> {
  $$TrackingOptionsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get code => $state.composableBuilder(
      column: $state.table.code,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get titleKey => $state.composableBuilder(
      column: $state.table.titleKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iconRef => $state.composableBuilder(
      column: $state.table.iconRef,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isBuiltIn => $state.composableBuilder(
      column: $state.table.isBuiltIn,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isHidden => $state.composableBuilder(
      column: $state.table.isHidden,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$TrackingCategoriesTableFilterComposer get categoryId {
    final $$TrackingCategoriesTableFilterComposer composer = $state
        .composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $state.db.trackingCategories,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$TrackingCategoriesTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.trackingCategories,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }

  ComposableFilter periodDaysRefs(
      ComposableFilter Function($$PeriodDaysTableFilterComposer f) f) {
    final $$PeriodDaysTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.periodDays,
        getReferencedColumn: (t) => t.flowOptionId,
        builder: (joinBuilder, parentComposers) =>
            $$PeriodDaysTableFilterComposer(ComposerState($state.db,
                $state.db.periodDays, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter dayLogsRefs(
      ComposableFilter Function($$DayLogsTableFilterComposer f) f) {
    final $$DayLogsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.dayLogs,
        getReferencedColumn: (t) => t.optionId,
        builder: (joinBuilder, parentComposers) => $$DayLogsTableFilterComposer(
            ComposerState(
                $state.db, $state.db.dayLogs, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$TrackingOptionsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TrackingOptionsTable> {
  $$TrackingOptionsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get code => $state.composableBuilder(
      column: $state.table.code,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get titleKey => $state.composableBuilder(
      column: $state.table.titleKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iconRef => $state.composableBuilder(
      column: $state.table.iconRef,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get colorHex => $state.composableBuilder(
      column: $state.table.colorHex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isBuiltIn => $state.composableBuilder(
      column: $state.table.isBuiltIn,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isHidden => $state.composableBuilder(
      column: $state.table.isHidden,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$TrackingCategoriesTableOrderingComposer get categoryId {
    final $$TrackingCategoriesTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $state.db.trackingCategories,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$TrackingCategoriesTableOrderingComposer(ComposerState(
                    $state.db,
                    $state.db.trackingCategories,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }
}

typedef $$PeriodDaysTableCreateCompanionBuilder = PeriodDaysCompanion Function({
  Value<int> id,
  required DateTime date,
  Value<int?> flowOptionId,
  Value<bool> isCycleStart,
  Value<DateTime> createdAt,
});
typedef $$PeriodDaysTableUpdateCompanionBuilder = PeriodDaysCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<int?> flowOptionId,
  Value<bool> isCycleStart,
  Value<DateTime> createdAt,
});

class $$PeriodDaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeriodDaysTable,
    PeriodDay,
    $$PeriodDaysTableFilterComposer,
    $$PeriodDaysTableOrderingComposer,
    $$PeriodDaysTableCreateCompanionBuilder,
    $$PeriodDaysTableUpdateCompanionBuilder> {
  $$PeriodDaysTableTableManager(_$AppDatabase db, $PeriodDaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PeriodDaysTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PeriodDaysTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int?> flowOptionId = const Value.absent(),
            Value<bool> isCycleStart = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PeriodDaysCompanion(
            id: id,
            date: date,
            flowOptionId: flowOptionId,
            isCycleStart: isCycleStart,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            Value<int?> flowOptionId = const Value.absent(),
            Value<bool> isCycleStart = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PeriodDaysCompanion.insert(
            id: id,
            date: date,
            flowOptionId: flowOptionId,
            isCycleStart: isCycleStart,
            createdAt: createdAt,
          ),
        ));
}

class $$PeriodDaysTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PeriodDaysTable> {
  $$PeriodDaysTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isCycleStart => $state.composableBuilder(
      column: $state.table.isCycleStart,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$TrackingOptionsTableFilterComposer get flowOptionId {
    final $$TrackingOptionsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.flowOptionId,
            referencedTable: $state.db.trackingOptions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$TrackingOptionsTableFilterComposer(ComposerState($state.db,
                    $state.db.trackingOptions, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$PeriodDaysTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PeriodDaysTable> {
  $$PeriodDaysTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isCycleStart => $state.composableBuilder(
      column: $state.table.isCycleStart,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$TrackingOptionsTableOrderingComposer get flowOptionId {
    final $$TrackingOptionsTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.flowOptionId,
            referencedTable: $state.db.trackingOptions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$TrackingOptionsTableOrderingComposer(ComposerState($state.db,
                    $state.db.trackingOptions, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$DayLogsTableCreateCompanionBuilder = DayLogsCompanion Function({
  Value<int> id,
  required DateTime date,
  required int optionId,
  Value<int?> intensity,
  Value<DateTime> createdAt,
});
typedef $$DayLogsTableUpdateCompanionBuilder = DayLogsCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<int> optionId,
  Value<int?> intensity,
  Value<DateTime> createdAt,
});

class $$DayLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DayLogsTable,
    DayLog,
    $$DayLogsTableFilterComposer,
    $$DayLogsTableOrderingComposer,
    $$DayLogsTableCreateCompanionBuilder,
    $$DayLogsTableUpdateCompanionBuilder> {
  $$DayLogsTableTableManager(_$AppDatabase db, $DayLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DayLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DayLogsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<int> optionId = const Value.absent(),
            Value<int?> intensity = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DayLogsCompanion(
            id: id,
            date: date,
            optionId: optionId,
            intensity: intensity,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required int optionId,
            Value<int?> intensity = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              DayLogsCompanion.insert(
            id: id,
            date: date,
            optionId: optionId,
            intensity: intensity,
            createdAt: createdAt,
          ),
        ));
}

class $$DayLogsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DayLogsTable> {
  $$DayLogsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get intensity => $state.composableBuilder(
      column: $state.table.intensity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$TrackingOptionsTableFilterComposer get optionId {
    final $$TrackingOptionsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.optionId,
            referencedTable: $state.db.trackingOptions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$TrackingOptionsTableFilterComposer(ComposerState($state.db,
                    $state.db.trackingOptions, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$DayLogsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DayLogsTable> {
  $$DayLogsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get intensity => $state.composableBuilder(
      column: $state.table.intensity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$TrackingOptionsTableOrderingComposer get optionId {
    final $$TrackingOptionsTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.optionId,
            referencedTable: $state.db.trackingOptions,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$TrackingOptionsTableOrderingComposer(ComposerState($state.db,
                    $state.db.trackingOptions, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$DayNotesTableCreateCompanionBuilder = DayNotesCompanion Function({
  Value<int> id,
  required DateTime date,
  required String note,
  Value<DateTime> updatedAt,
});
typedef $$DayNotesTableUpdateCompanionBuilder = DayNotesCompanion Function({
  Value<int> id,
  Value<DateTime> date,
  Value<String> note,
  Value<DateTime> updatedAt,
});

class $$DayNotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DayNotesTable,
    DayNote,
    $$DayNotesTableFilterComposer,
    $$DayNotesTableOrderingComposer,
    $$DayNotesTableCreateCompanionBuilder,
    $$DayNotesTableUpdateCompanionBuilder> {
  $$DayNotesTableTableManager(_$AppDatabase db, $DayNotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DayNotesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DayNotesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DayNotesCompanion(
            id: id,
            date: date,
            note: note,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required String note,
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DayNotesCompanion.insert(
            id: id,
            date: date,
            note: note,
            updatedAt: updatedAt,
          ),
        ));
}

class $$DayNotesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$DayNotesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DayNotesTable> {
  $$DayNotesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$MeasurementsTableCreateCompanionBuilder = MeasurementsCompanion
    Function({
  Value<int> id,
  required DateTime date,
  required String typeCode,
  required double value,
  required String unit,
  Value<DateTime> createdAt,
});
typedef $$MeasurementsTableUpdateCompanionBuilder = MeasurementsCompanion
    Function({
  Value<int> id,
  Value<DateTime> date,
  Value<String> typeCode,
  Value<double> value,
  Value<String> unit,
  Value<DateTime> createdAt,
});

class $$MeasurementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MeasurementsTable,
    Measurement,
    $$MeasurementsTableFilterComposer,
    $$MeasurementsTableOrderingComposer,
    $$MeasurementsTableCreateCompanionBuilder,
    $$MeasurementsTableUpdateCompanionBuilder> {
  $$MeasurementsTableTableManager(_$AppDatabase db, $MeasurementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MeasurementsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MeasurementsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> typeCode = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MeasurementsCompanion(
            id: id,
            date: date,
            typeCode: typeCode,
            value: value,
            unit: unit,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required DateTime date,
            required String typeCode,
            required double value,
            required String unit,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MeasurementsCompanion.insert(
            id: id,
            date: date,
            typeCode: typeCode,
            value: value,
            unit: unit,
            createdAt: createdAt,
          ),
        ));
}

class $$MeasurementsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get typeCode => $state.composableBuilder(
      column: $state.table.typeCode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$MeasurementsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MeasurementsTable> {
  $$MeasurementsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get typeCode => $state.composableBuilder(
      column: $state.table.typeCode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SettingsKvTableCreateCompanionBuilder = SettingsKvCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsKvTableUpdateCompanionBuilder = SettingsKvCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsKvTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsKvTable,
    SettingsKvData,
    $$SettingsKvTableFilterComposer,
    $$SettingsKvTableOrderingComposer,
    $$SettingsKvTableCreateCompanionBuilder,
    $$SettingsKvTableUpdateCompanionBuilder> {
  $$SettingsKvTableTableManager(_$AppDatabase db, $SettingsKvTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SettingsKvTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SettingsKvTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsKvCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsKvCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
        ));
}

class $$SettingsKvTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableFilterComposer(super.$state);
  ColumnFilters<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SettingsKvTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SettingsKvTable> {
  $$SettingsKvTableOrderingComposer(super.$state);
  ColumnOrderings<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TrackingCategoriesTableTableManager get trackingCategories =>
      $$TrackingCategoriesTableTableManager(_db, _db.trackingCategories);
  $$TrackingOptionsTableTableManager get trackingOptions =>
      $$TrackingOptionsTableTableManager(_db, _db.trackingOptions);
  $$PeriodDaysTableTableManager get periodDays =>
      $$PeriodDaysTableTableManager(_db, _db.periodDays);
  $$DayLogsTableTableManager get dayLogs =>
      $$DayLogsTableTableManager(_db, _db.dayLogs);
  $$DayNotesTableTableManager get dayNotes =>
      $$DayNotesTableTableManager(_db, _db.dayNotes);
  $$MeasurementsTableTableManager get measurements =>
      $$MeasurementsTableTableManager(_db, _db.measurements);
  $$SettingsKvTableTableManager get settingsKv =>
      $$SettingsKvTableTableManager(_db, _db.settingsKv);
}
