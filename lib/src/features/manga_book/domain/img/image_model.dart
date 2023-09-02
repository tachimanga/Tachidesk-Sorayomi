import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_model.freezed.dart';
part 'image_model.g.dart';

@freezed
class ImgData with _$ImgData {
  factory ImgData({
    String? url,
    String? method,
    Map<String, String>? headers,
  }) = _ImgData;

  factory ImgData.fromJson(Map<String, dynamic> json) =>
      _$ImgDataFromJson(json);
}
