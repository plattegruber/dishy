// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grocery.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GroceryItem _$GroceryItemFromJson(Map<String, dynamic> json) {
  return _GroceryItem.fromJson(json);
}

/// @nodoc
mixin _$GroceryItem {
  /// Display name of the ingredient.
  String get name => throw _privateConstructorUsedError;

  /// Total quantity after merging (may be null if not parseable).
  double? get quantity => throw _privateConstructorUsedError;

  /// Unit of measurement.
  String? get unit => throw _privateConstructorUsedError;

  /// The category for aisle grouping.
  GroceryCategory get category => throw _privateConstructorUsedError;

  /// IDs of recipes this ingredient came from.
  List<String> get recipeIds => throw _privateConstructorUsedError;

  /// Whether the item has been checked off.
  bool get checked => throw _privateConstructorUsedError;

  /// Serializes this GroceryItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroceryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroceryItemCopyWith<GroceryItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroceryItemCopyWith<$Res> {
  factory $GroceryItemCopyWith(
    GroceryItem value,
    $Res Function(GroceryItem) then,
  ) = _$GroceryItemCopyWithImpl<$Res, GroceryItem>;
  @useResult
  $Res call({
    String name,
    double? quantity,
    String? unit,
    GroceryCategory category,
    List<String> recipeIds,
    bool checked,
  });
}

/// @nodoc
class _$GroceryItemCopyWithImpl<$Res, $Val extends GroceryItem>
    implements $GroceryItemCopyWith<$Res> {
  _$GroceryItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroceryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? category = null,
    Object? recipeIds = null,
    Object? checked = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            quantity: freezed == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as double?,
            unit: freezed == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String?,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as GroceryCategory,
            recipeIds: null == recipeIds
                ? _value.recipeIds
                : recipeIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            checked: null == checked
                ? _value.checked
                : checked // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GroceryItemImplCopyWith<$Res>
    implements $GroceryItemCopyWith<$Res> {
  factory _$$GroceryItemImplCopyWith(
    _$GroceryItemImpl value,
    $Res Function(_$GroceryItemImpl) then,
  ) = __$$GroceryItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    double? quantity,
    String? unit,
    GroceryCategory category,
    List<String> recipeIds,
    bool checked,
  });
}

/// @nodoc
class __$$GroceryItemImplCopyWithImpl<$Res>
    extends _$GroceryItemCopyWithImpl<$Res, _$GroceryItemImpl>
    implements _$$GroceryItemImplCopyWith<$Res> {
  __$$GroceryItemImplCopyWithImpl(
    _$GroceryItemImpl _value,
    $Res Function(_$GroceryItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroceryItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? category = null,
    Object? recipeIds = null,
    Object? checked = null,
  }) {
    return _then(
      _$GroceryItemImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        quantity: freezed == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as double?,
        unit: freezed == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String?,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as GroceryCategory,
        recipeIds: null == recipeIds
            ? _value._recipeIds
            : recipeIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        checked: null == checked
            ? _value.checked
            : checked // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GroceryItemImpl implements _GroceryItem {
  const _$GroceryItemImpl({
    required this.name,
    this.quantity,
    this.unit,
    required this.category,
    required final List<String> recipeIds,
    this.checked = false,
  }) : _recipeIds = recipeIds;

  factory _$GroceryItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroceryItemImplFromJson(json);

  /// Display name of the ingredient.
  @override
  final String name;

  /// Total quantity after merging (may be null if not parseable).
  @override
  final double? quantity;

  /// Unit of measurement.
  @override
  final String? unit;

  /// The category for aisle grouping.
  @override
  final GroceryCategory category;

  /// IDs of recipes this ingredient came from.
  final List<String> _recipeIds;

  /// IDs of recipes this ingredient came from.
  @override
  List<String> get recipeIds {
    if (_recipeIds is EqualUnmodifiableListView) return _recipeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recipeIds);
  }

  /// Whether the item has been checked off.
  @override
  @JsonKey()
  final bool checked;

  @override
  String toString() {
    return 'GroceryItem(name: $name, quantity: $quantity, unit: $unit, category: $category, recipeIds: $recipeIds, checked: $checked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroceryItemImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(
              other._recipeIds,
              _recipeIds,
            ) &&
            (identical(other.checked, checked) || other.checked == checked));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    quantity,
    unit,
    category,
    const DeepCollectionEquality().hash(_recipeIds),
    checked,
  );

  /// Create a copy of GroceryItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroceryItemImplCopyWith<_$GroceryItemImpl> get copyWith =>
      __$$GroceryItemImplCopyWithImpl<_$GroceryItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroceryItemImplToJson(this);
  }
}

