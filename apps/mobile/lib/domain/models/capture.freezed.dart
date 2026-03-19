// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'capture.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CaptureInput _$CaptureInputFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'socialLink':
      return CaptureInputSocialLink.fromJson(json);
    case 'screenshot':
      return CaptureInputScreenshot.fromJson(json);
    case 'scan':
      return CaptureInputScan.fromJson(json);
    case 'speech':
      return CaptureInputSpeech.fromJson(json);
    case 'manual':
      return CaptureInputManual.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'runtimeType',
        'CaptureInput',
        'Invalid union type "${json['runtimeType']}"!',
      );
  }
}

/// @nodoc
mixin _$CaptureInput {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String url) socialLink,
    required TResult Function(String image) screenshot,
    required TResult Function(String image) scan,
    required TResult Function(String transcript) speech,
    required TResult Function(String text) manual,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String url)? socialLink,
    TResult? Function(String image)? screenshot,
    TResult? Function(String image)? scan,
    TResult? Function(String transcript)? speech,
    TResult? Function(String text)? manual,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String url)? socialLink,
    TResult Function(String image)? screenshot,
    TResult Function(String image)? scan,
    TResult Function(String transcript)? speech,
    TResult Function(String text)? manual,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CaptureInputSocialLink value) socialLink,
    required TResult Function(CaptureInputScreenshot value) screenshot,
    required TResult Function(CaptureInputScan value) scan,
    required TResult Function(CaptureInputSpeech value) speech,
    required TResult Function(CaptureInputManual value) manual,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CaptureInputSocialLink value)? socialLink,
    TResult? Function(CaptureInputScreenshot value)? screenshot,
    TResult? Function(CaptureInputScan value)? scan,
    TResult? Function(CaptureInputSpeech value)? speech,
    TResult? Function(CaptureInputManual value)? manual,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CaptureInputSocialLink value)? socialLink,
    TResult Function(CaptureInputScreenshot value)? screenshot,
    TResult Function(CaptureInputScan value)? scan,
    TResult Function(CaptureInputSpeech value)? speech,
    TResult Function(CaptureInputManual value)? manual,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this CaptureInput to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CaptureInputCopyWith<$Res> {
  factory $CaptureInputCopyWith(
    CaptureInput value,
    $Res Function(CaptureInput) then,
  ) = _$CaptureInputCopyWithImpl<$Res, CaptureInput>;
}

/// @nodoc
class _$CaptureInputCopyWithImpl<$Res, $Val extends CaptureInput>
    implements $CaptureInputCopyWith<$Res> {
  _$CaptureInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$CaptureInputSocialLinkImplCopyWith<$Res> {
  factory _$$CaptureInputSocialLinkImplCopyWith(
    _$CaptureInputSocialLinkImpl value,
    $Res Function(_$CaptureInputSocialLinkImpl) then,
  ) = __$$CaptureInputSocialLinkImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String url});
}

/// @nodoc
class __$$CaptureInputSocialLinkImplCopyWithImpl<$Res>
    extends _$CaptureInputCopyWithImpl<$Res, _$CaptureInputSocialLinkImpl>
    implements _$$CaptureInputSocialLinkImplCopyWith<$Res> {
  __$$CaptureInputSocialLinkImplCopyWithImpl(
    _$CaptureInputSocialLinkImpl _value,
    $Res Function(_$CaptureInputSocialLinkImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? url = null}) {
    return _then(
      _$CaptureInputSocialLinkImpl(
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CaptureInputSocialLinkImpl implements CaptureInputSocialLink {
  const _$CaptureInputSocialLinkImpl({required this.url, final String? $type})
    : $type = $type ?? 'socialLink';

  factory _$CaptureInputSocialLinkImpl.fromJson(Map<String, dynamic> json) =>
      _$$CaptureInputSocialLinkImplFromJson(json);

  /// The URL of the social media post or recipe page.
  @override
  final String url;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'CaptureInput.socialLink(url: $url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CaptureInputSocialLinkImpl &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, url);

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CaptureInputSocialLinkImplCopyWith<_$CaptureInputSocialLinkImpl>
  get copyWith =>
      __$$CaptureInputSocialLinkImplCopyWithImpl<_$CaptureInputSocialLinkImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String url) socialLink,
    required TResult Function(String image) screenshot,
    required TResult Function(String image) scan,
    required TResult Function(String transcript) speech,
    required TResult Function(String text) manual,
  }) {
    return socialLink(url);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String url)? socialLink,
    TResult? Function(String image)? screenshot,
    TResult? Function(String image)? scan,
    TResult? Function(String transcript)? speech,
    TResult? Function(String text)? manual,
  }) {
    return socialLink?.call(url);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String url)? socialLink,
    TResult Function(String image)? screenshot,
    TResult Function(String image)? scan,
    TResult Function(String transcript)? speech,
    TResult Function(String text)? manual,
    required TResult orElse(),
  }) {
    if (socialLink != null) {
      return socialLink(url);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CaptureInputSocialLink value) socialLink,
    required TResult Function(CaptureInputScreenshot value) screenshot,
    required TResult Function(CaptureInputScan value) scan,
    required TResult Function(CaptureInputSpeech value) speech,
    required TResult Function(CaptureInputManual value) manual,
  }) {
    return socialLink(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CaptureInputSocialLink value)? socialLink,
    TResult? Function(CaptureInputScreenshot value)? screenshot,
    TResult? Function(CaptureInputScan value)? scan,
    TResult? Function(CaptureInputSpeech value)? speech,
    TResult? Function(CaptureInputManual value)? manual,
  }) {
    return socialLink?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CaptureInputSocialLink value)? socialLink,
    TResult Function(CaptureInputScreenshot value)? screenshot,
    TResult Function(CaptureInputScan value)? scan,
    TResult Function(CaptureInputSpeech value)? speech,
    TResult Function(CaptureInputManual value)? manual,
    required TResult orElse(),
  }) {
    if (socialLink != null) {
      return socialLink(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CaptureInputSocialLinkImplToJson(this);
  }
}

abstract class CaptureInputSocialLink implements CaptureInput {
  const factory CaptureInputSocialLink({required final String url}) =
      _$CaptureInputSocialLinkImpl;

  factory CaptureInputSocialLink.fromJson(Map<String, dynamic> json) =
      _$CaptureInputSocialLinkImpl.fromJson;

  /// The URL of the social media post or recipe page.
  String get url;

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CaptureInputSocialLinkImplCopyWith<_$CaptureInputSocialLinkImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CaptureInputScreenshotImplCopyWith<$Res> {
  factory _$$CaptureInputScreenshotImplCopyWith(
    _$CaptureInputScreenshotImpl value,
    $Res Function(_$CaptureInputScreenshotImpl) then,
  ) = __$$CaptureInputScreenshotImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String image});
}

