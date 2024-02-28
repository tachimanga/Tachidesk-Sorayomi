import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TriCheckbox extends StatelessWidget {
  const TriCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;

  void _handleValueChange() {
    assert(onChanged != null);
    switch (value) {
      case true:
        onChanged!(false);
        break;
      case false:
        onChanged!(null);
        break;
      case null:
        onChanged!(true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _handleValueChange,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            if (value == null) ...[
              Icon(
                Icons.check_box_outline_blank_rounded,
                size: 24,
                color: colors.primary,
              )
            ],
            if (value == true) ...[
              Icon(
                Icons.check_box_rounded,
                size: 24,
                color: colors.primary,
              )
            ],
            if (value == false) ...[
              Icon(
                Icons.disabled_by_default_rounded,
                size: 24,
                color: colors.primary,
              )
            ],
          ],
        ),
      ),
    );
  }
}
