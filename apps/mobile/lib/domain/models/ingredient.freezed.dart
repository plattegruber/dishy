// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ingredient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

IngredientLine _$IngredientLineFromJson(Map<String, dynamic> json) {
  return _IngredientLine.fromJson(json);
}

/// @nodoc
mixin _$IngredientLine {
  /// The original ingredient text as it appeared in the recipe.
  String get rawText => throw _privateConstructorUsedError;

  /// The structured parse result, if parsing succeeded.
  ParsedIngredient? get parsed => throw _privateConstructorUsedError;

  /// Serializes this IngredientLine to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of IngredientLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IngredientLineCopyWith<IngredientLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IngredientLineCopyWith<$Res> {
  factory $IngredientLineCopyWith(
    IngredientLine value,
    $Res Function(IngredientLine) then,
  ) = _$IngredientLineCopyWithImpl<$Res, IngredientLine>;
  @useResult
  $Res call({String rawText, ParsedIngredient? parsed});

  $ParsedIngredientCopyWith<$Res>? get parsed;
}

/// @nodoc
class _$IngredientLineCopyWithImpl<$Res, $Val extends IngredientLine>
    implements $IngredientLineCopyWith<$Res> {
  _$IngredientLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IngredientLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rawText = null, Object? parsed = freezed}) {
    return _then(
      _value.copyWith(
            rawText: null == rawText
                ? _value.rawText
                : rawText // ignore: cast_nullable_to_non_nullable
                      as String,
            parsed: freezed == parsed
                ? _value.parsed
                : parsed // ignore: cast_nullable_to_non_nullable
                      as ParsedIngredient?,
          )
          as $Val,
    );
  }

  /// Create a copy of IngredientLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ParsedIngredientCopyWith<$Res>? get parsed {
    if (_value.parsed == null) {
      return null;
    }

    return $ParsedIngredientCopyWith<$Res>(_value.parsed!, (value) {
      return _then(_value.copyWith(parsed: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$IngredientLineImplCopyWith<$Res>
    implements $IngredientLineCopyWith<$Res> {
  factory _$$IngredientLineImplCopyWith(
    _$IngredientLineImpl value,
    $Res Function(_$IngredientLineImpl) then,
  ) = __$$IngredientLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String rawText, ParsedIngredient? parsed});

  @override
  $ParsedIngredientCopyWith<$Res>? get parsed;
}

/// @nodoc
class __$$IngredientLineImplCopyWithImpl<$Res>
    extends _$IngredientLineCopyWithImpl<$Res, _$IngredientLineImpl>
    implements _$$IngredientLineImplCopyWith<$Res> {
  __$$IngredientLineImplCopyWithImpl(
    _$IngredientLineImpl _value,
    $Res Function(_$IngredientLineImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IngredientLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rawText = null, Object? parsed = freezed}) {
    return _then(
      _$IngredientLineImpl(
        rawText: null == rawText
            ? _value.rawText
            : rawText // ignore: cast_nullable_to_non_nullable
                  as String,
        parsed: freezed == parsed
            ? _value.parsed
            : parsed // ignore: cast_nullable_to_non_nullable
                  as ParsedIngredient?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IngredientLineImpl implements _IngredientLine {
  const _$IngredientLineImpl({required this.rawText, this.parsed});

  factory _$IngredientLineImpl.fromJson(Map<String, dynamic> json) =>
      _$$IngredientLineImplFromJson(json);

  /// The original ingredient text as it appeared in the recipe.
  @override
  final String rawText;

  /// The structured parse result, if parsing succeeded.
  @override
  final ParsedIngredient? parsed;

  @override
  String toString() {
    return 'IngredientLine(rawText: $rawText, parsed: $parsed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientLineImpl &&
            (identical(other.rawText, rawText) || other.rawText == rawText) &&
            (identical(other.parsed, parsed) || other.parsed == parsed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, rawText, parsed);

  /// Create a copy of IngredientLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IngredientLineImplCopyWith<_$IngredientLineImpl> get copyWith =>
      __$$IngredientLineImplCopyWithImpl<_$IngredientLineImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$IngredientLineImplToJson(this);
  }
}

abstract class _IngredientLine implements IngredientLine {
  const factory _IngredientLine({
    required final String rawText,
    final ParsedIngredient? parsed,
  }) = _$IngredientLineImpl;

  factory _IngredientLine.fromJson(Map<String, dynamic> json) =
      _$IngredientLineImpl.fromJson;

  /// The original ingredient text as it appeared in the recipe.
  @override
  String get rawText;

  /// The structured parse result, if parsing succeeded.
  @override
  ParsedIngredient? get parsed;

  /// Create a copy of IngredientLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IngredientLineImplCopyWith<_$IngredientLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ParsedIngredient _$ParsedIngredientFromJson(Map<String, dynamic> json) {
  return _ParsedIngredient.fromJson(json);
}

/// @nodoc
mixin _$ParsedIngredient {
  /// Numeric quantity (e.g., 2.0, 0.5).
  double? get quantity => throw _privateConstructorUsedError;

  /// Unit of measurement (e.g., "cup", "tbsp", "g").
  String? get unit => throw _privateConstructorUsedError;

  /// The ingredient name (e.g., "all-purpose flour", "salt").
  String get name => throw _privateConstructorUsedError;

  /// Preparation instructions (e.g., "diced", "sifted").
  String? get preparation => throw _privateConstructorUsedError;

  /// Serializes this ParsedIngredient to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ParsedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ParsedIngredientCopyWith<ParsedIngredient> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ParsedIngredientCopyWith<$Res> {
  factory $ParsedIngredientCopyWith(
    ParsedIngredient value,
    $Res Function(ParsedIngredient) then,
  ) = _$ParsedIngredientCopyWithImpl<$Res, ParsedIngredient>;
  @useResult
  $Res call({double? quantity, String? unit, String name, String? preparation});
}

/// @nodoc
class _$ParsedIngredientCopyWithImpl<$Res, $Val extends ParsedIngredient>
    implements $ParsedIngredientCopyWith<$Res> {
  _$ParsedIngredientCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ParsedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? name = null,
    Object? preparation = freezed,
  }) {
    return _then(
      _value.copyWith(
            quantity: freezed == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as double?,
            unit: freezed == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            preparation: freezed == preparation
                ? _value.preparation
                : preparation // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ParsedIngredientImplCopyWith<$Res>
    implements $ParsedIngredientCopyWith<$Res> {
  factory _$$ParsedIngredientImplCopyWith(
    _$ParsedIngredientImpl value,
    $Res Function(_$ParsedIngredientImpl) then,
  ) = __$$ParsedIngredientImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double? quantity, String? unit, String name, String? preparation});
}

/// @nodoc
class __$$ParsedIngredientImplCopyWithImpl<$Res>
    extends _$ParsedIngredientCopyWithImpl<$Res, _$ParsedIngredientImpl>
    implements _$$ParsedIngredientImplCopyWith<$Res> {
  __$$ParsedIngredientImplCopyWithImpl(
    _$ParsedIngredientImpl _value,
    $Res Function(_$ParsedIngredientImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ParsedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? name = null,
    Object? preparation = freezed,
  }) {
    return _then(
      _$ParsedIngredientImpl(
        quantity: freezed == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as double?,
        unit: freezed == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        preparation: freezed == preparation
            ? _value.preparation
            : preparation // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ParsedIngredientImpl implements _ParsedIngredient {
  const _$ParsedIngredientImpl({
    this.quantity,
    this.unit,
    required this.name,
    this.preparation,
  });

  factory _$ParsedIngredientImpl.fromJson(Map<String, dynamic> json) =>
      _$$ParsedIngredientImplFromJson(json);

  /// Numeric quantity (e.g., 2.0, 0.5).
  @override
  final double? quantity;

  /// Unit of measurement (e.g., "cup", "tbsp", "g").
  @override
  final String? unit;

  /// The ingredient name (e.g., "all-purpose flour", "salt").
  @override
  final String name;

  /// Preparation instructions (e.g., "diced", "sifted").
  @override
  final String? preparation;

  @override
  String toString() {
    return 'ParsedIngredient(quantity: $quantity, unit: $unit, name: $name, preparation: $preparation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ParsedIngredientImpl &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.preparation, preparation) ||
                other.preparation == preparation));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, quantity, unit, name, preparation);

  /// Create a copy of ParsedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ParsedIngredientImplCopyWith<_$ParsedIngredientImpl> get copyWith =>
      __$$ParsedIngredientImplCopyWithImpl<_$ParsedIngredientImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ParsedIngredientImplToJson(this);
  }
}

abstract class _ParsedIngredient implements ParsedIngredient {
  const factory _ParsedIngredient({
    final double? quantity,
    final String? unit,
    required final String name,
    final String? preparation,
  }) = _$ParsedIngredientImpl;

  factory _ParsedIngredient.fromJson(Map<String, dynamic> json) =
      _$ParsedIngredientImpl.fromJson;

  /// Numeric quantity (e.g., 2.0, 0.5).
  @override
  double? get quantity;

  /// Unit of measurement (e.g., "cup", "tbsp", "g").
  @override
  String? get unit;

  /// The ingredient name (e.g., "all-purpose flour", "salt").
  @override
  String get name;

  /// Preparation instructions (e.g., "diced", "sifted").
  @override
  String? get preparation;

  /// Create a copy of ParsedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ParsedIngredientImplCopyWith<_$ParsedIngredientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ResolvedIngredient _$ResolvedIngredientFromJson(Map<String, dynamic> json) {
  return _ResolvedIngredient.fromJson(json);
}

/// @nodoc
mixin _$ResolvedIngredient {
  /// The parsed ingredient data.
  ParsedIngredient get parsed => throw _privateConstructorUsedError;

  /// The resolution result from the food database lookup.
  IngredientResolution get resolution => throw _privateConstructorUsedError;

  /// Serializes this ResolvedIngredient to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ResolvedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResolvedIngredientCopyWith<ResolvedIngredient> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResolvedIngredientCopyWith<$Res> {
  factory $ResolvedIngredientCopyWith(
    ResolvedIngredient value,
    $Res Function(ResolvedIngredient) then,
  ) = _$ResolvedIngredientCopyWithImpl<$Res, ResolvedIngredient>;
  @useResult
  $Res call({ParsedIngredient parsed, IngredientResolution resolution});

  $ParsedIngredientCopyWith<$Res> get parsed;
  $IngredientResolutionCopyWith<$Res> get resolution;
}

/// @nodoc
class _$ResolvedIngredientCopyWithImpl<$Res, $Val extends ResolvedIngredient>
    implements $ResolvedIngredientCopyWith<$Res> {
  _$ResolvedIngredientCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ResolvedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? parsed = null, Object? resolution = null}) {
    return _then(
      _value.copyWith(
            parsed: null == parsed
                ? _value.parsed
                : parsed // ignore: cast_nullable_to_non_nullable
                      as ParsedIngredient,
            resolution: null == resolution
                ? _value.resolution
                : resolution // ignore: cast_nullable_to_non_nullable
                      as IngredientResolution,
          )
          as $Val,
    );
  }

  /// Create a copy of ResolvedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ParsedIngredientCopyWith<$Res> get parsed {
    return $ParsedIngredientCopyWith<$Res>(_value.parsed, (value) {
      return _then(_value.copyWith(parsed: value) as $Val);
    });
  }

  /// Create a copy of ResolvedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $IngredientResolutionCopyWith<$Res> get resolution {
    return $IngredientResolutionCopyWith<$Res>(_value.resolution, (value) {
      return _then(_value.copyWith(resolution: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ResolvedIngredientImplCopyWith<$Res>
    implements $ResolvedIngredientCopyWith<$Res> {
  factory _$$ResolvedIngredientImplCopyWith(
    _$ResolvedIngredientImpl value,
    $Res Function(_$ResolvedIngredientImpl) then,
  ) = __$$ResolvedIngredientImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ParsedIngredient parsed, IngredientResolution resolution});

  @override
  $ParsedIngredientCopyWith<$Res> get parsed;
  @override
  $IngredientResolutionCopyWith<$Res> get resolution;
}

/// @nodoc
class __$$ResolvedIngredientImplCopyWithImpl<$Res>
    extends _$ResolvedIngredientCopyWithImpl<$Res, _$ResolvedIngredientImpl>
    implements _$$ResolvedIngredientImplCopyWith<$Res> {
  __$$ResolvedIngredientImplCopyWithImpl(
    _$ResolvedIngredientImpl _value,
    $Res Function(_$ResolvedIngredientImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ResolvedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? parsed = null, Object? resolution = null}) {
    return _then(
      _$ResolvedIngredientImpl(
        parsed: null == parsed
            ? _value.parsed
            : parsed // ignore: cast_nullable_to_non_nullable
                  as ParsedIngredient,
        resolution: null == resolution
            ? _value.resolution
            : resolution // ignore: cast_nullable_to_non_nullable
                  as IngredientResolution,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ResolvedIngredientImpl implements _ResolvedIngredient {
  const _$ResolvedIngredientImpl({
    required this.parsed,
    required this.resolution,
  });

  factory _$ResolvedIngredientImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResolvedIngredientImplFromJson(json);

  /// The parsed ingredient data.
  @override
  final ParsedIngredient parsed;

  /// The resolution result from the food database lookup.
  @override
  final IngredientResolution resolution;

  @override
  String toString() {
    return 'ResolvedIngredient(parsed: $parsed, resolution: $resolution)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResolvedIngredientImpl &&
            (identical(other.parsed, parsed) || other.parsed == parsed) &&
            (identical(other.resolution, resolution) ||
                other.resolution == resolution));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, parsed, resolution);

  /// Create a copy of ResolvedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResolvedIngredientImplCopyWith<_$ResolvedIngredientImpl> get copyWith =>
      __$$ResolvedIngredientImplCopyWithImpl<_$ResolvedIngredientImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ResolvedIngredientImplToJson(this);
  }
}

abstract class _ResolvedIngredient implements ResolvedIngredient {
  const factory _ResolvedIngredient({
    required final ParsedIngredient parsed,
    required final IngredientResolution resolution,
  }) = _$ResolvedIngredientImpl;

  factory _ResolvedIngredient.fromJson(Map<String, dynamic> json) =
      _$ResolvedIngredientImpl.fromJson;

  /// The parsed ingredient data.
  @override
  ParsedIngredient get parsed;

  /// The resolution result from the food database lookup.
  @override
  IngredientResolution get resolution;

  /// Create a copy of ResolvedIngredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResolvedIngredientImplCopyWith<_$ResolvedIngredientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IngredientResolution _$IngredientResolutionFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'matched':
      return IngredientResolutionMatched.fromJson(json);
    case 'fuzzyMatched':
      return IngredientResolutionFuzzyMatched.fromJson(json);
    case 'unmatched':
      return IngredientResolutionUnmatched.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'runtimeType',
        'IngredientResolution',
        'Invalid union type "${json['runtimeType']}"!',
      );
  }
}

/// @nodoc
mixin _$IngredientResolution {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String foodId, double confidence) matched,
    required TResult Function(
      List<FuzzyCandidate> candidates,
      double confidence,
    )
    fuzzyMatched,
    required TResult Function(String text) unmatched,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String foodId, double confidence)? matched,
    TResult? Function(List<FuzzyCandidate> candidates, double confidence)?
    fuzzyMatched,
    TResult? Function(String text)? unmatched,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String foodId, double confidence)? matched,
    TResult Function(List<FuzzyCandidate> candidates, double confidence)?
    fuzzyMatched,
    TResult Function(String text)? unmatched,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IngredientResolutionMatched value) matched,
    required TResult Function(IngredientResolutionFuzzyMatched value)
    fuzzyMatched,
    required TResult Function(IngredientResolutionUnmatched value) unmatched,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IngredientResolutionMatched value)? matched,
    TResult? Function(IngredientResolutionFuzzyMatched value)? fuzzyMatched,
    TResult? Function(IngredientResolutionUnmatched value)? unmatched,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IngredientResolutionMatched value)? matched,
    TResult Function(IngredientResolutionFuzzyMatched value)? fuzzyMatched,
    TResult Function(IngredientResolutionUnmatched value)? unmatched,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this IngredientResolution to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IngredientResolutionCopyWith<$Res> {
  factory $IngredientResolutionCopyWith(
    IngredientResolution value,
    $Res Function(IngredientResolution) then,
  ) = _$IngredientResolutionCopyWithImpl<$Res, IngredientResolution>;
}

/// @nodoc
class _$IngredientResolutionCopyWithImpl<
  $Res,
  $Val extends IngredientResolution
>
    implements $IngredientResolutionCopyWith<$Res> {
  _$IngredientResolutionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IngredientResolution
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$IngredientResolutionMatchedImplCopyWith<$Res> {
  factory _$$IngredientResolutionMatchedImplCopyWith(
    _$IngredientResolutionMatchedImpl value,
    $Res Function(_$IngredientResolutionMatchedImpl) then,
  ) = __$$IngredientResolutionMatchedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String foodId, double confidence});
}