/// @nodoc
class __$$CaptureInputScreenshotImplCopyWithImpl<$Res>
    extends _$CaptureInputCopyWithImpl<$Res, _$CaptureInputScreenshotImpl>
    implements _$$CaptureInputScreenshotImplCopyWith<$Res> {
  __$$CaptureInputScreenshotImplCopyWithImpl(
    _$CaptureInputScreenshotImpl _value,
    $Res Function(_$CaptureInputScreenshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? image = null}) {
    return _then(
      _$CaptureInputScreenshotImpl(
        image: null == image
            ? _value.image
            : image // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CaptureInputScreenshotImpl implements CaptureInputScreenshot {
  const _$CaptureInputScreenshotImpl({required this.image, final String? $type})
    : $type = $type ?? 'screenshot';

  factory _$CaptureInputScreenshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$CaptureInputScreenshotImplFromJson(json);

  /// Reference to the uploaded screenshot image asset.
  @override
  final String image;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'CaptureInput.screenshot(image: $image)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CaptureInputScreenshotImpl &&
            (identical(other.image, image) || other.image == image));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, image);

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CaptureInputScreenshotImplCopyWith<_$CaptureInputScreenshotImpl>
  get copyWith =>
      __$$CaptureInputScreenshotImplCopyWithImpl<_$CaptureInputScreenshotImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String url) socialLink,
    required TResult Function(String image) screenshot,
    required TResult Function(String image) scan,
    required TResult Function(String transcript) speech,
    required TResult Function(String text) manual,
  }) {
    return screenshot(image);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String url)? socialLink,
    TResult? Function(String image)? screenshot,
    TResult? Function(String image)? scan,
    TResult? Function(String transcript)? speech,
    TResult? Function(String text)? manual,
  }) {
    return screenshot?.call(image);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String url)? socialLink,
    TResult Function(String image)? screenshot,
    TResult Function(String image)? scan,
    TResult Function(String transcript)? speech,
    TResult Function(String text)? manual,
    required TResult orElse(),
  }) {
    if (screenshot != null) {
      return screenshot(image);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CaptureInputSocialLink value) socialLink,
    required TResult Function(CaptureInputScreenshot value) screenshot,
    required TResult Function(CaptureInputScan value) scan,
    required TResult Function(CaptureInputSpeech value) speech,
    required TResult Function(CaptureInputManual value) manual,
  }) {
    return screenshot(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CaptureInputSocialLink value)? socialLink,
    TResult? Function(CaptureInputScreenshot value)? screenshot,
    TResult? Function(CaptureInputScan value)? scan,
    TResult? Function(CaptureInputSpeech value)? speech,
    TResult? Function(CaptureInputManual value)? manual,
  }) {
    return screenshot?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CaptureInputSocialLink value)? socialLink,
    TResult Function(CaptureInputScreenshot value)? screenshot,
    TResult Function(CaptureInputScan value)? scan,
    TResult Function(CaptureInputSpeech value)? speech,
    TResult Function(CaptureInputManual value)? manual,
    required TResult orElse(),
  }) {
    if (screenshot != null) {
      return screenshot(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CaptureInputScreenshotImplToJson(this);
  }
}

abstract class CaptureInputScreenshot implements CaptureInput {
  const factory CaptureInputScreenshot({required final String image}) =
      _$CaptureInputScreenshotImpl;

  factory CaptureInputScreenshot.fromJson(Map<String, dynamic> json) =
      _$CaptureInputScreenshotImpl.fromJson;

  /// Reference to the uploaded screenshot image asset.
  String get image;

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CaptureInputScreenshotImplCopyWith<_$CaptureInputScreenshotImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CaptureInputScanImplCopyWith<$Res> {
  factory _$$CaptureInputScanImplCopyWith(
    _$CaptureInputScanImpl value,
    $Res Function(_$CaptureInputScanImpl) then,
  ) = __$$CaptureInputScanImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String image});
}

