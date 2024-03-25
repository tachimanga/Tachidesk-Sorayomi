import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'date_format_controller.g.dart';

@riverpod
class DateFormatPref extends _$DateFormatPref
    with SharedPreferenceEnumClientMixin<DateFormatEnum> {
  @override
  DateFormatEnum? build() => initialize(
        ref,
        initial: DBKeys.dateFormat.initial,
        key: DBKeys.dateFormat.name,
        enumList: DateFormatEnum.values,
      );
}