/// @nodoc
class __$$IngredientResolutionMatchedImplCopyWithImpl<$Res>
    extends
        _$IngredientResolutionCopyWithImpl<
          $Res,
          _$IngredientResolutionMatchedImpl
        >
    implements _$$IngredientResolutionMatchedImplCopyWith<$Res> {
  __$$IngredientResolutionMatchedImplCopyWithImpl(
    _$IngredientResolutionMatchedImpl _value,
    $Res Function(_$IngredientResolutionMatchedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IngredientResolution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? foodId = null, Object? confidence = null}) {
    return _then(
      _$IngredientResolutionMatchedImpl(
        foodId: null == foodId
            ? _value.foodId
            : foodId // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IngredientResolutionMatchedImpl implements IngredientResolutionMatched {
  const _$IngredientResolutionMatchedImpl({
    required this.foodId,
    required this.confidence,
    final String? $type,
  }) : $type = $type ?? 'matched';

  factory _$IngredientResolutionMatchedImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$IngredientResolutionMatchedImplFromJson(json);

  /// The ID of the matched food entity.
  @override
  final String foodId;

  /// Confidence score for the match (0.0 to 1.0).
  @override
  final double confidence;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'IngredientResolution.matched(foodId: $foodId, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientResolutionMatchedImpl &&
            (identical(other.foodId, foodId) || other.foodId == foodId) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, foodId, confidence);

  /// Create a copy of IngredientResolution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IngredientResolutionMatchedImplCopyWith<_$IngredientResolutionMatchedImpl>
  get copyWith =>
      __$$IngredientResolutionMatchedImplCopyWithImpl<
        _$IngredientResolutionMatchedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String foodId, double confidence) matched,
    required TResult Function(
      List<FuzzyCandidate> candidates,
      double confidence,
    )
    fuzzyMatched,
    required TResult Function(String text) unmatched,
  }) {
    return matched(foodId, confidence);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String foodId, double confidence)? matched,
    TResult? Function(List<FuzzyCandidate> candidates, double confidence)?
    fuzzyMatched,
    TResult? Function(String text)? unmatched,
  }) {
    return matched?.call(foodId, confidence);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String foodId, double confidence)? matched,
    TResult Function(List<FuzzyCandidate> candidates, double confidence)?
    fuzzyMatched,
    TResult Function(String text)? unmatched,
    required TResult orElse(),
  }) {
    if (matched != null) {
      return matched(foodId, confidence);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IngredientResolutionMatched value) matched,
    required TResult Function(IngredientResolutionFuzzyMatched value)
    fuzzyMatched,
    required TResult Function(IngredientResolutionUnmatched value) unmatched,
  }) {
    return matched(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IngredientResolutionMatched value)? matched,
    TResult? Function(IngredientResolutionFuzzyMatched value)? fuzzyMatched,
    TResult? Function(IngredientResolutionUnmatched value)? unmatched,
  }) {
    return matched?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IngredientResolutionMatched value)? matched,
    TResult Function(IngredientResolutionFuzzyMatched value)? fuzzyMatched,
    TResult Function(IngredientResolutionUnmatched value)? unmatched,
    required TResult orElse(),
  }) {
    if (matched != null) {
      return matched(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$IngredientResolutionMatchedImplToJson(this);
  }
}

abstract class IngredientResolutionMatched implements IngredientResolution {
  const factory IngredientResolutionMatched({
    required final String foodId,
    required final double confidence,
  }) = _$IngredientResolutionMatchedImpl;

  factory IngredientResolutionMatched.fromJson(Map<String, dynamic> json) =
      _$IngredientResolutionMatchedImpl.fromJson;

  /// The ID of the matched food entity.
  String get foodId;

  /// Confidence score for the match (0.0 to 1.0).
  double get confidence;

  /// Create a copy of IngredientResolution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IngredientResolutionMatchedImplCopyWith<_$IngredientResolutionMatchedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$IngredientResolutionFuzzyMatchedImplCopyWith<$Res> {
  factory _$$IngredientResolutionFuzzyMatchedImplCopyWith(
    _$IngredientResolutionFuzzyMatchedImpl value,
    $Res Function(_$IngredientResolutionFuzzyMatchedImpl) then,
  ) = __$$IngredientResolutionFuzzyMatchedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<FuzzyCandidate> candidates, double confidence});
}

