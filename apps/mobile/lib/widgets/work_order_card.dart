import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

class WorkOrderCard extends StatelessWidget {
  const WorkOrderCard({super.key, required this.order, required this.parcel, required this.onOpen});

  final WorkOrder order;
  final Parcel? parcel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final parcel = this.parcel;
    final stage = order.status.stage;

    Widget meta(IconData icon, String text) => Row(
      spacing: 6,
      children: [
        Icon(icon, size: 16, color: muted),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
        ),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              OperationIcon(operation: order.operation, stage: stage),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Expanded(child: Text(order.operation.label, style: theme.textTheme.titleMedium)),
                        StatusBadge(stage: stage),
                      ],
                    ),
                    if (parcel != null) meta(Icons.place_outlined, '${parcel.name}, ${formatHectares(parcel.area)}'),
                    meta(Icons.schedule, formatInterval(order.interval)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
