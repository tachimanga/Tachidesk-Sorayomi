import 'package:freezed_annotation/freezed_annotation.dart';

part 'trace_model.freezed.dart';
part 'trace_model.g.dart';

@freezed
class TraceInfo with _$TraceInfo {
  factory TraceInfo({
    String? type,
    String? sourceId,
    String? mangaUrl,
  }) = _TraceInfo;

  factory TraceInfo.fromJson(Map<String, dynamic> json) =>
      _$TraceInfoFromJson(json);
}