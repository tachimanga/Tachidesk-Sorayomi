/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $AssetsDataGen {
  const $AssetsDataGen();

  /// File path: assets/data/icons.json
  String get icons => 'assets/data/icons.json';

  /// File path: assets/data/products.json
  String get products => 'assets/data/products.json';

  /// List of all assets
  List<String> get values => [icons, products];
}

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/AppIcon 1.png
  AssetGenImage get appIcon1 =>
      const AssetGenImage('assets/icons/AppIcon 1.png');

  /// File path: assets/icons/AppIcon 10.png
  AssetGenImage get appIcon10 =>
      const AssetGenImage('assets/icons/AppIcon 10.png');

  /// File path: assets/icons/AppIcon 14.png
  AssetGenImage get appIcon14 =>
      const AssetGenImage('assets/icons/AppIcon 14.png');

  /// File path: assets/icons/AppIcon 17.png
  AssetGenImage get appIcon17 =>
      const AssetGenImage('assets/icons/AppIcon 17.png');

  /// File path: assets/icons/AppIcon 18.png
  AssetGenImage get appIcon18 =>
      const AssetGenImage('assets/icons/AppIcon 18.png');

  /// File path: assets/icons/AppIcon 19.png
  AssetGenImage get appIcon19 =>
      const AssetGenImage('assets/icons/AppIcon 19.png');

  /// File path: assets/icons/AppIcon 2.png
  AssetGenImage get appIcon2 =>
      const AssetGenImage('assets/icons/AppIcon 2.png');

  /// File path: assets/icons/AppIcon 22.png
  AssetGenImage get appIcon22 =>
      const AssetGenImage('assets/icons/AppIcon 22.png');

  /// File path: assets/icons/AppIcon 23.png
  AssetGenImage get appIcon23 =>
      const AssetGenImage('assets/icons/AppIcon 23.png');

  /// File path: assets/icons/AppIcon 24.png
  AssetGenImage get appIcon24 =>
      const AssetGenImage('assets/icons/AppIcon 24.png');

  /// File path: assets/icons/AppIcon 26.png
  AssetGenImage get appIcon26 =>
      const AssetGenImage('assets/icons/AppIcon 26.png');

  /// File path: assets/icons/AppIcon 27.png
  AssetGenImage get appIcon27 =>
      const AssetGenImage('assets/icons/AppIcon 27.png');

  /// File path: assets/icons/AppIcon 28.png
  AssetGenImage get appIcon28 =>
      const AssetGenImage('assets/icons/AppIcon 28.png');

  /// File path: assets/icons/AppIcon 29.png
  AssetGenImage get appIcon29 =>
      const AssetGenImage('assets/icons/AppIcon 29.png');

  /// File path: assets/icons/AppIcon 3.png
  AssetGenImage get appIcon3 =>
      const AssetGenImage('assets/icons/AppIcon 3.png');

  /// File path: assets/icons/AppIcon 30.png
  AssetGenImage get appIcon30 =>
      const AssetGenImage('assets/icons/AppIcon 30.png');

  /// File path: assets/icons/AppIcon 31.png
  AssetGenImage get appIcon31 =>
      const AssetGenImage('assets/icons/AppIcon 31.png');

  /// File path: assets/icons/AppIcon 4.png
  AssetGenImage get appIcon4 =>
      const AssetGenImage('assets/icons/AppIcon 4.png');

  /// File path: assets/icons/AppIcon 5.png
  AssetGenImage get appIcon5 =>
      const AssetGenImage('assets/icons/AppIcon 5.png');

  /// File path: assets/icons/AppIcon 6.png
  AssetGenImage get appIcon6 =>
      const AssetGenImage('assets/icons/AppIcon 6.png');

  /// File path: assets/icons/AppIcon 9.png
  AssetGenImage get appIcon9 =>
      const AssetGenImage('assets/icons/AppIcon 9.png');

  /// File path: assets/icons/AppIcon.png
  AssetGenImage get appIcon => const AssetGenImage('assets/icons/AppIcon.png');

  /// File path: assets/icons/dark_icon.png
  AssetGenImage get darkIcon =>
      const AssetGenImage('assets/icons/dark_icon.png');

  /// File path: assets/icons/incognito.png
  AssetGenImage get incognito =>
      const AssetGenImage('assets/icons/incognito.png');

  /// File path: assets/icons/light_icon.png
  AssetGenImage get lightIcon =>
      const AssetGenImage('assets/icons/light_icon.png');

  /// File path: assets/icons/pip.png
  AssetGenImage get pip => const AssetGenImage('assets/icons/pip.png');

  /// File path: assets/icons/previous_done.png
  AssetGenImage get previousDone =>
      const AssetGenImage('assets/icons/previous_done.png');

  /// List of all assets
  List<AssetGenImage> get values => [
        appIcon1,
        appIcon10,
        appIcon14,
        appIcon17,
        appIcon18,
        appIcon19,
        appIcon2,
        appIcon22,
        appIcon23,
        appIcon24,
        appIcon26,
        appIcon27,
        appIcon28,
        appIcon29,
        appIcon3,
        appIcon30,
        appIcon31,
        appIcon4,
        appIcon5,
        appIcon6,
        appIcon9,
        appIcon,
        darkIcon,
        incognito,
        lightIcon,
        pip,
        previousDone
      ];
}

class Assets {
  Assets._();

  static const $AssetsDataGen data = $AssetsDataGen();
  static const $AssetsIconsGen icons = $AssetsIconsGen();
}

class AssetGenImage {
  const AssetGenImage(this._assetName);

  final String _assetName;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = false,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.low,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    String? package,
  }) {
    return AssetImage(
      _assetName,
      bundle: bundle,
      package: package,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
