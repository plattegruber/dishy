// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nutrition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

NutritionFacts _$NutritionFactsFromJson(Map<String, dynamic> json) {
  return _NutritionFacts.fromJson(json);
}

/// @nodoc
mixin _$NutritionFacts {
  /// Total calories in kilocalories (kcal).
  double get calories => throw _privateConstructorUsedError;

  /// Protein content in grams.
  double get protein => throw _privateConstructorUsedError;

  /// Carbohydrate content in grams.
  double get carbs => throw _privateConstructorUsedError;

  /// Fat content in grams.
  double get fat => throw _privateConstructorUsedError;

  /// Serializes this NutritionFacts to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionFacts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionFactsCopyWith<NutritionFacts> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionFactsCopyWith<$Res> {
  factory $NutritionFactsCopyWith(
    NutritionFacts value,
    $Res Function(NutritionFacts) then,
  ) = _$NutritionFactsCopyWithImpl<$Res, NutritionFacts>;
  @useResult
  $Res call({double calories, double protein, double carbs, double fat});
}

/// @nodoc
class _$NutritionFactsCopyWithImpl<$Res, $Val extends NutritionFacts>
    implements $NutritionFactsCopyWith<$Res> {
  _$NutritionFactsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionFacts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
  }) {
    return _then(
      _value.copyWith(
            calories: null == calories
                ? _value.calories
                : calories // ignore: cast_nullable_to_non_nullable
                      as double,
            protein: null == protein
                ? _value.protein
                : protein // ignore: cast_nullable_to_non_nullable
                      as double,
            carbs: null == carbs
                ? _value.carbs
                : carbs // ignore: cast_nullable_to_non_nullable
                      as double,
            fat: null == fat
                ? _value.fat
                : fat // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NutritionFactsImplCopyWith<$Res>
    implements $NutritionFactsCopyWith<$Res> {
  factory _$$NutritionFactsImplCopyWith(
    _$NutritionFactsImpl value,
    $Res Function(_$NutritionFactsImpl) then,
  ) = __$$NutritionFactsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double calories, double protein, double carbs, double fat});
}

/// @nodoc
class __$$NutritionFactsImplCopyWithImpl<$Res>
    extends _$NutritionFactsCopyWithImpl<$Res, _$NutritionFactsImpl>
    implements _$$NutritionFactsImplCopyWith<$Res> {
  __$$NutritionFactsImplCopyWithImpl(
    _$NutritionFactsImpl _value,
    $Res Function(_$NutritionFactsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NutritionFacts
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
  }) {
    return _then(
      _$NutritionFactsImpl(
        calories: null == calories
            ? _value.calories
            : calories // ignore: cast_nullable_to_non_nullable
                  as double,
        protein: null == protein
            ? _value.protein
            : protein // ignore: cast_nullable_to_non_nullable
                  as double,
        carbs: null == carbs
            ? _value.carbs
            : carbs // ignore: cast_nullable_to_non_nullable
                  as double,
        fat: null == fat
            ? _value.fat
            : fat // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionFactsImpl implements _NutritionFacts {
  const _$NutritionFactsImpl({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory _$NutritionFactsImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionFactsImplFromJson(json);

  /// Total calories in kilocalories (kcal).
  @override
  final double calories;

  /// Protein content in grams.
  @override
  final double protein;

  /// Carbohydrate content in grams.
  @override
  final double carbs;

  /// Fat content in grams.
  @override
  final double fat;

  @override
  String toString() {
    return 'NutritionFacts(calories: $calories, protein: $protein, carbs: $carbs, fat: $fat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionFactsImpl &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.fat, fat) || other.fat == fat));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, calories, protein, carbs, fat);

  /// Create a copy of NutritionFacts
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionFactsImplCopyWith<_$NutritionFactsImpl> get copyWith =>
      __$$NutritionFactsImplCopyWithImpl<_$NutritionFactsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionFactsImplToJson(this);
  }
}

abstract class _NutritionFacts implements NutritionFacts {
  const factory _NutritionFacts({
    required final double calories,
    required final double protein,
    required final double carbs,
    required final double fat,
  }) = _$NutritionFactsImpl;

  factory _NutritionFacts.fromJson(Map<String, dynamic> json) =
      _$NutritionFactsImpl.fromJson;

  /// Total calories in kilocalories (kcal).
  @override
  double get calories;

  /// Protein content in grams.
  @override
  double get protein;

  /// Carbohydrate content in grams.
  @override
  double get carbs;

  /// Fat content in grams.
  @override
  double get fat;

  /// Create a copy of NutritionFacts
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionFactsImplCopyWith<_$NutritionFactsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NutritionComputation _$NutritionComputationFromJson(Map<String, dynamic> json) {
  return _NutritionComputation.fromJson(json);
}

/// @nodoc
mixin _$NutritionComputation {
  /// Total nutrition for the entire recipe.
  NutritionFacts get perRecipe => throw _privateConstructorUsedError;

  /// Nutrition per serving, if the recipe has a defined serving count.
  NutritionFacts? get perServing => throw _privateConstructorUsedError;

  /// Status indicating the reliability of this computation.
  NutritionStatus get status => throw _privateConstructorUsedError;

  /// Serializes this NutritionComputation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionComputation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionComputationCopyWith<NutritionComputation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionComputationCopyWith<$Res> {
  factory $NutritionComputationCopyWith(
    NutritionComputation value,
    $Res Function(NutritionComputation) then,
  ) = _$NutritionComputationCopyWithImpl<$Res, NutritionComputation>;
  @useResult
  $Res call({
    NutritionFacts perRecipe,
    NutritionFacts? perServing,
    NutritionStatus status,
  });

  $NutritionFactsCopyWith<$Res> get perRecipe;
  $NutritionFactsCopyWith<$Res>? get perServing;
}

/// @nodoc
class _$NutritionComputationCopyWithImpl<
  $Res,
  $Val extends NutritionComputation
>
    implements $NutritionComputationCopyWith<$Res> {
  _$NutritionComputationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionComputation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? perRecipe = null,
    Object? perServing = freezed,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            perRecipe: null == perRecipe
                ? _value.perRecipe
                : perRecipe // ignore: cast_nullable_to_non_nullable
                      as NutritionFacts,
            perServing: freezed == perServing
                ? _value.perServing
                : perServing // ignore: cast_nullable_to_non_nullable
                      as NutritionFacts?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as NutritionStatus,
          )
          as $Val,
    );
  }

  /// Create a copy of NutritionComputation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NutritionFactsCopyWith<$Res> get perRecipe {
    return $NutritionFactsCopyWith<$Res>(_value.perRecipe, (value) {
      return _then(_value.copyWith(perRecipe: value) as $Val);
    });
  }

  /// Create a copy of NutritionComputation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NutritionFactsCopyWith<$Res>? get perServing {
    if (_value.perServing == null) {
      return null;
    }

    return $NutritionFactsCopyWith<$Res>(_value.perServing!, (value) {
      return _then(_value.copyWith(perServing: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NutritionComputationImplCopyWith<$Res>
    implements $NutritionComputationCopyWith<$Res> {
  factory _$$NutritionComputationImplCopyWith(
    _$NutritionComputationImpl value,
    $Res Function(_$NutritionComputationImpl) then,
  ) = __$$NutritionComputationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    NutritionFacts perRecipe,
    NutritionFacts? perServing,
    NutritionStatus status,
  });

  @override
  $NutritionFactsCopyWith<$Res> get perRecipe;
  @override
  $NutritionFactsCopyWith<$Res>? get perServing;
}

/// @nodoc
class __$$NutritionComputationImplCopyWithImpl<$Res>
    extends _$NutritionComputationCopyWithImpl<$Res, _$NutritionComputationImpl>
    implements _$$NutritionComputationImplCopyWith<$Res> {
  __$$NutritionComputationImplCopyWithImpl(
    _$NutritionComputationImpl _value,
    $Res Function(_$NutritionComputationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NutritionComputation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? perRecipe = null,
    Object? perServing = freezed,
    Object? status = null,
  }) {
    return _then(
      _$NutritionComputationImpl(
        perRecipe: null == perRecipe
            ? _value.perRecipe
            : perRecipe // ignore: cast_nullable_to_non_nullable
                  as NutritionFacts,
        perServing: freezed == perServing
            ? _value.perServing
            : perServing // ignore: cast_nullable_to_non_nullable
                  as NutritionFacts?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as NutritionStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionComputationImpl implements _NutritionComputation {
  const _$NutritionComputationImpl({
    required this.perRecipe,
    this.perServing,
    required this.status,
  });

  factory _$NutritionComputationImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionComputationImplFromJson(json);

  /// Total nutrition for the entire recipe.
  @override
  final NutritionFacts perRecipe;

  /// Nutrition per serving, if the recipe has a defined serving count.
  @override
  final NutritionFacts? perServing;

  /// Status indicating the reliability of this computation.
  @override
  final NutritionStatus status;

  @override
  String toString() {
    return 'NutritionComputation(perRecipe: $perRecipe, perServing: $perServing, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionComputationImpl &&
            (identical(other.perRecipe, perRecipe) ||
                other.perRecipe == perRecipe) &&
            (identical(other.perServing, perServing) ||
                other.perServing == perServing) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, perRecipe, perServing, status);

  /// Create a copy of NutritionComputation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionComputationImplCopyWith<_$NutritionComputationImpl>
  get copyWith =>
      __$$NutritionComputationImplCopyWithImpl<_$NutritionComputationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionComputationImplToJson(this);
  }
}

abstract class _NutritionComputation implements NutritionComputation {
  const factory _NutritionComputation({
    required final NutritionFacts perRecipe,
    final NutritionFacts? perServing,
    required final NutritionStatus status,
  }) = _$NutritionComputationImpl;

  factory _NutritionComputation.fromJson(Map<String, dynamic> json) =
      _$NutritionComputationImpl.fromJson;

  /// Total nutrition for the entire recipe.
  @override
  NutritionFacts get perRecipe;

  /// Nutrition per serving, if the recipe has a defined serving count.
  @override
  NutritionFacts? get perServing;

  /// Status indicating the reliability of this computation.
  @override
  NutritionStatus get status;

  /// Create a copy of NutritionComputation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionComputationImplCopyWith<_$NutritionComputationImpl>
  get copyWith => throw _privateConstructorUsedError;
}
