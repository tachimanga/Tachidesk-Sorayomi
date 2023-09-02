import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unique_key_provider.g.dart';

@riverpod
class UniqKey extends _$UniqKey {
  @override
  UniqueKey build(String key) {
    return UniqueKey();
  }

  void reload() {
    state = UniqueKey();
  }
}
