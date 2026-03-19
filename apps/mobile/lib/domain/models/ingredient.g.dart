// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IngredientLineImpl _$$IngredientLineImplFromJson(Map<String, dynamic> json) =>
    _$IngredientLineImpl(
      rawText: json['rawText'] as String,
      parsed: json['parsed'] == null
          ? null
          : ParsedIngredient.fromJson(json['parsed'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$IngredientLineImplToJson(
  _$IngredientLineImpl instance,
) => <String, dynamic>{'rawText': instance.rawText, 'parsed': instance.parsed};

_$ParsedIngredientImpl _$$ParsedIngredientImplFromJson(
  Map<String, dynamic> json,
) => _$ParsedIngredientImpl(
  quantity: (json['quantity'] as num?)?.toDouble(),
  unit: json['unit'] as String?,
  name: json['name'] as String,
  preparation: json['preparation'] as String?,
);

Map<String, dynamic> _$$ParsedIngredientImplToJson(
  _$ParsedIngredientImpl instance,
) => <String, dynamic>{
  'quantity': instance.quantity,
  'unit': instance.unit,
  'name': instance.name,
  'preparation': instance.preparation,
};

_$ResolvedIngredientImpl _$$ResolvedIngredientImplFromJson(
  Map<String, dynamic> json,
) => _$ResolvedIngredientImpl(
  parsed: ParsedIngredient.fromJson(json['parsed'] as Map<String, dynamic>),
  resolution: IngredientResolution.fromJson(
    json['resolution'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$$ResolvedIngredientImplToJson(
  _$ResolvedIngredientImpl instance,
) => <String, dynamic>{
  'parsed': instance.parsed,
  'resolution': instance.resolution,
};

_$IngredientResolutionMatchedImpl _$$IngredientResolutionMatchedImplFromJson(
  Map<String, dynamic> json,
) => _$IngredientResolutionMatchedImpl(
  foodId: json['foodId'] as String,
  confidence: (json['confidence'] as num).toDouble(),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$IngredientResolutionMatchedImplToJson(
  _$IngredientResolutionMatchedImpl instance,
) => <String, dynamic>{
  'foodId': instance.foodId,
  'confidence': instance.confidence,
  'runtimeType': instance.$type,
};

_$IngredientResolutionFuzzyMatchedImpl
_$$IngredientResolutionFuzzyMatchedImplFromJson(Map<String, dynamic> json) =>
    _$IngredientResolutionFuzzyMatchedImpl(
      candidates: (json['candidates'] as List<dynamic>)
          .map((e) => FuzzyCandidate.fromJson(e as Map<String, dynamic>))
          .toList(),
      confidence: (json['confidence'] as num).toDouble(),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$IngredientResolutionFuzzyMatchedImplToJson(
  _$IngredientResolutionFuzzyMatchedImpl instance,
) => <String, dynamic>{
  'candidates': instance.candidates,
  'confidence': instance.confidence,
  'runtimeType': instance.$type,
};

_$IngredientResolutionUnmatchedImpl
_$$IngredientResolutionUnmatchedImplFromJson(Map<String, dynamic> json) =>
    _$IngredientResolutionUnmatchedImpl(
      text: json['text'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$IngredientResolutionUnmatchedImplToJson(
  _$IngredientResolutionUnmatchedImpl instance,
) => <String, dynamic>{'text': instance.text, 'runtimeType': instance.$type};

_$FuzzyCandidateImpl _$$FuzzyCandidateImplFromJson(Map<String, dynamic> json) =>
    _$FuzzyCandidateImpl(
      foodId: json['foodId'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$$FuzzyCandidateImplToJson(
  _$FuzzyCandidateImpl instance,
) => <String, dynamic>{
  'foodId': instance.foodId,
  'confidence': instance.confidence,
};
