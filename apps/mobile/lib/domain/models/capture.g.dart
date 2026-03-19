// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CaptureInputSocialLinkImpl _$$CaptureInputSocialLinkImplFromJson(
  Map<String, dynamic> json,
) => _$CaptureInputSocialLinkImpl(
  url: json['url'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$CaptureInputSocialLinkImplToJson(
  _$CaptureInputSocialLinkImpl instance,
) => <String, dynamic>{'url': instance.url, 'runtimeType': instance.$type};

_$CaptureInputScreenshotImpl _$$CaptureInputScreenshotImplFromJson(
  Map<String, dynamic> json,
) => _$CaptureInputScreenshotImpl(
  image: json['image'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$CaptureInputScreenshotImplToJson(
  _$CaptureInputScreenshotImpl instance,
) => <String, dynamic>{'image': instance.image, 'runtimeType': instance.$type};

_$CaptureInputScanImpl _$$CaptureInputScanImplFromJson(
  Map<String, dynamic> json,
) => _$CaptureInputScanImpl(
  image: json['image'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$CaptureInputScanImplToJson(
  _$CaptureInputScanImpl instance,
) => <String, dynamic>{'image': instance.image, 'runtimeType': instance.$type};

_$CaptureInputSpeechImpl _$$CaptureInputSpeechImplFromJson(
  Map<String, dynamic> json,
) => _$CaptureInputSpeechImpl(
  transcript: json['transcript'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$CaptureInputSpeechImplToJson(
  _$CaptureInputSpeechImpl instance,
) => <String, dynamic>{
  'transcript': instance.transcript,
  'runtimeType': instance.$type,
};

_$CaptureInputManualImpl _$$CaptureInputManualImplFromJson(
  Map<String, dynamic> json,
) => _$CaptureInputManualImpl(
  text: json['text'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$$CaptureInputManualImplToJson(
  _$CaptureInputManualImpl instance,
) => <String, dynamic>{'text': instance.text, 'runtimeType': instance.$type};

_$ExtractionArtifactImpl _$$ExtractionArtifactImplFromJson(
  Map<String, dynamic> json,
) => _$ExtractionArtifactImpl(
  id: json['id'] as String,
  version: (json['version'] as num).toInt(),
  rawText: json['rawText'] as String?,
  ocrText: json['ocrText'] as String?,
  transcript: json['transcript'] as String?,
  ingredients: (json['ingredients'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
  images: (json['images'] as List<dynamic>).map((e) => e as String).toList(),
  source: Source.fromJson(json['source'] as Map<String, dynamic>),
  confidence: (json['confidence'] as num).toDouble(),
);

Map<String, dynamic> _$$ExtractionArtifactImplToJson(
  _$ExtractionArtifactImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'version': instance.version,
  'rawText': instance.rawText,
  'ocrText': instance.ocrText,
  'transcript': instance.transcript,
  'ingredients': instance.ingredients,
  'steps': instance.steps,
  'images': instance.images,
  'source': instance.source,
  'confidence': instance.confidence,
};

_$StructuredRecipeCandidateImpl _$$StructuredRecipeCandidateImplFromJson(
  Map<String, dynamic> json,
) => _$StructuredRecipeCandidateImpl(
  title: json['title'] as String?,
  ingredientLines: (json['ingredientLines'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
  servings: (json['servings'] as num?)?.toInt(),
  timeMinutes: (json['timeMinutes'] as num?)?.toInt(),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  confidence: (json['confidence'] as num).toDouble(),
);

Map<String, dynamic> _$$StructuredRecipeCandidateImplToJson(
  _$StructuredRecipeCandidateImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'ingredientLines': instance.ingredientLines,
  'steps': instance.steps,
  'servings': instance.servings,
  'timeMinutes': instance.timeMinutes,
  'tags': instance.tags,
  'confidence': instance.confidence,
};