/// @nodoc
class __$$CaptureInputScanImplCopyWithImpl<$Res>
    extends _$CaptureInputCopyWithImpl<$Res, _$CaptureInputScanImpl>
    implements _$$CaptureInputScanImplCopyWith<$Res> {
  __$$CaptureInputScanImplCopyWithImpl(
    _$CaptureInputScanImpl _value,
    $Res Function(_$CaptureInputScanImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? image = null}) {
    return _then(
      _$CaptureInputScanImpl(
        image: null == image
            ? _value.image
            : image // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CaptureInputScanImpl implements CaptureInputScan {
  const _$CaptureInputScanImpl({required this.image, final String? $type})
    : $type = $type ?? 'scan';

  factory _$CaptureInputScanImpl.fromJson(Map<String, dynamic> json) =>
      _$$CaptureInputScanImplFromJson(json);

  /// Reference to the uploaded scan image asset.
  @override
  final String image;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'CaptureInput.scan(image: $image)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CaptureInputScanImpl &&
            (identical(other.image, image) || other.image == image));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, image);

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CaptureInputScanImplCopyWith<_$CaptureInputScanImpl> get copyWith =>
      __$$CaptureInputScanImplCopyWithImpl<_$CaptureInputScanImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String url) socialLink,
    required TResult Function(String image) screenshot,
    required TResult Function(String image) scan,
    required TResult Function(String transcript) speech,
    required TResult Function(String text) manual,
  }) {
    return scan(image);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String url)? socialLink,
    TResult? Function(String image)? screenshot,
    TResult? Function(String image)? scan,
    TResult? Function(String transcript)? speech,
    TResult? Function(String text)? manual,
  }) {
    return scan?.call(image);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String url)? socialLink,
    TResult Function(String image)? screenshot,
    TResult Function(String image)? scan,
    TResult Function(String transcript)? speech,
    TResult Function(String text)? manual,
    required TResult orElse(),
  }) {
    if (scan != null) {
      return scan(image);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CaptureInputSocialLink value) socialLink,
    required TResult Function(CaptureInputScreenshot value) screenshot,
    required TResult Function(CaptureInputScan value) scan,
    required TResult Function(CaptureInputSpeech value) speech,
    required TResult Function(CaptureInputManual value) manual,
  }) {
    return scan(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CaptureInputSocialLink value)? socialLink,
    TResult? Function(CaptureInputScreenshot value)? screenshot,
    TResult? Function(CaptureInputScan value)? scan,
    TResult? Function(CaptureInputSpeech value)? speech,
    TResult? Function(CaptureInputManual value)? manual,
  }) {
    return scan?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CaptureInputSocialLink value)? socialLink,
    TResult Function(CaptureInputScreenshot value)? screenshot,
    TResult Function(CaptureInputScan value)? scan,
    TResult Function(CaptureInputSpeech value)? speech,
    TResult Function(CaptureInputManual value)? manual,
    required TResult orElse(),
  }) {
    if (scan != null) {
      return scan(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CaptureInputScanImplToJson(this);
  }
}

abstract class CaptureInputScan implements CaptureInput {
  const factory CaptureInputScan({required final String image}) =
      _$CaptureInputScanImpl;

  factory CaptureInputScan.fromJson(Map<String, dynamic> json) =
      _$CaptureInputScanImpl.fromJson;

  /// Reference to the uploaded scan image asset.
  String get image;

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CaptureInputScanImplCopyWith<_$CaptureInputScanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CaptureInputSpeechImplCopyWith<$Res> {
  factory _$$CaptureInputSpeechImplCopyWith(
    _$CaptureInputSpeechImpl value,
    $Res Function(_$CaptureInputSpeechImpl) then,
  ) = __$$CaptureInputSpeechImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String transcript});
}