/// @nodoc
class __$$IngredientResolutionFuzzyMatchedImplCopyWithImpl<$Res>
    extends
        _$IngredientResolutionCopyWithImpl<
          $Res,
          _$IngredientResolutionFuzzyMatchedImpl
        >
    implements _$$IngredientResolutionFuzzyMatchedImplCopyWith<$Res> {
  __$$IngredientResolutionFuzzyMatchedImplCopyWithImpl(
    _$IngredientResolutionFuzzyMatchedImpl _value,
    $Res Function(_$IngredientResolutionFuzzyMatchedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IngredientResolution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? candidates = null, Object? confidence = null}) {
    return _then(
      _$IngredientResolutionFuzzyMatchedImpl(
        candidates: null == candidates
            ? _value._candidates
            : candidates // ignore: cast_nullable_to_non_nullable
                  as List<FuzzyCandidate>,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IngredientResolutionFuzzyMatchedImpl
    implements IngredientResolutionFuzzyMatched {
  const _$IngredientResolutionFuzzyMatchedImpl({
    required final List<FuzzyCandidate> candidates,
    required this.confidence,
    final String? $type,
  }) : _candidates = candidates,
       $type = $type ?? 'fuzzyMatched';

  factory _$IngredientResolutionFuzzyMatchedImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$IngredientResolutionFuzzyMatchedImplFromJson(json);

  /// Candidate food entity IDs with their confidence scores.
  final List<FuzzyCandidate> _candidates;

  /// Candidate food entity IDs with their confidence scores.
  @override
  List<FuzzyCandidate> get candidates {
    if (_candidates is EqualUnmodifiableListView) return _candidates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_candidates);
  }

  /// Overall confidence in the best match (0.0 to 1.0).
  @override
  final double confidence;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'IngredientResolution.fuzzyMatched(candidates: $candidates, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientResolutionFuzzyMatchedImpl &&
            const DeepCollectionEquality().equals(
              other._candidates,
              _candidates,
            ) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_candidates),
    confidence,
  );

  /// Create a copy of IngredientResolution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IngredientResolutionFuzzyMatchedImplCopyWith<
    _$IngredientResolutionFuzzyMatchedImpl
  >
  get copyWith =>
      __$$IngredientResolutionFuzzyMatchedImplCopyWithImpl<
        _$IngredientResolutionFuzzyMatchedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String foodId, double confidence) matched,
    required TResult Function(
      List<FuzzyCandidate> candidates,
      double confidence,
    )
    fuzzyMatched,
    required TResult Function(String text) unmatched,
  }) {
    return fuzzyMatched(candidates, confidence);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String foodId, double confidence)? matched,
    TResult? Function(List<FuzzyCandidate> candidates, double confidence)?
    fuzzyMatched,
    TResult? Function(String text)? unmatched,
  }) {
    return fuzzyMatched?.call(candidates, confidence);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String foodId, double confidence)? matched,
    TResult Function(List<FuzzyCandidate> candidates, double confidence)?
    fuzzyMatched,
    TResult Function(String text)? unmatched,
    required TResult orElse(),
  }) {
    if (fuzzyMatched != null) {
      return fuzzyMatched(candidates, confidence);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IngredientResolutionMatched value) matched,
    required TResult Function(IngredientResolutionFuzzyMatched value)
    fuzzyMatched,
    required TResult Function(IngredientResolutionUnmatched value) unmatched,
  }) {
    return fuzzyMatched(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IngredientResolutionMatched value)? matched,
    TResult? Function(IngredientResolutionFuzzyMatched value)? fuzzyMatched,
    TResult? Function(IngredientResolutionUnmatched value)? unmatched,
  }) {
    return fuzzyMatched?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IngredientResolutionMatched value)? matched,
    TResult Function(IngredientResolutionFuzzyMatched value)? fuzzyMatched,
    TResult Function(IngredientResolutionUnmatched value)? unmatched,
    required TResult orElse(),
  }) {
    if (fuzzyMatched != null) {
      return fuzzyMatched(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$IngredientResolutionFuzzyMatchedImplToJson(this);
  }
}

abstract class IngredientResolutionFuzzyMatched
    implements IngredientResolution {
  const factory IngredientResolutionFuzzyMatched({
    required final List<FuzzyCandidate> candidates,
    required final double confidence,
  }) = _$IngredientResolutionFuzzyMatchedImpl;

  factory IngredientResolutionFuzzyMatched.fromJson(Map<String, dynamic> json) =
      _$IngredientResolutionFuzzyMatchedImpl.fromJson;

  /// Candidate food entity IDs with their confidence scores.
  List<FuzzyCandidate> get candidates;

  /// Overall confidence in the best match (0.0 to 1.0).
  double get confidence;

  /// Create a copy of IngredientResolution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IngredientResolutionFuzzyMatchedImplCopyWith<
    _$IngredientResolutionFuzzyMatchedImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$IngredientResolutionUnmatchedImplCopyWith<$Res> {
  factory _$$IngredientResolutionUnmatchedImplCopyWith(
    _$IngredientResolutionUnmatchedImpl value,
    $Res Function(_$IngredientResolutionUnmatchedImpl) then,
  ) = __$$IngredientResolutionUnmatchedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String text});
}

