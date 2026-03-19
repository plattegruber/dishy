// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NutritionFactsImpl _$$NutritionFactsImplFromJson(Map<String, dynamic> json) =>
    _$NutritionFactsImpl(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );

Map<String, dynamic> _$$NutritionFactsImplToJson(
  _$NutritionFactsImpl instance,
) => <String, dynamic>{
  'calories': instance.calories,
  'protein': instance.protein,
  'carbs': instance.carbs,
  'fat': instance.fat,
};

_$NutritionComputationImpl _$$NutritionComputationImplFromJson(
  Map<String, dynamic> json,
) => _$NutritionComputationImpl(
  perRecipe: NutritionFacts.fromJson(json['perRecipe'] as Map<String, dynamic>),
  perServing: json['perServing'] == null
      ? null
      : NutritionFacts.fromJson(json['perServing'] as Map<String, dynamic>),
  status: $enumDecode(_$NutritionStatusEnumMap, json['status']),
);

Map<String, dynamic> _$$NutritionComputationImplToJson(
  _$NutritionComputationImpl instance,
) => <String, dynamic>{
  'perRecipe': instance.perRecipe,
  'perServing': instance.perServing,
  'status': _$NutritionStatusEnumMap[instance.status]!,
};

const _$NutritionStatusEnumMap = {
  NutritionStatus.pending: 'pending',
  NutritionStatus.calculated: 'calculated',
  NutritionStatus.estimated: 'estimated',
  NutritionStatus.unavailable: 'unavailable',
};
