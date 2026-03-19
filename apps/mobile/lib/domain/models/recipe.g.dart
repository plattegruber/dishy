// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SourceImpl _$$SourceImplFromJson(Map<String, dynamic> json) => _$SourceImpl(
  platform: $enumDecode(_$PlatformEnumMap, json['platform']),
  url: json['url'] as String?,
  creatorHandle: json['creatorHandle'] as String?,
  creatorId: json['creatorId'] as String?,
);

Map<String, dynamic> _$$SourceImplToJson(_$SourceImpl instance) =>
    <String, dynamic>{
      'platform': _$PlatformEnumMap[instance.platform]!,
      'url': instance.url,
      'creatorHandle': instance.creatorHandle,
      'creatorId': instance.creatorId,
    };

const _$PlatformEnumMap = {
  Platform.instagram: 'instagram',
  Platform.tiktok: 'tiktok',
  Platform.youtube: 'youtube',
  Platform.website: 'website',
  Platform.manual: 'manual',
  Platform.unknown: 'unknown',
};

_$CoverOutputSourceImageImpl _$$CoverOutputSourceImageImplFromJson(
  Map<String, dynamic> json,
) => _$CoverOutputSourceImageImpl(
  assetId: json['assetId'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$CoverOutputSourceImageImplToJson(
  _$CoverOutputSourceImageImpl instance,
) => <String, dynamic>{
  'assetId': instance.assetId,
  'runtimeType': instance.$type,
};

_$CoverOutputEnhancedImageImpl _$$CoverOutputEnhancedImageImplFromJson(
  Map<String, dynamic> json,
) => _$CoverOutputEnhancedImageImpl(
  assetId: json['assetId'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$CoverOutputEnhancedImageImplToJson(
  _$CoverOutputEnhancedImageImpl instance,
) => <String, dynamic>{
  'assetId': instance.assetId,
  'runtimeType': instance.$type,
};

_$CoverOutputGeneratedCoverImpl _$$CoverOutputGeneratedCoverImplFromJson(
  Map<String, dynamic> json,
) => _$CoverOutputGeneratedCoverImpl(
  assetId: json['assetId'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$CoverOutputGeneratedCoverImplToJson(
  _$CoverOutputGeneratedCoverImpl instance,
) => <String, dynamic>{
  'assetId': instance.assetId,
  'runtimeType': instance.$type,
};

_$StepImpl _$$StepImplFromJson(Map<String, dynamic> json) => _$StepImpl(
  number: (json['number'] as num).toInt(),
  instruction: json['instruction'] as String,
  timeMinutes: (json['timeMinutes'] as num?)?.toInt(),
);

Map<String, dynamic> _$$StepImplToJson(_$StepImpl instance) =>
    <String, dynamic>{
      'number': instance.number,
      'instruction': instance.instruction,
      'timeMinutes': instance.timeMinutes,
    };

_$ResolvedRecipeImpl _$$ResolvedRecipeImplFromJson(Map<String, dynamic> json) =>
    _$ResolvedRecipeImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => ResolvedIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json['steps'] as List<dynamic>)
          .map((e) => Step.fromJson(e as Map<String, dynamic>))
          .toList(),
      servings: (json['servings'] as num?)?.toInt(),
      timeMinutes: (json['timeMinutes'] as num?)?.toInt(),
      source: Source.fromJson(json['source'] as Map<String, dynamic>),
      nutrition: NutritionComputation.fromJson(
        json['nutrition'] as Map<String, dynamic>,
      ),
      cover: CoverOutput.fromJson(json['cover'] as Map<String, dynamic>),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$ResolvedRecipeImplToJson(
  _$ResolvedRecipeImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'ingredients': instance.ingredients,
  'steps': instance.steps,
  'servings': instance.servings,
  'timeMinutes': instance.timeMinutes,
  'source': instance.source,
  'nutrition': instance.nutrition,
  'cover': instance.cover,
  'tags': instance.tags,
};

_$UserRecipeViewImpl _$$UserRecipeViewImplFromJson(Map<String, dynamic> json) =>
    _$UserRecipeViewImpl(
      recipeId: json['recipeId'] as String,
      userId: json['userId'] as String,
      saved: json['saved'] as bool,
      favorite: json['favorite'] as bool,
      notes: json['notes'] as String?,
      patches: (json['patches'] as List<dynamic>)
          .map((e) => RecipePatch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$UserRecipeViewImplToJson(
  _$UserRecipeViewImpl instance,
) => <String, dynamic>{
  'recipeId': instance.recipeId,
  'userId': instance.userId,
  'saved': instance.saved,
  'favorite': instance.favorite,
  'notes': instance.notes,
  'patches': instance.patches,
};

_$RecipePatchImpl _$$RecipePatchImplFromJson(Map<String, dynamic> json) =>
    _$RecipePatchImpl(
      field: json['field'] as String,
      value: json['value'] as Object,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$$RecipePatchImplToJson(_$RecipePatchImpl instance) =>
    <String, dynamic>{
      'field': instance.field,
      'value': instance.value,
      'createdAt': instance.createdAt,
    };