/// @nodoc
class __$$IngredientResolutionUnmatchedImplCopyWithImpl<$Res>
    extends
        _$IngredientResolutionCopyWithImpl<
          $Res,
          _$IngredientResolutionUnmatchedImpl
        >
    implements _$$IngredientResolutionUnmatchedImplCopyWith<$Res> {
  __$$IngredientResolutionUnmatchedImplCopyWithImpl(
    _$IngredientResolutionUnmatchedImpl _value,
    $Res Function(_$IngredientResolutionUnmatchedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of IngredientResolution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? text = null}) {
    return _then(
      _$IngredientResolutionUnmatchedImpl(
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IngredientResolutionUnmatchedImpl
    implements IngredientResolutionUnmatched {
  const _$IngredientResolutionUnmatchedImpl({
    required this.text,
    final String? $type,
  }) : $type = $type ?? 'unmatched';

  factory _$IngredientResolutionUnmatchedImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$IngredientResolutionUnmatchedImplFromJson(json);

  /// The original text that could not be matched.
  @override
  final String text;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'IngredientResolution.unmatched(text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientResolutionUnmatchedImpl &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text);

  /// Create a copy of IngredientResolution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IngredientResolutionUnmatchedImplCopyWith<
    _$IngredientResolutionUnmatchedImpl
  >
  get copyWith =>
      __$$IngredientResolutionUnmatchedImplCopyWithImpl<
        _$IngredientResolutionUnmatchedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String foodId, double confidence) matched,
    required TResult Function(
      List<FuzzyCandidate> candidates,
      double confidence,
    )
    fuzzyMatched,
    required TResult Function(String text) unmatched,
  }) {
    return unmatched(text);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String foodId, double confidence)? matched,
    TResult? Function(List<FuzzyCandidate> candidates, double confidence)?
    fuzzyMatched,
    TResult? Function(String text)? unmatched,
  }) {
    return unmatched?.call(text);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String foodId, double confidence)? matched,
    TResult Function(List<FuzzyCandidate> candidates, double confidence)?
    fuzzyMatched,
    TResult Function(String text)? unmatched,
    required TResult orElse(),
  }) {
    if (unmatched != null) {
      return unmatched(text);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(IngredientResolutionMatched value) matched,
    required TResult Function(IngredientResolutionFuzzyMatched value)
    fuzzyMatched,
    required TResult Function(IngredientResolutionUnmatched value) unmatched,
  }) {
    return unmatched(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IngredientResolutionMatched value)? matched,
    TResult? Function(IngredientResolutionFuzzyMatched value)? fuzzyMatched,
    TResult? Function(IngredientResolutionUnmatched value)? unmatched,
  }) {
    return unmatched?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IngredientResolutionMatched value)? matched,
    TResult Function(IngredientResolutionFuzzyMatched value)? fuzzyMatched,
    TResult Function(IngredientResolutionUnmatched value)? unmatched,
    required TResult orElse(),
  }) {
    if (unmatched != null) {
      return unmatched(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$IngredientResolutionUnmatchedImplToJson(this);
  }
}

abstract class IngredientResolutionUnmatched implements IngredientResolution {
  const factory IngredientResolutionUnmatched({required final String text}) =
      _$IngredientResolutionUnmatchedImpl;

  factory IngredientResolutionUnmatched.fromJson(Map<String, dynamic> json) =
      _$IngredientResolutionUnmatchedImpl.fromJson;

  /// The original text that could not be matched.
  String get text;

  /// Create a copy of IngredientResolution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IngredientResolutionUnmatchedImplCopyWith<
    _$IngredientResolutionUnmatchedImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

FuzzyCandidate _$FuzzyCandidateFromJson(Map<String, dynamic> json) {
  return _FuzzyCandidate.fromJson(json);
}

/// @nodoc
mixin _$FuzzyCandidate {
  /// The ID of the candidate food entity.
  String get foodId => throw _privateConstructorUsedError;

  /// Confidence score for this candidate (0.0 to 1.0).
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this FuzzyCandidate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FuzzyCandidate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FuzzyCandidateCopyWith<FuzzyCandidate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FuzzyCandidateCopyWith<$Res> {
  factory $FuzzyCandidateCopyWith(
    FuzzyCandidate value,
    $Res Function(FuzzyCandidate) then,
  ) = _$FuzzyCandidateCopyWithImpl<$Res, FuzzyCandidate>;
  @useResult
  $Res call({String foodId, double confidence});
}

/// @nodoc
class _$FuzzyCandidateCopyWithImpl<$Res, $Val extends FuzzyCandidate>
    implements $FuzzyCandidateCopyWith<$Res> {
  _$FuzzyCandidateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FuzzyCandidate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? foodId = null, Object? confidence = null}) {
    return _then(
      _value.copyWith(
            foodId: null == foodId
                ? _value.foodId
                : foodId // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FuzzyCandidateImplCopyWith<$Res>
    implements $FuzzyCandidateCopyWith<$Res> {
  factory _$$FuzzyCandidateImplCopyWith(
    _$FuzzyCandidateImpl value,
    $Res Function(_$FuzzyCandidateImpl) then,
  ) = __$$FuzzyCandidateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String foodId, double confidence});
}

/// @nodoc
class __$$FuzzyCandidateImplCopyWithImpl<$Res>
    extends _$FuzzyCandidateCopyWithImpl<$Res, _$FuzzyCandidateImpl>
    implements _$$FuzzyCandidateImplCopyWith<$Res> {
  __$$FuzzyCandidateImplCopyWithImpl(
    _$FuzzyCandidateImpl _value,
    $Res Function(_$FuzzyCandidateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FuzzyCandidate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? foodId = null, Object? confidence = null}) {
    return _then(
      _$FuzzyCandidateImpl(
        foodId: null == foodId
            ? _value.foodId
            : foodId // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FuzzyCandidateImpl implements _FuzzyCandidate {
  const _$FuzzyCandidateImpl({required this.foodId, required this.confidence});

  factory _$FuzzyCandidateImpl.fromJson(Map<String, dynamic> json) =>
      _$$FuzzyCandidateImplFromJson(json);

  /// The ID of the candidate food entity.
  @override
  final String foodId;

  /// Confidence score for this candidate (0.0 to 1.0).
  @override
  final double confidence;

  @override
  String toString() {
    return 'FuzzyCandidate(foodId: $foodId, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FuzzyCandidateImpl &&
            (identical(other.foodId, foodId) || other.foodId == foodId) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, foodId, confidence);

  /// Create a copy of FuzzyCandidate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FuzzyCandidateImplCopyWith<_$FuzzyCandidateImpl> get copyWith =>
      __$$FuzzyCandidateImplCopyWithImpl<_$FuzzyCandidateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FuzzyCandidateImplToJson(this);
  }
}

abstract class _FuzzyCandidate implements FuzzyCandidate {
  const factory _FuzzyCandidate({
    required final String foodId,
    required final double confidence,
  }) = _$FuzzyCandidateImpl;

  factory _FuzzyCandidate.fromJson(Map<String, dynamic> json) =
      _$FuzzyCandidateImpl.fromJson;

  /// The ID of the candidate food entity.
  @override
  String get foodId;

  /// Confidence score for this candidate (0.0 to 1.0).
  @override
  double get confidence;

  /// Create a copy of FuzzyCandidate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FuzzyCandidateImplCopyWith<_$FuzzyCandidateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
