import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

class WorkOrderDetailScreen extends StatelessWidget {
  const WorkOrderDetailScreen({super.key, required this.id});

  final WorkOrderId id;

  Future<void> _cancel(BuildContext context, WorkOrder order) async {
    final bloc = context.read<MyWorkOrdersBloc>();
    final reason = await showReasonDialog(
      context,
      title: 'Otkazati nalog?',
      confirmLabel: 'Otkaži nalog',
      description: 'Otkazan nalog ne može da se vrati.',
    );
    if (reason != null) bloc.add(WorkOrderCancellationRequested(order.id, reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Radni nalog')),
      body: BlocBuilder<MyWorkOrdersBloc, MyWorkOrdersState>(
        builder: (context, state) {
          if (state is! MyWorkOrdersLoaded) return const LoadingView();
          final order = state.book.find(id);
          if (order == null) return const EmptyView(title: 'Nalog nije pronađen.');
          return _Details(state: state, order: order, onCancel: () => _cancel(context, order));
        },
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.state, required this.order, required this.onCancel});

  final MyWorkOrdersLoaded state;
  final WorkOrder order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = state.book;
    final actions = state.actionsFor(order);
    final busy = state.isBusy;
    final status = order.status;
    final material = order.material;
    final item = material == null ? null : book.stockItem(material.item);
    final remaining = book.remainingFor(order);
    final report = switch (status) {
      AwaitingConfirmation(:final report) || Completed(:final report) || Rejected(:final report) => report,
      Planned() || InProgress() || Cancelled() => null,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          spacing: 14,
          children: [
            OperationIcon(operation: order.operation, stage: status.stage, size: 52),
            Expanded(child: Text(order.operation.label, style: theme.textTheme.headlineSmall)),
            StatusBadge(stage: status.stage),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Row('Parcela', book.parcelOf(order)?.name ?? '—'),
                _Row('Termin', formatInterval(order.interval)),
                _Row('Mašina', book.machineOf(order)?.name ?? '—'),
                if (material != null)
                  _Row('Materijal', '${item?.name ?? '—'}, ${material.quantity} ${item?.unit.label ?? ''}'),
                if (remaining != null && !status.isFinal) _Row('Preostalo za meru', formatHectares(remaining)),
                if (report != null) ...[
                  _Row('Obrađeno', formatHectares(report.processed)),
                  _Row('Gorivo', formatLiters(report.fuel)),
                ],
                if (status case Rejected(:final reason)) _Row('Razlog odbijanja', reason.text),
                if (status case Cancelled(:final reason)) _Row('Razlog otkazivanja', reason.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (busy) ...[const LinearProgressIndicator(), const SizedBox(height: 12)],
        if (actions.contains(WorkOrderAction.start))
          FilledButton(
            onPressed: busy ? null : () => context.read<MyWorkOrdersBloc>().add(WorkOrderStartRequested(order.id)),
            child: Text(status is Rejected ? 'Vrati na doradu' : 'Započni rad'),
          ),
        if (actions.contains(WorkOrderAction.report))
          FilledButton(
            onPressed: busy ? null : () => context.push('/orders/${order.id.value}/report'),
            child: const Text('Unesi izveštaj'),
          ),
        if (actions.contains(WorkOrderAction.cancel)) ...[
          const SizedBox(height: 8),
          OutlinedButton(onPressed: busy ? null : onCancel, child: const Text('Otkaži nalog')),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
