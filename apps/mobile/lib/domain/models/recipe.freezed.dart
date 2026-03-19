// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Source _$SourceFromJson(Map<String, dynamic> json) {
  return _Source.fromJson(json);
}

/// @nodoc
mixin _$Source {
  /// The platform where the recipe was found.
  Platform get platform => throw _privateConstructorUsedError;

  /// The original URL, if available.
  String? get url => throw _privateConstructorUsedError;

  /// The content creator's handle (e.g., "@chefname").
  String? get creatorHandle => throw _privateConstructorUsedError;

  /// The content creator's platform-specific ID.
  String? get creatorId => throw _privateConstructorUsedError;

  /// Serializes this Source to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Source
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SourceCopyWith<Source> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SourceCopyWith<$Res> {
  factory $SourceCopyWith(Source value, $Res Function(Source) then) =
      _$SourceCopyWithImpl<$Res, Source>;
  @useResult
  $Res call({
    Platform platform,
    String? url,
    String? creatorHandle,
    String? creatorId,
  });
}

/// @nodoc
class _$SourceCopyWithImpl<$Res, $Val extends Source>
    implements $SourceCopyWith<$Res> {
  _$SourceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Source
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? platform = null,
    Object? url = freezed,
    Object? creatorHandle = freezed,
    Object? creatorId = freezed,
  }) {
    return _then(
      _value.copyWith(
            platform: null == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as Platform,
            url: freezed == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String?,
            creatorHandle: freezed == creatorHandle
                ? _value.creatorHandle
                : creatorHandle // ignore: cast_nullable_to_non_nullable
                      as String?,
            creatorId: freezed == creatorId
                ? _value.creatorId
                : creatorId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SourceImplCopyWith<$Res> implements $SourceCopyWith<$Res> {
  factory _$$SourceImplCopyWith(
    _$SourceImpl value,
    $Res Function(_$SourceImpl) then,
  ) = __$$SourceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Platform platform,
    String? url,
    String? creatorHandle,
    String? creatorId,
  });
}

/// @nodoc
class __$$SourceImplCopyWithImpl<$Res>
    extends _$SourceCopyWithImpl<$Res, _$SourceImpl>
    implements _$$SourceImplCopyWith<$Res> {
  __$$SourceImplCopyWithImpl(
    _$SourceImpl _value,
    $Res Function(_$SourceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Source
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? platform = null,
    Object? url = freezed,
    Object? creatorHandle = freezed,
    Object? creatorId = freezed,
  }) {
    return _then(
      _$SourceImpl(
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as Platform,
        url: freezed == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String?,
        creatorHandle: freezed == creatorHandle
            ? _value.creatorHandle
            : creatorHandle // ignore: cast_nullable_to_non_nullable
                  as String?,
        creatorId: freezed == creatorId
            ? _value.creatorId
            : creatorId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SourceImpl implements _Source {
  const _$SourceImpl({
    required this.platform,
    this.url,
    this.creatorHandle,
    this.creatorId,
  });

  factory _$SourceImpl.fromJson(Map<String, dynamic> json) =>
      _$$SourceImplFromJson(json);

  /// The platform where the recipe was found.
  @override
  final Platform platform;

  /// The original URL, if available.
  @override
  final String? url;

  /// The content creator's handle (e.g., "@chefname").
  @override
  final String? creatorHandle;

  /// The content creator's platform-specific ID.
  @override
  final String? creatorId;

  @override
  String toString() {
    return 'Source(platform: $platform, url: $url, creatorHandle: $creatorHandle, creatorId: $creatorId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SourceImpl &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.creatorHandle, creatorHandle) ||
                other.creatorHandle == creatorHandle) &&
            (identical(other.creatorId, creatorId) ||
                other.creatorId == creatorId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, platform, url, creatorHandle, creatorId);

  /// Create a copy of Source
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SourceImplCopyWith<_$SourceImpl> get copyWith =>
      __$$SourceImplCopyWithImpl<_$SourceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SourceImplToJson(this);
  }
}

abstract class _Source implements Source {
  const factory _Source({
    required final Platform platform,
    final String? url,
    final String? creatorHandle,
    final String? creatorId,
  }) = _$SourceImpl;

  factory _Source.fromJson(Map<String, dynamic> json) = _$SourceImpl.fromJson;

  /// The platform where the recipe was found.
  @override
  Platform get platform;

  /// The original URL, if available.
  @override
  String? get url;

  /// The content creator's handle (e.g., "@chefname").
  @override
  String? get creatorHandle;

  /// The content creator's platform-specific ID.
  @override
  String? get creatorId;

  /// Create a copy of Source
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SourceImplCopyWith<_$SourceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CoverOutput _$CoverOutputFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'sourceImage':
      return CoverOutputSourceImage.fromJson(json);
    case 'enhancedImage':
      return CoverOutputEnhancedImage.fromJson(json);
    case 'generatedCover':
      return CoverOutputGeneratedCover.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'runtimeType',
        'CoverOutput',
        'Invalid union type "${json['runtimeType']}"!',
      );
  }
}

/// @nodoc
mixin _$CoverOutput {
  /// Reference to the source image asset in R2.
  String get assetId => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String assetId) sourceImage,
    required TResult Function(String assetId) enhancedImage,
    required TResult Function(String assetId) generatedCover,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String assetId)? sourceImage,
    TResult? Function(String assetId)? enhancedImage,
    TResult? Function(String assetId)? generatedCover,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String assetId)? sourceImage,
    TResult Function(String assetId)? enhancedImage,
    TResult Function(String assetId)? generatedCover,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CoverOutputSourceImage value) sourceImage,
    required TResult Function(CoverOutputEnhancedImage value) enhancedImage,
    required TResult Function(CoverOutputGeneratedCover value) generatedCover,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CoverOutputSourceImage value)? sourceImage,
    TResult? Function(CoverOutputEnhancedImage value)? enhancedImage,
    TResult? Function(CoverOutputGeneratedCover value)? generatedCover,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CoverOutputSourceImage value)? sourceImage,
    TResult Function(CoverOutputEnhancedImage value)? enhancedImage,
    TResult Function(CoverOutputGeneratedCover value)? generatedCover,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this CoverOutput to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoverOutputCopyWith<CoverOutput> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoverOutputCopyWith<$Res> {
  factory $CoverOutputCopyWith(
    CoverOutput value,
    $Res Function(CoverOutput) then,
  ) = _$CoverOutputCopyWithImpl<$Res, CoverOutput>;
  @useResult
  $Res call({String assetId});
}

