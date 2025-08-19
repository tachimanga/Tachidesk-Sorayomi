import 'package:flutter/services.dart';

Set<LogicalKeyboardKey> previousKeySet = {
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.keyW,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.keyA,
};

Set<LogicalKeyboardKey> previousKeySetReversed = {
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.keyW,
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.keyD,
};

Set<LogicalKeyboardKey> nextKeySet = {
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.keyS,
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.arrowRight,
  LogicalKeyboardKey.keyD,
};

Set<LogicalKeyboardKey> nextKeySetReversed = {
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.keyS,
  LogicalKeyboardKey.space,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.keyA,
};

Set<LogicalKeyboardKey> speedUpKeySet = {
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
};

bool isSpeedUpKeyPressed() {
  return HardwareKeyboard.instance.logicalKeysPressed.any(
    (key) => speedUpKeySet.contains(key),
  );
}
