// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GroceryItemImpl _$$GroceryItemImplFromJson(Map<String, dynamic> json) =>
    _$GroceryItemImpl(
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      category: $enumDecode(_$GroceryCategoryEnumMap, json['category']),
      recipeIds: (json['recipeIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      checked: json['checked'] as bool? ?? false,
    );

Map<String, dynamic> _$$GroceryItemImplToJson(_$GroceryItemImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'category': _$GroceryCategoryEnumMap[instance.category]!,
      'recipeIds': instance.recipeIds,
      'checked': instance.checked,
    };

const _$GroceryCategoryEnumMap = {
  GroceryCategory.produce: 'produce',
  GroceryCategory.dairy: 'dairy',
  GroceryCategory.meat: 'meat',
  GroceryCategory.pantry: 'pantry',
  GroceryCategory.frozen: 'frozen',
  GroceryCategory.bakery: 'bakery',
  GroceryCategory.other: 'other',
};

_$GroceryListImpl _$$GroceryListImplFromJson(Map<String, dynamic> json) =>
    _$GroceryListImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => GroceryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      recipeIds: (json['recipeIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$GroceryListImplToJson(_$GroceryListImpl instance) =>
    <String, dynamic>{'items': instance.items, 'recipeIds': instance.recipeIds};