/// @nodoc
class _$CoverOutputCopyWithImpl<$Res, $Val extends CoverOutput>
    implements $CoverOutputCopyWith<$Res> {
  _$CoverOutputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? assetId = null}) {
    return _then(
      _value.copyWith(
            assetId: null == assetId
                ? _value.assetId
                : assetId // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CoverOutputSourceImageImplCopyWith<$Res>
    implements $CoverOutputCopyWith<$Res> {
  factory _$$CoverOutputSourceImageImplCopyWith(
    _$CoverOutputSourceImageImpl value,
    $Res Function(_$CoverOutputSourceImageImpl) then,
  ) = __$$CoverOutputSourceImageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String assetId});
}

/// @nodoc
class __$$CoverOutputSourceImageImplCopyWithImpl<$Res>
    extends _$CoverOutputCopyWithImpl<$Res, _$CoverOutputSourceImageImpl>
    implements _$$CoverOutputSourceImageImplCopyWith<$Res> {
  __$$CoverOutputSourceImageImplCopyWithImpl(
    _$CoverOutputSourceImageImpl _value,
    $Res Function(_$CoverOutputSourceImageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? assetId = null}) {
    return _then(
      _$CoverOutputSourceImageImpl(
        assetId: null == assetId
            ? _value.assetId
            : assetId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CoverOutputSourceImageImpl implements CoverOutputSourceImage {
  const _$CoverOutputSourceImageImpl({
    required this.assetId,
    final String? $type,
  }) : $type = $type ?? 'sourceImage';

  factory _$CoverOutputSourceImageImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoverOutputSourceImageImplFromJson(json);

  /// Reference to the source image asset in R2.
  @override
  final String assetId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'CoverOutput.sourceImage(assetId: $assetId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverOutputSourceImageImpl &&
            (identical(other.assetId, assetId) || other.assetId == assetId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, assetId);

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverOutputSourceImageImplCopyWith<_$CoverOutputSourceImageImpl>
  get copyWith =>
      __$$CoverOutputSourceImageImplCopyWithImpl<_$CoverOutputSourceImageImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String assetId) sourceImage,
    required TResult Function(String assetId) enhancedImage,
    required TResult Function(String assetId) generatedCover,
  }) {
    return sourceImage(assetId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String assetId)? sourceImage,
    TResult? Function(String assetId)? enhancedImage,
    TResult? Function(String assetId)? generatedCover,
  }) {
    return sourceImage?.call(assetId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String assetId)? sourceImage,
    TResult Function(String assetId)? enhancedImage,
    TResult Function(String assetId)? generatedCover,
    required TResult orElse(),
  }) {
    if (sourceImage != null) {
      return sourceImage(assetId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CoverOutputSourceImage value) sourceImage,
    required TResult Function(CoverOutputEnhancedImage value) enhancedImage,
    required TResult Function(CoverOutputGeneratedCover value) generatedCover,
  }) {
    return sourceImage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CoverOutputSourceImage value)? sourceImage,
    TResult? Function(CoverOutputEnhancedImage value)? enhancedImage,
    TResult? Function(CoverOutputGeneratedCover value)? generatedCover,
  }) {
    return sourceImage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CoverOutputSourceImage value)? sourceImage,
    TResult Function(CoverOutputEnhancedImage value)? enhancedImage,
    TResult Function(CoverOutputGeneratedCover value)? generatedCover,
    required TResult orElse(),
  }) {
    if (sourceImage != null) {
      return sourceImage(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CoverOutputSourceImageImplToJson(this);
  }
}

abstract class CoverOutputSourceImage implements CoverOutput {
  const factory CoverOutputSourceImage({required final String assetId}) =
      _$CoverOutputSourceImageImpl;

  factory CoverOutputSourceImage.fromJson(Map<String, dynamic> json) =
      _$CoverOutputSourceImageImpl.fromJson;

  /// Reference to the source image asset in R2.
  @override
  String get assetId;

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoverOutputSourceImageImplCopyWith<_$CoverOutputSourceImageImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CoverOutputEnhancedImageImplCopyWith<$Res>
    implements $CoverOutputCopyWith<$Res> {
  factory _$$CoverOutputEnhancedImageImplCopyWith(
    _$CoverOutputEnhancedImageImpl value,
    $Res Function(_$CoverOutputEnhancedImageImpl) then,
  ) = __$$CoverOutputEnhancedImageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String assetId});
}

