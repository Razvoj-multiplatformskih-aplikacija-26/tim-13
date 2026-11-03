import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../text/serbian.dart';
import '../theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.stage});

  final WorkOrderStage stage;

  @override
  Widget build(BuildContext context) {
    final colors = stage.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: colors.foreground, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 6),
            ),
            Flexible(
              child: Text(
                stage.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
