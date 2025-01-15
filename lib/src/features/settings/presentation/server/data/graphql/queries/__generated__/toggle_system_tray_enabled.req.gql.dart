// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:ferry_exec/ferry_exec.dart' as _i1;
import 'package:gql_exec/gql_exec.dart' as _i4;
import 'package:tachidesk_sorayomi/src/features/settings/presentation/server/data/graphql/queries/__generated__/toggle_system_tray_enabled.ast.gql.dart'
    as _i5;
import 'package:tachidesk_sorayomi/src/features/settings/presentation/server/data/graphql/queries/__generated__/toggle_system_tray_enabled.data.gql.dart'
    as _i2;
import 'package:tachidesk_sorayomi/src/features/settings/presentation/server/data/graphql/queries/__generated__/toggle_system_tray_enabled.var.gql.dart'
    as _i3;
import 'package:tachidesk_sorayomi/src/graphql/__generated__/serializers.gql.dart'
    as _i6;

part 'toggle_system_tray_enabled.req.gql.g.dart';

abstract class GToggleSystemTrayEnabledReq
    implements
        Built<GToggleSystemTrayEnabledReq, GToggleSystemTrayEnabledReqBuilder>,
        _i1.OperationRequest<_i2.GToggleSystemTrayEnabledData,
            _i3.GToggleSystemTrayEnabledVars> {
  GToggleSystemTrayEnabledReq._();

  factory GToggleSystemTrayEnabledReq(
          [void Function(GToggleSystemTrayEnabledReqBuilder b) updates]) =
      _$GToggleSystemTrayEnabledReq;

  static void _initializeBuilder(GToggleSystemTrayEnabledReqBuilder b) => b
    ..operation = _i4.Operation(
      document: _i5.document,
      operationName: 'ToggleSystemTrayEnabled',
    )
    ..executeOnListen = true;

  @override
  _i3.GToggleSystemTrayEnabledVars get vars;
  @override
  _i4.Operation get operation;
  @override
  _i4.Request get execRequest => _i4.Request(
        operation: operation,
        variables: vars.toJson(),
        context: context ?? const _i4.Context(),
      );

  @override
  String? get requestId;
  @override
  @BuiltValueField(serialize: false)
  _i2.GToggleSystemTrayEnabledData? Function(
    _i2.GToggleSystemTrayEnabledData?,
    _i2.GToggleSystemTrayEnabledData?,
  )? get updateResult;
  @override
  _i2.GToggleSystemTrayEnabledData? get optimisticResponse;
  @override
  String? get updateCacheHandlerKey;
  @override
  Map<String, dynamic>? get updateCacheHandlerContext;
  @override
  _i1.FetchPolicy? get fetchPolicy;
  @override
  bool get executeOnListen;
  @override
  @BuiltValueField(serialize: false)
  _i4.Context? get context;
  @override
  _i2.GToggleSystemTrayEnabledData? parseData(Map<String, dynamic> json) =>
      _i2.GToggleSystemTrayEnabledData.fromJson(json);

  @override
  Map<String, dynamic> varsToJson() => vars.toJson();

  @override
  Map<String, dynamic> dataToJson(_i2.GToggleSystemTrayEnabledData data) =>
      data.toJson();

  @override
  _i1.OperationRequest<_i2.GToggleSystemTrayEnabledData,
      _i3.GToggleSystemTrayEnabledVars> transformOperation(
          _i4.Operation Function(_i4.Operation) transform) =>
      this.rebuild((b) => b..operation = transform(operation));

  static Serializer<GToggleSystemTrayEnabledReq> get serializer =>
      _$gToggleSystemTrayEnabledReqSerializer;

  Map<String, dynamic> toJson() => (_i6.serializers.serializeWith(
        GToggleSystemTrayEnabledReq.serializer,
        this,
      ) as Map<String, dynamic>);

  static GToggleSystemTrayEnabledReq? fromJson(Map<String, dynamic> json) =>
      _i6.serializers.deserializeWith(
        GToggleSystemTrayEnabledReq.serializer,
        json,
      );
}