/// @nodoc
class __$$CoverOutputEnhancedImageImplCopyWithImpl<$Res>
    extends _$CoverOutputCopyWithImpl<$Res, _$CoverOutputEnhancedImageImpl>
    implements _$$CoverOutputEnhancedImageImplCopyWith<$Res> {
  __$$CoverOutputEnhancedImageImplCopyWithImpl(
    _$CoverOutputEnhancedImageImpl _value,
    $Res Function(_$CoverOutputEnhancedImageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? assetId = null}) {
    return _then(
      _$CoverOutputEnhancedImageImpl(
        assetId: null == assetId
            ? _value.assetId
            : assetId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CoverOutputEnhancedImageImpl implements CoverOutputEnhancedImage {
  const _$CoverOutputEnhancedImageImpl({
    required this.assetId,
    final String? $type,
  }) : $type = $type ?? 'enhancedImage';

  factory _$CoverOutputEnhancedImageImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoverOutputEnhancedImageImplFromJson(json);

  /// Reference to the enhanced image asset in R2.
  @override
  final String assetId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'CoverOutput.enhancedImage(assetId: $assetId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverOutputEnhancedImageImpl &&
            (identical(other.assetId, assetId) || other.assetId == assetId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, assetId);

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverOutputEnhancedImageImplCopyWith<_$CoverOutputEnhancedImageImpl>
  get copyWith =>
      __$$CoverOutputEnhancedImageImplCopyWithImpl<
        _$CoverOutputEnhancedImageImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String assetId) sourceImage,
    required TResult Function(String assetId) enhancedImage,
    required TResult Function(String assetId) generatedCover,
  }) {
    return enhancedImage(assetId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String assetId)? sourceImage,
    TResult? Function(String assetId)? enhancedImage,
    TResult? Function(String assetId)? generatedCover,
  }) {
    return enhancedImage?.call(assetId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String assetId)? sourceImage,
    TResult Function(String assetId)? enhancedImage,
    TResult Function(String assetId)? generatedCover,
    required TResult orElse(),
  }) {
    if (enhancedImage != null) {
      return enhancedImage(assetId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CoverOutputSourceImage value) sourceImage,
    required TResult Function(CoverOutputEnhancedImage value) enhancedImage,
    required TResult Function(CoverOutputGeneratedCover value) generatedCover,
  }) {
    return enhancedImage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CoverOutputSourceImage value)? sourceImage,
    TResult? Function(CoverOutputEnhancedImage value)? enhancedImage,
    TResult? Function(CoverOutputGeneratedCover value)? generatedCover,
  }) {
    return enhancedImage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CoverOutputSourceImage value)? sourceImage,
    TResult Function(CoverOutputEnhancedImage value)? enhancedImage,
    TResult Function(CoverOutputGeneratedCover value)? generatedCover,
    required TResult orElse(),
  }) {
    if (enhancedImage != null) {
      return enhancedImage(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CoverOutputEnhancedImageImplToJson(this);
  }
}

abstract class CoverOutputEnhancedImage implements CoverOutput {
  const factory CoverOutputEnhancedImage({required final String assetId}) =
      _$CoverOutputEnhancedImageImpl;

  factory CoverOutputEnhancedImage.fromJson(Map<String, dynamic> json) =
      _$CoverOutputEnhancedImageImpl.fromJson;

  /// Reference to the enhanced image asset in R2.
  @override
  String get assetId;

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoverOutputEnhancedImageImplCopyWith<_$CoverOutputEnhancedImageImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CoverOutputGeneratedCoverImplCopyWith<$Res>
    implements $CoverOutputCopyWith<$Res> {
  factory _$$CoverOutputGeneratedCoverImplCopyWith(
    _$CoverOutputGeneratedCoverImpl value,
    $Res Function(_$CoverOutputGeneratedCoverImpl) then,
  ) = __$$CoverOutputGeneratedCoverImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String assetId});
}