/// @nodoc
class __$$CaptureInputSpeechImplCopyWithImpl<$Res>
    extends _$CaptureInputCopyWithImpl<$Res, _$CaptureInputSpeechImpl>
    implements _$$CaptureInputSpeechImplCopyWith<$Res> {
  __$$CaptureInputSpeechImplCopyWithImpl(
    _$CaptureInputSpeechImpl _value,
    $Res Function(_$CaptureInputSpeechImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? transcript = null}) {
    return _then(
      _$CaptureInputSpeechImpl(
        transcript: null == transcript
            ? _value.transcript
            : transcript // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CaptureInputSpeechImpl implements CaptureInputSpeech {
  const _$CaptureInputSpeechImpl({
    required this.transcript,
    final String? $type,
  }) : $type = $type ?? 'speech';

  factory _$CaptureInputSpeechImpl.fromJson(Map<String, dynamic> json) =>
      _$$CaptureInputSpeechImplFromJson(json);

  /// The transcribed text from the speech input.
  @override
  final String transcript;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'CaptureInput.speech(transcript: $transcript)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CaptureInputSpeechImpl &&
            (identical(other.transcript, transcript) ||
                other.transcript == transcript));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, transcript);

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CaptureInputSpeechImplCopyWith<_$CaptureInputSpeechImpl> get copyWith =>
      __$$CaptureInputSpeechImplCopyWithImpl<_$CaptureInputSpeechImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String url) socialLink,
    required TResult Function(String image) screenshot,
    required TResult Function(String image) scan,
    required TResult Function(String transcript) speech,
    required TResult Function(String text) manual,
  }) {
    return speech(transcript);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String url)? socialLink,
    TResult? Function(String image)? screenshot,
    TResult? Function(String image)? scan,
    TResult? Function(String transcript)? speech,
    TResult? Function(String text)? manual,
  }) {
    return speech?.call(transcript);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String url)? socialLink,
    TResult Function(String image)? screenshot,
    TResult Function(String image)? scan,
    TResult Function(String transcript)? speech,
    TResult Function(String text)? manual,
    required TResult orElse(),
  }) {
    if (speech != null) {
      return speech(transcript);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CaptureInputSocialLink value) socialLink,
    required TResult Function(CaptureInputScreenshot value) screenshot,
    required TResult Function(CaptureInputScan value) scan,
    required TResult Function(CaptureInputSpeech value) speech,
    required TResult Function(CaptureInputManual value) manual,
  }) {
    return speech(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CaptureInputSocialLink value)? socialLink,
    TResult? Function(CaptureInputScreenshot value)? screenshot,
    TResult? Function(CaptureInputScan value)? scan,
    TResult? Function(CaptureInputSpeech value)? speech,
    TResult? Function(CaptureInputManual value)? manual,
  }) {
    return speech?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CaptureInputSocialLink value)? socialLink,
    TResult Function(CaptureInputScreenshot value)? screenshot,
    TResult Function(CaptureInputScan value)? scan,
    TResult Function(CaptureInputSpeech value)? speech,
    TResult Function(CaptureInputManual value)? manual,
    required TResult orElse(),
  }) {
    if (speech != null) {
      return speech(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CaptureInputSpeechImplToJson(this);
  }
}

abstract class CaptureInputSpeech implements CaptureInput {
  const factory CaptureInputSpeech({required final String transcript}) =
      _$CaptureInputSpeechImpl;

  factory CaptureInputSpeech.fromJson(Map<String, dynamic> json) =
      _$CaptureInputSpeechImpl.fromJson;

  /// The transcribed text from the speech input.
  String get transcript;

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CaptureInputSpeechImplCopyWith<_$CaptureInputSpeechImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CaptureInputManualImplCopyWith<$Res> {
  factory _$$CaptureInputManualImplCopyWith(
    _$CaptureInputManualImpl value,
    $Res Function(_$CaptureInputManualImpl) then,
  ) = __$$CaptureInputManualImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String text});
}

