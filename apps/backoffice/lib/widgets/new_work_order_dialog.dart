import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../dependencies.dart';

Future<WorkOrder?> showNewWorkOrderDialog(
  BuildContext context, {
  required WorkBook book,
  required BackofficeDependencies dependencies,
}) => showDialog<WorkOrder>(
  context: context,
  builder: (context) => BlocProvider(
    create: (_) => NewWorkOrderBloc(
      planWorkOrder: dependencies.planWorkOrder,
      book: book,
      owner: dependencies.owner,
      day: dependencies.clock.now().add(const Duration(days: 1)),
    ),
    child: const _NewWorkOrderDialog(),
  ),
);

class _NewWorkOrderDialog extends StatelessWidget {
  const _NewWorkOrderDialog();

  Future<void> _pickDay(BuildContext context, NewWorkOrderDraft draft) async {
    final bloc = context.read<NewWorkOrderBloc>();
    final picked = await showDatePicker(
      context: context,
      initialDate: draft.day,
      firstDate: DateTime(2026),
      lastDate: DateTime(2028),
    );
    if (picked != null) bloc.add(NewWorkOrderDraftChanged(bloc.state.draft.copyWith(day: picked)));
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<NewWorkOrderBloc>();
    final book = bloc.book;
    return BlocConsumer<NewWorkOrderBloc, NewWorkOrderState>(
      listener: (context, state) {
        if (state is NewWorkOrderSucceeded) Navigator.pop(context, state.order);
      },
      builder: (context, state) {
        final draft = state.draft;
        void change(NewWorkOrderDraft next) => bloc.add(NewWorkOrderDraftChanged(next));
        final submitting = state is NewWorkOrderSubmitting;
        final error = switch (state) {
          NewWorkOrderEditing(:final error) => error,
          NewWorkOrderRejected(:final error) => error,
          _ => null,
        };
        final kind = draft.operation.requiredStock;
        final stock = book.stock.where((item) => item.kind == kind).toList();
        final quantityEmpty = draft.quantity.trim().isEmpty;
        final shownError = error is InvalidMaterialQuantity && quantityEmpty ? null : error;
        final canSubmit = !submitting && state is! NewWorkOrderSucceeded && error == null;
        return AlertDialog(
          title: const Text('Novi radni nalog'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  const SizedBox(height: 4),
                  _Choice<ParcelId>(
                    label: 'Parcela',
                    value: draft.parcelId,
                    items: {for (final parcel in book.parcels) parcel.id: parcel.name},
                    onChanged: (value) => change(draft.copyWith(parcelId: value)),
                  ),
                  _Choice<AgroOperation>(
                    label: 'Mera',
                    value: draft.operation,
                    items: {for (final operation in AgroOperation.values) operation: operation.label},
                    onChanged: (value) => change(draft.copyWith(operation: value)),
                  ),
                  _Choice<UserId>(
                    label: 'Radnik',
                    value: draft.workerId,
                    items: {for (final worker in book.workers) worker.id: worker.name},
                    onChanged: (value) => change(draft.copyWith(workerId: value)),
                  ),
                  _Choice<MachineId>(
                    label: 'Mašina',
                    value: draft.machineId,
                    items: {for (final machine in book.machines) machine.id: machine.name},
                    onChanged: (value) => change(draft.copyWith(machineId: value)),
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDay(context, draft),
                          icon: const Icon(Icons.calendar_today_outlined, size: 18),
                          label: Text(formatDate(draft.day)),
                        ),
                      ),
                      Expanded(
                        child: _Choice<int>(
                          label: 'Od',
                          value: draft.startHour,
                          items: _hours,
                          onChanged: (value) => change(draft.copyWith(startHour: value)),
                        ),
                      ),
                      Expanded(
                        child: _Choice<int>(
                          label: 'Do',
                          value: draft.endHour,
                          items: _hours,
                          onChanged: (value) => change(draft.copyWith(endHour: value)),
                        ),
                      ),
                    ],
                  ),
                  if (kind != null)
                    Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _Choice<StockItemId>(
                            key: ValueKey(kind),
                            label: 'Materijal',
                            value: draft.stockItemId,
                            items: {for (final item in stock) item.id: '${item.name} (${item.unit.label})'},
                            onChanged: (value) => change(draft.copyWith(stockItemId: value)),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            key: const Key('quantity'),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Količina'),
                            onChanged: (text) => change(bloc.state.draft.copyWith(quantity: text)),
                          ),
                        ),
                      ],
                    ),
                  if (shownError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(shownError.message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  if (state is NewWorkOrderFailed)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nalog nije sačuvan. Pokušajte ponovo.',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
            FilledButton(
              onPressed: canSubmit ? () => bloc.add(const NewWorkOrderSubmitted()) : null,
              child: const Text('Sačuvaj'),
            ),
          ],
        );
      },
    );
  }
}

final _hours = {for (var hour = 5; hour <= 21; hour++) hour: '${hour.toString().padLeft(2, '0')}:00'};

class _Choice<T> extends StatelessWidget {
  const _Choice({super.key, required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final MapEntry(:key, :value) in items.entries)
          DropdownMenuItem(
            value: key,
            child: Text(value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
