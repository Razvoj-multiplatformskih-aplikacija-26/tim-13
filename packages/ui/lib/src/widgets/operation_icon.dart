import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

class OperationIcon extends StatelessWidget {
  const OperationIcon({super.key, required this.operation, required this.stage, this.size = 44});

  final AgroOperation operation;
  final WorkOrderStage stage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = stage.colors;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Icon(operation.icon, color: colors.foreground, size: size * 0.5),
      ),
    );
  }
}