/// @nodoc
class __$$CaptureInputManualImplCopyWithImpl<$Res>
    extends _$CaptureInputCopyWithImpl<$Res, _$CaptureInputManualImpl>
    implements _$$CaptureInputManualImplCopyWith<$Res> {
  __$$CaptureInputManualImplCopyWithImpl(
    _$CaptureInputManualImpl _value,
    $Res Function(_$CaptureInputManualImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? text = null}) {
    return _then(
      _$CaptureInputManualImpl(
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
class _$CaptureInputManualImpl implements CaptureInputManual {
  const _$CaptureInputManualImpl({required this.text, final String? $type})
    : $type = $type ?? 'manual';

  factory _$CaptureInputManualImpl.fromJson(Map<String, dynamic> json) =>
      _$$CaptureInputManualImplFromJson(json);

  /// The raw text entered by the user.
  @override
  final String text;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'CaptureInput.manual(text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CaptureInputManualImpl &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text);

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CaptureInputManualImplCopyWith<_$CaptureInputManualImpl> get copyWith =>
      __$$CaptureInputManualImplCopyWithImpl<_$CaptureInputManualImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String url) socialLink,
    required TResult Function(String image) screenshot,
    required TResult Function(String image) scan,
    required TResult Function(String transcript) speech,
    required TResult Function(String text) manual,
  }) {
    return manual(text);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String url)? socialLink,
    TResult? Function(String image)? screenshot,
    TResult? Function(String image)? scan,
    TResult? Function(String transcript)? speech,
    TResult? Function(String text)? manual,
  }) {
    return manual?.call(text);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String url)? socialLink,
    TResult Function(String image)? screenshot,
    TResult Function(String image)? scan,
    TResult Function(String transcript)? speech,
    TResult Function(String text)? manual,
    required TResult orElse(),
  }) {
    if (manual != null) {
      return manual(text);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(CaptureInputSocialLink value) socialLink,
    required TResult Function(CaptureInputScreenshot value) screenshot,
    required TResult Function(CaptureInputScan value) scan,
    required TResult Function(CaptureInputSpeech value) speech,
    required TResult Function(CaptureInputManual value) manual,
  }) {
    return manual(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(CaptureInputSocialLink value)? socialLink,
    TResult? Function(CaptureInputScreenshot value)? screenshot,
    TResult? Function(CaptureInputScan value)? scan,
    TResult? Function(CaptureInputSpeech value)? speech,
    TResult? Function(CaptureInputManual value)? manual,
  }) {
    return manual?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(CaptureInputSocialLink value)? socialLink,
    TResult Function(CaptureInputScreenshot value)? screenshot,
    TResult Function(CaptureInputScan value)? scan,
    TResult Function(CaptureInputSpeech value)? speech,
    TResult Function(CaptureInputManual value)? manual,
    required TResult orElse(),
  }) {
    if (manual != null) {
      return manual(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$CaptureInputManualImplToJson(this);
  }
}

abstract class CaptureInputManual implements CaptureInput {
  const factory CaptureInputManual({required final String text}) =
      _$CaptureInputManualImpl;

  factory CaptureInputManual.fromJson(Map<String, dynamic> json) =
      _$CaptureInputManualImpl.fromJson;

  /// The raw text entered by the user.
  String get text;

  /// Create a copy of CaptureInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CaptureInputManualImplCopyWith<_$CaptureInputManualImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExtractionArtifact _$ExtractionArtifactFromJson(Map<String, dynamic> json) {
  return _ExtractionArtifact.fromJson(json);
}

/// @nodoc
mixin _$ExtractionArtifact {
  /// The capture input that produced this artifact.
  String get id => throw _privateConstructorUsedError;

  /// Version number for reprocessing support (starts at 1).
  int get version => throw _privateConstructorUsedError;

  /// Raw text extracted directly from the input.
  String? get rawText => throw _privateConstructorUsedError;

  /// Text extracted via OCR from images.
  String? get ocrText => throw _privateConstructorUsedError;

  /// Text from speech transcription.
  String? get transcript => throw _privateConstructorUsedError;

  /// Individual ingredient text lines found in the source.
  List<String> get ingredients => throw _privateConstructorUsedError;

  /// Individual step text lines found in the source.
  List<String> get steps => throw _privateConstructorUsedError;

  /// References to images found in or associated with the source.
  List<String> get images => throw _privateConstructorUsedError;

  /// Attribution and platform information about the source.
  Source get source => throw _privateConstructorUsedError;

  /// Confidence score for the extraction quality (0.0 to 1.0).
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this ExtractionArtifact to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExtractionArtifact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExtractionArtifactCopyWith<ExtractionArtifact> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExtractionArtifactCopyWith<$Res> {
  factory $ExtractionArtifactCopyWith(
    ExtractionArtifact value,
    $Res Function(ExtractionArtifact) then,
  ) = _$ExtractionArtifactCopyWithImpl<$Res, ExtractionArtifact>;
  @useResult
  $Res call({
    String id,
    int version,
    String? rawText,
    String? ocrText,
    String? transcript,
    List<String> ingredients,
    List<String> steps,
    List<String> images,
    Source source,
    double confidence,
  });

  $SourceCopyWith<$Res> get source;
}

/// @nodoc
class _$ExtractionArtifactCopyWithImpl<$Res, $Val extends ExtractionArtifact>
    implements $ExtractionArtifactCopyWith<$Res> {
  _$ExtractionArtifactCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExtractionArtifact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? version = null,
    Object? rawText = freezed,
    Object? ocrText = freezed,
    Object? transcript = freezed,
    Object? ingredients = null,
    Object? steps = null,
    Object? images = null,
    Object? source = null,
    Object? confidence = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            version: null == version
                ? _value.version
                : version // ignore: cast_nullable_to_non_nullable
                      as int,
            rawText: freezed == rawText
                ? _value.rawText
                : rawText // ignore: cast_nullable_to_non_nullable
                      as String?,
            ocrText: freezed == ocrText
                ? _value.ocrText
                : ocrText // ignore: cast_nullable_to_non_nullable
                      as String?,
            transcript: freezed == transcript
                ? _value.transcript
                : transcript // ignore: cast_nullable_to_non_nullable
                      as String?,
            ingredients: null == ingredients
                ? _value.ingredients
                : ingredients // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            steps: null == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            images: null == images
                ? _value.images
                : images // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as Source,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }

  /// Create a copy of ExtractionArtifact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SourceCopyWith<$Res> get source {
    return $SourceCopyWith<$Res>(_value.source, (value) {
      return _then(_value.copyWith(source: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ExtractionArtifactImplCopyWith<$Res>
    implements $ExtractionArtifactCopyWith<$Res> {
  factory _$$ExtractionArtifactImplCopyWith(
    _$ExtractionArtifactImpl value,
    $Res Function(_$ExtractionArtifactImpl) then,
  ) = __$$ExtractionArtifactImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    int version,
    String? rawText,
    String? ocrText,
    String? transcript,
    List<String> ingredients,
    List<String> steps,
    List<String> images,
    Source source,
    double confidence,
  });

  @override
  $SourceCopyWith<$Res> get source;
}

/// @nodoc
class __$$ExtractionArtifactImplCopyWithImpl<$Res>
    extends _$ExtractionArtifactCopyWithImpl<$Res, _$ExtractionArtifactImpl>
    implements _$$ExtractionArtifactImplCopyWith<$Res> {
  __$$ExtractionArtifactImplCopyWithImpl(
    _$ExtractionArtifactImpl _value,
    $Res Function(_$ExtractionArtifactImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExtractionArtifact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? version = null,
    Object? rawText = freezed,
    Object? ocrText = freezed,
    Object? transcript = freezed,
    Object? ingredients = null,
    Object? steps = null,
    Object? images = null,
    Object? source = null,
    Object? confidence = null,
  }) {
    return _then(
      _$ExtractionArtifactImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        version: null == version
            ? _value.version
            : version // ignore: cast_nullable_to_non_nullable
                  as int,
        rawText: freezed == rawText
            ? _value.rawText
            : rawText // ignore: cast_nullable_to_non_nullable
                  as String?,
        ocrText: freezed == ocrText
            ? _value.ocrText
            : ocrText // ignore: cast_nullable_to_non_nullable
                  as String?,
        transcript: freezed == transcript
            ? _value.transcript
            : transcript // ignore: cast_nullable_to_non_nullable
                  as String?,
        ingredients: null == ingredients
            ? _value._ingredients
            : ingredients // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        steps: null == steps
            ? _value._steps
            : steps // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        images: null == images
            ? _value._images
            : images // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as Source,
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
class _$ExtractionArtifactImpl implements _ExtractionArtifact {
  const _$ExtractionArtifactImpl({
    required this.id,
    required this.version,
    this.rawText,
    this.ocrText,
    this.transcript,
    required final List<String> ingredients,
    required final List<String> steps,
    required final List<String> images,
    required this.source,
    required this.confidence,
  }) : _ingredients = ingredients,
       _steps = steps,
       _images = images;

  factory _$ExtractionArtifactImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExtractionArtifactImplFromJson(json);

  /// The capture input that produced this artifact.
  @override
  final String id;

  /// Version number for reprocessing support (starts at 1).
  @override
  final int version;

  /// Raw text extracted directly from the input.
  @override
  final String? rawText;

  /// Text extracted via OCR from images.
  @override
  final String? ocrText;

  /// Text from speech transcription.
  @override
  final String? transcript;

  /// Individual ingredient text lines found in the source.
  final List<String> _ingredients;

  /// Individual ingredient text lines found in the source.
  @override
  List<String> get ingredients {
    if (_ingredients is EqualUnmodifiableListView) return _ingredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ingredients);
  }

  /// Individual step text lines found in the source.
  final List<String> _steps;

  /// Individual step text lines found in the source.
  @override
  List<String> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  /// References to images found in or associated with the source.
  final List<String> _images;

  /// References to images found in or associated with the source.
  @override
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  /// Attribution and platform information about the source.
  @override
  final Source source;

  /// Confidence score for the extraction quality (0.0 to 1.0).
  @override
  final double confidence;

  @override
  String toString() {
    return 'ExtractionArtifact(id: $id, version: $version, rawText: $rawText, ocrText: $ocrText, transcript: $transcript, ingredients: $ingredients, steps: $steps, images: $images, source: $source, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExtractionArtifactImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.rawText, rawText) || other.rawText == rawText) &&
            (identical(other.ocrText, ocrText) || other.ocrText == ocrText) &&
            (identical(other.transcript, transcript) ||
                other.transcript == transcript) &&
            const DeepCollectionEquality().equals(
              other._ingredients,
              _ingredients,
            ) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    version,
    rawText,
    ocrText,
    transcript,
    const DeepCollectionEquality().hash(_ingredients),
    const DeepCollectionEquality().hash(_steps),
    const DeepCollectionEquality().hash(_images),
    source,
    confidence,
  );

  /// Create a copy of ExtractionArtifact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExtractionArtifactImplCopyWith<_$ExtractionArtifactImpl> get copyWith =>
      __$$ExtractionArtifactImplCopyWithImpl<_$ExtractionArtifactImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ExtractionArtifactImplToJson(this);
  }
}

abstract class _ExtractionArtifact implements ExtractionArtifact {
  const factory _ExtractionArtifact({
    required final String id,
    required final int version,
    final String? rawText,
    final String? ocrText,
    final String? transcript,
    required final List<String> ingredients,
    required final List<String> steps,
    required final List<String> images,
    required final Source source,
    required final double confidence,
  }) = _$ExtractionArtifactImpl;

  factory _ExtractionArtifact.fromJson(Map<String, dynamic> json) =
      _$ExtractionArtifactImpl.fromJson;

  /// The capture input that produced this artifact.
  @override
  String get id;

  /// Version number for reprocessing support (starts at 1).
  @override
  int get version;

  /// Raw text extracted directly from the input.
  @override
  String? get rawText;

  /// Text extracted via OCR from images.
  @override
  String? get ocrText;

  /// Text from speech transcription.
  @override
  String? get transcript;

  /// Individual ingredient text lines found in the source.
  @override
  List<String> get ingredients;

  /// Individual step text lines found in the source.
  @override
  List<String> get steps;

  /// References to images found in or associated with the source.
  @override
  List<String> get images;

  /// Attribution and platform information about the source.
  @override
  Source get source;

  /// Confidence score for the extraction quality (0.0 to 1.0).
  @override
  double get confidence;

  /// Create a copy of ExtractionArtifact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExtractionArtifactImplCopyWith<_$ExtractionArtifactImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StructuredRecipeCandidate _$StructuredRecipeCandidateFromJson(
  Map<String, dynamic> json,
) {
  return _StructuredRecipeCandidate.fromJson(json);
}

/// @nodoc
mixin _$StructuredRecipeCandidate {
  /// The recipe title, if it could be identified.
  String? get title => throw _privateConstructorUsedError;

  /// Raw ingredient lines as extracted (not yet parsed).
  List<String> get ingredientLines => throw _privateConstructorUsedError;

  /// Step-by-step instructions.
  List<String> get steps => throw _privateConstructorUsedError;

  /// Number of servings, if identified.
  int? get servings => throw _privateConstructorUsedError;

  /// Total time in minutes, if identified.
  int? get timeMinutes => throw _privateConstructorUsedError;

  /// Tags or categories associated with the recipe.
  List<String> get tags => throw _privateConstructorUsedError;

  /// Confidence score for the structuring quality (0.0 to 1.0).
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this StructuredRecipeCandidate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StructuredRecipeCandidate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StructuredRecipeCandidateCopyWith<StructuredRecipeCandidate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StructuredRecipeCandidateCopyWith<$Res> {
  factory $StructuredRecipeCandidateCopyWith(
    StructuredRecipeCandidate value,
    $Res Function(StructuredRecipeCandidate) then,
  ) = _$StructuredRecipeCandidateCopyWithImpl<$Res, StructuredRecipeCandidate>;
  @useResult
  $Res call({
    String? title,
    List<String> ingredientLines,
    List<String> steps,
    int? servings,
    int? timeMinutes,
    List<String> tags,
    double confidence,
  });
}

/// @nodoc
class _$StructuredRecipeCandidateCopyWithImpl<
  $Res,
  $Val extends StructuredRecipeCandidate
>
    implements $StructuredRecipeCandidateCopyWith<$Res> {
  _$StructuredRecipeCandidateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StructuredRecipeCandidate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? ingredientLines = null,
    Object? steps = null,
    Object? servings = freezed,
    Object? timeMinutes = freezed,
    Object? tags = null,
    Object? confidence = null,
  }) {
    return _then(
      _value.copyWith(
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            ingredientLines: null == ingredientLines
                ? _value.ingredientLines
                : ingredientLines // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            steps: null == steps
                ? _value.steps
                : steps // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            servings: freezed == servings
                ? _value.servings
                : servings // ignore: cast_nullable_to_non_nullable
                      as int?,
            timeMinutes: freezed == timeMinutes
                ? _value.timeMinutes
                : timeMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
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
abstract class _$$StructuredRecipeCandidateImplCopyWith<$Res>
    implements $StructuredRecipeCandidateCopyWith<$Res> {
  factory _$$StructuredRecipeCandidateImplCopyWith(
    _$StructuredRecipeCandidateImpl value,
    $Res Function(_$StructuredRecipeCandidateImpl) then,
  ) = __$$StructuredRecipeCandidateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? title,
    List<String> ingredientLines,
    List<String> steps,
    int? servings,
    int? timeMinutes,
    List<String> tags,
    double confidence,
  });
}

/// @nodoc
class __$$StructuredRecipeCandidateImplCopyWithImpl<$Res>
    extends
        _$StructuredRecipeCandidateCopyWithImpl<
          $Res,
          _$StructuredRecipeCandidateImpl
        >
    implements _$$StructuredRecipeCandidateImplCopyWith<$Res> {
  __$$StructuredRecipeCandidateImplCopyWithImpl(
    _$StructuredRecipeCandidateImpl _value,
    $Res Function(_$StructuredRecipeCandidateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StructuredRecipeCandidate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? ingredientLines = null,
    Object? steps = null,
    Object? servings = freezed,
    Object? timeMinutes = freezed,
    Object? tags = null,
    Object? confidence = null,
  }) {
    return _then(
      _$StructuredRecipeCandidateImpl(
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        ingredientLines: null == ingredientLines
            ? _value._ingredientLines
            : ingredientLines // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        steps: null == steps
            ? _value._steps
            : steps // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        servings: freezed == servings
            ? _value.servings
            : servings // ignore: cast_nullable_to_non_nullable
                  as int?,
        timeMinutes: freezed == timeMinutes
            ? _value.timeMinutes
            : timeMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
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
class _$StructuredRecipeCandidateImpl implements _StructuredRecipeCandidate {
  const _$StructuredRecipeCandidateImpl({
    this.title,
    required final List<String> ingredientLines,
    required final List<String> steps,
    this.servings,
    this.timeMinutes,
    required final List<String> tags,
    required this.confidence,
  }) : _ingredientLines = ingredientLines,
       _steps = steps,
       _tags = tags;

  factory _$StructuredRecipeCandidateImpl.fromJson(Map<String, dynamic> json) =>
      _$$StructuredRecipeCandidateImplFromJson(json);

  /// The recipe title, if it could be identified.
  @override
  final String? title;

  /// Raw ingredient lines as extracted (not yet parsed).
  final List<String> _ingredientLines;

  /// Raw ingredient lines as extracted (not yet parsed).
  @override
  List<String> get ingredientLines {
    if (_ingredientLines is EqualUnmodifiableListView) return _ingredientLines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ingredientLines);
  }

  /// Step-by-step instructions.
  final List<String> _steps;

  /// Step-by-step instructions.
  @override
  List<String> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  /// Number of servings, if identified.
  @override
  final int? servings;

  /// Total time in minutes, if identified.
  @override
  final int? timeMinutes;

  /// Tags or categories associated with the recipe.
  final List<String> _tags;

  /// Tags or categories associated with the recipe.
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// Confidence score for the structuring quality (0.0 to 1.0).
  @override
  final double confidence;

  @override
  String toString() {
    return 'StructuredRecipeCandidate(title: $title, ingredientLines: $ingredientLines, steps: $steps, servings: $servings, timeMinutes: $timeMinutes, tags: $tags, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StructuredRecipeCandidateImpl &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(
              other._ingredientLines,
              _ingredientLines,
            ) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            (identical(other.servings, servings) ||
                other.servings == servings) &&
            (identical(other.timeMinutes, timeMinutes) ||
                other.timeMinutes == timeMinutes) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    const DeepCollectionEquality().hash(_ingredientLines),
    const DeepCollectionEquality().hash(_steps),
    servings,
    timeMinutes,
    const DeepCollectionEquality().hash(_tags),
    confidence,
  );

  /// Create a copy of StructuredRecipeCandidate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StructuredRecipeCandidateImplCopyWith<_$StructuredRecipeCandidateImpl>
  get copyWith =>
      __$$StructuredRecipeCandidateImplCopyWithImpl<
        _$StructuredRecipeCandidateImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StructuredRecipeCandidateImplToJson(this);
  }
}

abstract class _StructuredRecipeCandidate implements StructuredRecipeCandidate {
  const factory _StructuredRecipeCandidate({
    final String? title,
    required final List<String> ingredientLines,
    required final List<String> steps,
    final int? servings,
    final int? timeMinutes,
    required final List<String> tags,
    required final double confidence,
  }) = _$StructuredRecipeCandidateImpl;

  factory _StructuredRecipeCandidate.fromJson(Map<String, dynamic> json) =
      _$StructuredRecipeCandidateImpl.fromJson;

  /// The recipe title, if it could be identified.
  @override
  String? get title;

  /// Raw ingredient lines as extracted (not yet parsed).
  @override
  List<String> get ingredientLines;

  /// Step-by-step instructions.
  @override
  List<String> get steps;

  /// Number of servings, if identified.
  @override
  int? get servings;

  /// Total time in minutes, if identified.
  @override
  int? get timeMinutes;

  /// Tags or categories associated with the recipe.
  @override
  List<String> get tags;

  /// Confidence score for the structuring quality (0.0 to 1.0).
  @override
  double get confidence;

  /// Create a copy of StructuredRecipeCandidate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StructuredRecipeCandidateImplCopyWith<_$StructuredRecipeCandidateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