/// @nodoc
class __$$CoverOutputGeneratedCoverImplCopyWithImpl<$Res>
    extends _$CoverOutputCopyWithImpl<$Res, _$CoverOutputGeneratedCoverImpl>
    implements _$$CoverOutputGeneratedCoverImplCopyWith<$Res> {
  __$$CoverOutputGeneratedCoverImplCopyWithImpl(
    _$CoverOutputGeneratedCoverImpl _value,
    $Res Function(_$CoverOutputGeneratedCoverImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? assetId = null}) {
    return _then(
      _$CoverOutputGeneratedCoverImpl(
        assetId: null == assetId
            ? _value.assetId
            : assetId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CoverOutputGeneratedCoverImpl implements CoverOutputGeneratedCover {
  const _$CoverOutputGeneratedCoverImpl({
    required this.assetId,
    final String? $type,
  }) : $type = $type ?? 'generatedCover';

  factory _$CoverOutputGeneratedCoverImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoverOutputGeneratedCoverImplFromJson(json);

  /// Reference to the generated cover asset in R2.
  @override
  final String assetId;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'CoverOutput.generatedCover(assetId: $assetId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoverOutputGeneratedCoverImpl &&
            (identical(other.assetId, assetId) || other.assetId == assetId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, assetId);

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoverOutputGeneratedCoverImplCopyWith<_$CoverOutputGeneratedCoverImpl>
  get copyWith =>
      __$$CoverOutputGeneratedCoverImplCopyWithImpl<
        _$CoverOutputGeneratedCoverImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String assetId) sourceImage,
    required TResult Function(String assetId) enhancedImage,
    required TResult Function(String assetId) generatedCover,
  }) {
    return generatedCover(assetId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String assetId)? sourceImage,
    TResult? Function(String assetId)? enhancedImage,
    TResult? Function(String assetId)? generatedCover,
  }) {
    return generatedCover?.call(assetId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String assetId)? sourceImage,
    TResult Function(String assetId)? enhancedImage,
    TResult Function(String assetId)? generatedCover,
    required TResult orElse(),
  }) {
    if (generatedCover != null) {
      return generatedCover(assetId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CoverOutputSourceImage value) sourceImage,
    required TResult Function(CoverOutputEnhancedImage value) enhancedImage,
    required TResult Function(CoverOutputGeneratedCover value) generatedCover,
  }) {
    return generatedCover(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CoverOutputSourceImage value)? sourceImage,
    TResult? Function(CoverOutputEnhancedImage value)? enhancedImage,
    TResult? Function(CoverOutputGeneratedCover value)? generatedCover,
  }) {
    return generatedCover?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CoverOutputSourceImage value)? sourceImage,
    TResult Function(CoverOutputEnhancedImage value)? enhancedImage,
    TResult Function(CoverOutputGeneratedCover value)? generatedCover,
    required TResult orElse(),
  }) {
    if (generatedCover != null) {
      return generatedCover(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CoverOutputGeneratedCoverImplToJson(this);
  }
}

abstract class CoverOutputGeneratedCover implements CoverOutput {
  const factory CoverOutputGeneratedCover({required final String assetId}) =
      _$CoverOutputGeneratedCoverImpl;

  factory CoverOutputGeneratedCover.fromJson(Map<String, dynamic> json) =
      _$CoverOutputGeneratedCoverImpl.fromJson;

  /// Reference to the generated cover asset in R2.
  @override
  String get assetId;

  /// Create a copy of CoverOutput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoverOutputGeneratedCoverImplCopyWith<_$CoverOutputGeneratedCoverImpl>
  get copyWith => throw _privateConstructorUsedError;
}

Step _$StepFromJson(Map<String, dynamic> json) {
  return _Step.fromJson(json);
}

/// @nodoc
mixin _$Step {
  /// The 1-based step number.
  int get number => throw _privateConstructorUsedError;

  /// The instruction text for this step.
  String get instruction => throw _privateConstructorUsedError;

  /// Duration in minutes for this step, if applicable.
  int? get timeMinutes => throw _privateConstructorUsedError;

  /// Serializes this Step to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Step
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StepCopyWith<Step> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StepCopyWith<$Res> {
  factory $StepCopyWith(Step value, $Res Function(Step) then) =
      _$StepCopyWithImpl<$Res, Step>;
  @useResult
  $Res call({int number, String instruction, int? timeMinutes});
}

/// @nodoc
class _$StepCopyWithImpl<$Res, $Val extends Step>
    implements $StepCopyWith<$Res> {
  _$StepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Step
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? instruction = null,
    Object? timeMinutes = freezed,
  }) {
    return _then(
      _value.copyWith(
            number: null == number
                ? _value.number
                : number // ignore: cast_nullable_to_non_nullable
                      as int,
            instruction: null == instruction
                ? _value.instruction
                : instruction // ignore: cast_nullable_to_non_nullable
                      as String,
            timeMinutes: freezed == timeMinutes
                ? _value.timeMinutes
                : timeMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StepImplCopyWith<$Res> implements $StepCopyWith<$Res> {
  factory _$$StepImplCopyWith(
    _$StepImpl value,
    $Res Function(_$StepImpl) then,
  ) = __$$StepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int number, String instruction, int? timeMinutes});
}

/// @nodoc
class __$$StepImplCopyWithImpl<$Res>
    extends _$StepCopyWithImpl<$Res, _$StepImpl>
    implements _$$StepImplCopyWith<$Res> {
  __$$StepImplCopyWithImpl(_$StepImpl _value, $Res Function(_$StepImpl) _then)
    : super(_value, _then);

  /// Create a copy of Step
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? number = null,
    Object? instruction = null,
    Object? timeMinutes = freezed,
  }) {
    return _then(
      _$StepImpl(
        number: null == number
            ? _value.number
            : number // ignore: cast_nullable_to_non_nullable
                  as int,
        instruction: null == instruction
            ? _value.instruction
            : instruction // ignore: cast_nullable_to_non_nullable
                  as String,
        timeMinutes: freezed == timeMinutes
            ? _value.timeMinutes
            : timeMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StepImpl implements _Step {
  const _$StepImpl({
    required this.number,
    required this.instruction,
    this.timeMinutes,
  });

  factory _$StepImpl.fromJson(Map<String, dynamic> json) =>
      _$$StepImplFromJson(json);

  /// The 1-based step number.
  @override
  final int number;

  /// The instruction text for this step.
  @override
  final String instruction;

  /// Duration in minutes for this step, if applicable.
  @override
  final int? timeMinutes;

  @override
  String toString() {
    return 'Step(number: $number, instruction: $instruction, timeMinutes: $timeMinutes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StepImpl &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.instruction, instruction) ||
                other.instruction == instruction) &&
            (identical(other.timeMinutes, timeMinutes) ||
                other.timeMinutes == timeMinutes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, number, instruction, timeMinutes);

  /// Create a copy of Step
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StepImplCopyWith<_$StepImpl> get copyWith =>
      __$$StepImplCopyWithImpl<_$StepImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StepImplToJson(this);
  }
}

abstract class _Step implements Step {
  const factory _Step({
    required final int number,
    required final String instruction,
    final int? timeMinutes,
  }) = _$StepImpl;

  factory _Step.fromJson(Map<String, dynamic> json) = _$StepImpl.fromJson;

  /// The 1-based step number.
  @override
  int get number;

  /// The instruction text for this step.
  @override
  String get instruction;

  /// Duration in minutes for this step, if applicable.
  @override
  int? get timeMinutes;

  /// Create a copy of Step
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StepImplCopyWith<_$StepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ResolvedRecipe _$ResolvedRecipeFromJson(Map<String, dynamic> json) {
  return _ResolvedRecipe.fromJson(json);
}

/// @nodoc
mixin _$ResolvedRecipe {
  /// Unique identifier for this recipe.
  String get id => throw _privateConstructorUsedError;

  /// The recipe title.
  String get title => throw _privateConstructorUsedError;

  /// Resolved ingredients with food database matches.
  List<ResolvedIngredient> get ingredients =>
      throw _privateConstructorUsedError;

  /// Ordered recipe steps.
  List<Step> get steps => throw _privateConstructorUsedError;

  /// Number of servings, if known.
  int? get servings => throw _privateConstructorUsedError;

  /// Total time in minutes, if known.
  int? get timeMinutes => throw _privateConstructorUsedError;

  /// Attribution to the original source.
  Source get source => throw _privateConstructorUsedError;

  /// Computed nutrition information.
  NutritionComputation get nutrition => throw _privateConstructorUsedError;

  /// Cover image for the recipe.
  CoverOutput get cover => throw _privateConstructorUsedError;

  /// Tags or categories for the recipe.
  List<String> get tags => throw _privateConstructorUsedError;

  /// Serializes this ResolvedRecipe to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ResolvedRecipe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResolvedRecipeCopyWith<ResolvedRecipe> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResolvedRecipeCopyWith<$Res> {
  factory $ResolvedRecipeCopyWith(
    ResolvedRecipe value,
    $Res Function(ResolvedRecipe) then,
  ) = _$ResolvedRecipeCopyWithImpl<$Res, ResolvedRecipe>;
  @useResult
  $Res call({
    String id,
    String title,
    List<ResolvedIngredient> ingredients,
    List<Step> steps,
    int? servings,
    int? timeMinutes,
    Source source,
    NutritionComputation nutrition,
    CoverOutput cover,
    List<String> tags,
  });

  $SourceCopyWith<$Res> get source;
  $NutritionComputationCopyWith<$Res> get nutrition;
  $CoverOutputCopyWith<$Res> get cover;
}

/// @nodoc
class _$ResolvedRecipeCopyWithImpl<$Res, $Val extends ResolvedRecipe>
    implements $ResolvedRecipeCopyWith<$Res> {
  _$ResolvedRecipeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ResolvedRecipe
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? ingredients = null,
    Object? steps = null,
    Object? servings = freezed,
    Object? timeMinutes = freezed,
    Object? source = null,
    Object? nutrition = null,
    Object? cover = null,
    Object? tags = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            ingredients: null == ingredients
                ? _value.ingredients
                : ingredients // ignore: cast_nullable_to_non_nullable
                      as List<ResolvedIngredient>,
            steps: null == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                      as List<Step>,
            servings: freezed == servings
                ? _value.servings
                : servings // ignore: cast_nullable_to_non_nullable
                      as int?,
            timeMinutes: freezed == timeMinutes
                ? _value.timeMinutes
                : timeMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as Source,
            nutrition: null == nutrition
                ? _value.nutrition
                : nutrition // ignore: cast_nullable_to_non_nullable
                      as NutritionComputation,
            cover: null == cover
                ? _value.cover
                : cover // ignore: cast_nullable_to_non_nullable
                      as CoverOutput,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }

  /// Create a copy of ResolvedRecipe
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SourceCopyWith<$Res> get source {
    return $SourceCopyWith<$Res>(_value.source, (value) {
      return _then(_value.copyWith(source: value) as $Val);
    });
  }

  /// Create a copy of ResolvedRecipe
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NutritionComputationCopyWith<$Res> get nutrition {
    return $NutritionComputationCopyWith<$Res>(_value.nutrition, (value) {
      return _then(_value.copyWith(nutrition: value) as $Val);
    });
  }

  /// Create a copy of ResolvedRecipe
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CoverOutputCopyWith<$Res> get cover {
    return $CoverOutputCopyWith<$Res>(_value.cover, (value) {
      return _then(_value.copyWith(cover: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ResolvedRecipeImplCopyWith<$Res>
    implements $ResolvedRecipeCopyWith<$Res> {
  factory _$$ResolvedRecipeImplCopyWith(
    _$ResolvedRecipeImpl value,
    $Res Function(_$ResolvedRecipeImpl) then,
  ) = __$$ResolvedRecipeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    List<ResolvedIngredient> ingredients,
    List<Step> steps,
    int? servings,
    int? timeMinutes,
    Source source,
    NutritionComputation nutrition,
    CoverOutput cover,
    List<String> tags,
  });

  @override
  $SourceCopyWith<$Res> get source;
  @override
  $NutritionComputationCopyWith<$Res> get nutrition;
  @override
  $CoverOutputCopyWith<$Res> get cover;
}

/// @nodoc
class __$$ResolvedRecipeImplCopyWithImpl<$Res>
    extends _$ResolvedRecipeCopyWithImpl<$Res, _$ResolvedRecipeImpl>
    implements _$$ResolvedRecipeImplCopyWith<$Res> {
  __$$ResolvedRecipeImplCopyWithImpl(
    _$ResolvedRecipeImpl _value,
    $Res Function(_$ResolvedRecipeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ResolvedRecipe
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? ingredients = null,
    Object? steps = null,
    Object? servings = freezed,
    Object? timeMinutes = freezed,
    Object? source = null,
    Object? nutrition = null,
    Object? cover = null,
    Object? tags = null,
  }) {
    return _then(
      _$ResolvedRecipeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        ingredients: null == ingredients
            ? _value._ingredients
            : ingredients // ignore: cast_nullable_to_non_nullable
                  as List<ResolvedIngredient>,
        steps: null == steps
            ? _value._steps
            : steps // ignore: cast_nullable_to_non_nullable
                  as List<Step>,
        servings: freezed == servings
            ? _value.servings
            : servings // ignore: cast_nullable_to_non_nullable
                  as int?,
        timeMinutes: freezed == timeMinutes
            ? _value.timeMinutes
            : timeMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as Source,
        nutrition: null == nutrition
            ? _value.nutrition
            : nutrition // ignore: cast_nullable_to_non_nullable
                  as NutritionComputation,
        cover: null == cover
            ? _value.cover
            : cover // ignore: cast_nullable_to_non_nullable
                  as CoverOutput,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ResolvedRecipeImpl implements _ResolvedRecipe {
  const _$ResolvedRecipeImpl({
    required this.id,
    required this.title,
    required final List<ResolvedIngredient> ingredients,
    required final List<Step> steps,
    this.servings,
    this.timeMinutes,
    required this.source,
    required this.nutrition,
    required this.cover,
    required final List<String> tags,
  }) : _ingredients = ingredients,
       _steps = steps,
       _tags = tags;

  factory _$ResolvedRecipeImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResolvedRecipeImplFromJson(json);

  /// Unique identifier for this recipe.
  @override
  final String id;

  /// The recipe title.
  @override
  final String title;

  /// Resolved ingredients with food database matches.
  final List<ResolvedIngredient> _ingredients;

  /// Resolved ingredients with food database matches.
  @override
  List<ResolvedIngredient> get ingredients {
    if (_ingredients is EqualUnmodifiableListView) return _ingredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ingredients);
  }

  /// Ordered recipe steps.
  final List<Step> _steps;

  /// Ordered recipe steps.
  @override
  List<Step> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  /// Number of servings, if known.
  @override
  final int? servings;

  /// Total time in minutes, if known.
  @override
  final int? timeMinutes;

  /// Attribution to the original source.
  @override
  final Source source;

  /// Computed nutrition information.
  @override
  final NutritionComputation nutrition;

  /// Cover image for the recipe.
  @override
  final CoverOutput cover;

  /// Tags or categories for the recipe.
  final List<String> _tags;

  /// Tags or categories for the recipe.
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  String toString() {
    return 'ResolvedRecipe(id: $id, title: $title, ingredients: $ingredients, steps: $steps, servings: $servings, timeMinutes: $timeMinutes, source: $source, nutrition: $nutrition, cover: $cover, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResolvedRecipeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(
              other._ingredients,
              _ingredients,
            ) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            (identical(other.servings, servings) ||
                other.servings == servings) &&
            (identical(other.timeMinutes, timeMinutes) ||
                other.timeMinutes == timeMinutes) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.nutrition, nutrition) ||
                other.nutrition == nutrition) &&
            (identical(other.cover, cover) || other.cover == cover) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    const DeepCollectionEquality().hash(_ingredients),
    const DeepCollectionEquality().hash(_steps),
    servings,
    timeMinutes,
    source,
    nutrition,
    cover,
    const DeepCollectionEquality().hash(_tags),
  );

  /// Create a copy of ResolvedRecipe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResolvedRecipeImplCopyWith<_$ResolvedRecipeImpl> get copyWith =>
      __$$ResolvedRecipeImplCopyWithImpl<_$ResolvedRecipeImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ResolvedRecipeImplToJson(this);
  }
}

abstract class _ResolvedRecipe implements ResolvedRecipe {
  const factory _ResolvedRecipe({
    required final String id,
    required final String title,
    required final List<ResolvedIngredient> ingredients,
    required final List<Step> steps,
    final int? servings,
    final int? timeMinutes,
    required final Source source,
    required final NutritionComputation nutrition,
    required final CoverOutput cover,
    required final List<String> tags,
  }) = _$ResolvedRecipeImpl;

  factory _ResolvedRecipe.fromJson(Map<String, dynamic> json) =
      _$ResolvedRecipeImpl.fromJson;

  /// Unique identifier for this recipe.
  @override
  String get id;

  /// The recipe title.
  @override
  String get title;

  /// Resolved ingredients with food database matches.
  @override
  List<ResolvedIngredient> get ingredients;

  /// Ordered recipe steps.
  @override
  List<Step> get steps;

  /// Number of servings, if known.
  @override
  int? get servings;

  /// Total time in minutes, if known.
  @override
  int? get timeMinutes;

  /// Attribution to the original source.
  @override
  Source get source;

  /// Computed nutrition information.
  @override
  NutritionComputation get nutrition;

  /// Cover image for the recipe.
  @override
  CoverOutput get cover;

  /// Tags or categories for the recipe.
  @override
  List<String> get tags;

  /// Create a copy of ResolvedRecipe
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResolvedRecipeImplCopyWith<_$ResolvedRecipeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserRecipeView _$UserRecipeViewFromJson(Map<String, dynamic> json) {
  return _UserRecipeView.fromJson(json);
}

/// @nodoc
mixin _$UserRecipeView {
  /// The recipe this view belongs to.
  String get recipeId => throw _privateConstructorUsedError;

  /// The user who owns this view.
  String get userId => throw _privateConstructorUsedError;

  /// Whether the user has saved this recipe.
  bool get saved => throw _privateConstructorUsedError;

  /// Whether the user has favorited this recipe.
  bool get favorite => throw _privateConstructorUsedError;

  /// User's personal notes about the recipe.
  String? get notes => throw _privateConstructorUsedError;

  /// User edits to the canonical recipe.
  List<RecipePatch> get patches => throw _privateConstructorUsedError;

  /// Serializes this UserRecipeView to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserRecipeView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserRecipeViewCopyWith<UserRecipeView> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserRecipeViewCopyWith<$Res> {
  factory $UserRecipeViewCopyWith(
    UserRecipeView value,
    $Res Function(UserRecipeView) then,
  ) = _$UserRecipeViewCopyWithImpl<$Res, UserRecipeView>;
  @useResult
  $Res call({
    String recipeId,
    String userId,
    bool saved,
    bool favorite,
    String? notes,
    List<RecipePatch> patches,
  });
}

/// @nodoc
class _$UserRecipeViewCopyWithImpl<$Res, $Val extends UserRecipeView>
    implements $UserRecipeViewCopyWith<$Res> {
  _$UserRecipeViewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserRecipeView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipeId = null,
    Object? userId = null,
    Object? saved = null,
    Object? favorite = null,
    Object? notes = freezed,
    Object? patches = null,
  }) {
    return _then(
      _value.copyWith(
            recipeId: null == recipeId
                ? _value.recipeId
                : recipeId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            saved: null == saved
                ? _value.saved
                : saved // ignore: cast_nullable_to_non_nullable
                      as bool,
            favorite: null == favorite
                ? _value.favorite
                : favorite // ignore: cast_nullable_to_non_nullable
                      as bool,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            patches: null == patches
                ? _value.patches
                : patches // ignore: cast_nullable_to_non_nullable
                      as List<RecipePatch>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserRecipeViewImplCopyWith<$Res>
    implements $UserRecipeViewCopyWith<$Res> {
  factory _$$UserRecipeViewImplCopyWith(
    _$UserRecipeViewImpl value,
    $Res Function(_$UserRecipeViewImpl) then,
  ) = __$$UserRecipeViewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String recipeId,
    String userId,
    bool saved,
    bool favorite,
    String? notes,
    List<RecipePatch> patches,
  });
}

/// @nodoc
class __$$UserRecipeViewImplCopyWithImpl<$Res>
    extends _$UserRecipeViewCopyWithImpl<$Res, _$UserRecipeViewImpl>
    implements _$$UserRecipeViewImplCopyWith<$Res> {
  __$$UserRecipeViewImplCopyWithImpl(
    _$UserRecipeViewImpl _value,
    $Res Function(_$UserRecipeViewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserRecipeView
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipeId = null,
    Object? userId = null,
    Object? saved = null,
    Object? favorite = null,
    Object? notes = freezed,
    Object? patches = null,
  }) {
    return _then(
      _$UserRecipeViewImpl(
        recipeId: null == recipeId
            ? _value.recipeId
            : recipeId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        saved: null == saved
            ? _value.saved
            : saved // ignore: cast_nullable_to_non_nullable
                  as bool,
        favorite: null == favorite
            ? _value.favorite
            : favorite // ignore: cast_nullable_to_non_nullable
                  as bool,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        patches: null == patches
            ? _value._patches
            : patches // ignore: cast_nullable_to_non_nullable
                  as List<RecipePatch>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserRecipeViewImpl implements _UserRecipeView {
  const _$UserRecipeViewImpl({
    required this.recipeId,
    required this.userId,
    required this.saved,
    required this.favorite,
    this.notes,
    required final List<RecipePatch> patches,
  }) : _patches = patches;

  factory _$UserRecipeViewImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserRecipeViewImplFromJson(json);

  /// The recipe this view belongs to.
  @override
  final String recipeId;

  /// The user who owns this view.
  @override
  final String userId;

  /// Whether the user has saved this recipe.
  @override
  final bool saved;

  /// Whether the user has favorited this recipe.
  @override
  final bool favorite;

  /// User's personal notes about the recipe.
  @override
  final String? notes;

  /// User edits to the canonical recipe.
  final List<RecipePatch> _patches;

  /// User edits to the canonical recipe.
  @override
  List<RecipePatch> get patches {
    if (_patches is EqualUnmodifiableListView) return _patches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_patches);
  }

  @override
  String toString() {
    return 'UserRecipeView(recipeId: $recipeId, userId: $userId, saved: $saved, favorite: $favorite, notes: $notes, patches: $patches)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserRecipeViewImpl &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.saved, saved) || other.saved == saved) &&
            (identical(other.favorite, favorite) ||
                other.favorite == favorite) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality().equals(other._patches, _patches));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    recipeId,
    userId,
    saved,
    favorite,
    notes,
    const DeepCollectionEquality().hash(_patches),
  );

  /// Create a copy of UserRecipeView
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserRecipeViewImplCopyWith<_$UserRecipeViewImpl> get copyWith =>
      __$$UserRecipeViewImplCopyWithImpl<_$UserRecipeViewImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserRecipeViewImplToJson(this);
  }
}

abstract class _UserRecipeView implements UserRecipeView {
  const factory _UserRecipeView({
    required final String recipeId,
    required final String userId,
    required final bool saved,
    required final bool favorite,
    final String? notes,
    required final List<RecipePatch> patches,
  }) = _$UserRecipeViewImpl;

  factory _UserRecipeView.fromJson(Map<String, dynamic> json) =
      _$UserRecipeViewImpl.fromJson;

  /// The recipe this view belongs to.
  @override
  String get recipeId;

  /// The user who owns this view.
  @override
  String get userId;

  /// Whether the user has saved this recipe.
  @override
  bool get saved;

  /// Whether the user has favorited this recipe.
  @override
  bool get favorite;

  /// User's personal notes about the recipe.
  @override
  String? get notes;

  /// User edits to the canonical recipe.
  @override
  List<RecipePatch> get patches;

  /// Create a copy of UserRecipeView
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserRecipeViewImplCopyWith<_$UserRecipeViewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipePatch _$RecipePatchFromJson(Map<String, dynamic> json) {
  return _RecipePatch.fromJson(json);
}

/// @nodoc
mixin _$RecipePatch {
  /// The field being patched (e.g., "title", "servings").
  String get field => throw _privateConstructorUsedError;

  /// The new value for the field, as a JSON value.
  Object get value => throw _privateConstructorUsedError;

  /// ISO-8601 timestamp of when the patch was created.
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this RecipePatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecipePatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipePatchCopyWith<RecipePatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipePatchCopyWith<$Res> {
  factory $RecipePatchCopyWith(
    RecipePatch value,
    $Res Function(RecipePatch) then,
  ) = _$RecipePatchCopyWithImpl<$Res, RecipePatch>;
  @useResult
  $Res call({String field, Object value, String createdAt});
}

/// @nodoc
class _$RecipePatchCopyWithImpl<$Res, $Val extends RecipePatch>
    implements $RecipePatchCopyWith<$Res> {
  _$RecipePatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecipePatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field = null,
    Object? value = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            field: null == field
                ? _value.field
                : field // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value ? _value.value : value,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecipePatchImplCopyWith<$Res>
    implements $RecipePatchCopyWith<$Res> {
  factory _$$RecipePatchImplCopyWith(
    _$RecipePatchImpl value,
    $Res Function(_$RecipePatchImpl) then,
  ) = __$$RecipePatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String field, Object value, String createdAt});
}

/// @nodoc
class __$$RecipePatchImplCopyWithImpl<$Res>
    extends _$RecipePatchCopyWithImpl<$Res, _$RecipePatchImpl>
    implements _$$RecipePatchImplCopyWith<$Res> {
  __$$RecipePatchImplCopyWithImpl(
    _$RecipePatchImpl _value,
    $Res Function(_$RecipePatchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecipePatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field = null,
    Object? value = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$RecipePatchImpl(
        field: null == field
            ? _value.field
            : field // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value ? _value.value : value,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipePatchImpl implements _RecipePatch {
  const _$RecipePatchImpl({
    required this.field,
    required this.value,
    required this.createdAt,
  });

  factory _$RecipePatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipePatchImplFromJson(json);

  /// The field being patched (e.g., "title", "servings").
  @override
  final String field;

  /// The new value for the field, as a JSON value.
  @override
  final Object value;

  /// ISO-8601 timestamp of when the patch was created.
  @override
  final String createdAt;

  @override
  String toString() {
    return 'RecipePatch(field: $field, value: $value, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipePatchImpl &&
            (identical(other.field, field) || other.field == field) &&
            const DeepCollectionEquality().equals(other.value, value) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    field,
    const DeepCollectionEquality().hash(value),
    createdAt,
  );

  /// Create a copy of RecipePatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipePatchImplCopyWith<_$RecipePatchImpl> get copyWith =>
      __$$RecipePatchImplCopyWithImpl<_$RecipePatchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipePatchImplToJson(this);
  }
}

abstract class _RecipePatch implements RecipePatch {
  const factory _RecipePatch({
    required final String field,
    required final Object value,
    required final String createdAt,
  }) = _$RecipePatchImpl;

  factory _RecipePatch.fromJson(Map<String, dynamic> json) =
      _$RecipePatchImpl.fromJson;

  /// The field being patched (e.g., "title", "servings").
  @override
  String get field;

  /// The new value for the field, as a JSON value.
  @override
  Object get value;

  /// ISO-8601 timestamp of when the patch was created.
  @override
  String get createdAt;

  /// Create a copy of RecipePatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipePatchImplCopyWith<_$RecipePatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
