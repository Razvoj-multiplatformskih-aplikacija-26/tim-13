import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

class OrderDetailPanel extends StatelessWidget {
  const OrderDetailPanel({
    super.key,
    required this.order,
    required this.book,
    required this.actions,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
    required this.onClose,
  });

  final WorkOrder order;
  final WorkBook book;
  final Set<WorkOrderAction> actions;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order.status;
    final material = order.material;
    final item = material == null ? null : book.stockItem(material.item);
    final remaining = book.remainingFor(order);
    final report = switch (status) {
      AwaitingConfirmation(:final report) || Completed(:final report) || Rejected(:final report) => report,
      Planned() || InProgress() || Cancelled() => null,
    };
    return Material(
      color: Colors.white,
      child: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              spacing: 12,
              children: [
                OperationIcon(operation: order.operation, stage: status.stage),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(order.operation.label, style: theme.textTheme.titleLarge),
                      StatusBadge(stage: status.stage),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Zatvori (Esc)', onPressed: onClose, icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(height: 32),
            _Field('Parcela', book.parcelOf(order)?.name ?? '—'),
            _Field('Radnik', book.workerOf(order)?.name ?? '—'),
            _Field('Mašina', book.machineOf(order)?.name ?? '—'),
            _Field('Termin', formatInterval(order.interval)),
            if (material != null)
              _Field('Materijal', '${item?.name ?? '—'}, ${material.quantity} ${item?.unit.label ?? ''}'),
            if (remaining != null && !status.isFinal) _Field('Preostalo za meru', formatHectares(remaining)),
            if (report != null) ...[
              _Field('Obrađeno', formatHectares(report.processed)),
              _Field('Gorivo', formatLiters(report.fuel)),
            ],
            if (status case Rejected(:final reason)) _Field('Razlog odbijanja', reason.text),
            if (status case Cancelled(:final reason)) _Field('Razlog otkazivanja', reason.text),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (actions.contains(WorkOrderAction.approve))
                  Tooltip(
                    message: 'Odobri (A)',
                    child: FilledButton(onPressed: busy ? null : onApprove, child: const Text('Odobri')),
                  ),
                if (actions.contains(WorkOrderAction.reject))
                  Tooltip(
                    message: 'Odbij (R)',
                    child: OutlinedButton(onPressed: busy ? null : onReject, child: const Text('Odbij')),
                  ),
                if (actions.contains(WorkOrderAction.cancel))
                  Tooltip(
                    message: 'Otkaži (X)',
                    child: OutlinedButton(onPressed: busy ? null : onCancel, child: const Text('Otkaži')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