abstract class _GroceryItem implements GroceryItem {
  const factory _GroceryItem({
    required final String name,
    final double? quantity,
    final String? unit,
    required final GroceryCategory category,
    required final List<String> recipeIds,
    final bool checked,
  }) = _$GroceryItemImpl;

  factory _GroceryItem.fromJson(Map<String, dynamic> json) =
      _$GroceryItemImpl.fromJson;

  /// Display name of the ingredient.
  @override
  String get name;

  /// Total quantity after merging (may be null if not parseable).
  @override
  double? get quantity;

  /// Unit of measurement.
  @override
  String? get unit;

  /// The category for aisle grouping.
  @override
  GroceryCategory get category;

  /// IDs of recipes this ingredient came from.
  @override
  List<String> get recipeIds;

  /// Whether the item has been checked off.
  @override
  bool get checked;

  /// Create a copy of GroceryItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroceryItemImplCopyWith<_$GroceryItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroceryList _$GroceryListFromJson(Map<String, dynamic> json) {
  return _GroceryList.fromJson(json);
}

/// @nodoc
mixin _$GroceryList {
  /// All items in the grocery list, grouped by category.
  List<GroceryItem> get items => throw _privateConstructorUsedError;

  /// Recipe IDs that contributed to this list.
  List<String> get recipeIds => throw _privateConstructorUsedError;

  /// Serializes this GroceryList to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroceryList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroceryListCopyWith<GroceryList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroceryListCopyWith<$Res> {
  factory $GroceryListCopyWith(
    GroceryList value,
    $Res Function(GroceryList) then,
  ) = _$GroceryListCopyWithImpl<$Res, GroceryList>;
  @useResult
  $Res call({List<GroceryItem> items, List<String> recipeIds});
}

/// @nodoc
class _$GroceryListCopyWithImpl<$Res, $Val extends GroceryList>
    implements $GroceryListCopyWith<$Res> {
  _$GroceryListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroceryList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null, Object? recipeIds = null}) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<GroceryItem>,
            recipeIds: null == recipeIds
                ? _value.recipeIds
                : recipeIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GroceryListImplCopyWith<$Res>
    implements $GroceryListCopyWith<$Res> {
  factory _$$GroceryListImplCopyWith(
    _$GroceryListImpl value,
    $Res Function(_$GroceryListImpl) then,
  ) = __$$GroceryListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<GroceryItem> items, List<String> recipeIds});
}

/// @nodoc
class __$$GroceryListImplCopyWithImpl<$Res>
    extends _$GroceryListCopyWithImpl<$Res, _$GroceryListImpl>
    implements _$$GroceryListImplCopyWith<$Res> {
  __$$GroceryListImplCopyWithImpl(
    _$GroceryListImpl _value,
    $Res Function(_$GroceryListImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroceryList
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? items = null, Object? recipeIds = null}) {
    return _then(
      _$GroceryListImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<GroceryItem>,
        recipeIds: null == recipeIds
            ? _value._recipeIds
            : recipeIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GroceryListImpl implements _GroceryList {
  const _$GroceryListImpl({
    required final List<GroceryItem> items,
    required final List<String> recipeIds,
  }) : _items = items,
       _recipeIds = recipeIds;

  factory _$GroceryListImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroceryListImplFromJson(json);

  /// All items in the grocery list, grouped by category.
  final List<GroceryItem> _items;

  /// All items in the grocery list, grouped by category.
  @override
  List<GroceryItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// Recipe IDs that contributed to this list.
  final List<String> _recipeIds;

  /// Recipe IDs that contributed to this list.
  @override
  List<String> get recipeIds {
    if (_recipeIds is EqualUnmodifiableListView) return _recipeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recipeIds);
  }

  @override
  String toString() {
    return 'GroceryList(items: $items, recipeIds: $recipeIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroceryListImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality().equals(
              other._recipeIds,
              _recipeIds,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    const DeepCollectionEquality().hash(_recipeIds),
  );

  /// Create a copy of GroceryList
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroceryListImplCopyWith<_$GroceryListImpl> get copyWith =>
      __$$GroceryListImplCopyWithImpl<_$GroceryListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroceryListImplToJson(this);
  }
}

abstract class _GroceryList implements GroceryList {
  const factory _GroceryList({
    required final List<GroceryItem> items,
    required final List<String> recipeIds,
  }) = _$GroceryListImpl;

  factory _GroceryList.fromJson(Map<String, dynamic> json) =
      _$GroceryListImpl.fromJson;

  /// All items in the grocery list, grouped by category.
  @override
  List<GroceryItem> get items;

  /// Recipe IDs that contributed to this list.
  @override
  List<String> get recipeIds;

  /// Create a copy of GroceryList
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroceryListImplCopyWith<_$GroceryListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
